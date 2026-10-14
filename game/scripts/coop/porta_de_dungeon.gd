class_name PortaDeDungeon
extends Node3D

## Uma porta fechada entre duas salas da dungeon. Quem a abre é a SalaDeDungeon, quando
## fica limpa.
##
## O corpo da porta fica na camada "porta" (a 9), e não na "mundo". O jogador e os
## inimigos colidem com ela, mas o gerador da malha de navegação só lê a camada "mundo":
## assim a malha passa pelo vão, e os inimigos conseguem atravessar depois que ela abre.

const SEGUNDOS_PARA_ABRIR: float = 0.8

## A altura da folha. É o quanto ela desce para sumir dentro do chão.
@export var altura: float = 2.2

@onready var _modelo: Node3D = $Modelo
@onready var _corpo: StaticBody3D = $Corpo

var _aberta: bool = false

func esta_aberta() -> bool:
	return _aberta

## Desliga a colisão na hora, para ninguém ficar esperando a animação, e afunda o modelo
## no chão.
func abrir() -> void:
	if _aberta:
		return
	_aberta = true
	_corpo.collision_layer = 0
	var descida: Tween = create_tween()
	descida.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	descida.tween_property(_modelo, "position:y", -altura - 0.1, SEGUNDOS_PARA_ABRIR)
	descida.tween_callback(func() -> void: _modelo.visible = false)
	EventBus.dungeon_door_opened.emit(global_position)
