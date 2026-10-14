# Plano 19: Partículas no que já existe

**Objetivo:** dar efeito de partículas às ações que foram implementadas sem ele. Os planos
01 a 18 foram escritos antes de o jogo ter partículas, então nenhum deles prevê efeito.
Este plano passa por tudo que eles entregaram e acrescenta os efeitos de uma vez.

**Depende de:** todos os planos de 01 a 17 que estiverem feitos quando este começar. É
para ser executado **depois dos planos que já existem**, por decisão do Antonio em
2026-09-30.

**Entrega para:** ninguém. É acabamento.

## Revisão de 2026-10-13 (vale sobre o resto do plano)

**Situação:** feito. Cada ação foi disparada por teste e o efeito contado na cena: um
efeito por ação, na cor e na quantidade da tabela, e nenhum sobrando depois de 2
segundos. Arar, molhar, subir de nível, inimigo caindo e dano no jogador foram conferidos
por captura. O ajuste fino de tamanho e cor (tarefa 6) é de olho, e fica com o Antonio.

**Um defeito antigo apareceu e foi corrigido.** O efeito começava a emitir antes de ser
posto no lugar, e as partículas ficam onde nascem. A maior parte nascia na origem do
mapa, longe da ação. Isso valia para a poeira dos passos desde que ela foi feita: só a
parte emitida depois do primeiro quadro aparecia no pé do jogador. Agora
`EfeitoDeParticulas.soltar` posiciona antes de adicionar à cena.

**Ajustes ao plano:**

- **Três cenas novas:** `estouro` (para todos os lados), `jorro` (cai) e `subida_lenta`.
  Com a poeira de passo, que faz o papel do sopro, são as quatro do plano.
- **As partículas ficaram maiores que as da poeira** (0,11 contra 0,045). No tamanho da
  poeira, a esta distância de câmera, elas tinham um pixel.
- **A tabela de efeitos fica no `EfeitosDoJogo`:** para cada ação, a cena, a cor, a
  quantidade e a altura.
- **Teto de 8 efeitos novos por quadro,** e nada é solto a mais de 22 metros do jogador.
  Na virada do dia dezenas de plantas crescem e todo o solo muda de uma vez.
- **Sinais novos, só para quem mostra efeito:** `projectile_impacted`, `player_dashed` e
  `item_consumed`. O `crop_harvested` ganhou a célula. O alvo de treino passou a emitir
  `damage_dealt`.
- **O golpe que acerta usa o `damage_dealt`,** e não um gancho no `AtaqueDoJogador`. Serve
  para o jogador, os inimigos e os alvos de treino de uma vez. A faísca é ciano quando o
  item na mão é o bastão de choque.
- **Dos planos 09 a 17 entraram:** inimigo levando dano e caindo (na cor do perfil),
  troca de estação (folhas na cor da grama nova), ganhar um coração e começar a namorar
  (sobre o NPC), e alcançar um marco.
- **Não entraram:** comprar e vender (a loja pausa o jogo, e a venda acontece com a tela
  escura do sono), e o raio da tempestade, que já tem o clarão. A chuva, o salvar e a
  entrada na dungeon já tinham efeito próprio.
- **Subir de nível não solta efeito ao carregar um save,** que também emite
  `level_changed`.

## Contexto

O sistema de partículas já existe e está descrito em `game/docs/arquitetura.md`, seção
"Efeitos de partícula":

- cada efeito é uma cena pequena em `game/scenes/effects/`, com o script
  `EfeitoDeParticulas`, que dispara uma vez e se apaga sozinha;
- usa `CPUParticles3D`, por causa do renderizador Compatibility e do alvo web;
- quem quer um efeito chama `EfeitoDeParticulas.soltar(cena, posicao, cor, quantidade, pai)`.

O primeiro efeito, a poeira do passo (`poeira_de_passo.tscn`), está feito e serve de
modelo para os outros.

## Regra daqui para frente

**Feature nova já nasce com partículas.** Todo plano escrito depois deste (as etapas que
ainda não estão em `equipe/planos/`) precisa prever, na própria lista de tarefas, o
efeito de partículas das ações que ele cria. Este plano 19 cobre só o que foi feito sem
efeito. A regra está também no `CLAUDE.md` e na skill `padrao-cyber-moon`.

## Decisões fechadas

