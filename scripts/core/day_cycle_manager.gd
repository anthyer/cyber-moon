extends Node

signal day_started(numero_do_dia: int)
signal day_ended(numero_do_dia: int)

const HORA_INICIO_DIA: float = 6.0
const HORA_FIM_DIA: float = 24.0

var numero_do_dia: int = 1
var hora_atual: float = HORA_INICIO_DIA

func avancar_para_o_proximo_dia() -> void:
	day_ended.emit(numero_do_dia)
	numero_do_dia += 1
	hora_atual = HORA_INICIO_DIA
	day_started.emit(numero_do_dia)
