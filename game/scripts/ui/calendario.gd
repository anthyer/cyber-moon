class_name Calendario
extends Control

## A tela do calendário: o mês da estação numa grade de 6 colunas por 5 linhas, o dia de
## hoje destacado e os aniversários dos NPCs.
##
## Abrir pausa o jogo de verdade, como o menu de pausa, e por isso este nó fica com
## process_mode ALWAYS. As setas trocam a estação mostrada, sem mudar nada no jogo: é só
## para olhar os outros meses.
##
## Os aniversários vêm dos .tres de resources/npcs/, lidos da pasta. Uma lista fixa no
## código seria esquecida no dia em que alguém criasse um NPC novo.

const PASTA_DOS_NPCS: String = "res://resources/npcs/"
const TAMANHO_DA_CELULA: Vector2 = Vector2(84.0, 44.0)

const COR_DO_DIA: Color = Color(0.1, 0.13, 0.2, 0.9)
const COR_DA_FOLGA: Color = Color(0.16, 0.12, 0.2, 0.9)
const COR_DE_HOJE: Color = Color(0.2, 0.95, 1.0, 0.35)
const COR_DA_BORDA_DE_HOJE: Color = Color(0.2, 0.95, 1.0, 1.0)
const COR_DO_ANIVERSARIO: Color = Color(1.0, 0.45, 0.75)
const COR_DO_TEXTO: Color = Color(0.92, 0.95, 1.0)
const COR_DO_TEXTO_APAGADO: Color = Color(0.6, 0.66, 0.8)

@onready var titulo: Label = %Titulo
@onready var botao_anterior: Button = %BotaoAnterior
@onready var botao_proximo: Button = %BotaoProximo
@onready var grade: GridContainer = %Grade
@onready var lista_de_aniversarios: VBoxContainer = %ListaDeAniversarios

var _npcs: Array[PerfilNpc] = []
## Índice em SeasonManager.ESTACOES da estação que a tela mostra agora. Só muda a
## visualização; a estação do jogo continua sendo a do SeasonManager.
var _indice_mostrado: int = 0

func _ready() -> void:
	visible = false
	_carregar_npcs()
	botao_anterior.pressed.connect(_mostrar_estacao_vizinha.bind(-1))
	botao_proximo.pressed.connect(_mostrar_estacao_vizinha.bind(1))
	EventBus.calendar_requested.connect(abrir)

## A entrada é lida no _process, pelo InputManager, para responder com o jogo rodando
## (abrir) e pausado (fechar). Este nó precisa vir depois do MenuPausa na cena: assim, no
## quadro em que o Esc fecha o calendário, o MenuPausa já rodou, viu o jogo pausado e não
## abriu por cima.
func _process(_delta: float) -> void:
	if not visible:
		if InputManager.abrir_calendario_pressionado():
			abrir()
		return
	if InputManager.abrir_calendario_pressionado() or Input.is_action_just_pressed(&"ui_cancel"):
		fechar()
	elif Input.is_action_just_pressed(&"ui_left"):
		_mostrar_estacao_vizinha(-1)
	elif Input.is_action_just_pressed(&"ui_right"):
		_mostrar_estacao_vizinha(1)

## Abre mostrando a estação atual. Não abre por cima de outra tela que já pausou o jogo
## (o inventário), nem com o jogador caído.
func abrir() -> void:
	if visible or get_tree().paused or StatusManager.esta_desmaiado:
		return
	_indice_mostrado = SeasonManager.indice_da_estacao()
	_redesenhar()
	visible = true
	get_tree().paused = true

func fechar() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false

func aniversariantes_do_dia(estacao: StringName, dia: int) -> Array[PerfilNpc]:
	var aniversariantes: Array[PerfilNpc] = []
	for npc in _npcs:
		if npc.estacao_do_aniversario == estacao and npc.dia_do_aniversario == dia:
			aniversariantes.append(npc)
	return aniversariantes

func _mostrar_estacao_vizinha(passo: int) -> void:
	_indice_mostrado = posmod(_indice_mostrado + passo, SeasonManager.ESTACOES.size())
	_redesenhar()

