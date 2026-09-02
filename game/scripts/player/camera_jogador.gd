extends Camera3D

@export var alvo: NodePath
@export var deslocamento: Vector3 = Vector3(0, 5, 5)

@onready var _alvo_no: Node3D = get_node(alvo)

func _process(_delta: float) -> void:
	global_position = _alvo_no.global_position + deslocamento
