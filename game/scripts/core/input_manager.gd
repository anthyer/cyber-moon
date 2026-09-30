extends Node

func obter_direcao_movimento() -> Vector2:
	return Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")

func correr_pressionado() -> bool:
	return Input.is_action_pressed("correr")

func interagir_pressionado() -> bool:
	return Input.is_action_just_pressed("interagir")

func abrir_inventario_pressionado() -> bool:
	return Input.is_action_just_pressed("abrir_inventario")

func menu_pausa_pressionado() -> bool:
	return Input.is_action_just_pressed("menu_pausa")

func dash_pressionado() -> bool:
	return Input.is_action_just_pressed("dash")

func atacar_pressionado() -> bool:
	return Input.is_action_just_pressed("atacar")

## Devolve o índice do slot rápido pedido por tecla numérica (0 para a tecla 1), ou -1
## quando nenhuma foi pressionada neste quadro. Um método só no lugar de nove quase
## iguais.
func slot_numerico_pressionado() -> int:
	for indice in 9:
		if Input.is_action_just_pressed("slot_%d" % (indice + 1)):
			return indice
	return -1

func slot_proximo_pressionado() -> bool:
	return Input.is_action_just_pressed("slot_proximo")

func slot_anterior_pressionado() -> bool:
	return Input.is_action_just_pressed("slot_anterior")

## Temporária: avança um dia para testar o crescimento das plantas. Sai quando o plano
## 10 trouxer o ciclo de dia automático.
func teste_avancar_dia_pressionado() -> bool:
	return Input.is_action_just_pressed("teste_avancar_dia")

