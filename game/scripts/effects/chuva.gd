class_name Chuva
extends CPUParticles3D

## A chuva: gotas caindo numa caixa larga em volta do jogador, que anda junto com ele.
## Chover no mapa inteiro custaria caro e quase tudo cairia fora da tela.
##
## A quantidade de gotas vem do perfil do clima. Com zero, a emissão fica desligada.
## Usa CPUParticles3D pelo mesmo motivo dos outros efeitos: funciona igual no
## renderizador Compatibility e na web.

## Altura acima do jogador de onde as gotas nascem.
@export var altura: float = 9.0

var _jogador: Node3D

func _ready() -> void:
	WeatherManager.weather_changed.connect(_ao_mudar_clima)
	_ao_mudar_clima(WeatherManager.clima_atual)

func _process(_delta: float) -> void:
	if not emitting:
		return
	if _jogador == null or not is_instance_valid(_jogador):
		_jogador = get_tree().get_first_node_in_group(&"jogador") as Node3D
		if _jogador == null:
			return
	global_position = _jogador.global_position + Vector3(0.0, altura, 0.0)

func _ao_mudar_clima(_clima: StringName) -> void:
	var gotas: int = WeatherManager.perfil_atual().quantidade_de_gotas
	if gotas <= 0:
		emitting = false
		return
	# Mudar amount reinicia o emissor, então só troca quando o número muda de verdade.
	if amount != gotas:
		amount = gotas
	emitting = true
