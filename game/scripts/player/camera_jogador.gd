extends Camera3D

@export var alvo: NodePath
@export var deslocamento: Vector3 = Vector3(0, 5, 5)

@onready var _alvo_no: Node3D = get_node(alvo)

## A sacudida é um deslocamento aleatório somado à posição de seguir. Ela começa na
## intensidade pedida e cai até zero, para o tranco ser forte no instante do golpe e
## sumir logo em seguida.
var _intensidade_da_sacudida: float = 0.0
var _duracao_da_sacudida: float = 0.0
var _segundos_de_sacudida: float = 0.0

func _process(delta: float) -> void:
	global_position = _alvo_no.global_position + deslocamento + _deslocamento_da_sacudida(delta)

## Sacode a câmera. Chamar de novo durante uma sacudida recomeça com a nova intensidade.
func sacudir(intensidade: float = 0.12, duracao: float = 0.2) -> void:
	_intensidade_da_sacudida = intensidade
	_duracao_da_sacudida = duracao
	_segundos_de_sacudida = duracao

func _deslocamento_da_sacudida(delta: float) -> Vector3:
	if _segundos_de_sacudida <= 0.0 or _duracao_da_sacudida <= 0.0:
		return Vector3.ZERO
	_segundos_de_sacudida = maxf(_segundos_de_sacudida - delta, 0.0)
	var forca: float = _intensidade_da_sacudida * (_segundos_de_sacudida / _duracao_da_sacudida)
	return Vector3(randf_range(-forca, forca), randf_range(-forca, forca), randf_range(-forca, forca))
