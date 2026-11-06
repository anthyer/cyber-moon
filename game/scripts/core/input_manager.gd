extends Node

## Abaixo deste valor o eixo do controle é tratado como parado. Stick analógico quase
## nunca fica exatamente em zero, e sem a folga o jogo acharia que o jogador pegou o
## controle só porque o stick tremeu.
const FOLGA_DO_EIXO_DO_CONTROLE: float = 0.5
## Folga menor para o giro de modelo pelo direcional direito: ali o toque leve é para
## girar devagar, como no movimento.
const FOLGA_DO_GIRO_DO_DIRECIONAL_DIREITO: float = 0.2

## Ligado enquanto o jogador digita no chat ou mexe numa tela que não pausa o jogo (o
## lobby). Com ele ligado, toda pergunta de gameplay responde que nada foi pressionado:
## as teclas vão para a tela, e o personagem não anda nem ataca.
var teclado_capturado: bool = false

var _usando_controle: bool = false

## Como cada botão do controle aparece na tela. Os números são os do JoyButton do Godot
## (o botão de baixo é 0); vale para o controle de Xbox e para o painel arcade.
const NOMES_DOS_BOTOES: Dictionary = {0: "A", 1: "B", 2: "X", 3: "Y", 9: "LB", 10: "RB", 4: "Select", 6: "Start"}
var _posicao_do_mouse: Vector2 = Vector2.ZERO

## Continua ouvindo com o jogo pausado, para as telas de pausa (o menu de pausa) saberem
## quando o jogador troca do teclado para o controle com elas abertas.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
			var tecla_do_evento: InputEventKey = evento as InputEventKey
			# As ações nativas da interface (ui_accept, por exemplo) guardam a tecla pelo
			# keycode, e não pela posição física.
			if tecla_do_evento.physical_keycode == KEY_NONE:
				return OS.get_keycode_string(tecla_do_evento.keycode)
			var tecla: Key = DisplayServer.keyboard_get_keycode_from_physical(tecla_do_evento.physical_keycode)
			return OS.get_keycode_string(tecla)
	return "?"

## Quanto o direcional direito do controle está empurrado para o lado, de -1 (esquerda) a
## 1 (direita), ou zero dentro da folga. Gira o modelo do palco de modelo (ModelStage) nas
## telas que deixam girar; não é uma ação do Input Map porque o valor é contínuo.
func giro_do_direcional_direito() -> float:
	if teclado_capturado:
		return 0.0
	var maior: float = 0.0
	for aparelho in Input.get_connected_joypads():
		var eixo: float = Input.get_joy_axis(aparelho, JOY_AXIS_RIGHT_X)
		if absf(eixo) > absf(maior):
			maior = eixo
	if absf(maior) < FOLGA_DO_GIRO_DO_DIRECIONAL_DIREITO:
		return 0.0
	return maior

func interagir_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("interagir")

func abrir_inventario_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("abrir_inventario")

func menu_pausa_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("menu_pausa")

## Trocam a aba do menu de pausa (Q e E, L1 e R1). Só o menu de pausa pergunta: fora
## dele, as mesmas teclas soltam item e abrem o inventário.
func aba_anterior_pressionada() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("aba_anterior")

func aba_seguinte_pressionada() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("aba_seguinte")

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

## Temporária: avança um dia para testar o crescimento das plantas. Sai quando o plano
## 10 trouxer o ciclo de dia automático.
func teste_avancar_dia_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("teste_avancar_dia")

## Solta o item da mão. Perto de um NPC, é dar de presente; longe, o item cai no chão.
func soltar_item_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("soltar_item")

## Abre o campo de texto do chat (Enter ou T).
func abrir_chat_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("abrir_chat")

## Abre e fecha o menu de debug. Só no teclado, de propósito: é ferramenta de teste.
func menu_debug_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("menu_debug")

