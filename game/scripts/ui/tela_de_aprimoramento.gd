class_name TelaDeAprimoramento
extends Control

## A bancada do ferreiro: as armas e ferramentas do jogador de um lado, e do outro o que
## o próximo nível do item escolhido dá e o que ele custa, em materiais e em créditos.
##
## Abre em EventBus.forge_requested e pausa o jogo de verdade, como a loja, e por isso
## fica com process_mode ALWAYS. Quem sabe os níveis, as receitas e os custos é o
## UpgradeManager; esta tela só mostra e pede.
##
## A lista da esquerda é montada uma vez ao abrir, e os botões dela são atualizados no
## lugar quando algo muda. Refazer a lista apagaria o botão focado, e o controle perderia
## o lugar a cada aprimoramento. A coluna da direita não tem foco nenhum além do botão
## Aprimorar, que é fixo na cena, então ela pode ser refeita à vontade.

const TAMANHO_DO_ICONE: Vector2 = Vector2(32.0, 32.0)
const TAMANHO_DO_ICONE_DA_RECEITA: Vector2 = Vector2(24.0, 24.0)
const COR_DO_TEXTO: Color = Color(0.92, 0.95, 1.0)
const COR_DO_TEXTO_APAGADO: Color = Color(0.6, 0.66, 0.8)
const COR_DO_PROXIMO_NIVEL: Color = Color(0.3, 0.95, 1.0)
const COR_DE_QUEM_TEM: Color = Color(0.4, 1.0, 0.5)
const COR_DE_QUEM_FALTA: Color = Color(1.0, 0.4, 0.4)
const CAMINHO_DO_ICONE_DE_CREDITO: String = "res://assets/textures/icones_itens/credito.png"

@onready var titulo: Label = %Titulo
@onready var rotulo_do_saldo: Label = %Saldo
@onready var lista: VBoxContainer = %Lista
@onready var detalhes: VBoxContainer = %Detalhes
@onready var botao_aprimorar: Button = %BotaoAprimorar
@onready var mensagem: Label = %Mensagem
@onready var botao_fechar: Button = %BotaoFechar

## O botão de cada item da lista, para ser atualizado sem ser recriado.
var _botoes_por_item: Dictionary[Item, Button] = {}
var _item_escolhido: Item

func _ready() -> void:
	visible = false
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
	_mostrar_mensagem("", COR_DO_TEXTO_APAGADO)
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
	_item_escolhido = null
	if itens.is_empty():
		var vazio: Label = _novo_rotulo("Você não tem nada para aprimorar aqui.", 15, COR_DO_TEXTO_APAGADO)
		vazio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lista.add_child(vazio)
		return
	for item in itens:
		var botao: Button = Button.new()
		botao.icon = item.icone
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.custom_minimum_size = Vector2(0.0, TAMANHO_DO_ICONE.y + 12.0)
		botao.toggle_mode = true
		# Escolher é focar: no controle, andar pela lista já mostra o item do lado, sem
		# precisar confirmar em cada um.
		botao.focus_entered.connect(_escolher.bind(item))
		botao.pressed.connect(_escolher.bind(item))
		lista.add_child(botao)
		_botoes_por_item[item] = botao
	_item_escolhido = itens[0]

func _escolher(item: Item) -> void:
	if item == _item_escolhido:
		_marcar_o_escolhido()
		return
	_item_escolhido = item
	_mostrar_mensagem("", COR_DO_TEXTO_APAGADO)
	_atualizar_tudo()

func _aprimorar_o_escolhido() -> void:
	var item: Item = _item_escolhido
	if item == null:
		return
	if UpgradeManager.aprimorar(item):
		_mostrar_mensagem("%s agora é nível %d." % [item.nome, UpgradeManager.nivel_de(item)], COR_DE_QUEM_TEM)
	else:
		_mostrar_mensagem("Falta material ou crédito.", COR_DE_QUEM_FALTA)
	# O aprimorar já mexeu no inventário e no saldo, e os sinais deles atualizaram a tela.
	# Esta chamada garante o estado certo mesmo se a receita não gastar nada.
	_atualizar_tudo()

