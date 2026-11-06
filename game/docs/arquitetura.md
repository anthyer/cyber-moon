# Arquitetura

Este documento descreve os sistemas globais (autoloads) e o modelo de dados do Cyber Moon.

## Autoloads

- `EventBus` (`scripts/core/event_bus.gd`): declara sinais globais usados por sistemas que não precisam se conhecer diretamente. Sinais atuais: `crop_harvested`, `city_expansion_blocked`, `npc_relationship_changed`, `tile_plowed`, `tile_watered`, `tile_removed`, `musica_solicitada`, `item_picked_up(item, quantidade)` (o jogador pegou um item do chão), `crop_planted(celula, cultivo)`, `crop_grown(celula, novo_estagio)`, `crop_withered(celula)`, `crop_removed(celula)`, `damage_dealt(alvo, quantidade)` e `enemy_defeated(perfil, posicao)`. Do plano 30:
`npc_waved(posicao)` (uma figurante acenou), `visitor_arrived(posicao)` e
`visitor_left(posicao)` (quem mora fora do mapa chegou ou foi embora). Veja "NPCs".
- `DayCycleManager` (`scripts/core/day_cycle_manager.gd`): o relógio do jogo. A hora anda sozinha das 6:00 à 1:00 do dia seguinte (5 minutos reais de dia, das 6:00 às 18:00, e 5 de noite, das 18:00 à 1:00), e passa de 24 em vez de voltar a zero (24.5 é 0:30). Sinais: `day_started`, `day_ended`, `hour_changed` (a cada minuto de jogo), `period_changed` e `player_slept(forcado)`. Métodos: `avancar_para_o_proximo_dia()`, `dormir(forcado)`, `periodo_atual()`, `hora_formatada()`, `fracao_do_dia()`. Para com o menu de pausa (pausa junto com a árvore) e com `tempo_congelado`.
- `WeatherManager` (`scripts/core/weather_manager.gd`): o clima do dia (`sol`, `chuva` ou `tempestade`), sorteado no `day_started` com a `chance_de_chuva` da estação; a tempestade é um quinto dela. Não muda no meio do dia. Sinal `weather_changed(clima)`, emitido todo dia. `clima_atual`, `clima_de_amanha`, `esta_chovendo()`, `perfil_atual()`, `definir_clima(clima)`.
- `UpgradeManager` (`scripts/core/upgrade_manager.gd`): o nível das armas e ferramentas. `nivel_de(item)`, `aprimorar(item)`, `dano_de(arma)`, `etapa_maxima_de_area(ferramenta)`. Veja "Saque e aprimoramento".
- `EconomyManager` (`scripts/core/economy_manager.gd`): os créditos. `creditos`, `comprar(item, quantidade)`, `vender(pilhas)`, `preco_de_compra(item)`. Veja "Economia".
- `RelationshipManager` (`scripts/core/relationship_manager.gd`): a amizade com cada NPC. `coracoes(npc_id)`, `pontos_de(npc_id)`, `presentear(npc_id, item)`, `pode_presentear(npc_id)`, `pedir_em_namoro(npc_id)`. Veja "Amizade e romance".
- `DialogueManager` (`scripts/core/dialogue_manager.gd`): conduz a conversa com um NPC. `iniciar(npc)`, `avancar()`, `encerrar()`, `fala_do_dia(npc_id)`, `em_dialogo`. Veja "Diálogo".
- `AccountManager`, `NetworkManager`, `ChatManager`, `LobbyManager` e `DungeonManager`: a conta online, a conexão, o chat, a equipe e a entrada na dungeon. Veja "Rede" e "Dungeon em equipe".
- `SeasonManager` (`scripts/core/season_manager.gd`): o calendário. Quatro estações de 30 dias (Brotação, Estiagem, Colheita, Apagão), 120 dias por ano. Não guarda nada: estação, dia da estação e ano são calculados do `numero_do_dia` do `DayCycleManager` a cada pergunta. Sinais `season_changed(nova)` e `year_changed(novo_ano)`, emitidos no `day_started` da virada. Métodos: `estacao_atual()`, `dia_da_estacao()`, `ano_atual()`, `indice_da_estacao()`, `nome_exibido(estacao)`, `perfil_da_estacao(estacao)`, `perfil_atual()`.
- `InventoryManager` (`scripts/core/inventory_manager.gd`): inventário do jogador em 36 slots, cada um uma `PilhaDeItens` ou `null`. Os índices de 0 a 8 são a barra rápida e de 9 a 35 a matriz de 3 linhas por 9 colunas, a mesma largura da barra rápida. `adicionar_item` devolve o que não coube (inventário cheio), e completa pilhas iguais antes de ocupar o primeiro slot vazio, varrendo a barra rápida antes da matriz. Também guarda o equipamento: os espaços `ARMADURA` e `ACESSORIO` apontam para o índice de um slot, e o item equipado continua ocupando esse slot. Sinais: `inventory_changed` e `equipment_changed(espaco, item)`.
- `EquipmentManager` (`scripts/core/equipment_manager.gd`): guarda só qual dos 9 slots rápidos está selecionado (`indice_selecionado`, sinal `slot_selecionado_alterado`). O item na mão é o que está nesse slot do `InventoryManager` (`item_na_mao()`, `ferramenta_na_mao()`), como no Minecraft. Slot vazio é uma seleção válida, e com ele ou com os cestos o ataque é o soco. Ao iniciar, põe os cestos e as três ferramentas nos slots rápidos 1 a 4.
- `StatusManager` (`scripts/core/status_manager.gd`): vida, stamina, experiência e nível do jogador. Sinais `health_changed`, `stamina_changed`, `level_changed`, `experience_changed`, `player_fainted(motivo)` e `player_woke_up(motivo)`. A stamina só volta dormindo (virada do dia) ou comendo; a vida volta devagar depois de 5 segundos sem dano.
- `InputManager` (`scripts/core/input_manager.gd`): traduz o Input Map do Godot em consultas simples (`obter_direcao_movimento`, `interagir_pressionado`, `abrir_inventario_pressionado`), independente do dispositivo físico usado.
- `GameManager` (`scripts/core/game_manager.gd`): guarda a fase da história e os marcos de progresso já desbloqueados. Método principal: `desbloquear_marco`, que emite `EventBus.city_expansion_blocked`.
- `SaveManager` (`scripts/core/save_manager.gd`): grava e lê o progresso em `user://save_game.json`.
- `RealWorldManager` (`scripts/core/real_world_manager.gd`): o mundo de fora (plano 37). Sincroniza a hora inicial com o relógio do computador, troca o clima do dia pelo tempo real de Florianópolis e define a fase da Lua. Sinais `real_weather_received(clima)` e `moon_phase_changed(fase)`; `fase_da_lua`, `forcar_fase(fase)`, `configuracao()`. Não salva nada. Veja "Mundo real".
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
- `PerfilNpc` (`scripts/resources/perfil_npc.gd`): dados de um NPC, com a rotina (lista de `Compromisso`). Veja "NPCs".
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
Alvo invisível (o baú de recompensa antes do chefe cair) não conta.

**Destaque do alvo (plano 28).** A cada quadro a área confere qual é o alvo mais perto e,
quando ele muda, emite `EventBus.interaction_target_changed(alvo)` (null quando não há
nenhum, e durante uma conversa). O `DestaqueDeInteracao` (`scripts/ui/destaque_de_interacao.gd`,
na `InterfaceHUD`) ouve e faz duas coisas: põe o shader
`assets/shaders/destaque_de_interacao.gdshader` no `material_overlay` das malhas do alvo
(um brilho amarelo claro que pulsa, por cima do material, sem trocá-lo) e mostra um
balão acima dele com a tecla e o verbo. Dois métodos opcionais no interagível:
`texto_de_interacao()` devolve o verbo ("Abrir baú"; sem ele, "Interagir") e
`no_do_destaque()` devolve o nó que brilha, quando não é o próprio alvo (a entrada de
dungeon brilha o modelo ao lado). O `EfeitosDoJogo` solta um sopro pequeno no alvo novo
(`alvo_de_interacao`). Interagível novo ganha o destaque sem código novo; só o verbo é
dele.

