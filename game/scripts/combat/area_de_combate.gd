class_name AreaDeCombate
extends Node3D

## O canto da cidade onde a demo tem inimigos.
##
## No jogo completo o combate acontece nas dungeons. A demo não tem dungeon, então os
## inimigos ficam todos aqui, cercados, longe da horta e da vendinha. Cada filho
## PontoDeInimigo é um inimigo: ele nasce no começo e, quando cai, nasce de novo no mesmo
## ponto depois de segundos_para_renascer. Assim a área nunca fica vazia para quem está
## experimentando.

const CENA_DO_INIMIGO: PackedScene = preload("res://scenes/combat/inimigo.tscn")

@export var segundos_para_renascer: float = 20.0

func _ready() -> void:
	# Um quadro depois, para a malha de navegação da fase já estar pronta quando os
	# inimigos pedirem o primeiro caminho.
	_criar_todos.call_deferred()

func _criar_todos() -> void:
	for filho in get_children():
		var ponto: PontoDeInimigo = filho as PontoDeInimigo
		if ponto != null:
			_criar_inimigo(ponto)

func _criar_inimigo(ponto: PontoDeInimigo) -> void:
	if ponto.perfil == null:
		push_warning("Ponto de inimigo sem perfil: %s" % ponto.name)
		return
	var inimigo: Inimigo = CENA_DO_INIMIGO.instantiate() as Inimigo
	inimigo.perfil = ponto.perfil
	# A posição vem antes de entrar na árvore: o inimigo guarda onde nasceu no _ready, e
	# patrulha em volta desse ponto. O ponto e o inimigo são filhos deste nó, então a
	# posição local dos dois é a mesma.
	inimigo.position = ponto.position
	add_child(inimigo)
	inimigo.defeated.connect(_ao_cair.bind(ponto).unbind(1))
	EventBus.enemy_spawned.emit(ponto.global_position)

func _ao_cair(ponto: PontoDeInimigo) -> void:
	await get_tree().create_timer(segundos_para_renascer, false).timeout
	_criar_inimigo(ponto)
