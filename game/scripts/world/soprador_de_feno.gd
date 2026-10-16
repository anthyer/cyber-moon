class_name SopradorDeFeno
extends Node3D

## Solta bolas de feno que rolam com o vento pelo deserto e somem com o tempo.
##
## Cada bola nasce num ponto sorteado de uma das áreas, rola na direção do vento dando
## pulinhos, acompanha o relevo do chão e, depois de um tempo, encolhe até sumir. Nunca há
## mais do que `maximo_ao_mesmo_tempo` bolas: quando uma some, outra pode nascer. Assim o
## custo fica fixo, por mais tempo que o jogador passe no mapa.
##
## As bolas não têm colisão nem bloqueiam ninguém: são enfeite que se mexe.

## A cena da bola (o .glb do pacote).
@export var modelo: PackedScene
## Retângulos (x, z, largura, profundidade) no espaço deste nó onde as bolas nascem.
@export var areas: Array[Rect2] = []
@export var maximo_ao_mesmo_tempo: int = 6
## Para onde o vento sopra, no plano do chão.
@export var direcao_do_vento: Vector2 = Vector2(1.0, 0.25)
@export var velocidade_minima: float = 1.4
@export var velocidade_maxima: float = 2.8
@export var segundos_de_vida_minimo: float = 9.0
@export var segundos_de_vida_maximo: float = 16.0
## Segundos entre uma bola nascer e a próxima poder nascer.
@export var intervalo_entre_nascimentos: float = 2.5

const SEGUNDOS_ENCOLHENDO: float = 1.2
const ALTURA_DO_PULO: float = 0.25
const CAMADA_DO_CHAO: int = 1

var _bolas: Array[Dictionary] = []
var _segundos_ate_nascer: float = 0.0
var _sorteio: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_sorteio.seed = hash(name)

func _physics_process(delta: float) -> void:
	_segundos_ate_nascer -= delta
	if _segundos_ate_nascer <= 0.0 and _bolas.size() < maximo_ao_mesmo_tempo and not areas.is_empty():
		_segundos_ate_nascer = intervalo_entre_nascimentos
		_nascer()
	for indice in range(_bolas.size() - 1, -1, -1):
		if not _rolar(_bolas[indice], delta):
			(_bolas[indice]["no"] as Node3D).queue_free()
			_bolas.remove_at(indice)

func _nascer() -> void:
	if modelo == null:
		return
	var area: Rect2 = areas[_sorteio.randi() % areas.size()]
	var ponto: Vector2 = Vector2(_sorteio.randf_range(area.position.x, area.end.x), _sorteio.randf_range(area.position.y, area.end.y))
	var bola: Node3D = modelo.instantiate() as Node3D
	add_child(bola)
	bola.position = Vector3(ponto.x, 0.0, ponto.y)
	var escala: float = _sorteio.randf_range(0.7, 1.2)
	bola.scale = Vector3.ONE * 0.01
	_bolas.append({
		"no": bola,
		"escala": escala,
		"velocidade": _sorteio.randf_range(velocidade_minima, velocidade_maxima),
		"vida": _sorteio.randf_range(segundos_de_vida_minimo, segundos_de_vida_maximo),
		"idade": 0.0,
		"fase": _sorteio.randf() * TAU,
	})

## Move uma bola um quadro. Devolve falso quando ela acabou de sumir.
func _rolar(bola: Dictionary, delta: float) -> bool:
	var no: Node3D = bola["no"]
	bola["idade"] += delta
	var idade: float = bola["idade"]
	var vida: float = bola["vida"]
	if idade >= vida:
		return false
	var vento: Vector2 = direcao_do_vento.normalized()
	# A rajada muda de força devagar, para as bolas não andarem como em trilho.
	var rajada: float = 0.75 + 0.35 * sin(idade * 0.9 + bola["fase"])
	var passo: Vector2 = vento * bola["velocidade"] * rajada * delta
	no.position.x += passo.x
	no.position.z += passo.y
	var pulo: float = absf(sin(idade * 3.2 + bola["fase"])) * ALTURA_DO_PULO
	no.position.y = _altura_do_chao(no.global_position) - global_position.y + pulo
	# Rola em volta do eixo perpendicular ao vento.
	var eixo: Vector3 = Vector3(vento.y, 0.0, -vento.x).normalized()
	no.rotate(eixo, -passo.length() / 0.3)
	# Cresce ao nascer e encolhe no fim, em vez de aparecer e sumir de uma vez.
	var tamanho: float = bola["escala"] * minf(idade / 0.6, 1.0)
	var resta: float = vida - idade
	if resta < SEGUNDOS_ENCOLHENDO:
		tamanho *= resta / SEGUNDOS_ENCOLHENDO
	no.scale = Vector3.ONE * maxf(tamanho, 0.01)
	return true

func _altura_do_chao(ponto: Vector3) -> float:
	var espaco: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ponto + Vector3.UP * 4.0, ponto + Vector3.DOWN * 6.0, CAMADA_DO_CHAO)
	var acerto: Dictionary = espaco.intersect_ray(consulta)
	return (acerto["position"] as Vector3).y if not acerto.is_empty() else ponto.y
