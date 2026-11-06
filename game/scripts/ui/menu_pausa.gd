extends Control

## Menu de pausa, estilo Rune Factory: uma fileira de abas no alto (Inventário,
## Equipamento, Relacionamentos, Diário, Mapa, Calendário, Opções), trocadas com Q e E
## (L1 e R1 no controle) ou com o clique na aba. Cada aba é uma página dentro de Paginas;
## trocar de aba só mostra uma e esconde as outras, então nada é recriado. Diário, Mapa e
## Opções ainda são reservadas (planos 32 e 33, e a tela de opções do plano 40).
##
## Abrir o menu pausa o jogo de verdade (get_tree().paused). Por isso este nó fica com
## process_mode ALWAYS: ele precisa ler a entrada com o jogo rodando, para abrir, e com
## o jogo pausado, para fechar.
##
## Q e E são também soltar_item e abrir_inventario. Com o menu aberto, a troca de aba vem
## primeiro: o E troca de aba e não fecha o menu, e o Q troca de aba e não solta nada
## (o jogador está pausado). Fecha com Esc (menu_pausa ou ui_cancel) ou com um botão de
## abrir_inventario que não troca de aba (Y e Start no controle).
##
## Inventário: os slots são criados por código a partir de uma cena só,
## slot_inventario.tscn, e só mostram o que o InventoryManager tem. Toda mudança passa
## pelo InventoryManager, que avisa pelos sinais e o menu redesenha. Mover item tem dois
## caminhos com o mesmo resultado: o mouse usa o arrastar e soltar nativo do Godot, e o
## controle usa pegar e soltar (confirma num slot para pegar, navega pelo foco, confirma
## em outro para soltar), porque controle não arrasta.

const CENA_DO_SLOT: PackedScene = preload("res://scenes/ui/slot_inventario.tscn")

## As abas, na ordem da fileira. O índice de cada uma é a posição aqui.
const NOMES_DAS_ABAS: Array[String] = ["Inventário", "Equipamento", "Relacionamentos", "Diário", "Mapa", "Calendário", "Opções"]
const ABA_INVENTARIO: int = 0
const ABA_EQUIPAMENTO: int = 1
const ABA_RELACIONAMENTOS: int = 2
const ABA_DIARIO: int = 3
const ABA_MAPA: int = 4
const ABA_CALENDARIO: int = 5
const ABA_OPCOES: int = 6

## Quantas linhas de slots trancados aparecem embaixo da mochila. O inventário ainda não
## cresce (não existe mochila maior), então elas só mostram que há espaço por vir.
const LINHAS_TRANCADAS: int = 1
const OPACIDADE_DO_FUNDO: float = 0.6

## O nome e a cor (pelo nome em CoresDaInterface) de cada categoria de item, na etiqueta
## do cartão. Texto de tela, não regra de jogo.
const ETIQUETAS_DAS_CATEGORIAS: Dictionary = {
	Item.Categoria.RECURSO: ["Recurso", &"texto_apagado"],
	Item.Categoria.SEMENTE: ["Semente", &"verde"],
	Item.Categoria.COLHEITA: ["Colheita", &"verde"],
	Item.Categoria.FERRAMENTA: ["Ferramenta", &"ciano"],
	Item.Categoria.ARMA: ["Arma", &"magenta"],
	Item.Categoria.ARMADURA: ["Armadura", &"ciano"],
	Item.Categoria.CONSUMIVEL: ["Consumível", &"verde"],
	Item.Categoria.MATERIAL: ["Material", &"texto_apagado"],
	Item.Categoria.ESPECIAL: ["Especial", &"violeta"],
	Item.Categoria.ACESSORIO: ["Acessório", &"ciano"],
}

## Espaços de equipamento mostrados na coluna da esquerda, de cima para baixo. O
## primeiro é o item em uso agora, que é o slot rápido selecionado. É var, e não const,
## porque o enum vem de um autoload, que só existe com o jogo rodando.
var _espacos_na_tela: Array[Array] = [
	[SlotInventario.ESPACO_EM_USO, "Equipado"],
	[InventoryManager.Espaco.ARMADURA, "Armadura"],
	[InventoryManager.Espaco.ACESSORIO, "Acessório"],
]

