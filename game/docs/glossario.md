# Glossário

Mapeamento entre termos de design em português e os nomes técnicos correspondentes usados no código em inglês.

| Termo de design | Nome técnico |
|---|---|
| Cultivo | Crop / `Cultivo` (classe Resource) |
| Colheita | Harvest / sinal `crop_harvested` |
| Item | Item / `Item` (classe Resource) |
| Inventário | Inventory / `InventoryManager` |
| Ciclo de dias | Day cycle / `DayCycleManager` |
| Marco de progresso | Progress milestone / `GameManager.marcos_desbloqueados` |
| Expansão da cidade | City expansion / sinal `city_expansion_blocked` |
| Perfil de NPC | NPC profile / `PerfilNpc` (classe Resource) |
| Nó de diálogo | Dialogue node / `NoDialogo` (classe Resource) |
| Banco de passos | Footsteps bank / `BancoDePassos` (classe Resource) |
| Superfície | Surface / metadata `superficie` |
| Item no chão | Dropped item / `ItemNoMundo` (cena e classe) |
| Pegar item | Pick up item / sinal `item_picked_up`, método `ItemNoMundo.coletar()` |
| Pilha de itens | Item stack / `PilhaDeItens` (classe Resource) |
| Espaço de equipamento | Equipment slot / enum `InventoryManager.Espaco` |
| Item equipado (em uso) | Item in use / espaço `Espaco.EM_USO`, `EquipmentManager.item_em_uso()` |
| Soqueira | Brass knuckles / item `soqueira`, categoria ARMA, o soco do jogador |
| Menu de pausa | Pause menu / cena `menu_pausa.tscn`, também a tela do inventário |
| Ímã de coleta | Item magnet / `AreaDeAtracao` e `AreaDeColeta` do `ItemNoMundo` |
| Área de interação | Interaction area / `AreaDeInteracao`, nó `AreaInteracao` do jogador |
| Interagir | Interact / método `interagir()` em todo nó interagível |
