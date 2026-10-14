# Infraestrutura do Cyber Moon na AWS

Provisiona com **Pulumi** (Python, uv) os recursos da AWS do chat WebSocket do jogo.

## O que esta pasta provisiona

- Bucket S3 privado com versionamento (builds do Godot)
- Zona Route53 `cyber-moon.negoci.online` (so no stack `prod`)
- Duas tabelas DynamoDB: `cybermoon-conexoes` e `cybermoon-salas`
- API Gateway WebSocket com 10 rotas (`$connect`, `$disconnect`, `entrar`, `chat`,
  `convidar`, `responder_convite`, `sair_da_sala`, `iniciar_dungeon`, `sala`, `ping`)
- Uma Lambda por rota, empacotadas com o `utils.py` compartilhado
- Com `usar_vpc`: VPC privada com NAT e endpoint do DynamoDB
- Com `ses_remetente`: e-mail de boas-vindas via SES apos cadastro no Cognito
- Com `exigir_login`: User Pool do Cognito + authorizer JWT no `$connect`

## Criar o stack de desenvolvimento

```bash
cd pulumi-start-aws
pulumi stack init anthyer-ifsc/dev
pulumi up
```

O comando exporta `wss_url`. Para pegar a URL a qualquer momento:

```bash
pulumi stack output wss_url
```

## Como rodar e testar a conexao no Godot

Com a URL em maos (algo como `wss://...amazonaws.com/dev`), abra dois terminais na raiz do repositorio:

### Jogador 1 (Ana)
```bash
godot --path game -- --nome=Ana --servidor="<wss_url>"
```

### Jogador 2 (Beto)
Abra uma segunda janela em outro terminal. O parametro `--sem-save` evita que ambos gravem no mesmo save local:
```bash
godot --path game -- --nome=Beto --sem-save --servidor="<wss_url>"
```

*(Caso use o Godot instalado via Flatpak, troque `godot` por `flatpak run org.godotengine.Godot` ou `/var/lib/flatpak/exports/bin/org.godotengine.Godot`)*.

### Como testar dentro do jogo
1. **Chat global:**
   - Pressione **Enter** ou **T** para abrir o chat.
   - Digite uma mensagem e aperte **Enter** para enviar. A mensagem aparece nas duas telas em menos de 300 ms.
   - Pressione **Esc** para fechar o chat sem enviar. Enquanto o chat esta aberto, as teclas de movimento (WASD) ficam travadas para nao movimentar o personagem.
2. **Lobby e Dungeon Coop:**
   - Va com um dos jogadores ate o portal em frente a casa da fazenda e aperte **E** para interagir.
   - Na tela do lobby, o outro jogador aparecera na lista de online.
   - Clique em **Convidar**. O outro jogador recebera o convite na tela.
   - Apos aceitar, ambos estarao na mesma sala e o anfitriao pode clicar em **Iniciar Dungeon**.
   - As posicoes e golpes dentro da dungeon sao repassados em tempo real pela rota `sala` do API Gateway.

### Configuracao alternativa (fixar no arquivo)
Se preferir nao digitar `--servidor` toda vez, edite `game/resources/rede/configuracao.tres` no editor do Godot ou em texto e preencha o campo `endereco` ou `endereco_na_nuvem` com o `wss_url`.

## Chaves de configuracao (sprint 4)

| Chave | O que liga | Padrao |
|---|---|---|
| `usar_vpc` | Lambdas dentro de VPC privada com NAT | desligado |
| `exigir_login` | `$connect` exige token JWT do Cognito | desligado |
| `ses_remetente` | E-mail de boas-vindas assinado por este endereco | sem e-mail |

```bash
pulumi config set usar_vpc true
pulumi config set exigir_login true
pulumi config set ses_remetente noreply@cyber-moon.negoci.online
```

**Atencao:** o NAT Gateway e cobrado por hora mesmo sem trafego. Ligar para
demonstrar e desligar depois: `pulumi config set usar_vpc false && pulumi up`.

Antes de ligar `exigir_login`, construir a layer do PyJWT:

```bash
uv pip install --target build/layer/python \
  --python-platform x86_64-manylinux2014 --python-version 3.12 \
  --only-binary :all: "pyjwt[crypto]"
```

## Valores exportados

| Nome | Descricao |
|---|---|
| `wss_url` | URL WebSocket do jogo (`wss://...amazonaws.com/<stack>`) |
| `builds_bucket_name` | Nome fisico do bucket S3 |
| `conexoes_table` | Nome fisico da tabela de conexoes |
| `salas_table` | Nome fisico da tabela de salas |
| `cognito_user_pool_id` | ID do User Pool do Cognito |
| `cognito_client_id` | ID do App Client do Cognito |