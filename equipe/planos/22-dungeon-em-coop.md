# Plano 22: Dungeon em coop

**Objetivo:** uma dungeon de combate onde dois jogadores enfrentam os mesmos inimigos
juntos. Entra-se por um portal na fazenda, que abre um lobby para chamar quem está online.

**Depende de:** 21 (conexão e salas), 09 (inimigos), 14 (malha de navegação).

**Entrega para:** 23 (conteúdo da dungeon: salas, chefes e objetivo).

## Decisões fechadas (Antonio, 2026-10-06)

**A dungeon não tem horário nem clima.** O relógio para enquanto o jogador está lá
dentro, e a luz é fixa. Só existe progressão por enfrentar inimigos e coletar itens.

**Quem cria o lobby é o anfitrião, e o jogo dele manda nos inimigos.** O servidor só
repassa mensagens (plano 21), então alguém precisa simular. O anfitrião roda a
inteligência dos inimigos e transmite; o convidado mostra fantoches e avisa quando acerta
um golpe.

**Cada jogador cuida de si.** Vida, stamina, experiência, inventário e saque são de cada
um. O inimigo que morre solta item no jogo de cada jogador, sem disputa.

**Quem morre volta sozinho para a fazenda.** É o desmaio que já existe: acorda em casa no
dia seguinte. O outro continua na dungeon.

**Se o anfitrião sai ou cai, a dungeon acaba para os dois.** O convidado volta para a
fazenda com um aviso. Passar o comando dos inimigos para o convidado fica fora.

**Dá para jogar sozinho,** sem servidor: o jogo é o próprio anfitrião.

## Como a dungeon existe no jogo

A dungeon é uma cena (`scenes/levels/dungeon.tscn`) criada longe da fazenda, na mesma
árvore, e o jogador é levado até ela. Não há troca de cena: o jogador, a câmera, a HUD e
o chat são os mesmos, e a fazenda fica intacta para a volta (o jogo ainda não salva, então
trocar de cena perderia as plantas). Ao sair, a cena da dungeon é apagada.

- `DungeonManager` (autoload): `entrar()`, `sair()`, `esta_na_dungeon()`. Cria e apaga a
  cena, leva e traz o jogador, para e solta o relógio.
- `EventBus.dungeon_entered` e `dungeon_left`: a iluminação troca para a luz fixa e a
  chuva some.
- `PortalDaDungeon` (na fazenda): `interagir()` abre o lobby. `PortalDeSaida` (na
  dungeon): `interagir()` sai.

## Lobby

- `LobbyManager` (autoload): a sala do plano 21 vista pelo jogo. `convidar(id)`,
  `responder_convite(aceita)`, `sair()`, `iniciar()`, `sou_anfitriao()`, `membros`,
  `enviar_para_a_sala(tipo, campos)`. Sinais `room_changed`, `invite_received`,
  `room_closed`, `room_message(de, tipo, campos)`.
- `TelaDeLobby`: quem está na equipe, quem está online com o botão de convidar, e
  "Entrar na dungeon". O convidado não precisa estar no portal: aceitou o convite, entra
  junto quando o anfitrião inicia.
- `HudConvite`: o aviso de convite, com aceitar e recusar.

## O que trafega na sala (campo `dados` da rota `sala`)

| `tipo` | Quem manda | Conteúdo |
|---|---|---|
| `jogador` | todos, 12 vezes por segundo | posição, giro e animação do próprio jogador |
| `inimigos` | anfitrião, 10 vezes por segundo | de cada inimigo: id, posição, giro, animação, vida |
| `golpe` | convidado | id do inimigo e dano. O anfitrião aplica |
| `dano` | anfitrião | dano que um inimigo causou no jogador que recebe a mensagem |
| `morreu` | anfitrião | id do inimigo. Cada jogo dá a experiência e sorteia o próprio saque |
| `saiu` | quem sai | o jogador deixou a dungeon (morreu ou usou a saída) |

## Peças novas

- `JogadorRemoto`: o outro jogador como fantoche, na camada `jogador` para o inimigo
  conseguir acertar, com o nome em cima. Anda por interpolação.
- `Inimigo` ganha o modo fantoche: sem inteligência, segue o que o anfitrião manda e
  repassa o golpe que leva.
- O `Inimigo` do anfitrião escolhe como alvo o jogador mais perto, local ou remoto.
- `Dungeon` (script da cena): cria os inimigos nos marcadores, os jogadores remotos, e faz
  o envio e a aplicação das mensagens. Quando todos os inimigos caem, avisa e libera a
  saída.

## Partículas

Plano escrito depois da regra de partículas, então as ações dele nascem com efeito:

- Jogador (local ou remoto) entrando e saindo da dungeon: um sopro no lugar.
- Inimigo de fantoche levando golpe: o mesmo clarão do inimigo normal.

## Tarefas

- [ ] **1.** `DungeonManager`, a cena da dungeon de teste com malha de navegação, a luz
  fixa e o relógio parado. Entrar e sair sozinho.
- [ ] **2.** Portal na fazenda e saída na dungeon.
- [ ] **3.** `LobbyManager`, `TelaDeLobby` e `HudConvite`.
- [ ] **4.** `JogadorRemoto` e o envio do estado do jogador.
- [ ] **5.** Inimigo com alvo mais próximo, modo fantoche e as mensagens `inimigos`,
  `golpe`, `dano` e `morreu`.
- [ ] **6.** Saída, morte e queda do anfitrião.
- [ ] **7.** Testar com dois jogos: os dois veem os mesmos inimigos, os dois causam dano,
  os dois levam dano.
- [ ] **8.** Documentar e commitar.

## Critério de pronto

- Sozinho e sem servidor: entrar pelo portal, lutar e sair, com a fazenda intacta.
- Com dois jogos: convite, aceite e os dois dentro da mesma dungeon, se vendo.
- O golpe de qualquer um tira vida do mesmo inimigo, e ele morre para os dois.
- O inimigo persegue e acerta o jogador mais próximo, seja qual for.
- Morrer devolve só quem morreu à fazenda. O anfitrião sair encerra para os dois.

## Fora de escopo

- **Chefes, subchefes, várias salas e objetivo.** É o plano 23.
- **Inimigo de distância na dungeon.** O projétil não é transmitido ainda.
- **Ver a arma e o tiro do outro jogador.** O fantoche mostra só o corpo e a animação.
- **Reviver o parceiro e ajustar a dificuldade pelo número de jogadores.**
- **Mais de dois jogadores.** O protocolo aceita, mas só dois foram testados.
- **Salvar o progresso da dungeon.**
