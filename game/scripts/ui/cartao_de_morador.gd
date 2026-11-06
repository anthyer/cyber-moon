class_name CartaoDeMorador
extends PanelContainer

## Um cartão da aba de relacionamentos: o modelo 3D do morador num palco pequeno, o nome,
## as duas marcas do dia (conversou hoje, presente dado nesta semana), os corações e o
## aniversário, que fica em rosa quando está perto. São duas linhas de texto, e não três
## como no mock, para os doze moradores caberem sem rolar.
##
## O palco fica em modo foto (uma imagem parada, sem custo por quadro) e só anima quando
## o cartão tem o foco. Com doze moradores na tela, doze palcos animando ao mesmo tempo
## custariam doze renderizações 3D por quadro.
##
## O cartão é montado por código, a partir do PerfilNpc, e só os textos mudam depois:
## o palco e o modelo são criados uma vez.

const CENA_DO_PALCO: PackedScene = preload("res://scenes/ui/palco_de_modelo.tscn")
const TAMANHO_DO_PALCO: Vector2 = Vector2(48.0, 52.0)
## O enquadramento do palco pequeno: só o corpo, um pouco de cima.
const CAMPO_DE_VISAO_DO_PALCO: float = 24.0
## Aniversário a esta distância ou menos aparece em rosa no cartão.
const DIAS_PARA_O_ANIVERSARIO_FICAR_PERTO: int = 7

var perfil: PerfilNpc

var _palco: ModelStage
var _nome: Label
var _conversou: Label
var _presente: Label
var _linha_de_baixo: Label
var _coracoes: FileiraDeCoracoes

## Cria o cartão de um morador. O palco nasce em modo foto.
static func novo(perfil_do_morador: PerfilNpc) -> CartaoDeMorador:
	var cartao: CartaoDeMorador = CartaoDeMorador.new()
	cartao.perfil = perfil_do_morador
	return cartao

func _ready() -> void:
	theme_type_variation = &"PainelNeutro"
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_montar()
	focus_entered.connect(_ao_ganhar_foco)
	focus_exited.connect(_ao_perder_foco)
	# Passar o mouse dá o foco, para o mouse e o controle acenderem o cartão do mesmo jeito.
	mouse_entered.connect(grab_focus)
	_palco.mostrar_cena(perfil.modelo)
	atualizar()
	# A aba ainda está escondida e o container não deu tamanho ao palco. Sem isso a foto
	# sairia no tamanho padrão do SubViewport, com o modelo minúsculo.
	_palco.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_palco.size = TAMANHO_DO_PALCO
	_fotografar()
	visibility_changed.connect(_ao_aparecer_pela_primeira_vez, CONNECT_ONE_SHOT)

## Relê os pontos, as marcas do dia e o aniversário. O modelo não muda.
func atualizar() -> void:
	_coracoes.mostrar(RelationshipManager.coracoes(perfil.id))

	var conversou: bool = DialogueManager.ja_conversou_hoje(perfil.id)
	_conversou.add_theme_color_override(&"font_color", CoresDaInterface.ciano() if conversou else CoresDaInterface.texto_apagado())
	_conversou.tooltip_text = "Já conversaram hoje." if conversou else "Ainda não conversaram hoje."
	var presenteou: bool = not RelationshipManager.pode_presentear(perfil.id)
	_presente.add_theme_color_override(&"font_color", CoresDaInterface.rosa() if presenteou else CoresDaInterface.texto_apagado())
	_presente.tooltip_text = "Presente desta semana já foi dado." if presenteou else "Ainda dá para presentear nesta semana."

	var partes: PackedStringArray = []
	if RelationshipManager.esta_namorando(perfil.id):
		partes.append("namorando")
	var faltam: int = dias_para_o_aniversario()
	if faltam == 0:
		partes.append("aniversário hoje")
	elif faltam <= DIAS_PARA_O_ANIVERSARIO_FICAR_PERTO:
		partes.append("aniversário em %d dias" % faltam if faltam > 1 else "aniversário amanhã")
	if partes.is_empty():
		_linha_de_baixo.text = "%s, dia %d" % [SeasonManager.nome_exibido(perfil.estacao_do_aniversario), perfil.dia_do_aniversario]
		_linha_de_baixo.add_theme_color_override(&"font_color", CoresDaInterface.texto_apagado())
	else:
		_linha_de_baixo.text = " . ".join(partes)
		_linha_de_baixo.add_theme_color_override(&"font_color", CoresDaInterface.rosa())

