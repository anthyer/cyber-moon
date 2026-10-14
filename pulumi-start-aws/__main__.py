"""Infraestrutura do Cyber Moon na AWS: bucket, chat WebSocket e (na sprint 4) VPC, Cognito e SES."""

import json

import pulumi
import pulumi_aws as aws
from pulumi_aws import route53, s3

# Tags aplicadas a todos os recursos, para identificar o projeto e o stack no console da AWS.
common_tags = {
    'Project': 'cyber-moon',
    'Stack': pulumi.get_stack(),
    'ManagedBy': 'pulumi',
}

# Bucket que guarda os builds exportados pelo Godot.
# O Pulumi acrescenta um sufixo aleatório ao nome físico, então não há conflito de nome global.
builds_bucket = s3.Bucket(
    'cyber-moon-builds',
    tags=common_tags,
)

# Bloqueia qualquer forma de acesso público ao bucket.
builds_bucket_public_access_block = s3.BucketPublicAccessBlock(
    'cyber-moon-builds-public-access-block',
    bucket=builds_bucket.id,
    block_public_acls=True,
    block_public_policy=True,
    ignore_public_acls=True,
    restrict_public_buckets=True,
)

# Mantém as versões antigas dos arquivos, para recuperar um build sobrescrito por engano.
builds_bucket_versioning = s3.BucketVersioning(
    'cyber-moon-builds-versioning',
    bucket=builds_bucket.id,
    versioning_configuration={
        'status': 'Enabled',
    },
)

DOMAIN = 'cyber-moon.negoci.online'

# Zona DNS do domínio do projeto. Só existe em produção, os outros stacks não têm domínio.
dns_zone = None
if pulumi.get_stack() == 'prod':
    dns_zone = route53.Zone(
        'cyber-moon',
        name=DOMAIN,
        tags=common_tags,
    )

# ---------------------------------------------------------------------------
# Configuração das chaves opcionais da sprint 4.
# Desligadas, o chat funciona aberto e fora da VPC.
# ---------------------------------------------------------------------------
config = pulumi.Config()
use_vpc = config.get_bool('usar_vpc') or False
require_login = config.get_bool('exigir_login') or False
# Endereço que assina o e-mail de boas-vindas. Sem ele, o e-mail não é enviado.
ses_sender = config.get('ses_remetente')

region = aws.get_region().region
stack = pulumi.get_stack()

# ---------------------------------------------------------------------------
# Tabelas DynamoDB
# ---------------------------------------------------------------------------

# Uma linha por conexão aberta: connection_id, nome (depois do entrar) e sala (se estiver em uma).
connections_table = aws.dynamodb.Table(
    'cybermoon-conexoes',
    billing_mode='PAY_PER_REQUEST',
    hash_key='connection_id',
    attributes=[{'name': 'connection_id', 'type': 'S'}],
    # O DynamoDB apaga sozinho a linha quando passa da hora gravada em expira_em.
    ttl={'attribute_name': 'expira_em', 'enabled': True},
    tags=common_tags,
)

# Uma linha por sala da dungeon: sala_id, anfitriao, membros (lista, anfitrião primeiro)
# e convidados (conjunto de quem tem convite sem resposta).
rooms_table = aws.dynamodb.Table(
    'cybermoon-salas',
    billing_mode='PAY_PER_REQUEST',
    hash_key='sala_id',
    attributes=[{'name': 'sala_id', 'type': 'S'}],
    ttl={'attribute_name': 'expira_em', 'enabled': True},
    tags=common_tags,
)

pulumi.export('conexoes_table', connections_table.name)
pulumi.export('salas_table', rooms_table.name)

# ---------------------------------------------------------------------------
# API Gateway WebSocket e IAM Role das Lambdas das rotas
# ---------------------------------------------------------------------------

# A API é criada antes da role porque a permissão de enviar mensagens aponta para ela.
# Não há dependência cíclica: a policy é um recurso separado da role.
api = aws.apigatewayv2.Api(
    'cybermoon-chat',
    protocol_type='WEBSOCKET',
    # O campo "action" da mensagem escolhe a rota.
    route_selection_expression='$request.body.action',
    tags=common_tags,
)


