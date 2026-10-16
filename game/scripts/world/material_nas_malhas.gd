class_name MaterialNasMalhas
extends Node

## Põe um material por cima de todas as malhas do modelo pai.
##
## Serve para o modelo importado que precisa de um material do jogo, e não o do arquivo:
## a água do rio e do aquífero vem do Blender sem material, e ganha aqui o shader toon de
## água. Fica como filho da instância do modelo.

@export var material: Material

func _ready() -> void:
	if material == null:
		return
	for no in get_parent().find_children("*", "MeshInstance3D", true, false):
		(no as MeshInstance3D).material_override = material
