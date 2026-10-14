"""Rota $disconnect: limpa a conexão quando o jogo fecha a sessão WebSocket."""

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    connection = utils.get_connection(connection_id)
    if connection is None:
        return utils.OK

    api = utils.api_client(event)

    # Sai da sala primeiro, para os outros receberem sala_encerrada ou sala_atualizada
    # antes de a conexão sumir da tabela.
    utils.leave_room(api, connection_id)

    # Apaga o item antes do aviso de saída: assim a própria conexão não recebe jogador_saiu.
    utils.connections.delete_item(Key={'connection_id': connection_id})

    if 'nome' in connection:
        utils.broadcast(api, 'jogador_saiu', id=connection_id, nome=connection['nome'])

    return utils.OK