## Quantos dias do jogo faltam para o aniversário, de 0 (hoje) até um ano menos um dia.
func dias_para_o_aniversario() -> int:
	var dias_no_ano: int = SeasonManager.ESTACOES.size() * SeasonManager.DIAS_POR_ESTACAO
	var indice_do_aniversario: int = SeasonManager.ESTACOES.find(perfil.estacao_do_aniversario)
	var dia_do_aniversario: int = indice_do_aniversario * SeasonManager.DIAS_POR_ESTACAO + perfil.dia_do_aniversario
	var hoje: int = SeasonManager.indice_da_estacao() * SeasonManager.DIAS_POR_ESTACAO + SeasonManager.dia_da_estacao()
	return posmod(dia_do_aniversario - hoje, dias_no_ano)

func palco() -> ModelStage:
	return _palco

func _montar() -> void:
	var colunas: HBoxContainer = HBoxContainer.new()
	colunas.add_theme_constant_override(&"separation", 10)
	colunas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(colunas)

	_palco = CENA_DO_PALCO.instantiate() as ModelStage
	_palco.custom_minimum_size = TAMANHO_DO_PALCO
	_palco.campo_de_visao = CAMPO_DE_VISAO_DO_PALCO
	_palco.mostrar_brilho_do_chao = false
	colunas.add_child(_palco)

	var linhas: VBoxContainer = VBoxContainer.new()
	linhas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linhas.alignment = BoxContainer.ALIGNMENT_CENTER
	linhas.add_theme_constant_override(&"separation", 0)
	linhas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	colunas.add_child(linhas)

	var de_cima: HBoxContainer = HBoxContainer.new()
	de_cima.add_theme_constant_override(&"separation", 8)
	de_cima.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linhas.add_child(de_cima)
	_nome = Label.new()
	_nome.text = perfil.nome_exibido
	_nome.theme_type_variation = &"Titulo"
	_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	de_cima.add_child(_nome)
	_conversou = _nova_marca("conversou")
	de_cima.add_child(_conversou)
	_presente = _nova_marca("presente")
	de_cima.add_child(_presente)

	var de_baixo: HBoxContainer = HBoxContainer.new()
	de_baixo.add_theme_constant_override(&"separation", 12)
	de_baixo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linhas.add_child(de_baixo)
	_coracoes = FileiraDeCoracoes.new()
	_coracoes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	de_baixo.add_child(_coracoes)
	_linha_de_baixo = Label.new()
	_linha_de_baixo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_linha_de_baixo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_linha_de_baixo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	de_baixo.add_child(_linha_de_baixo)

func _nova_marca(texto: String) -> Label:
	var marca: Label = Label.new()
	marca.text = texto
	# O tooltip da marca precisa do mouse; o resto do cartão deixa o mouse passar.
	marca.mouse_filter = Control.MOUSE_FILTER_PASS
	return marca

func _ao_ganhar_foco() -> void:
	theme_type_variation = &"PainelCiano"
	_palco.voltar_a_animar()

func _ao_perder_foco() -> void:
	theme_type_variation = &"PainelNeutro"
	_fotografar()

## Na primeira vez que a aba aparece, o container já pôs o palco no tamanho final: a foto
## é tirada de novo, para sair igual ao palco animado.
func _ao_aparecer_pela_primeira_vez() -> void:
	if not has_focus():
		_fotografar()

## A foto leva dois quadros. Se o foco voltou para o cartão nesse meio tempo, ele volta a
## animar, senão ficaria parado justo com o foco.
func _fotografar() -> void:
	await _palco.tirar_foto()
	if has_focus():
		_palco.voltar_a_animar()
