"""Gatilho Post Confirmation do Cognito: manda o e-mail de boas-vindas pelo SES."""

import os

import boto3
from botocore.exceptions import ClientError

SENDER = os.environ['SES_REMETENTE']
ses = boto3.client('ses')


def handler(event, context):
    attributes = event['request']['userAttributes']
    # Desde o plano 38 o cadastro não pede e-mail. Conta sem e-mail não recebe nada.
    if 'email' not in attributes:
        return event
    name = event['userName']
    text = (
        f'Olá, {name}!\n\n'
        'Sua conta no Cyber Moon foi criada.\n'
        'Entre no jogo e abra o chat com Enter ou T.\n\n'
        'Boa jornada!'
    )
    try:
        ses.send_email(
            Source=SENDER,
            Destination={'ToAddresses': [attributes['email']]},
            Message={
                'Subject': {'Data': 'Bem-vindo ao Cyber Moon'},
                'Body': {'Text': {'Data': text}},
            },
        )
    except ClientError as error:
        # Um e-mail que falhou não pode impedir o cadastro: se esta função levantar erro,
        # o Cognito devolve erro ao jogador na confirmação da conta.
        print(f'E-mail de boas-vindas não enviado: {error}')
    # O Cognito espera receber o evento de volta.
    return event
