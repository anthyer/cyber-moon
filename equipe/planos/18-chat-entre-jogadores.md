# Plano 18: Chat entre jogadores (CyberMoon Chat)

**Prioridade.** Feature de nuvem para a disciplina de Infraestrutura e Serviços de Nuvem.
Não depende de nenhum dos planos 01-17 para funcionar — pode ser feita em paralelo.

**Objetivo:** jogadores conectados via WebGL podem se comunicar em tempo real através de
um chat global, usando conexões WebSocket gerenciadas pelo AWS API Gateway. O jogador
abre o chat com uma tecla, digita e envia. A mensagem aparece para todos os outros
jogadores conectados em menos de 300 ms.

**Abordagem:** back-end 100% serverless na AWS (API Gateway WebSocket + Lambda +
DynamoDB + Cognito). No Godot, um autoload `ChatManager` centraliza a conexão WebSocket
e repassa mensagens via `EventBus`. A UI é um painel simples de PanelContainer com
ScrollContainer, campo de texto e botão enviar.

**Depende de:**
- Back-end AWS criado e com a URL do WebSocket disponível.
- Conta na AWS com permissões de Lambda, DynamoDB, Cognito e API Gateway.

**Entrega para:** disciplina de Infraestrutura e Serviços de Nuvem (demonstração da
integração do jogo com serviços de nuvem reais).

---

## Contexto do que existe hoje

- `game/scripts/core/event_bus.gd` é o barramento de eventos do jogo. Novos sinais
  serão adicionados aqui para o chat (`chat_mensagem_recebida`, `chat_conectado`,
  `chat_desconectado`).
- `game/scripts/core/` já tem o padrão de autoloads — `ChatManager` entra aqui.
- `game/scripts/ui/` tem scripts de UI — `chat_ui.gd` entra aqui.
- `game/scenes/ui/` tem cenas de UI — `chat.tscn` entra aqui.
- `game/project.godot` tem a lista de autoloads — `ChatManager` precisa ser registrado.
- O jogo roda em WebGL, que suporta WebSocket nativamente pelo `WebSocketPeer` do Godot 4.
- Não existe nenhum sistema de rede no projeto hoje. Este plano é o primeiro.

## Arquivos novos

- `game/scripts/core/chat_manager.gd` — autoload que gerencia a conexão WebSocket
- `game/scripts/ui/chat_ui.gd` — script do painel de chat na tela
- `game/scenes/ui/chat.tscn` — cena do painel de chat (PanelContainer com ScrollContainer)
- `backend/lambdas/on_connect.py` — Lambda que roda quando um cliente conecta
- `backend/lambdas/on_disconnect.py` — Lambda que roda quando um cliente desconecta
- `backend/lambdas/send_message.py` — Lambda que distribui mensagens para os conectados
- `backend/lambdas/authorizer.py` — Lambda autorizador que valida o token JWT do Cognito
- `backend/terraform/main.tf` — infraestrutura como código (opcional, alternativa ao console)

## Arquivos modificados

- `game/project.godot` — registrar `ChatManager` nos autoloads
- `game/scripts/core/event_bus.gd` — adicionar sinais do chat
- `game/scenes/levels/playground.tscn` — instanciar `chat.tscn` como filho do HUD

---

## Parte A — Back-end AWS

As tarefas A1 a A5 constroem toda a infraestrutura na AWS. Faça pelo console da AWS ou
pelo Terraform. O console é mais simples para começar.

---

### Tarefa A1: criar o User Pool no Amazon Cognito

O Cognito gerencia cadastro e login dos jogadores. O token JWT que ele emite é o que o
Lambda autorizador valida.

- [ ] **Passo 1.** No console AWS, vá em **Cognito -> User Pools -> Create user pool**.
- [ ] **Passo 2.** Configure:
  - Sign-in: **Email**
  - Password policy: mínimo 8 caracteres (padrão já serve)
  - MFA: **No MFA** (simplifica para o projeto acadêmico)
  - Self-service sign-up: **habilitado**
