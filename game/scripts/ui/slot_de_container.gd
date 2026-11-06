class_name SlotDeContainer
extends Panel

## Um quadrado da tela de baú. Só mostra uma pilha e avisa quando é focado ou acionado.
##
## Não é o SlotInventario porque aquele lê o InventoryManager sozinho e arrasta; aqui o
## mesmo slot serve o baú e o inventário, e quem decide o que o clique faz é a tela. Por
## isso ele não sabe de onde vem a pilha: a tela entrega com mostrar().

signal focado(slot: SlotDeContainer)
## Clique do mouse ou ui_accept com foco. Os dois caminhos emitem o mesmo sinal, para o
## mouse e o controle darem sempre o mesmo resultado.
signal acionado(slot: SlotDeContainer)

## O visual do slot vem do Theme: trocar de estado é trocar a variation.
const VARIACAO_NORMAL: StringName = &"SlotNormal"
const VARIACAO_FOCADA: StringName = &"SlotFocado"

## Verdadeiro para slot do baú, falso para slot do inventário do jogador.
var do_bau: bool = false
## Índice no ContainerDeItens do baú ou no InventoryManager, conforme do_bau.
var indice: int = -1
## A pilha mostrada agora. Null quando o slot está vazio.
var pilha: PilhaDeItens = null

@onready var icone: TextureRect = $Icone
@onready var rotulo_quantidade: Label = $Quantidade

func _ready() -> void:
	# O número fica legível sobre qualquer ícone com o contorno na cor do fundo.
	rotulo_quantidade.add_theme_color_override(&"font_color", CoresDaInterface.texto())
	rotulo_quantidade.add_theme_color_override(&"font_outline_color", CoresDaInterface.noite())
	focus_entered.connect(_ao_ganhar_foco)
	focus_exited.connect(_atualizar_estilo)
	_atualizar_estilo()
	mostrar(pilha)

func esta_vazio() -> bool:
	return pilha == null or pilha.esta_vazia()

func mostrar(nova_pilha: PilhaDeItens) -> void:
	pilha = nova_pilha
	if not is_node_ready():
		return
	if esta_vazio():
		icone.texture = null
		rotulo_quantidade.visible = false
		return
	icone.texture = pilha.item.icone
	rotulo_quantidade.text = str(pilha.quantidade)
	rotulo_quantidade.visible = pilha.quantidade > 1

func _gui_input(evento: InputEvent) -> void:
	var clicou: bool = evento is InputEventMouseButton and (evento as InputEventMouseButton).pressed and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if clicou or evento.is_action_pressed(&"ui_accept"):
		# O clique também leva o foco para cá, para o rodapé falar do slot clicado.
		grab_focus()
		acionado.emit(self)
		accept_event()

func _ao_ganhar_foco() -> void:
	_atualizar_estilo()
	focado.emit(self)

func _atualizar_estilo() -> void:
	theme_type_variation = VARIACAO_FOCADA if has_focus() else VARIACAO_NORMAL