## O inventário ou o saldo mudaram. A tela só se refaz quando está aberta.
func _ao_mudar_algo() -> void:
	if visible:
		_atualizar_tudo()

func _atualizar_tudo() -> void:
	rotulo_do_saldo.text = "%d créditos" % EconomyManager.creditos
	for item: Item in _botoes_por_item:
		_botoes_por_item[item].text = "%s\n%s" % [item.nome, _texto_do_nivel(UpgradeManager.nivel_de(item))]
	_marcar_o_escolhido()
	_montar_detalhes()
	_ligar_vizinhos_de_foco()

func _marcar_o_escolhido() -> void:
	for item: Item in _botoes_por_item:
		_botoes_por_item[item].set_pressed_no_signal(item == _item_escolhido)

## Refaz a coluna da direita para o item escolhido: o que ele é agora, o que vira, e a
## receita com o que o jogador tem de cada coisa.
func _montar_detalhes() -> void:
	for filho in detalhes.get_children():
		filho.queue_free()
	var item: Item = _item_escolhido
	if item == null:
		_definir_botao_de_aprimorar(false, false)
		return
	var nivel: int = UpgradeManager.nivel_de(item)
	detalhes.add_child(_novo_rotulo(item.nome, 20, COR_DO_TEXTO))

	var receita: ReceitaDeAprimoramento = UpgradeManager.receita_para(item)
	if nivel >= UpgradeManager.NIVEL_MAXIMO or receita == null:
		detalhes.add_child(_novo_rotulo("Nível máximo", 15, COR_DO_PROXIMO_NIVEL))
		detalhes.add_child(_novo_rotulo(UpgradeManager.descricao_do_nivel(item, nivel), 15, COR_DO_TEXTO))
		_definir_botao_de_aprimorar(false, false)
		return

	detalhes.add_child(_novo_rotulo("Nível %d -> Nível %d" % [nivel, nivel + 1], 15, COR_DO_PROXIMO_NIVEL))
	detalhes.add_child(_novo_rotulo("Agora: %s" % UpgradeManager.descricao_do_nivel(item, nivel), 15, COR_DO_TEXTO_APAGADO))
	detalhes.add_child(_novo_rotulo("Depois: %s" % UpgradeManager.descricao_do_nivel(item, nivel + 1), 15, COR_DO_TEXTO))
	detalhes.add_child(HSeparator.new())
	detalhes.add_child(_novo_rotulo("Custa", 13, COR_DO_TEXTO_APAGADO))
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

## Uma linha da receita: o ícone, o nome e "tem X de Y", em verde quando o jogador tem o
## bastante e em vermelho quando falta.
func _nova_linha_de_custo(textura: Texture2D, nome: String, tem: int, pedido: int) -> HBoxContainer:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 10)
	var icone: TextureRect = TextureRect.new()
	icone.texture = textura
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.custom_minimum_size = TAMANHO_DO_ICONE_DA_RECEITA
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	linha.add_child(icone)
	var rotulo_do_nome: Label = _novo_rotulo(nome, 15, COR_DO_TEXTO)
	rotulo_do_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo_do_nome)
	linha.add_child(_novo_rotulo("tem %d de %d" % [tem, pedido], 15, COR_DE_QUEM_TEM if tem >= pedido else COR_DE_QUEM_FALTA))
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
	for item: Item in _botoes_por_item:
		var botao: Button = _botoes_por_item[item]
		botao.focus_neighbor_right = botao.get_path_to(da_direita)
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

func _texto_do_nivel(nivel: int) -> String:
	return "Nível máximo" if nivel >= UpgradeManager.NIVEL_MAXIMO else "Nível %d" % nivel

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
