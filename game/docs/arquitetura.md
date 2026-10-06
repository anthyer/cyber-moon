# Arquitetura

Este documento descreve os sistemas globais (autoloads) e o modelo de dados do Cyber Moon.

## Autoloads

- `EventBus` (`scripts/core/event_bus.gd`): declara sinais globais usados por sistemas que não precisam se conhecer diretamente. Sinais atuais: `crop_harvested`, `city_expansion_blocked`, `npc_relationship_changed`, `tile_plowed`, `tile_watered`, `tile_removed`, `musica_solicitada`, `item_picked_up(item, quantidade)` (o jogador pegou um item do chão), `crop_planted(celula, cultivo)`, `crop_grown(celula, novo_estagio)`, `crop_withered(celula)`, `crop_removed(celula)`, `damage_dealt(alvo, quantidade)` e `enemy_defeated(perfil, posicao)`.
- `DayCycleManager` (`scripts/core/day_cycle_manager.gd`): o relógio do jogo. A hora anda sozinha das 6:00 à 1:00 do dia seguinte (5 minutos reais de dia, das 6:00 às 18:00, e 5 de noite, das 18:00 à 1:00), e passa de 24 em vez de voltar a zero (24.5 é 0:30). Sinais: `day_started`, `day_ended`, `hour_changed` (a cada minuto de jogo), `period_changed` e `player_slept(forcado)`. Métodos: `avancar_para_o_proximo_dia()`, `dormir(forcado)`, `periodo_atual()`, `hora_formatada()`, `fracao_do_dia()`. Para com o menu de pausa (pausa junto com a árvore) e com `tempo_congelado`.
- `WeatherManager` (`scripts/core/weather_manager.gd`): o clima do dia (`sol`, `chuva` ou `tempestade`), sorteado no `day_started` com a `chance_de_chuva` da estação; a tempestade é um quinto dela. Não muda no meio do dia. Sinal `weather_changed(clima)`, emitido todo dia. `clima_atual`, `clima_de_amanha`, `esta_chovendo()`, `perfil_atual()`, `definir_clima(clima)`.
- `SeasonManager` (`scripts/core/season_manager.gd`): o calendário. Quatro estações de 30 dias (Brotação, Estiagem, Colheita, Apagão), 120 dias por ano. Não guarda nada: estação, dia da estação e ano são calculados do `numero_do_dia` do `DayCycleManager` a cada pergunta. Sinais `season_changed(nova)` e `year_changed(novo_ano)`, emitidos no `day_started` da virada. Métodos: `estacao_atual()`, `dia_da_estacao()`, `ano_atual()`, `indice_da_estacao()`, `nome_exibido(estacao)`, `perfil_da_estacao(estacao)`, `perfil_atual()`.
- `InventoryManager` (`scripts/core/inventory_manager.gd`): inventário do jogador em 36 slots, cada um uma `PilhaDeItens` ou `null`. Os índices de 0 a 8 são a barra rápida e de 9 a 35 a matriz de 3 linhas por 9 colunas, a mesma largura da barra rápida. `adicionar_item` devolve o que não coube (inventário cheio), e completa pilhas iguais antes de ocupar o primeiro slot vazio, varrendo a barra rápida antes da matriz. Também guarda o equipamento: os espaços `ARMADURA` e `ACESSORIO` apontam para o índice de um slot, e o item equipado continua ocupando esse slot. Sinais: `inventory_changed` e `equipment_changed(espaco, item)`.
- `EquipmentManager` (`scripts/core/equipment_manager.gd`): guarda só qual dos 9 slots rápidos está selecionado (`indice_selecionado`, sinal `slot_selecionado_alterado`). O item na mão é o que está nesse slot do `InventoryManager` (`item_na_mao()`, `ferramenta_na_mao()`), como no Minecraft. Slot vazio é uma seleção válida, e com ele ou com os cestos o ataque é o soco. Ao iniciar, põe os cestos e as três ferramentas nos slots rápidos 1 a 4.
- `StatusManager` (`scripts/core/status_manager.gd`): vida, stamina, experiência e nível do jogador. Sinais `health_changed`, `stamina_changed`, `level_changed`, `experience_changed`, `player_fainted(motivo)` e `player_woke_up(motivo)`. A stamina só volta dormindo (virada do dia) ou comendo; a vida volta devagar depois de 5 segundos sem dano.
- `InputManager` (`scripts/core/input_manager.gd`): traduz o Input Map do Godot em consultas simples (`obter_direcao_movimento`, `interagir_pressionado`, `abrir_inventario_pressionado`), independente do dispositivo físico usado.
- `GameManager` (`scripts/core/game_manager.gd`): guarda a fase da história e os marcos de progresso já desbloqueados. Método principal: `desbloquear_marco`, que emite `EventBus.city_expansion_blocked`.
- `SaveManager` (`scripts/core/save_manager.gd`): grava e lê o progresso em `user://save_game.json`.
- `AudioManager` (`scripts/core/audio_manager.gd`): Ponto único de reprodução de som do jogo com piscina de tocadores reutilizados para SFX.

