class_name AreaDeInteracao
extends Area3D

## Guarda o que está perto o bastante do jogador para interagir.
##
## Contrato: um nó é interagível quando tem o método interagir(). A área detecta o
## corpo de colisão (StaticBody3D, Area3D) e sobe pela árvore até achar o primeiro
## ancestral com esse método, que é o alvo. Assim o item no chão, o NPC e o baú se
## registram do mesmo jeito, e quem decide o que acontece é o próprio alvo.

var _alvos: Array[Node3D] = []

func _ready() -> void:
	body_entered.connect(_ao_entrar)
	body_exited.connect(_ao_sair)
	area_entered.connect(_ao_entrar)
	area_exited.connect(_ao_sair)

## Devolve o alvo interagível mais perto do jogador, ou null quando não há nenhum.
func alvo_mais_proximo() -> Node3D:
	var mais_proximo: Node3D = null
	var menor_distancia: float = INF
	for alvo in _alvos:
		if not is_instance_valid(alvo) or alvo.is_queued_for_deletion():
			continue
		var distancia: float = global_position.distance_squared_to(alvo.global_position)
		if distancia < menor_distancia:
			menor_distancia = distancia
			mais_proximo = alvo
	return mais_proximo

func _ao_entrar(corpo: Node3D) -> void:
	var alvo: Node3D = _dono_interagivel(corpo)
	if alvo != null and not _alvos.has(alvo):
		_alvos.append(alvo)

func _ao_sair(corpo: Node3D) -> void:
	var alvo: Node3D = _dono_interagivel(corpo)
	if alvo != null:
		_alvos.erase(alvo)

func _dono_interagivel(corpo: Node) -> Node3D:
	var no: Node = corpo
	while no != null:
		if no.has_method(&"interagir") and no is Node3D:
			return no as Node3D
		no = no.get_parent()
	return null
