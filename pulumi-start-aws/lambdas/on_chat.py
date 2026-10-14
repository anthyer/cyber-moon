"""Rota chat: repassa o texto a todos os conectados, inclusive a quem mandou."""

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    sender = utils.get_named_connection(connection_id)
    if sender is None:
        return utils.OK

    text = str(utils.read_body(event).get('texto', '')).strip()[:utils.MAX_CHAT_LENGTH]
    if text:
        api = utils.api_client(event)
        utils.broadcast(api, 'chat', de=connection_id, nome=sender['nome'], texto=text)

    return utils.OK