Cada autoload tem responsabilidade única. Quando um autoload começar a acumular lógica de um domínio diferente do seu, isso é sinal de que uma responsabilidade nova precisa de seu próprio autoload.

## Dados de jogo como Resources

Conteúdo de jogo é representado por classes `Resource` customizadas, definidas em `scripts/resources/` e instanciadas como arquivos `.tres` em `resources/`:

- `PilhaDeItens` (`scripts/resources/pilha_de_itens.gd`): um item e sua quantidade num slot do inventário.
- `Item` (`scripts/resources/item.gd`): um item do inventário, com `id` estável, `categoria` (enum `Item.Categoria`), ícone e valor de venda. Filhas: `Ferramenta`, `Semente` (aponta o `Cultivo`) e `Consumivel` (vida e stamina recuperadas).
- `Cultivo` (`scripts/resources/cultivo.gd`): uma cultura plantável, com as texturas de cada estágio, os dias por estágio, o item colhido e a quantidade, e o estágio de rebrota. Os `.tres` ficam em `resources/farming/cultivos/` e são gerados junto com o catálogo de itens. Cada `Semente` aponta para o seu `Cultivo`.
- `CustosDeAcao` (`scripts/resources/custos_de_acao.gd`): stamina gasta e experiência ganha por plantar e colher, e a stamina do golpe que acerta um oponente. O balanceamento fica num arquivo só, `resources/status/custos_padrao.tres`. O custo de cada ferramenta fica no `.tres` dela (`custo_de_stamina`, `experiencia_ao_usar`).
- `Arma` (`scripts/resources/arma.gd`): item da categoria ARMA com tipo (`PUNHO`, `LEVE`, `PESADA`, `DISTANCIA`), dano, alcance, custo de stamina por acerto, velocidade da animação, cooldown, o modelo que aparece na mão e, na arma de distância, o projétil. Os `.tres` ficam em `resources/items/armas/` e são gerados com o catálogo. O punho das mãos vazias é uma `Arma` fora do inventário, em `resources/combat/punho.tres`.
- `PerfilInimigo` (`scripts/resources/perfil_inimigo.gd`): tudo que diferencia um tipo de inimigo: modelo e cor, vida, velocidade, dano, alcance e intervalo do ataque, raios de percepção e de desistência, comportamento parado, experiência e drop. Os `.tres` ficam em `resources/combat/inimigos/`.
- `PerfilNpc` (`scripts/resources/perfil_npc.gd`): dados de um NPC.
- `NoDialogo` (`scripts/resources/no_dialogo.gd`): um nó de uma árvore de diálogo.
- `BancoDePassos` (`scripts/resources/banco_de_passos.gd`): mapeia tipos de superfície a clipes de áudio para os passos do jogador.

Um novo cultivo, item ou NPC vira um arquivo `.tres` criado no editor, sem exigir código novo.

O catálogo de itens fica em `resources/items/`, numa subpasta por grupo (`colheitas`,
`sementes`, `sucata`, `recursos`, `materiais`, `consumiveis`, `especiais`,
`ferramentas`), e o nome do arquivo é o `id` do item. Tudo menos as ferramentas é gerado
pelo script `scripts/utils/gerar_catalogo_itens.gd`, que guarda os números em tabela.
Para mudar um valor, edite a tabela e rode de novo:

```
godot --headless --path game --script res://scripts/utils/gerar_catalogo_itens.gd
```

As ferramentas são editadas à mão, porque têm som e ação próprios.

## Composição de cenas

Entidades do jogo usam herança de cena padrão do Godot. Nós de comportamento reutilizáveis são extraídos como cenas próprias e instanciados como filhos quando o mesmo comportamento se repete em mais de um tipo de entidade.

## Itens no mundo e interação

Um item caído no chão é uma instância de `ItemNoMundo` (`scenes/items/item_no_mundo.tscn`,
script `scripts/items/item_no_mundo.gd`). É uma cena só para todos os itens: ela recebe
qual `Item` representa e mostra o ícone dele como um quadrado em pé que gira e flutua. O
corpo fica na camada `item_no_chao`. Para fazer um item cair no mundo, qualquer sistema
chama `ItemNoMundo.soltar(item, quantidade, posicao, pai)`.

**Coleta automática, sem botão.** O item tem duas áreas que só enxergam a camada
`jogador`. Quando o jogador entra na `AreaDeAtracao` (raio 2), o item voa até ele
ganhando velocidade; quando encosta no corpo do jogador (`AreaDeColeta`), chama
`coletar()`, que põe o item no `InventoryManager`, emite `EventBus.item_picked_up` e
remove o item do mundo. Item solto por `soltar()` espera 0,6 s antes de ser atraído, para
não voltar para o jogador no instante em que cai do lado dele. Se `coletar()` falhar
(inventário cheio, a partir do plano 04), o item para de perseguir o jogador.

O jogador tem um nó `AreaInteracao` (script `scripts/player/area_de_interacao.gd`, classe
`AreaDeInteracao`) com raio de 1,5 que enxerga as camadas `item_no_chao`, `npc` e
`area_interacao`. Ao apertar `interagir`, o `player.gd` pede o `alvo_mais_proximo()` e
chama `interagir()` nele. Item no chão não usa essa área, porque é coletado sozinho; ela
fica para colher, conversar e abrir baú (planos 06, 15 e 17).

**Contrato de interação:** um nó é interagível quando tem o método `interagir()`. A área
detecta o corpo de colisão e sobe pela árvore até o primeiro ancestral com esse método.
O jogador não conhece o tipo do alvo; NPC, planta e baú decidem sozinhos o que fazer.

## Camadas de física

O jogo usa 8 camadas de colisão 3D, nomeadas no `project.godot`:

| Camada | Nome | Quem fica nela |
|---|---|---|
| 1 | `mundo` | cenário estático, chão, paredes, obstáculo |
| 2 | `jogador` | o corpo do jogador |
| 3 | `npc` | corpo dos NPCs |
| 4 | `inimigo` | corpo dos inimigos |
| 5 | `item_no_chao` | item dropado esperando ser pego |
| 6 | `area_interacao` | área que detecta o que dá para interagir |
| 7 | `hitbox_ataque` | área de dano de um golpe |
| 8 | `solo_agricola` | a grade de solo arável |

A colisão do cenário não é montada à mão nas cenas. Ela é gerada na importação pelo
`scripts/utils/post_import_kenney.gd`, que cria um `StaticBody3D` com forma trimesh
para cada malha do modelo e marca nele uma metadata `superficie`, usada pelo sistema de
áudio para escolher o som de passo. Modelos de decoração atravessável ficam de fora por
uma lista de trechos de nome no próprio script.

## Áudio

O sistema de áudio utiliza três buses (`Musica`, `SFX`, e `Ambiente`) para controle independente de volume. Os sons de passo devem ser organizados em pastas por superfície em `game/assets/audio/sfx/passos/` (ex. `grama`, `terra`). Uma regra fundamental do `AudioManager` é que chamadas de som com fluxo nulo (quando o arquivo não existe) são intencionalmente ignoradas, permitindo que o jogo rode sem erros enquanto os assets de áudio ainda não foram incluídos.

## Menu de pausa e inventário

