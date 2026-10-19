class_name Portal
extends Node3D

## A passagem entre o mundo e a dungeon. No mundo, interagir abre o lobby, onde se
## chama alguém e se começa; na dungeon, interagir sai. Segue o contrato de interação do
## jogo (ver AreaDeInteracao): o jogador só chama interagir().

enum Funcao { ABRIR_O_LOBBY, SAIR_DA_DUNGEON }

@export var funcao: Funcao = Funcao.ABRIR_O_LOBBY
## Qual dungeon esta entrada abre. Cada dungeon tem a sua entrada no mapa mundi.
@export var dungeon_id: StringName = &""

func texto_de_interacao() -> String:
	return "Entrar na dungeon" if funcao == Funcao.ABRIR_O_LOBBY else "Sair da dungeon"

## A entrada do mundo é só a área; o modelo (o alçapão, o elevador) fica ao lado, no
## mesmo grupo. É ele que brilha quando a entrada é o alvo.
func no_do_destaque() -> Node3D:
	if funcao == Funcao.ABRIR_O_LOBBY and get_parent() is Node3D:
		return get_parent() as Node3D
	return self

func interagir() -> void:
	match funcao:
		Funcao.ABRIR_O_LOBBY:
			EventBus.lobby_requested.emit(dungeon_id)
		Funcao.SAIR_DA_DUNGEON:
			DungeonManager.sair()
