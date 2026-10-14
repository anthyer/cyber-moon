class_name GeradorDaCorporacao
extends StaticBody3D

## Um gerador da corporação, que o jogador destrói a golpes. É alvo do objetivo de
## geradores da dungeon.
##
## Segue o contrato de dano do jogo: receber_dano(quantidade, origem). Fica na camada dos
## inimigos, que é a que a área de golpe e os projéteis do jogador enxergam, mas não é
## inimigo: não ataca, e os inimigos não ligam para ele.
##
## O gerador não fala com a rede. Ele avisa o objetivo pelo sinal hit, e é o objetivo quem
## repassa o golpe aos outros jogos.

## Um golpe deste jogo acertou. O objetivo repassa aos outros.
signal hit(quantidade: int)
signal destroyed

const SEGUNDOS_DO_TRANCO: float = 0.12
const SEGUNDOS_PARA_TOMBAR: float = 0.6
const GRAUS_TOMBADO: float = 80.0
const QUANTO_AFUNDA: float = 0.25

@export var vida_maxima: int = 40

@onready var modelo: Node3D = $Modelo
@onready var forma: CollisionShape3D = $Forma

var vida_atual: int = 0
var destruido: bool = false

func _ready() -> void:
	vida_atual = vida_maxima

## O golpe de um jogador deste jogo.
func receber_dano(quantidade: int, _origem: Node3D) -> void:
	if destruido or quantidade <= 0:
		return
	hit.emit(quantidade)
	aplicar_dano(quantidade)

## Tira a vida e mostra o golpe. Serve ao golpe local e ao que chegou de outro jogo.
func aplicar_dano(quantidade: int) -> void:
	if destruido:
		return
	vida_atual = maxi(vida_atual - quantidade, 0)
	# O damage_dealt é o que solta a faísca do golpe, como num inimigo.
	EventBus.damage_dealt.emit(self, quantidade)
	EventBus.dungeon_objective_progress.emit(global_position)
	if vida_atual <= 0:
		_cair()
	else:
		_dar_tranco()

## O gerador encolhe e volta, para o acerto ser visível mesmo sem som.
func _dar_tranco() -> void:
	var tranco: Tween = create_tween()
	tranco.tween_property(modelo, "scale", Vector3(1.12, 0.9, 1.12), SEGUNDOS_DO_TRANCO * 0.5)
	tranco.tween_property(modelo, "scale", Vector3.ONE, SEGUNDOS_DO_TRANCO * 0.5)

## Destruído, ele para de bloquear e de levar golpe, tomba de lado e afunda um pouco.
func _cair() -> void:
	destruido = true
	collision_layer = 0
	forma.set_deferred(&"disabled", true)
	var queda: Tween = create_tween().set_parallel(true)
	queda.tween_property(modelo, "rotation_degrees:z", GRAUS_TOMBADO, SEGUNDOS_PARA_TOMBAR).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	queda.tween_property(modelo, "position:y", modelo.position.y - QUANTO_AFUNDA, SEGUNDOS_PARA_TOMBAR)
	destroyed.emit()