O item solto pelo jogo (`ItemNoMundo.soltar()`) some do chão depois de
`SEGUNDOS_NO_CHAO_AO_SOLTAR` (300), piscando nos últimos segundos. O item colocado à mão
numa cena tem `segundos_ate_sumir` zero e não some. Item-chave, ferramenta e arma nunca
somem.

## Camadas de física

O jogo usa 10 camadas de colisão 3D, nomeadas no `project.godot`:

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
| 9 | `porta` | a porta da dungeon (`porta_de_dungeon.gd`) |
| 10 | `chao` | o terreno do mundo e o chão da fazenda, além da camada `mundo` |

A camada `chao` existe para quem procura onde pisar: a graminha, o deserto espalhado, os
bichos e as bolas de feno lançam o raio para baixo só nela, e por isso nada nasce em
telhado. O projétil também a usa: ele não bate no terreno, acompanha a altura dele (ver
"Combate do jogador").

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

A lixeira (`LixeiraDoInventario`) apaga para sempre a pilha solta nela, pelo mouse ou pelo
controle. O que o jogador não pode perder por conta própria é decidido num lugar só,
`Item.pode_ser_descartado()`: falso para item-chave (`item_chave`), ferramenta e arma. A
lixeira, o soltar da mão, o presente e o sumiço do item no chão consultam essa função.

## Barra de acesso rápido

A barra (`scenes/ui/barra_rapida.tscn`, no `InterfaceHUD`) mostra os 9 slots rápidos
durante o jogo, com o slot selecionado destacado e o nome do item aparecendo por dois
segundos quando a seleção muda. Ela reusa a cena do slot do inventário em modo só de
exibição (sem foco e sem arraste) e escuta dois sinais: `inventory_changed` e
`slot_selecionado_alterado`. Some enquanto o jogo está pausado.

## Plantio e colheita

**Ajuda para mirar (plano 29).** A célula onde a ação cai sai de
`GradeSolo.celula_com_ajuda()`: com semente a mira puxa para a vizinha arada e vazia, com
regador para a arada e seca, e para colher para a planta madura. A ajuda só puxa uma
célula, dentro de 2 do jogador, e enxada e picareta não têm ajuda. O `IndicadorAlvo`
marca a célula escolhida.

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

**Mira pelo mouse:** com arma de mira na mão (`tem_mira_laser`), no teclado e mouse, o
laser ou o cone segue o mouse o tempo todo, solto da frente do personagem, mesmo
andando: o `player.gd` (`direcao_da_mira()`) projeta o mouse num plano horizontal na
altura do tiro. Ao clicar, o personagem vira de uma vez para a mira e atira. No controle,
a mira é a frente do personagem. O botão de correr só corre (o "correr que planta" saiu
em 2026-10-20, a pedido do Antonio).

**Giro automático no golpe (plano 35):** no início de todo golpe e de todo tiro, o
`player.gd` (`_direcao_do_golpe`) procura o inimigo vivo (ou alvo de treino) mais perto
num cone que sai da direção da mira, e vira o personagem de uma vez para ele; o tiro sai
nessa direção. Sem ninguém no cone, vale a mira. O cone não aparece na tela. A abertura e
a folga além do alcance são da arma (`abertura_do_giro_automatico_em_graus`,
`folga_do_giro_automatico`): 110 graus e 1,2 no corpo a corpo, 50 graus e 0,5 na
escopeta. O alvo de treino entra pelo grupo `alvos_de_treino`, e não pelo dos inimigos,
que conta quem falta vencer na sala.

**Dash depois do golpe:** o golpe trava o movimento até a animação acabar, mas o dash
pode sair antes, assim que o golpe termina de acertar (65% do clipe, o export
`fracao_do_golpe_que_libera_o_dash` do player). O dash vai para onde o direcional
aponta, e só usa a frente do personagem quando não há direção.

**Contrato de dano:** quem pode levar dano tem o método
`receber_dano(quantidade: int, origem: Node3D)`. A hitbox e o projétil sobem pela árvore
a partir do corpo atingido até achar esse método. O `Inimigo` e o jogador implementam o
contrato: o golpe do jogador procura a camada `inimigo`, e o golpe do inimigo procura a
camada `jogador`.

**Projétil no relevo.** O projétil voa reto, mas não bate no terreno (camada `chao`): a
cada quadro ele lança um raio para baixo e mantém a altura que tinha sobre o chão quando
saiu da arma. Sem isso, a primeira duna na frente engolia o tiro. Por cima do rio e do
cânion ele não mergulha no leito (`CHAO_MAIS_BAIXO`). Na dungeon não há camada `chao`, e
o tiro segue reto como antes.

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
para as partículas ficarem onde nasceram. A posição entra antes de o efeito ir para a
árvore, porque ele começa a emitir no `_ready`.

São quatro cenas, uma por tipo de movimento: `poeira_de_passo` (sopro para cima),
`estouro` (para todos os lados), `jorro` (cai) e `subida_lenta`. A cor e a quantidade
mudam por ação.

O nó `EfeitosDoJogo` (`scripts/effects/efeitos_do_jogo.gd`), posto na fase, escuta os
sinais que os sistemas já emitem (arar, molhar, colher, dano, inimigo caindo, subir de
nível, troca de estação, ganhar coração) e solta o efeito no lugar certo. A tabela
`EFEITOS` dele diz, para cada ação, a cena, a cor, a quantidade e a altura. Os sistemas
não sabem que partículas existem: tirar o nó da fase tira os efeitos sem quebrar nada.
Quando falta o dado no sinal, acrescenta-se o parâmetro ou um sinal novo no `EventBus`,
em vez de dar ao sistema uma referência ao nó de efeitos. Há um teto de efeitos novos por
quadro, para a virada do dia não soltar centenas de uma vez.

**O jogo não tem sangue.** Nenhum efeito de dano é vermelho, nem no jogador nem no
inimigo: o golpe solta faísca clara, e o inimigo que cai solta faísca de metal, numa cor
fixa (e não na cor do perfil, porque o drone é avermelhado).

A poeira do passo é a exceção: o `passos_do_jogador.gd` a solta direto, na cor da
superfície sob o pé (as cores ficam no `BancoDePassos`). Efeito de feature nova segue a
regra do `CLAUDE.md`: nasce junto com a feature.

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

## Diálogo

Conversar é interagir com um NPC (`Npc.interagir()`). O `DialogueManager` (autoload) abre
a `Conversa` dele (`resources/dialogue/<id>.tres`, um Resource com a lista de `NoDialogo`)
e escolhe a fala do dia. O relógio para durante a conversa, mas o jogo não pausa.

Cada `NoDialogo` tem condições: a faixa de amizade, a estação, se o NPC namora o jogador,
e uma lista de situações pelo nome (o clima, o dia da semana, a hora, o lugar, uma data,
algo que aconteceu com o jogador). `DialogueManager.situacoes_atuais(npc_id)` é o único
lugar que pergunta aos outros sistemas quais situações valem agora. A escolha:

1. Ficam as falas em que todas as condições valem.
2. Saem as que foram ditas nos últimos 6 dias, se sobrar alguma; a de `uma_vez` sai para
   sempre depois de dita.
3. Vence a de maior `especificidade()`, que soma o peso de cada condição: o que aconteceu
   com o jogador pesa mais que o clima, que pesa mais que a faixa de amizade.
