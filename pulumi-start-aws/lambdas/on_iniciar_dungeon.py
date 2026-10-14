"""Rota iniciar_dungeon: o anfitrião dispara o início da partida para todos os membros."""

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    sender = utils.get_named_connection(connection_id)
    if sender is None or 'sala' not in sender:
        return utils.OK

    room = utils.get_room(sender['sala'])
    if room is None or room['anfitriao'] != connection_id:
        # Só o anfitrião inicia.
        return utils.OK

    api = utils.api_client(event)
    summary = utils.room_summary(room)
    for member in room['membros']:
        utils.send(api, member, 'dungeon_iniciada', **summary)

    return utils.OK
