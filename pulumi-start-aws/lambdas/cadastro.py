"""Gatilho Pre sign-up do Cognito: confere o nome de usuário e confirma a conta sozinha.

O cadastro não pede e-mail, então não há código para confirmar. Sem este gatilho a conta
ficaria parada como não confirmada e não conseguiria entrar.
"""

import re

# De 3 a 20 caracteres: letras sem acento, números e sublinhado. O jogo confere a mesma
# regra antes de mandar (PADRAO_DO_USUARIO em game/scripts/core/account_manager.gd).
USERNAME_PATTERN = re.compile(r'^[A-Za-z0-9_]{3,20}$')


def handler(event, context):
    if not USERNAME_PATTERN.match(event['userName']):
        # O texto volta ao jogo dentro da mensagem do UserLambdaValidationException.
        raise Exception('nome_invalido')
    event['response']['autoConfirmUser'] = True
    return event