O menu de pausa (`scenes/ui/menu_pausa.tscn`, dentro do `InterfaceHUD` do playground) é
também a tela do inventário. Abrir o menu pausa o jogo de verdade
(`get_tree().paused`), e o nó do menu fica em `PROCESS_MODE_ALWAYS` para continuar
lendo a entrada. Os 39 slots da tela (36 do inventário e 3 na coluna de equipamento) são
instâncias de uma cena só, `scenes/ui/slot_inventario.tscn`, criadas por código. A tela
só mostra o que o `InventoryManager` tem e redesenha quando ele avisa.

Mover item tem dois caminhos com a mesma regra (`SlotInventario.transferir`): o mouse
usa o arrastar e soltar nativo do Godot, e o controle usa pegar e soltar (confirma num
slot para pegar, navega pelo foco, confirma em outro para soltar). Soltar num espaço de
equipamento equipa, se a categoria servir.

O primeiro espaço da coluna, "Equipado", não é um equipamento guardado: é uma janela
para o slot rápido selecionado. Ele mostra o item na mão, e soltar um item nele leva o
item para o slot selecionado.

## Barra de acesso rápido

A barra (`scenes/ui/barra_rapida.tscn`, no `InterfaceHUD`) mostra os 9 slots rápidos
durante o jogo, com o slot selecionado destacado e o nome do item aparecendo por dois
segundos quando a seleção muda. Ela reusa a cena do slot do inventário em modo só de
exibição (sem foco e sem arraste) e escuta dois sinais: `inventory_changed` e
`slot_selecionado_alterado`. Some enquanto o jogo está pausado.

## Plantio e colheita

O estado das plantas mora na `GradeSolo` (`scripts/farming/grade_solo.gd`), num
dicionário de célula para `PlantaNaGrade`, paralelo ao dicionário do estado do solo. A
`PlantaNaGrade` é classe interna, e não Resource, porque é estado da partida: guarda o
`Cultivo`, o estágio e o progresso dentro do estágio.

- **Plantar:** com uma `Semente` na mão, o botão de atacar chama
  `GradeSolo.plantar(celula, cultivo)` na célula à frente e gasta uma semente do slot
  selecionado. Só planta em célula arada e sem planta, e só cultivo da estação atual
  (`Cultivo.estacoes_permitidas`; vazio vale para todas). Fora da estação, a `GradeSolo`
  recusa e pede um aviso na tela pelo `EventBus.notice_requested`.
- **Crescer:** a `GradeSolo` escuta `DayCycleManager.day_started`. A cada dia, a planta
  em solo molhado conta um dia e sobe de estágio ao juntar `dias_por_estagio`. Ao virar
  o dia, o solo molhado seca, então é preciso regar todo dia.
- **Murchar:** a planta que passa um dia em solo seco murcha, em qualquer estágio,
  inclusive madura. Ela troca para a `textura_murcha`, não cresce mais e não dá
  colheita. Fica na célula até ser arrancada. Na virada de estação, toda planta viva
  cujo cultivo não serve para a estação nova também murcha.
- **Colher:** `interagir` na célula à frente chama `GradeSolo.colher(celula)`. Só colhe
  planta no estágio máximo. Rende de 2 a 4 itens, sorteado, que nascem no chão como
  `ItemNoMundo` e são coletados pelo ímã. A planta some, ou volta ao
  `estagio_de_rebrota` do cultivo (milho e tomate).
- **Arrancar:** a enxada numa célula com planta tira a planta, viva ou murcha, e mantém
  a terra arada. A picareta tira a planta e a terra arada juntas. Nenhuma das duas rende
  colheita.

O visual da planta são sprites em pé, sem billboard, fincados na célula: duas fileiras,
uma atrás da outra, viradas para a câmera (que não gira). O tamanho e o recuo das
fileiras são exports da `GradeSolo`. Cada `Cultivo` pode ter uma `escala_da_planta_madura`: a
muda nasce no tamanho padrão e cresce até essa escala (o milho maduro fica 1,4 vez maior e o tomate 1,25). Dois detalhes de arte entram na conta da posição: a
margem transparente na base das texturas da planta é descontada, para ela não flutuar, e
as fileiras são centradas na faixa de terra desenhada, que fica deslocada para a frente
dentro da célula porque a textura do solo tem 4 linhas vazias em cima.

