class_name Calendario
extends Control

## A tela do calendário aberta pelo quadro de calendário no mundo (QuadroCalendario),
## nunca por tecla. O conteúdo é a GradeDoCalendario, a mesma da aba Calendário do menu
## de pausa; esta tela só cuida de abrir, fechar e trocar a estação pelo teclado.
##
## Abrir pausa o jogo de verdade, como o menu de pausa, e por isso este nó fica com
## process_mode ALWAYS.

@onready var grade: GradeDoCalendario = %GradeDoCalendario

func _ready() -> void:
	visible = false
	EventBus.calendar_requested.connect(abrir)

## Aqui só se lê a entrada com a tela aberta, e por isso com o jogo pausado. Este nó
## precisa vir depois do MenuPausa na cena: assim, no quadro em que o Esc fecha o
## calendário, o MenuPausa já rodou, viu o jogo pausado e não abriu por cima.
func _process(_delta: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(&"ui_cancel"):
		fechar()
	elif Input.is_action_just_pressed(&"ui_left"):
		grade.mostrar_estacao_vizinha(-1)
	elif Input.is_action_just_pressed(&"ui_right"):
		grade.mostrar_estacao_vizinha(1)

## Abre mostrando a estação atual. Não abre por cima de outra tela que já pausou o jogo
## (o inventário), nem com o jogador caído.
func abrir() -> void:
	if visible or get_tree().paused or StatusManager.esta_desmaiado:
		return
	grade.mostrar_estacao_atual()
	grade.definir_dica("Esquerda e direita trocam a estação. %s fecha." % InputManager.nome_da_tecla(&"ui_cancel"))
	visible = true
	get_tree().paused = true

func fechar() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
