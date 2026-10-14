# Plano 18: Chat entre jogadores (CyberMoon Chat)

**Prioridade.** Feature de nuvem para a disciplina de Infraestrutura e Servicos de Nuvem.
Nao depende de nenhum dos planos 01-17 para funcionar, e pode ser feita em paralelo.

**Objetivo:** jogadores conectados via WebGL podem se comunicar em tempo real atraves de
um chat global e de salas de dungeon, usando conexoes WebSocket gerenciadas pelo AWS API
Gateway. A mensagem aparece para todos os outros jogadores conectados em menos de 300 ms.

**Abordagem:** infraestrutura serverless provisionada como codigo usando **Pulumi**
(Python, uv). Backend na AWS (API Gateway WebSocket, Lambda, DynamoDB, Cognito e SES).
O codigo Pulumi fica em `pulumi-start-aws/`. O frontend Godot (NetworkManager, ChatManager,
HudChat, LobbyManager) ja esta pronto (planos 21 e 22).

---

## O que ja existe (Sprints 1 e 2, concluidas)

- `pulumi-start-aws/__main__.py`: bucket S3 privado com versionamento e bloqueio de acesso
  publico; zona Route53 (so em prod) para `cyber-moon.negoci.online`. Exporta
  `builds_bucket_name`.
- `Pulumi.dev.yaml`: stack `dev`, regiao `sa-east-1`.
- `Pulumi.prod.yaml`: stack `prod`.
- `backend/servidor_local/servidor.py`: servidor local que implementa o protocolo completo
  (referencia para as Lambdas).
- Lado Godot: `NetworkManager`, `ChatManager`, `HudChat`, `LobbyManager` prontos.

---

## O protocolo (referencia para as Lambdas)

Mensagens em JSON por WebSocket. O campo `action` da mensagem escolhe a rota no API
Gateway (`routeSelectionExpression: $request.body.action`). O campo `tipo` identifica o
que o servidor devolveu.

| Do jogo (`action`) | Campos enviados | O servidor responde ou repassa |
|---|---|---|
| `$connect` | (query string `token` p/ Cognito, sprint 4) | registra `connection_id` + `nome` no DynamoDB |
| `$disconnect` | - | remove `connection_id`; emite `jogador_saiu` aos demais; encerra sala se necessario |
| `entrar` | `nome` | a quem entrou: `bem_vindo` (`id`, `nome`, `online`); aos outros: `jogador_entrou` |
| `chat` | `texto` | a todos (inclusive quem mandou): `chat` (`de`, `nome`, `texto`) |
| `convidar` | `para` | ao convidado: `convite` (`de`, `nome`, `sala`). Cria sala se nao existia |
| `responder_convite` | `sala`, `aceita` | aos membros: `sala_atualizada`; se recusou: ao anfitriao `convite_recusado` |
| `sair_da_sala` | - | aos membros: `sala_atualizada` ou `sala_encerrada` |
| `iniciar_dungeon` | - | aos membros: `dungeon_iniciada` (so anfitriao pode) |
| `sala` | `dados` | aos outros membros: `sala` (`de`, `dados`), sem inspecionar o conteudo |

O `servidor.py` e a referencia. `testar_protocolo.py` cobre todas as rotas com asserts.

**Para trocar o jogo para a AWS:** altere `endereco` em
`game/resources/rede/configuracao.tres` para a URL `wss://` exportada pelo Pulumi.

---

## Sprint 3: Banco de Dados, Lambdas e API Gateway WebSocket

**Meta:** o jogo consegue conectar na AWS e trocar mensagens em tempo real, sem Cognito
(conexao aberta por enquanto). As tabelas guardam conexoes e salas com o mesmo formato
que o servidor local usa.

### Tarefa 3.1: Estrutura de pastas do backend

Criar as pastas e arquivos dentro de `pulumi-start-aws/` para organizar o codigo das
Lambdas e da infra:

```
pulumi-start-aws/
  lambdas/
    on_connect.py
    on_disconnect.py
    on_entrar.py
    on_chat.py
    on_convidar.py
    on_responder_convite.py
    on_sair_da_sala.py
    on_iniciar_dungeon.py
    on_sala.py
  __main__.py        (ja existe, vai crescer)
```

