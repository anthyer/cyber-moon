class_name TelaDeLoja
extends Control

## A loja de um comerciante: a lista do que ele vende, com o preço, e os botões de comprar.
##
## Abre quando o jogador conversa com um NPC que tem catálogo e está com a loja aberta
## (EventBus.shop_requested). Pausa o jogo de verdade, como o calendário, e por isso fica
## com process_mode ALWAYS. Aqui só se compra: vender é pelo baú de venda da fazenda.
##
## A lista é montada uma vez ao abrir. Quando o saldo ou o inventário mudam, as linhas
## que já existem são atualizadas no lugar, em vez de a lista ser refeita: refazer
## apagaria o botão focado, e o controle perderia o lugar a cada compra.

const QUANTIDADES_DE_COMPRA: Array[int] = [1, 5]
const TAMANHO_DO_ICONE: Vector2 = Vector2(32.0, 32.0)
const COR_DO_TEXTO: Color = Color(0.92, 0.95, 1.0)
const COR_DO_TEXTO_APAGADO: Color = Color(0.6, 0.66, 0.8)
const COR_DO_PRECO: Color = Color(1.0, 0.85, 0.35)
const COR_DA_RECUSA: Color = Color(1.0, 0.4, 0.4)
const COR_DA_COMPRA: Color = Color(0.4, 1.0, 0.5)

@onready var titulo: Label = %Titulo
@onready var rotulo_do_saldo: Label = %Saldo
@onready var lista: VBoxContainer = %Lista
@onready var descricao: Label = %Descricao
@onready var mensagem: Label = %Mensagem
@onready var botao_fechar: Button = %BotaoFechar

## O que cada linha precisa para ser atualizada sem ser recriada.
class LinhaDeItem:
	var item: Item
	var rotulo_de_posse: Label
	var rotulo_de_preco: Label
	## Um botão por quantidade de QUANTIDADES_DE_COMPRA, na mesma ordem.
	var botoes: Array[Button] = []

var _linhas: Array[LinhaDeItem] = []

func _ready() -> void:
	visible = false
	botao_fechar.pressed.connect(fechar)
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
	descricao.text = ""
	_mostrar_mensagem("", COR_DO_TEXTO_APAGADO)
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

func _montar_lista(itens: Array[Item]) -> void:
	for filho in lista.get_children():
		filho.queue_free()
	_linhas.clear()
	if itens.is_empty():
		var vazio: Label = _novo_rotulo("Nada à venda por enquanto.", 15, COR_DO_TEXTO_APAGADO)
		lista.add_child(vazio)
		return
	for item in itens:
		_linhas.append(_nova_linha(item))
	_atualizar_linhas()

func _nova_linha(item: Item) -> LinhaDeItem:
	var linha: LinhaDeItem = LinhaDeItem.new()
	linha.item = item

	var caixa: HBoxContainer = HBoxContainer.new()
	caixa.add_theme_constant_override(&"separation", 12)
	# A linha inteira responde ao mouse, para a descrição aparecer ao passar por ela e
	# não só em cima dos botões.
	caixa.mouse_filter = Control.MOUSE_FILTER_PASS
	caixa.mouse_entered.connect(_mostrar_descricao.bind(item))
	lista.add_child(caixa)

	var icone: TextureRect = TextureRect.new()
	icone.texture = item.icone
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.custom_minimum_size = TAMANHO_DO_ICONE
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(icone)

	var nomes: VBoxContainer = VBoxContainer.new()
	nomes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nomes.add_theme_constant_override(&"separation", 0)
	nomes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(nomes)
	nomes.add_child(_novo_rotulo(item.nome, 16, COR_DO_TEXTO))
	linha.rotulo_de_posse = _novo_rotulo("", 12, COR_DO_TEXTO_APAGADO)
	nomes.add_child(linha.rotulo_de_posse)

	linha.rotulo_de_preco = _novo_rotulo("", 16, COR_DO_PRECO)
	linha.rotulo_de_preco.custom_minimum_size = Vector2(64.0, 0.0)
	linha.rotulo_de_preco.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	linha.rotulo_de_preco.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caixa.add_child(linha.rotulo_de_preco)

	for quantidade in QUANTIDADES_DE_COMPRA:
		var botao: Button = Button.new()
		botao.text = "Comprar %d" % quantidade
		botao.pressed.connect(_comprar.bind(item, quantidade))
		botao.focus_entered.connect(_mostrar_descricao.bind(item))
		botao.mouse_entered.connect(_mostrar_descricao.bind(item))
		caixa.add_child(botao)
		linha.botoes.append(botao)
	return linha

func _comprar(item: Item, quantidade: int) -> void:
	if EconomyManager.comprar(item, quantidade):
		_mostrar_mensagem("Comprou %d de %s." % [quantidade, item.nome], COR_DA_COMPRA)
	else:
		_mostrar_mensagem(EconomyManager.ultimo_motivo_de_recusa, COR_DA_RECUSA)

func _ao_mudar_saldo(saldo: int) -> void:
	rotulo_do_saldo.text = "%d créditos" % saldo
	_atualizar_linhas()

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
		linha.rotulo_de_posse.text = "Você tem %d" % InventoryManager.obter_quantidade(linha.item)
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

func _mostrar_descricao(item: Item) -> void:
	descricao.text = item.descricao if item.descricao != "" else item.nome

func _mostrar_mensagem(texto: String, cor: Color) -> void:
	mensagem.text = texto
	mensagem.add_theme_color_override(&"font_color", cor)

func _novo_rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override(&"font_size", tamanho)
	rotulo.add_theme_color_override(&"font_color", cor)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo
