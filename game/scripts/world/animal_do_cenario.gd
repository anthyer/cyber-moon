class_name AnimalDoCenario
extends Node3D

## Um bicho que passeia devagar dentro de uma área: a raposa na reserva, o gado no pasto,
## a galinha no quintal da fazenda.
##
## Escolhe um ponto da área, anda até ele, para um pouco, e escolhe outro. Acompanha o
## relevo do chão. Não tem colisão e não atrapalha ninguém: as áreas dele são cercadas,
## ou são cantos onde o jogador não precisa passar.
##
## O modelo é um dos animais do pacote cube pets. Se o modelo tiver animação de andar, ela
## toca; se não tiver, o corpo dá pulinhos.

@export var modelo: PackedScene
## Retângulo (x, z, largura, profundidade) no espaço do pai, onde o bicho passeia.
@export var area: Rect2 = Rect2(-3, -3, 6, 6)
@export var velocidade: float = 0.9
@export var segundos_parado_minimo: float = 1.5
@export var segundos_parado_maximo: float = 5.0
@export var escala_do_modelo: float = 1.0

const CAMADA_DO_CHAO: int = 1

var _visual: Node3D
var _animacao: AnimationPlayer
var _destino: Vector3
var _segundos_parado: float = 0.0
var _tempo: float = 0.0
var _sorteio: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_sorteio.seed = hash(get_path())
	if modelo == null:
		return
	_visual = modelo.instantiate() as Node3D
	_visual.scale = Vector3.ONE * escala_do_modelo
	add_child(_visual)
	var animacoes: Array[Node] = _visual.find_children("*", "AnimationPlayer", true, false)
	if not animacoes.is_empty():
		_animacao = animacoes[0] as AnimationPlayer
	_segundos_parado = _sorteio.randf_range(0.0, segundos_parado_maximo)
	_destino = position

func _process(delta: float) -> void:
	if _visual == null:
		return
	_tempo += delta
	if _segundos_parado > 0.0:
		_segundos_parado -= delta
		_tocar(&"idle")
		if _segundos_parado <= 0.0:
			_destino = Vector3(_sorteio.randf_range(area.position.x, area.end.x), 0.0, _sorteio.randf_range(area.position.y, area.end.y))
		return
	var para_o_destino: Vector3 = Vector3(_destino.x - position.x, 0.0, _destino.z - position.z)
	if para_o_destino.length() < 0.15:
		_segundos_parado = _sorteio.randf_range(segundos_parado_minimo, segundos_parado_maximo)
		return
	var passo: Vector3 = para_o_destino.normalized() * minf(velocidade * delta, para_o_destino.length())
	position += passo
	_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(passo.x, passo.z), minf(6.0 * delta, 1.0))
	position.y = _altura_do_chao(global_position) - (get_parent() as Node3D).global_position.y
	if _animacao != null:
		_tocar(&"walk")
	else:
		_visual.position.y = absf(sin(_tempo * 9.0)) * 0.06

func _tocar(nome: StringName) -> void:
	if _animacao == null:
		_visual.position.y = 0.0
		return
	if _animacao.has_animation(nome) and _animacao.current_animation != nome:
		_animacao.play(nome)

func _altura_do_chao(ponto: Vector3) -> float:
	var espaco: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ponto + Vector3.UP * 3.0, ponto + Vector3.DOWN * 6.0, CAMADA_DO_CHAO)
	var acerto: Dictionary = espaco.intersect_ray(consulta)
	return (acerto["position"] as Vector3).y if not acerto.is_empty() else ponto.y
