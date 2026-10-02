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
| Item na mão (equipado) | Item in hand / slot rápido selecionado, `EquipmentManager.item_na_mao()` |
| Barra de acesso rápido | Hotbar / cena `barra_rapida.tscn`, slots 0 a 8 do inventário |
| Cestos | Caestus (luva de couro com tiras dos pugilistas antigos) / item `cestos`, categoria ARMA, o soco do jogador |
| Menu de pausa | Pause menu / cena `menu_pausa.tscn`, também a tela do inventário |
| Ímã de coleta | Item magnet / `AreaDeAtracao` e `AreaDeColeta` do `ItemNoMundo` |
| Área de interação | Interaction area / `AreaDeInteracao`, nó `AreaInteracao` do jogador |
| Interagir | Interact / método `interagir()` em todo nó interagível |
| Planta na grade | Planted crop / classe interna `GradeSolo.PlantaNaGrade` |
| Estágio de crescimento | Growth stage / `Cultivo.estagios_de_crescimento`, sinal `crop_grown` |
| Planta murcha | Withered crop / `PlantaNaGrade.murcha`, sinal `crop_withered` |
| Rebrota | Regrowth / `Cultivo.estagio_de_rebrota` |
| Stamina (fôlego) | Stamina / `StatusManager.stamina_atual`, sinal `stamina_changed` |
| Desmaio, queda | Fainting / sinais `player_fainted` e `player_woke_up`, enum `StatusManager.Motivo` |
| Custos de ação | Action costs / `CustosDeAcao` (classe Resource) |
| Ponto de spawn | Spawn point / `Marker3D` `PontoDeSpawn`, a casa do jogador |
| Arma | Weapon / `Arma` (classe Resource), enum `Arma.Tipo` |
| Área de acerto | Hitbox / nó `HitboxAtaque`, script `AtaqueDoJogador` |
| Mira | Aim guide / `Arma.tem_mira_laser`; linha de laser (`FeixeDoLaser`) ou área do cone no chão (`AreaDoCone`) |
| Disparo em leque | Spread shot / `Arma.projeteis_por_disparo`, `Arma.abertura_do_cone_em_graus` |
| Projétil | Projectile / `Projetil` (cena e classe) |
| Inimigo | Enemy / `Inimigo` (cena e classe), configurado por `PerfilInimigo` (classe Resource) |
| Alvo de treino | Training dummy / `AlvoDeTreino`, boneco que leva dano e não revida |
| Reação a dano | Damage reaction / `ReacaoADano` (cena e classe) |
| Efeito de partículas | Particle effect / `EfeitoDeParticulas`, cenas em `scenes/effects/` |