def make_role(name):
    """Role que uma Lambda assume, já com permissão de escrever os logs no CloudWatch."""
    role = aws.iam.Role(
        f'cybermoon-{name}-role',
        assume_role_policy=json.dumps({
            'Version': '2012-10-17',
            'Statement': [{
                'Effect': 'Allow',
                'Principal': {'Service': 'lambda.amazonaws.com'},
                'Action': 'sts:AssumeRole',
            }],
        }),
        tags=common_tags,
    )
    aws.iam.RolePolicyAttachment(
        f'cybermoon-{name}-logs',
        role=role.name,
        policy_arn='arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole',
    )
    return role


def routes_policy(arns):
    """O mínimo que as Lambdas das rotas precisam: as duas tabelas e o envio pelas conexões."""
    connections_arn, rooms_arn, api_arn = arns
    return json.dumps({
        'Version': '2012-10-17',
        'Statement': [
            {
                'Effect': 'Allow',
                'Action': [
                    'dynamodb:GetItem',
                    'dynamodb:PutItem',
                    'dynamodb:UpdateItem',
                    'dynamodb:DeleteItem',
                    'dynamodb:Scan',
                ],
                'Resource': [connections_arn, rooms_arn],
            },
            {
                'Effect': 'Allow',
                'Action': 'execute-api:ManageConnections',
                'Resource': f'{api_arn}/*/POST/@connections/*',
            },
        ],
    })


routes_role = make_role('rotas')
aws.iam.RolePolicy(
    'cybermoon-rotas-policy',
    role=routes_role.id,
    policy=pulumi.Output.all(
        connections_table.arn, rooms_table.arn, api.execution_arn
    ).apply(routes_policy),
)

# ---------------------------------------------------------------------------
# Função auxiliar que cria Lambdas
# ---------------------------------------------------------------------------

# A pasta lambdas/ inteira vai em todas as funções, para o utils.py estar sempre junto.
lambdas_code = pulumi.FileArchive('lambdas')

# A sprint 4 preenche estes três. Vazios, as Lambdas ficam fora da VPC e a conexão é aberta.
lambda_vpc_config = None
lambda_vpc_dependencies = []
authorizer = None


def make_lambda(name, module, role, extra_env=None, in_vpc=False, layers=None):
    """Cria uma Lambda a partir de lambdas/<module>.py, que precisa ter a função handler."""
    variables = {
        'CONEXOES_TABLE': connections_table.name,
        'SALAS_TABLE': rooms_table.name,
    }
    variables.update(extra_env or {})
    return aws.lambda_.Function(
        f'cybermoon-fn-{name}',
        runtime='python3.12',
        role=role.arn,
        handler=f'{module}.handler',
        code=lambdas_code,
        # O padrão é 3 segundos e 128 MB, pouco para ler a tabela e mandar a vários jogadores.
        timeout=10,
        memory_size=256,
        environment={'variables': variables},
        vpc_config=lambda_vpc_config if in_vpc else None,
        layers=layers,
        tags=common_tags,
        opts=pulumi.ResourceOptions(depends_on=lambda_vpc_dependencies if in_vpc else []),
    )

# ---------------------------------------------------------------------------
# Sprint 4: VPC (chave usar_vpc)
# ---------------------------------------------------------------------------