Cada arquivo `lambdas/*.py` contera uma funcao `handler(event, context)` no padrao AWS
Lambda. O `event` de uma rota WebSocket traz:
- `event["requestContext"]["connectionId"]`: id da conexao que enviou a mensagem.
- `event["requestContext"]["domainName"]` e `event["requestContext"]["stage"]`: usados
  para montar o endpoint de callback.
- `event["body"]`: o JSON enviado pelo jogo (string; usar `json.loads`).

Para mandar de volta ao cliente, usar `boto3.client("apigatewaymanagementapi",
endpoint_url=f"https://{domain}/{stage}").post_to_connection(...)`.

### Tarefa 3.2: Tabelas DynamoDB (via Pulumi)

Adicionar em `pulumi-start-aws/__main__.py` (importar `pulumi_aws.dynamodb`):

**Tabela `cybermoon-conexoes`**
- Partition key: `connection_id` (String).
- Atributos extras (sem declarar no schema, so usar no codigo): `nome`, `sala`.
- Billing: `PAY_PER_REQUEST` (on-demand).

**Tabela `cybermoon-salas`**
- Partition key: `sala_id` (String).
- Atributos extras: `anfitriao`, `membros` (lista de connection_ids), `convidados`
  (lista de connection_ids com convite sem resposta).
- Billing: `PAY_PER_REQUEST`.

Exportar os nomes fisicos das tabelas:
```python
pulumi.export("conexoes_table", conexoes_table.name)
pulumi.export("salas_table", salas_table.name)
```

Nao e necessaria tabela de mensagens nesta sprint: o servidor local tambem nao guarda
historico, e o jogo nao tem scroll de historico. Pode ser adicionada depois.

### Tarefa 3.3: IAM Role para as Lambdas

Criar uma IAM Role com trust policy para `lambda.amazonaws.com` e anexar:
1. Policy gerenciada `AWSLambdaBasicExecutionRole` (logs no CloudWatch).
2. Policy inline com as permissoes minimas:
   - `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:DeleteItem`,
     `dynamodb:UpdateItem`, `dynamodb:Scan` nas duas tabelas.
   - `execute-api:ManageConnections` no ARN do API Gateway (para `post_to_connection`).

```python
import json
import pulumi_aws as aws

lambda_role = aws.iam.Role("cybermoon-lambda-role",
    assume_role_policy=json.dumps({
        "Version": "2012-10-17",
        "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"},
                       "Action": "sts:AssumeRole"}],
    }),
    tags=common_tags,
)
aws.iam.RolePolicyAttachment("cybermoon-lambda-logs",
    role=lambda_role.name,
    policy_arn="arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
)
# Policy inline: DynamoDB + ManageConnections (ARN do API GW adicionado depois).
```

### Tarefa 3.4: Funcoes Lambda (via Pulumi)

Para cada arquivo em `lambdas/`, criar um recurso `aws.lambda_.Function`. Usar
`pulumi.AssetArchive` para empacotar o arquivo:

```python
import pulumi

def make_lambda(name, handler_file, handler_func="handler"):
    return aws.lambda_.Function(
        f"cybermoon-{name}",
        runtime="python3.12",
        role=lambda_role.arn,
        handler=f"{handler_file}.{handler_func}",
        code=pulumi.AssetArchive({
            f"{handler_file}.py": pulumi.FileAsset(f"lambdas/{handler_file}.py"),
        }),
        environment={"variables": {
            "CONEXOES_TABLE": conexoes_table.name,
            "SALAS_TABLE": salas_table.name,
        }},
        tags=common_tags,
    )

fn_connect    = make_lambda("on-connect",    "on_connect")
fn_disconnect = make_lambda("on-disconnect", "on_disconnect")
fn_entrar     = make_lambda("on-entrar",     "on_entrar")
fn_chat       = make_lambda("on-chat",       "on_chat")
fn_convidar   = make_lambda("on-convidar",   "on_convidar")
fn_resp       = make_lambda("on-resp-conv",  "on_responder_convite")
fn_sair       = make_lambda("on-sair-sala",  "on_sair_da_sala")
fn_iniciar    = make_lambda("on-iniciar",    "on_iniciar_dungeon")
fn_sala       = make_lambda("on-sala",       "on_sala")
```

