# Plano 18: Chat entre jogadores (CyberMoon Chat)

**Prioridade.** Feature de nuvem para a disciplina de Infraestrutura e Serviços de Nuvem.
Não depende de nenhum dos planos 01 a 17 e pode ser feita em paralelo. O lado do jogo já
foi feito nos planos 21 e 22.

**Objetivo:** jogadores conectados conversam em tempo real num chat global e jogam a
dungeon em equipe, com as mensagens passando por conexões WebSocket do AWS API Gateway.

**Abordagem:** infraestrutura serverless provisionada como código com **Pulumi** (Python,
uv), em `pulumi-start-aws/`. Na AWS: API Gateway WebSocket, Lambda, DynamoDB, e na sprint 4
VPC, Cognito e SES. O jogo fala hoje com um servidor local que imita o API Gateway
(`backend/servidor_local/servidor.py`), e as Lambdas precisam se comportar igual a ele.

---

## Revisão de 2026-10-13 (vale sobre as versões anteriores)

A versão anterior deste plano foi revisada contra o código do jogo, o `servidor.py` e o
`pulumi_aws` 7.48 instalado. O que mudou, e por quê:

- **Empacotamento.** Cada Lambda levava só o próprio arquivo, e o `utils.py` ficava de
  fora. Agora a pasta `lambdas/` inteira vai em todas as funções.
- **Regras que faltavam.** Antes do `entrar` nenhuma outra rota vale; só o anfitrião
  convida; quem cria a sala recebe `sala_atualizada`; quem aceita um convite sai da sala
  anterior. Sem a terceira, o anfitrião não via a própria sala no lobby.
- **Conexão que caiu sem avisar.** O envio para ela levanta `GoneException`. Sem tratar,
  uma conexão fantasma interrompia o envio para todos os outros.
- **Duas Lambdas na mesma sala ao mesmo tempo.** As gravações agora são condicionais, para
  uma não apagar o que a outra acabou de gravar.
- **Rota `ping`.** O API Gateway fecha a conexão que fica 10 minutos sem mensagem. O jogo
  precisa mandar um `ping` de tempos em tempos (ver "Mudanças no jogo").
- **VPC.** Com as Lambdas em sub-rede privada e só o endpoint do DynamoDB, elas não
  alcançavam o API Gateway para enviar mensagens, e o chat parava inteiro. A VPC agora tem
  NAT, e fica atrás de uma chave de configuração porque o NAT é cobrado por hora.
- **Login.** O authorizer não tinha permissão de ser chamado, a biblioteca de JWT não ia
  no pacote, e o jogo não tem tela de login. O login também ficou atrás de uma chave, para
  o chat continuar funcionando até o lado do jogo existir.
- **SES.** Faltavam os registros de DNS que verificam o domínio, e uma falha no e-mail
  derrubava o cadastro do jogador.
- **Nomes de argumento.** `schema` do User Pool é `schemas`, e `aws.get_region().name`
  está depreciado (é `.region`).
- **Sprint 5 (testes, CI e CD).** Fica para depois. O texto foi corrigido e está no fim,
  marcado como futuro.

O código deste plano foi conferido antes de ser escrito aqui: o programa do Pulumi rodou
com mocks nas combinações de stack e de chaves, e as Lambdas passaram num roteiro igual ao
do `testar_protocolo.py`, contra um DynamoDB de mentira (moto). Nada foi executado na AWS
de verdade, então a verificação manual de cada sprint continua valendo.

---

## O que já existe

Conferido em 2026-10-13.

- `pulumi-start-aws/__main__.py`: bucket S3 privado com versionamento e bloqueio de acesso
  público, e a zona Route53 de `cyber-moon.negoci.online` (só no stack `prod`). Exporta
  `builds_bucket_name`.
- No Pulumi Cloud existe só o stack `anthyer-ifsc/cybermoon/prod`, e ele está com **zero
  recursos**: o código das sprints 1 e 2 está escrito, mas não há nada no ar. O stack
  `dev` ainda não foi criado.
- `backend/servidor_local/servidor.py`: a referência do protocolo.
  `backend/servidor_local/testar_protocolo.py` confere todas as rotas.
- No jogo: `NetworkManager`, `ChatManager`, `HudChat` e `LobbyManager` prontos.

## Decisões desta revisão

Propostas na revisão de 2026-10-13. Quem discordar de alguma muda aqui antes de implementar.

- **Desenvolver no stack `dev`.** O `prod` só recebe o que já funcionou no `dev`.
  ```bash
  cd pulumi-start-aws
  pulumi stack init anthyer-ifsc/dev
  ```
- **O id do jogador na AWS é o `connectionId`** do API Gateway. No servidor local é `j1`,
  `j2`. O jogo trata o id como texto qualquer, então nada muda nele.
- **As partes da sprint 4 ligam por configuração**, uma de cada vez:

  | Chave | O que liga | Padrão |
  |---|---|---|
  | `usar_vpc` | Lambdas das rotas dentro da VPC, com NAT | desligado |
  | `exigir_login` | o `$connect` só aceita quem manda um token do Cognito | desligado |
  | `ses_remetente` | e-mail de boas-vindas, assinado por este endereço | sem e-mail |

  ```bash
  pulumi config set usar_vpc true
  pulumi config set exigir_login true
  pulumi config set ses_remetente noreply@cyber-moon.negoci.online
  ```
- **Não há tabela de mensagens.** O servidor local não guarda histórico e o jogo não tem
  como rolar o chat para trás.
- **Login com a conta Google** é pedido do Antonio para o jogo final. No Cognito é um
  provedor de identidade federado no mesmo User Pool (`aws.cognito.IdentityProvider`), e
  entra depois que o login por e-mail e senha estiver funcionando no jogo.

## O protocolo

A tabela das rotas e dos campos está em `equipe/planos/21-rede-e-chat.md`, seção "O
protocolo", e vale o que o `servidor.py` faz. Aqui só o que é próprio da AWS:

| Rota no API Gateway | Arquivo | Quando roda |
|---|---|---|
| `$connect` | `on_connect.py` | o jogo abriu a conexão |
| `$disconnect` | `on_disconnect.py` | a conexão fechou (o aviso pode atrasar ou não vir) |
| `entrar` | `on_entrar.py` | |
| `chat` | `on_chat.py` | |
| `convidar` | `on_convidar.py` | |
| `responder_convite` | `on_responder_convite.py` | |
| `sair_da_sala` | `on_sair_da_sala.py` | |
| `iniciar_dungeon` | `on_iniciar_dungeon.py` | |
| `sala` | `on_sala.py` | |
| `ping` | `on_ping.py` | rota nova, só mantém a conexão viva |

O campo `action` da mensagem escolhe a rota (`route_selection_expression` igual a
`$request.body.action`). Mensagem com `action` desconhecida recebe do API Gateway uma
resposta de erro sem o campo `tipo`, que o `NetworkManager` já ignora.

## Mudanças no jogo que este plano exige

São três. As duas primeiras **já estão feitas** (2026-10-13), a terceira não.

1. **Ping (feito).** `ConfiguracaoDeRede` tem o campo `segundos_entre_pings` (padrão
   300). O `NetworkManager` conta o tempo desde a última mensagem enviada e, passado o
   intervalo, chama `enviar("ping")`. O servidor local e o `testar_protocolo.py` já
   conhecem a rota, e ela está na tabela do plano 21.
2. **Endereço da nuvem (feito).** Trocar `endereco` no `configuracao.tres` quebraria o
   desenvolvimento local de todo mundo, e no navegador não existe argumento de linha de
   comando. `ConfiguracaoDeRede` tem o campo `endereco_na_nuvem` (vazio por padrão), e o
   `NetworkManager` usa ele quando `OS.has_feature("web")` e o campo não está vazio.
   **Falta só preencher** com o `wss_url` que o Pulumi exporta, depois do primeiro
   `pulumi up`. Não foi testado num jogo exportado, porque ainda não há preset de
   exportação para a Web (tarefa 5.3).
3. **Login (feito em 2026-10-21, plano 36)**, só para ligar `exigir_login`. Está na
   tarefa 4.5.

Para testar o jogo de desktop contra a AWS antes de existir a exportação para a Web,
passe o endereço na linha de comando:
`godot --path game -- --nome=Ana --servidor=<wss_url>`.

**Partículas.** Não se aplica: este plano não cria ação de jogo.

---

## Sprint 3: Banco de dados, Lambdas e API Gateway WebSocket

**Meta:** o jogo conecta na AWS e troca mensagens em tempo real, com a conexão aberta
(sem login). As tabelas guardam conexões e salas como o servidor local guarda em memória.

### Tarefa 3.1: Arrumar a pasta

```
pulumi-start-aws/
  lambdas/
    utils.py
    on_connect.py
    on_disconnect.py
    on_entrar.py
    on_chat.py
    on_convidar.py
    on_responder_convite.py
    on_sair_da_sala.py
    on_iniciar_dungeon.py
    on_sala.py
    on_ping.py
  __main__.py        (já existe, vai crescer)
```

- Trocar o `README.md` da pasta, que ainda é o do template em inglês, por um curto em
  português: o que a pasta provisiona, como criar o stack, as três chaves de configuração
  e os valores exportados.
- Acrescentar ao `pulumi-start-aws/.gitignore`: `.venv/`, `__pycache__/` e `build/`.
- No topo do `__main__.py`, acrescentar `import json` e `import pulumi_aws as aws`.

Cada arquivo `lambdas/on_*.py` tem uma função `handler(event, context)`. Numa rota
WebSocket, o `event` traz:

- `event["requestContext"]["connectionId"]`: a conexão que mandou a mensagem.
- `event["requestContext"]["domainName"]` e `["stage"]`: montam o endereço de retorno.
- `event["body"]`: o JSON que o jogo mandou, como texto.

### Tarefa 3.2: Configuração e tabelas

Depois do bloco da zona DNS, antes do `pulumi.export` do bucket:

```python
config = pulumi.Config()
# Ligam as partes da sprint 4. Desligadas, o chat funciona aberto e fora da VPC.
use_vpc = config.get_bool('usar_vpc') or False
require_login = config.get_bool('exigir_login') or False
# Endereço que assina o e-mail de boas-vindas. Sem ele, o e-mail não é enviado.
ses_sender = config.get('ses_remetente')

region = aws.get_region().region
stack = pulumi.get_stack()
```

Em seguida:

```python
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
```

Só a chave é declarada. Os outros atributos (`nome`, `sala`, `anfitriao`, `membros`,
`convidados`, `expira_em`) existem só nos itens. Um atributo que não tem valor **não é
gravado**: conexão sem nome é item sem o atributo `nome`, e é assim que as Lambdas sabem
quem já entrou.

### Tarefa 3.3: A API e a role das Lambdas

A API é criada antes da role porque a permissão de enviar mensagens aponta para ela. Não
há dependência cíclica: a policy é um recurso separado da role.

```python
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
    policy=pulumi.Output.all(connections_table.arn, rooms_table.arn, api.execution_arn).apply(routes_policy),
)
```

### Tarefa 3.4: A função que cria as Lambdas

```python
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
```

As variáveis `CONEXOES_TABLE` e `SALAS_TABLE` levam o nome físico das tabelas, porque o
Pulumi acrescenta um sufixo aleatório ao nome lógico.

### Tarefa 3.5: Rotas, permissões e estágio

Este bloco fica **no fim do arquivo**, depois de tudo que a sprint 4 acrescentar, porque
ele usa `authorizer` e `lambda_vpc_config`.

```python
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
    function = make_lambda(slug, module, routes_role, in_vpc=True)
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
```

### Tarefa 3.6: O módulo compartilhado

`lambdas/utils.py`, inteiro. É onde estão as partes delicadas: o envio que sobrevive a
uma conexão morta e as gravações condicionais da sala.

