class_name SlotInventario
extends Panel

## Um quadrado do inventário na tela. A mesma cena serve os 36 slots comuns e os
## espaços de equipamento, para o visual e o arrastar e soltar existirem num lugar só.
##
## O slot não guarda item nenhum: ele só mostra o que o InventoryManager tem no índice
## dele. Num espaço de equipamento, o índice mostrado é o do slot equipado, porque
## equipar não copia o item (ver InventoryManager).

## Emitido quando o slot ganha foco, para o menu mostrar nome e descrição do item.
signal focado(slot: SlotInventario)
## Emitido quando o jogador confirma (ui_accept) com o slot focado. Quem decide se isso
## pega, solta ou desequipa é o menu, que sabe se há um item seguro.
signal acionado(slot: SlotInventario)

const COR_DE_FUNDO: Color = Color(0.06, 0.07, 0.12, 0.85)
const COR_DA_BORDA: Color = Color(0.25, 0.3, 0.45, 1.0)
const COR_DA_BORDA_FOCADA: Color = Color(0.2, 0.95, 1.0, 1.0)
const COR_DA_BORDA_SEGURANDO: Color = Color(1.0, 0.25, 0.8, 1.0)
const TAMANHO_DA_PREVIA: Vector2 = Vector2(40, 40)

## Índice no InventoryManager.slots. Ignorado quando o slot é espaço de equipamento.
@export var indice_do_slot: int = -1
## Valor de InventoryManager.Espaco quando este slot é um espaço de equipamento, ou -1
## quando é um slot comum do inventário.
@export var espaco_de_equipamento: int = -1

## Ligado pelo menu enquanto este slot é a origem de um pegar e soltar pelo controle.
var segurando: bool = false:
	set(valor):
		segurando = valor
		_atualizar_estilo()

@onready var icone: TextureRect = $Icone
@onready var rotulo_quantidade: Label = $Quantidade
@onready var marca_equipado: Label = $MarcaEquipado

var _estilo: StyleBoxFlat = StyleBoxFlat.new()

func _ready() -> void:
	_estilo.bg_color = COR_DE_FUNDO
	_estilo.set_border_width_all(2)
	_estilo.set_corner_radius_all(4)
	add_theme_stylebox_override(&"panel", _estilo)
	focus_entered.connect(_ao_ganhar_foco)
	focus_exited.connect(_atualizar_estilo)
	_atualizar_estilo()
	atualizar()

func eh_espaco_de_equipamento() -> bool:
	return espaco_de_equipamento != -1

## Índice do InventoryManager que este slot mostra agora. Num espaço de equipamento é
## o slot equipado, que pode ser -1 quando o espaço está vazio.
func indice_mostrado() -> int:
	if eh_espaco_de_equipamento():
		return InventoryManager.indice_equipado(espaco_de_equipamento)
	return indice_do_slot

func pilha_mostrada() -> PilhaDeItens:
	return InventoryManager.slot_em(indice_mostrado())

## Relê o InventoryManager e redesenha ícone, quantidade e marca de equipado.
func atualizar() -> void:
	if not is_node_ready():
		return
	var pilha: PilhaDeItens = pilha_mostrada()
	if pilha == null or pilha.esta_vazia():
		icone.texture = null
		rotulo_quantidade.visible = false
	else:
		icone.texture = pilha.item.icone
		rotulo_quantidade.text = str(pilha.quantidade)
		rotulo_quantidade.visible = pilha.quantidade > 1
	marca_equipado.visible = not eh_espaco_de_equipamento() and _esta_equipado()

## Move o conteúdo de um slot de origem para o slot de destino. Fica aqui, e não no
## menu, porque o arraste do mouse e o pegar e soltar do controle fazem exatamente a
## mesma coisa e precisam dar o mesmo resultado.
static func transferir(indice_origem: int, espaco_origem: int, destino: SlotInventario) -> void:
	if indice_origem < 0:
		return
	if destino.eh_espaco_de_equipamento():
		InventoryManager.equipar(destino.espaco_de_equipamento, indice_origem)
		return
	# Tirar um item de um espaço de equipamento e soltar no inventário é desequipar. O
	# item continua no slot dele, então só muda de lugar se o destino for outro slot.
	if espaco_origem != -1:
		InventoryManager.desequipar(espaco_origem)
	InventoryManager.mover(indice_origem, destino.indice_do_slot)

func _get_drag_data(_posicao: Vector2) -> Variant:
	var pilha: PilhaDeItens = pilha_mostrada()
	if pilha == null or pilha.esta_vazia():
		return null
	var previa: TextureRect = TextureRect.new()
	previa.texture = pilha.item.icone
	previa.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	previa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	previa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	previa.size = TAMANHO_DA_PREVIA
	previa.position = -TAMANHO_DA_PREVIA / 2.0
	# O preview precisa de um nó pai para o deslocamento valer, senão o ícone fica com o
	# canto no ponteiro em vez do centro.
	var suporte: Control = Control.new()
	suporte.add_child(previa)
	set_drag_preview(suporte)
	return {"indice_origem": indice_mostrado(), "espaco_origem": espaco_de_equipamento}

func _can_drop_data(_posicao: Vector2, dados: Variant) -> bool:
	if not (dados is Dictionary and dados.has("indice_origem")):
		return false
	if not eh_espaco_de_equipamento():
		return true
	var pilha: PilhaDeItens = InventoryManager.slot_em(dados["indice_origem"])
	if pilha == null:
		return false
	return InventoryManager.aceita(espaco_de_equipamento, pilha.item)

func _drop_data(_posicao: Vector2, dados: Variant) -> void:
	transferir(dados["indice_origem"], dados["espaco_origem"], self)

func _gui_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"ui_accept"):
		acionado.emit(self)
		accept_event()

func _ao_ganhar_foco() -> void:
	_atualizar_estilo()
	focado.emit(self)

func _esta_equipado() -> bool:
	for espaco in InventoryManager.CATEGORIAS_POR_ESPACO:
		if InventoryManager.indice_equipado(espaco) == indice_do_slot:
			return true
	return false

func _atualizar_estilo() -> void:
	if segurando:
		_estilo.border_color = COR_DA_BORDA_SEGURANDO
	elif has_focus():
		_estilo.border_color = COR_DA_BORDA_FOCADA
	else:
		_estilo.border_color = COR_DA_BORDA