4. No empate, o número do dia escolhe, no lugar de um sorteio.

A fala escolhida vale o dia inteiro: falar de novo repete a mesma, e ela não muda se
começar a chover. A memória do que foi dito entra no save.

O texto dos personagens mora em `equipe/`: a ficha de cada um em `equipe/personas/`, e as
falas em `equipe/biblioteca-de-dialogos.md`. O guia `equipe/personas/leiame.md` tem o
formato e a tabela de condições com os pesos.

A tela é a `CaixaDialogo` (`scenes/dialogue/caixa_dialogo.tscn`): a caixa de texto embaixo
e, atrás, os modelos 3D dos dois personagens, cada um no seu palco de modelo (`ModelStage`,
veja "Interface: Theme e palco de modelo"): o jogador à esquerda, vestido com o visual
escolhido, e o morador à direita. Quem fala fica aceso e um pouco à frente; quem escuta
fica mais escuro. O texto
aparece letra por letra; o botão de interagir completa a fala e depois avança, e Esc
encerra. Com `DialogueManager.em_dialogo`, o jogador fica parado, o NPC vira para ele, a
barra rápida some e o menu de pausa não abre.

Quando o jogador chega perto o bastante para conversar, aparece um balão em cima do NPC
(o nó `Indicador` da cena do NPC). O NPC pergunta à própria área de interação do jogador
se ele é o alvo, então o balão só aparece quando o botão de interagir abriria a conversa.
Ele é amarelo enquanto a conversa de hoje ainda não aconteceu, e branco depois
(`DialogueManager.ja_conversou_hoje(npc_id)`), quando falar de novo só repete.

As conversas saem de `scripts/utils/gerar_dialogos.gd`, que transcreve
`equipe/biblioteca-de-dialogos.md` e recusa condição que o jogo não conhece. Para mudar
uma fala, edite a biblioteca e rode o gerador.

## Saque e aprimoramento

**Saque.** Cada `PerfilInimigo` tem a chance de soltar um material de cada faixa (comum,
incomum, raro). Um sorteio só decide a faixa, e o item sai da lista dela em
`resources/combat/faixas_de_material.tres` (`FaixasDeMaterial`). Inimigo mais forte tem
mais chance nas faixas de cima.

**Único.** Arma e ferramenta são únicas (`Item.e_unico()`): o jogador tem no máximo uma de
cada. A loja esconde a que ele já tem e recusa a segunda.

**Níveis.** O `UpgradeManager` (autoload) guarda o nível de cada arma e ferramenta, pelo
id do item, de 1 a 3. Subir custa uma `ReceitaDeAprimoramento` (materiais e créditos), da
`TabelaDeAprimoramento` em `resources/combat/aprimoramento.tres`. Na arma, o nível
multiplica o dano (`UpgradeManager.dano_de(arma)`, usado no golpe e no projétil). Vender a
arma apaga o nível dela.

**Ferramenta com área.** O nível da ferramenta é o máximo de área que ela alcança: um
quadrado, três em linha, três por três. No nível 1 ela age ao apertar. Aprimorada, age ao
soltar: um toque faz um quadrado, e segurar faz a marcação crescer em etapas até o máximo
do nível (`player.gd`, `_celulas_da_area` e `_usar_ferramenta_na_area`). A área maior
custa menos stamina por quadrado.

**Ferreiro.** O comerciante com `PerfilNpc.eh_ferreiro` (o Vitor) oferece, depois da
conversa, o `MenuDeServicos`: a loja ou a bancada (`TelaDeAprimoramento`).

## Save

O `SaveManager` grava o jogo inteiro num JSON em `user://save_game.json`, com uma chave
`versao`. Ele não conhece o interior de ninguém: cada sistema tem
`exportar_estado() -> Dictionary` e `importar_estado(dados)`, e o `SaveManager` só junta um
dicionário por sistema.

- **Autoloads:** estão numa lista no `SaveManager`, na ordem em que são importados (o dia
  antes de quem depende dele, o inventário antes de quem aponta para os slots).
- **Nós da fase:** entram pelo grupo `salvaveis` e dizem a própria chave com
  `chave_de_save()`. Hoje são a `GradeSolo`, o jogador e cada `Bau`.
- **Item é salvo pelo id**, e o `CatalogoDeItens` o acha de volta. Mudar um item de pasta
  não quebra o save.
- **Quem importa usa valor padrão para o que faltar**, então um save de versão antiga
  abre num jogo mais novo.
- **Quando:** salva no começo de cada dia e ao fechar a janela; carrega ao abrir, se
  houver save. `-- --sem-save` na linha de comando desliga os dois.
- **Depois de carregar** sai `EventBus.game_loaded`, e quem mostra estado na tela se
  atualiza. Carregar não emite `day_started`.

Sistema novo com estado: escreva os dois métodos e ponha o autoload na lista, ou o nó no
grupo.

## Economia

O `EconomyManager` (autoload) guarda os créditos, que são um número e não um item.

- **Comprar:** cara a cara. Depois da conversa do dia com um comerciante (NPC com
  `PerfilNpc.catalogo`), a loja abre se estiver no horário e não for Folga; fechada, ele
  diz por quê. Enquanto atende, ele mostra uma banquinha em cima da cabeça (o nó
  `IndicadorDeLoja` da cena do NPC), visível de longe e através de parede. O preço é
  `EconomyManager.preco_de_compra(item)`: o dobro do valor de
  venda, com a semente custando 60 por cento da colheita que dá, e `Item.preco_de_compra`
  para exceção escrita à mão.
- **Vender:** pelo baú de venda. O `Bau` com a função VENDER é recolhido no `day_ended`
  (dormir, cair de sono ou desmaiar): tudo que está dentro vira crédito, e o
  `ResumoDeVendas` mostra o total ao acordar.
- **Guardar:** o `Bau` com a função GUARDAR. O conteúdo de um baú é um
  `ContainerDeItens`, e a `TelaDeBau` passa pilhas inteiras entre ele e o inventário.
- **O que cada item pode fazer:** `Item.pode_ser_descartado()` (lixeira e soltar),
  `pode_ser_vendido()` (baú de venda) e `pode_ser_guardado()` (baú de guardar). Arma pode
  ser guardada e vendida, mas não descartada; ferramenta de fazenda pode ser guardada, e
  nunca vendida nem descartada; item-chave não pode nada disso.
- **Marcos:** o total já vendido (e não o saldo) desbloqueia `marco_1`, `marco_2` e
  `marco_3` no `GameManager`, e o catálogo das lojas cresce com eles
  (`CatalogoDeLoja.itens_disponiveis()`).
- **Começo do jogo:** itens e créditos vêm de `resources/items/inventario_inicial.tres`.

Os catálogos saem da tabela de `scripts/utils/gerar_npcs.gd`, que roda como cena:
`godot --headless --path game res://scenes/utils/gerar_npcs.tscn`.

## Amizade e romance

O `RelationshipManager` (autoload) guarda os pontos com cada NPC. O jogador vê corações:
250 pontos por coração, dez no máximo. Os números (conversa, presente, decaimento) estão
em `equipe/planos/16-amizade-e-romance.md`.

- **Conversar:** a conversa do dia dá ponto uma vez por dia. A fala de reação a um
  presente também passa pelo `DialogueManager`, mas não conta
  (`DialogueManager.e_conversa_do_dia`).
- **Presentear:** soltar o item da mão (`soltar_item`) com um NPC ao alcance. O jogador
  chama `Npc.receber_presente(item)`, e só tira o item do inventário se o NPC aceitar. A
  reação vem das quatro listas de gosto do `PerfilNpc`; item fora delas é neutro. Um
  presente por semana do jogo. Sem NPC por perto, o item cai no chão.
