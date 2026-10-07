# Plano 21: Rede e chat

**Objetivo:** o jogo conecta a um servidor de repasse, sabe quem está online e tem um chat
global que funciona o tempo todo, na fazenda e na dungeon. Tudo rodando local; a AWS entra
depois trocando o endereço.

**Depende de:** nada dos planos 01 a 20.

**Entrega para:** 22 (dungeon em coop usa a conexão e as salas).

## Revisão de 2026-10-06 (vale sobre o resto do plano)

**Situação:** feito. Conferido: o teste do protocolo passa em todas as rotas; um jogo e
um cliente de teste trocam chat nos dois sentidos; digitar "wasd" no chat não move o
personagem, e o Esc que fecha o chat não abre o menu de pausa; com o servidor derrubado o
chat avisa que está offline, e reconecta sozinho quando o servidor volta.

**Ajustes ao plano:**

- **`InputManager.teclado_capturado`** é o nome da trava (o plano dizia `digitando`),
  porque a tela de lobby também usa.
- **Ação nova `abrir_chat`**, em Enter e T.
- **Só quem foi convidado entra numa sala.** O servidor guarda os convites sem resposta;
  sem isso, quem adivinhasse o id da sala entrava nela.
- **O `LobbyManager` e as rotas de sala** foram feitos junto, mas pertencem ao plano 22.
- **Como rodar** está em `backend/servidor_local/leiame.md`.

**Relação com o plano 18:** este plano substitui a parte do Godot do plano 18 (o
`ChatManager` e a tela de chat). A parte da AWS do plano 18 (API Gateway WebSocket, Lambda,
DynamoDB, Cognito) continua valendo, e passa a implementar o protocolo descrito aqui.

## Decisões fechadas (Antonio, 2026-10-06)

**O multiplayer fica restrito à dungeon.** A fazenda continua sendo de um jogador só:
relógio, clima, plantas e NPCs não são compartilhados. Só o chat atravessa tudo.

**O servidor só repassa mensagens.** Ele não simula o jogo. É o que o API Gateway
WebSocket com Lambda consegue fazer, e por isso o servidor local imita exatamente isso:
recebe um JSON com o campo `action` (a rota), e devolve ou repassa outros JSON. Quem
simula a dungeon é o jogo do anfitrião (plano 22).

**Entrada local com nome.** Sem conta por enquanto: o jogador tem um nome, guardado em
`user://`. No jogo final o nome vem do login com a conta Google (Cognito), e a lista de
quem está online vira a lista de amigos. O protocolo já separa `id` de `nome` para isso.

**Sem servidor, o jogo funciona.** Fora do ar, o chat avisa que está offline e a dungeon
pode ser jogada sozinho.

## O protocolo

Mensagens em JSON, texto, por WebSocket. Do jogo para o servidor, o campo `action` diz a
rota (é o `routeSelectionExpression` do API Gateway). Do servidor para o jogo, o campo
`tipo` diz o que chegou.

| Do jogo (`action`) | Campos | O servidor responde ou repassa |
|---|---|---|
| `entrar` | `nome` | a quem entrou: `bem_vindo` (`id`, `online`); aos outros: `jogador_entrou` |
| `chat` | `texto` | a todos, inclusive quem mandou: `chat` (`de`, `nome`, `texto`) |
| `convidar` | `para` | ao convidado: `convite` (`de`, `nome`, `sala`). Cria a sala se quem convida não tem uma |
| `responder_convite` | `sala`, `aceita` | aos membros: `sala_atualizada`; se recusou, ao anfitrião: `convite_recusado` |
| `sair_da_sala` | | aos membros: `sala_atualizada`, ou `sala_encerrada` se quem saiu era o anfitrião |
| `iniciar_dungeon` | | aos membros: `dungeon_iniciada` (só o anfitrião pode) |
| `sala` | `dados` | aos outros membros da sala: `sala` (`de`, `dados`), sem olhar o conteúdo |

Quando alguém desconecta, os outros recebem `jogador_saiu`, e a sala dele é tratada como
em `sair_da_sala`. A rota `sala` é o canal do jogo: o plano 22 define o que vai em `dados`.

## Modelo no Godot

- `NetworkManager` (autoload): a conexão. `conectar()`, `desconectar()`,
  `enviar(acao, campos)`, `esta_conectado()`, `meu_id`, `meu_nome`, `online` (id para
  nome). Sinais `connected`, `disconnected`, `message_received(tipo, dados)`,
  `player_joined`, `player_left`. Tenta reconectar sozinho.
- `ChatManager` (autoload): o histórico do chat e o `enviar(texto)`. Sinal
  `message_added`. Guarda o histórico para a tela não perder as mensagens.
- `ConfiguracaoDeRede` (Resource, `resources/rede/configuracao.tres`): o endereço do
  servidor. Trocar para a AWS é trocar este arquivo.
- `HudChat` (`scenes/ui/hud_chat.tscn`): o histórico no canto e o campo de texto. Enter
  abre e envia, Esc fecha. Enquanto o jogador digita, o personagem não anda.
- `InputManager.digitando`: enquanto verdadeiro, toda pergunta de gameplay responde que
  nada foi pressionado.

Para testar duas janelas na mesma máquina, o nome pode vir da linha de comando:
`godot --path game -- --nome=Ana`.

## Partículas

Plano escrito depois da regra de partículas. A única ação visível deste plano é a
mensagem de chat, que é interface; não há ação no mundo para ganhar efeito. Os efeitos de
entrada e saída de jogador são do plano 22, onde o outro jogador aparece no mundo.

## Tarefas

- [x] **1.** Servidor local em `backend/servidor_local/`, com teste de protocolo.
- [x] **2.** `ConfiguracaoDeRede` e `NetworkManager`, com reconexão.
- [x] **3.** `ChatManager` e `HudChat`, com o bloqueio de entrada ao digitar.
- [x] **4.** Testar com dois jogos conectados ao mesmo servidor.
- [x] **5.** Documentar e commitar.

## Critério de pronto

- Dois jogos abertos na mesma máquina trocam mensagens de chat.
- Cada jogo sabe o nome de quem está online, e percebe quando o outro sai.
- Digitar no chat não move o personagem nem dispara ataque.
- Sem o servidor, o jogo abre e joga normal, e o chat mostra que está offline.

## Fora de escopo

- **A AWS.** Fica com o plano 18: as Lambdas implementam a tabela de protocolo acima.
- **Login com Google e lista de amigos.** Dependem do Cognito e de um banco.
- **Histórico de chat guardado no servidor.** O servidor local não guarda nada.
- **Moderação, canais e mensagem privada.**
