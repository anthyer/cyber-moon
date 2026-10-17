extends Node

## A célula entrou no fim para o efeito de colheita saber onde aparecer.
signal crop_harvested(cultivo: Cultivo, quantidade: int, celula: Vector2i)
signal city_expansion_blocked(id_do_marco: String)
signal npc_relationship_changed(id_do_npc: String, novo_valor: int)
signal tile_plowed(celula: Vector2i)
signal tile_watered(celula: Vector2i)
signal tile_removed(celula: Vector2i)
signal musica_solicitada(faixa: AudioStream)
signal item_picked_up(item: Item, quantidade: int)
signal crop_planted(celula: Vector2i, cultivo: Cultivo)
signal crop_grown(celula: Vector2i, novo_estagio: int)
signal crop_withered(celula: Vector2i)
signal crop_removed(celula: Vector2i)
signal damage_dealt(alvo: Node3D, quantidade: int)
signal enemy_defeated(perfil: PerfilInimigo, posicao: Vector3)
## Um aviso curto na tela, como "Tomate não cresce no Apagão". Quem mostra é o HudAviso.
signal notice_requested(texto: String)
## Algo no mundo (o quadro de calendário) pediu para abrir a tela do calendário.
signal calendar_requested
## Som de ambiente em loop, como a chuva. Nulo pede para parar o que estiver tocando.
signal ambience_requested(fluxo: AudioStream)
## A entrada de uma dungeon pediu para abrir a tela de lobby, com essa dungeon escolhida.
signal lobby_requested(dungeon_id: StringName)
## O mapa ativo trocou (fazenda ou mundo). Os NPCs do mapa que voltou se reposicionam.
signal map_changed(mapa_id: StringName)
## O jogador entrou ou saiu da dungeon. A luz, a chuva e o relógio reagem.
signal dungeon_entered
signal dungeon_left
## O jogador conversou com um comerciante que está com a loja aberta.
signal shop_requested(perfil: PerfilNpc)
## O jogador interagiu com um baú, de guardar ou de venda.
signal chest_requested(bau: Bau)
## Um jogo salvo acabou de ser carregado. Quem mostra estado na tela se atualiza aqui.
signal game_loaded
## Momentos que só existem para quem mostra algo na tela (o EfeitosDoJogo): onde um
## projétil bateu, onde o jogador começou um dash, e o que ele comeu.
signal projectile_impacted(posicao: Vector3)
signal player_dashed(posicao: Vector3)
## O jogador caiu na água e foi posto de volta no chão (o ResgateDoJogador).
signal player_rescued(posicao: Vector3)
signal item_consumed(consumivel: Consumivel)
signal rare_loot_dropped(posicao: Vector3, cor: Color)
## O comerciante que também é ferreiro oferece os dois serviços; a escolha pede um deles.
signal services_requested(perfil: PerfilNpc)
signal forge_requested(perfil: PerfilNpc)
## Dungeon (plano 23). Emitidos para quem mostra algo na tela: a barra do chefe, a linha
## do objetivo paralelo e os efeitos de partícula.
signal dungeon_room_cleared(posicao: Vector3)
signal dungeon_door_opened(posicao: Vector3)
signal boss_engaged(chefe: Node3D)
signal boss_phase_changed(chefe: Node3D, fase: int)
signal boss_attack_landed(posicao: Vector3, raio: float, cor: Color)
signal boss_defeated(chefe: Node3D)
signal dungeon_objective_changed(texto: String, concluido: bool)
signal dungeon_objective_progress(posicao: Vector3)
signal dungeon_reward_claimed(posicao: Vector3)