@onready var fundo: ColorRect = %Fundo
@onready var abas: TabBar = %Abas
@onready var tecla_anterior: Label = %TeclaAnterior
@onready var tecla_seguinte: Label = %TeclaSeguinte
@onready var lista_de_equipamento: VBoxContainer = %ListaDeEquipamento
@onready var matriz: GridContainer = %Matriz
@onready var trancados: GridContainer = %Trancados
@onready var barra_rapida: GridContainer = %BarraRapida
@onready var ocupacao: Label = %Ocupacao
@onready var lixeira: LixeiraDoInventario = %Lixeira
@onready var icone_grande: TextureRect = %IconeGrande
@onready var nome_do_item: Label = %NomeDoItem
@onready var categoria_do_item: Label = %CategoriaDoItem
@onready var descricao_do_item: Label = %DescricaoDoItem
@onready var efeitos_do_item: VBoxContainer = %EfeitosDoItem
@onready var dica_do_cartao: Label = %DicaDoCartao
@onready var aba_de_equipamento: AbaDeEquipamento = %AbaDeEquipamento
@onready var aba_de_relacionamentos: AbaDeRelacionamentos = %AbaDeRelacionamentos
@onready var grade_do_calendario: GradeDoCalendario = %GradeDoCalendario
## As páginas na ordem de NOMES_DAS_ABAS.
@onready var _paginas: Array[Control] = [%PaginaInventario, %AbaDeEquipamento, %AbaDeRelacionamentos, %AbaDoDiario, %AbaDoMapa, %AbaDoCalendario, %AbaDeOpcoes]

var _slots_rapidos: Array[SlotInventario] = []
var _slots_da_matriz: Array[SlotInventario] = []
var _slots_de_equipamento: Array[SlotInventario] = []
var _nomes_dos_espacos: Dictionary = {}
var _aba_atual: int = ABA_INVENTARIO

## Slot de onde o controle pegou um item e ainda não soltou. Null quando não há pega.
var _slot_segurado: SlotInventario = null
var _slot_focado: SlotInventario = null

func _ready() -> void:
	visible = false
	fundo.color = Color(CoresDaInterface.noite(), OPACIDADE_DO_FUNDO)
	for nome in NOMES_DAS_ABAS:
		abas.add_tab(nome)
	abas.tab_changed.connect(_ao_clicar_na_aba)
	_criar_slots()
	lixeira.descarte_pedido.connect(_descartar)
	lixeira.acionada.connect(_ao_acionar_lixeira)
	lixeira.focus_entered.connect(_ao_focar_lixeira)
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
	var pediu_inventario: bool = InputManager.abrir_inventario_pressionado()
	var pediu_pausa: bool = InputManager.menu_pausa_pressionado()
	if not visible:
		# Se o jogo já está pausado, outra tela está aberta (o calendário), e o menu não
		# abre por cima dela. Também não abre no meio de uma conversa.
		if (pediu_inventario or pediu_pausa) and not get_tree().paused and not DialogueManager.em_dialogo and not DialogueManager.acabou_de_encerrar():
			abrir()
		return
	_mostrar_teclas_das_abas()
	# A troca de aba vem antes de tudo e consome o quadro: o E é também abrir_inventario
	# e não pode fechar o menu no mesmo quadro em que troca de aba.
	var passo: int = 0
	if InputManager.aba_seguinte_pressionada():
		passo = 1
	elif InputManager.aba_anterior_pressionada():
		passo = -1
	if passo != 0:
		_mostrar_aba(posmod(_aba_atual + passo, NOMES_DAS_ABAS.size()))
		return
	# ui_cancel é a ação nativa de voltar dos menus do Godot. Com um item seguro, ela
	# só desfaz a pega; sem nada seguro, fecha o menu como Esc.
	var pediu_voltar: bool = Input.is_action_just_pressed(&"ui_cancel")
	if _slot_segurado != null and pediu_voltar:
		_cancelar_pega()
	elif pediu_inventario or pediu_pausa or pediu_voltar:
		fechar()
	elif _aba_atual == ABA_CALENDARIO:
		if Input.is_action_just_pressed(&"ui_left"):
			grade_do_calendario.mostrar_estacao_vizinha(-1)
		elif Input.is_action_just_pressed(&"ui_right"):
			grade_do_calendario.mostrar_estacao_vizinha(1)

