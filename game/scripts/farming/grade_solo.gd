class_name GradeSolo
extends GridMap

enum EstadoTile { VAZIO, ARADO_SECO, ARADO_MOLHADO }

## Uma planta em cima de uma célula. É classe interna, e não Resource, porque é estado
## da partida (em que estágio esta planta está), não conteúdo de jogo. O conteúdo é o
## Cultivo que ela aponta.
class PlantaNaGrade:
	var cultivo: Cultivo
	var estagio: int = 0
	## Progresso dentro do estágio atual, em meios dias: um dia de solo molhado vale 2,
	## um dia de solo seco vale 1.
	var progresso_no_estagio: int = 0
	var murcha: bool = false
	var visual: Node3D

## Progresso que um dia dá à planta. Solo molhado vale o dobro do seco, o que faz regar
## ter valor sem a planta morrer por descuido.
const PROGRESSO_DIA_MOLHADO: int = 2
const PROGRESSO_DIA_SECO: int = 1

var _estado: Dictionary = {}
## Célula para PlantaNaGrade. Célula sem entrada é célula sem planta.
var _plantas: Dictionary = {}

@export var limite: Rect2i = Rect2i(Vector2i(-15, -15), Vector2i(30, 30))

@export_group("Visual da planta")
## Tamanho de um pixel da textura no mundo. Com 0.03, a planta de 16 pixels fica com
## cerca de meio metro, um pouco menor que o personagem.
@export var tamanho_do_pixel_da_planta: float = 0.03
## A planta é desenhada como sprites em pé, fixos, virados para a câmera (que não gira),
## como as plantações do Minecraft. São duas fileiras por célula, uma atrás da outra,
## nesta distância do centro, para o quadrado parecer plantado e não ter um sprite só.
@export var recuo_das_fileiras: float = 0.22
@export var fileiras_por_celula: int = 2

func _ready() -> void:
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)

func arar(celula: Vector2i) -> bool:
	if not limite.has_point(celula):
		return false
	if _estado.get(celula, EstadoTile.VAZIO) != EstadoTile.VAZIO:
		return false
	_definir_estado(celula, EstadoTile.ARADO_SECO)
	EventBus.tile_plowed.emit(celula)
	return true

func molhar(celula: Vector2i) -> bool:
	if not limite.has_point(celula):
		return false
	if _estado.get(celula, EstadoTile.VAZIO) != EstadoTile.ARADO_SECO:
		return false
	_definir_estado(celula, EstadoTile.ARADO_MOLHADO)
	EventBus.tile_watered.emit(celula)
	return true

func remover(celula: Vector2i) -> bool:
	if not limite.has_point(celula):
		return false
	if _estado.get(celula, EstadoTile.VAZIO) == EstadoTile.VAZIO:
		return false
	# Desfazer o solo leva junto o que estava plantado nele, sem render colheita.
	_tirar_planta(celula)
	_definir_estado(celula, EstadoTile.VAZIO)
	EventBus.tile_removed.emit(celula)
	return true

## Planta o cultivo na célula. Recusa célula que não está arada e célula que já tem
## planta. A checagem de estação entra no plano 11.
func plantar(celula: Vector2i, cultivo: Cultivo) -> bool:
	if cultivo == null or cultivo.estagios_de_crescimento.is_empty():
		return false
	if _estado.get(celula, EstadoTile.VAZIO) == EstadoTile.VAZIO:
		return false
	if _plantas.has(celula):
		return false
	var planta: PlantaNaGrade = PlantaNaGrade.new()
	planta.cultivo = cultivo
	planta.visual = _criar_visual_da_planta(celula)
	_plantas[celula] = planta
	_atualizar_visual_da_planta(planta)
	EventBus.crop_planted.emit(celula, cultivo)
	return true

func planta_em(celula: Vector2i) -> PlantaNaGrade:
	return _plantas.get(celula, null)

func esta_madura(celula: Vector2i) -> bool:
	var planta: PlantaNaGrade = planta_em(celula)
	return planta != null and not planta.murcha and planta.estagio >= planta.cultivo.estagio_maduro()

