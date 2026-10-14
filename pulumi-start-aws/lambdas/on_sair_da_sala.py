"""Rota sair_da_sala: o jogador sai voluntariamente da sala da dungeon."""

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    if utils.get_named_connection(connection_id) is None:
        return utils.OK

    api = utils.api_client(event)
    utils.leave_room(api, connection_id)
    return utils.OK
