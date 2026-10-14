class_name MaquinaAnimada
extends Node

## Anima por código um modelo de malha rígida, sem esqueleto.
##
## Os inimigos e chefes das dungeons são máquinas modeladas em partes. O nome de cada
## parte, dado no Blender, diz como ela se mexe:
##
## - `Gira...` roda sem parar em torno do próprio eixo vertical (hélice, serra, anel).
##   Partes com "Coroa" no nome rodam ao contrário, mais devagar.
## - `Flutua...` sobe e desce devagar (corpo de drone, núcleo).
## - `Braco...` fica em repouso e desce num golpe quando `golpear()` é chamado.
##
## Este nó é colocado como filho do modelo. O Inimigo cria um sozinho quando o modelo do
## perfil não tem AnimationPlayer; numa peça de cenário (o exaustor, a antena) ele é
## posto à mão na cena.

const PREFIXO_DE_GIRO: String = "Gira"
const PREFIXO_DE_FLUTUACAO: String = "Flutua"
const PREFIXO_DE_BRACO: String = "Braco"
const TRECHO_DE_GIRO_INVERTIDO: String = "Coroa"

## Voltas por segundo das partes que giram.
@export var voltas_por_segundo: float = 1.5
## Quanto as partes que flutuam sobem e descem, para cada lado.
@export var altura_da_flutuacao: float = 0.05
@export var velocidade_da_flutuacao: float = 2.4
## Até onde o braço desce no golpe, em radianos.
@export var angulo_do_golpe: float = 1.3

var _partes_que_giram: Array[Node3D] = []
var _partes_que_flutuam: Array[Node3D] = []
var _alturas_de_repouso: Array[float] = []
var _bracos: Array[Node3D] = []
var _tempo: float = 0.0
var _tempo_do_golpe: float = 0.0
var _duracao_do_golpe: float = 0.0
var _parada: bool = false

func _ready() -> void:
	var modelo: Node = get_parent()
	for no in modelo.find_children("*", "Node3D", true, false):
		var parte: Node3D = no as Node3D
		var nome: String = String(parte.name)
		if nome.begins_with(PREFIXO_DE_GIRO):
			_partes_que_giram.append(parte)
		elif nome.begins_with(PREFIXO_DE_FLUTUACAO):
			_partes_que_flutuam.append(parte)
			_alturas_de_repouso.append(parte.position.y)
		elif nome.begins_with(PREFIXO_DE_BRACO):
			_bracos.append(parte)
	# Cada máquina começa num ponto diferente da onda, senão um grupo de drones sobe e
	# desce todo junto, como se fosse um bloco só.
	_tempo = randf() * TAU

func _process(delta: float) -> void:
	if _parada:
		return
	_tempo += delta
	for parte in _partes_que_giram:
		var sentido: float = 1.0
		if String(parte.name).contains(TRECHO_DE_GIRO_INVERTIDO):
			sentido = -0.5
		parte.rotate_object_local(Vector3.UP, voltas_por_segundo * TAU * delta * sentido)
	for indice in _partes_que_flutuam.size():
		var parte: Node3D = _partes_que_flutuam[indice]
		parte.position.y = _alturas_de_repouso[indice] + sin(_tempo * velocidade_da_flutuacao) * altura_da_flutuacao
	_animar_golpe(delta)

## Começa o golpe: os braços sobem, descem de uma vez e voltam ao repouso.
func golpear(duracao: float) -> void:
	_duracao_do_golpe = maxf(duracao, 0.1)
	_tempo_do_golpe = _duracao_do_golpe

## A máquina quebrou: tudo para onde está e os braços caem.
func parar() -> void:
	_parada = true
	for braco in _bracos:
		braco.rotation.x = angulo_do_golpe * 0.5

func _animar_golpe(delta: float) -> void:
	if _tempo_do_golpe <= 0.0:
		return
	_tempo_do_golpe = maxf(_tempo_do_golpe - delta, 0.0)
	var fracao: float = 1.0 - _tempo_do_golpe / _duracao_do_golpe
	# Primeiro terço: o braço recua para trás (ângulo negativo). Depois desce de uma vez
	# e volta devagar. O recuo é o aviso de que o golpe vem.
	var angulo: float = 0.0
	if fracao < 0.35:
		angulo = lerpf(0.0, -angulo_do_golpe * 0.6, fracao / 0.35)
	elif fracao < 0.55:
		angulo = lerpf(-angulo_do_golpe * 0.6, angulo_do_golpe, (fracao - 0.35) / 0.2)
	else:
		angulo = lerpf(angulo_do_golpe, 0.0, (fracao - 0.55) / 0.45)
	for braco in _bracos:
		braco.rotation.x = -angulo
