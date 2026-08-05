# Arquitetura

Este documento descreve os sistemas globais (autoloads) e o modelo de dados do Cyber Moon.

## Autoloads

- `EventBus` (`scripts/core/event_bus.gd`): declara sinais globais usados por sistemas que nao precisam se conhecer diretamente. Sinais atuais: `crop_harvested`, `city_expansion_blocked`, `npc_relationship_changed`.
- `DayCycleManager` (`scripts/core/day_cycle_manager.gd`): controla o numero do dia e a hora atual. Sinais proprios: `day_started`, `day_ended`. Metodo principal: `avancar_para_o_proximo_dia()`.
- `InventoryManager` (`scripts/core/inventory_manager.gd`): guarda as quantidades de cada `Item` no inventario do jogador. Metodos: `adicionar_item`, `remover_item`, `obter_quantidade`.
- `InputManager` (`scripts/core/input_manager.gd`): traduz o Input Map do Godot em consultas simples (`obter_direcao_movimento`, `interagir_pressionado`, `abrir_inventario_pressionado`), independente do dispositivo fisico usado.
- `GameManager` (`scripts/core/game_manager.gd`): guarda a fase da historia e os marcos de progresso ja desbloqueados. Metodo principal: `desbloquear_marco`, que emite `EventBus.city_expansion_blocked`.
- `SaveManager` (`scripts/core/save_manager.gd`): grava e le o progresso em `user://save_game.json`.

Cada autoload tem responsabilidade unica. Quando um autoload comecar a acumular logica de um dominio diferente do seu, isso e sinal de que uma responsabilidade nova precisa de seu proprio autoload.

## Dados de jogo como Resources

Conteudo de jogo e representado por classes `Resource` customizadas, definidas em `scripts/resources/` e instanciadas como arquivos `.tres` em `resources/`:

- `Item` (`scripts/resources/item.gd`): um item do inventario.
- `Cultivo` (`scripts/resources/cultivo.gd`): uma cultura plantavel na fazenda.
- `PerfilNpc` (`scripts/resources/perfil_npc.gd`): dados de um NPC.
- `NoDialogo` (`scripts/resources/no_dialogo.gd`): um no de uma arvore de dialogo.

Um novo cultivo, item ou NPC vira um arquivo `.tres` criado no editor, sem exigir codigo novo.

## Composicao de cenas

Entidades do jogo usam heranca de cena padrao do Godot. Nos de comportamento reutilizaveis sao extraidos como cenas proprias e instanciados como filhos quando o mesmo comportamento se repete em mais de um tipo de entidade.