- [ ] **Passo 3.** Em **App clients**, crie um app client:
  - Nome: `cybermoon-game`
  - Auth flows: marque `ALLOW_USER_PASSWORD_AUTH` e `ALLOW_REFRESH_TOKEN_AUTH`
  - Sem client secret (o Godot/WebGL não consegue guardar segredo de forma segura)
- [ ] **Passo 4.** Anote os valores:
  - `USER_POOL_ID` (ex: `us-east-1_AbCdEfGhI`)
  - `CLIENT_ID` do app client criado
- [ ] **Passo 5.** Commit de documentação.

```bash
git add equipe/planos/18-chat-entre-jogadores.md
git commit -m "docs(chat): registra USER_POOL_ID e CLIENT_ID no plano"
```

---

### Tarefa A2: criar as tabelas no DynamoDB

Duas tabelas são necessárias: uma para conexões ativas (quem está online agora), outra
para o histórico de mensagens.

- [ ] **Passo 1.** No console AWS, vá em **DynamoDB -> Tables -> Create table**.

**Tabela `cybermoon-conexoes`:**
- Partition key: `connection_id` (String)
- Billing: On-demand (Free Tier cobre bem)

**Tabela `cybermoon-mensagens`:**
- Partition key: `sala_id` (String)
- Sort key: `enviada_em` (String — ISO 8601, ordena cronologicamente)
- Billing: On-demand
- TTL attribute: `expira_em` (apaga mensagens automaticamente após 30 dias)

- [ ] **Passo 2.** Na tabela `cybermoon-mensagens`, habilite TTL:
  - **Table settings -> Additional settings -> Time to Live -> Enable**
  - Attribute name: `expira_em`

- [ ] **Passo 3.** Commit de documentação.

```bash
git add equipe/planos/18-chat-entre-jogadores.md
git commit -m "docs(chat): registra nomes e schemas das tabelas DynamoDB"
```

---

### Tarefa A3: criar as funções Lambda

Três Lambdas de rota + um autorizador. Use Python 3.12 em todas.

- [ ] **Passo 1.** No console AWS, vá em **Lambda -> Create function** para cada uma.

**Lambda `cybermoon-chat-authorizer`** (valida o JWT do Cognito):
- Runtime: Python 3.12
- Crie o arquivo `backend/lambdas/authorizer.py` com o conteúdo abaixo e faça o upload.

```python
import json
import urllib.request
from jose import jwk, jwt
from jose.utils import base64url_decode

REGION = "us-east-1"          # troque pela sua região
USER_POOL_ID = "SEU_POOL_ID"  # preencha após a tarefa A1

JWKS_URL = f"https://cognito-idp.{REGION}.amazonaws.com/{USER_POOL_ID}/.well-known/jwks.json"

def handler(event, context):
    token = event.get("queryStringParameters", {}).get("token", "")
    try:
        with urllib.request.urlopen(JWKS_URL) as response:
            jwks = json.loads(response.read())
        claims = jwt.decode(token, jwks, algorithms=["RS256"])
        return {
            "isAuthorized": True,
            "context": {
                "player_id": claims["sub"],
                "username": claims.get("cognito:username", "anonimo")
            }
        }
    except Exception as e:
        print(f"Autorizacao falhou: {e}")
        return {"isAuthorized": False}
```

> **Dependencia Python:** instale `python-jose` na Lambda usando um Layer ou empacotando
> junto com o zip. Alternativa mais simples: use `PyJWT` com `cryptography` e ajuste o
> decode. Anote a escolha em `pendencias.md`.

**Lambda `cybermoon-chat-on-connect`:**
- Crie `backend/lambdas/on_connect.py`:

```python
import boto3
import os

dynamo = boto3.resource("dynamodb")
tabela = dynamo.Table("cybermoon-conexoes")

def handler(event, context):
    connection_id = event["requestContext"]["connectionId"]
    player_id = event["requestContext"]["authorizer"]["player_id"]
    username = event["requestContext"]["authorizer"]["username"]

    tabela.put_item(Item={
        "connection_id": connection_id,
        "player_id": player_id,
        "username": username
    })
    print(f"Conectado: {username} ({connection_id})")
    return {"statusCode": 200}
```