## Status, stamina e queda

Toda ação do jogador que gasta stamina segue a mesma regra, aplicada no `player.gd`: sem
stamina para o custo a ação é recusada, e a stamina só é cobrada quando a ação teve
efeito (usar a enxada onde ela não faz nada não custa). O dash não gasta stamina, e o
golpe só gasta quando acerta um oponente; golpe no ar é de graça. Com um `Consumivel` na mão, o
botão de atacar come uma unidade, desde que ele recupere alguma coisa.

Subir de nível (experiência `100 * nivel`, até o nível 20) aumenta a vida máxima em 10 e
a stamina máxima em 8.

Zerar a stamina ou a vida derruba o jogador. Não há tela de fim de jogo: o
`StatusManager` emite `player_fainted`, o `player.gd` toca a animação de queda e para de
responder, e a `tela_de_desmaio` escurece e chama `acordar_no_dia_seguinte()`. Isso vira
o dia, e o jogador acorda no `PontoDeSpawn` da fase. O máximo das barras não muda: quem
desmaiou de cansaço acorda com metade da stamina, e quem foi derrotado acorda com metade
da stamina e metade da vida. O que falta pode ser recuperado comendo, e uma noite normal
devolve tudo.

As barras são um componente só (`scenes/ui/barras_de_status.tscn`), usado na HUD e no
menu de pausa.

## Combate do jogador

Todo golpe passa por um caminho só no `player.gd` (`_atacar_com`), e o que muda entre os
tipos de arma é dado do `.tres`: o punho faz o combo de três golpes, a arma leve e a
pesada dão um golpe por vez (a pesada com o mesmo clipe, mais lento), e a arma de
distância dispara um projétil. Sem arma na mão, o golpe é do punho.

O `AtaqueDoJogador` (`scripts/combat/ataque_do_jogador.gd`, nó filho do `Player`) faz o
golpe acontecer no mundo:

- **Arma na mão:** um `BoneAttachment3D` no osso `arm-right`, criado em código porque o
  esqueleto vem pronto dentro do `.glb`, segura o modelo da arma. O encaixe (posição,
  rotação, escala) é dado da arma.
- **Acerto por área:** a `HitboxAtaque` é uma esfera à frente do jogador, do tamanho do
  alcance da arma. Ela vale numa janela entre 35% e 65% da duração do clipe, porque as
  animações do `.glb` não aceitam marcação de quadro. Um golpe acerta cada alvo uma vez,
  e pode acertar vários.
- **Projétil:** `scenes/combat/projetil.tscn` viaja reto, some ao bater em qualquer coisa
  e some ao percorrer o alcance da arma. A arma pode soltar vários de uma vez, abertos
  em leque (`projeteis_por_disparo`, `abertura_do_cone_em_graus`), e aí a stamina do
  disparo é cobrada uma vez só. A escopeta de cano serrado solta 6 num cone de 32 graus,
  com 3,5 metros de alcance.
- **Mira:** arma com `tem_mira_laser` mostra por onde o tiro vai passar, saindo do mesmo
  ponto e na mesma direção do projétil. Arma de um projétil só mostra uma linha de laser,
  que para no primeiro obstáculo (mundo ou inimigo) ou no alcance. Arma em leque, como a
  escopeta, mostra a área que o disparo cobre pintada no chão, amarela e translúcida
  como a marcação de alvo da enxada, e a área encurta onde há obstáculo. As duas são
  desenhadas em código, sem cena própria.

A arma também pode acelerar o giro do personagem (`multiplicador_de_giro`). A escopeta
usa 2,5, para a mira acompanhar o direcional.

**Correr que planta:** arma com `correr_planta_no_lugar` troca o que o botão de correr
faz. Segurando o botão, o `player.gd` zera a velocidade e o direcional continua virando
o personagem do jeito normal, para mirar sem sair do lugar. A escopeta usa. No teclado e
mouse, plantado, a mira segue o mouse: o `player.gd` projeta a posição do mouse num plano
horizontal na altura do tiro e vira o personagem para esse ponto. Vale o que foi usado
por último, o mouse ou as teclas de direção.