Variaveis de ambiente `CONEXOES_TABLE` e `SALAS_TABLE` passam os nomes fisicos das
tabelas (o Pulumi acrescenta sufixo aleatorio ao nome logico).

### Tarefa 3.5: Logica de cada Lambda

Implementar cada `lambdas/*.py` espelhando o `servidor.py` local. Pontos de atencao:

**`on_connect.py`** - rota `$connect`
- Inserir item na tabela `CONEXOES_TABLE`:
  `{"connection_id": connectionId, "nome": None, "sala": None}`.
- Retornar `{"statusCode": 200}`.

**`on_disconnect.py`** - rota `$disconnect`
- Ler a conexao na tabela.
- Se tiver sala, chamar a logica de `sair_da_sala` (extrair para modulo `utils.py`).
- Deletar o item da tabela.
- Broadcast `jogador_saiu` se `nome != None`.

**`on_entrar.py`** - rota `entrar`
- Ler `nome` do body (truncar em 20 chars, default `Jogador<connectionId[:4]>`).
- Atualizar item na tabela: setar `nome`.
- Fazer scan na tabela de conexoes para montar lista `online`.
- Mandar `bem_vindo` ao proprio jogador e broadcast `jogador_entrou` aos demais.

**`on_chat.py`** - rota `chat`
- Ler `texto` do body (truncar em 200 chars).
- Se vazio, ignorar.
- Ler `nome` da tabela de conexoes.
- Scan na tabela, mandar `chat` a todos que tem `nome != None`.

**`on_convidar.py`** - rota `convidar`
- Ler `para` (connection_id do convidado) do body.
- Se o anfitriao nao tem sala, criar item na tabela `SALAS_TABLE`:
  `{"sala_id": uuid, "anfitriao": connectionId, "membros": [connectionId], "convidados": []}`.
  Atualizar `sala` do anfitriao na tabela de conexoes.
- Adicionar `para` ao campo `convidados` da sala.
- Mandar `convite` ao convidado.

**`on_responder_convite.py`** - rota `responder_convite`
- Checar se `connectionId` esta em `convidados` da sala.
- Se nao, ignorar.
- Remover de `convidados`.
- Se `aceita == False`: mandar `convite_recusado` ao anfitriao.
- Se `aceita == True`: adicionar `connectionId` a `membros`, atualizar `sala` na tabela
  de conexoes, mandar `sala_atualizada` a todos os membros.

**`on_sair_da_sala.py`** - rota `sair_da_sala`
- Mesma logica de `leave_room` do servidor local.
- Se quem saiu era o anfitriao, encerrar a sala e mandar `sala_encerrada` a todos.
- Se nao, remover dos `membros` e mandar `sala_atualizada`.

**`on_iniciar_dungeon.py`** - rota `iniciar_dungeon`
- Verificar se `connectionId` e o `anfitriao` da sala.
- Mandar `dungeon_iniciada` a todos os membros.

**`on_sala.py`** - rota `sala`
- Ler `dados` do body.
- Buscar `sala` da conexao na tabela.
- Repassar `{"tipo": "sala", "de": connectionId, "dados": dados}` a todos os outros
  membros da sala.

Modulo auxiliar `lambdas/utils.py` com funcoes compartilhadas:
- `send(apigw, connection_id, tipo, **fields)`: manda JSON ao cliente.
- `broadcast(apigw, connection_ids, tipo, skip=None, **fields)`: manda a uma lista.
- `get_connection(table, connection_id)`: le item; retorna `None` se nao existe.
- `leave_room(conn_table, rooms_table, apigw, connection_id)`: logica de saida de sala.

### Tarefa 3.6: API Gateway WebSocket (via Pulumi)

Criar a WebSocket API e as rotas:

```python
api = aws.apigatewayv2.Api("cybermoon-chat",
    protocol_type="WEBSOCKET",
    route_selection_expression="$request.body.action",
    tags=common_tags,
)
```

Para cada rota, criar `Integration` + `Route` + permissao Lambda:

```python
def make_route(route_key, fn):
    integration = aws.apigatewayv2.Integration(
        f"cybermoon-integ-{route_key.lstrip('$')}",
        api_id=api.id,
        integration_type="AWS_PROXY",
        integration_uri=fn.invoke_arn,
    )
    aws.apigatewayv2.Route(
        f"cybermoon-route-{route_key.lstrip('$')}",
        api_id=api.id,
        route_key=route_key,
        target=integration.id.apply(lambda i: f"integrations/{i}"),
    )
    aws.lambda_.Permission(
        f"cybermoon-perm-{route_key.lstrip('$')}",
        action="lambda:InvokeFunction",
        function=fn.name,
        principal="apigateway.amazonaws.com",
        source_arn=api.execution_arn.apply(lambda arn: f"{arn}/*/*"),
    )

make_route("$connect",          fn_connect)
make_route("$disconnect",       fn_disconnect)
make_route("entrar",            fn_entrar)
make_route("chat",              fn_chat)
make_route("convidar",          fn_convidar)
make_route("responder_convite", fn_resp)
make_route("sair_da_sala",      fn_sair)
make_route("iniciar_dungeon",   fn_iniciar)
make_route("sala",              fn_sala)
```

Criar o Stage e o deployment:

```python
stage = aws.apigatewayv2.Stage("cybermoon-prod",
    api_id=api.id,
    name="prod",
    auto_deploy=True,
    tags=common_tags,
)
pulumi.export("wss_url", stage.invoke_url)
```

A URL exportada (`wss://...`) vai para `game/resources/rede/configuracao.tres` quando
for ligar o jogo a AWS.

Apos o `pulumi up`, atualizar a policy inline da IAM Role para incluir o ARN do API GW
(`execute-api:ManageConnections` no `arn:aws:execute-api:<regiao>:<conta>:<api-id>/*`).
Pode deixar `*` no ARN por enquanto para nao criar dependencia ciclica.

### Tarefa 3.7: Verificacao manual da Sprint 3

1. `cd pulumi-start-aws && pulumi up` sem erros.
2. Conectar com `wscat -c <wss_url>` ou `websocat`.
3. Mandar `{"action":"entrar","nome":"Ana"}` e conferir `bem_vindo`.
4. Abrir segunda conexao com `Beto` e conferir `jogador_entrou` na primeira.
5. Mandar `{"action":"chat","texto":"oi"}` e ver chegar nas duas.
6. Fechar a segunda conexao e ver `jogador_saiu`.

---

## Sprint 4: VPC, Cognito e SES

**Meta:** as Lambdas ficam numa VPC privada (seguranca de rede), o jogo so conecta com
token JWT valido do Cognito (autenticacao), e o cadastro dispara um e-mail de boas-vindas
via SES.

### Tarefa 4.1: VPC dedicada (via Pulumi)

Criar a VPC e subnets. Usar `pulumi_aws.ec2`:

```python
vpc = aws.ec2.Vpc("cybermoon-vpc",
    cidr_block="10.0.0.0/16",
    enable_dns_hostnames=True,
    enable_dns_support=True,
    tags={**common_tags, "Name": "cybermoon-vpc"},
)

# Duas subnets privadas em AZs diferentes (para Lambda em VPC exigir pelo menos 2).
subnet_a = aws.ec2.Subnet("cybermoon-subnet-a",
    vpc_id=vpc.id,
    cidr_block="10.0.1.0/24",
    availability_zone="sa-east-1a",
    tags={**common_tags, "Name": "cybermoon-subnet-a"},
)
subnet_b = aws.ec2.Subnet("cybermoon-subnet-b",
    vpc_id=vpc.id,
    cidr_block="10.0.2.0/24",
    availability_zone="sa-east-1b",
    tags={**common_tags, "Name": "cybermoon-subnet-b"},
)

# Security group para as Lambdas: saida liberada, entrada bloqueada.
lambda_sg = aws.ec2.SecurityGroup("cybermoon-lambda-sg",
    vpc_id=vpc.id,
    description="Security group das Lambdas do chat",
    egress=[{"protocol": "-1", "from_port": 0, "to_port": 0,
             "cidr_blocks": ["0.0.0.0/0"]}],
    tags={**common_tags, "Name": "cybermoon-lambda-sg"},
)
```

Adicionar VPC Endpoint para o DynamoDB (tipo Gateway) para que as Lambdas acessem o
banco sem sair para a internet:

```python
route_table = aws.ec2.RouteTable("cybermoon-rt",
    vpc_id=vpc.id,
    tags={**common_tags, "Name": "cybermoon-rt"},
)
aws.ec2.RouteTableAssociation("cybermoon-rt-a", subnet_id=subnet_a.id, route_table_id=route_table.id)
aws.ec2.RouteTableAssociation("cybermoon-rt-b", subnet_id=subnet_b.id, route_table_id=route_table.id)

aws.ec2.VpcEndpoint("cybermoon-dynamo-endpoint",
    vpc_id=vpc.id,
    service_name=pulumi.Output.concat("com.amazonaws.", aws.get_region().name, ".dynamodb"),
    vpc_endpoint_type="Gateway",
    route_table_ids=[route_table.id],
    tags={**common_tags, "Name": "cybermoon-dynamo-endpoint"},
)
```

Atualizar todas as `aws.lambda_.Function` da Sprint 3 para incluir:

```python
vpc_config={
    "subnet_ids": [subnet_a.id, subnet_b.id],
    "security_group_ids": [lambda_sg.id],
},
```

Adicionar a policy gerenciada `AWSLambdaVPCAccessExecutionRole` na Role das Lambdas
(ela inclui as permissoes de ENI necessarias para Lambda em VPC).

### Tarefa 4.2: Cognito User Pool (via Pulumi)

Criar o User Pool com login por e-mail:

```python
user_pool = aws.cognito.UserPool("cybermoon-users",
    name="cybermoon-users",
    username_attributes=["email"],
    auto_verified_attributes=["email"],
    password_policy={
        "minimum_length": 8,
        "require_lowercase": True,
        "require_numbers": True,
        "require_symbols": False,
        "require_uppercase": False,
    },
    schema=[{
        "name": "nome",
        "attribute_data_type": "String",
        "mutable": True,
        "required": False,
        "string_attribute_constraints": {"min_length": "1", "max_length": "20"},
    }],
    tags=common_tags,
)

app_client = aws.cognito.UserPoolClient("cybermoon-client",
    name="cybermoon-game-client",
    user_pool_id=user_pool.id,
    generate_secret=False,           # sem segredo; o jogo WebGL nao consegue esconder
    explicit_auth_flows=[
        "ALLOW_USER_PASSWORD_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH",
    ],
)

pulumi.export("cognito_user_pool_id",  user_pool.id)
pulumi.export("cognito_client_id",     app_client.id)
pulumi.export("cognito_jwks_url",
    user_pool.id.apply(
        lambda uid: f"https://cognito-idp.sa-east-1.amazonaws.com/{uid}/.well-known/jwks.json"
    )
)
```

**Provedor de identidade federado com Google (opcional, para o jogo final):**
Quando ativado, o `sub` do token passa a ser o `player_id` e o `nome` vem do perfil
Google. Requer configurar OAuth 2.0 no Google Cloud Console e registrar o `client_id`
e `client_secret` no Cognito (`aws.cognito.IdentityProvider`). Por ora, deixar como
tarefa futura anotada no codigo.

### Tarefa 4.3: Lambda Authorizer para o $connect

Criar `lambdas/authorizer.py`:

```python
import os, json, urllib.request
from jose import jwk, jwt  # python-jose, adicionar ao pyproject.toml

JWKS_URL = os.environ["COGNITO_JWKS_URL"]
CLIENT_ID = os.environ["COGNITO_CLIENT_ID"]
_keys = None

def _get_keys():
    global _keys
    if _keys is None:
        with urllib.request.urlopen(JWKS_URL) as r:
            _keys = json.loads(r.read())["keys"]
    return _keys

def handler(event, context):
    token = event.get("queryStringParameters", {}).get("token", "")
    try:
        header = jwt.get_unverified_header(token)
        key = next(k for k in _get_keys() if k["kid"] == header["kid"])
        claims = jwt.decode(token, jwk.construct(key), algorithms=["RS256"],
                            audience=CLIENT_ID)
        connection_id = event["requestContext"]["connectionId"]
        return {
            "principalId": claims["sub"],
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [{"Action": "execute-api:Invoke", "Effect": "Allow",
                               "Resource": event["methodArn"]}],
            },
            "context": {"nome": claims.get("custom:nome", "Jogador")},
        }
    except Exception:
        raise Exception("Unauthorized")
```

Adicionar `python-jose[cryptography]` em `pyproject.toml`.

Registrar no Pulumi:

```python
fn_authorizer = make_lambda("authorizer", "authorizer",
    extra_env={
        "COGNITO_JWKS_URL": cognito_jwks_url,
        "COGNITO_CLIENT_ID": app_client.id,
    }
)

authorizer = aws.apigatewayv2.Authorizer("cybermoon-authorizer",
    api_id=api.id,
    authorizer_type="REQUEST",
    authorizer_uri=fn_authorizer.invoke_arn,
    identity_sources=["route.request.querystring.token"],
    name="cognito-jwt-authorizer",
)
```

Atualizar a rota `$connect` para usar o authorizer:

```python
aws.apigatewayv2.Route("cybermoon-route-connect",
    api_id=api.id,
    route_key="$connect",
    target=...,
    authorization_type="CUSTOM",
    authorizer_id=authorizer.id,
)
```

O jogo passa o token na query string: `wss://<url>/prod?token=<jwt>`. O `NetworkManager`
ja suporta query string no endereco.

### Tarefa 4.4: SES - Boas-vindas por e-mail

Verificar a identidade de e-mail (ou dominio) no SES via Pulumi:

```python
# Verificar o dominio (recomendado) ou um e-mail especifico.
ses_identity = aws.ses.DomainIdentity("cybermoon-ses",
    domain="cyber-moon.negoci.online",
)
# Em sandbox, verificar tambem o e-mail de destino para testes.
```

Criar `lambdas/boas_vindas.py` (trigger de Post Confirmation do Cognito):

```python
import os, boto3

SES_FROM = os.environ["SES_FROM_EMAIL"]
ses = boto3.client("ses", region_name="sa-east-1")

def handler(event, context):
    email = event["request"]["userAttributes"]["email"]
    nome  = event["request"]["userAttributes"].get("custom:nome", "Jogador")
    ses.send_email(
        Source=SES_FROM,
        Destination={"ToAddresses": [email]},
        Message={
            "Subject": {"Data": "Bem-vindo ao CyberMoon!"},
            "Body": {"Text": {"Data":
                f"Ola, {nome}!\n\nSua conta no CyberMoon foi criada com sucesso.\n"
                "Entre no jogo e abra o chat com Enter ou T.\n\nBoa jornada!"
            }},
        },
    )
    return event   # obrigatorio: o Cognito espera o evento de volta
```

Registrar no Pulumi e conectar ao Cognito:

```python
fn_boas_vindas = make_lambda("boas-vindas", "boas_vindas",
    extra_env={"SES_FROM_EMAIL": "noreply@cyber-moon.negoci.online"}
)

# Permissao para o Cognito invocar a Lambda.
aws.lambda_.Permission("cybermoon-cognito-perm",
    action="lambda:InvokeFunction",
    function=fn_boas_vindas.name,
    principal="cognito-idp.amazonaws.com",
    source_arn=user_pool.arn,
)

# Recriar o User Pool com o trigger (o Pulumi atualiza o recurso existente).
# Adicionar ao user_pool:
#   lambda_config={"post_confirmation": fn_boas_vindas.arn}
```

Adicionar permissao `ses:SendEmail` na IAM Role da Lambda `boas-vindas`.

### Tarefa 4.5: Verificacao manual da Sprint 4

1. `pulumi up` sem erros.
2. Criar conta no Cognito via AWS Console (ou `aws cognito-idp sign-up ...`).
3. Confirmar a conta e checar se o e-mail de boas-vindas chegou.
4. Obter token JWT (`aws cognito-idp initiate-auth ...`) e conectar:
   `wscat -c "<wss_url>?token=<jwt>"`.
5. Sem token valido, a conexao deve ser recusada (403).
6. Com token valido, mandar `{"action":"entrar","nome":"Ana"}` e conferir `bem_vindo`.

---

## Sprint 5: CI/CD - Testes e Deploy Automatizado

**Meta:** qualquer push na `main` roda os testes das Lambdas e, se passarem, faz deploy
automatico da infraestrutura e do jogo WebGL.

### Tarefa 5.1: Testes das Lambdas com pytest e moto

Criar estrutura de testes em `pulumi-start-aws/tests/`:

```
pulumi-start-aws/
  tests/
    __init__.py
    conftest.py
    test_on_connect.py
    test_on_disconnect.py
    test_on_entrar.py
    test_on_chat.py
    test_sala.py
```

Adicionar dependencias de desenvolvimento em `pyproject.toml`:

```toml
[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "moto[dynamodb]>=5.0",
    "boto3>=1.34",
]
```

**`tests/conftest.py`** - fixtures compartilhadas:

```python
import os, boto3, pytest
from moto import mock_aws

@pytest.fixture
def aws_env(monkeypatch):
    """Seta variaveis de ambiente e moca a AWS antes de cada teste."""
    monkeypatch.setenv("AWS_DEFAULT_REGION", "sa-east-1")
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "test")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "test")

@pytest.fixture
def tables(aws_env):
    """Cria as tabelas DynamoDB mockadas e devolve os clientes boto3."""
    with mock_aws():
        ddb = boto3.resource("dynamodb", region_name="sa-east-1")
        conn_table = ddb.create_table(
            TableName="conexoes",
            KeySchema=[{"AttributeName": "connection_id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "connection_id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        rooms_table = ddb.create_table(
            TableName="salas",
            KeySchema=[{"AttributeName": "sala_id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "sala_id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )
        os.environ["CONEXOES_TABLE"] = "conexoes"
        os.environ["SALAS_TABLE"]    = "salas"
        yield conn_table, rooms_table
```

**Exemplos de testes a cobrir:**

- `test_on_connect.py`: chamar `on_connect.handler(event, {})` e verificar que o item
  foi inserido na tabela de conexoes com `nome=None` e `sala=None`.
- `test_on_disconnect.py`: inserir conexao com nome, chamar disconnect, verificar que
  o item foi deletado.
- `test_on_entrar.py`: inserir conexao sem nome, chamar `on_entrar.handler`, verificar
  que `nome` foi atualizado e que a resposta bem_vindo foi enviada (mockar o
  `boto3.client("apigatewaymanagementapi")`).
- `test_on_chat.py`: inserir duas conexoes com nome, chamar `on_chat.handler`, verificar
  que `post_to_connection` foi chamado duas vezes com o JSON certo.
- `test_sala.py`: fluxo completo de convite e aceite em memoria.

Rodar localmente:

```bash
cd pulumi-start-aws
uv run pytest tests/ -v
```

### Tarefa 5.2: Workflow de CI (GitHub Actions)

Criar `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Instalar uv
        uses: astral-sh/setup-uv@v4
        with:
          version: "latest"

      - name: Instalar dependencias
        run: uv sync --extra dev
        working-directory: pulumi-start-aws

      - name: Rodar testes das Lambdas
        run: uv run pytest tests/ -v --tb=short
        working-directory: pulumi-start-aws

      - name: Checar formatacao (ruff)
        run: uv run ruff check lambdas/ tests/
        working-directory: pulumi-start-aws
```

Adicionar `ruff` em `[project.optional-dependencies] dev` para linting.

O CI bloqueia merges se algum teste falhar (configurar Branch Protection Rule no GitHub:
"Require status checks to pass before merging" -> selecionar o job `test`).

### Tarefa 5.3: Workflow de CD - Deploy de Infraestrutura (GitHub Actions)

Criar `.github/workflows/cd-infra.yml`:

```yaml
name: CD - Infraestrutura

on:
  push:
    branches: [main]
    paths:
      - "pulumi-start-aws/**"

permissions:
  id-token: write   # necessario para OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configurar credenciais AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: sa-east-1

      - name: Instalar uv
        uses: astral-sh/setup-uv@v4

      - name: Instalar Pulumi CLI
        uses: pulumi/actions@v5

      - name: Deploy da infraestrutura
        run: pulumi up --yes --stack prod
        working-directory: pulumi-start-aws
        env:
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
```

**Configurar OIDC na AWS (fazer uma vez via Console ou CLI):**

1. Criar um OIDC Provider em IAM:
   - URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
