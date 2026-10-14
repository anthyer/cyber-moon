"""Rota convidar: o anfitrião convida outro jogador para a sala da dungeon."""

import uuid

from botocore.exceptions import ClientError

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    sender = utils.get_named_connection(connection_id)
    if sender is None:
        return utils.OK

    body = utils.read_body(event)
    target_id = body.get('para')

    # O alvo precisa existir e ser diferente de quem convida.
    if not isinstance(target_id, str) or target_id == connection_id:
        return utils.OK
    if utils.get_connection(target_id) is None:
        return utils.OK

    api = utils.api_client(event)

    room_id = sender.get('sala')

    # Se quem convida ainda não tem sala, cria uma nova.
    if room_id is None:
        room_id = uuid.uuid4().hex
        utils.rooms.put_item(Item={
            'sala_id': room_id,
            'anfitriao': connection_id,
            'membros': [connection_id],
            'expira_em': utils.expiration(),
        })
        utils.set_room_of(connection_id, room_id)
        # Notifica o anfitrião: o lobby precisa deste sala_atualizada para mostrar a sala.
        room = utils.get_room(room_id)
        if room:
            utils.notify_room(api, room)

    # Adiciona o convidado ao conjunto. A condição garante que só o anfitrião convida.
    try:
        utils.rooms.update_item(
            Key={'sala_id': room_id},
            UpdateExpression='ADD convidados :convidado',
            ConditionExpression='anfitriao = :eu',
            ExpressionAttributeValues={
                ':convidado': {target_id},
                ':eu': connection_id,
            },
        )
    except ClientError as error:
        if utils.condition_failed(error):
            # A sala não existe mais ou quem chamou não é o anfitrião.
            return utils.OK
        raise

    utils.send(api, target_id, 'convite', de=connection_id, nome=sender['nome'], sala=room_id)
    return utils.OK
