extends Control

## Relógio no canto superior direito: a hora, o ícone do clima do dia e o da fase da Lua
## (plano 37), a faixa colorida do dia, o período, a estação com o dia dentro dela e o dia
## da semana.
##
## Depois da meia-noite a hora fica âmbar e pisca, e o painel ganha a borda magenta. É o
## aviso de que mais tarde o personagem cai de sono onde estiver, com penalidade, e que é
## hora de ir para a cama. Âmbar, e não vermelho: o jogo não usa vermelho.

## Nome e cor de cada período, na ordem do enum DayCycleManager.Periodo. A cor pinta o
## pedaço do período na faixa do dia e o nome dele, para o período ser lido de relance.
## São as cores do céu de cada hora, e não papéis da interface, por isso não estão no
## Theme.
const NOMES_DOS_PERIODOS: Array[String] = ["Madrugada", "Manhã", "Tarde", "Anoitecer", "Noite"]
const CORES_DOS_PERIODOS: Array[Color] = [
	Color(0.35, 0.3, 0.75),
	Color(1.0, 0.85, 0.35),
	Color(1.0, 0.65, 0.2),
	Color(0.95, 0.4, 0.3),
	Color(0.25, 0.4, 0.95),
]
## A faixa do dia: a altura de cada pedaço e a grossura do contorno do período atual.
const ALTURA_DA_FAIXA: float = 6.0
const CONTORNO_DO_PERIODO_ATUAL: float = 2.0
const DURACAO_DA_PISCADA: float = 0.5
const OPACIDADE_DA_PISCADA: float = 0.35

@onready var painel: PanelContainer = %Painel
@onready var rotulo_da_hora: Label = %Hora
@onready var rotulo_do_dia: Label = %Dia
@onready var rotulo_do_periodo: Label = %Periodo
@onready var faixa_do_dia: Control = %FaixaDoDia
@onready var rotulo_da_estacao: Label = %Estacao
@onready var icone_do_clima: TextureRect = %Clima
@onready var icone_da_lua: TextureRect = %Lua

var _periodo_atual: int = 0
var _piscada_da_hora: Tween = null

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir, como a
	# HUD de status e a barra rápida.
	process_mode = Node.PROCESS_MODE_ALWAYS
	faixa_do_dia.draw.connect(_desenhar_faixa_do_dia)
	DayCycleManager.hour_changed.connect(_ao_mudar_hora)
	DayCycleManager.period_changed.connect(_ao_mudar_periodo)
	DayCycleManager.day_started.connect(_ao_comecar_dia)
	SeasonManager.season_changed.connect(_ao_mudar_estacao)
	EventBus.game_loaded.connect(func() -> void: _ao_comecar_dia(DayCycleManager.numero_do_dia))
	WeatherManager.weather_changed.connect(_ao_mudar_clima)
	_ao_mudar_clima(WeatherManager.clima_atual)
	RealWorldManager.moon_phase_changed.connect(_ao_mudar_fase_da_lua)
	_ao_mudar_fase_da_lua(RealWorldManager.fase_da_lua)
	_ao_mudar_hora(DayCycleManager.hora_atual)
	_ao_mudar_periodo(DayCycleManager.periodo_atual())
	_ao_comecar_dia(DayCycleManager.numero_do_dia)

func _process(_delta: float) -> void:
	visible = not get_tree().paused

func _ao_mudar_hora(hora: float) -> void:
	rotulo_da_hora.text = DayCycleManager.hora_formatada()
	_definir_aviso(hora >= DayCycleManager.HORA_MEIA_NOITE)