**Lambda `cybermoon-chat-on-disconnect`:**
- Crie `backend/lambdas/on_disconnect.py`:

```python
import boto3

dynamo = boto3.resource("dynamodb")
tabela = dynamo.Table("cybermoon-conexoes")

def handler(event, context):
    connection_id = event["requestContext"]["connectionId"]
    tabela.delete_item(Key={"connection_id": connection_id})
    print(f"Desconectado: {connection_id}")
    return {"statusCode": 200}
```

**Lambda `cybermoon-chat-send-message`:**
- Crie `backend/lambdas/send_message.py`:

```python
import boto3
import json
import time
import uuid

dynamo = boto3.resource("dynamodb")
tabela_conexoes = dynamo.Table("cybermoon-conexoes")
tabela_mensagens = dynamo.Table("cybermoon-mensagens")

def handler(event, context):
    connection_id = event["requestContext"]["connectionId"]
    domain = event["requestContext"]["domainName"]
    stage = event["requestContext"]["stage"]
    endpoint = f"https://{domain}/{stage}"

    dados = json.loads(event.get("body", "{}"))
    conteudo = dados.get("conteudo", "").strip()[:300]  # max 300 chars
    sala_id = dados.get("sala_id", "global")

    if not conteudo:
        return {"statusCode": 400}

    # busca dados do remetente
    item_remetente = tabela_conexoes.get_item(Key={"connection_id": connection_id})
    remetente = item_remetente.get("Item", {})
    username = remetente.get("username", "desconhecido")
    player_id = remetente.get("player_id", "")

    agora = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    expira = int(time.time()) + 30 * 24 * 60 * 60  # 30 dias

    # persiste a mensagem
    tabela_mensagens.put_item(Item={
        "sala_id": sala_id,
        "enviada_em": agora + "#" + str(uuid.uuid4()),
        "player_id": player_id,
        "username": username,
        "conteudo": conteudo,
        "expira_em": expira
    })

    # monta o payload para os clientes
    payload = json.dumps({
        "tipo": "mensagem",
        "sala_id": sala_id,
        "username": username,
        "conteudo": conteudo,
        "enviada_em": agora
    })

    # distribui para todos os conectados
    conexoes = tabela_conexoes.scan()["Items"]
    gateway = boto3.client("apigatewaymanagementapi", endpoint_url=endpoint)

    for conexao in conexoes:
        dest_id = conexao["connection_id"]
        try:
            gateway.post_to_connection(ConnectionId=dest_id, Data=payload.encode())
        except gateway.exceptions.GoneException:
            # conexao morta, limpa
            tabela_conexoes.delete_item(Key={"connection_id": dest_id})

    return {"statusCode": 200}
```

- [ ] **Passo 2.** Para cada Lambda, adicione uma **IAM Policy** que permita:
  - `dynamodb:PutItem`, `dynamodb:GetItem`, `dynamodb:DeleteItem`, `dynamodb:Scan`
    nas tabelas `cybermoon-conexoes` e `cybermoon-mensagens`
  - `execute-api:ManageConnections` no ARN do API Gateway (configurar após A4)

- [ ] **Passo 3.** Commit dos arquivos Lambda.

```bash
git add backend/lambdas/
git commit -m "feat(chat/backend): adiciona as 4 funcoes Lambda do chat"
```

---

### Tarefa A4: criar o API Gateway WebSocket

- [ ] **Passo 1.** No console AWS, vá em **API Gateway -> Create API -> WebSocket API**.
  - API name: `cybermoon-chat`
  - Route selection expression: `$request.body.action`

- [ ] **Passo 2.** Crie as rotas e conecte as Lambdas:
  - Rota `$connect` -> Lambda `cybermoon-chat-on-connect`
  - Rota `$disconnect` -> Lambda `cybermoon-chat-on-disconnect`
  - Rota `sendmessage` -> Lambda `cybermoon-chat-send-message`

- [ ] **Passo 3.** Em **$connect**, adicione o autorizador:
  - Vá em **Authorizers -> Create authorizer**
  - Type: **Lambda**
  - Lambda: `cybermoon-chat-authorizer`
  - Identity source: `route.request.querystring.token`
  - Associe o autorizador à rota `$connect`

