class_name PassagemDeMapa
extends Area3D

## A porteira entre a fazenda e o mundo. Entrar na área leva o jogador para o outro mapa,
## no marcador de chegada indicado. Não precisa apertar botão: atravessar a porteira já
## basta, como sair por uma rua.
##
## O marcador de chegada fica um pouco para dentro do outro mapa, longe da passagem de
## volta, senão o jogador chegaria em cima dela e voltaria na hora.

@export var mapa_de_destino: StringName = &""
@export var chegada: StringName = &""

func _ready() -> void:
	collision_layer = 0
	# Só o jogador (camada 2) atravessa a passagem.
	collision_mask = 2
	monitorable = false
	body_entered.connect(_ao_entrar)

func _ao_entrar(corpo: Node3D) -> void:
	if not corpo.is_in_group(&"jogador"):
		return
	MapManager.ir_para.call_deferred(mapa_de_destino, chegada)
