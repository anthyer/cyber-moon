# Plano 38: Cadastro só com nome de usuário e senha

**Objetivo:** o jogador cria a conta só com um nome de usuário e uma senha, sem e-mail e
sem código de confirmação, e o jogo não deixa duas contas com o mesmo nome de usuário.
O nome de usuário é também o nome no chat e no lobby.

**Origem:** pedido do professor da disciplina de Infraestrutura e Serviços de Nuvem. O RF01,
o RF02 e os casos de uso UC01 e UC02 de `docs/chat-cloud/documentacao.md` foram
atualizados junto.

**Depende de:** 18 (sprint 4, o User Pool) e 36 (login no jogo).

**Situação:** feito em 2026-11-04.

## Decisões

- **O nome de usuário é o username do Cognito.** O Cognito já não aceita dois usuários
  com o mesmo username (`UsernameExistsException`). Com `case_sensitive` desligado,
  `Ana` e `ana` contam como o mesmo nome. Não precisa de tabela própria de nomes.
- **O nome no chat é o nome de usuário.** O atributo `custom:nome` sai. No ID token o
  nome vem em `cognito:username`, e é o que o authorizer passa adiante.
- **Sem e-mail, a conta é confirmada sozinha.** Um gatilho Pre sign-up do Cognito
  responde `autoConfirmUser`. O mesmo gatilho confere o formato do nome: de 3 a 20
  caracteres, só letras sem acento, números e `_`. O jogo confere a mesma regra antes de
  mandar, para a mensagem sair na hora.
- **Recriar o User Pool.** Tirar o `email` como username e o `custom:nome` só é possível
  criando outro User Pool. As contas que existiam somem, e o `cognito_client_id` muda.
- **SES sem uso no `prod`.** Sem e-mail não há a quem mandar as boas-vindas. A chave
  `ses_remetente` continua ligada no `prod`, porque tirar a chave apagaria a verificação
  do domínio e o DKIM; a Lambda de boas-vindas ignora a conta sem e-mail. O SES foi
  demonstrado no `prod` em 2026-11-03 (tarefa 4.6 do plano 18).
- **Sem recuperação de senha.** Sem e-mail, o Cognito não tem para onde mandar o código.
  Quem esquecer a senha cria outra conta.
- **Partículas:** não se aplica. Cadastro não é ação de jogo.

## Tarefas

### 38.1: User Pool sem e-mail

`pulumi-start-aws/__main__.py`: o User Pool perde `username_attributes`,
`auto_verified_attributes` e `schemas`, e ganha `username_configuration` com
`case_sensitive` falso e o gatilho `pre_sign_up`. Lambda nova `lambdas/cadastro.py`. O
authorizer lê `cognito:username`. A de boas-vindas pula a conta sem e-mail.

**Verificação:** `SignUp` sem atributos devolve `UserConfirmed` verdadeiro; o mesmo nome
com outra caixa devolve `UsernameExistsException`; nome com espaço é recusado; a conexão
com o token entra com o nome de usuário.

### 38.2: Jogo

`AccountManager`: `criar_conta(usuario, senha)` entra direto depois de criar; saem
`confirmar_conta` e os sinais do código. `TelaDeConta`: campos usuário e senha, sem o
formulário do código. O `configuracao.tres` recebe o `cognito_client_id` novo.

**Verificação:** criar a conta pela tela, ver "Conectado como <usuário>"; tentar criar de
novo com o mesmo nome e ver a mensagem de nome em uso.

## Fora de escopo

- Trocar o nome de usuário depois de criado.
- Recuperar a senha.
- Filtro de palavrão no nome.