- [ ] **Passo 4.** Deploy:
  - **Deploy API -> Stage name:** `prod`

- [ ] **Passo 5.** Anote a URL gerada (formato `wss://XXXXXX.execute-api.REGIAO.amazonaws.com/prod`).
  Ela vai para `chat_manager.gd` na Parte B.

- [ ] **Passo 6.** Volte à Lambda `cybermoon-chat-send-message` e atualize a IAM Policy
  com o ARN real do API Gateway (`execute-api:ManageConnections` no recurso correto).

- [ ] **Passo 7.** Commit de documentação.

```bash
git add equipe/planos/18-chat-entre-jogadores.md
git commit -m "docs(chat): registra a URL WSS do API Gateway no plano"
```

---

### Tarefa A5: testar o back-end isoladamente

Antes de tocar no Godot, confirme que o back-end funciona.

- [ ] **Passo 1.** Instale `wscat` na máquina de desenvolvimento:

```bash
npm install -g wscat
```

- [ ] **Passo 2.** Obtenha um token JWT temporário pelo console Cognito:
  - **Cognito -> User Pools -> SEU_POOL -> Users -> Create user** (crie um usuário de teste)
  - Use o AWS CLI para gerar o token:

```bash
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id SEU_CLIENT_ID \
  --auth-parameters USERNAME=seuteste@email.com,PASSWORD=SuaSenha123! \
  --query "AuthenticationResult.IdToken" \
  --output text
```

- [ ] **Passo 3.** Conecte via wscat:

```bash
wscat -c "wss://XXXXXX.execute-api.REGIAO.amazonaws.com/prod?token=SEU_TOKEN_JWT"
```

- [ ] **Passo 4.** Envie uma mensagem de teste:

```json
{"action": "sendmessage", "conteudo": "Ola do back-end!", "sala_id": "global"}
```

- [ ] **Passo 5.** Abra uma segunda sessão wscat com outro token e confirme que a
  mensagem chega nas duas janelas.

- [ ] **Passo 6.** Verifique no DynamoDB que a mensagem foi persistida na tabela
  `cybermoon-mensagens`.

- [ ] **Passo 7.** Commit de confirmação.

```bash
git add equipe/planos/18-chat-entre-jogadores.md
git commit -m "docs(chat): marca back-end testado e funcionando"
```

---

## Parte B — Front-end Godot

As tarefas B1 a B4 integram o back-end ao jogo.

---

### Tarefa B1: adicionar sinais do chat ao EventBus

- [ ] **Passo 1.** Abra `game/scripts/core/event_bus.gd` e adicione os três sinais
  abaixo ao final do arquivo:

```gdscript
signal chat_mensagem_recebida(username: String, conteudo: String, sala_id: String, enviada_em: String)
signal chat_conectado()
signal chat_desconectado(motivo: String)
```

- [ ] **Passo 2.** Commit.

```bash
git add game/scripts/core/event_bus.gd
git commit -m "feat(chat): adiciona sinais de chat ao EventBus"
```

---

### Tarefa B2: criar o ChatManager (autoload)

- [ ] **Passo 1.** Crie o arquivo `game/scripts/core/chat_manager.gd`:

```gdscript
extends Node

## Gerencia a conexão WebSocket com o back-end AWS do chat.
## É um autoload: existe durante toda a vida do jogo.
## Repassa eventos pelo EventBus para que a UI e outros sistemas reajam sem
## depender diretamente deste nó.

const URL_WEBSOCKET: String = "wss://XXXXXX.execute-api.REGIAO.amazonaws.com/prod"
# ^ substitua pela URL anotada na tarefa A4

var _peer: WebSocketPeer = WebSocketPeer.new()
var _token_jwt: String = ""
var _conectado: bool = false

func _ready() -> void:
    set_process(false)  # só processa quando tiver conexão ativa

## Tenta conectar ao chat usando o token JWT do jogador autenticado.
func conectar(token: String) -> void:
    if _conectado:
        return
    _token_jwt = token
    var url := URL_WEBSOCKET + "?token=" + token
    var erro := _peer.connect_to_url(url)
    if erro != OK:
        push_error("ChatManager: falha ao iniciar conexão WebSocket: " + str(erro))
        return
    set_process(true)

## Envia uma mensagem para a sala informada.
func enviar_mensagem(conteudo: String, sala_id: String = "global") -> void:
    if not _conectado:
        push_warning("ChatManager: tentativa de enviar mensagem sem conexão ativa")
        return
    var payload := JSON.stringify({
        "action": "sendmessage",
        "conteudo": conteudo,
        "sala_id": sala_id
    })
    _peer.send_text(payload)

func desconectar() -> void:
    _peer.close()
    _conectado = false
    set_process(false)

func _process(_delta: float) -> void:
    _peer.poll()
    var estado := _peer.get_ready_state()

    match estado:
        WebSocketPeer.STATE_OPEN:
            if not _conectado:
                _conectado = true
                EventBus.chat_conectado.emit()
            _ler_mensagens()

        WebSocketPeer.STATE_CLOSED:
            if _conectado:
                _conectado = false
                var motivo := "código %d" % _peer.get_close_code()
                EventBus.chat_desconectado.emit(motivo)
            set_process(false)

func _ler_mensagens() -> void:
    while _peer.get_available_packet_count() > 0:
        var texto := _peer.get_packet().get_string_from_utf8()
        var dados = JSON.parse_string(texto)
        if dados == null or typeof(dados) != TYPE_DICTIONARY:
            continue
        if dados.get("tipo") == "mensagem":
            EventBus.chat_mensagem_recebida.emit(
                dados.get("username", "?"),
                dados.get("conteudo", ""),
                dados.get("sala_id", "global"),
                dados.get("enviada_em", "")
            )
```

- [ ] **Passo 2.** Abra `game/project.godot` e adicione o autoload. Na seção `[autoload]`,
  acrescente a linha abaixo (pode ser em qualquer ordem, mas por convenção vai ao final):

```ini
ChatManager="*res://scripts/core/chat_manager.gd"
```

- [ ] **Passo 3.** Abra o Godot, confirme que não há erros de parse no script
  (`Erros` na parte inferior do editor deve ficar vazia).

- [ ] **Passo 4.** Commit.

```bash
git add game/scripts/core/chat_manager.gd game/project.godot
git commit -m "feat(chat): adiciona ChatManager como autoload com conexao WebSocket"
```

---

### Tarefa B3: criar a cena e o script de UI do chat

- [ ] **Passo 1.** No editor Godot, crie a cena `game/scenes/ui/chat.tscn` com a
  seguinte hierarquia de nós (use **Add Child Node** para cada um):

```
PanelContainer  (chat.tscn, script: chat_ui.gd)
  VBoxContainer
    ScrollContainer
      VBoxContainer  (name: Mensagens)
    HBoxContainer
      LineEdit       (name: CampoTexto, placeholder: "Escreva uma mensagem...")
      Button         (name: BotaoEnviar, text: "Enviar")
```

  Dica de layout:
  - `PanelContainer`: ancora no canto inferior da tela, tamanho fixo de 600 × 220 px
  - `ScrollContainer`: `size_flags_vertical = EXPAND_FILL`
  - `LineEdit`: `size_flags_horizontal = EXPAND_FILL`

- [ ] **Passo 2.** Crie `game/scripts/ui/chat_ui.gd` e associe à raiz da cena:

```gdscript
extends PanelContainer

## Painel de chat da tela. Ouve o EventBus e repassa ações ao ChatManager.

const MAX_MENSAGENS_VISIVEIS: int = 50

@onready var mensagens: VBoxContainer = $VBoxContainer/ScrollContainer/Mensagens
@onready var campo_texto: LineEdit = $VBoxContainer/HBoxContainer/CampoTexto
@onready var botao_enviar: Button = $VBoxContainer/HBoxContainer/BotaoEnviar
@onready var scroll: ScrollContainer = $VBoxContainer/ScrollContainer

func _ready() -> void:
    EventBus.chat_mensagem_recebida.connect(_ao_receber_mensagem)
    EventBus.chat_conectado.connect(_ao_conectar)
    EventBus.chat_desconectado.connect(_ao_desconectar)
    botao_enviar.pressed.connect(_ao_pressionar_enviar)
    campo_texto.text_submitted.connect(_ao_submeter_texto)
    visible = false  # começa fechado; abre com a tecla chat

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("abrir_chat"):
        visible = not visible
        if visible:
            campo_texto.grab_focus()

func _ao_pressionar_enviar() -> void:
    _enviar()

func _ao_submeter_texto(_texto: String) -> void:
    _enviar()

func _enviar() -> void:
    var texto := campo_texto.text.strip_edges()
    if texto.is_empty():
        return
    ChatManager.enviar_mensagem(texto)
    campo_texto.clear()

func _ao_receber_mensagem(username: String, conteudo: String, _sala: String, _hora: String) -> void:
    var label := Label.new()
    label.text = "[%s]: %s" % [username, conteudo]
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_ARBITRARY
    mensagens.add_child(label)
    # limita o historico visivel
    if mensagens.get_child_count() > MAX_MENSAGENS_VISIVEIS:
        mensagens.get_child(0).queue_free()
    # rola para o final
    await get_tree().process_frame
    scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _ao_conectar() -> void:
    _adicionar_aviso("[Chat conectado]")

func _ao_desconectar(motivo: String) -> void:
    _adicionar_aviso("[Chat desconectado: %s]" % motivo)

func _adicionar_aviso(texto: String) -> void:
    var label := Label.new()
    label.text = texto
    label.add_theme_color_override("font_color", Color.GRAY)
    mensagens.add_child(label)
```

- [ ] **Passo 3.** Commit.

```bash
git add game/scenes/ui/chat.tscn game/scripts/ui/chat_ui.gd
git commit -m "feat(chat): adiciona cena e script da UI do chat"
```

---

### Tarefa B4: registrar a ação de input e instanciar o chat na cena

- [ ] **Passo 1.** Em `game/project.godot`, na seção `[input]`, adicione a ação `abrir_chat`
  mapeada para a tecla **Enter**:

```ini
abrir_chat={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":16,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194309,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

> `physical_keycode` 4194309 é o Enter. Se preferir outra tecla, mapeie pelo editor do
> Godot em **Project -> Project Settings -> Input Map -> Add Action**.

- [ ] **Passo 2.** Abra `game/scenes/levels/playground.tscn` no editor. Localize o nó
  de HUD (ou a raiz da cena se não houver HUD dedicado) e instancie `chat.tscn` como
  filho. O painel fica no canto inferior da tela.

- [ ] **Passo 3.** Teste rápido sem back-end real: no `_ready` do `chat_ui.gd`, emita um
  sinal de teste manualmente para confirmar que o painel abre e fecha com Enter e que
  mensagens renderizam corretamente:

```gdscript
# linha temporaria de teste — remova antes do commit final
EventBus.chat_mensagem_recebida.emit("Fazendeiro", "Ola mundo!", "global", "2026-09-16T00:00:00Z")
```

- [ ] **Passo 4.** Remova a linha de teste e commit.

```bash
git add game/project.godot game/scenes/levels/playground.tscn
git commit -m "feat(chat): instancia painel de chat no playground e mapeia tecla Enter"
```

---

### Tarefa B5: conectar o ChatManager ao fluxo de login

Por enquanto não existe tela de login no jogo, então a conexão é iniciada com um token
temporário gerado no console Cognito (mesmo token do teste A5).

- [ ] **Passo 1.** Em `game/scripts/core/chat_manager.gd`, adicione uma constante com o
  token temporário de desenvolvimento (substitua pelo valor real):

```gdscript
## Somente para desenvolvimento. Trocar por fluxo de login real quando existir.
const TOKEN_DEV: String = "COLE_AQUI_O_ID_TOKEN_DO_COGNITO"
```

- [ ] **Passo 2.** Faça o `ChatManager` se conectar automaticamente no `_ready`:

```gdscript
func _ready() -> void:
    set_process(false)
    # conexao automatica com token de dev; remover quando o login existir
    if TOKEN_DEV != "COLE_AQUI_O_ID_TOKEN_DO_COGNITO":
        conectar(TOKEN_DEV)
