# Arquitetura

Este documento descreve os sistemas globais (autoloads) e o modelo de dados do Cyber Moon.

## Autoloads

- `EventBus` (`scripts/core/event_bus.gd`): declara sinais globais usados por sistemas que não precisam se conhecer diretamente. Sinais atuais: `crop_harvested`, `city_expansion_blocked`, `npc_relationship_changed`, `tile_plowed`, `tile_watered`, `tile_removed`, `musica_solicitada` e `item_picked_up(item, quantidade)`, emitido quando o jogador pega um item do chão.
- `DayCycleManager` (`scripts/core/day_cycle_manager.gd`): controla o número do dia e a hora atual. Sinais próprios: `day_started`, `day_ended`. Método principal: `avancar_para_o_proximo_dia()`.
- `InventoryManager` (`scripts/core/inventory_manager.gd`): guarda as quantidades de cada `Item` no inventário do jogador. Métodos: `adicionar_item`, `remover_item`, `obter_quantidade`.
- `InputManager` (`scripts/core/input_manager.gd`): traduz o Input Map do Godot em consultas simples (`obter_direcao_movimento`, `interagir_pressionado`, `abrir_inventario_pressionado`), independente do dispositivo físico usado.
- `GameManager` (`scripts/core/game_manager.gd`): guarda a fase da história e os marcos de progresso já desbloqueados. Método principal: `desbloquear_marco`, que emite `EventBus.city_expansion_blocked`.
- `SaveManager` (`scripts/core/save_manager.gd`): grava e lê o progresso em `user://save_game.json`.
- `AudioManager` (`scripts/core/audio_manager.gd`): Ponto único de reprodução de som do jogo com piscina de tocadores reutilizados para SFX.

Cada autoload tem responsabilidade única. Quando um autoload começar a acumular lógica de um domínio diferente do seu, isso é sinal de que uma responsabilidade nova precisa de seu próprio autoload.

## Dados de jogo como Resources

Conteúdo de jogo é representado por classes `Resource` customizadas, definidas em `scripts/resources/` e instanciadas como arquivos `.tres` em `resources/`:

- `Item` (`scripts/resources/item.gd`): um item do inventário, com `id` estável, `categoria` (enum `Item.Categoria`), ícone e valor de venda. Filhas: `Ferramenta`, `Semente` (aponta o `Cultivo`) e `Consumivel` (vida e stamina recuperadas).
- `Cultivo` (`scripts/resources/cultivo.gd`): uma cultura plantável na fazenda.
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