**Dash depois do golpe:** o golpe trava o movimento até a animação acabar, mas o dash
pode sair antes, assim que o golpe termina de acertar (65% do clipe, o export
`fracao_do_golpe_que_libera_o_dash` do player). O dash vai para onde o direcional
aponta, e só usa a frente do personagem quando não há direção.

**Contrato de dano:** quem pode levar dano tem o método
`receber_dano(quantidade: int, origem: Node3D)`. A hitbox e o projétil sobem pela árvore
a partir do corpo atingido até achar esse método. O `Inimigo` e o jogador implementam o
contrato: o golpe do jogador procura a camada `inimigo`, e o golpe do inimigo procura a
camada `jogador`.

**Modelo na mão sem colisão:** o `AtaqueDoJogador` remove qualquer corpo de colisão do
modelo da arma ao prendê-lo na mão, e os acessórios `aid_*` estão na lista de modelos sem
colisão da importação. Um corpo sólido preso ao personagem faz a física arremessá-lo.

A stamina do golpe só é cobrada quando ele acerta alguém, uma vez por golpe.

## Efeitos de partícula

Os efeitos usam `CPUParticles3D`, e não `GPUParticles3D`, porque o jogo roda no
renderizador Compatibility com a web como alvo, onde as partículas de CPU funcionam igual
em qualquer máquina. Cada efeito é uma cena pequena em `scenes/effects/` com o script
`EfeitoDeParticulas` (`scripts/effects/efeito_de_particulas.gd`): ela dispara uma vez e
se apaga sozinha. Quem quer um efeito chama
`EfeitoDeParticulas.soltar(cena, posicao, cor, quantidade, pai)`, com a fase como pai,
para as partículas ficarem onde nasceram.

O primeiro efeito é a poeira do passo (`poeira_de_passo.tscn`): a cada passada, o
`passos_do_jogador.gd` solta uns quadradinhos na cor da superfície sob o pé. As cores
ficam no `BancoDePassos`, junto dos sons (`cor_da_poeira_por_superficie`).

## Inimigos

Um inimigo é uma cena só, `scenes/combat/inimigo.tscn` (script `Inimigo`), configurada
por um `PerfilInimigo`. O modelo vem do perfil e é tingido em código, sobrescrevendo uma
cópia do material de cada superfície, sem mexer no `.glb`.

O comportamento é uma máquina de quatro estados num `match`: `OCIOSO` (círculo,
patrulha ou parado girando, conforme o perfil), `PERSEGUINDO`, `ATACANDO` e
`MORRENDO`. O raio de desistência é maior que o de percepção, para o inimigo não ligar e
desligar a perseguição na borda. Ele anda em linha reta, sem desviar de obstáculo (a
malha de navegação entra no plano 14, e ele passa a usá-la), e acha o jogador pelo grupo
`jogador`.

O ataque é corpo a corpo por padrão: uma área de acerto à frente do inimigo, na janela
do clipe. Perfil com `projetil` ataca de longe: o inimigo para ao chegar no
`alcance_de_ataque` e dispara os projéteis do perfil, abertos em leque quando são vários.
O tiro do inimigo usa a mesma cena do projétil do jogador, mas procura a camada
`jogador`, sai tingido com a cor do inimigo e é lento, para dar para desviar. A
sentinela dispara 3 projéteis num cone de 30 graus, a 5 m/s, com 9 metros de alcance. Morrendo, toca `die`, dá a experiência pelo
`StatusManager`, emite `enemy_defeated` e solta um item do perfil com `ItemNoMundo`.

**Reação a dano** (`scenes/combat/reacao_a_dano.tscn`, script `ReacaoADano`) é um nó
filho do jogador e de cada inimigo: empurrão para longe de quem bateu, piscada branca
(uma camada no `material_overlay`, para não apagar o tingimento), invencibilidade curta
e som. Ele não move o corpo: o dono lê `empurrao_atual()` e soma na própria velocidade.
No jogador, a câmera também sacode.

**Tamanho da cápsula:** o jogador e os inimigos usam uma cápsula do tamanho do boneco
(raio 0,25 e altura 0,7, centro a 0,35 do chão). O personagem da Kenney tem só 0,67 de
altura, e uma cápsula mais alta bate em copas de árvore e beirais acima da cabeça dele,
que para quem joga parecem paredes invisíveis.