```python
"""O que as Lambdas do chat dividem: ler a mensagem, enviar, ler conexão e sair de sala."""

import json
import os
import time

import boto3
from botocore.exceptions import ClientError

MAX_NAME_LENGTH = 20
MAX_CHAT_LENGTH = 200
# Quantas vezes tentar de novo quando outra Lambda mexeu na mesma sala ao mesmo tempo.
MAX_ATTEMPTS = 3
# Uma conexão do API Gateway dura no máximo 2 horas. Depois de 3, o DynamoDB apaga
# sozinho o que tiver sobrado de uma conexão que caiu sem avisar.
SECONDS_TO_EXPIRE = 3 * 60 * 60
OK = {'statusCode': 200}

_dynamodb = boto3.resource('dynamodb')
connections = _dynamodb.Table(os.environ['CONEXOES_TABLE'])
rooms = _dynamodb.Table(os.environ['SALAS_TABLE'])
# Um cliente por endereço de retorno, reaproveitado entre uma chamada e outra.
_api_clients = {}


def api_client(event):
    """O cliente que manda mensagens de volta pelas conexões abertas no API Gateway."""
    request = event['requestContext']
    endpoint = f"https://{request['domainName']}/{request['stage']}"
    if endpoint not in _api_clients:
        _api_clients[endpoint] = boto3.client('apigatewaymanagementapi', endpoint_url=endpoint)
    return _api_clients[endpoint]


def read_body(event):
    """O JSON que o jogo mandou. Mensagem que não é um objeto JSON vira dicionário vazio."""
    try:
        body = json.loads(event.get('body') or '{}')
    except json.JSONDecodeError:
        return {}
    return body if isinstance(body, dict) else {}


def expiration():
    return int(time.time()) + SECONDS_TO_EXPIRE


def condition_failed(error):
    return error.response['Error']['Code'] == 'ConditionalCheckFailedException'


def send(api, connection_id, message_type, **fields):
    """Manda uma mensagem a uma conexão. Conexão que já caiu é apagada da tabela."""
    data = json.dumps({'tipo': message_type, **fields}).encode()
    try:
        api.post_to_connection(ConnectionId=connection_id, Data=data)
    except api.exceptions.GoneException:
        connections.delete_item(Key={'connection_id': connection_id})


def get_connection(connection_id):
    """O item da conexão, ou None se ela não existe mais."""
    return connections.get_item(Key={'connection_id': connection_id}, ConsistentRead=True).get('Item')


def get_named_connection(connection_id):
    """A conexão, só se ela já disse o nome. Antes do nome, a única rota aceita é entrar."""
    connection = get_connection(connection_id)
    if connection is None or 'nome' not in connection:
        return None
    return connection


def named_connections():
    """Todas as conexões que já disseram o nome. Lê a tabela inteira, página por página."""
    arguments = {
        'FilterExpression': 'attribute_exists(nome)',
        'ProjectionExpression': 'connection_id, nome',
        'ConsistentRead': True,
    }
    found = []
    while True:
        page = connections.scan(**arguments)
        found.extend(page['Items'])
        if 'LastEvaluatedKey' not in page:
            return found
        arguments['ExclusiveStartKey'] = page['LastEvaluatedKey']


def broadcast(api, message_type, skip=None, **fields):
    """Manda uma mensagem a todos os que já disseram o nome."""
    for connection in named_connections():
        if connection['connection_id'] != skip:
            send(api, connection['connection_id'], message_type, **fields)


def set_room_of(connection_id, room_id):
    """Anota em que sala a conexão está. None tira a sala. Conexão que já saiu é ignorada."""
    arguments = {
        'Key': {'connection_id': connection_id},
        # Sem a condição, o update_item criaria de novo o item de uma conexão que já saiu.
        'ConditionExpression': 'attribute_exists(connection_id)',
    }
    if room_id is None:
        arguments['UpdateExpression'] = 'REMOVE sala'
    else:
        arguments['UpdateExpression'] = 'SET sala = :sala'
        arguments['ExpressionAttributeValues'] = {':sala': room_id}
    try:
        connections.update_item(**arguments)
    except ClientError as error:
        if not condition_failed(error):
            raise


def get_room(room_id):
    return rooms.get_item(Key={'sala_id': room_id}, ConsistentRead=True).get('Item')


def room_summary(room):
    members = []
    for member in room['membros']:
        connection = get_connection(member) or {}
        members.append({'id': member, 'nome': connection.get('nome', '?')})
    return {'sala': room['sala_id'], 'anfitriao': room['anfitriao'], 'membros': members}


def notify_room(api, room):
    summary = room_summary(room)
    for member in room['membros']:
        send(api, member, 'sala_atualizada', **summary)


def replace_members(room, new_members):
    """Grava a nova lista de membros, só se ninguém mexeu nela desde a leitura.

    Devolve False quando outra Lambda gravou antes. Quem chamou lê a sala e tenta de novo.
    """
    try:
        rooms.update_item(
            Key={'sala_id': room['sala_id']},
            UpdateExpression='SET membros = :novos',
            ConditionExpression='membros = :lidos',
            ExpressionAttributeValues={':novos': new_members, ':lidos': room['membros']},
        )
    except ClientError as error:
        if condition_failed(error):
            return False
        raise
    return True


def leave_room(api, connection_id):
    """Tira a conexão da sala em que está. Se ela era a anfitriã, a sala acaba."""
    connection = get_connection(connection_id)
    if connection is None or 'sala' not in connection:
        return
    room_id = connection['sala']
    set_room_of(connection_id, None)
    for _ in range(MAX_ATTEMPTS):
        room = get_room(room_id)
        if room is None or connection_id not in room['membros']:
            return
        remaining = [member for member in room['membros'] if member != connection_id]
        if room['anfitriao'] == connection_id or not remaining:
            rooms.delete_item(Key={'sala_id': room_id})
            for member in remaining:
                set_room_of(member, None)
                send(api, member, 'sala_encerrada', sala=room_id)
            return
        if replace_members(room, remaining):
            room['membros'] = remaining
            notify_room(api, room)
            return
```

Três coisas para entender antes de escrever as rotas:

- `update_item` **cria o item se ele não existe**. Por isso toda atualização de conexão
  leva `ConditionExpression='attribute_exists(connection_id)'`. Sem ela, mexer numa
  conexão que já saiu criaria uma conexão fantasma.
