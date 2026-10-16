class_name LuzDoJogador
extends OmniLight3D

## A luz em volta do jogador. Fica apagada de dia e acende aos poucos quando o mapa
## começa a escurecer, no fim da tarde. Na dungeon, que é escura, fica sempre acesa.
##
## Apagada, ela fica invisível, e uma luz invisível não custa nada no desenho.

## A força da luz quando está toda acesa. A da cena é lida no começo e vira esta.
var energia_maxima: float = 1.0
## Começa a acender nesta hora, um pouco antes do anoitecer do relógio.
@export var hora_de_comecar_a_acender: float = 17.5
## Está toda acesa nesta hora.
@export var hora_toda_acesa: float = 19.0

var _na_dungeon: bool = false

func _ready() -> void:
	energia_maxima = light_energy
	EventBus.dungeon_entered.connect(func() -> void: _na_dungeon = true)
	EventBus.dungeon_left.connect(func() -> void: _na_dungeon = false)
	_atualizar()

func _process(_delta: float) -> void:
	_atualizar()

func _atualizar() -> void:
	var fator: float = 1.0 if _na_dungeon else _fator_da_hora(DayCycleManager.hora_atual)
	light_energy = energia_maxima * fator
	visible = fator > 0.0

## De 0 (dia) a 1 (noite). A hora passa de 24 depois da meia-noite, então a madrugada
## continua acesa até o dia virar.
func _fator_da_hora(hora: float) -> float:
	return clampf((hora - hora_de_comecar_a_acender) / (hora_toda_acesa - hora_de_comecar_a_acender), 0.0, 1.0)
