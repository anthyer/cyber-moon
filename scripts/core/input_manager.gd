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
