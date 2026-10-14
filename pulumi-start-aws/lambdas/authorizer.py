"""Autoriza o $connect: confere o token do Cognito que o jogo manda na query string."""

import os

import jwt

ISSUER = os.environ['COGNITO_ISSUER']
CLIENT_ID = os.environ['COGNITO_CLIENT_ID']
# Busca as chaves públicas do Cognito e guarda entre uma chamada e outra.
_keys = jwt.PyJWKClient(f'{ISSUER}/.well-known/jwks.json')


def handler(event, context):
    token = (event.get('queryStringParameters') or {}).get('token', '')
    try:
        key = _keys.get_signing_key_from_jwt(token)
        claims = jwt.decode(token, key.key, algorithms=['RS256'], audience=CLIENT_ID, issuer=ISSUER)
    except jwt.PyJWTError as error:
        # O API Gateway recusa a conexão quando o authorizer levanta exatamente este texto.
        raise Exception('Unauthorized') from error
    # Só o ID token serve: é ele que traz o nome. O access token não tem o campo aud.
    if claims.get('token_use') != 'id':
        raise Exception('Unauthorized')
    return {
        'principalId': claims['sub'],
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [
                {'Action': 'execute-api:Invoke', 'Effect': 'Allow', 'Resource': event['methodArn']},
            ],
        },
        'context': {'nome': claims.get('custom:nome', '')},
    }