- `membros` é uma lista, porque a ordem importa (o anfitrião é o primeiro, e a ordem
  define onde cada jogador nasce na dungeon). Lista se troca inteira, com a condição de
  que ela ainda seja a que foi lida (`replace_members`).
- `convidados` é um conjunto (String Set). `ADD` e `DELETE` mexem num elemento só, sem
  precisar ler antes. O DynamoDB não guarda conjunto vazio: quando o último convite sai,
  o atributo some, e está certo assim.

### Tarefa 3.7: A lógica de cada rota

Todas devolvem `utils.OK`. Todas, menos `on_connect`, `on_entrar` e `on_ping`, começam com
`utils.get_named_connection(connection_id)` e não fazem nada se vier `None` (é a regra
"antes do nome, só vale `entrar`" do `servidor.py`).

Um exemplo completo, para servir de molde:

```python
"""Rota chat: repassa o texto a todos os conectados, inclusive a quem mandou."""

import utils


def handler(event, context):
    connection_id = event['requestContext']['connectionId']
    sender = utils.get_named_connection(connection_id)
    if sender is None:
        return utils.OK
    text = str(utils.read_body(event).get('texto', '')).strip()[: utils.MAX_CHAT_LENGTH]
    if text:
        api = utils.api_client(event)
        utils.broadcast(api, 'chat', de=connection_id, nome=sender['nome'], texto=text)
    return utils.OK
```

**`on_connect.py`** (rota `$connect`)
- Grava o item `{"connection_id", "expira_em": utils.expiration()}`.
- Se `event["requestContext"].get("authorizer")` existir (sprint 4, com login), guarda
  também `conta` (o `principalId`) e `nome_da_conta` (o `nome`), quando não estão vazios.
- Não manda nada ao jogo: durante o `$connect` a conexão ainda não aceita mensagem.

**`on_disconnect.py`** (rota `$disconnect`)
- Lê a conexão. Se não existe mais, termina.
- `utils.leave_room`, depois apaga o item, depois, se tinha `nome`, `broadcast` de
  `jogador_saiu` (`id`, `nome`). Nesta ordem: o item é apagado antes do aviso para a
  própria conexão não receber a mensagem.

**`on_entrar.py`** (rota `entrar`)
- Lê a conexão. Se não existe, termina.
- O nome é, nesta ordem: `nome_da_conta` da conexão (quando há login), o `nome` do corpo
  sem espaços nas pontas, ou `Jogador` mais os 4 primeiros caracteres do `connectionId`.
  Corta em `MAX_NAME_LENGTH`.
- Grava o `nome` com a condição `attribute_exists(connection_id)`.
- Monta `online` com `utils.named_connections()`, tirando a própria conexão.
- Manda `bem_vindo` (`id`, `nome`, `online`) a quem entrou e `jogador_entrou` (`id`,
  `nome`) aos outros. O nome é gravado **antes** de ler a lista: assim, se dois jogadores
  entram juntos, pelo menos um deles fica sabendo do outro pelo `jogador_entrou`.

**`on_convidar.py`** (rota `convidar`)
- `para` precisa ser texto, diferente de quem convida, e uma conexão que existe.
- Se quem convida não tem `sala`: cria a sala (`sala_id` com `uuid.uuid4().hex`,
  `anfitriao`, `membros` só com ele, `expira_em`), anota a sala na conexão com
  `utils.set_room_of` e chama `utils.notify_room`. Esse `sala_atualizada` é o que faz o
  lobby do anfitrião mostrar a sala.
- Acrescenta o convidado: `UpdateExpression='ADD convidados :convidado'` com
  `ConditionExpression='anfitriao = :eu'`. A condição cobre as duas regras de uma vez: a
  sala existe, e só o anfitrião convida. Se falhar, termina sem mandar nada.
- Manda `convite` (`de`, `nome`, `sala`) ao convidado.

**`on_responder_convite.py`** (rota `responder_convite`)
- `sala` precisa ser texto.
- Gasta o convite numa operação só: `UpdateExpression='DELETE convidados :convidado'`,
  `ConditionExpression='contains(convidados, :id)'`, `ReturnValues='ALL_NEW'`. Se a
  condição falhar, a pessoa não foi convidada (ou a sala não existe): termina. É isso que
  impede alguém de entrar numa sala adivinhando o id.
- `aceita` falso: manda `convite_recusado` (`de`, `nome`) ao anfitrião e termina.
- `aceita` verdadeiro: `utils.leave_room` (sai da sala anterior), depois tenta até
  `MAX_ATTEMPTS` vezes: lê a sala, e `utils.replace_members` com ele no fim da lista.
  Quando gravar, `utils.set_room_of` e `utils.notify_room`.

**`on_sair_da_sala.py`** (rota `sair_da_sala`)
- `utils.leave_room`. A regra está toda lá: se quem saiu era o anfitrião, ou se não
  sobrou ninguém, a sala é apagada e os que ficaram recebem `sala_encerrada`. Senão, os
  que ficaram recebem `sala_atualizada`.

**`on_iniciar_dungeon.py`** (rota `iniciar_dungeon`)
- Só segue se a conexão tem `sala`, a sala existe e o `anfitriao` é quem mandou.
- Manda `dungeon_iniciada` com `utils.room_summary` a todos os membros, inclusive ele.

**`on_sala.py`** (rota `sala`)
- Só segue se a conexão tem `sala` e a sala existe.
- Repassa `sala` (`de`, `dados`) aos **outros** membros, sem olhar o que há em `dados`.
- É a rota mais chamada do jogo. Não acrescentar leitura nem gravação aqui sem medir.

**`on_ping.py`** (rota `ping`)
- Só devolve `utils.OK`.

### Tarefa 3.8: Verificação manual da sprint 3

Usar `wscat` (`npm install -g wscat`) ou `websocat`.

1. `pulumi up` no stack `dev` sem erros, e `pulumi stack output wss_url` mostra um
   endereço `wss://...amazonaws.com/dev`.
