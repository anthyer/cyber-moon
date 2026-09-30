extends Node

## Atalhos temporários de teste, que não fazem parte do jogo final.
##
## Hoje só tem um: a tecla N avança um dia, para dar para ver as plantas crescerem antes
## de existir o ciclo de dia automático (plano 10). Quando o plano 10 entrar, este nó e
## a ação teste_avancar_dia saem.

func _process(_delta: float) -> void:
	if InputManager.teste_avancar_dia_pressionado():
		DayCycleManager.avancar_para_o_proximo_dia()
		print("Dia ", DayCycleManager.numero_do_dia)
