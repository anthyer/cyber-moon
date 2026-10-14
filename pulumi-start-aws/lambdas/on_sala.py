"""Rota sala: repassa dados do jogo aos outros membros da sala, sem inspecionar o conteúdo.

É a rota mais chamada: posições, golpes e eventos da dungeon passam por aqui, umas 20
mensagens por segundo por jogador. Não acrescentar leitura nem gravação sem medir o custo.
"""

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    sender = utils.get_named_connection(connection_id)
    if sender is None or 'sala' not in sender:
        return utils.OK

    room = utils.get_room(sender['sala'])
    if room is None:
        return utils.OK

    dados = utils.read_body(event).get('dados', {})
    api = utils.api_client(event)

    for member in room['membros']:
        if member != connection_id:
            utils.send(api, member, 'sala', de=connection_id, dados=dados)

    return utils.OK
