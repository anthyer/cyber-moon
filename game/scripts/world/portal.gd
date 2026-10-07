class_name Portal
extends Node3D

## A passagem entre a fazenda e a dungeon. Na fazenda, interagir abre o lobby, onde se
## chama alguém e se começa; na dungeon, interagir sai. Segue o contrato de interação do
## jogo (ver AreaDeInteracao): o jogador só chama interagir().

enum Funcao { ABRIR_O_LOBBY, SAIR_DA_DUNGEON }

@export var funcao: Funcao = Funcao.ABRIR_O_LOBBY

func interagir() -> void:
	match funcao:
		Funcao.ABRIR_O_LOBBY:
			EventBus.lobby_requested.emit()
		Funcao.SAIR_DA_DUNGEON:
			DungeonManager.sair()
