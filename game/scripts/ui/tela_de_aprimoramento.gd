class_name TelaDeAprimoramento
extends Control

## A bancada do ferreiro: as armas e ferramentas do jogador de um lado, e do outro o que
## o próximo nível do item escolhido dá e o que ele custa, em materiais e em créditos.
##
## Abre em EventBus.forge_requested e pausa o jogo de verdade, como a loja, e por isso
## fica com process_mode ALWAYS. Quem sabe os níveis, as receitas e os custos é o
## UpgradeManager; esta tela só mostra e pede.
##
## O visual segue o mock da bancada: as armas e ferramentas numa grade de slots à
## esquerda, com o nível no canto; à direita, o nível atual e o próximo lado a lado, o
## próximo aceso em ciano; embaixo, os materiais com "tem / precisa", em verde quando
## tem e em âmbar quando falta.
##
## A lista da esquerda é montada uma vez ao abrir, e os botões dela são atualizados no
## lugar quando algo muda. Refazer a lista apagaria o botão focado, e o controle perderia
## o lugar a cada aprimoramento. A coluna da direita não tem foco nenhum, e o botão
## Aprimorar é fixo na cena, então ela pode ser refeita à vontade.

const TAMANHO_DO_SLOT: Vector2 = Vector2(64.0, 64.0)
## O espaço entre a borda do slot e o ícone.
const MARGEM_DO_ICONE_NO_SLOT: float = 8.0
## O "Nv 2" do canto do slot é menor que o texto corrido, para não cobrir o ícone.
const TAMANHO_DO_NIVEL_NO_SLOT: int = 16
const TAMANHO_DO_ICONE_DO_CARTAO: Vector2 = Vector2(64.0, 64.0)
const TAMANHO_DO_ICONE_DA_RECEITA: Vector2 = Vector2(24.0, 24.0)
const CAMINHO_DO_ICONE_DE_CREDITO: String = "res://assets/textures/icones_itens/credito.png"

@onready var titulo: Label = %Titulo
@onready var rotulo_do_saldo: Label = %Saldo
@onready var lista: GridContainer = %Lista
@onready var linhas_do_agora: VBoxContainer = %LinhasDoAgora
@onready var linhas_do_proximo: VBoxContainer = %LinhasDoProximo
@onready var seta: Label = %Seta
@onready var detalhes: VBoxContainer = %Detalhes
@onready var botao_aprimorar: Button = %BotaoAprimorar
@onready var mensagem: Label = %Mensagem
@onready var botao_fechar: Button = %BotaoFechar

## O botão de cada item da lista, para ser atualizado sem ser recriado.
var _botoes_por_item: Dictionary[Item, Button] = {}
## O "Nv 2" no canto de cada slot, para ser atualizado junto com o botão.
var _niveis_por_item: Dictionary[Item, Label] = {}
var _item_escolhido: Item

func _ready() -> void:
	visible = false
	rotulo_do_saldo.add_theme_color_override(&"font_color", CoresDaInterface.ouro())
	seta.add_theme_color_override(&"font_color", CoresDaInterface.ciano())
	botao_fechar.pressed.connect(fechar)
	botao_aprimorar.pressed.connect(_aprimorar_o_escolhido)
	EventBus.forge_requested.connect(abrir)
	EconomyManager.credits_changed.connect(_ao_mudar_algo.unbind(1))
	InventoryManager.inventory_changed.connect(_ao_mudar_algo)

## Este nó precisa vir depois do MenuPausa na cena, pelo mesmo motivo do calendário: no
## quadro em que o Esc ou a tecla de inventário fecham a bancada, o MenuPausa já rodou,
## viu o jogo pausado e não abriu por cima.
func _process(_delta: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(&"ui_cancel") or InputManager.abrir_inventario_pressionado():
		fechar()

## Abre a bancada do ferreiro. Não abre por cima de outra tela que já pausou o jogo.
func abrir(perfil: PerfilNpc) -> void:
	if visible or get_tree().paused or perfil == null:
		return
	titulo.text = "Bancada de %s" % perfil.nome_exibido
	_mostrar_mensagem("", CoresDaInterface.texto_apagado())
	_montar_lista(UpgradeManager.itens_aprimoraveis_do_jogador())
	visible = true
	get_tree().paused = true
	_atualizar_tudo()
	_focar_o_escolhido.call_deferred()

func fechar() -> void:
	if not visible:
		return
	get_viewport().gui_release_focus()
	visible = false
	get_tree().paused = false
	_item_escolhido = null

func _montar_lista(itens: Array[Item]) -> void:
	for filho in lista.get_children():
		filho.queue_free()
	_botoes_por_item.clear()
	_niveis_por_item.clear()
	_item_escolhido = null
	if itens.is_empty():
		var vazio: Label = _novo_rotulo("Você não tem nada para aprimorar aqui.", CoresDaInterface.texto_apagado())
		vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vazio.custom_minimum_size = Vector2(200.0, 0.0)
		lista.add_child(vazio)
		return
	for item in itens:
		var botao: Button = _novo_slot(item)
		# Escolher é focar: no controle, andar pela lista já mostra o item do lado, sem
		# precisar confirmar em cada um.
		botao.focus_entered.connect(_escolher.bind(item))
		botao.pressed.connect(_escolher.bind(item))
		lista.add_child(botao)
		_botoes_por_item[item] = botao
	_item_escolhido = itens[0]

## Um botão com cara de slot do inventário: as caixas do Theme (SlotNormal, e SlotFocado
## para o escolhido e o que está sob o mouse), o ícone no meio e o nível no canto.
func _novo_slot(item: Item) -> Button:
	var botao: Button = Button.new()
	botao.icon = item.icone
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.custom_minimum_size = TAMANHO_DO_SLOT
	botao.tooltip_text = item.nome
	botao.toggle_mode = true
	var normal: StyleBox = _caixa_de_slot(&"SlotNormal")
	var aceso: StyleBox = _caixa_de_slot(&"SlotFocado")
	botao.add_theme_stylebox_override(&"normal", normal)
	botao.add_theme_stylebox_override(&"hover", aceso)
	botao.add_theme_stylebox_override(&"pressed", aceso)
	botao.add_theme_stylebox_override(&"hover_pressed", aceso)
	# Escolher é focar, então o slot escolhido já mostra o foco em ciano; o anel de foco
	# do botão comum ficaria por cima do slot.
	botao.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	var nivel: Label = _novo_rotulo("", CoresDaInterface.ciano())
	nivel.add_theme_font_size_override(&"font_size", TAMANHO_DO_NIVEL_NO_SLOT)
	nivel.position = Vector2(5.0, TAMANHO_DO_SLOT.y - TAMANHO_DO_NIVEL_NO_SLOT - 4.0)
	botao.add_child(nivel)
	_niveis_por_item[item] = nivel
	return botao

func _caixa_de_slot(variacao: StringName) -> StyleBox:
	var caixa: StyleBox = get_theme_stylebox(&"panel", variacao).duplicate() as StyleBox
	caixa.content_margin_left = MARGEM_DO_ICONE_NO_SLOT
	caixa.content_margin_right = MARGEM_DO_ICONE_NO_SLOT
	caixa.content_margin_top = MARGEM_DO_ICONE_NO_SLOT
	caixa.content_margin_bottom = MARGEM_DO_ICONE_NO_SLOT
	return caixa

func _escolher(item: Item) -> void:
	if item == _item_escolhido:
		_marcar_o_escolhido()
		return
	_item_escolhido = item
	_mostrar_mensagem("", CoresDaInterface.texto_apagado())
	_atualizar_tudo()

func _aprimorar_o_escolhido() -> void:
	var item: Item = _item_escolhido
	if item == null:
		return
	if UpgradeManager.aprimorar(item):
		_mostrar_mensagem("%s agora é nível %d." % [item.nome, UpgradeManager.nivel_de(item)], CoresDaInterface.verde())
	else:
		_mostrar_mensagem("Falta material ou crédito.", CoresDaInterface.ambar())
	# O aprimorar já mexeu no inventário e no saldo, e os sinais deles atualizaram a tela.
	# Esta chamada garante o estado certo mesmo se a receita não gastar nada.
	_atualizar_tudo()

## O inventário ou o saldo mudaram. A tela só se refaz quando está aberta.
func _ao_mudar_algo() -> void:
	if visible:
		_atualizar_tudo()

func _atualizar_tudo() -> void:
	rotulo_do_saldo.text = str(EconomyManager.creditos)
	for item: Item in _niveis_por_item:
		_niveis_por_item[item].text = "Nv%d" % UpgradeManager.nivel_de(item)
	_marcar_o_escolhido()
	_montar_detalhes()
	_ligar_vizinhos_de_foco()

func _marcar_o_escolhido() -> void:
	for item: Item in _botoes_por_item:
		_botoes_por_item[item].set_pressed_no_signal(item == _item_escolhido)

## Refaz a coluna da direita para o item escolhido: o cartão de agora, o do próximo
## nível, e a receita com o que o jogador tem de cada coisa.
func _montar_detalhes() -> void:
	for pai: Control in [linhas_do_agora, linhas_do_proximo, detalhes]:
		for filho in pai.get_children():
			filho.queue_free()
	var item: Item = _item_escolhido
	if item == null:
		_definir_botao_de_aprimorar(false, false)
		return
	var nivel: int = UpgradeManager.nivel_de(item)
	_montar_cartao(linhas_do_agora, item, "Agora", nivel, CoresDaInterface.texto_apagado(), CoresDaInterface.texto())

	var receita: ReceitaDeAprimoramento = UpgradeManager.receita_para(item)
	if nivel >= UpgradeManager.NIVEL_MAXIMO or receita == null:
		linhas_do_proximo.add_child(_rotulo_centrado("Nível máximo", CoresDaInterface.ciano()))
		linhas_do_proximo.add_child(_rotulo_centrado("Não há o que aprimorar.", CoresDaInterface.texto_apagado()))
		_definir_botao_de_aprimorar(false, false)
		return

	_montar_cartao(linhas_do_proximo, item, "Próximo", nivel + 1, CoresDaInterface.ciano(), CoresDaInterface.ciano())
	detalhes.add_child(_novo_rotulo("Precisa de", CoresDaInterface.texto_apagado()))
	for indice in receita.materiais.size():
		# "material" é nome de propriedade do Control, por isso a variável tem outro nome.
		var ingrediente: Item = receita.materiais[indice]
		var pedido: int = receita.quantidades[indice] if indice < receita.quantidades.size() else 1
		detalhes.add_child(_nova_linha_de_custo(ingrediente.icone, ingrediente.nome, InventoryManager.obter_quantidade(ingrediente), pedido))
	var creditos: int = UpgradeManager.creditos_para(item)
	if creditos > 0:
		var icone_de_credito: Texture2D = load(CAMINHO_DO_ICONE_DE_CREDITO) as Texture2D if ResourceLoader.exists(CAMINHO_DO_ICONE_DE_CREDITO) else null
		detalhes.add_child(_nova_linha_de_custo(icone_de_credito, "Créditos", EconomyManager.creditos, creditos))
	_definir_botao_de_aprimorar(true, UpgradeManager.pode_aprimorar(item))

## Um dos dois cartões lado a lado: o título ("Agora" ou "Próximo"), o ícone grande, o
## nome com o nível e o que o nível dá. No cartão do próximo nível, tudo em ciano.
func _montar_cartao(pai: VBoxContainer, item: Item, cabecalho: String, nivel: int, cor_do_cabecalho: Color, cor_do_texto: Color) -> void:
	pai.add_child(_rotulo_centrado(cabecalho, cor_do_cabecalho))
	var icone: TextureRect = _novo_icone(item.icone, TAMANHO_DO_ICONE_DO_CARTAO)
	icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pai.add_child(icone)
	var nome: Label = _rotulo_centrado("%s Nv %d" % [item.nome, nivel], cor_do_texto)
	nome.theme_type_variation = &"Titulo"
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pai.add_child(nome)
	pai.add_child(_rotulo_centrado(UpgradeManager.descricao_do_nivel(item, nivel), cor_do_texto))

## Uma linha da receita: o ícone, o nome e "tem / precisa", em verde quando o jogador tem
## o bastante e em âmbar, com o quanto falta, quando não tem.
func _nova_linha_de_custo(textura: Texture2D, nome: String, tem: int, pedido: int) -> HBoxContainer:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 10)
	linha.add_child(_novo_icone(textura, TAMANHO_DO_ICONE_DA_RECEITA))
	var rotulo_do_nome: Label = _novo_rotulo(nome, CoresDaInterface.texto())
	rotulo_do_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo_do_nome)
	if tem >= pedido:
		linha.add_child(_novo_rotulo("%d / %d" % [tem, pedido], CoresDaInterface.verde()))
	else:
		linha.add_child(_novo_rotulo("%d / %d, falta %d" % [tem, pedido, pedido - tem], CoresDaInterface.ambar()))
	return linha