2. `wscat -c <wss_url>`, mandar `{"action":"entrar","nome":"Ana"}` e receber `bem_vindo`.
3. Segunda conexão como `Beto`: a primeira recebe `jogador_entrou`.
4. `{"action":"chat","texto":"oi"}` chega nas duas.
5. Numa terceira conexão, mandar `chat` **sem** ter mandado `entrar`: ninguém recebe.
6. Fechar a segunda: a primeira recebe `jogador_saiu`.
7. Roteiro de sala com duas conexões: `convidar` (quem convida recebe `sala_atualizada`,
   o outro recebe `convite`), `responder_convite` com `aceita` verdadeiro (as duas recebem
   `sala_atualizada` com os dois membros), `iniciar_dungeon`, uma mensagem `sala`, e
   fechar a conexão do anfitrião (o outro recebe `sala_encerrada`).
8. Abrir dois jogos com `--servidor=<wss_url>` (em uma ou duas máquinas), conversar no
   chat e jogar a dungeon juntos. Preencher `endereco_na_nuvem` no `configuracao.tres`
   com o mesmo endereço, para o jogo exportado já sair apontando para a nuvem.
9. Deixar um dos jogos aberto e parado por 12 minutos: a conexão não pode cair (é o
   `ping` funcionando).
10. Se algo não responder, o erro está no CloudWatch, no grupo de logs
    `/aws/lambda/cybermoon-fn-<rota>-<sufixo>`.

---

## Sprint 4: VPC, Cognito e SES

**Meta:** as Lambdas das rotas rodam numa rede privada, o jogo só conecta com um token
válido do Cognito, e quem cria conta recebe um e-mail de boas-vindas. Cada parte liga por
uma chave de configuração, e com todas desligadas o chat da sprint 3 continua igual.

**Onde entra cada bloco.** O `__main__.py` final fica nesta ordem:

1. imports, `common_tags`, bucket (já existem)
2. a zona DNS, alterada na tarefa 4.1
3. configuração e tabelas (3.2)
4. API e role (3.3)
5. `make_lambda` (3.4)
6. VPC (4.2)
7. SES (4.3)
8. Cognito (4.4)
9. authorizer (4.4)
10. rotas e estágio (3.5)
11. o `pulumi.export` do bucket (já existe)

### Tarefa 4.1: Guardar a zona DNS numa variável

O SES precisa criar registros na zona, e hoje ela não fica em variável nenhuma. Trocar o
bloco da zona por:

```python
DOMAIN = 'cyber-moon.negoci.online'

# Zona DNS do domínio do projeto. Só existe em produção, os outros stacks não têm domínio.
dns_zone = None
if pulumi.get_stack() == 'prod':
    dns_zone = route53.Zone(
        'cyber-moon',
        name=DOMAIN,
        tags=common_tags,
    )
```

**Antes de contar com o domínio, conferir a delegação.** A zona só responde na internet
se os quatro servidores de nome dela (campo `name_servers` da zona, ou no console do
Route53) estiverem cadastrados como registros NS de `cyber-moon` no DNS de
`negoci.online`. Sem isso, nenhum registro criado aqui é visto de fora, e o SES nunca
verifica o domínio.

### Tarefa 4.2: VPC (chave `usar_vpc`)

Uma Lambda dentro de VPC só fala com o que a rede alcança. As rotas precisam de duas
coisas: o DynamoDB, que ganha um endpoint dentro da VPC, e o API Gateway (para mandar
mensagens aos jogadores), que fica na internet e é alcançado pelo NAT.

**Custo.** O NAT é cobrado por hora ligado, mesmo sem tráfego, e é de longe o item mais
caro deste plano (confira o preço de NAT Gateway em `sa-east-1` antes de ligar). Ligar
para demonstrar e desligar depois: `pulumi config set usar_vpc false` e `pulumi up`.

```python
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
```

Uma alternativa mais barata ao NAT seria um endpoint de interface para o serviço
`execute-api`. Não foi adotada porque não encontramos confirmação de que as chamadas de
`@connections` de uma API WebSocket pública funcionam por ele, e há relatos de erro 403.
Se alguém quiser testar, o critério é o passo 2 da verificação desta sprint.

### Tarefa 4.3: SES (chave `ses_remetente`)

```python
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
```

`lambdas/boas_vindas.py`:

```python
"""Gatilho Post Confirmation do Cognito: manda o e-mail de boas-vindas pelo SES."""

import os

import boto3
from botocore.exceptions import ClientError

SENDER = os.environ['SES_REMETENTE']
ses = boto3.client('ses')


def handler(event, context):
    attributes = event['request']['userAttributes']
    name = attributes.get('custom:nome', 'Jogador')
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
```

**A conta do SES nasce em modo sandbox:** só envia para endereços verificados. Para
testar, verificar o e-mail de destino no console do SES. Para valer com qualquer
jogador, pedir a saída do sandbox no console (Account dashboard, Request production
access). Enquanto isso, a Lambda registra a falha no log e o cadastro segue normal.

### Tarefa 4.4: Cognito e o authorizer (chave `exigir_login`)

O User Pool e o cliente são criados sempre. O que a chave liga é a exigência do token no
`$connect`.

```python
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
```

`lambdas/authorizer.py`:

```python
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
```

O authorizer usa PyJWT, que precisa do `cryptography`, uma biblioteca com código
compilado. Ela tem que ser baixada na versão para o Linux da Lambda, não para a máquina
de quem faz o deploy. Antes do `pulumi up` com `exigir_login` ligado, rodar em
`pulumi-start-aws/`:

```bash
uv pip install --target build/layer/python \
  --python-platform x86_64-manylinux2014 --python-version 3.12 \
  --only-binary :all: "pyjwt[crypto]"
```

```python
if require_login:
    # O PyJWT e o cryptography não vêm no runtime da Lambda. Vão numa layer, construída
    # antes do pulumi up pelo comando da tarefa 4.4.
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
```

Pontos de atenção:

- **O token é o ID token**, não o access token. Só o ID token tem o campo `aud` e o
  `custom:nome`. O authorizer recusa os outros.
