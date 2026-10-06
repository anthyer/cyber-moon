extends Control

## Relógio no canto superior direito: a hora, o número do dia, o período do dia e a
## estação com o dia dentro dela. Ao lado do período fica o ícone do clima do dia.
##
## Depois da meia-noite a hora fica vermelha. É o aviso de que à 1:00 o personagem cai
## de sono onde estiver, com penalidade, e que é hora de ir para a cama.

## Nome e cor de cada período, na ordem do enum DayCycleManager.Periodo. A cor pinta a
## bolinha ao lado do nome, para o período ser lido de relance sem ler o texto.
const NOMES_DOS_PERIODOS: Array[String] = ["Madrugada", "Manhã", "Tarde", "Anoitecer", "Noite"]
const CORES_DOS_PERIODOS: Array[Color] = [
	Color(0.35, 0.3, 0.75),
	Color(1.0, 0.85, 0.35),
	Color(1.0, 0.65, 0.2),
	Color(0.95, 0.4, 0.3),
	Color(0.25, 0.4, 0.95),
]
const COR_DA_HORA_NORMAL: Color = Color(0.92, 0.95, 1.0)
const COR_DA_HORA_DE_AVISO: Color = Color(1.0, 0.3, 0.3)

@onready var rotulo_da_hora: Label = %Hora
@onready var rotulo_do_dia: Label = %Dia
@onready var rotulo_do_periodo: Label = %Periodo
@onready var bolinha_do_periodo: ColorRect = %Bolinha
@onready var rotulo_da_estacao: Label = %Estacao
@onready var icone_do_clima: TextureRect = %Clima

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir, como a
	# HUD de status e a barra rápida.
	process_mode = Node.PROCESS_MODE_ALWAYS
	DayCycleManager.hour_changed.connect(_ao_mudar_hora)
	DayCycleManager.period_changed.connect(_ao_mudar_periodo)
	DayCycleManager.day_started.connect(_ao_comecar_dia)
	SeasonManager.season_changed.connect(_ao_mudar_estacao)
	WeatherManager.weather_changed.connect(_ao_mudar_clima)
	_ao_mudar_clima(WeatherManager.clima_atual)
	_ao_mudar_hora(DayCycleManager.hora_atual)
	_ao_mudar_periodo(DayCycleManager.periodo_atual())
	_ao_comecar_dia(DayCycleManager.numero_do_dia)

func _process(_delta: float) -> void:
	visible = not get_tree().paused

func _ao_mudar_hora(hora: float) -> void:
	rotulo_da_hora.text = DayCycleManager.hora_formatada()
	var cor: Color = COR_DA_HORA_DE_AVISO if hora >= DayCycleManager.HORA_MEIA_NOITE else COR_DA_HORA_NORMAL
	rotulo_da_hora.add_theme_color_override(&"font_color", cor)

func _ao_mudar_periodo(periodo: int) -> void:
	rotulo_do_periodo.text = NOMES_DOS_PERIODOS[periodo]
	bolinha_do_periodo.color = CORES_DOS_PERIODOS[periodo]

func _ao_comecar_dia(numero_do_dia: int) -> void:
	# O dia da semana na frente, porque é ele que diz se hoje é Folga e as lojas fecham.
	rotulo_do_dia.text = "%s (dia %d)" % [SeasonManager.nome_do_dia_da_semana(), numero_do_dia]
	# O dia novo começa de manhã, e a hora volta ao normal, sem o vermelho de aviso.
	_ao_mudar_hora(DayCycleManager.hora_atual)
	_ao_mudar_periodo(DayCycleManager.periodo_atual())
	_atualizar_estacao()

func _ao_mudar_clima(_clima: StringName) -> void:
	var perfil: PerfilClima = WeatherManager.perfil_atual()
	icone_do_clima.texture = perfil.icone
	icone_do_clima.tooltip_text = perfil.nome_exibido

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
