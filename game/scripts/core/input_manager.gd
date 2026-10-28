extends Node

## Abaixo deste valor o eixo do controle é tratado como parado. Stick analógico quase
## nunca fica exatamente em zero, e sem a folga o jogo acharia que o jogador pegou o
## controle só porque o stick tremeu.
const FOLGA_DO_EIXO_DO_CONTROLE: float = 0.5

## Ligado enquanto o jogador mexe numa tela que não pausa o jogo. Com ele ligado, toda
## pergunta de gameplay responde que nada foi pressionado: as teclas vão para a tela, e o personagem não anda nem ataca.
var teclado_capturado: bool = false

var _usando_controle: bool = false

## Como cada botão do controle aparece na tela. Os números são os do JoyButton do Godot
## (o botão de baixo é 0); vale para o controle de Xbox e para o painel arcade.
const NOMES_DOS_BOTOES: Dictionary = {0: "A", 1: "B", 2: "X", 3: "Y", 9: "LB", 10: "RB", 4: "Select", 6: "Start"}
var _posicao_do_mouse: Vector2 = Vector2.ZERO

## Guarda de qual aparelho veio a última entrada e por onde o mouse andou. Não decide
## nada de gameplay: só responde às perguntas de quem pergunta, como o resto deste script.
func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		_usando_controle = false
		_posicao_do_mouse = (evento as InputEventMouseMotion).position
	elif evento is InputEventMouseButton:
		_usando_controle = false
		_posicao_do_mouse = (evento as InputEventMouseButton).position
	elif evento is InputEventKey:
		_usando_controle = false
	elif evento is InputEventJoypadButton:
		_usando_controle = true
	elif evento is InputEventJoypadMotion and absf((evento as InputEventJoypadMotion).axis_value) > FOLGA_DO_EIXO_DO_CONTROLE:
		_usando_controle = true

## Verdadeiro quando a última entrada veio do teclado ou do mouse, e não do controle.
func usando_teclado_e_mouse() -> bool:
	return not _usando_controle

## Posição do mouse na tela, em pixels, da última vez que ele se mexeu ou clicou.
func posicao_do_mouse() -> Vector2:
	return _posicao_do_mouse

func obter_direcao_movimento() -> Vector2:
	if teclado_capturado:
		return Vector2.ZERO
	return Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")

func correr_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_pressed("correr")

## O nome da tecla (ou do botão do controle) ligado a uma ação, para a tela dizer o que
## apertar. Lê o Input Map, então trocar a tecla no projeto troca o texto junto. Segue o
## aparelho em uso: com controle, mostra o botão.
func nome_da_tecla(acao: StringName) -> String:
	for evento in InputMap.action_get_events(acao):
		if _usando_controle and evento is InputEventJoypadButton:
			return NOMES_DOS_BOTOES.get((evento as InputEventJoypadButton).button_index, "Botão")
		if not _usando_controle and evento is InputEventKey:
			var tecla: Key = (evento as InputEventKey).physical_keycode
			# No navegador o Godot não sabe o layout do teclado, e a tradução da tecla
			# física dá erro a cada quadro. Lá vale a tecla física, que é a do padrão QWERTY.
			if not OS.has_feature("web"):
				tecla = DisplayServer.keyboard_get_keycode_from_physical(tecla)
			return OS.get_keycode_string(tecla)
	return "?"

func interagir_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("interagir")

func abrir_inventario_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("abrir_inventario")

func menu_pausa_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("menu_pausa")

func dash_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("dash")

## Verdadeiro enquanto o botão de atacar está apertado. Serve para carregar a área da
## ferramenta aprimorada.
func atacar_segurado() -> bool:
	return not teclado_capturado and Input.is_action_pressed("atacar")

func atacar_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("atacar")

## Devolve o índice do slot rápido pedido por tecla numérica (0 para a tecla 1), ou -1
## quando nenhuma foi pressionada neste quadro. Um método só no lugar de nove quase
## iguais.
func slot_numerico_pressionado() -> int:
	if teclado_capturado:
		return -1
	for indice in 9:
		if Input.is_action_just_pressed("slot_%d" % (indice + 1)):
			return indice
	return -1

func slot_proximo_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("slot_proximo")

func slot_anterior_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("slot_anterior")

## Solta o item da mão, que cai no chão.
func soltar_item_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("soltar_item")
