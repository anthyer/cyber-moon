extends Control

## Menu de pausa com o inventário, estilo Rune Factory.
##
## Abrir o menu pausa o jogo de verdade (get_tree().paused). Por isso este nó fica com
## process_mode ALWAYS: ele precisa ler a entrada com o jogo rodando, para abrir, e com
## o jogo pausado, para fechar.
##
## Os slots são criados por código a partir de uma cena só, slot_inventario.tscn, e só
## mostram o que o InventoryManager tem. Toda mudança passa pelo InventoryManager, que
## avisa pelos sinais e o menu redesenha.
##
## Mover item tem dois caminhos com o mesmo resultado: o mouse usa o arrastar e soltar
## nativo do Godot, e o controle usa pegar e soltar (confirma num slot para pegar,
## navega pelo foco, confirma em outro para soltar), porque controle não arrasta.

const CENA_DO_SLOT: PackedScene = preload("res://scenes/ui/slot_inventario.tscn")

## Espaços de equipamento mostrados na coluna da esquerda, de cima para baixo. O
## primeiro é o item em uso agora, que é o slot rápido selecionado. É var, e não const,
## porque o enum vem de um autoload, que só existe com o jogo rodando.
var _espacos_na_tela: Array[Array] = [
	[SlotInventario.ESPACO_EM_USO, "Equipado"],
	[InventoryManager.Espaco.ARMADURA, "Armadura"],
	[InventoryManager.Espaco.ACESSORIO, "Acessório"],
]

@onready var lista_de_equipamento: VBoxContainer = %ListaDeEquipamento
@onready var matriz: GridContainer = %Matriz
@onready var barra_rapida: GridContainer = %BarraRapida
@onready var nome_do_item: Label = %NomeDoItem
@onready var descricao_do_item: Label = %DescricaoDoItem

var _slots_rapidos: Array[SlotInventario] = []
var _slots_da_matriz: Array[SlotInventario] = []
var _slots_de_equipamento: Array[SlotInventario] = []
var _nomes_dos_espacos: Dictionary = {}

## Slot de onde o controle pegou um item e ainda não soltou. Null quando não há pega.
var _slot_segurado: SlotInventario = null
var _slot_focado: SlotInventario = null

func _ready() -> void:
	visible = false
	_criar_slots()
	_ligar_vizinhos_de_foco()
	InventoryManager.inventory_changed.connect(_atualizar_tudo)
	InventoryManager.equipment_changed.connect(_ao_mudar_equipamento)
	# O "Equipado" e a marca de equipado dependem do slot selecionado, que muda fora do
	# InventoryManager.
	EquipmentManager.slot_selecionado_alterado.connect(_ao_mudar_selecao)
	_atualizar_tudo()

## A entrada é lida no _process, pelo InputManager, porque o menu precisa responder
## tanto com o jogo rodando quanto pausado. Tudo num lugar só também impede que o mesmo
## Esc feche o menu e abra de novo no mesmo quadro.
func _process(_delta: float) -> void:
	var pediu_menu: bool = InputManager.abrir_inventario_pressionado() or InputManager.menu_pausa_pressionado()
	if not visible:
		# Se o jogo já está pausado, outra tela está aberta (o calendário), e o menu não
		# abre por cima dela.
		if pediu_menu and not get_tree().paused:
			abrir()
		return
	# ui_cancel é a ação nativa de voltar dos menus do Godot. Com um item seguro, ela
	# só desfaz a pega; sem nada seguro, fecha o menu como Esc.
	var pediu_voltar: bool = Input.is_action_just_pressed(&"ui_cancel")
	if _slot_segurado != null and pediu_voltar:
		_cancelar_pega()
	elif pediu_menu or pediu_voltar:
		fechar()

func abrir() -> void:
	visible = true
	get_tree().paused = true
	_atualizar_tudo()
	_slots_rapidos[0].grab_focus()

func fechar() -> void:
	_cancelar_pega()
	get_viewport().gui_release_focus()
	visible = false
	get_tree().paused = false

func _criar_slots() -> void:
	for indice in InventoryManager.SLOTS_RAPIDOS:
		_slots_rapidos.append(_novo_slot(indice, -1, barra_rapida))
	for indice in InventoryManager.SLOTS_DA_MATRIZ:
		_slots_da_matriz.append(_novo_slot(InventoryManager.SLOTS_RAPIDOS + indice, -1, matriz))

	for espaco_e_nome in _espacos_na_tela:
		var linha: HBoxContainer = HBoxContainer.new()
		linha.add_theme_constant_override(&"separation", 12)
		var rotulo: Label = Label.new()
		rotulo.text = espaco_e_nome[1]
		rotulo.custom_minimum_size = Vector2(90, 0)
		rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		linha.add_child(rotulo)
		lista_de_equipamento.add_child(linha)
		_slots_de_equipamento.append(_novo_slot(-1, espaco_e_nome[0], linha))
		_nomes_dos_espacos[espaco_e_nome[0]] = espaco_e_nome[1]

