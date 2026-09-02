extends Node

enum FaseDaHistoria { INICIO, MARCO_1, MARCO_2, MARCO_3, FINAL }

var fase_atual: FaseDaHistoria = FaseDaHistoria.INICIO
var marcos_desbloqueados: Array[String] = []

func desbloquear_marco(id_do_marco: String) -> void:
	if marcos_desbloqueados.has(id_do_marco):
		return
	marcos_desbloqueados.append(id_do_marco)
	EventBus.city_expansion_blocked.emit(id_do_marco)

func marco_esta_desbloqueado(id_do_marco: String) -> bool:
	return marcos_desbloqueados.has(id_do_marco)