- **Faixas de fala:** os pontos decidem quais falas do dia o NPC usa
  (`NoDialogo.relacionamento_minimo` e `maximo`).
- **Falas de evento:** a reação a cada tipo de presente, o aniversário e as respostas ao
  buquê ficam em `Conversa.falas_de_evento`, e saem por
  `DialogueManager.mostrar_fala_de_evento`.
- **Decaimento:** depois de 7 dias sem conversar, perde um pouco por dia, até o piso do
  coração em que está.
- **Namoro:** o buquê é aceito por NPC romanceável, com dez corações, se o jogador não
  namora ninguém. Recusado, o buquê não é consumido.
- **Interface:** a aba Relacionamentos do menu de pausa (`AbaDeRelacionamentos`) mostra um cartão por morador com o modelo 3D, os corações, o aniversário (em rosa quando falta uma semana ou menos) e as marcas do dia: "conversou" acesa em ciano se já conversaram hoje, "presente" acesa em rosa se o presente da semana já foi dado. Os gostos não aparecem.

Os gostos saem da tabela de `scripts/utils/gerar_npcs.gd`, e as falas de evento, de
`scripts/utils/gerar_dialogos.gd`.

## Rede

O jogo conversa com um servidor de repasse por WebSocket, em JSON. O servidor não simula
nada: recebe uma mensagem com o campo `action` (a rota) e repassa a quem deve receber. É o
que o API Gateway WebSocket da AWS faz, e por isso o servidor local
(`backend/servidor_local/servidor.py`) imita isso. O protocolo está em
`equipe/planos/21-rede-e-chat.md`, e o endereço em `resources/rede/configuracao.tres`
(`ConfiguracaoDeRede`). Sem servidor, o jogo funciona offline.

A configuração tem dois endereços. `endereco` é o servidor local, usado no
desenvolvimento. `endereco_na_nuvem` é o do API Gateway da AWS (plano 18), e só vale no
jogo exportado para a Web, quando está preenchido. Assim, apontar o jogo publicado para a
nuvem não muda nada para quem desenvolve na própria máquina.

- `NetworkManager` (autoload): só a conexão e a lista de quem está online. Reconecta
  sozinho. Entrega toda mensagem pelo sinal `message_received(tipo, dados)`. Depois de
  `segundos_entre_pings` sem enviar nada, manda a ação `ping`, porque o API Gateway fecha
  a conexão que fica 10 minutos parada.
- `ChatManager` (autoload): o histórico do chat e o `enviar(texto)`. A tela é o `HudChat`.
- `LobbyManager` (autoload): a equipe da dungeon (a sala do servidor), os convites, e o
  canal de mensagens da sala (`enviar_para_a_sala` e o sinal `room_message`).
- `InputManager.teclado_capturado`: ligado enquanto o jogador digita no chat ou mexe no
  lobby. Com ele, toda pergunta de gameplay responde que nada foi pressionado.
- `AccountManager` (autoload, planos 36 e 38): a conta do jogador no Cognito da AWS, só
  com nome de usuário e senha, sem e-mail. Cria (e já entra), entra, sai e renova o ID
  token, com POSTs ao Cognito (`HTTPRequest`). O nome de usuário é único sem diferenciar
  maiúsculas, segue o `PADRAO_DO_USUARIO` (o mesmo do gatilho de cadastro na AWS) e é o
  nome no chat. Guarda o `RefreshToken` e o client id em `user://conta.cfg`, nunca a
  senha; conta guardada de outro client id é descartada. Sinais `logged_in`,
  `logged_out` e `request_failed(mensagem)`. Só existe login quando `cognito_client_id`
  está preenchido na `ConfiguracaoDeRede`.
- O `NetworkManager` pergunta o token ao `AccountManager` ao abrir a conexão e, se houver,
  acrescenta `?token=` ao endereço (o authorizer da AWS confere; o servidor local
  ignora). Token com mais de 50 minutos é renovado antes de abrir. Entrar ou sair da conta
  reconecta na hora.
- `TelaDeConta`: filha da `TelaDeLobby`, aberta pelo botão "Conta" do lobby. O lobby
  esconde o próprio painel enquanto ela está aberta e continua segurando o teclado.

## Dungeon em equipe

O multiplayer existe só na dungeon; a fazenda é de um jogador. A dungeon não é troca de
cena: o `DungeonManager` cria a cena da dungeon escolhida longe dos mapas, na mesma
fase, e leva o jogador. O relógio para, e `EventBus.dungeon_entered` e `dungeon_left`
fazem a luz ficar fixa e a chuva sumir. Ao sair, a cena é apagada e a fazenda está intacta.

Como o servidor só repassa, o jogo do anfitrião (quem criou a equipe, ou quem joga
sozinho) manda nos inimigos:

- No anfitrião os `Inimigo` são de verdade. No convidado são fantoches
  (`Inimigo.fantoche`): não pensam, seguem a posição e a vida que chegam, e repassam o
  golpe que levam.
- O outro jogador aparece como `JogadorRemoto`, um fantoche na camada `jogador`, para o
  inimigo do anfitrião conseguir acertá-lo. O dano vai por mensagem ao jogo dele.
- O inimigo escolhe o alvo mais perto no grupo `alvos_de_inimigo` (o jogador local e os
  fantoches).
- Cada jogador cuida da própria vida, experiência e saque.

O script `Dungeon` cria os inimigos nos `PontoDeInimigo` da cena e faz o envio e a
aplicação das mensagens, listadas em `equipe/planos/22-dungeon-em-coop.md`. Quem morre
volta sozinho para a fazenda; se o anfitrião morre, o jogo dele continua simulando até o
parceiro sair.

## Mapas: fazenda e mundo

O jogo tem dois mapas, a fazenda e o mundo em volta da vila (plano 26). Os dois estão
dentro da cena principal (`playground.tscn`, nó `Mapas`) o tempo todo, em lugares
distantes: a fazenda em x = -300, o mundo na origem. A dungeon continua sendo criada à
parte, em z = 400.

- **`Mapa`** é o nó raiz de cada mapa, com um `id` (`fazenda` ou `mundo`). Só um fica
  ativo; o outro fica invisível e com o processamento desligado. Parado, ele não custa
  desenho nem lógica, mas continua na árvore: o save acha os nós dele pelo grupo, a
  `GradeSolo` faz a planta crescer na virada do dia, e nada precisa ser guardado à mão.
- **`MapManager`** (autoload) liga um mapa e desliga o outro, leva o jogador até o
  marcador de chegada e emite `EventBus.map_changed`. O mapa ativo vai para o save. Ao
  acordar (dormindo ou desmaiado), a fazenda volta a ser o mapa ativo.
- **`PassagemDeMapa`** é a porteira: uma área que, quando o jogador entra, chama
  `MapManager.ir_para(mapa, chegada)`.
- **NPCs** moram no mundo. Quando o mundo volta a ficar ativo, cada um aparece onde a
  rotina manda naquela hora, em vez de seguir de onde parou.
- **Talhões.** A `GradeSolo` só aceita enxada, regador e picareta dentro de um
  `TalhaoDeCultivo` liberado (`eh_cultivavel`). O talhão é um nó no canto noroeste da área,
  com o tamanho em células.
- **Entradas de dungeon.** Cada dungeon tem uma `entrada_de_dungeon.tscn` no mundo (o
  `Portal` com `dungeon_id`). Ela abre o lobby com a dungeon já escolhida; trancada, avisa
  qual chefe falta vencer.