if use_vpc:
    zones = aws.get_availability_zones(state='available').names

    vpc = aws.ec2.Vpc(
        'cybermoon-vpc',
        cidr_block='10.0.0.0/16',
        enable_dns_support=True,
        enable_dns_hostnames=True,
        tags={**common_tags, 'Name': 'cybermoon-vpc'},
    )

    # Sub-rede pública: só o NAT mora nela.
    public_subnet = aws.ec2.Subnet(
        'cybermoon-publica',
        vpc_id=vpc.id,
        cidr_block='10.0.0.0/24',
        availability_zone=zones[0],
        tags={**common_tags, 'Name': 'cybermoon-publica'},
    )
    # Sub-redes privadas, em duas zonas: é nelas que as Lambdas rodam.
    private_subnet_a = aws.ec2.Subnet(
        'cybermoon-privada-a',
        vpc_id=vpc.id,
        cidr_block='10.0.1.0/24',
        availability_zone=zones[0],
        tags={**common_tags, 'Name': 'cybermoon-privada-a'},
    )
    private_subnet_b = aws.ec2.Subnet(
        'cybermoon-privada-b',
        vpc_id=vpc.id,
        cidr_block='10.0.2.0/24',
        availability_zone=zones[1],
        tags={**common_tags, 'Name': 'cybermoon-privada-b'},
    )

    internet_gateway = aws.ec2.InternetGateway(
        'cybermoon-igw',
        vpc_id=vpc.id,
        tags={**common_tags, 'Name': 'cybermoon-igw'},
    )
    nat_address = aws.ec2.Eip('cybermoon-nat-ip', domain='vpc', tags=common_tags)
    # O NAT é a saída das sub-redes privadas para a internet. As Lambdas precisam dele
    # para mandar mensagens pelo API Gateway, que fica fora da VPC.
    nat_gateway = aws.ec2.NatGateway(
        'cybermoon-nat',
        allocation_id=nat_address.id,
        subnet_id=public_subnet.id,
        tags={**common_tags, 'Name': 'cybermoon-nat'},
        opts=pulumi.ResourceOptions(depends_on=[internet_gateway]),
    )

    public_route_table = aws.ec2.RouteTable(
        'cybermoon-rt-publica',
        vpc_id=vpc.id,
        routes=[{'cidr_block': '0.0.0.0/0', 'gateway_id': internet_gateway.id}],
        tags={**common_tags, 'Name': 'cybermoon-rt-publica'},
    )
    private_route_table = aws.ec2.RouteTable(
        'cybermoon-rt-privada',
        vpc_id=vpc.id,
        routes=[{'cidr_block': '0.0.0.0/0', 'nat_gateway_id': nat_gateway.id}],
        tags={**common_tags, 'Name': 'cybermoon-rt-privada'},
    )
    aws.ec2.RouteTableAssociation(
        'cybermoon-rta-publica',
        subnet_id=public_subnet.id,
        route_table_id=public_route_table.id,
    )
    aws.ec2.RouteTableAssociation(
        'cybermoon-rta-privada-a',
        subnet_id=private_subnet_a.id,
        route_table_id=private_route_table.id,
    )
    aws.ec2.RouteTableAssociation(
        'cybermoon-rta-privada-b',
        subnet_id=private_subnet_b.id,
        route_table_id=private_route_table.id,
    )

    # Com este endpoint, o tráfego para o DynamoDB não sai da rede da AWS nem passa pelo NAT.
    aws.ec2.VpcEndpoint(
        'cybermoon-dynamodb-endpoint',
        vpc_id=vpc.id,
        service_name=f'com.amazonaws.{region}.dynamodb',
        vpc_endpoint_type='Gateway',
        route_table_ids=[private_route_table.id],
        tags={**common_tags, 'Name': 'cybermoon-dynamodb-endpoint'},
    )

    # Nada entra nas Lambdas pela rede (quem as chama é o serviço da AWS). Só a saída é liberada.
    lambda_security_group = aws.ec2.SecurityGroup(
        'cybermoon-lambda-sg',
        vpc_id=vpc.id,
        description='Lambdas do chat: sem entrada, saida liberada',
        egress=[{'protocol': '-1', 'from_port': 0, 'to_port': 0, 'cidr_blocks': ['0.0.0.0/0']}],
        tags={**common_tags, 'Name': 'cybermoon-lambda-sg'},
    )

    # Lambda em VPC cria interfaces de rede, e precisa de permissão para isso antes de nascer.
    vpc_access = aws.iam.RolePolicyAttachment(
        'cybermoon-rotas-vpc',
        role=routes_role.name,
        policy_arn='arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole',
    )
    lambda_vpc_dependencies = [vpc_access]
    lambda_vpc_config = {
        'subnet_ids': [private_subnet_a.id, private_subnet_b.id],
        'security_group_ids': [lambda_security_group.id],
    }

# ---------------------------------------------------------------------------
# Sprint 4: SES (chave ses_remetente)
# ---------------------------------------------------------------------------

