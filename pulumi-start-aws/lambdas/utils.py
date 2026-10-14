"""O que as Lambdas do chat dividem: ler a mensagem, enviar, ler conexão e sair de sala."""

import json
import os
import time

import boto3
from botocore.exceptions import ClientError

MAX_NAME_LENGTH = 20
MAX_CHAT_LENGTH = 200
# Quantas vezes tentar de novo quando outra Lambda mexeu na mesma sala ao mesmo tempo.
MAX_ATTEMPTS = 3
# Uma conexão do API Gateway dura no máximo 2 horas. Depois de 3, o DynamoDB apaga
# sozinho o que tiver sobrado de uma conexão que caiu sem avisar.
SECONDS_TO_EXPIRE = 3 * 60 * 60
OK = {'statusCode': 200}

_dynamodb = boto3.resource('dynamodb')
connections = _dynamodb.Table(os.environ['CONEXOES_TABLE'])
rooms = _dynamodb.Table(os.environ['SALAS_TABLE'])
# Um cliente por endereço de retorno, reaproveitado entre uma chamada e outra.
_api_clients = {}


def api_client(event):
    """O cliente que manda mensagens de volta pelas conexões abertas no API Gateway."""
    request = event['requestContext']
    endpoint = f"https://{request['domainName']}/{request['stage']}"
    if endpoint not in _api_clients:
        _api_clients[endpoint] = boto3.client('apigatewaymanagementapi', endpoint_url=endpoint)
    return _api_clients[endpoint]


def read_body(event):
    """O JSON que o jogo mandou. Mensagem que não é um objeto JSON vira dicionário vazio."""
    try:
        body = json.loads(event.get('body') or '{}')
    except json.JSONDecodeError:
        return {}
    return body if isinstance(body, dict) else {}


def expiration():
    return int(time.time()) + SECONDS_TO_EXPIRE


def condition_failed(error):
    return error.response['Error']['Code'] == 'ConditionalCheckFailedException'


def send(api, connection_id, message_type, **fields):
    """Manda uma mensagem a uma conexão. Conexão que já caiu é apagada da tabela."""
    data = json.dumps({'tipo': message_type, **fields}).encode()
    try:
        api.post_to_connection(ConnectionId=connection_id, Data=data)
    except api.exceptions.GoneException:
        connections.delete_item(Key={'connection_id': connection_id})


def get_connection(connection_id):
    """O item da conexão, ou None se ela não existe mais."""
    return connections.get_item(Key={'connection_id': connection_id}, ConsistentRead=True).get('Item')


def get_named_connection(connection_id):
    """A conexão, só se ela já disse o nome. Antes do nome, a única rota aceita é entrar."""
    connection = get_connection(connection_id)
    if connection is None or 'nome' not in connection:
        return None
    return connection


def named_connections():
    """Todas as conexões que já disseram o nome. Lê a tabela inteira, página por página."""
    arguments = {
        'FilterExpression': 'attribute_exists(nome)',
        'ProjectionExpression': 'connection_id, nome',
        'ConsistentRead': True,
    }
    found = []
    while True:
        page = connections.scan(**arguments)
        found.extend(page['Items'])
        if 'LastEvaluatedKey' not in page:
            return found
        arguments['ExclusiveStartKey'] = page['LastEvaluatedKey']


def broadcast(api, message_type, skip=None, **fields):
    """Manda uma mensagem a todos os que já disseram o nome."""
    for connection in named_connections():
        if connection['connection_id'] != skip:
            send(api, connection['connection_id'], message_type, **fields)


def set_room_of(connection_id, room_id):
    """Anota em que sala a conexão está. None tira a sala. Conexão que já saiu é ignorada."""
    arguments = {
        'Key': {'connection_id': connection_id},
        # Sem a condição, o update_item criaria de novo o item de uma conexão que já saiu.
        'ConditionExpression': 'attribute_exists(connection_id)',
    }
    if room_id is None:
        arguments['UpdateExpression'] = 'REMOVE sala'
    else:
        arguments['UpdateExpression'] = 'SET sala = :sala'
        arguments['ExpressionAttributeValues'] = {':sala': room_id}
    try:
        connections.update_item(**arguments)
    except ClientError as error:
        if not condition_failed(error):
            raise


def get_room(room_id):
    return rooms.get_item(Key={'sala_id': room_id}, ConsistentRead=True).get('Item')


def room_summary(room):
    members = []
    for member in room['membros']:
        connection = get_connection(member) or {}
        members.append({'id': member, 'nome': connection.get('nome', '?')})
    return {'sala': room['sala_id'], 'anfitriao': room['anfitriao'], 'membros': members}


def notify_room(api, room):
    summary = room_summary(room)
    for member in room['membros']:
        send(api, member, 'sala_atualizada', **summary)


def replace_members(room, new_members):
    """Grava a nova lista de membros, só se ninguém mexeu nela desde a leitura.

    Devolve False quando outra Lambda gravou antes. Quem chamou lê a sala e tenta de novo.
    """
    try:
        rooms.update_item(
            Key={'sala_id': room['sala_id']},
            UpdateExpression='SET membros = :novos',
            ConditionExpression='membros = :lidos',
            ExpressionAttributeValues={':novos': new_members, ':lidos': room['membros']},
        )
    except ClientError as error:
        if condition_failed(error):
            return False
        raise
    return True


def leave_room(api, connection_id):
    """Tira a conexão da sala em que está. Se ela era a anfitriã, a sala acaba."""
    connection = get_connection(connection_id)
    if connection is None or 'sala' not in connection:
        return
    room_id = connection['sala']
    set_room_of(connection_id, None)
    for _ in range(MAX_ATTEMPTS):
        room = get_room(room_id)
        if room is None or connection_id not in room['membros']:
            return
        remaining = [member for member in room['membros'] if member != connection_id]
        if room['anfitriao'] == connection_id or not remaining:
            rooms.delete_item(Key={'sala_id': room_id})
            for member in remaining:
                set_room_of(member, None)
                send(api, member, 'sala_encerrada', sala=room_id)
            return
        if replace_members(room, remaining):
            room['membros'] = remaining
            notify_room(api, room)
            return
