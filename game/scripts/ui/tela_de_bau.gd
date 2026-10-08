class_name TelaDeBau
extends Control

## A tela de um baú: os slots dele em cima e o inventário do jogador embaixo.
##
## Serve o baú de guardar e o baú de venda. A diferença entre os dois (o que cada um
## aceita, e o valor da venda) é do próprio Bau; esta tela só pergunta.
##
## Não há arrastar. Um clique, ou confirmar com o slot focado, manda a pilha inteira para
## o outro lado: do inventário para o baú, ou do baú para o inventário. Assim o mouse e o
## controle fazem a mesma coisa pelo mesmo caminho.
##
## Abrir pausa o jogo de verdade, como o menu de pausa e o calendário, e por isso este nó
## fica com process_mode ALWAYS. Ele precisa vir depois do MenuPausa na cena: assim, no
## quadro em que o Esc fecha o baú, o MenuPausa já rodou, viu o jogo pausado e não abriu
## por cima.

const CENA_DO_SLOT: PackedScene = preload("res://scenes/ui/slot_de_container.tscn")

const AJUDA_DE_GUARDAR: String = "Clique num item para mandar para o outro lado."
const AJUDA_DE_VENDA: String = "O que ficar aqui é vendido quando você dormir."
const AVISO_DE_ITEM_RECUSADO: String = "Isso não pode ir neste baú."
const AVISO_DE_BAU_CHEIO: String = "O baú está cheio."
const AVISO_DE_INVENTARIO_CHEIO: String = "O inventário está cheio."

@onready var titulo: Label = %Titulo
@onready var grade_do_bau: GridContainer = %GradeDoBau
@onready var matriz: GridContainer = %Matriz
@onready var barra_rapida: GridContainer = %BarraRapida
@onready var valor_da_venda: Label = %ValorDaVenda
@onready var nome_do_item: Label = %NomeDoItem
@onready var linha_de_ajuda: Label = %LinhaDeAjuda
@onready var botao_fechar: Button = %BotaoFechar

## O baú aberto agora. Null com a tela fechada.
var _bau: Bau = null
var _slots_do_bau: Array[SlotDeContainer] = []
## Os 36 slots do inventário, na ordem do InventoryManager: a barra rápida primeiro.
var _slots_do_inventario: Array[SlotDeContainer] = []
var _slot_focado: SlotDeContainer = null

func _ready() -> void:
	visible = false
	botao_fechar.pressed.connect(fechar)
	EventBus.chest_requested.connect(abrir)
	_criar_slots_do_inventario()

## A entrada é lida no _process porque a tela só responde com o jogo pausado, e o
## InputManager é o caminho de leitura do projeto.
func _process(_delta: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(&"ui_cancel") or InputManager.abrir_inventario_pressionado():
		fechar()

## Não abre por cima de outra tela que já pausou o jogo, nem com o jogador caído.
func abrir(bau: Bau) -> void:
	if visible or bau == null or get_tree().paused or StatusManager.esta_desmaiado:
		return
	_bau = bau
	titulo.text = bau.nome_exibido
	valor_da_venda.visible = bau.e_de_venda()
	linha_de_ajuda.text = AJUDA_DE_VENDA if bau.e_de_venda() else AJUDA_DE_GUARDAR
	nome_do_item.text = ""
	_criar_slots_do_bau()
	# Os sinais são ligados aqui, e não no _ready, porque o baú muda de uma abertura para
	# a outra, e a tela fechada não tem por que redesenhar.
	_bau.conteudo.changed.connect(_redesenhar)
	InventoryManager.inventory_changed.connect(_redesenhar)
	_redesenhar()
	visible = true
	get_tree().paused = true
	_slots_do_inventario[InventoryManager.SLOTS_RAPIDOS].grab_focus()

func fechar() -> void:
	if not visible:
		return
	if _bau != null and is_instance_valid(_bau):
		_bau.conteudo.changed.disconnect(_redesenhar)
	InventoryManager.inventory_changed.disconnect(_redesenhar)
	_bau = null
	_slot_focado = null
	get_viewport().gui_release_focus()
	visible = false
	get_tree().paused = false

## O inventário tem sempre o mesmo tamanho, então os slots dele são criados uma vez só.
func _criar_slots_do_inventario() -> void:
	for indice in InventoryManager.SLOTS_RAPIDOS:
		_slots_do_inventario.append(_novo_slot(false, indice, barra_rapida))
	for indice in InventoryManager.SLOTS_DA_MATRIZ:
		_slots_do_inventario.append(_novo_slot(false, InventoryManager.SLOTS_RAPIDOS + indice, matriz))

## Os do baú são refeitos a cada abertura, porque cada baú pode ter um tamanho.
func _criar_slots_do_bau() -> void:
	for slot in _slots_do_bau:
		# Sai da grade na hora: o queue_free só apaga no fim do quadro, e até lá o slot
		# velho ocuparia lugar ao lado dos novos.
		grade_do_bau.remove_child(slot)
		slot.queue_free()
	_slots_do_bau.clear()
	for indice in _bau.conteudo.total_de_slots():
		_slots_do_bau.append(_novo_slot(true, indice, grade_do_bau))

func _novo_slot(do_bau: bool, indice: int, pai: Control) -> SlotDeContainer:
	var slot: SlotDeContainer = CENA_DO_SLOT.instantiate() as SlotDeContainer
	slot.do_bau = do_bau
	slot.indice = indice
	pai.add_child(slot)
	slot.focado.connect(_ao_focar_slot)
	slot.acionado.connect(_ao_acionar_slot)
	return slot

func _redesenhar() -> void:
	if _bau == null:
		return
	for slot in _slots_do_bau:
		slot.mostrar(_bau.conteudo.slot_em(slot.indice))
	for slot in _slots_do_inventario:
		slot.mostrar(InventoryManager.slot_em(slot.indice))
	if _bau.e_de_venda():
		valor_da_venda.text = "Valor da venda: %d créditos" % _bau.valor_total()
	if _slot_focado != null:
		_mostrar_nome(_slot_focado)

## Manda a pilha inteira para o outro lado. Quando não dá, o rodapé diz o motivo, porque
## os avisos da tela do jogo ficam escondidos com ele pausado.
func _ao_acionar_slot(slot: SlotDeContainer) -> void:
	if _bau == null or slot.esta_vazio():
		return
	var item: Item = slot.pilha.item
	if slot.do_bau:
		if not _bau.conteudo.devolver_ao_inventario(slot.indice):
			nome_do_item.text = AVISO_DE_INVENTARIO_CHEIO
		return
	if _bau.conteudo.receber_do_inventario(slot.indice, _bau.aceita):
		return
	nome_do_item.text = AVISO_DE_BAU_CHEIO if _bau.aceita(item) else AVISO_DE_ITEM_RECUSADO

func _ao_focar_slot(slot: SlotDeContainer) -> void:
	_slot_focado = slot
	_mostrar_nome(slot)

func _mostrar_nome(slot: SlotDeContainer) -> void:
	nome_do_item.text = "" if slot.esta_vazio() else slot.pilha.item.nome
