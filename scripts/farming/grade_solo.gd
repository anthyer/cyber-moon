class_name GradeSolo
extends GridMap

enum EstadoTile { VAZIO, ARADO_SECO, ARADO_MOLHADO }

var _estado: Dictionary = {}

func arar(celula: Vector2i) -> bool:
	if _estado.get(celula, EstadoTile.VAZIO) != EstadoTile.VAZIO:
		return false
	_definir_estado(celula, EstadoTile.ARADO_SECO)
	EventBus.tile_plowed.emit(celula)
	return true

func molhar(celula: Vector2i) -> bool:
	if _estado.get(celula, EstadoTile.VAZIO) != EstadoTile.ARADO_SECO:
		return false
	_definir_estado(celula, EstadoTile.ARADO_MOLHADO)
	EventBus.tile_watered.emit(celula)
	return true

func remover(celula: Vector2i) -> bool:
	if _estado.get(celula, EstadoTile.VAZIO) == EstadoTile.VAZIO:
		return false
	_definir_estado(celula, EstadoTile.VAZIO)
	EventBus.tile_removed.emit(celula)
	return true

func obter_celula_alvo(posicao_jogador: Vector3, rotacao_y: float) -> Vector2i:
	var direcao := Vector3(sin(rotacao_y), 0.0, cos(rotacao_y))
	var alvo_local := local_to_map(to_local(posicao_jogador + direcao))
	return Vector2i(alvo_local.x, alvo_local.z)

func _definir_estado(celula: Vector2i, novo_estado: EstadoTile) -> void:
	if novo_estado == EstadoTile.VAZIO:
		_estado.erase(celula)
	else:
		_estado[celula] = novo_estado
	_atualizar_variante(celula)
	_atualizar_variante(celula + Vector2i.LEFT)
	_atualizar_variante(celula + Vector2i.RIGHT)

func _atualizar_variante(celula: Vector2i) -> void:
	var estado: EstadoTile = _estado.get(celula, EstadoTile.VAZIO)
	if estado == EstadoTile.VAZIO:
		set_cell_item(Vector3i(celula.x, 0, celula.y), -1)
		return

	var tem_esquerda: bool = _estado.get(celula + Vector2i.LEFT, EstadoTile.VAZIO) != EstadoTile.VAZIO
	var tem_direita: bool = _estado.get(celula + Vector2i.RIGHT, EstadoTile.VAZIO) != EstadoTile.VAZIO
	var sufixo: String = "single"
	if tem_esquerda and tem_direita:
		sufixo = "middle"
	elif tem_direita:
		sufixo = "left"
	elif tem_esquerda:
		sufixo = "right"

	var prefixo: String = "dry" if estado == EstadoTile.ARADO_SECO else "watered"
	var nome_item: String = "soil_plow_%s_%s" % [prefixo, sufixo]
	set_cell_item(Vector3i(celula.x, 0, celula.y), mesh_library.find_item_by_name(nome_item))
