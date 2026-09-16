@tool
extends EditorScenePostImport

## Normaliza os materiais dos pacotes de modelos da Kenney na importação e gera a
## colisão estática do cenário.
##
## Os modelos são exportados com metallicFactor 1.0 no glTF. Com esse valor o
## Godot trata a cor do albedo como cor de reflexo e zera a componente difusa,
## deixando tudo escuro. Como esses materiais tiram a cor inteira do albedo, o
## componente metálico não acrescenta nada e é zerado aqui.
##
## A colisão é gerada aqui, e não à mão na cena, porque o playground instancia
## centenas de cópias dos mesmos modelos. Gerando na importação, um modelo
## corrigido conserta todas as instâncias dele de uma vez.

const RUGOSIDADE_PADRAO: float = 0.9

const CAMADA_MUNDO: int = 1

## Modelos cujo nome contém um destes trechos não recebem colisão. São decoração
## que o jogador precisa poder atravessar, senão andar pelo mapa vira um labirinto
## de tufos de grama invisíveis. Modelos de personagem também ficam de fora: eles
## são instanciados como filhos do CharacterBody3D, e ter um StaticBody3D dentro de
## um corpo que se move faz o move_and_slide() interpretar o contato como plataforma
## em movimento, lançando o personagem para cima indefinidamente.
const TRECHOS_SEM_COLISAO: Array[String] = [
	"character", "animal",
	"grass", "flower", "mushroom", "plant_", "crops_",
	"mulch", "mound", "mark_", "mark-",
]

## Mapeamento de trecho do nome do arquivo para superfície. A primeira entrada que
## casar vence, então a ordem importa: "path_stone" precisa vir antes de "path".
const SUPERFICIE_POR_TRECHO: Array = [
	["water", &"agua"],
	["river", &"agua"],
	["lake", &"agua"],
	["road", &"asfalto"],
	["driveway", &"asfalto"],
	["sidewalk", &"pedra"],
	["path_stone", &"pedra"],
	["stone", &"pedra"],
	["cliff", &"pedra"],
	["rock", &"pedra"],
	["bridge", &"madeira"],
	["log_", &"madeira"],
	["plank", &"madeira"],
	["fence", &"madeira"],
	["crate", &"madeira"],
	["tree", &"madeira"],
	["building", &"metal"],
	["detail_", &"metal"],
	["tank", &"metal"],
	["silo", &"metal"],
	["ground_path", &"terra"],
	["dirt", &"terra"],
	["platform_grass", &"grama"],
	["ground_grass", &"grama"],
]


const SUPERFICIE_PADRAO: StringName = &"grama"

func _post_import(cena: Node) -> Object:
	var nome_do_arquivo: String = get_source_file().get_file().to_lower()
	_normalizar_materiais(cena)
	var superficie: StringName = _superficie_do_nome(nome_do_arquivo)
	## Modelos com superfície conhecida sempre recebem colisão: são peças de chão ou
	## obstáculo reconhecido. Só aplica a lista de exclusão quando o modelo não foi
	## reconhecido pelo mapeamento e recebeu o valor padrão.
	var tem_superficie_conhecida: bool = _tem_superficie_conhecida(nome_do_arquivo)
	if not tem_superficie_conhecida and not _deve_ter_colisao(nome_do_arquivo):
		return cena
	_gerar_colisao(cena, cena, superficie)
	return cena

func _tem_superficie_conhecida(nome_do_arquivo: String) -> bool:
	for par in SUPERFICIE_POR_TRECHO:
		if nome_do_arquivo.contains(par[0] as String):
			return true
	return false

func _deve_ter_colisao(nome_do_arquivo: String) -> bool:
	for trecho in TRECHOS_SEM_COLISAO:
		if nome_do_arquivo.contains(trecho):
			return false
	return true

func _superficie_do_nome(nome_do_arquivo: String) -> StringName:
	for par in SUPERFICIE_POR_TRECHO:
		if nome_do_arquivo.contains(par[0] as String):
			return par[1] as StringName
	return SUPERFICIE_PADRAO

func _gerar_colisao(no: Node, raiz: Node, superficie: StringName) -> void:
	if no is MeshInstance3D:
		var instancia := no as MeshInstance3D
		var malha: Mesh = instancia.mesh
		if malha != null and malha.get_surface_count() > 0:
			var corpo := StaticBody3D.new()
			corpo.name = "Colisao"
			corpo.collision_layer = CAMADA_MUNDO
			corpo.collision_mask = 0
			corpo.set_meta(&"superficie", superficie)

			var forma := CollisionShape3D.new()
			forma.name = "FormaColisao"
			forma.shape = malha.create_trimesh_shape()

			corpo.add_child(forma)
			instancia.add_child(corpo)
			corpo.owner = raiz
			forma.owner = raiz

	for filho in no.get_children():
		_gerar_colisao(filho, raiz, superficie)

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