welcome_function = None
if ses_sender:
    if dns_zone is not None:
        # Em produção, o domínio inteiro é verificado, com os registros criados na zona.
        ses_domain = aws.ses.DomainIdentity('cybermoon-ses', domain=DOMAIN)
        route53.Record(
            'cybermoon-ses-verificacao',
            zone_id=dns_zone.zone_id,
            name=f'_amazonses.{DOMAIN}',
            type='TXT',
            ttl=600,
            records=[ses_domain.verification_token],
        )
        # O DKIM assina os e-mails. Sem ele, a mensagem tende a cair no spam.
        ses_dkim = aws.ses.DomainDkim('cybermoon-ses-dkim', domain=ses_domain.domain)
        for index in range(3):
            dkim_token = ses_dkim.dkim_tokens[index]
            route53.Record(
                f'cybermoon-ses-dkim-{index}',
                zone_id=dns_zone.zone_id,
                name=dkim_token.apply(lambda token: f'{token}._domainkey.{DOMAIN}'),
                type='CNAME',
                ttl=600,
                records=[dkim_token.apply(lambda token: f'{token}.dkim.amazonses.com')],
            )
    else:
        # Fora de produção não há domínio. A AWS manda um e-mail de confirmação ao
        # remetente, e ele só pode enviar depois de clicar no link.
        aws.ses.EmailIdentity('cybermoon-ses-remetente', email=ses_sender)

    welcome_role = make_role('boas-vindas')
    aws.iam.RolePolicy(
        'cybermoon-boas-vindas-policy',
        role=welcome_role.id,
        policy=json.dumps({
            'Version': '2012-10-17',
            'Statement': [{'Effect': 'Allow', 'Action': 'ses:SendEmail', 'Resource': '*'}],
        }),
    )
    welcome_function = make_lambda(
        'boas-vindas',
        'boas_vindas',
        welcome_role,
        extra_env={'SES_REMETENTE': ses_sender},
    )

# ---------------------------------------------------------------------------
# Sprint 4: Cognito (User Pool criado sempre; o authorizer só com exigir_login)
# ---------------------------------------------------------------------------

user_pool = aws.cognito.UserPool(
    'cybermoon-users',
    # O jogador entra com o e-mail, e o Cognito confirma o e-mail com um código.
    username_attributes=['email'],
    auto_verified_attributes=['email'],
    password_policy={
        'minimum_length': 8,
        'require_lowercase': True,
        'require_numbers': True,
        'require_symbols': False,
        'require_uppercase': False,
    },
    # O nome que aparece no chat. No token ele vem como custom:nome.
    # Atenção: mudar esta lista depois de criado recria o User Pool e apaga as contas.
    schemas=[{
        'name': 'nome',
        'attribute_data_type': 'String',
        'mutable': True,
        'required': False,
        'string_attribute_constraints': {'min_length': '1', 'max_length': '20'},
    }],
    lambda_config={'post_confirmation': welcome_function.arn} if welcome_function else None,
    tags=common_tags,
)

app_client = aws.cognito.UserPoolClient(
    'cybermoon-client',
    user_pool_id=user_pool.id,
    # Sem segredo: o jogo roda no navegador e não tem como esconder um.
    generate_secret=False,
    explicit_auth_flows=['ALLOW_USER_PASSWORD_AUTH', 'ALLOW_REFRESH_TOKEN_AUTH'],
)

if welcome_function is not None:
    aws.lambda_.Permission(
        'cybermoon-perm-boas-vindas',
        action='lambda:InvokeFunction',
        function=welcome_function.name,
        principal='cognito-idp.amazonaws.com',
        source_arn=user_pool.arn,
    )

pulumi.export('cognito_user_pool_id', user_pool.id)
pulumi.export('cognito_client_id', app_client.id)