- Com login, o nome do chat vem da conta (`on_connect` guarda, `on_entrar` usa). O `nome`
  que o jogo manda no `entrar` passa a ser ignorado, para ninguém se passar por outro.
- O token vai na query string porque o navegador não deixa mandar cabeçalho numa conexão
  WebSocket. Ele vale 1 hora, e a conexão do API Gateway dura no máximo 2 horas: o jogo
  precisa renovar o token antes de reconectar.
- Enquanto a tarefa 4.5 não existir, **não ligar `exigir_login` no stack que o jogo
  usa**: o jogo não teria como conectar.

### Tarefa 4.5: Login no jogo (lado Godot)

**Feita em 2026-10-21 no plano 36** (`equipe/planos/36-login-no-jogo.md`). O botão
"Conta" do lobby abre a tela de criar conta, confirmar e entrar.

É uma feature de jogo, com tela e fluxo próprios. Vale escrever um plano separado em
`equipe/planos/` antes de implementar. O que ele precisa cobrir:

- Tela de criar conta (e-mail, senha, nome), de confirmar o código que chega por e-mail,
  e de entrar.
- As chamadas ao Cognito são `POST https://cognito-idp.sa-east-1.amazonaws.com/` com os
  cabeçalhos `Content-Type: application/x-amz-json-1.1` e `X-Amz-Target:
  AWSCognitoIdentityProviderService.<Operação>`, onde a operação é `SignUp`,
  `ConfirmSignUp` ou `InitiateAuth` (com `AuthFlow` igual a `USER_PASSWORD_AUTH`). O
  `ClientId` é o `cognito_client_id` exportado pelo Pulumi. No `SignUp`, o nome vai em
  `UserAttributes` como `custom:nome`.
- Guardar o `IdToken` e o `RefreshToken` da resposta. O `NetworkManager` acrescenta
  `?token=<IdToken>` ao endereço na hora de conectar. Hoje ele passa o endereço como
  está para o `connect_to_url`, então a mudança é pequena.
- Renovar o `IdToken` com `InitiateAuth` e `AuthFlow` igual a `REFRESH_TOKEN_AUTH` quando
  a conexão cair e o token tiver mais de 50 minutos.
- O `id` do Cognito e o `ClientId` são dados: campos novos em `ConfiguracaoDeRede`, não
  texto solto no código.

### Tarefa 4.6: Verificação manual da sprint 4

**Feita em 2026-10-21 no stack `dev`**, com as três chaves ligadas. Com a VPC, as 10
Lambdas das rotas ficaram nas sub-redes privadas e o chat respondeu como antes (`bem_vindo`
em 2 s). Sem token e com token falso, o `$connect` devolve 401. Uma conta criada pela tela
do jogo (plano 36) recebeu o código, foi confirmada, disparou o e-mail de boas-vindas, e a
conexão entrou com o nome da conta, não com o nome local do jogo. O passo do access token
no lugar do ID token não foi testado à parte; o authorizer recusa pelo `token_use`.

Uma chave por vez, com `pulumi up` e teste entre uma e outra.

1. Com tudo desligado, `pulumi up` cria o User Pool e o chat segue igual à sprint 3.
2. `usar_vpc` ligado: refazer os passos 2 a 4 da tarefa 3.8. Se `bem_vindo` não chegar em
   até 10 segundos, a Lambda não está alcançando o API Gateway (olhar o log: o sintoma é
   `Task timed out`).
3. `ses_remetente` ligado: criar uma conta com um e-mail verificado no SES e confirmar.
   O e-mail de boas-vindas chega.
   ```bash
   aws cognito-idp sign-up --client-id <cognito_client_id> --username voce@exemplo.com \
     --password 'senha1234' --user-attributes Name=custom:nome,Value=Ana
   aws cognito-idp confirm-sign-up --client-id <cognito_client_id> \
     --username voce@exemplo.com --confirmation-code <código do e-mail>
   ```
4. `exigir_login` ligado. Pegar o ID token e conectar:
   ```bash
   aws cognito-idp initiate-auth --client-id <cognito_client_id> \
     --auth-flow USER_PASSWORD_AUTH \
     --auth-parameters USERNAME=voce@exemplo.com,PASSWORD='senha1234' \
     --query AuthenticationResult.IdToken --output text
   wscat -c "<wss_url>?token=<IdToken>"
   ```
5. Sem token, ou com o access token no lugar, a conexão é recusada (401 ou 403).
6. Com o token, mandar `{"action":"entrar","nome":"Outro"}`: o `bem_vindo` traz o nome
   da conta (`Ana`), não `Outro`.

---

## Sprint 5: Testes, CI e CD (a implementar futuramente)

**Não faz parte da entrega atual.** O texto abaixo está corrigido e pronto para quando a
equipe decidir fazer. A tarefa 5.1 (testes locais) não depende das outras e pode ser
adiantada a qualquer momento: ela ajuda a escrever as Lambdas da sprint 3.

**Meta:** um push na `main` roda os testes das Lambdas e, se passarem, faz o deploy da
infraestrutura. Um push em `game/` exporta o jogo para a Web e publica.

### Tarefa 5.1: Testes das Lambdas com pytest e moto

Acrescentar ao `pulumi-start-aws/pyproject.toml`:

```toml
[dependency-groups]
dev = [
    "boto3>=1.34",
    "moto[dynamodb]>=5.0",
    "pyjwt[crypto]>=2.9",
    "pytest>=8.0",
    "ruff>=0.6",
]

[tool.pytest.ini_options]
# As Lambdas se importam pelo nome solto (import utils), como dentro da AWS.
pythonpath = ["lambdas"]

[tool.ruff]
line-length = 110
src = ["lambdas"]

[tool.ruff.lint]
select = ["E", "F", "I"]
```

`pulumi-start-aws/tests/__init__.py` vazio, e `pulumi-start-aws/tests/conftest.py`:

```python
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
```

Um teste fica assim:

```python
import on_chat
import on_connect
import on_entrar

from .conftest import call


def test_chat_chega_em_todos(api):
    for connection_id, name in (('ana', 'Ana'), ('beto', 'Beto')):
        call(on_connect, connection_id)
        call(on_entrar, connection_id, nome=name)
    call(on_chat, 'ana', texto='oi')
    assert api.last('beto', 'chat') == {'tipo': 'chat', 'de': 'ana', 'nome': 'Ana', 'texto': 'oi'}
    assert api.last('ana', 'chat')['texto'] == 'oi'
```

O que cobrir, espelhando o `testar_protocolo.py`:

- entrar e chat, com o `bem_vindo` trazendo a lista `online`;
- uma conexão que não mandou `entrar` não consegue mandar `chat`;
- convite recusado, e o convite gasto não serve uma segunda vez;
- quem não foi convidado não entra na sala, mesmo sabendo o id;
- só o anfitrião convida e inicia a dungeon;
- a rota `sala` repassa aos outros e não a quem mandou;
- o anfitrião desconecta: `sala_encerrada` e `jogador_saiu` para quem ficou;
- um membro sai e a sala continua;
- uma conexão marcada em `api.gone` não interrompe o envio aos outros e é apagada;
- `utils.replace_members` devolve `False` para quem leu a sala antes de outra gravação.

```bash
cd pulumi-start-aws
uv run ruff check lambdas tests
uv run pytest tests -v
```

### Tarefa 5.2: CI e deploy da infraestrutura

Um workflow só, `.github/workflows/ci.yml`. O deploy é um job que depende do job de
teste: em arquivos separados os dois rodariam em paralelo, e o deploy sairia mesmo com
teste falhando.

```yaml
name: CI e deploy da infraestrutura

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

# Dois deploys ao mesmo tempo brigam pelo mesmo stack. O segundo espera o primeiro.
concurrency:
  group: infra-${{ github.ref }}
  cancel-in-progress: false

jobs:
  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: pulumi-start-aws
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - name: Instalar dependências
        run: uv sync
      - name: Checar o código (ruff)
        run: uv run ruff check lambdas tests
      - name: Rodar os testes das Lambdas
        run: uv run pytest tests -v --tb=short

  deploy:
    # Só roda depois dos testes passarem, e só em push na main.
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    # Ambiente do GitHub com aprovação manual: o deploy espera alguém liberar.
    environment: prod
    permissions:
      id-token: write
      contents: read
    defaults:
      run:
        working-directory: pulumi-start-aws
    env:
      PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: sa-east-1
      - uses: astral-sh/setup-uv@v4
      # Sem o campo command, esta action só instala a CLI do Pulumi.
      - uses: pulumi/actions@v6
      - name: Construir a layer do authorizer
        run: >
          uv pip install --target build/layer/python
          --python-platform x86_64-manylinux2014 --python-version 3.12
          --only-binary :all: "pyjwt[crypto]"
      - name: Deploy da infraestrutura
        run: pulumi up --yes --stack anthyer-ifsc/cybermoon/prod
```

Configurar uma vez:

1. **Ambiente `prod` no GitHub** (Settings, Environments), com "Required reviewers". É o
   que impede um `pulumi up` em produção sem ninguém olhar. Importa porque algumas
   mudanças recriam recursos: mexer em `schemas` do User Pool, por exemplo, apaga todas
   as contas.
2. **Proteção da `main`** (Settings, Branches): exigir pull request e o check `test`.
   Hoje a `main` não tem proteção e os commits vão direto nela.
3. **OIDC na AWS**, para o GitHub assumir uma role sem chave guardada:
   - Provedor OIDC no IAM: URL `https://token.actions.githubusercontent.com`, audiência
     `sts.amazonaws.com`.
   - Role `cybermoon-github-deploy` com esta trust policy. A condição `sub` restringe ao
     ambiente `prod` deste repositório: como os jobs de deploy usam `environment: prod`,
     é esse o formato do `sub` que o GitHub manda.
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [{
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::<CONTA>:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
             "token.actions.githubusercontent.com:sub": "repo:anthyer/cyber-moon:environment:prod"
           }
         }
       }]
     }
     ```
   - Permissões da role: o Pulumi cria roles do IAM, então esta role é, na prática,
     administradora da conta. Por isso a condição acima e a aprovação manual importam.
4. Segredos em Settings, Secrets, Actions: `AWS_DEPLOY_ROLE_ARN` e `PULUMI_ACCESS_TOKEN`
   (token do Pulumi Cloud com acesso à organização `anthyer-ifsc`).

### Tarefa 5.3: Publicar o jogo na Web

Três coisas precisam existir antes do workflow:

1. **Preset de exportação.** `game/export_presets.cfg` não existe no repositório. Criar
   no editor (Projeto, Exportar, adicionar "Web", com o nome exatamente `Web`) e
   versionar o arquivo.
2. **CloudFront na frente do bucket.** O bucket é privado, e uma URL pré-assinada não
   serve para o jogo: o `index.html` busca o `.js`, o `.wasm` e o `.pck` por endereço
   relativo, sem assinatura. No Pulumi: uma distribuição `aws.cloudfront.Distribution`
   com `default_root_object` igual a `index.html`, um `OriginAccessControl` para o S3, e
   uma policy no bucket liberando `s3:GetObject` ao serviço `cloudfront.amazonaws.com`
   com a condição `AWS:SourceArn` igual ao ARN da distribuição. Exportar o endereço como
   `jogo_url`. Para usar `cyber-moon.negoci.online`, o certificado do ACM precisa ser
   criado em `us-east-1`, e a zona ganha um registro alias para a distribuição.
3. **`endereco_na_nuvem`** preenchido no `configuracao.tres` com o `wss_url` de produção.
   A página é servida por HTTPS, e o navegador só aceita `wss://` a partir dela.

`.github/workflows/cd-jogo.yml`:

