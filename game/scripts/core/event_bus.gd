extends Node

signal crop_harvested(cultivo: Cultivo, quantidade: int)
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
