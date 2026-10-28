extends Control

## Barra de acesso rápido na tela, estilo Minecraft: os 9 slots rápidos do inventário,
## com o selecionado destacado. O slot selecionado é o item em uso.
##
## Ela só mostra. A posse dos itens é do InventoryManager e a seleção é do
## EquipmentManager; a barra escuta os sinais dos dois e não conhece mais nada.

const CENA_DO_SLOT: PackedScene = preload("res://scenes/ui/slot_inventario.tscn")

## Quanto tempo o nome do item fica visível acima do slot depois de trocar a seleção,
## e quanto dura o sumiço no fim.
const DURACAO_DO_NOME: float = 2.0
const DURACAO_DO_SUMICO: float = 0.4

@onready var caixa_dos_slots: HBoxContainer = $Slots
@onready var nome_do_item: Label = $NomeDoItem

var _slots: Array[SlotInventario] = []
var _animacao_do_nome: Tween = null

func _ready() -> void:
	# A barra processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir.
	# Se ela pausasse junto com o jogo, o _process parava antes de ela se esconder e a
	# barra ficaria por cima do menu de pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	nome_do_item.modulate.a = 0.0
	for indice in InventoryManager.SLOTS_RAPIDOS:
		var slot: SlotInventario = CENA_DO_SLOT.instantiate() as SlotInventario
		slot.indice_do_slot = indice
		slot.somente_exibicao = true
		caixa_dos_slots.add_child(slot)
		_slots.append(slot)
	InventoryManager.inventory_changed.connect(_atualizar_slots)
	EquipmentManager.slot_selecionado_alterado.connect(_ao_mudar_selecao)
	_atualizar_slots()
	_marcar_selecionado(EquipmentManager.indice_selecionado)

func _process(_delta: float) -> void:
	visible = not get_tree().paused

func _atualizar_slots() -> void:
	for slot in _slots:
		slot.atualizar()

func _ao_mudar_selecao(indice: int) -> void:
	_marcar_selecionado(indice)
	_mostrar_nome(indice)

func _marcar_selecionado(indice: int) -> void:
	for slot in _slots:
		slot.selecionado = slot.indice_do_slot == indice

## Mostra o nome do item acima do slot selecionado e some depois de um tempo, como no
## Minecraft. Ajuda quando os ícones são pequenos. Slot vazio não mostra nada.
func _mostrar_nome(indice: int) -> void:
	if _animacao_do_nome != null:
		_animacao_do_nome.kill()
	var item: Item = EquipmentManager.item_na_mao()
	if item == null:
		nome_do_item.modulate.a = 0.0
		return
	nome_do_item.text = item.nome
	var slot: SlotInventario = _slots[indice]
	var centro_do_slot: float = caixa_dos_slots.position.x + slot.position.x + slot.size.x / 2.0
	nome_do_item.position.x = centro_do_slot - nome_do_item.size.x / 2.0
	nome_do_item.modulate.a = 1.0
	_animacao_do_nome = create_tween()
	_animacao_do_nome.tween_interval(DURACAO_DO_NOME)
	_animacao_do_nome.tween_property(nome_do_item, "modulate:a", 0.0, DURACAO_DO_SUMICO)