O jogador e os inimigos só aceitam a camada `mundo` como chão de plataforma
(`platform_floor_layers = 1`). Sem isso, a cápsula de um sobe na do outro e a física
trata quem anda como plataforma em movimento.

Para testar o combate, o playground tem seis inimigos no nó `AreaDeTeste` (na faixa
livre em z = -15), quatro espalhados pelo mapa (`InimigosEspalhados`) e três bonecos de
treino perto do spawn (`AlvosDeTreino`). O boneco (`AlvoDeTreino`) implementa o contrato
de dano, não revida, não morre e mostra o número do dano, o que serve para medir armas
com calma. Nenhum inimigo percebe o jogador a partir do spawn nem da fazenda.

## Dia e noite

**Iluminação:** o nó `IluminacaoDoCiclo` (`scripts/core/iluminacao_do_ciclo.gd`) do
playground lê a hora a cada quadro e ajusta a luz direcional `Luz` e o `WorldEnvironment`
`Ambiente`: cor e energia do sol, e quanto o céu e o ambiente clareiam a cena. Os valores
vêm de uma tabela de pontos por hora, interpolada, então a cena escurece e clareia aos
poucos. A noite nunca fica toda preta. A luz é girada por código, e não pela matriz do
`.tscn`.

A direção do sol, que é o que move a sombra, anda em degraus: o dia é dividido em trechos
de `horas_por_passo_da_sombra` (2 horas de jogo), a sombra fica parada dentro de cada
trecho, na posição da hora do meio dele, e na virada o sol gira até a posição seguinte em
`segundos_da_troca_de_sombra` (3 segundos reais). Sombra se arrastando o dia inteiro
tremia na borda. Na virada do dia o sol pula direto do poente para o nascente.

**Luz do jogador:** uma `OmniLight3D` (`LuzDoJogador`) ciano, de alcance curto, presa ao
jogador e sempre ligada. De dia não aparece; à noite ilumina só em volta dele. Alcance e
energia são as próprias propriedades da luz, e um item de lanterna futuro pode mudá-las.

**Dormir:** a `Cama` (`scenes/world/cama.tscn`) implementa o contrato `interagir()` e chama
`DayCycleManager.dormir(false)`. A tela de transição escurece, vira o dia e clareia, sem
penalidade, e a stamina volta cheia. Chegando à 1:00, o `DayCycleManager` chama
`dormir(true)`, que derruba o jogador pelo mesmo caminho do desmaio do plano 07
(`StatusManager.Motivo.SONO`): ele acorda em casa no dia seguinte com metade da stamina.

## Estações

O `SeasonManager` diz a estação, e cada estação tem um `PerfilEstacao`
(`scripts/resources/perfil_estacao.gd`, um `.tres` por estação em `resources/estacoes/`)
com o que ela muda: cor da luz, multiplicador de energia, hora do anoitecer, cor da grama,
música e chance de chuva (esta, para o clima do plano 13).

- **Luz:** o `IluminacaoDoCiclo` multiplica a cor do sol pela da estação, e a energia do
  sol e do ambiente pelo multiplicador. Os pontos da tabela do fim da tarde em diante andam
  junto com o anoitecer da estação; o da 1:00 fica parado.
- **Grama:** o nó `GramaDaEstacao` (`scripts/world/grama_da_estacao.gd`) multiplica a cor
  original do material de grama pela cor da estação.
- **Música:** na virada, se o perfil tiver faixa, o `SeasonManager` emite
  `EventBus.musica_solicitada`.
- **Plantio:** veja "Plantio e colheita".
- **Relógio:** mostra a estação e o dia dentro dela, e o ano a partir do segundo.

## Clima

Cada clima tem um `PerfilClima` (`scripts/resources/perfil_clima.gd`, um `.tres` por clima
em `resources/climas/`). Quem reage escuta `WeatherManager.weather_changed`:

- **Solo:** no amanhecer com clima que `molha_o_solo`, a `GradeSolo` molha todo o solo
  arado. Ela faz isso no fim do próprio `day_started`, depois de o dia secar o solo.
