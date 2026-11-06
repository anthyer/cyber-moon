class_name TelaDeLoja
extends Control

## A loja de um comerciante: a lista do que ele vende, com o preço, e os botões de comprar.
##
## Abre quando o jogador conversa com um NPC que tem catálogo e está com a loja aberta
## (EventBus.shop_requested). Pausa o jogo de verdade, como o calendário, e por isso fica
## com process_mode ALWAYS. Aqui só se compra: vender é pelo baú de venda da fazenda.
##
## O visual segue o mock de serviços e loja: o comerciante em pé à esquerda, num palco de
## modelo, e a loja à direita, com as abas Comprar e Vender, o preço em ouro, o cartão do
## item em foco e o saldo depois da compra. O que não dá para pagar fica apagado. A aba
## Vender só explica o baú de venda, porque vender continua sendo pelo baú.
##
## A lista é montada uma vez ao abrir. Quando o saldo ou o inventário mudam, as linhas
## que já existem são atualizadas no lugar, em vez de a lista ser refeita: refazer
## apagaria o botão focado, e o controle perderia o lugar a cada compra.

const QUANTIDADES_DE_COMPRA: Array[int] = [1, 5]
const TAMANHO_DO_ICONE: Vector2 = Vector2(32.0, 32.0)
const ABA_COMPRAR: int = 0
## A linha em foco é o painel ciano do Theme com a margem de dentro menor; as outras têm
## a mesma margem sem painel, para a lista não pular quando o foco anda.
const MARGEM_DA_LINHA: Vector2 = Vector2(8.0, 4.0)
## O ícone de quem não dá para pagar fica meio transparente, junto com o texto apagado.
const OPACIDADE_DO_ICONE_APAGADO: float = 0.4

@onready var palco_do_lojista: ModelStage = %PalcoDoLojista
@onready var nome_do_lojista: Label = %NomeDoLojista
@onready var titulo: Label = %Titulo
@onready var rotulo_do_saldo: Label = %Saldo
@onready var abas: TabBar = %Abas
@onready var rolagem: ScrollContainer = %Rolagem
@onready var lista: VBoxContainer = %Lista
@onready var como_vender: Label = %ComoVender
@onready var cartao: PanelContainer = %Cartao
@onready var icone_do_cartao: TextureRect = %IconeDoCartao
@onready var nome_do_cartao: Label = %NomeDoCartao
@onready var descricao: Label = %Descricao
@onready var depois_da_compra: Label = %DepoisDaCompra
@onready var mensagem: Label = %Mensagem
@onready var botao_fechar: Button = %BotaoFechar

## O que cada linha precisa para ser atualizada sem ser recriada.
class LinhaDeItem:
	var item: Item
	var painel: PanelContainer
	var icone: TextureRect
	var rotulo_do_nome: Label
	var rotulo_de_posse: Label
	var rotulo_de_preco: Label
	## Um botão por quantidade de QUANTIDADES_DE_COMPRA, na mesma ordem.
	var botoes: Array[Button] = []

var _linhas: Array[LinhaDeItem] = []
## O item do cartão e a quantidade do botão em foco, para o saldo depois da compra.
var _item_do_cartao: Item
var _quantidade_do_cartao: int = 1
var _estilo_da_linha_em_foco: StyleBox
var _estilo_da_linha: StyleBox

func _ready() -> void:
	visible = false
	_estilo_da_linha_em_foco = _estilo_com_margem(get_theme_stylebox(&"panel", &"PainelCiano").duplicate() as StyleBox)
	_estilo_da_linha = _estilo_com_margem(StyleBoxEmpty.new())
	rotulo_do_saldo.add_theme_color_override(&"font_color", CoresDaInterface.ouro())
	botao_fechar.pressed.connect(fechar)
	abas.tab_changed.connect(_ao_trocar_de_aba)
	EventBus.shop_requested.connect(abrir)
	EconomyManager.credits_changed.connect(_ao_mudar_saldo)
	InventoryManager.inventory_changed.connect(_atualizar_linhas)

## Este nó precisa vir depois do MenuPausa na cena, pelo mesmo motivo do calendário: no
## quadro em que o Esc ou a tecla de inventário fecham a loja, o MenuPausa já rodou, viu o
## jogo pausado e não abriu por cima.
func _process(_delta: float) -> void:
	if not visible:
		return
	if Input.is_action_just_pressed(&"ui_cancel") or InputManager.abrir_inventario_pressionado():
		fechar()