2. Criar uma IAM Role `cybermoon-github-deploy` com trust policy para o repositorio:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Principal": {"Federated": "arn:aws:iam::<CONTA>:oidc-provider/token.actions.githubusercontent.com"},
       "Action": "sts:AssumeRoleWithWebIdentity",
       "Condition": {
         "StringEquals": {"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"},
         "StringLike":   {"token.actions.githubusercontent.com:sub": "repo:<ORG>/cyber-moon:*"}
       }
     }]
   }
   ```
3. Anexar policies de permissao suficientes para o Pulumi criar todos os recursos
   (DynamoDB, Lambda, IAM, API GW, EC2 VPC, Cognito, SES).
4. Salvar o ARN da Role em `Settings > Secrets > Actions` como `AWS_DEPLOY_ROLE_ARN`.
5. Criar token no Pulumi Cloud e salvar como `PULUMI_ACCESS_TOKEN`.

### Tarefa 5.4: Workflow de CD - Deploy do Jogo WebGL (GitHub Actions)

Criar `.github/workflows/cd-jogo.yml`:

```yaml
name: CD - Jogo WebGL

on:
  push:
    branches: [main]
    paths:
      - "game/**"

permissions:
  id-token: write
  contents: read

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - name: Configurar credenciais AWS via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: sa-east-1

      - name: Instalar Godot headless
        run: |
          wget -q https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_linux.x86_64.zip
          unzip -q Godot_v4.4-stable_linux.x86_64.zip
          mv Godot_v4.4-stable_linux.x86_64 /usr/local/bin/godot
          chmod +x /usr/local/bin/godot
          mkdir -p ~/.config/godot
          wget -q https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_export_templates.tpz
          mkdir -p ~/.local/share/godot/export_templates/4.4.stable
          unzip -q Godot_v4.4-stable_export_templates.tpz -d /tmp/templates
          mv /tmp/templates/templates/* ~/.local/share/godot/export_templates/4.4.stable/

      - name: Exportar para WebGL
        run: |
          mkdir -p build/web
          godot --headless --path game --export-release "Web" ../build/web/index.html

      - name: Enviar para S3
        run: |
          BUCKET=$(cd pulumi-start-aws && pulumi stack output builds_bucket_name --stack prod)
          aws s3 sync build/web/ s3://$BUCKET/ --delete \
            --cache-control "max-age=3600" \
            --exclude "*.html" \
            --exclude "*.js"
          # HTML e JS sem cache para sempre pegar a versao mais nova.
          aws s3 sync build/web/ s3://$BUCKET/ \
            --include "*.html" --include "*.js" \
            --cache-control "no-cache, no-store"
        env:
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
```

**Observacao:** o bucket criado nas sprints 1 e 2 e privado. Se for servir o WebGL
publicamente, sera necessario adicionar um CloudFront na frente (tarefa futura). Por
enquanto o upload funciona e o arquivo pode ser acessado com URL pre-assinada.

### Tarefa 5.5: Verificacao final da Sprint 5

1. Abrir um Pull Request com qualquer mudanca em `pulumi-start-aws/`.
2. Conferir que o CI roda e os testes passam no Actions.
3. Fazer merge e conferir que o CD dispara `pulumi up` automaticamente.
4. Fazer um push em `game/` e conferir o build e upload para o S3.

---

## Resumo dos servicos AWS e onde aparecem

| Servico | Funcao | Sprint |
|---|---|---|
| **S3** | Bucket privado para builds WebGL exportados pelo Godot | 1 e 2 |
| **Route53** | Zona DNS `cyber-moon.negoci.online` (so em prod) | 1 e 2 |
| **DynamoDB** | Tabelas `cybermoon-conexoes` e `cybermoon-salas` | 3 |
| **Lambda** | 9 funcoes (connect, disconnect, entrar, chat, convidar, responder_convite, sair_da_sala, iniciar_dungeon, sala) + authorizer + boas-vindas | 3 e 4 |
| **API Gateway WebSocket** | Gerencia conexoes persistentes e roteia mensagens pelas 9 rotas | 3 |
| **IAM** | Roles e policies para Lambda, GitHub Actions OIDC | 3 e 5 |
| **VPC** | Rede privada com subnets, security group e VPC Endpoint DynamoDB | 4 |
| **Cognito** | User Pool com login por e-mail; JWT para autenticar a conexao WebSocket | 4 |
| **SES** | E-mail de boas-vindas disparado pelo Post Confirmation trigger do Cognito | 4 |
| **CloudWatch** | Logs automaticos das Lambdas (via AWSLambdaBasicExecutionRole) | todas |
| **GitHub Actions** | CI: testes pytest + ruff; CD: `pulumi up` e build/deploy do jogo | 5 |