func _redesenhar() -> void:
	var estacao: StringName = SeasonManager.ESTACOES[_indice_mostrado]
	titulo.text = "%s, ano %d" % [SeasonManager.nome_exibido(estacao), SeasonManager.ano_atual()]
	_redesenhar_grade(estacao)
	_redesenhar_aniversarios(estacao)

func _redesenhar_grade(estacao: StringName) -> void:
	for filho in grade.get_children():
		filho.queue_free()
	for nome_do_dia in SeasonManager.NOMES_DOS_DIAS_DA_SEMANA:
		var cabecalho: Label = _novo_rotulo(nome_do_dia, 13, COR_DO_TEXTO_APAGADO)
		cabecalho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grade.add_child(cabecalho)
	# O destaque de hoje só aparece no mês da estação atual.
	var hoje: int = SeasonManager.dia_da_estacao() if estacao == SeasonManager.estacao_atual() else 0
	for dia in range(1, SeasonManager.DIAS_POR_ESTACAO + 1):
		grade.add_child(_nova_celula(estacao, dia, dia == hoje))

func _nova_celula(estacao: StringName, dia: int, e_hoje: bool) -> PanelContainer:
	var celula: PanelContainer = PanelContainer.new()
	celula.custom_minimum_size = TAMANHO_DA_CELULA
	var e_folga: bool = (dia - 1) % SeasonManager.DIAS_POR_SEMANA == SeasonManager.DIA_DE_FOLGA
	var fundo: StyleBoxFlat = StyleBoxFlat.new()
	fundo.bg_color = COR_DA_FOLGA if e_folga else COR_DO_DIA
	fundo.set_corner_radius_all(3)
	if e_hoje:
		fundo.bg_color = COR_DE_HOJE
		fundo.border_color = COR_DA_BORDA_DE_HOJE
		fundo.set_border_width_all(2)
	celula.add_theme_stylebox_override(&"panel", fundo)

	var linha: HBoxContainer = HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override(&"separation", 6)
	celula.add_child(linha)
	linha.add_child(_novo_rotulo(str(dia), 18, COR_DO_TEXTO))

	var aniversariantes: Array[PerfilNpc] = aniversariantes_do_dia(estacao, dia)
	if not aniversariantes.is_empty():
		var ponto: ColorRect = ColorRect.new()
		ponto.color = COR_DO_ANIVERSARIO
		ponto.custom_minimum_size = Vector2(8.0, 8.0)
		ponto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha.add_child(ponto)
		var nomes: PackedStringArray = []
		for npc in aniversariantes:
			nomes.append(npc.nome_exibido)
		celula.tooltip_text = "Aniversário: " + ", ".join(nomes)
	return celula

func _redesenhar_aniversarios(estacao: StringName) -> void:
	for filho in lista_de_aniversarios.get_children():
		filho.queue_free()
	var da_estacao: Array[PerfilNpc] = []
	for npc in _npcs:
		if npc.estacao_do_aniversario == estacao:
			da_estacao.append(npc)
	da_estacao.sort_custom(func(a: PerfilNpc, b: PerfilNpc) -> bool: return a.dia_do_aniversario < b.dia_do_aniversario)
	if da_estacao.is_empty():
		lista_de_aniversarios.add_child(_novo_rotulo("Nenhum nesta estação.", 14, COR_DO_TEXTO_APAGADO))
		return
	for npc in da_estacao:
		lista_de_aniversarios.add_child(_novo_rotulo("dia %d   %s" % [npc.dia_do_aniversario, npc.nome_exibido], 15, COR_DO_TEXTO))

func _novo_rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override(&"font_size", tamanho)
	rotulo.add_theme_color_override(&"font_color", cor)
	return rotulo

## Lê todo .tres da pasta de NPCs. No jogo exportado o Godot lista os recursos com
## ".remap" no fim do nome, e o load precisa do nome sem ele.
func _carregar_npcs() -> void:
	_npcs.clear()
	var pasta: DirAccess = DirAccess.open(PASTA_DOS_NPCS)
	if pasta == null:
		return
	for arquivo in pasta.get_files():
		var nome: String = arquivo.trim_suffix(".remap")
		if not nome.ends_with(".tres"):
			continue
		var perfil: PerfilNpc = load(PASTA_DOS_NPCS + nome) as PerfilNpc
		if perfil != null:
			_npcs.append(perfil)
