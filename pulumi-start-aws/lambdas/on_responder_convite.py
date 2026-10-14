"""Rota responder_convite: o convidado aceita ou recusa entrar na sala da dungeon."""

from botocore.exceptions import ClientError

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    sender = utils.get_named_connection(connection_id)
    if sender is None:
        return utils.OK

    body = utils.read_body(event)
    room_id = body.get('sala')
    if not isinstance(room_id, str):
        return utils.OK

    # Gasta o convite numa operação só: só entra quem foi convidado.
    # ReturnValues='ALL_NEW' devolve o item já atualizado, economizando uma leitura.
    try:
        result = utils.rooms.update_item(
            Key={'sala_id': room_id},
            UpdateExpression='DELETE convidados :convidado',
            ConditionExpression='contains(convidados, :id)',
            ExpressionAttributeValues={
                ':convidado': {connection_id},
                ':id': connection_id,
            },
            ReturnValues='ALL_NEW',
        )
    except ClientError as error:
        if utils.condition_failed(error):
            # Não foi convidado ou a sala não existe.
            return utils.OK
        raise

    room = result.get('Attributes')
    if room is None:
        return utils.OK

    api = utils.api_client(event)

    if not body.get('aceita', False):
        utils.send(api, room['anfitriao'], 'convite_recusado',
                   de=connection_id, nome=sender['nome'])
        return utils.OK

    # Aceito: sai da sala anterior e entra nesta.
    utils.leave_room(api, connection_id)

    for _ in range(utils.MAX_ATTEMPTS):
        room = utils.get_room(room_id)
        if room is None:
            return utils.OK
        new_members = list(room['membros']) + [connection_id]
        if utils.replace_members(room, new_members):
            utils.set_room_of(connection_id, room_id)
            room['membros'] = new_members
            utils.notify_room(api, room)
            return utils.OK

    return utils.OK
