class_name GradeDoCalendario
extends VBoxContainer

## O mês de uma estação numa grade de seis colunas (a semana do jogo tem seis dias, com a
## Folga em roxo), com o dia de hoje em ciano, os aniversários em rosa e a fase da Lua.
##
## É só o conteúdo. Quem mostra decide como abre e fecha: a tela do calendário (aberta
## pelo quadro no mundo) e a aba Calendário do menu de pausa usam esta mesma cena. Trocar
## a estação mostrada não muda nada no jogo; é só para olhar os outros meses.
##
## A Lua de cada dia sai da conta local do RealWorldManager (fase_calculada_localmente),
## contando um dia real por dia do jogo a partir de hoje. Hoje usa a fase que o jogo está
## usando de verdade (RealWorldManager.fase_da_lua), que pode ter vindo da API. O ícone
## aparece no dia em que a fase começa e no dia de hoje, como no mock; o nome da fase de
## qualquer dia aparece ao passar o mouse.
##
## Os aniversários vêm dos .tres de resources/npcs/, lidos da pasta. Uma lista fixa no
## código seria esquecida no dia em que alguém criasse um NPC novo.

const TAMANHO_DA_CELULA: Vector2 = Vector2(136.0, 64.0)
const ICONES_DA_LUA: Array[Texture2D] = [
	preload("res://assets/textures/icones_lua/nova.png"),
	preload("res://assets/textures/icones_lua/crescente.png"),
	preload("res://assets/textures/icones_lua/cheia.png"),
	preload("res://assets/textures/icones_lua/minguante.png"),
]
const TAMANHO_DO_ICONE_DA_LUA: Vector2 = Vector2(16.0, 16.0)
const SEGUNDOS_POR_DIA: float = 86400.0
## Quanto do roxo entra no fundo da Folga. O fundo é o do slot, pintado pelo
## self_modulate, então o número e o resto da célula não mudam de cor.
const MISTURA_DO_ROXO_DA_FOLGA: float = 0.55
## Dia que já passou fica com o número apagado, e o resto da célula meio transparente.
const OPACIDADE_DO_DIA_QUE_PASSOU: float = 0.6

@onready var titulo: Label = %Titulo
@onready var botao_anterior: Button = %BotaoAnterior
@onready var botao_proximo: Button = %BotaoProximo
@onready var nomes_dos_dias: HBoxContainer = %NomesDosDias
@onready var grade: GridContainer = %Grade
@onready var aniversarios: Label = %Aniversarios
@onready var rotulo_da_dica: Label = %Dica

var _npcs: Array[PerfilNpc] = []
## Índice em SeasonManager.ESTACOES da estação mostrada agora.
var _indice_mostrado: int = 0

func _ready() -> void:
	_npcs = ElencoDeNpcs.carregar_perfis()
	botao_anterior.pressed.connect(mostrar_estacao_vizinha.bind(-1))
	botao_proximo.pressed.connect(mostrar_estacao_vizinha.bind(1))
	titulo.add_theme_color_override(&"font_color", CoresDaInterface.verde())
	_montar_nomes_dos_dias()

## Volta para a estação de hoje e redesenha. Quem abre a grade chama ao abrir.
func mostrar_estacao_atual() -> void:
	_indice_mostrado = SeasonManager.indice_da_estacao()
	_redesenhar()

## O texto de ajuda do rodapé. Cada tela que usa a grade diz como ela fecha, com o nome
## da tecla lido do InputManager na hora de abrir.
func definir_dica(texto: String) -> void:
	rotulo_da_dica.text = texto

func mostrar_estacao_vizinha(passo: int) -> void:
	_indice_mostrado = posmod(_indice_mostrado + passo, SeasonManager.ESTACOES.size())
	_redesenhar()

func aniversariantes_do_dia(estacao: StringName, dia: int) -> Array[PerfilNpc]:
	var aniversariantes: Array[PerfilNpc] = []
	for npc in _npcs:
		if npc.estacao_do_aniversario == estacao and npc.dia_do_aniversario == dia:
			aniversariantes.append(npc)
	return aniversariantes

## A fase da Lua de um dia da estação mostrada. Conta quantos dias do jogo ele está
## longe de hoje e pergunta a fase daquela data real.
func fase_do_dia(dia: int) -> RealWorldManager.FaseDaLua:
	var dias_a_partir_de_hoje: int = (_indice_mostrado - SeasonManager.indice_da_estacao()) * SeasonManager.DIAS_POR_ESTACAO + dia - SeasonManager.dia_da_estacao()
	if dias_a_partir_de_hoje == 0:
		return RealWorldManager.fase_da_lua
	var data: float = Time.get_unix_time_from_system() + dias_a_partir_de_hoje * SEGUNDOS_POR_DIA
	return RealWorldManager.fase_calculada_localmente(data)

func _montar_nomes_dos_dias() -> void:
	for indice in SeasonManager.NOMES_DOS_DIAS_DA_SEMANA.size():
		var nome: Label = Label.new()
		nome.text = SeasonManager.NOMES_DOS_DIAS_DA_SEMANA[indice]
		nome.custom_minimum_size = Vector2(TAMANHO_DA_CELULA.x, 0.0)
		nome.theme_type_variation = &"TextoApagado"
		if indice == SeasonManager.DIA_DE_FOLGA:
			nome.add_theme_color_override(&"font_color", CoresDaInterface.violeta())
		nomes_dos_dias.add_child(nome)

