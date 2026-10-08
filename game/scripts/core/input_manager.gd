extends Node

## Abaixo deste valor o eixo do controle é tratado como parado. Stick analógico quase
## nunca fica exatamente em zero, e sem a folga o jogo acharia que o jogador pegou o
## controle só porque o stick tremeu.
const FOLGA_DO_EIXO_DO_CONTROLE: float = 0.5

## Ligado enquanto o jogador digita no chat ou mexe numa tela que não pausa o jogo (o
## lobby). Com ele ligado, toda pergunta de gameplay responde que nada foi pressionado:
## as teclas vão para a tela, e o personagem não anda nem ataca.
var teclado_capturado: bool = false

var _usando_controle: bool = false
var _posicao_do_mouse: Vector2 = Vector2.ZERO
var _quadro_do_ultimo_movimento_do_mouse: int = -1000

## Guarda de qual aparelho veio a última entrada e por onde o mouse andou. Não decide
## nada de gameplay: só responde às perguntas de quem pergunta, como o resto deste script.
func _input(evento: InputEvent) -> void:
	if evento is InputEventMouseMotion:
		_usando_controle = false
		_posicao_do_mouse = (evento as InputEventMouseMotion).position
		_quadro_do_ultimo_movimento_do_mouse = Engine.get_physics_frames()
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

## Verdadeiro no quadro de física em que o mouse se mexeu e no seguinte.
func mouse_se_moveu_agora() -> bool:
	return Engine.get_physics_frames() - _quadro_do_ultimo_movimento_do_mouse <= 1

func obter_direcao_movimento() -> Vector2:
	if teclado_capturado:
		return Vector2.ZERO
	return Input.get_vector("mover_esquerda", "mover_direita", "mover_cima", "mover_baixo")

func correr_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_pressed("correr")

func interagir_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("interagir")

func abrir_inventario_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("abrir_inventario")

func menu_pausa_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("menu_pausa")

func dash_pressionado() -> bool:
	return not teclado_capturado and Input.is_action_just_pressed("dash")

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

