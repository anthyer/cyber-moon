"""O gatilho de cadastro e o authorizer do plano 38: nome de usuário, sem e-mail."""

import time

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa

import authorizer
import cadastro

ISSUER = authorizer.ISSUER
CLIENT_ID = authorizer.CLIENT_ID


def signup_event(username):
    return {'userName': username, 'request': {'userAttributes': {}}, 'response': {}}


@pytest.mark.parametrize('username', ['Ana', 'bombazaro2', 'jogador_1', 'a' * 20])
def test_cadastro_confirma_nome_valido(username):
    assert cadastro.handler(signup_event(username), None)['response']['autoConfirmUser'] is True


@pytest.mark.parametrize('username', ['ab', 'a' * 21, 'João', 'com espaço', 'traço-no-meio'])
def test_cadastro_recusa_nome_fora_do_formato(username):
    with pytest.raises(Exception, match='nome_invalido'):
        cadastro.handler(signup_event(username), None)


class FakeSigningKey:
    def __init__(self, key):
        self.key = key


@pytest.fixture
def private_key(monkeypatch):
    """Uma chave RSA de teste no lugar das chaves públicas que o Cognito publicaria."""
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    monkeypatch.setattr(authorizer._keys, 'get_signing_key_from_jwt',
                        lambda token: FakeSigningKey(key.public_key()))
    return key


def make_token(private_key, **claims):
    now = int(time.time())
    payload = {
        'iss': ISSUER,
        'aud': CLIENT_ID,
        'sub': 'conta-1',
        'token_use': 'id',
        'cognito:username': 'testeana',
        'preferred_username': 'TesteAna',
        'iat': now,
        'exp': now + 3600,
        **claims,
    }
    return jwt.encode(payload, private_key, algorithm='RS256')


def authorize(token):
    event = {'queryStringParameters': {'token': token}, 'methodArn': 'arn:teste'}
    return authorizer.handler(event, None)


def test_authorizer_passa_o_nome_como_o_jogador_digitou(private_key):
    result = authorize(make_token(private_key))
    assert result['principalId'] == 'conta-1'
    assert result['context'] == {'nome': 'TesteAna'}


def test_authorizer_usa_o_username_sem_preferred_username(private_key):
    token = make_token(private_key, preferred_username=None)
    assert authorize(token)['context'] == {'nome': 'testeana'}


@pytest.mark.parametrize('claims', [
    {'token_use': 'access'},
    {'aud': 'outro-cliente'},
    {'iss': 'https://outro-emissor'},
    {'exp': int(time.time()) - 60},
])
def test_authorizer_recusa_token_errado(private_key, claims):
    with pytest.raises(Exception, match='Unauthorized'):
        authorize(make_token(private_key, **claims))