func abrir() -> void:
	visible = true
	get_tree().paused = true
	_mostrar_teclas_das_abas()
	# O menu sempre abre no inventário, que é para o que o jogador mais o abre.
	_mostrar_aba(ABA_INVENTARIO)
	_atualizar_tudo()
	_slots_rapidos[0].grab_focus()

func fechar() -> void:
	_cancelar_pega()
	get_viewport().gui_release_focus()
	visible = false
	get_tree().paused = false

## Mostra uma aba e esconde as outras, e dá o foco ao que a aba nova tem para focar.
func _mostrar_aba(indice: int) -> void:
	# Um item seguro pelo controle ficaria preso numa aba que não aparece mais.
	_cancelar_pega()
	# Soltar o foco antes de esconder a página faz o cartão de morador focado voltar ao
	# modo foto.
	get_viewport().gui_release_focus()
	_aba_atual = indice
	# A aba também é marcada aqui, porque Q, E e abrir o menu trocam de aba sem clique.
	if abas.current_tab != indice:
		abas.current_tab = indice
	for numero in _paginas.size():
		_paginas[numero].visible = numero == indice
	match indice:
		ABA_INVENTARIO:
			(_slot_focado if _slot_focado != null else _slots_rapidos[0]).grab_focus()
		ABA_RELACIONAMENTOS:
			var primeiro: Control = aba_de_relacionamentos.primeiro_cartao()
			if primeiro != null:
				primeiro.grab_focus()
		ABA_CALENDARIO:
			grade_do_calendario.mostrar_estacao_atual()
			grade_do_calendario.definir_dica("%s e %s trocam a estação." % [InputManager.nome_da_tecla(&"mover_esquerda"), InputManager.nome_da_tecla(&"mover_direita")])

func _ao_clicar_na_aba(indice: int) -> void:
	if indice != _aba_atual:
		_mostrar_aba(indice)

## As teclas dos dois lados da fileira seguem o aparelho em uso: Q e E no teclado, LB e
## RB no controle.
func _mostrar_teclas_das_abas() -> void:
	tecla_anterior.text = InputManager.nome_da_tecla(&"aba_anterior")
	tecla_seguinte.text = InputManager.nome_da_tecla(&"aba_seguinte")