## Abre a loja do comerciante. Não abre por cima de outra tela que já pausou o jogo, nem
## para quem não tem catálogo.
func abrir(perfil: PerfilNpc) -> void:
	if visible or get_tree().paused or perfil == null or perfil.catalogo == null:
		return
	titulo.text = "Loja de %s" % perfil.nome_exibido
	nome_do_lojista.text = perfil.nome_exibido
	palco_do_lojista.mostrar_cena(perfil.modelo)
	abas.current_tab = ABA_COMPRAR
	_ao_trocar_de_aba(ABA_COMPRAR)
	_mostrar_no_cartao(null, 1)
	_mostrar_mensagem("", CoresDaInterface.texto_apagado())
	_montar_lista(perfil.catalogo.itens_disponiveis())
	_ao_mudar_saldo(EconomyManager.creditos)
	visible = true
	get_tree().paused = true
	_focar_primeiro_botao.call_deferred()

func fechar() -> void:
	if not visible:
		return
	get_viewport().gui_release_focus()
	visible = false
	get_tree().paused = false
	palco_do_lojista.limpar()

func _montar_lista(itens: Array[Item]) -> void:
	for filho in lista.get_children():
		filho.queue_free()
	_linhas.clear()
	if itens.is_empty():
		var vazio: Label = _novo_rotulo("Nada à venda por enquanto.", CoresDaInterface.texto_apagado())
		lista.add_child(vazio)
		return
	for item in itens:
		_linhas.append(_nova_linha(item))
	_atualizar_linhas()

func _nova_linha(item: Item) -> LinhaDeItem:
	var linha: LinhaDeItem = LinhaDeItem.new()
	linha.item = item

	linha.painel = PanelContainer.new()
	linha.painel.add_theme_stylebox_override(&"panel", _estilo_da_linha)
	# A linha inteira responde ao mouse, para o cartão mostrar o item ao passar por ela e
	# não só em cima dos botões.
	linha.painel.mouse_filter = Control.MOUSE_FILTER_PASS
	linha.painel.mouse_entered.connect(_mostrar_no_cartao.bind(item, 1))
	lista.add_child(linha.painel)

	var caixa: HBoxContainer = HBoxContainer.new()
	caixa.add_theme_constant_override(&"separation", 12)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.painel.add_child(caixa)

	var icone: TextureRect = TextureRect.new()
	linha.icone = icone
	icone.texture = item.icone
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.custom_minimum_size = TAMANHO_DO_ICONE
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(icone)

	linha.rotulo_do_nome = _novo_rotulo(item.nome, CoresDaInterface.texto())
	linha.rotulo_do_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.rotulo_do_nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caixa.add_child(linha.rotulo_do_nome)
	linha.rotulo_de_posse = _novo_rotulo("", CoresDaInterface.texto_apagado())
	linha.rotulo_de_posse.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caixa.add_child(linha.rotulo_de_posse)

	linha.rotulo_de_preco = _novo_rotulo("", CoresDaInterface.ouro())
	linha.rotulo_de_preco.custom_minimum_size = Vector2(64.0, 0.0)
	linha.rotulo_de_preco.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	linha.rotulo_de_preco.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caixa.add_child(linha.rotulo_de_preco)

	for quantidade in QUANTIDADES_DE_COMPRA:
		var botao: Button = Button.new()
		botao.text = "Comprar %d" % quantidade
		botao.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		botao.pressed.connect(_comprar.bind(item, quantidade))
		botao.focus_entered.connect(_mostrar_no_cartao.bind(item, quantidade))
		botao.mouse_entered.connect(_mostrar_no_cartao.bind(item, quantidade))
		caixa.add_child(botao)
		linha.botoes.append(botao)
	return linha

func _comprar(item: Item, quantidade: int) -> void:
	if EconomyManager.comprar(item, quantidade):
		_mostrar_mensagem("Comprou %d de %s." % [quantidade, item.nome], CoresDaInterface.verde())
	else:
		_mostrar_mensagem(EconomyManager.ultimo_motivo_de_recusa, CoresDaInterface.ambar())

func _ao_mudar_saldo(saldo: int) -> void:
	rotulo_do_saldo.text = str(saldo)
	_atualizar_linhas()
	_atualizar_depois_da_compra()

