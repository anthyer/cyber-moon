@tool
extends EditorScenePostImport

## Normaliza os materiais dos pacotes de modelos da Kenney na importação.
##
## Os modelos são exportados com metallicFactor 1.0 no glTF. Com esse valor o
## Godot trata a cor do albedo como cor de reflexo e zera a componente difusa,
## deixando tudo escuro. Como esses materiais tiram a cor inteira do albedo, o
## componente metálico não acrescenta nada e é zerado aqui.

const RUGOSIDADE_PADRAO: float = 0.9

func _post_import(cena: Node) -> Object:
	_normalizar_materiais(cena)
	return cena

func _normalizar_materiais(no: Node) -> void:
	if no is MeshInstance3D:
		var malha: Mesh = (no as MeshInstance3D).mesh
		if malha != null:
			for indice in malha.get_surface_count():
				var material: Material = malha.surface_get_material(indice)
				if material is BaseMaterial3D:
					var base := material as BaseMaterial3D
					base.metallic = 0.0
					base.roughness = RUGOSIDADE_PADRAO
					base.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	for filho in no.get_children():
		_normalizar_materiais(filho)