func _criar_slots() -> void:
	for indice in InventoryManager.SLOTS_RAPIDOS:
		_slots_rapidos.append(_novo_slot(indice, -1, barra_rapida))
	for indice in InventoryManager.SLOTS_DA_MATRIZ:
		_slots_da_matriz.append(_novo_slot(InventoryManager.SLOTS_RAPIDOS + indice, -1, matriz))
	for indice in LINHAS_TRANCADAS * InventoryManager.COLUNAS:
		var trancado: Panel = Panel.new()
		trancado.custom_minimum_size = _slots_rapidos[0].custom_minimum_size
		trancado.theme_type_variation = &"SlotTrancado"
		trancado.tooltip_text = "Trancado"
		trancados.add_child(trancado)

	for espaco_e_nome in _espacos_na_tela:
		var rotulo: Label = Label.new()
		rotulo.text = espaco_e_nome[1]
		rotulo.theme_type_variation = &"TextoApagado"
		lista_de_equipamento.add_child(rotulo)
		_slots_de_equipamento.append(_novo_slot(-1, espaco_e_nome[0], lista_de_equipamento))
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

	# A linha trancada fica entre a matriz e a barra rápida, mas não recebe foco: descer
	# da matriz pula direto para a barra.
	for coluna in colunas:
		var de_baixo_da_matriz: SlotInventario = _slots_da_matriz[ultima_linha * colunas + coluna]
		var da_barra: SlotInventario = _slots_rapidos[coluna]
		de_baixo_da_matriz.focus_neighbor_bottom = de_baixo_da_matriz.get_path_to(da_barra)
		da_barra.focus_neighbor_top = da_barra.get_path_to(de_baixo_da_matriz)
		# A fileira de abas não recebe foco (troca com Q e E), então subir da primeira
		# linha não sai da matriz.
		var de_cima_da_matriz: SlotInventario = _slots_da_matriz[coluna]
		de_cima_da_matriz.focus_neighbor_top = de_cima_da_matriz.get_path_to(de_cima_da_matriz)

	var ultimo_equipamento: int = _slots_de_equipamento.size() - 1
	for linha in InventoryManager.LINHAS:
		var inicio_da_linha: SlotInventario = _slots_da_matriz[linha * colunas]
		var equipamento: SlotInventario = _slots_de_equipamento[mini(linha, ultimo_equipamento)]
		inicio_da_linha.focus_neighbor_left = inicio_da_linha.get_path_to(equipamento)
	for indice in _slots_de_equipamento.size():
		var equipamento: SlotInventario = _slots_de_equipamento[indice]
		equipamento.focus_neighbor_right = equipamento.get_path_to(_slots_da_matriz[indice * colunas])
		equipamento.focus_neighbor_left = equipamento.get_path_to(equipamento)
	var primeiro_equipamento: SlotInventario = _slots_de_equipamento[0]
	primeiro_equipamento.focus_neighbor_top = primeiro_equipamento.get_path_to(primeiro_equipamento)
	# A lixeira fica embaixo dos espaços de equipamento, à esquerda da barra rápida.
	var ultimo_slot_de_equipamento: SlotInventario = _slots_de_equipamento[ultimo_equipamento]
	ultimo_slot_de_equipamento.focus_neighbor_bottom = ultimo_slot_de_equipamento.get_path_to(lixeira)
	lixeira.focus_neighbor_top = lixeira.get_path_to(ultimo_slot_de_equipamento)
	lixeira.focus_neighbor_right = lixeira.get_path_to(_slots_rapidos[0])
	lixeira.focus_neighbor_left = lixeira.get_path_to(lixeira)
	lixeira.focus_neighbor_bottom = lixeira.get_path_to(lixeira)
	var primeiro_rapido: SlotInventario = _slots_rapidos[0]
	primeiro_rapido.focus_neighbor_left = primeiro_rapido.get_path_to(lixeira)

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
			_mostrar_dica_do_cartao()
		return
	if _slot_segurado != slot:
		SlotInventario.transferir(_slot_segurado.indice_mostrado(), -1, slot)
	_cancelar_pega()

## Joga fora, para sempre, tudo que está no slot. Item-chave, ferramenta e arma não vão:
## o jogador não pode perder por engano o que não tem como conseguir de novo. O motivo
## aparece no cartão, porque os avisos da tela ficam escondidos com o menu aberto.
func _descartar(indice: int) -> void:
	var pilha: PilhaDeItens = InventoryManager.slot_em(indice)
	if pilha == null or pilha.esta_vazia():
		return
	if not pilha.item.pode_ser_descartado():
		_mostrar_mensagem(pilha.item.nome, "Isso não pode ser jogado fora.", pilha.item.icone)
		return
	var nome: String = pilha.item.nome
	var quantidade: int = pilha.quantidade
	InventoryManager.remover_do_slot(indice, quantidade)
	_mostrar_mensagem("Lixeira", "%s (%d) jogado fora." % [nome, quantidade], lixeira.get_node("Icone").texture)

## Pelo controle: com um item seguro, confirmar na lixeira joga ele fora.
func _ao_acionar_lixeira() -> void:
	if _slot_segurado == null:
		return
	var indice: int = _slot_segurado.indice_mostrado()
	_cancelar_pega()
	_descartar(indice)

func _ao_focar_lixeira() -> void:
	_slot_focado = null
	_mostrar_mensagem("Lixeira", "O que for solto aqui é apagado para sempre.", lixeira.get_node("Icone").texture)

func _cancelar_pega() -> void:
	if _slot_segurado != null:
		_slot_segurado.segurando = false
	_slot_segurado = null
	_mostrar_dica_do_cartao()

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
	# O item em uso aparece em ouro na barra rápida do menu, como na barra da tela.
	for slot in _slots_rapidos:
		slot.selecionado = slot.indice_do_slot == EquipmentManager.indice_selecionado
	var ocupados: int = 0
	for pilha in InventoryManager.slots:
		if pilha != null and not pilha.esta_vazia():
			ocupados += 1
	ocupacao.text = "%d / %d" % [ocupados, InventoryManager.TOTAL_DE_SLOTS]
	ocupacao.add_theme_color_override(&"font_color", CoresDaInterface.ambar() if InventoryManager.esta_cheio() else CoresDaInterface.ouro())
	if _slot_focado != null:
		_mostrar_descricao(_slot_focado)
	_mostrar_dica_do_cartao()