```

- [ ] **Passo 3.** Rode o jogo em WebGL (ou diretamente no editor) e confirme na
  aba de Output do Godot que o sinal `chat_conectado` é emitido e que o aviso
  "[Chat conectado]" aparece no painel.

- [ ] **Passo 4.** Abra `wscat` em paralelo com o mesmo token e confirme que mensagens
  enviadas pelo jogo chegam no terminal, e mensagens enviadas pelo terminal chegam no jogo.

- [ ] **Passo 5.** Commit.

```bash
git add game/scripts/core/chat_manager.gd
git commit -m "feat(chat): conecta automaticamente com token de dev ao iniciar"
```

---

### Tarefa B6: build WebGL e hospedagem no S3

- [ ] **Passo 1.** No editor Godot, vá em **Project -> Export -> Add -> Web**.
  - Marque **Threads support**: desabilitado (compatibilidade ampla)
  - Export path: `build/web/index.html`

- [ ] **Passo 2.** Clique em **Export Project** (sem depuração) para gerar os arquivos.

- [ ] **Passo 3.** No console AWS, vá em **S3 -> Create bucket**:
  - Nome: `cybermoon-chat-web` (deve ser único globalmente)
  - Desmarque **Block all public access**
  - Habilite **Static website hosting**, index document: `index.html`

- [ ] **Passo 4.** Faça upload de todos os arquivos da pasta `build/web/` para o bucket.

- [ ] **Passo 5.** Adicione a **Bucket Policy** para leitura pública:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::cybermoon-chat-web/*"
  }]
}
```

- [ ] **Passo 6.** Acesse a URL do bucket (`http://cybermoon-chat-web.s3-website-REGIAO.amazonaws.com`),
  abra o chat com Enter, envie uma mensagem e confirme que ela aparece.

- [ ] **Passo 7.** Commit.

```bash
git add build/web/ equipe/planos/18-chat-entre-jogadores.md
git commit -m "feat(chat): adiciona build WebGL e hospeda no S3"
```

---

## Fora de escopo

- Login real com tela de usuário e senha no jogo — fica para feature futura (plano 19).
- Mensagens privadas — o back-end recebe `sala_id` e pode ser estendido, mas a UI só
  expõe a sala global agora.
- Moderação e banimento pela UI do jogo — administração fica no console AWS.
- ElastiCache / Redis para presença — o scan no DynamoDB é suficiente para o volume
  acadêmico; otimizar depois se necessário.
- Filtro de palavras ofensivas — Lambda pode ter lista negra simples, mas não é
  requisito para a entrega.

---

## Resumo dos commits

| # | Commit | O que entrou |
|---|--------|--------------|
| 1 | `docs(chat): registra USER_POOL_ID e CLIENT_ID no plano` | Cognito configurado |
| 2 | `docs(chat): registra nomes e schemas das tabelas DynamoDB` | Tabelas criadas |
| 3 | `feat(chat/backend): adiciona as 4 funcoes Lambda do chat` | Lambdas em Python |
| 4 | `docs(chat): registra a URL WSS do API Gateway no plano` | API Gateway pronto |
| 5 | `docs(chat): marca back-end testado e funcionando` | wscat valida back-end |
| 6 | `feat(chat): adiciona sinais de chat ao EventBus` | event_bus.gd |
| 7 | `feat(chat): adiciona ChatManager como autoload com conexao WebSocket` | chat_manager.gd |
| 8 | `feat(chat): adiciona cena e script da UI do chat` | chat.tscn + chat_ui.gd |
| 9 | `feat(chat): instancia painel de chat no playground e mapeia tecla Enter` | playground.tscn |
| 10 | `feat(chat): conecta automaticamente com token de dev ao iniciar` | token de dev |
| 11 | `feat(chat): adiciona build WebGL e hospeda no S3` | jogo no ar |
