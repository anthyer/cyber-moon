class_name TalhaoDeCultivo
extends Node3D

## Um pedaço de terra da fazenda onde a enxada funciona. Fora de todo talhão o solo não
## pode ser arado: é assim que a fazenda tem lugares certos para plantar, em vez de o
## mapa inteiro aceitar a enxada.
##
## O nó fica no canto noroeste do talhão (o canto de menor x e menor z), e o tamanho é
## em células da GradeSolo, que têm 1 por 1. A GradeSolo acha os talhões pelo grupo.

const GRUPO: StringName = &"talhoes_de_cultivo"

@export var tamanho_em_celulas: Vector2i = Vector2i(10, 8)
## Talhão ainda não liberado aparece no mapa, mas a enxada não funciona nele. Fica para
## quando a fazenda crescer (plano 26, decisão em aberto: comprar terreno ou aprimorar).
@export var liberado: bool = true

func _ready() -> void:
	add_to_group(GRUPO)

## As células do talhão na grade dada.
func celulas_na_grade(grade: GridMap) -> Rect2i:
	var canto: Vector3i = grade.local_to_map(grade.to_local(global_position + Vector3(0.5, 0.0, 0.5)))
	return Rect2i(Vector2i(canto.x, canto.z), tamanho_em_celulas)