## Liga ou desliga o aviso de que está tarde: a hora em âmbar piscando e o painel com a
## borda magenta. Só mexe quando o estado muda, para a piscada não recomeçar a cada hora.
func _definir_aviso(tarde: bool) -> void:
	if tarde == (_piscada_da_hora != null):
		return
	if tarde:
		rotulo_da_hora.add_theme_color_override(&"font_color", CoresDaInterface.ambar())
		painel.theme_type_variation = &"PainelMagenta"
		_piscada_da_hora = create_tween().set_loops()
		_piscada_da_hora.tween_property(rotulo_da_hora, "modulate:a", OPACIDADE_DA_PISCADA, DURACAO_DA_PISCADA)
		_piscada_da_hora.tween_property(rotulo_da_hora, "modulate:a", 1.0, DURACAO_DA_PISCADA)
		return
	_piscada_da_hora.kill()
	_piscada_da_hora = null
	rotulo_da_hora.modulate.a = 1.0
	rotulo_da_hora.remove_theme_color_override(&"font_color")
	painel.theme_type_variation = &"PainelNeutro"

func _ao_mudar_periodo(periodo: int) -> void:
	_periodo_atual = periodo
	rotulo_do_periodo.text = NOMES_DOS_PERIODOS[periodo]
	rotulo_do_periodo.add_theme_color_override(&"font_color", CORES_DOS_PERIODOS[periodo])
	faixa_do_dia.queue_redraw()

## Um pedaço de cor por período, do mesmo tamanho, com o período de agora contornado.
func _desenhar_faixa_do_dia() -> void:
	var largura_do_pedaco: float = faixa_do_dia.size.x / CORES_DOS_PERIODOS.size()
	var topo: float = (faixa_do_dia.size.y - ALTURA_DA_FAIXA) / 2.0
	for indice in CORES_DOS_PERIODOS.size():
		var pedaco: Rect2 = Rect2(indice * largura_do_pedaco, topo, largura_do_pedaco, ALTURA_DA_FAIXA)
		faixa_do_dia.draw_rect(pedaco, CORES_DOS_PERIODOS[indice])
	var atual: Rect2 = Rect2(_periodo_atual * largura_do_pedaco, topo, largura_do_pedaco, ALTURA_DA_FAIXA)
	atual = atual.grow(CONTORNO_DO_PERIODO_ATUAL)
	faixa_do_dia.draw_rect(atual, CoresDaInterface.texto(), false, CONTORNO_DO_PERIODO_ATUAL)

func _ao_comecar_dia(numero_do_dia: int) -> void:
	# O dia da semana na frente, porque é ele que diz se hoje é Folga e as lojas fecham.
	rotulo_do_dia.text = "%s (dia %d)" % [SeasonManager.nome_do_dia_da_semana(), numero_do_dia]
	# O dia novo começa de manhã, e a hora volta ao normal, sem o âmbar de aviso.
	_ao_mudar_hora(DayCycleManager.hora_atual)
	_ao_mudar_periodo(DayCycleManager.periodo_atual())
	_atualizar_estacao()

func _ao_mudar_clima(_clima: StringName) -> void:
	var perfil: PerfilClima = WeatherManager.perfil_atual()
	icone_do_clima.texture = perfil.icone
	icone_do_clima.tooltip_text = perfil.nome_exibido

func _ao_mudar_fase_da_lua(fase: RealWorldManager.FaseDaLua) -> void:
	icone_da_lua.texture = RealWorldManager.configuracao().icone_da_fase(fase)
	icone_da_lua.tooltip_text = RealWorldManager.nome_da_fase(fase)

func _ao_mudar_estacao(_nova: StringName) -> void:
	_atualizar_estacao()

func _atualizar_estacao() -> void:
	var estacao: StringName = SeasonManager.estacao_atual()
	var texto: String = "%s, dia %d" % [SeasonManager.nome_exibido(estacao), SeasonManager.dia_da_estacao()]
	# O ano só aparece a partir do segundo: no primeiro ano ele não diz nada ao jogador
	# e só ocupa espaço no painel.
	if SeasonManager.ano_atual() > 1:
		texto += " (ano %d)" % SeasonManager.ano_atual()
	rotulo_da_estacao.text = texto