func _redesenhar() -> void:
	var estacao: StringName = SeasonManager.ESTACOES[_indice_mostrado]
	titulo.text = "%s, ano %d" % [SeasonManager.nome_exibido(estacao), SeasonManager.ano_atual()]
	_redesenhar_grade(estacao)
	_redesenhar_aniversarios(estacao)

func _redesenhar_grade(estacao: StringName) -> void:
	for filho in grade.get_children():
		filho.queue_free()
	var e_a_estacao_atual: bool = estacao == SeasonManager.estacao_atual()
	var hoje: int = SeasonManager.dia_da_estacao() if e_a_estacao_atual else 0
	var fase_de_ontem: int = fase_do_dia(0)
	for dia in range(1, SeasonManager.DIAS_POR_ESTACAO + 1):
		var fase: RealWorldManager.FaseDaLua = fase_do_dia(dia)
		var ja_passou: bool = e_a_estacao_atual and dia < hoje
		grade.add_child(_nova_celula(estacao, dia, dia == hoje, ja_passou, fase, fase != fase_de_ontem))
		fase_de_ontem = fase

func _nova_celula(estacao: StringName, dia: int, e_hoje: bool, ja_passou: bool, fase: RealWorldManager.FaseDaLua, lua_mudou: bool) -> PanelContainer:
	var celula: PanelContainer = PanelContainer.new()
	celula.custom_minimum_size = TAMANHO_DA_CELULA
	celula.theme_type_variation = &"SlotFocado" if e_hoje else &"SlotNormal"
	var e_folga: bool = (dia - 1) % SeasonManager.DIAS_POR_SEMANA == SeasonManager.DIA_DE_FOLGA
	if e_folga and not e_hoje:
		celula.self_modulate = Color.WHITE.lerp(CoresDaInterface.violeta(), MISTURA_DO_ROXO_DA_FOLGA)
	if ja_passou:
		celula.modulate.a = OPACIDADE_DO_DIA_QUE_PASSOU
	var dicas: PackedStringArray = [RealWorldManager.nome_da_fase(fase)]

	var margem: MarginContainer = MarginContainer.new()
	margem.add_theme_constant_override(&"margin_left", 5)
	margem.add_theme_constant_override(&"margin_right", 5)
	celula.add_child(margem)
	var linhas: VBoxContainer = VBoxContainer.new()
	linhas.add_theme_constant_override(&"separation", 0)
	margem.add_child(linhas)

	var numero: Label = Label.new()
	numero.text = str(dia)
	if ja_passou:
		numero.theme_type_variation = &"TextoApagado"
	linhas.add_child(numero)

	var de_baixo: HBoxContainer = HBoxContainer.new()
	de_baixo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	de_baixo.alignment = BoxContainer.ALIGNMENT_END
	de_baixo.add_theme_constant_override(&"separation", 4)
	linhas.add_child(de_baixo)

	var eventos: HBoxContainer = HBoxContainer.new()
	eventos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eventos.add_theme_constant_override(&"separation", 4)
	de_baixo.add_child(eventos)
	var aniversariantes: Array[PerfilNpc] = aniversariantes_do_dia(estacao, dia)
	if not aniversariantes.is_empty():
		eventos.add_child(CoracaoDePixel.novo(CoresDaInterface.rosa()))
		var nomes: PackedStringArray = []
		for npc in aniversariantes:
			nomes.append(_primeiro_nome(npc))
		eventos.add_child(_rotulo_pequeno(", ".join(nomes), CoresDaInterface.rosa()))
		dicas.append("Aniversário: " + ", ".join(nomes))
	elif e_hoje:
		eventos.add_child(_rotulo_pequeno("hoje", CoresDaInterface.ciano()))

	if lua_mudou or e_hoje:
		var lua: TextureRect = TextureRect.new()
		lua.texture = ICONES_DA_LUA[fase]
		lua.custom_minimum_size = TAMANHO_DO_ICONE_DA_LUA
		lua.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lua.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lua.size_flags_vertical = Control.SIZE_SHRINK_END
		de_baixo.add_child(lua)
	celula.tooltip_text = "\n".join(dicas)
	return celula

## O rodapé lista os aniversários da estação numa linha só, em rosa.
func _redesenhar_aniversarios(estacao: StringName) -> void:
	var da_estacao: Array[PerfilNpc] = []
	for npc in _npcs:
		if npc.estacao_do_aniversario == estacao:
			da_estacao.append(npc)
	da_estacao.sort_custom(func(a: PerfilNpc, b: PerfilNpc) -> bool: return a.dia_do_aniversario < b.dia_do_aniversario)
	if da_estacao.is_empty():
		aniversarios.text = "Nenhum aniversário nesta estação."
		aniversarios.add_theme_color_override(&"font_color", CoresDaInterface.texto_apagado())
		return
	var partes: PackedStringArray = []
	for npc in da_estacao:
		partes.append("dia %d %s" % [npc.dia_do_aniversario, _primeiro_nome(npc)])
	aniversarios.text = "Aniversários: " + ", ".join(partes)
	aniversarios.add_theme_color_override(&"font_color", CoresDaInterface.rosa())

func _rotulo_pequeno(texto: String, cor: Color) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_color_override(&"font_color", cor)
	rotulo.size_flags_vertical = Control.SIZE_SHRINK_END
	rotulo.clip_text = true
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return rotulo

## A célula é estreita para o nome inteiro ("Kenji Moura" vira "Kenji").
func _primeiro_nome(npc: PerfilNpc) -> String:
	return npc.nome_exibido.get_slice(" ", 0)
