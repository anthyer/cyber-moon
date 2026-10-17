class_name ResgateDoJogador
extends Node

## Tira o jogador da água se ele cair nela, e o põe de volta no último chão seguro.
##
## O rio, o cânion e o lago são afundados e cercados por paredes invisíveis no alto da
## margem. Se mesmo assim o jogador chegar lá embaixo (um dash numa fresta, um empurrão de
## inimigo), não há como subir o barranco a pé. Este nó guarda, a cada passo em chão firme
## e alto, onde o jogador estava, e o devolve para lá quando ele desce abaixo do limite.
##
## Fica dentro do mapa: com o mapa desligado ele também para.

## Abaixo desta altura (em relação ao mapa) o jogador está no leito, e não no chão.
@export var altura_minima: float = -0.45
## Quanto tempo o jogador pode ficar lá embaixo antes de ser resgatado.
@export var segundos_ate_resgatar: float = 0.4

var _ultimo_lugar_seguro: Vector3 = Vector3.ZERO
var _tem_lugar_seguro: bool = false
var _segundos_embaixo: float = 0.0

func _physics_process(delta: float) -> void:
	var jogador: CharacterBody3D = get_tree().get_first_node_in_group(&"jogador") as CharacterBody3D
	var mapa: Node3D = get_parent() as Node3D
	if jogador == null or mapa == null:
		return
	var altura: float = jogador.global_position.y - mapa.global_position.y
	if altura >= altura_minima:
		_segundos_embaixo = 0.0
		if jogador.is_on_floor():
			_ultimo_lugar_seguro = jogador.global_position
			_tem_lugar_seguro = true
		return
	_segundos_embaixo += delta
	if _segundos_embaixo >= segundos_ate_resgatar and _tem_lugar_seguro:
		_segundos_embaixo = 0.0
		jogador.velocity = Vector3.ZERO
		jogador.global_position = _ultimo_lugar_seguro + Vector3.UP * 0.1
		EventBus.player_rescued.emit(jogador.global_position)
