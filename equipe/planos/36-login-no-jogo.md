# Plano 36: Login no jogo (conta do Cognito)

**Objetivo:** o jogador cria uma conta, confirma o e-mail e entra, de dentro do jogo, e a
conexão com a AWS passa a levar o token da conta. É a tarefa 4.5 do plano 18, sem a qual
a chave `exigir_login` não pode ser ligada no stack que o jogo usa.

**Depende de:** 18 (sprint 4, o User Pool e o authorizer) e 21 (o `NetworkManager`).

**Situação:** feito em 2026-10-21.

## O que o plano 18 pede (tarefa 4.5)

- Telas de criar conta (e-mail, senha, nome), de confirmar o código que chega por e-mail,
  e de entrar.
- As chamadas ao Cognito são `POST https://cognito-idp.<região>.amazonaws.com/` com os
  cabeçalhos `Content-Type: application/x-amz-json-1.1` e `X-Amz-Target:
  AWSCognitoIdentityProviderService.<Operação>`. Operações: `SignUp`, `ConfirmSignUp` e
  `InitiateAuth` (`AuthFlow` igual a `USER_PASSWORD_AUTH`, e `REFRESH_TOKEN_AUTH` para
  renovar). No `SignUp`, o nome vai em `UserAttributes` como `custom:nome`.
- O `NetworkManager` acrescenta `?token=<IdToken>` ao endereço na hora de conectar.
- Renovar o `IdToken` quando a conexão cair e o token tiver mais de 50 minutos.
- A região e o `ClientId` são dados: campos novos em `ConfiguracaoDeRede`.

## Decisões

- **Um autoload novo, `AccountManager`.** Fala com o Cognito e guarda os tokens. O
  `NetworkManager` só pergunta a ele o token na hora de abrir a conexão. Assim a conexão
  não sabe nada de HTTP nem de Cognito, e a conta não sabe nada de WebSocket.
- **A conta fica guardada** em `user://conta.cfg` (e-mail, nome, `RefreshToken`). Na
  próxima vez que o jogo abre, o `IdToken` é renovado com o `RefreshToken`, sem pedir a
  senha. A senha nunca é guardada.
- **A tela de conta abre pelo lobby**, com o botão "Conta". O lobby é a tela de quem
  quer jogar com outros, e já diz com que nome o jogo está conectado. Não entra ação de
  entrada nova. O botão só aparece quando `cognito_client_id` está preenchido.
- **A tela não pausa o jogo**, pelo mesmo motivo do lobby: a requisição HTTP e a
  reconexão precisam andar. Ela liga `InputManager.teclado_capturado` enquanto aberta.
- **Entrar ou sair da conta reconecta** na hora, para o token novo valer sem esperar a
  conexão cair.
- **Sem conta, o jogo conecta sem token**, como hoje. Com `exigir_login` desligado no
  servidor, nada muda para quem não tem conta.
- **Partículas:** não se aplica. Login não é ação de jogo.

## Tarefas

### 36.1: Configuração

`ConfiguracaoDeRede` ganha `cognito_regiao` (padrão `sa-east-1`) e `cognito_client_id`
(vazio). O `configuracao.tres` recebe o `cognito_client_id` e o `endereco_na_nuvem`
exportados pelo stack que o jogo usa.

**Verificação:** o jogo abre sem erro e a configuração carrega os valores.

### 36.2: `AccountManager`

`scripts/core/account_manager.gd`, registrado antes do `NetworkManager`.

- `criar_conta(email, senha, nome)`, `confirmar_conta(email, codigo)`,
  `entrar(email, senha)`, `sair()`, `renovar_token()`. Todas assíncronas, com um
  `HTTPRequest` filho.
- `esta_logado()`, `token_de_conexao()`, `token_vencendo()`, `nome_da_conta`,
  `email_da_conta`.
- Sinais: `logged_in`, `logged_out`, `sign_up_finished(email)` (o código foi mandado),
  `account_confirmed(email)` e `request_failed(mensagem)`.
- Os erros do Cognito (`__type` da resposta) viram mensagens em português.

**Verificação:** um script de teste chama o Cognito do stack `dev` e recebe a resposta
esperada (por exemplo, `entrar` com senha errada devolve a mensagem de senha errada).

### 36.3: Token na conexão

No `NetworkManager._abrir_socket`: se o token está vencendo e há `RefreshToken`, renova
antes de abrir. Se há token, o endereço ganha `?token=`. Escuta `logged_in` e
`logged_out` do `AccountManager` para reconectar.

**Verificação:** contra o servidor local (que ignora a query string) o jogo continua
conectando e o chat funciona.

### 36.4: Tela de conta

`scenes/ui/tela_de_conta.tscn` e `scripts/ui/tela_de_conta.gd`, no mesmo estilo do lobby.
Três modos na mesma tela: entrar ou criar conta (e-mail, senha, nome), confirmar (código)
e logado (nome, e-mail, botão de sair). Linha de status embaixo para o andamento e os
erros. Abre pelo sinal `EventBus.account_requested`, que o botão "Conta" do lobby emite;
fechar volta ao lobby.

**Verificação:** criar conta, receber o código, confirmar, entrar, e ver o lobby dizer
"Conectado como <nome da conta>".

## Fora de escopo

- Login com a conta Google (pedido do Antonio, anotado no plano 18).
- Esqueci a senha (`ForgotPassword`) e reenviar o código (`ResendConfirmationCode`).
- Trocar o nome da conta depois de criada.
- Tela de login obrigatória ao abrir o jogo.
