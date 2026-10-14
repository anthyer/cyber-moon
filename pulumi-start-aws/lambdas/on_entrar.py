"""Rota entrar: o jogador diz o nome, recebe a lista de quem está online e anuncia chegada."""

from botocore.exceptions import ClientError

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    connection = utils.get_connection(connection_id)
    if connection is None:
        return utils.OK

    body = utils.read_body(event)

    # O nome vem, nesta ordem: da conta do Cognito (quando há login), do corpo da mensagem,
    # ou de um padrão baseado no connectionId.
    name = (
        connection.get('nome_da_conta')
        or str(body.get('nome', '')).strip()
        or f'Jogador{connection_id[:4]}'
    )
    name = name[:utils.MAX_NAME_LENGTH]

    # Grava o nome. A condição evita criar de novo um item de conexão que já saiu.
    try:
        utils.connections.update_item(
            Key={'connection_id': connection_id},
            UpdateExpression='SET nome = :nome',
            ConditionExpression='attribute_exists(connection_id)',
            ExpressionAttributeValues={':nome': name},
        )
    except ClientError as error:
        if utils.condition_failed(error):
            return utils.OK
        raise

    api = utils.api_client(event)

    # Monta a lista de quem já está online (não inclui quem acabou de entrar).
    # O nome é gravado antes: se dois entram juntos, pelo menos um fica sabendo do outro.
    online = [
        {'id': c['connection_id'], 'nome': c['nome']}
        for c in utils.named_connections()
        if c['connection_id'] != connection_id
    ]

    utils.send(api, connection_id, 'bem_vindo', id=connection_id, nome=name, online=online)
    utils.broadcast(api, 'jogador_entrou', skip=connection_id, id=connection_id, nome=name)

    return utils.OK