- **Luz e névoa:** o `IluminacaoDoCiclo` multiplica a energia e a cor pelo clima, por cima
  da estação, e liga a névoa do `WorldEnvironment` com a densidade do perfil.
- **Chuva:** `scenes/effects/chuva.tscn` (`Chuva`), um `CPUParticles3D` com caixa de
  emissão larga que anda junto com o jogador. A quantidade de gotas vem do perfil.
- **Raio:** o nó `RaiosDaTempestade` sorteia um intervalo de 8 a 20 segundos, pede o
  clarão ao `IluminacaoDoCiclo.dar_clarao()` e toca o trovão de 1 a 3 segundos depois.
- **Som:** o `WeatherManager` emite `EventBus.ambience_requested` com o som do perfil, e o
  `AudioManager` toca em loop no bus `Ambiente`. Sem clipe, nada toca.
- **Relógio:** mostra o ícone do clima ao lado do período.

## Calendário

A tela `Calendario` (`scenes/ui/calendario.tscn`, no `InterfaceHUD`) mostra o mês da
estação numa grade de 6 por 5, destaca o dia de hoje e marca os aniversários. A semana do
jogo tem 6 dias (Primeiro a Quinto e a Folga), e por isso 30 dias fecham em 5 semanas; o
`SeasonManager` responde `dia_da_semana()` e `nome_do_dia_da_semana()`. Os aniversários
vêm do `PerfilNpc` (`estacao_do_aniversario` e `dia_do_aniversario`), e a tela lê todo
`.tres` de `resources/npcs/`, sem lista fixa no código.

Abre só interagindo com o `QuadroCalendario`
(`scenes/world/quadro_calendario.tscn`), que só emite `EventBus.calendar_requested`. Não
existe tecla de atalho, por decisão de design; o menu de debug tem um botão para teste. A
tela pausa o jogo. Ela precisa vir depois do `MenuPausa` na cena, para o Esc que a fecha
não abrir o menu no mesmo quadro.

## Aviso na tela

Qualquer sistema mostra uma frase curta ao jogador emitindo
`EventBus.notice_requested(texto)`. Quem desenha é o `HudAviso`
(`scenes/ui/hud_aviso.tscn`), acima da barra rápida: o texto fica 2,5 s e some. Um aviso
novo substitui o anterior em vez de empilhar.

## Menu de debug

O menu de debug (`scenes/ui/menu_debug.tscn`, script `MenuDebug`, no `InterfaceHUD` do
playground) abre e fecha com F3 e serve para testar os sistemas sem esperar o jogo:
trocar a hora, avançar o dia, pular para a próxima estação, abrir o calendário, trocar o clima, cair um raio, congelar o relógio, encher vida e stamina, tomar dano,
ganhar experiência, ficar invencível, teleportar, molhar o solo e amadurecer as plantas,
ganhar sementes, pães e armas, soltar sucata, criar e matar inimigos, mostrar os quadros
por segundo e ligar e desligar a sombra do sol. Ele não pausa o jogo e os botões não
pegam foco, então o jogador continua andando com o menu aberto. Tudo que ele mexe é
procurado na hora do clique, então o menu não quebra numa fase diferente.

Os sistemas expõem funções públicas para ele, que também servem a eventos futuros:
`DayCycleManager.definir_hora(hora)`, `StatusManager.invencivel_para_teste`,
`GradeSolo.molhar_todo_o_solo()` e `GradeSolo.amadurecer_todas_as_plantas()`. Ação de teste
nova entra no menu, e não como tecla solta.

## Sombra

A sombra do sol é a única sombra em tempo real, e foi ajustada para o renderizador
Compatibility e o alvo web: vai até 35 metros (a câmera vê uns 15), usa duas divisões
(`directional_shadow_mode = 1`) e um mapa de 2048 (`project.godot`). As peças planas de
chão (estrada, calçada, caminho, piso) não projetam sombra: o script de importação desliga
a sombra delas pela lista `TRECHOS_SEM_SOMBRA`, e os planos de grama da fase também estão
sem sombra. Na mesma máquina, a cena passou de 145 para 191 quadros por segundo.

