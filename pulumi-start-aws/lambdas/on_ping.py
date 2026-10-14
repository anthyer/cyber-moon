"""Rota ping: mantém a conexão viva. O API Gateway fecha conexões inativas por 10 minutos."""

import utils


def handler(event, context):
    return utils.OK