## Colhe a planta madura da célula: o item cai no chão, em cima dela, e a planta some
## ou volta ao estágio de rebrota. Planta imatura não faz nada e a função retorna false.
func colher(celula: Vector2i) -> bool:
	if not esta_madura(celula):
		return false
	var planta: PlantaNaGrade = planta_em(celula)
	var cultivo: Cultivo = planta.cultivo
	var quantidade: int = randi_range(cultivo.quantidade_colhida_minima, cultivo.quantidade_colhida_maxima)
	if cultivo.item_colhido != null:
		ItemNoMundo.soltar(cultivo.item_colhido, quantidade, _centro_da_celula_no_mundo(celula), get_parent())

	if cultivo.estagio_de_rebrota > 0:
		planta.estagio = cultivo.estagio_de_rebrota
		planta.progresso_no_estagio = 0
		_atualizar_visual_da_planta(planta)
	else:
		_tirar_planta(celula)
	EventBus.crop_harvested.emit(cultivo, quantidade)
	return true

## Um dia passou: cada planta ganha progresso conforme o solo dela, e todo solo molhado
## seca. É o único lugar que mexe no progresso das plantas.
func avancar_um_dia() -> void:
	for celula: Vector2i in _plantas:
		var planta: PlantaNaGrade = _plantas[celula]
		if planta.murcha or planta.estagio >= planta.cultivo.estagio_maduro():
			continue
		var molhado: bool = _estado.get(celula, EstadoTile.VAZIO) == EstadoTile.ARADO_MOLHADO
		planta.progresso_no_estagio += PROGRESSO_DIA_MOLHADO if molhado else PROGRESSO_DIA_SECO
		var progresso_para_crescer: int = planta.cultivo.dias_por_estagio * PROGRESSO_DIA_MOLHADO
		if planta.progresso_no_estagio >= progresso_para_crescer:
			planta.progresso_no_estagio = 0
			planta.estagio += 1
			_atualizar_visual_da_planta(planta)
			EventBus.crop_grown.emit(celula, planta.estagio)

	for celula: Vector2i in _estado.keys():
		if _estado[celula] == EstadoTile.ARADO_MOLHADO:
			_definir_estado(celula, EstadoTile.ARADO_SECO)

func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	avancar_um_dia()

func aplicar(id_acao: StringName, celula: Vector2i) -> bool:
	match id_acao:
		&"enxada":
			return arar(celula)
		&"regador":
			return molhar(celula)
		&"picareta":
			return remover(celula)
		_:
			return false

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
	var indice_item: int = mesh_library.find_item_by_name(nome_item)
	if indice_item == -1:
		push_error("GradeSolo: item de MeshLibrary nao encontrado: %s" % nome_item)
	set_cell_item(Vector3i(celula.x, 0, celula.y), indice_item)

func _centro_da_celula_no_mundo(celula: Vector2i) -> Vector3:
	return to_global(map_to_local(Vector3i(celula.x, 0, celula.y)))

## Monta as fileiras de sprites da planta na célula. Os sprites não usam billboard: ficam
## fincados na terra, e a base da textura encosta no chão.
func _criar_visual_da_planta(celula: Vector2i) -> Node3D:
	var raiz: Node3D = Node3D.new()
	raiz.name = "Planta_%d_%d" % [celula.x, celula.y]
	add_child(raiz)
	raiz.position = map_to_local(Vector3i(celula.x, 0, celula.y))
	for indice in fileiras_por_celula:
		var sprite: Sprite3D = Sprite3D.new()
		sprite.pixel_size = tamanho_do_pixel_da_planta
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.shaded = false
		# Com uma fileira ela fica no centro; com duas, uma atrás e uma na frente.
		var posicao_relativa: float = 0.0
		if fileiras_por_celula > 1:
			posicao_relativa = lerpf(-recuo_das_fileiras, recuo_das_fileiras, float(indice) / float(fileiras_por_celula - 1))
		sprite.position.z = posicao_relativa
		raiz.add_child(sprite)
	return raiz

func _atualizar_visual_da_planta(planta: PlantaNaGrade) -> void:
	var textura: Texture2D = planta.cultivo.textura_murcha if planta.murcha else planta.cultivo.estagios_de_crescimento[planta.estagio]
	for filho in planta.visual.get_children():
		var sprite: Sprite3D = filho as Sprite3D
		sprite.texture = textura
		# O sprite é centralizado na textura, então sobe meia altura para a base
		# encostar no chão.
		sprite.position.y = textura.get_height() * tamanho_do_pixel_da_planta * 0.5

func _tirar_planta(celula: Vector2i) -> void:
	var planta: PlantaNaGrade = planta_em(celula)
	if planta == null:
		return
	planta.visual.queue_free()
	_plantas.erase(celula)