**Um nó de efeitos escuta os sinais, os sistemas não mudam.** A maior parte das ações já
emite sinal no `EventBus` ou no autoload dela. Um nó `EfeitosDoJogo`
(`game/scripts/effects/efeitos_do_jogo.gd`), instanciado na fase, escuta esses sinais e
solta o efeito no lugar certo. Assim a `GradeSolo`, o `StatusManager` e o `ItemNoMundo`
não ficam sabendo que partículas existem. Onde faltar o dado no sinal (a posição, por
exemplo), acrescente o parâmetro no sinal em vez de dar ao sistema uma referência ao nó
de efeitos.

**Uma cena por tipo de movimento, cor por parâmetro.** Não uma cena por ação. Três ou
quatro cenas bastam: sopro para cima (a poeira do passo), jorro que cai (água), estouro
para todos os lados (impacto, brilho) e subida lenta (folhas, estrelas). A cor e a
quantidade entram por parâmetro.

**Efeito pequeno e rápido.** De 5 a 30 partículas, menos de um segundo de vida. O jogo
é visto de cima e de longe: efeito grande demais tapa o personagem.

## Lista de efeitos

Fazenda (planos 03 a 06):

| Ação | Sinal que já existe | Efeito |
|---|---|---|
| Arar | `EventBus.tile_plowed` | torrões de terra saltando |
| Molhar | `EventBus.tile_watered` | gotas caindo e respingo |
| Desfazer o solo com a picareta | `EventBus.tile_removed` | lascas de terra |
| Plantar | `EventBus.crop_planted` | terra fina subindo |
| Planta cresce | `EventBus.crop_grown` | brilho verde curto |
| Planta murcha | `EventBus.crop_withered` | folhas secas caindo |
| Arrancar planta | `EventBus.crop_removed` | folhas voando |
| Colher | `EventBus.crop_harvested` | folhas subindo, na cor da cultura |
| Item coletado | `EventBus.item_picked_up` | brilho rápido no peito do jogador |

Combate e status (planos 07 e 08):

| Ação | De onde disparar | Efeito |
|---|---|---|
| Golpe que acerta | `AtaqueDoJogador`, no acerto | faíscas no alvo |
| Bastão de choque acerta | idem, cor ciano | faíscas elétricas |
| Projétil bate | `Projetil`, ao sumir | estilhaço no ponto de impacto |
| Dash | `player.gd`, ao começar | rastro de poeira |
| Comer | `StatusManager.consumir` | brilho de recuperação |
| Subir de nível | `StatusManager.level_changed` | estouro para cima |
| Desmaiar | `StatusManager.player_fainted` | estrelinhas girando |

Planos 09 a 17, se já estiverem feitos quando este começar: inimigo levando dano e
morrendo, troca de estação, chuva e clima (o plano 13 pode usar o mesmo sistema), NPC
reagindo a presente, compra e venda. Levante a lista olhando o que cada plano entregou.

## Tarefas

- [x] **1.** Criar as cenas de efeito que faltam (jorro, estouro, subida lenta), no
  molde da `poeira_de_passo.tscn`.
- [x] **2.** Criar o `EfeitosDoJogo` e instanciar na fase. Ligar os sinais da fazenda.
  Conferir cada efeito no jogo, um por um.
- [x] **3.** Completar os sinais que não levam posição. `crop_harvested`, por exemplo,
  leva o cultivo e a quantidade, mas não a célula.
- [x] **4.** Efeitos de combate e de status.
- [x] **5.** Levantar e fazer os efeitos dos planos 09 a 17 que já estiverem prontos.
- [ ] **6.** Ajustar tamanho, cor e quantidade olhando o jogo na câmera normal. Este
  passo é de olho.
- [x] **7.** Documentar e commitar.

## Critério de pronto

- Cada ação da lista mostra o efeito dela, no lugar certo e na cor certa.
- Nenhum efeito fica sobrando na cena depois de terminar.
- Os sistemas de jogo não ganharam referência ao nó de efeitos.
- O jogo continua rodando liso com vários efeitos ao mesmo tempo (arar uma fileira
  correndo, por exemplo).

## Fora de escopo

- **Som dos efeitos.** Partícula é visual. Som novo é outro trabalho.
- **Partículas de GPU, rastro e colisão de partícula.** O alvo web pede o simples.
- **Tremor de câmera e pausa no acerto.** São outra família de efeito, e cabem numa
  etapa própria de "sensação de jogo".