## Relê o preço, a quantidade que o jogador tem e o que dá para pagar. Um botão que
## deixa de valer fica desabilitado; se era ele que tinha o foco, o foco vai para outro
## botão habilitado, para o controle não ficar preso num botão morto.
func _atualizar_linhas() -> void:
	if _linhas.is_empty():
		return
	var foco_perdido: bool = false
	for linha in _linhas:
		var preco: int = EconomyManager.preco_de_compra(linha.item)
		linha.rotulo_de_preco.text = str(preco)
		linha.rotulo_de_posse.text = "tem %d" % InventoryManager.obter_quantidade(linha.item)
		_apagar_se_nao_da_para_pagar(linha, EconomyManager.pode_pagar(preco))
		for indice in linha.botoes.size():
			var botao: Button = linha.botoes[indice]
			var pode: bool = EconomyManager.pode_pagar(preco * QUANTIDADES_DE_COMPRA[indice])
			if not pode and botao.has_focus():
				foco_perdido = true
			botao.disabled = not pode
	if foco_perdido:
		_focar_primeiro_botao()

func _focar_primeiro_botao() -> void:
	for linha in _linhas:
		for botao in linha.botoes:
			if not botao.disabled:
				botao.grab_focus()
				return
	botao_fechar.grab_focus()

## O item que não dá para pagar nem uma unidade fica apagado: nome e preço na cor de
## desligado e o ícone meio transparente.
func _apagar_se_nao_da_para_pagar(linha: LinhaDeItem, da_para_pagar: bool) -> void:
	linha.rotulo_do_nome.add_theme_color_override(&"font_color", CoresDaInterface.texto() if da_para_pagar else CoresDaInterface.desligado())
	linha.rotulo_de_preco.add_theme_color_override(&"font_color", CoresDaInterface.ouro() if da_para_pagar else CoresDaInterface.desligado())
	linha.icone.modulate.a = 1.0 if da_para_pagar else OPACIDADE_DO_ICONE_APAGADO

## O cartão embaixo da lista: ícone grande, nome, descrição e o saldo depois de comprar a
## quantidade do botão em foco. A linha do item fica acesa em ciano.
func _mostrar_no_cartao(item: Item, quantidade: int) -> void:
	_item_do_cartao = item
	_quantidade_do_cartao = quantidade
	cartao.visible = item != null
	for linha in _linhas:
		linha.painel.add_theme_stylebox_override(&"panel", _estilo_da_linha_em_foco if linha.item == item else _estilo_da_linha)
	if item == null:
		return
	icone_do_cartao.texture = item.icone
	nome_do_cartao.text = item.nome
	descricao.text = item.descricao if item.descricao != "" else item.nome
	_atualizar_depois_da_compra()

## Quanto sobra depois de comprar, em ouro; quando não dá, quanto falta, em âmbar.
func _atualizar_depois_da_compra() -> void:
	if _item_do_cartao == null:
		depois_da_compra.text = ""
		return
	var sobra: int = EconomyManager.creditos - EconomyManager.preco_de_compra(_item_do_cartao) * _quantidade_do_cartao
	if sobra >= 0:
		depois_da_compra.text = "Depois da compra de %d: %d créditos" % [_quantidade_do_cartao, sobra]
		depois_da_compra.add_theme_color_override(&"font_color", CoresDaInterface.ouro())
	else:
		depois_da_compra.text = "Faltam %d créditos para comprar %d" % [-sobra, _quantidade_do_cartao]
		depois_da_compra.add_theme_color_override(&"font_color", CoresDaInterface.ambar())

## A aba Comprar mostra a lista e o cartão; a aba Vender, só a explicação do baú de venda.
func _ao_trocar_de_aba(aba: int) -> void:
	var comprando: bool = aba == ABA_COMPRAR
	rolagem.visible = comprando
	cartao.visible = comprando and _item_do_cartao != null
	como_vender.visible = not comprando

func _mostrar_mensagem(texto: String, cor: Color) -> void:
	mensagem.text = texto
	mensagem.add_theme_color_override(&"font_color", cor)

func _estilo_com_margem(estilo: StyleBox) -> StyleBox:
	estilo.content_margin_left = MARGEM_DA_LINHA.x
	estilo.content_margin_right = MARGEM_DA_LINHA.x
	estilo.content_margin_top = MARGEM_DA_LINHA.y
	estilo.content_margin_bottom = MARGEM_DA_LINHA.y
	return estilo

func _novo_rotulo(texto: String, cor: Color) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_color_override(&"font_color", cor)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo
