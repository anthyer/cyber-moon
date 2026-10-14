class_name PecaDeResgate
extends Node3D

## Uma peça escondida na dungeon, que o jogador pega interagindo. É alvo do objetivo de
## resgate. Segue o contrato de interação do jogo (ver AreaDeInteracao): a área desta cena
## fica na camada area_interacao, e o jogador só chama interagir().
##
## A peça vale para a equipe: quem pegar pega para todos. Ela não fala com a rede; avisa o
## objetivo pelo sinal picked, e é o objetivo quem repassa aos outros jogos.

## Um jogador deste jogo pegou a peça. O objetivo repassa aos outros.
signal picked
## A peça foi pega, por este jogo ou por outro.
signal collected

@onready var area: Area3D = $AreaDaPeca

var coletada: bool = false

func interagir() -> void:
	if coletada:
		return
	picked.emit()
	coletar()

## Marca a peça como pega e a tira do mundo. Serve à interação local e ao aviso de outro
## jogo.
func coletar() -> void:
	if coletada:
		return
	coletada = true
	visible = false
	# Fora da camada de interação, o botão do jogador não a acha mais.
	area.collision_layer = 0
	EventBus.dungeon_objective_progress.emit(global_position)
	collected.emit()