- **Deserto espalhado.** `EspalhadorDeObjetos` põe cópias de um modelo numa área, com
  semente fixa, desenhadas em `MultiMeshInstance3D` por blocos de 24 por 24 (uma chamada
  de desenho por bloco, e bloco fora da tela não é desenhado) e
  com um cilindro de colisão por cópia. Áreas livres (estrada, praça, canal) ficam vazias.
- **Água.** O rio, o cânion e o lago são afundados no terreno, com uma parede invisível no
  alto do barranco. Nas pontes a parede tem um vão do tamanho do tabuleiro, e um
  guarda-corpo invisível dos dois lados emenda a ponte com a parede. Se mesmo assim o
  jogador cair, o `ResgateDoJogador` (`scripts/world/resgate_do_jogador.gd`, um nó do
  mapa) o devolve ao último chão firme em que ele pisou e emite
  `EventBus.player_rescued`, que solta o efeito `resgate_da_agua`.
- **Corredores.** O mundo é andável só nas trilhas (com uma folga para cada lado) e nos
  lugares, como no Stardew Valley. O resto do deserto continua à vista, mas fica atrás de
  uma borda de cenário (muro de pedra, cerca, barreira, moita, sucata, junco, com o
  tema escolhido pelo lugar), com parede invisível. A borda sai de uma
  grade de meio em meio montada pelo gerador a partir de `desenho_do_mundo.py`
  (`TRILHAS`, `LUGARES`, `FOLGA_DOS_CORREDORES`); as peças dela são um
  `EspalhadorDeObjetos` com `posicoes_fixas`. Ponto de rotina de NPC, porta de dungeon e
  qualquer coisa que o jogador precise alcançar tem que cair dentro de um corredor: o
  gerador lista os que ficarem de fora.