if require_login:
    # O PyJWT e o cryptography não vêm no runtime da Lambda. Vão numa layer, construída
    # antes do pulumi up pelo comando da tarefa 4.4:
    #   uv pip install --target build/layer/python \
    #     --python-platform x86_64-manylinux2014 --python-version 3.12 \
    #     --only-binary :all: "pyjwt[crypto]"
    jwt_layer = aws.lambda_.LayerVersion(
        'cybermoon-jwt-layer',
        layer_name=f'cybermoon-jwt-{stack}',
        code=pulumi.FileArchive('build/layer'),
        compatible_runtimes=['python3.12'],
    )
    cognito_issuer = user_pool.id.apply(
        lambda pool_id: f'https://cognito-idp.{region}.amazonaws.com/{pool_id}'
    )
    # Fora da VPC: ele só busca as chaves públicas do Cognito e não toca nas tabelas.
    authorizer_function = make_lambda(
        'authorizer',
        'authorizer',
        make_role('authorizer'),
        extra_env={'COGNITO_ISSUER': cognito_issuer, 'COGNITO_CLIENT_ID': app_client.id},
        layers=[jwt_layer.arn],
    )
    authorizer = aws.apigatewayv2.Authorizer(
        'cybermoon-authorizer',
        api_id=api.id,
        authorizer_type='REQUEST',
        authorizer_uri=authorizer_function.invoke_arn,
        # O token vem na query string: wss://.../dev?token=<id token>
        identity_sources=['route.request.querystring.token'],
        name='cognito-id-token',
    )
    # Sem esta permissão o API Gateway não consegue chamar o authorizer e todo $connect falha.
    aws.lambda_.Permission(
        'cybermoon-perm-authorizer',
        action='lambda:InvokeFunction',
        function=authorizer_function.name,
        principal='apigateway.amazonaws.com',
        source_arn=api.execution_arn.apply(lambda arn: f'{arn}/authorizers/*'),
    )

# ---------------------------------------------------------------------------
# Rotas, permissões e estágio (sprint 3, mas fica aqui no fim porque usa
# authorizer e lambda_vpc_config que a sprint 4 pode ter preenchido acima)
# ---------------------------------------------------------------------------

# Cada rota do protocolo e o arquivo de lambdas/ que responde por ela.
ROUTES = {
    '$connect': 'on_connect',
    '$disconnect': 'on_disconnect',
    'entrar': 'on_entrar',
    'chat': 'on_chat',
    'convidar': 'on_convidar',
    'responder_convite': 'on_responder_convite',
    'sair_da_sala': 'on_sair_da_sala',
    'iniciar_dungeon': 'on_iniciar_dungeon',
    'sala': 'on_sala',
    'ping': 'on_ping',
}

routes = []
for route_key, module in ROUTES.items():
    # '$connect' vira 'connect' e 'sair_da_sala' vira 'sair-da-sala' no nome do recurso.
    slug = route_key.lstrip('$').replace('_', '-')
    function = make_lambda(slug, module, routes_role, in_vpc=use_vpc)
    integration = aws.apigatewayv2.Integration(
        f'cybermoon-integ-{slug}',
        api_id=api.id,
        integration_type='AWS_PROXY',
        integration_uri=function.invoke_arn,
    )
    # Só o $connect passa pelo authorizer, e só quando o login está ligado (sprint 4).
    needs_login = route_key == '$connect' and authorizer is not None
    routes.append(aws.apigatewayv2.Route(
        f'cybermoon-route-{slug}',
        api_id=api.id,
        route_key=route_key,
        target=integration.id.apply(lambda integration_id: f'integrations/{integration_id}'),
        authorization_type='CUSTOM' if needs_login else 'NONE',
        authorizer_id=authorizer.id if needs_login else None,
    ))
    aws.lambda_.Permission(
        f'cybermoon-perm-{slug}',
        action='lambda:InvokeFunction',
        function=function.name,
        principal='apigateway.amazonaws.com',
        source_arn=api.execution_arn.apply(lambda arn: f'{arn}/*/*'),
    )

# O estágio leva o nome do stack (dev ou prod), que aparece no fim da URL.
api_stage = aws.apigatewayv2.Stage(
    'cybermoon-stage',
    api_id=api.id,
    name=stack,
    auto_deploy=True,
    # Teto de mensagens por segundo em cada rota, somando todas as conexões. Protege a
    # conta de um laço de envio por engano. Uma dungeon com 4 jogadores manda perto de 60
    # por segundo na rota sala.
    default_route_settings={'throttling_rate_limit': 200, 'throttling_burst_limit': 400},
    tags=common_tags,
    opts=pulumi.ResourceOptions(depends_on=routes),
)

# O endereço wss:// que o jogo usa para conectar.
pulumi.export('wss_url', api_stage.invoke_url)

# Exporta o nome físico do bucket, usado na hora de enviar os builds.
pulumi.export('builds_bucket_name', builds_bucket.id)
