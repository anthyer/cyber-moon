class_name BancoDePassos
extends Resource

## Mapeia superfície para os clipes de passo daquela superfície.
##
## As chaves do dicionário são os mesmos StringName que o post_import_kenney.gd
## grava como metadata nos corpos do cenário: grama, terra, pedra, madeira, metal
## e asfalto.

@export var clipes_por_superficie: Dictionary = {}

@export var superficie_padrao: StringName = &"grama"

@export_range(0.0, 0.5) var variacao_de_tom: float = 0.08
@export_range(0.0, 6.0) var variacao_de_volume_db: float = 2.0

var _ultimo_indice_por_superficie: Dictionary = {}

## Sorteia um clipe da superfície pedida, evitando repetir o último sorteado.
## Retorna null quando a superfície não tem clipe nenhum cadastrado, que é o caso
## normal enquanto os arquivos de áudio não chegaram.
func sortear(superficie: StringName) -> AudioStream:
	var clipes: Array = clipes_por_superficie.get(superficie, [])
	if clipes.is_empty():
		clipes = clipes_por_superficie.get(superficie_padrao, [])
	if clipes.is_empty():
		return null
	if clipes.size() == 1:
		return clipes[0]

	var ultimo: int = _ultimo_indice_por_superficie.get(superficie, -1)
	var indice: int = randi() % clipes.size()
	while indice == ultimo:
		indice = randi() % clipes.size()
	_ultimo_indice_por_superficie[superficie] = indice
	return clipes[indice]

func sortear_tom() -> float:
	return 1.0 + randf_range(-variacao_de_tom, variacao_de_tom)

func sortear_volume_db() -> float:
	return randf_range(-variacao_de_volume_db, variacao_de_volume_db)