```yaml
name: Deploy do jogo (Web)

on:
  push:
    branches: [main]
    paths:
      - "game/**"

concurrency:
  group: jogo-${{ github.ref }}
  cancel-in-progress: true

permissions:
  id-token: write
  contents: read

env:
  # A mesma versão do projeto (config/features em game/project.godot).
  GODOT_VERSION: "4.7.2"

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    environment: prod
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
          aws-region: sa-east-1
      - uses: pulumi/actions@v6

      - name: Instalar o Godot e os templates de exportação
        run: |
          base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
          wget -q "${base}/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
          unzip -q "Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
          sudo mv "Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot
          wget -q "${base}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
          unzip -q "Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -d /tmp/godot
          templates="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
          mkdir -p "${templates}"
          mv /tmp/godot/templates/* "${templates}/"

      # A pasta .godot não está no repositório. Sem importar antes, a exportação sai sem assets.
      - name: Importar os assets
        run: godot --headless --path game --import

      - name: Exportar para a Web
        run: |
          mkdir -p build/web
          godot --headless --path game --export-release "Web" ../build/web/index.html

      - name: Enviar para o S3
        env:
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
        run: |
          bucket=$(pulumi stack output builds_bucket_name \
            --stack anthyer-ifsc/cybermoon/prod --cwd pulumi-start-aws)
          # no-cache faz o navegador conferir a versão a cada visita, sem misturar um
          # index.js novo com um .wasm ou .pck antigo.
          aws s3 sync build/web/ "s3://${bucket}/" --delete --cache-control "no-cache"
```

### Tarefa 5.4: Verificação da sprint 5

1. Abrir um pull request mexendo em `pulumi-start-aws/`: o job `test` roda, e o `deploy`
   não.
2. Quebrar um teste de propósito no pull request: o merge fica bloqueado.
3. Fazer o merge: o `deploy` espera a aprovação no ambiente `prod` e, aprovado, roda o
   `pulumi up`.
4. Um push em `game/` exporta o jogo e publica. Abrir o `jogo_url` em dois navegadores e
   conversar no chat.

---

## Custos e limites para ter em mente

- **O canal `sala` é o que pesa.** Na dungeon, cada jogador manda 12 mensagens por
  segundo e o anfitrião mais 10 dos inimigos (`ENVIOS_DO_JOGADOR_POR_SEGUNDO` e
  `ENVIOS_DOS_INIMIGOS_POR_SEGUNDO` em `game/scripts/coop/dungeon.gd`). Uma dupla gera
  cerca de 34 mensagens por segundo, umas 120 mil execuções de Lambda por hora de jogo,
  cada uma com duas leituras no DynamoDB e um envio. O API Gateway cobra por mensagem
  recebida e por mensagem enviada. **Medir no painel de custos depois da primeira sessão
  de dungeon na AWS**, e baixar as duas constantes se for o caso.
- **A ordem das mensagens não é garantida.** Cada mensagem roda numa execução separada, e
  duas posições seguidas podem chegar trocadas. Se os jogadores remotos tremerem na
  dungeon, a solução é do lado do jogo: um contador em `dados` e descartar o que chegar
  atrasado.
- **Concorrência de Lambda.** Conta nova da AWS costuma ter limite baixo de execuções
  simultâneas. Com 4 jogadores numa dungeon dá para encostar nele. Se aparecer
  `TooManyRequestsException` nos logs, pedir aumento em Service Quotas.
- **Conexão.** O API Gateway fecha a conexão ociosa por 10 minutos (por isso o `ping`) e
  qualquer conexão depois de 2 horas. O jogo reconecta sozinho e recebe um id novo.
- **Tempo de resposta.** A primeira mensagem depois de um tempo parado é mais lenta, por
  causa da partida a frio da Lambda. Dentro da VPC, mais ainda.
- **Desligar o que não está em uso.** `pulumi destroy` no stack `dev` ao fim de um dia de
  testes, principalmente com `usar_vpc` ligado.

## Critério de pronto

Sprints 3 e 4. A sprint 5 tem verificação própria e fica para depois.

- [x] `pulumi up` no stack `dev` sobe sem erro, com as três chaves desligadas.
- [ ] Os passos 2 a 9 da tarefa 3.8 passam.
- [ ] Dois jogos conversam no chat e jogam a dungeon juntos pela AWS.
- [x] Com `usar_vpc` ligado, o chat continua funcionando.
- [x] Com `ses_remetente` definido, uma conta nova recebe o e-mail de boas-vindas.
- [x] Com `exigir_login` ligado, só conecta quem manda um ID token válido.
- [x] `README.md` de `pulumi-start-aws/` reescrito.
- [x] `endereco_na_nuvem` preenchido em `game/resources/rede/configuracao.tres` (com o
  endereço do `dev`, porque o `prod` ainda não tem nada no ar).
- [ ] O que ficou de fora está em `equipe/pendencias.md`.

## Fora de escopo

- Histórico de mensagens e mensagem privada.
- Moderação do chat.
- Login com a conta Google (anotado em "Decisões desta revisão").
- Testes automatizados, CI e CD (sprint 5, futura).
- Publicação do jogo na Web com CloudFront (tarefa 5.3, futura).

## Resumo dos serviços AWS

| Serviço | Função | Sprint |
|---|---|---|
| **S3** | Bucket privado para os builds exportados do jogo | 1 e 2 |
| **Route53** | Zona DNS `cyber-moon.negoci.online` (só em prod) e os registros do SES | 1, 2 e 4 |
| **DynamoDB** | Tabelas de conexões e de salas, com expiração automática | 3 |
| **Lambda** | 10 funções de rota, mais o authorizer e a de boas-vindas | 3 e 4 |
| **API Gateway WebSocket** | Mantém as conexões e escolhe a Lambda de cada mensagem | 3 |
| **IAM** | Uma role por tipo de Lambda, com o mínimo de permissão | 3 e 4 |
| **CloudWatch** | Logs das Lambdas | 3 |
| **VPC** | Sub-redes privadas, NAT e endpoint do DynamoDB (chave `usar_vpc`) | 4 |
| **Cognito** | Contas dos jogadores e o token que autoriza a conexão | 4 |
| **SES** | E-mail de boas-vindas na confirmação da conta | 4 |
| **CloudFront** | Serve o jogo exportado a partir do bucket privado | 5 (futura) |
| **GitHub Actions** | Testes, deploy da infraestrutura e publicação do jogo | 5 (futura) |
