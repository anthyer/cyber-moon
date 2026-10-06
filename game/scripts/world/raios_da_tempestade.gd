class_name RaiosDaTempestade
extends Node

## O raio da tempestade: de tempos em tempos um clarão na luz da cena e, um pouco depois,
## o trovão. O atraso entre os dois dá a sensação de distância. Só age em clima com
## tem_raio; nos outros fica parado.

@export var caminho_da_iluminacao: NodePath = ^"../IluminacaoDoCiclo"
@export var intervalo_minimo: float = 8.0
@export var intervalo_maximo: float = 20.0
@export var atraso_minimo_do_trovao: float = 1.0
@export var atraso_maximo_do_trovao: float = 3.0

var _segundos_ate_o_proximo: float = 0.0
var _ativo: bool = false

@onready var _iluminacao: IluminacaoDoCiclo = get_node_or_null(caminho_da_iluminacao) as IluminacaoDoCiclo

func _ready() -> void:
	WeatherManager.weather_changed.connect(_ao_mudar_clima)
	_ao_mudar_clima(WeatherManager.clima_atual)

func _process(delta: float) -> void:
	if not _ativo:
		return
	_segundos_ate_o_proximo -= delta
	if _segundos_ate_o_proximo <= 0.0:
		cair_um_raio()
		_segundos_ate_o_proximo = randf_range(intervalo_minimo, intervalo_maximo)

func cair_um_raio() -> void:
	if _iluminacao != null:
		_iluminacao.dar_clarao()
	var som: AudioStream = WeatherManager.perfil_atual().som_do_trovao
	if som == null:
		return
	var atraso: float = randf_range(atraso_minimo_do_trovao, atraso_maximo_do_trovao)
	get_tree().create_timer(atraso, false).timeout.connect(AudioManager.tocar_no_ambiente.bind(som))

func _ao_mudar_clima(_clima: StringName) -> void:
	_ativo = WeatherManager.perfil_atual().tem_raio
	if _ativo:
		_segundos_ate_o_proximo = randf_range(intervalo_minimo, intervalo_maximo)