func _novo_slot(indice: int, espaco: int, pai: Control) -> SlotInventario:
	var slot: SlotInventario = CENA_DO_SLOT.instantiate() as SlotInventario
	slot.indice_do_slot = indice
	slot.espaco_de_equipamento = espaco
	pai.add_child(slot)
	slot.focado.connect(_ao_focar_slot)
	slot.acionado.connect(_ao_acionar_slot)
	return slot

## O foco automático do Godot escolhe o vizinho pela geometria e às vezes pula entre
## blocos diferentes (matriz, barra rápida, coluna de equipamento) para um slot
## inesperado. Os vizinhos das bordas de cada bloco são ligados à mão.
func _ligar_vizinhos_de_foco() -> void:
	var colunas: int = InventoryManager.COLUNAS
	var ultima_linha: int = InventoryManager.LINHAS - 1

	for coluna in colunas:
		var de_baixo_da_matriz: SlotInventario = _slots_da_matriz[ultima_linha * colunas + coluna]
		var da_barra: SlotInventario = _slots_rapidos[coluna]
		de_baixo_da_matriz.focus_neighbor_bottom = de_baixo_da_matriz.get_path_to(da_barra)
		da_barra.focus_neighbor_top = da_barra.get_path_to(de_baixo_da_matriz)

	var ultimo_equipamento: int = _slots_de_equipamento.size() - 1
	for linha in InventoryManager.LINHAS:
		var inicio_da_linha: SlotInventario = _slots_da_matriz[linha * colunas]
		var equipamento: SlotInventario = _slots_de_equipamento[mini(linha, ultimo_equipamento)]
		inicio_da_linha.focus_neighbor_left = inicio_da_linha.get_path_to(equipamento)
	for indice in _slots_de_equipamento.size():
		var equipamento: SlotInventario = _slots_de_equipamento[indice]
		equipamento.focus_neighbor_right = equipamento.get_path_to(_slots_da_matriz[indice * colunas])
	var primeiro_rapido: SlotInventario = _slots_rapidos[0]
	primeiro_rapido.focus_neighbor_left = primeiro_rapido.get_path_to(_slots_de_equipamento[ultimo_equipamento])

## Confirmar num slot pega, solta ou desequipa, dependendo do que já está seguro.
func _ao_acionar_slot(slot: SlotInventario) -> void:
	if slot.eh_espaco_de_equipamento():
		if _slot_segurado == null:
			# Sem nada seguro, confirmar num espaço ocupado tira o equipamento. O item
			# continua no slot dele, só deixa de estar equipado. O "Equipado" não tem o
			# que tirar: ele é sempre o slot selecionado.
			if not slot.eh_espaco_em_uso() and slot.indice_mostrado() != -1:
				InventoryManager.desequipar(slot.espaco_de_equipamento)
			return
		SlotInventario.transferir(_slot_segurado.indice_mostrado(), -1, slot)
		_cancelar_pega()
		return

	if _slot_segurado == null:
		var pilha: PilhaDeItens = slot.pilha_mostrada()
		if pilha != null and not pilha.esta_vazia():
			_slot_segurado = slot
			slot.segurando = true
		return
	if _slot_segurado != slot:
		SlotInventario.transferir(_slot_segurado.indice_mostrado(), -1, slot)
	_cancelar_pega()

func _cancelar_pega() -> void:
	if _slot_segurado != null:
		_slot_segurado.segurando = false
	_slot_segurado = null

func _ao_focar_slot(slot: SlotInventario) -> void:
	_slot_focado = slot
	_mostrar_descricao(slot)

func _ao_mudar_equipamento(_espaco: int, _item: Item) -> void:
	_atualizar_tudo()

func _ao_mudar_selecao(_indice: int) -> void:
	_atualizar_tudo()

func _atualizar_tudo() -> void:
	for slot: SlotInventario in _slots_rapidos + _slots_da_matriz + _slots_de_equipamento:
		slot.atualizar()
	if _slot_focado != null:
		_mostrar_descricao(_slot_focado)

func _mostrar_descricao(slot: SlotInventario) -> void:
	var pilha: PilhaDeItens = slot.pilha_mostrada()
	if pilha != null and not pilha.esta_vazia():
		nome_do_item.text = pilha.item.nome
		descricao_do_item.text = pilha.item.descricao
		return
	if slot.eh_espaco_de_equipamento():
		nome_do_item.text = "%s (vazio)" % _nomes_dos_espacos[slot.espaco_de_equipamento]
	else:
		nome_do_item.text = ""
	descricao_do_item.text = ""
