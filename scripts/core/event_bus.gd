extends Node

signal crop_harvested(cultivo: Cultivo, quantidade: int)
signal city_expansion_blocked(id_do_marco: String)
signal npc_relationship_changed(id_do_npc: String, novo_valor: int)
signal tile_plowed(celula: Vector2i)
signal tile_watered(celula: Vector2i)
