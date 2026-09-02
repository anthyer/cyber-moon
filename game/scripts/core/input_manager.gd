extends Node

func obter_direcao_movimento() -> Vector2:
	return Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")

func correr_pressionado() -> bool:
	return Input.is_action_pressed("correr")

func interagir_pressionado() -> bool:
	return Input.is_action_just_pressed("interagir")

func abrir_inventario_pressionado() -> bool:
	return Input.is_action_just_pressed("abrir_inventario")

func dash_pressionado() -> bool:
	return Input.is_action_just_pressed("dash")

func atacar_pressionado() -> bool:
	return Input.is_action_just_pressed("atacar")

func equipar_1_pressionado() -> bool:
	return Input.is_action_just_pressed("equipar_1")

func equipar_2_pressionado() -> bool:
	return Input.is_action_just_pressed("equipar_2")

func equipar_3_pressionado() -> bool:
	return Input.is_action_just_pressed("equipar_3")

func equipar_4_pressionado() -> bool:
	return Input.is_action_just_pressed("equipar_4")

func proxima_ferramenta_pressionada() -> bool:
	return Input.is_action_just_pressed("ferramenta_proxima")

func ferramenta_anterior_pressionada() -> bool:
	return Input.is_action_just_pressed("ferramenta_anterior")
