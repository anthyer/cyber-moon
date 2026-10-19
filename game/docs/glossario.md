# Glossário

Mapeamento entre termos de design em português e os nomes técnicos correspondentes usados no código em inglês.

| Termo de design | Nome técnico |
|---|---|
| Cultivo | Crop / `Cultivo` (classe Resource) |
| Colheita | Harvest / sinal `crop_harvested` |
| Item | Item / `Item` (classe Resource) |
| Inventário | Inventory / `InventoryManager` |
| Ciclo de dias | Day cycle / `DayCycleManager` |
| Estação | Season / `SeasonManager`, sinal `season_changed` |
| Perfil de estação | Season profile / `PerfilEstacao` (classe Resource) |
| Brotação, Estiagem, Colheita, Apagão | ids `brotacao`, `estiagem`, `colheita`, `apagao` (primavera, verão, outono, inverno) |
| Saque, faixa de material | Loot / `FaixasDeMaterial`, `PerfilInimigo.chance_de_material_*` |
| Aprimorar, nível | Upgrade / `UpgradeManager`, `ReceitaDeAprimoramento`, `TabelaDeAprimoramento` |
| Ferreiro, bancada | Blacksmith / `PerfilNpc.eh_ferreiro`, `MenuDeServicos`, `TelaDeAprimoramento` |
| Item único | Unique item / `Item.e_unico()` |
| Salvar, carregar | Save, load / `SaveManager`, `exportar_estado()` e `importar_estado()`, grupo `salvaveis`, sinal `game_loaded` |
| Catálogo de itens | Item catalog / `CatalogoDeItens.por_id()` |
| Crédito, economia | Credits / `EconomyManager`, sinais `credits_changed` e `sale_completed` |
| Loja, catálogo | Shop / `CatalogoDeLoja` (classe Resource), `TelaDeLoja`, sinal `shop_requested` |
| Baú de guardar, baú de venda | Storage chest, shipping chest / `Bau`, `ContainerDeItens`, `TelaDeBau` |
| Marco | Milestone / `GameManager.desbloquear_marco()` |
| Amizade, corações | Relationship, hearts / `RelationshipManager`, sinais `relationship_changed` e `heart_gained` |
| Presentear | Gift / `Npc.receber_presente()`, ação `soltar_item` |
| Gostos | Likes / `PerfilNpc.itens_amados`, `itens_queridos`, `itens_indesejados`, `itens_odiados` |
| Namoro | Dating / `RelationshipManager.pedir_em_namoro()`, sinal `dating_started` |
| Fala de evento | Event line / `Conversa.falas_de_evento` |
| Diálogo, conversa, fala | Dialogue / `DialogueManager`, `Conversa` e `NoDialogo` (classes Resource), `CaixaDialogo` |
| Efeito de partícula | Particle effect / `EfeitoDeParticulas.soltar()`, `EfeitosDoJogo` |
| Persona | Persona / fichas em `equipe/personas/` |
| Situação (condição de fala) | Dialogue condition / `NoDialogo.situacoes`, `DialogueManager.situacoes_atuais()` |
| Fala do dia | Daily line / `DialogueManager.fala_do_dia()` |
| Servidor de repasse | Relay server / `backend/servidor_local/`, `NetworkManager` |
| Chat | Chat / `ChatManager`, `HudChat` |
| Equipe, sala, anfitrião | Party, room, host / `LobbyManager`, `sou_anfitriao()` |
| Dungeon | Dungeon / `DungeonManager`, `Dungeon` (cena), sinais `dungeon_entered` e `dungeon_left` |
| Fantoche | Puppet / `JogadorRemoto`, `Inimigo.fantoche` |
| Malha de navegação | NavMesh / `RegiaoDeNavegacao`, `NavigationAgent3D` |
| Rotina, compromisso | Routine, appointment / `PerfilNpc.rotina`, `Compromisso` (classe Resource) |
| Ponto de rotina | Routine point / `Marker3D` no grupo `pontos_de_rotina` |
| Elenco | Cast / `ElencoDeNpcs` |
| Clima | Weather / `WeatherManager`, sinal `weather_changed`, `PerfilClima` (classe Resource) |
| Sol, Chuva, Tempestade | ids `sol`, `chuva`, `tempestade` |
| Som de ambiente | Ambience / sinal `ambience_requested`, `AudioManager.tocar_ambiente()` |
| Calendário | Calendar / `Calendario` (tela), sinal `calendar_requested`, `QuadroCalendario` |
| Dia da semana, Folga | Weekday / `SeasonManager.dia_da_semana()`, `DIA_DE_FOLGA` |
| Aniversário | Birthday / `PerfilNpc.estacao_do_aniversario`, `dia_do_aniversario` |
| Aviso na tela | Notice / sinal `notice_requested`, `HudAviso` |
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
| Malha de navegação | NavMesh / `NavigationRegion3D` (a malha) e `NavigationAgent3D` (quem anda por ela); prevista para o plano 14 |
| Inimigo | Enemy / `Inimigo` (cena e classe), configurado por `PerfilInimigo` (classe Resource) |
| Alvo de treino | Training dummy / `AlvoDeTreino`, boneco que leva dano e não revida |
| Reação a dano | Damage reaction / `ReacaoADano` (cena e classe) |
| Efeito de partículas | Particle effect / `EfeitoDeParticulas`, cenas em `scenes/effects/` |
| Menu de debug | Debug menu / `MenuDebug` (cena e classe), tecla F3 |
| Período do dia | Day period / enum `DayCycleManager.Periodo` (madrugada, manhã, tarde, anoitecer, noite) |
| Cair de sono | Forced sleep / `DayCycleManager.dormir(true)`, `StatusManager.Motivo.SONO` |
| Cama | Bed / `Cama` (cena e classe), dormir sem penalidade |
| Luz do jogador | Player light / `OmniLight3D` `LuzDoJogador` |
| Definição de dungeon | Dungeon definition / `DefinicaoDeDungeon` (classe Resource), um `.tres` por dungeon em `resources/dungeons/` |
| Sala de dungeon | Dungeon room / `SalaDeDungeon`, acorda os inimigos dela e abre a porta quando fica limpa |
| Porta de dungeon | Dungeon door / `PortaDeDungeon`, na camada de física `porta` |
| Subchefe e chefe | Miniboss and boss / `Chefe` (cena e classe, filha de `Inimigo`), configurado por `PerfilChefe` |
| Ataque anunciado | Telegraphed attack / `AtaqueDeChefe` (classe Resource) e `AvisoDeAtaque` (a marca no chão) |
| Segunda fase | Second phase / `Chefe.fase`, sinal `EventBus.boss_phase_changed` |
| Objetivo paralelo | Side objective / `ObjetivoParalelo` e as filhas `ObjetivoDeGeradores`, `ObjetivoDeResgate`, `ObjetivoDeDefesa` |
| Baú de recompensa | Reward chest / `BauDeRecompensa`, paga pelo `DungeonManager.receber_recompensa` |
| Troféu de chefe | Boss trophy / `Item` com `item_chave`, em `resources/items/especiais/trofeu_*.tres` |
| Máquina animada | Code-driven machine / `MaquinaAnimada`, mexe as partes de um modelo sem esqueleto pelo nome delas |
| Cobertura translúcida | See-through cover / `CoberturaTranslucida`, deixa translúcida a peça que esconde o jogador |
| Paleta de cores | Colormap / `colormap.png`, a textura única de cada pacote de modelos |
| Mapa (fazenda, mundo) | Map / `Mapa` (nó raiz de cada mapa), trocado pelo `MapManager` |
| Mapa mundi | World map / `scenes/levels/mundo.tscn` |
| Porteira | Map passage / `PassagemDeMapa`, a área que leva de um mapa ao outro |
| Talhão | Farm plot / `TalhaoDeCultivo`, onde a enxada funciona |
| Entrada de dungeon | Dungeon entrance / `Portal` com `dungeon_id`, em `scenes/world/entrada_de_dungeon.tscn` |
| Espalhador | Scatter / `EspalhadorDeObjetos`, cópias em MultiMesh |
| Destaque de interação | Interaction highlight / `DestaqueDeInteracao`, o brilho e o balão no alvo do botão de interagir |
| Verbo de interação | Interaction label / `texto_de_interacao()`, o que o balão diz ("Abrir baú") |