- **Peças altas translúcidas.** Toda peça cujo arquivo começa com um nome de
  `MODELOS_QUE_COBREM` (casa, prédio, rochedo, palmeira, caixa d'água) ganha a
  `CoberturaTranslucida` sozinha.
- **Montagem.** As duas cenas saem de `equipe/ferramentas/gerar_mapas.py`, que reescreve a
  cena inteira. Depois de mudar o mundo, refaça a malha de navegação dele.

## Conteúdo das dungeons

São três dungeons, descritas uma a uma em `equipe/dungeons/`. O que muda entre elas é
dado, não código.

**Dados.** Cada dungeon é um `DefinicaoDeDungeon` em `resources/dungeons/`: nome, cena,
ordem, qual dungeon precisa ter sido vencida para esta abrir, e a recompensa. O
`DungeonManager` lê a pasta, guarda quais chefes já caíram e em que dia saiu a última
recompensa (as duas coisas vão para o save), e responde `esta_liberada`,
`pode_receber_recompensa` e `receber_recompensa`. O lobby lista as definições, e
`LobbyManager.iniciar(id)` leva a equipe para a escolhida.

**Salas.** A cena de uma dungeon tem um `SalaDeDungeon` por sala, com os
`PontoDeInimigo` dentro. A `Dungeon` cria os inimigos e entrega cada um à sala do ponto
dele. Inimigo de sala que ainda não acordou fica `adormecido`. Derrubar o último
inimigo da sala abre as `PortaDeDungeon` dela e acorda as salas seguintes. Nada disso
passa pela rede: a queda de cada inimigo já é igual nos dois jogos, então a sala fica
limpa em cada jogo por conta própria.

**Chefes.** `Chefe` é filho de `Inimigo`, e `PerfilChefe` é filho de `PerfilInimigo`. O
perfil traz uma lista de `AtaqueDeChefe`. O chefe sorteia um ataque, cria uma ou mais
marcas no chão (`AvisoDeAtaque`), fica parado enquanto elas enchem e só então o dano cai
em quem estiver dentro. Com metade da vida o chefe final entra na fase 2: mais rápido,
menos intervalo e os ataques marcados `so_na_fase_2`. O anfitrião decide o ataque e a
fase e avisa pela sala (`aviso_de_chefe`, `fase_de_chefe`); o convidado só desenha as
marcas. Em equipe a vida cresce `vida_a_mais_por_jogador` por jogador além do primeiro.

**Tiro.** Quando um inimigo de distância atira, o anfitrião manda `tiro` pela sala e o
convidado solta os mesmos projéteis com `Projetil.so_desenho`: voam e somem igual, mas
não tiram vida. O dano continua vindo do tiro do anfitrião, pela mensagem `dano`.

**Máquinas.** Os inimigos das dungeons são modelos de malha rígida, sem
`AnimationPlayer`. Quando o `Inimigo` não acha animação no modelo, cria um
`MaquinaAnimada`, que mexe as partes pelo nome dado no Blender (`Gira...`, `Flutua...`,
`Braco...`). A convenção está em `docs/biblia_3d.md`.

**Objetivo paralelo.** Um nó `ObjetivoParalelo` por dungeon, no grupo
`objetivo_paralelo`. As três filhas são `ObjetivoDeGeradores` (destruir os alvos antes de
o chefe cair), `ObjetivoDeResgate` (pegar as peças) e `ObjetivoDeDefesa` (o ponto perde
vida enquanto há inimigo acordado perto). O alvo avisa o objetivo por sinal, e é o
objetivo que fala com a rede. A tela ouve `EventBus.dungeon_objective_changed`.

**Recompensa.** O `BauDeRecompensa` aparece quando o chefe final cai. Ao abrir, pergunta
ao `DungeonManager`, que paga uma vez por dia e dá o troféu só na primeira vitória.

**Câmera.** A câmera olha do sul para o norte e não gira. As cenas são montadas para
ela: parede alta só ao norte, mureta ao sul, salas em fila de oeste para leste. Peça
alta no meio da sala leva um `CoberturaTranslucida`, que troca o material dela por uma
cópia translúcida enquanto a linha da câmera até o jogador (ou até um inimigo) cruza a
peça. A propriedade `transparency` do Godot não serve, porque o renderizador
Compatibility a ignora.

**Montagem das cenas.** As três cenas são geradas por
`equipe/ferramentas/gerar_dungeons.py` a partir de uma descrição curta de cada dungeon
(salas, inimigos, decoração, objetivo). O script reescreve a cena inteira; para mudar
uma dungeon, mude a descrição e gere de novo, depois refaça a malha de navegação.

## Navegação

A malha de navegação (NavMesh) é o mapa de por onde os personagens podem andar. Cada fase
tem um nó `RegiaoDeNavegacao` (`scripts/world/regiao_de_navegacao.gd`, uma
`NavigationRegion3D`) que carrega a malha pronta de `resources/navigation/`. NPCs e
inimigos têm um `NavigationAgent3D`, que devolve o próximo ponto do caminho até o destino.

A malha é calculada da colisão da camada `mundo`, com o tamanho da cápsula dos personagens
(raio 0,25, altura 0,75) e sem atravessar degrau, porque os personagens não sobem degrau.
Ela não é refeita com o jogo rodando. **Toda vez que o mapa muda, gere de novo:**

```
godot --headless --path game res://scenes/utils/gerar_malha_de_navegacao.tscn -- res://scenes/levels/NOME.tscn
```

Fase nova: pôr um nó `RegiaoDeNavegacao`, ajustar `limite_do_chao` para cobrir o mapa,
rodar o comando e apontar o `navigation_mesh` da região para o arquivo gerado. Para ver a
malha em jogo, rode com `--debug-navigation`.

## NPCs

Um NPC é a cena `scenes/npcs/npc.tscn` (`Npc`, um `CharacterBody3D` na camada `npc`), a
mesma para todos, configurada por um `PerfilNpc`. O perfil tem o modelo, a casa, o
aniversário e a rotina, que é uma lista de `Compromisso` (`scripts/resources/compromisso.gd`):
de tal a tal hora, se a estação, o dia da semana, o clima ou o aniversário baterem, ir
para tal lugar e ficar em tal pose.

- **Escolha:** a cada minuto de jogo o NPC pega o compromisso que serve para o momento.
  Se mais de um serve, vence o mais específico. Se nenhum serve, ele vai para casa. Na
  Folga e em clima com `npcs_ficam_em_casa` (a tempestade) todos ficam em casa.
- **Lugares:** a rotina cita nomes, e a fase tem os `Marker3D` com esses nomes, filhos de
  um nó do grupo `pontos_de_rotina`. O NPC não conhece o mapa.
- **Andar:** pela malha de navegação, com `walk`; ao chegar, vira para a frente do
  marcador e toca a pose do compromisso. Na virada do dia ele já aparece no lugar certo.
- **Elenco:** o nó `ElencoDeNpcs` da fase cria um NPC para cada `.tres` de
  `resources/npcs/` e de `resources/npcs/figurantes/`. Os `.tres` saem de
  `scripts/utils/gerar_npcs.gd`, que tem a tabela com a semana de cada um. São doze
  moradores e duas figurantes (plano 30). `ElencoDeNpcs.carregar_perfis()` devolve só os
  moradores, que é a lista que o calendário, a amizade e o diálogo leem.
- **Modelo:** cada um usa `assets/models/cyber_moon_personagens/personagem_<id>.glb`, um
  personagem da Kenney editado no Blender (cor e peças do tema), com o mesmo esqueleto e
  as mesmas animações. Veja `biblia_3d.md`, seção "Pessoas".
- **Figurante** (`PerfilNpc.eh_figurante`): enche o lugar (as motoqueiras do acampamento).
  Não conversa, não recebe presente e não tem amizade. Interagir com ela faz ela acenar
  (`EventBus.npc_waved`), e o balão de interação diz "Acenar".
- **Quem mora fora do mapa** (`PerfilNpc.mora_fora_do_mapa`, a Lúcia e o Zeca): a casa é o
  ponto por onde ele chega (o ponto de ônibus, o fim da estrada). Ao chegar em casa ele
  some (`visible`, colisão e física desligados) e reaparece ali no próximo compromisso.
  Os sinais `EventBus.visitor_arrived` e `visitor_left` levantam poeira nesse ponto.
- **Encenação:** dois NPCs parados em `idle` a menos de 3 metros se viram um para o outro
  e fazem gestos com um balão de conversa. Não é diálogo, que é o plano 15.

## Clima

Cada clima tem um `PerfilClima` (`scripts/resources/perfil_clima.gd`, um `.tres` por clima
em `resources/climas/`). Quem reage escuta `WeatherManager.weather_changed`:

- **Solo:** no amanhecer com clima que `molha_o_solo`, a `GradeSolo` molha todo o solo
  arado. Ela faz isso no fim do próprio `day_started`, depois de o dia secar o solo. A terra
  arada com a chuva já caindo molha sozinha depois de `segundos_para_a_chuva_molhar`.
- **Luz e névoa:** o `IluminacaoDoCiclo` multiplica a energia e a cor pelo clima, por cima
  da estação, e liga a névoa do `WorldEnvironment` com a densidade do perfil. A sombra do
  sol fica difusa: mais clara (`opacidade_da_sombra`) e de borda borrada
  (`desfoque_da_sombra`).
- **Chuva:** `scenes/effects/chuva.tscn` (`Chuva`), um `CPUParticles3D` com caixa de
  emissão larga que anda junto com o jogador. A quantidade de gotas vem do perfil.
- **Raio:** o nó `RaiosDaTempestade` sorteia um intervalo de 8 a 20 segundos, pede o
  clarão ao `IluminacaoDoCiclo.dar_clarao()` e toca o trovão de 1 a 3 segundos depois.
- **Som:** o `WeatherManager` emite `EventBus.ambience_requested` com o som do perfil, e o
  `AudioManager` toca em loop no bus `Ambiente`. Sem clipe, nada toca.
- **Relógio:** mostra o ícone do clima ao lado do período.

## Mundo real

O `RealWorldManager` liga o jogo ao mundo de fora, com três dados. A configuração fica em
`resources/mundo_real/configuracao.tres` (`ConfiguracaoMundoReal`): coordenada, endereços,
limite de espera, tabela de código WMO para clima, os números da Lua por fase e o ícone
de cada fase. Com `usar_apis` desligado, nada é consultado na rede.

- **Hora inicial:** lida do relógio do computador (`Time`), uma vez, depois que o save
  carregou (senão o save a sobrescreveria). A madrugada real, da 0:00 às 5:59, começa às
  6:00. Depois disso o `DayCycleManager` anda como sempre, e o dia só vira dormindo. Pode
  voltar a hora dentro do mesmo dia do jogo (salvou às 22:00, abriu às 10:00); não
  adianta a lavoura, porque crescer só acontece dormindo. Para testar,
  `-- --hora-real=HH:MM`.
- **Clima:** a Open-Meteo devolve o código WMO de agora, que vira `sol`, `chuva` ou
  `tempestade` pela tabela. Consultado ao abrir e a cada `day_started`; o
  `WeatherManager` escuta `real_weather_received` e chama `definir_clima()`. O clima de
  amanhã continua sorteado.
- **Fase da Lua:** o USNO devolve as fases principais a partir de 8 dias atrás, e vale a
  última até hoje. Sem resposta, uma conta local pelo mês lunar médio (erra por cerca de
  um dia). A fase segue o calendário real: dormir não a troca.
- **O que a Lua faz:** a `IluminacaoDoCiclo` multiplica a luz da noite pela
  `energia_da_lua` da fase, entrando aos poucos entre o anoitecer e a noite fechada. Na
  `GradeSolo`, a planta regada tem `chance_de_crescer` de contar um dia a mais ao dormir
  (`EventBus.moon_growth_applied`, partícula `lua_cheia`), e a colheita tem
  `chance_de_render` de dar um item a mais (`EventBus.moon_harvest_bonus`, partícula
  `colheita_da_lua`). O relógio da tela mostra o ícone da fase.

Sem rede, ou com resposta que demore mais que `segundos_de_limite`, fica a reserva (o
sorteio e a conta local) com um `push_warning`, nunca erro. O jogo não espera a rede para
começar. As duas APIs liberam CORS, então o export para a Web consulta igual.

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
trocar a hora, avançar o dia, ver de onde vieram a hora, o clima e a Lua (API ou reserva) e forçar cada fase da Lua, pular para a próxima estação, abrir o calendário, trocar o clima, cair um raio, abrir o lobby, entrar e sair da dungeon, dar corações e itens de presente, dar créditos e abrir as lojas, salvar, carregar e apagar o save, dar sucata e subir níveis, congelar o relógio, encher vida e stamina, tomar dano,
ganhar experiência, ficar invencível, teleportar, molhar o solo e amadurecer as plantas,
ganhar sementes, pães e armas, ganhar qualquer item por um submenu de ícones, soltar sucata, criar e matar inimigos, mostrar os quadros
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


## Interface: Theme e palco de modelo

O visual da interface (plano 40) sai de um Theme só, e os personagens aparecem como modelo
3D num palco reutilizável. Esta seção é o contrato para quem refaz uma tela.

### Fontes

Ficam em `assets/fonts/`, cada uma na sua pasta com a licença (`OFL.txt`, SIL Open Font
License 1.1) ao lado, baixadas do repositório `google/fonts`:

- `silkscreen/silkscreen_regular.ttf` e `silkscreen/silkscreen_bold.ttf`: títulos,
  etiquetas, abas e números grandes. Só tem maiúsculas, por desenho. Fica nítida em
  múltiplos de 8 (8, 16, 24, 32).
- `vt323/vt323_regular.ttf`: texto corrido. O tamanho base do jogo é 24, que equivale aos
  20 px do mock em 1152 por 648.

Fonte de pixel não pode ter suavização, senão a borda de cada pixel vira um borrão
cinza. Os `.ttf.import` das três estão com `antialiasing=0` (nenhum), `hinting=0`
(nenhum, para o contorno não ser puxado para fora da grade do desenho) e
`subpixel_positioning=0` (desligado, para cada letra começar num pixel inteiro). Com
`oversampling=0` a fonte é rasterizada de novo na escala da janela, então ela continua
nítida em tela cheia. Fonte nova de pixel entra com as mesmas três opções.

O projeto também usa filtro `nearest` no 2D (`rendering/textures/canvas_textures/
default_texture_filter=0` no `project.godot`), para os painéis e os ícones de pixel não
borrarem quando a janela cresce. Uma imagem que precise de suavização liga o filtro no
próprio nó (`texture_filter`).

### O Theme

`resources/ui/tema_cyber_moon.tres`, gerado por `scripts/utils/gerar_tema.gd`:

```bash
godot --headless --path game --script res://scripts/utils/gerar_tema.gd
godot --headless --path game --import
```

Na primeira vez as texturas ainda não estão importadas: rode o script, o `--import` e o
script de novo. Não edite o `.tres` no Inspector, porque a próxima geração apaga a
mudança; edite as tabelas e funções do gerador. As texturas de 9 fatias são desenhadas
pelo mesmo script em `assets/textures/ui/`, em pixel de tela (borda de 3 px, como no
mock).

O Theme é o tema padrão do projeto (`gui/theme/custom`), então **toda tela já herda dele
sem fazer nada**. Tela nova não aplica o Theme no nó raiz nem cria `StyleBoxFlat`
próprio: escolhe a variation certa em cada nó, no Inspector (`Theme Type Variation`) ou
por código (`theme_type_variation = &"PainelCiano"`). As telas antigas ainda têm
`StyleBoxFlat` e cor próprios, que os passos 4 a 8 do plano 40 trocam pelo Theme.

Padrões (sem variation):

- Fonte VT323 24, texto `texto` em `Label` e `RichTextLabel`.
- `PanelContainer` e `Panel`: painel neutro de chapa, com canto em degrau de pixel e
  sombra preta de 3 px embaixo (fora do retângulo, não ocupa layout).
- `Button`: chapa com sombra. Sob o mouse ou com foco, borda e texto ciano e uma seta na
  frente; pressionado, afunda (sem sombra); desligado, cinza azulado. A seta faz parte da
  textura dos estados acesos (no canto de cima à esquerda, que não estica), então não
  precisa de script, e o `icon` próprio de um botão continua funcionando. Ela fica
  centrada num botão de uma linha (32 px de altura); num botão mais alto, fica no alto.
- `TabBar` e `TabContainer`: abas em Silkscreen 16; a ativa é ciano cheio com texto
  escuro, e o painel do `TabContainer` é o painel neutro.
- `ProgressBar`: bateria em segmentos de 8 px com vão de 2 px, em verde. Desligue
  `show_percentage` e dê a altura por `custom_minimum_size.y` (veja abaixo).
- `LineEdit`: caixa escura de borda neutra, ciano com foco.
- `TooltipPanel`: painel neutro.

Variations:

| Variation | Base | Para quê |
|---|---|---|
| `PainelNeutro` | `PanelContainer` | Igual ao padrão, para deixar explícito |
| `PainelCiano` | `PanelContainer` | O que está em foco ou aceso, terminal de acesso |
| `PainelMagenta` | `PanelContainer` | Convite, ação destrutiva |
| `PainelOuro` | `PanelContainer` | Dinheiro, baú de venda, recompensa |
| `PainelCabecalho` | `PanelContainer` | A faixa de cabeçalho com um rebite em cada ponta; dentro, um `Label` com `TituloDoCabecalho` |
| `Titulo` | `Label` | Silkscreen 16, cor `texto` |
| `TituloDoCabecalho` | `Label` | Silkscreen 16, ciano |
| `TituloGrande` | `Label` | Silkscreen negrito 32 |
| `NumeroGrande` | `Label` | Silkscreen negrito 24 (relógio, créditos, dano) |
| `TextoApagado` | `Label` | VT323 24, cor `texto_apagado` (função do morador, dica) |
| `TeclaNaTela` | `Label` | Tecla clara com sombra; o texto é `InputManager.nome_da_tecla(acao)` |
| `TeclaPrincipal` | `Label` | A mesma tecla em ciano, para a ação principal do momento |
| `BotaoDestrutivo` | `Button` | Magenta ("Salvar e sair", descartar) |
| `BarraVida` | `ProgressBar` | Verde; altura 20 |
| `BarraStamina` | `ProgressBar` | Ouro; altura 20 |
| `BarraExperiencia` | `ProgressBar` | Ciano fina; altura 12 |
| `BarraChefe` | `ProgressBar` | Ouro; altura 24 |
| `BarraChefeFase2` | `ProgressBar` | Violeta; altura 24 |
| `SlotNormal` | `Panel` | Slot do inventário, borda neutra |
| `SlotFocado` | `Panel` | Slot com foco, ciano |
| `SlotSegurando` | `Panel` | Slot de onde o item foi pego, magenta |
| `SlotNaMao` | `Panel` | O item na mão, ouro |
| `SlotTrancado` | `Panel` | Slot ainda não liberado, com listras |
| `SlotLixeira` | `Panel` | A lixeira, roxo escuro |

Trocar o estado de um slot é trocar a variation: `slot.theme_type_variation =
&"SlotFocado"`. Trocar a barra do chefe para a fase 2 é a mesma coisa, com
`&"BarraChefeFase2"`.

### Cores

As cores ficam no Theme, no type `Cores`. Script de tela **não declara constante de cor**:
lê pela classe `CoresDaInterface` (`scripts/ui/cores_da_interface.gd`, só funções
estáticas):

```gdscript
rotulo.add_theme_color_override(&"font_color", CoresDaInterface.ouro())
var cor: Color = CoresDaInterface.cor(&"texto_apagado")
```

| Nome | Função | Papel |
|---|---|---|
| `ciano` | `ciano()` | Foco, informação, golpe crítico |
| `magenta` | `magenta()` | Segurando item, dano, convite, destrutivo |
| `ouro` | `ouro()` | Dinheiro, preço, item na mão, stamina |
| `verde` | `verde()` | Vida, ganho, cura, o que se tem |
| `rosa` | `rosa()` | Corações, aniversário |
| `violeta` | `violeta()` | Fase 2 do chefe, desmaio, madrugada |
| `ambar` | `ambar()` | Aviso, erro, o que falta (o que antes era vermelho) |
| `texto` | `texto()` | Texto |
| `texto_apagado` | `texto_apagado()` | Texto secundário |
| `desligado` | `desligado()` | Botão desligado, item que não dá para pagar |
| `fundo_painel` | `fundo_painel()` | Fundo de painel |
| `borda` | `borda()` | Borda neutra |
| `borda_escura` | `borda_escura()` | Borda de dentro, aba inativa |
| `noite` | `noite()` | Texto sobre fundo aceso (aba ativa, tecla) |
| `lixeira` | `lixeira()` | A lixeira do inventário |

Nada vermelho em lugar nenhum. Número de dano: `magenta()` normal, `ciano()` crítico,
`verde()` cura. Cor nova entra no dicionário `CORES` do gerador e ganha uma função aqui.

### Palco de modelo

`scenes/ui/palco_de_modelo.tscn`, classe `ModelStage` (`scripts/ui/palco_de_modelo.gd`).
É um `Control` que ocupa o retângulo que a tela der a ele; dentro, um `SubViewport` com
mundo próprio, câmera, luz, um brilho e uma luz ciano no chão. Ele anima com o jogo
pausado (`process_mode` sempre), porque o menu de pausa também mostra modelo.

Para pôr na tela: instancie a cena como filho, ajuste âncoras e tamanho como qualquer
`Control`, marque com nome único (`%PalcoDoMorador`) e chame pelo script da tela.
Propriedades no Inspector:

- `posicao_do_modelo` (padrão `(0, 0.2, 0)`): onde ficam os pés; o x desloca o modelo para
  o lado dentro do palco.
- `giro_inicial_graus`: zero é de frente para a câmera; positivo vira para a direita.
- `distancia_da_camera` (2.2), `altura_da_camera` (0.5) e `campo_de_visao` (30): o
  enquadramento. Menos campo de visão, modelo maior.
- `gira_com_mouse_e_direcional`: arrastar com o botão esquerdo ou o direcional direito
  do controle (`InputManager.giro_do_direcional_direito()`) gira o modelo. Para a aba de
  equipamento.
- `mostrar_brilho_do_chao`: o brilho ciano embaixo dos pés.

Funções:

| Função | O que faz |
|---|---|
| `mostrar_cena(cena: PackedScene)` | Mostra um modelo qualquer |
| `mostrar_npc(id: String) -> bool` | Pelo `PerfilNpc` em `resources/npcs/<id>.tres` (ou a pasta das figurantes) |
| `mostrar_protagonista(id: StringName) -> bool` | Pelo `PerfilProtagonista` em `resources/protagonistas/<id>.tres` |
| `mostrar_jogador()` | O jogador desta máquina, com o visual que está vestindo |
| `mostrar_por_id(id: StringName) -> bool` | `&"jogador"`, id de morador ou id de protagonista |
| `tocar(clipe: StringName)` | Toca um clipe; clipe que não existe vira `idle` |
| `definir_aceso(aceso: bool, imediato := false)` | Aceso: claro e à frente. Apagado: mais escuro |
| `esta_aceso() -> bool` | |
| `limpar()` | Tira o modelo |
| `modelo() -> Node3D` e `animacao() -> AnimationPlayer` | Para mexer no modelo (vestir, trocar arma) |
| `tirar_foto() -> Texture2D` | Modo foto, com `await`; emite `foto_tirada(foto)` |
| `voltar_a_animar()` e `esta_em_foto() -> bool` | Desfaz o modo foto |

O palco usa o próprio `modulate` para apagar quem escuta: não mexa no `modulate` dele de
fora. Para esmaecer a tela inteira, use o `modulate` de um pai.

**Modo foto.** Para tela com muitos modelos (a aba de relacionamentos, com até catorze):
`await palco.tirar_foto()` renderiza uma vez, troca a imagem animada por uma foto parada,
para de renderizar o `SubViewport` e pausa a animação. Anime só o cartão focado
(`voltar_a_animar()` nele e `tirar_foto()` no que perdeu o foco). Funciona com o palco
ainda escondido numa aba fechada. `mostrar_*` num palco em foto volta a animar sozinho.

**Mistura pré-multiplicada.** O `SubViewport` transparente guarda a cor já multiplicada
pelo alfa. Desenhado com a mistura comum, a borda semitransparente (o brilho do chão)
escurece o que está atrás. Por isso a `Tela` e a `Foto` do palco usam um
`CanvasItemMaterial` com `blend_mode` pré-multiplicado. Quem mostrar uma
`ViewportTexture` transparente fora do palco precisa do mesmo material.

Exemplo, a conversa (`caixa_dialogo.gd`):

```gdscript
@onready var palco_do_jogador: ModelStage = %PalcoDoJogador
@onready var palco_do_morador: ModelStage = %PalcoDoMorador

palco_do_morador.mostrar_cena(npc.perfil.modelo)
palco_do_jogador.mostrar_jogador()
quem_fala.tocar(no.animacao)
quem_fala.definir_aceso(true)
quem_escuta.definir_aceso(false)
```

### Menu de pausa

`scenes/ui/menu_pausa.tscn` tem uma fileira de abas (`TabBar` sem foco, com a `TeclaNaTela` de `aba_anterior` e `aba_seguinte` dos dois lados) e uma página por aba dentro de `Paginas`; trocar de aba só mostra uma e esconde as outras. A ordem está em `NOMES_DAS_ABAS` no `menu_pausa.gd`. Diário, Mapa e Opções ainda são páginas reservadas (planos 32 e 33, e a tela de opções do plano 40): quem fizer o conteúdo troca a página pela cena nova, com o mesmo nome único.

- **Inventário:** mochila (`PainelNeutro` com `PainelCabecalho`), uma linha de `SlotTrancado` só visual (não existe mochila maior ainda), barra rápida com o item em uso em `SlotNaMao`, lixeira em `SlotLixeira` e o cartão do item focado em `PainelCiano`. O estado de cada `SlotInventario` é a variation (segurando, focado, na mão, normal, nessa ordem).
- **Equipamento:** `AbaDeEquipamento` (`scripts/ui/aba_de_equipamento.gd`), só para olhar: arma na mão (ou o punho do jogador), ferramentas, armadura, acessório, troféus por dungeon (trancado até vencer o chefe), o jogador num `ModelStage` que gira, nível e experiência, e os números com a comparação de troca pela primeira outra arma da mochila (ganho em verde, perda em âmbar).
- **Relacionamentos:** `AbaDeRelacionamentos` monta um `CartaoDeMorador` por perfil de `resources/npcs/` uma vez só. Cada cartão tem um `ModelStage` pequeno em modo foto; só o cartão com foco anima. Medido com os doze moradores: cerca de 9 ms por quadro em modo foto contra 12 a 13 ms com todos animando. **Palco que ainda não passou pelo container precisa de tamanho antes da foto** (`tirar_foto()` usa o tamanho atual do SubViewport); o cartão faz isso.
- **Calendário:** `GradeDoCalendario` (`scenes/ui/grade_do_calendario.tscn`) é o conteúdo, usado pela aba e pela tela `Calendario` do quadro no mundo. Seis colunas, Folga em roxo, hoje em `SlotFocado`, aniversário em rosa, e a Lua de cada dia pela conta local do `RealWorldManager.fase_calculada_localmente` (hoje usa a `fase_da_lua` de verdade).

`CoracaoDePixel` (`scripts/ui/coracao_de_pixel.gd`) é o coração de pixel da interface, desenhado em código porque as fontes não têm o caractere; quem mostra pinta com o `modulate`. `FileiraDeCoracoes` (`scripts/ui/fileira_de_coracoes.gd`, `mostrar(cheios)`) monta os dez corações da amizade com ele, e é usada na conversa e nos cartões de morador.

### Telas de serviço e HUD

- A conversa (`caixa_dialogo`) mostra os corações do morador com a `FileiraDeCoracoes` e o nome numa etiqueta; o menu de serviços e a loja mostram o lojista em pé num `ModelStage` (`%PalcoDoLojista`).
- A loja tem as abas Comprar e Vender; a aba Vender só explica o baú de venda. O `ResumoDeVendas` é um cupom de papel que escuta `item_sold` e `sale_completed`.
- O aviso (`HudAviso`) fica no alto, no meio. A barra do chefe (`HudDoChefe`) entra no grupo `barra_do_chefe`, e o aviso desce para logo abaixo dela enquanto ela está visível. A barra troca de fase pela variation (`BarraChefe` ou `BarraChefeFase2`) e mostra os golpes da fase.
- O relógio fica âmbar e com painel magenta depois da meia-noite; os créditos mostram o ganho em verde e o gasto em âmbar. O lobby mostra cada dungeon num cartão com o estado, e o convite é um painel magenta com barra de tempo.