# Cartão do item focado

func _mostrar_descricao(slot: SlotInventario) -> void:
	var pilha: PilhaDeItens = slot.pilha_mostrada()
	if pilha == null or pilha.esta_vazia():
		var titulo: String = "%s (vazio)" % _nomes_dos_espacos[slot.espaco_de_equipamento] if slot.eh_espaco_de_equipamento() else ""
		_mostrar_mensagem(titulo, "", null)
		return
	var item: Item = pilha.item
	icone_grande.texture = item.icone
	nome_do_item.text = item.nome
	var etiqueta: Array = ETIQUETAS_DAS_CATEGORIAS.get(item.categoria, ["", &"texto_apagado"])
	categoria_do_item.text = etiqueta[0]
	categoria_do_item.add_theme_color_override(&"font_color", CoresDaInterface.cor(etiqueta[1]))
	descricao_do_item.text = item.descricao
	_esvaziar_efeitos()
	# Arma e ferramenta mostram o nível e o que ele dá.
	if UpgradeManager.pode_ser_aprimorado(item):
		var nivel: int = UpgradeManager.nivel_de(item)
		_novo_efeito("Nível %d" % nivel, UpgradeManager.descricao_do_nivel(item, nivel), CoresDaInterface.ciano())
	var consumivel: Consumivel = item as Consumivel
	if consumivel != null:
		if consumivel.recupera_vida > 0:
			_novo_efeito("Vida", "+%d" % consumivel.recupera_vida, CoresDaInterface.verde())
		if consumivel.recupera_stamina > 0:
			_novo_efeito("Stamina", "+%d" % consumivel.recupera_stamina, CoresDaInterface.ouro())
	if item.item_chave:
		_novo_efeito("Item-chave", "", CoresDaInterface.violeta())
	if item.pode_ser_vendido():
		_novo_efeito("Vende por", str(item.valor_de_venda), CoresDaInterface.ouro())
	else:
		_novo_efeito("Não se vende", "", CoresDaInterface.texto_apagado())

## Mostra um aviso no lugar do item (a lixeira, o que foi jogado fora, o slot vazio).
func _mostrar_mensagem(titulo: String, texto: String, icone: Texture2D) -> void:
	icone_grande.texture = icone
	nome_do_item.text = titulo
	categoria_do_item.text = ""
	descricao_do_item.text = texto
	_esvaziar_efeitos()

## Uma linha de efeito: o nome à esquerda e o valor à direita, na cor do que ele é.
func _novo_efeito(nome: String, valor: String, cor: Color) -> void:
	var linha: HBoxContainer = HBoxContainer.new()
	var rotulo: Label = Label.new()
	rotulo.text = nome
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo)
	var numero: Label = Label.new()
	numero.text = valor
	linha.add_child(numero)
	if valor == "":
		rotulo.add_theme_color_override(&"font_color", cor)
	else:
		rotulo.theme_type_variation = &"TextoApagado"
		numero.add_theme_color_override(&"font_color", cor)
	efeitos_do_item.add_child(linha)

func _esvaziar_efeitos() -> void:
	for filho in efeitos_do_item.get_children():
		efeitos_do_item.remove_child(filho)
		filho.queue_free()

## O que dá para fazer agora, com o nome da tecla do aparelho em uso.
func _mostrar_dica_do_cartao() -> void:
	if not is_node_ready():
		return
	var confirmar: String = InputManager.nome_da_tecla(&"ui_accept")
	if _slot_segurado != null:
		dica_do_cartao.text = "%s solta no slot focado. %s cancela." % [confirmar, InputManager.nome_da_tecla(&"ui_cancel")]
	elif InputManager.usando_teclado_e_mouse():
		dica_do_cartao.text = "Arraste com o mouse, ou %s pega e solta." % confirmar
	else:
		dica_do_cartao.text = "%s pega e solta." % confirmar