## O botão Aprimorar some no nível máximo e fica desabilitado quando falta algo. Botão
## desabilitado não segura foco: se era ele que tinha, o foco volta para o item da lista.
func _definir_botao_de_aprimorar(aparece: bool, habilitado: bool) -> void:
	var tinha_o_foco: bool = botao_aprimorar.has_focus()
	botao_aprimorar.visible = aparece
	botao_aprimorar.disabled = not habilitado
	if tinha_o_foco and (not aparece or not habilitado):
		_focar_o_escolhido()

## Da lista, a seta para a direita vai ao botão Aprimorar (ou ao Fechar, quando não dá
## para aprimorar), e de lá a seta para a esquerda volta ao item escolhido. O vizinho
## automático do Godot erra aqui, porque as duas colunas têm alturas bem diferentes.
func _ligar_vizinhos_de_foco() -> void:
	var da_direita: Button = botao_aprimorar if botao_aprimorar.visible and not botao_aprimorar.disabled else botao_fechar
	var botoes: Array[Button] = []
	botoes.assign(_botoes_por_item.values())
	for indice in botoes.size():
		# Na grade, só o slot da última coluna (ou o último da lista) sai para a direita;
		# os outros andam para o slot ao lado, pelo vizinho automático.
		var na_ultima_coluna: bool = indice % lista.columns == lista.columns - 1 or indice == botoes.size() - 1
		if na_ultima_coluna:
			botoes[indice].focus_neighbor_right = botoes[indice].get_path_to(da_direita)
	var escolhido: Button = _botoes_por_item.get(_item_escolhido, null)
	if escolhido != null:
		botao_aprimorar.focus_neighbor_left = botao_aprimorar.get_path_to(escolhido)
		botao_fechar.focus_neighbor_left = botao_fechar.get_path_to(escolhido)
	botao_aprimorar.focus_neighbor_bottom = botao_aprimorar.get_path_to(botao_fechar)
	if da_direita != botao_fechar:
		botao_fechar.focus_neighbor_top = botao_fechar.get_path_to(da_direita)

func _focar_o_escolhido() -> void:
	var escolhido: Button = _botoes_por_item.get(_item_escolhido, null)
	if escolhido != null:
		escolhido.grab_focus()
	else:
		botao_fechar.grab_focus()

func _mostrar_mensagem(texto: String, cor: Color) -> void:
	mensagem.text = texto
	mensagem.add_theme_color_override(&"font_color", cor)

func _novo_rotulo(texto: String, cor: Color) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_color_override(&"font_color", cor)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo

func _rotulo_centrado(texto: String, cor: Color) -> Label:
	var rotulo: Label = _novo_rotulo(texto, cor)
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return rotulo

func _novo_icone(textura: Texture2D, tamanho: Vector2) -> TextureRect:
	var icone: TextureRect = TextureRect.new()
	icone.texture = textura
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.custom_minimum_size = tamanho
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icone
