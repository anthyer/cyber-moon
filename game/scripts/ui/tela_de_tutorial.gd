class_name TelaDeTutorial
extends Control

## A tela que aparece logo depois de começar a demo: os controles, numa tela só, e
## onde fica cada coisa na cidade.
##
## Abre sozinha quando a fase entra, e pausa o jogo até o jogador fechar, como o menu de
## pausa. Por isso fica com process_mode ALWAYS. Precisa vir depois do MenuPausa na cena:
## no quadro em que o Esc fecha esta tela, o MenuPausa já rodou, viu o jogo pausado e não
## abriu por cima. A mesma tabela continua à mão depois, na aba Controles do menu de pausa.

@onready var botao_comecar: Button = %BotaoComecar

func _ready() -> void:
	botao_comecar.pressed.connect(fechar)
	abrir.call_deferred()

func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed(&"ui_cancel"):
		fechar()

func abrir() -> void:
	visible = true
	get_tree().paused = true
	botao_comecar.grab_focus()

func fechar() -> void:
	if not visible:
		return
	get_viewport().gui_release_focus()
	visible = false
	get_tree().paused = false
