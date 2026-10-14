class_name CoberturaTranslucida
extends Node

## Deixa translúcido o objeto que está cobrindo o jogador ou um inimigo.
##
## A câmera do jogo olha de cima e de frente, então uma peça alta (coluna, armário de
## servidor, árvore) esconde quem passa atrás dela. Este nó, posto como filho da peça,
## confere algumas vezes por segundo se a linha entre a câmera e algum personagem cruza a
## peça. Se cruza, a peça fica quase transparente; quando o personagem sai, ela volta.
##
## O renderizador Compatibility ignora a propriedade `transparency` do GeometryInstance3D
## (testado: o objeto continua opaco). Por isso a transparência é feita com uma cópia do
## material de cada superfície, em modo alfa, posta como material de substituição só
## enquanto a peça está translúcida. Opaca, a peça usa o material original, que é mais
## barato de desenhar e não sofre com a ordenação de transparentes.

const GRUPO_DOS_JOGADORES: StringName = &"alvos_de_inimigo"
const GRUPO_DOS_INIMIGOS: StringName = Inimigo.GRUPO
const SEGUNDOS_ENTRE_CONFERENCIAS: float = 0.1
## A linha vai da câmera até o meio do corpo do personagem, e não até o pé.
const ALTURA_DO_CORPO: float = 0.35

## Quanto da peça continua visível quando ela cobre alguém. Zero some de vez.
@export_range(0.0, 1.0) var opacidade_cobrindo: float = 0.28
@export var segundos_de_transicao: float = 0.18
## Inimigo escondido atrás da peça também a deixa translúcida.
@export var revela_inimigos: bool = true

var _malhas: Array[MeshInstance3D] = []
## Para cada malha, os materiais translúcidos das superfícies dela, na mesma ordem.
var _materiais: Array[Array] = []
var _caixas: Array[AABB] = []
var _cobrindo: bool = false
var _segundos_ate_conferir: float = 0.0
var _transicao: Tween

func _ready() -> void:
	for no in get_parent().find_children("*", "MeshInstance3D", true, false):
		var malha: MeshInstance3D = no as MeshInstance3D
		if malha.mesh == null:
			continue
		var materiais: Array = []
		for superficie in malha.mesh.get_surface_count():
			var original: Material = malha.get_active_material(superficie)
			var copia: BaseMaterial3D = null
			if original is BaseMaterial3D:
				copia = (original as BaseMaterial3D).duplicate() as BaseMaterial3D
				copia.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			materiais.append(copia)
		_malhas.append(malha)
		_materiais.append(materiais)
		# A caixa já no espaço do mundo: a peça de cenário não se mexe.
		_caixas.append(malha.global_transform * malha.mesh.get_aabb())
	_segundos_ate_conferir = randf() * SEGUNDOS_ENTRE_CONFERENCIAS

func _process(delta: float) -> void:
	_segundos_ate_conferir -= delta
	if _segundos_ate_conferir > 0.0:
		return
	_segundos_ate_conferir = SEGUNDOS_ENTRE_CONFERENCIAS
	var deve_cobrir: bool = _esta_cobrindo_alguem()
	if deve_cobrir != _cobrindo:
		_cobrindo = deve_cobrir
		_mudar_opacidade(opacidade_cobrindo if _cobrindo else 1.0)

func _esta_cobrindo_alguem() -> bool:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return false
	var origem: Vector3 = camera.global_position
	for no in get_tree().get_nodes_in_group(GRUPO_DOS_JOGADORES):
		if _cruza_a_linha(origem, no):
			return true
	if revela_inimigos:
		for no in get_tree().get_nodes_in_group(GRUPO_DOS_INIMIGOS):
			if _cruza_a_linha(origem, no):
				return true
	return false

func _cruza_a_linha(origem: Vector3, no: Node) -> bool:
	var personagem: Node3D = no as Node3D
	if personagem == null:
		return false
	var destino: Vector3 = personagem.global_position + Vector3.UP * ALTURA_DO_CORPO
	for caixa in _caixas:
		# Personagem dentro da própria caixa (encostado na peça) não conta: a linha
		# precisa atravessar a peça antes de chegar nele.
		if caixa.has_point(destino):
			continue
		if caixa.intersects_segment(origem, destino) != null:
			return true
	return false

func _mudar_opacidade(alvo: float) -> void:
	if _transicao != null:
		_transicao.kill()
	if alvo < 1.0:
		_usar_materiais_translucidos()
	_transicao = create_tween().set_parallel(true)
	for materiais in _materiais:
		for material in materiais:
			if material != null:
				_transicao.tween_property(material, "albedo_color:a", alvo, segundos_de_transicao)
	if alvo >= 1.0:
		_transicao.chain().tween_callback(_voltar_aos_materiais_originais)

func _usar_materiais_translucidos() -> void:
	for indice in _malhas.size():
		for superficie in _materiais[indice].size():
			var material: BaseMaterial3D = _materiais[indice][superficie] as BaseMaterial3D
			if material != null:
				_malhas[indice].set_surface_override_material(superficie, material)

func _voltar_aos_materiais_originais() -> void:
	for indice in _malhas.size():
		for superficie in _materiais[indice].size():
			_malhas[indice].set_surface_override_material(superficie, null)
