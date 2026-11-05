"""Prepara a AWS de mentira (moto) e um API Gateway falso para os testes das Lambdas."""

import json
import os
import sys
from types import SimpleNamespace

# Sem isto, importar as Lambdas cria lambdas/__pycache__, que iria junto no pacote e faria
# o Pulumi enxergar código novo em todas as funções a cada rodada de testes.
sys.dont_write_bytecode = True
# As Lambdas leem estas variáveis ao serem importadas, então elas vêm antes de tudo.
os.environ['AWS_DEFAULT_REGION'] = 'sa-east-1'
os.environ['AWS_ACCESS_KEY_ID'] = 'teste'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'teste'
os.environ['CONEXOES_TABLE'] = 'conexoes'
os.environ['SALAS_TABLE'] = 'salas'
os.environ['COGNITO_ISSUER'] = 'https://cognito-idp.sa-east-1.amazonaws.com/sa-east-1_teste'
os.environ['COGNITO_CLIENT_ID'] = 'cliente-de-teste'

import boto3  # noqa: E402
import pytest  # noqa: E402
from moto import mock_aws  # noqa: E402


class GoneError(Exception):
    pass


class FakeApi:
    """Guarda o que cada conexão recebeu, no lugar do API Gateway."""

    exceptions = SimpleNamespace(GoneException=GoneError)

    def __init__(self):
        self.received = {}
        self.gone = set()

    def post_to_connection(self, ConnectionId, Data):
        if ConnectionId in self.gone:
            raise GoneError()
        self.received.setdefault(ConnectionId, []).append(json.loads(Data))

    def types(self, connection_id):
        """Os tipos das mensagens que a conexão recebeu, na ordem."""
        return [message['tipo'] for message in self.received.get(connection_id, [])]

    def last(self, connection_id, message_type):
        """A última mensagem do tipo pedido que a conexão recebeu."""
        for message in reversed(self.received.get(connection_id, [])):
            if message['tipo'] == message_type:
                return message
        raise AssertionError(f'{connection_id} não recebeu {message_type}')


@pytest.fixture
def api(monkeypatch):
    """Cria as duas tabelas no moto e troca o cliente do API Gateway pelo falso."""
    with mock_aws():
        dynamodb = boto3.resource('dynamodb')
        for table, key in (('conexoes', 'connection_id'), ('salas', 'sala_id')):
            dynamodb.create_table(
                TableName=table,
                KeySchema=[{'AttributeName': key, 'KeyType': 'HASH'}],
                AttributeDefinitions=[{'AttributeName': key, 'AttributeType': 'S'}],
                BillingMode='PAY_PER_REQUEST',
            )
        import utils

        fake = FakeApi()
        monkeypatch.setattr(utils, 'api_client', lambda event: fake)
        yield fake


def call(module, connection_id, **body):
    """Chama o handler de uma Lambda como o API Gateway chamaria."""
    event = {
        'requestContext': {'connectionId': connection_id, 'domainName': 'exemplo', 'stage': 'dev'},
        'body': json.dumps(body),
    }
    return module.handler(event, None)
