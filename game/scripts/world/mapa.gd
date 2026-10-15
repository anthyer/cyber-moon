class_name Mapa
extends Node3D

## Um mapa do jogo: a fazenda ou o mundo. Os dois ficam dentro da cena principal ao mesmo
## tempo, longe um do outro, mas só um está ativo: o outro fica invisível e parado (sem
## processar), então não custa desenho nem lógica. Quem liga e desliga é o MapManager.
##
## Ficar na árvore, mesmo parado, mantém o estado do mapa sem código extra: a terra arada
## da fazenda continua lá, o save acha os nós pelo grupo de sempre, e a planta cresce na
## virada do dia mesmo com o jogador no mundo.

const GRUPO: StringName = &"mapas"

@export var id: StringName = &""
@export var nome_exibido: String = ""

func _ready() -> void:
	add_to_group(GRUPO)

## O marcador de chegada com esse nome, onde o jogador aparece ao entrar no mapa.
func ponto_de_chegada(nome: StringName) -> Node3D:
	return find_child(String(nome), true, false) as Node3D

func ativar(ligado: bool) -> void:
	visible = ligado
	process_mode = Node.PROCESS_MODE_INHERIT if ligado else Node.PROCESS_MODE_DISABLED
