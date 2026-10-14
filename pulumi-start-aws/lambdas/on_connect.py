"""Rota $connect: registra a conexão no DynamoDB quando o jogo abre a sessão WebSocket."""

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    item = {
        'connection_id': connection_id,
        'expira_em': utils.expiration(),
    }
    # Com login ligado (sprint 4), o authorizer grava o id da conta e o nome no contexto.
    authorizer_context = event['requestContext'].get('authorizer') or {}
    if authorizer_context.get('principalId'):
        item['conta'] = authorizer_context['principalId']
    if authorizer_context.get('nome'):
        item['nome_da_conta'] = authorizer_context['nome']
    # Durante o $connect a conexão ainda não aceita mensagem: não mandar nada ao jogo.
    utils.connections.put_item(Item=item)
    return utils.OK
