extends CharacterBody3D

@export var velocidade_andar: float = 3.0
@export var velocidade_correr: float = 6.0
@export var velocidade_rotacao: float = 10.0

@onready var personagem: Node3D = $Personagem
@onready var animation_player: AnimationPlayer = $Personagem/AnimationPlayer

func _physics_process(delta: float) -> void:
	var entrada: Vector2 = InputManager.obter_direcao_movimento()
	var direcao: Vector3 = Vector3(entrada.x, 0.0, entrada.y)

	var esta_correndo: bool = direcao != Vector3.ZERO and InputManager.correr_pressionado()
	var velocidade_atual: float = velocidade_correr if esta_correndo else velocidade_andar

	velocity.x = direcao.x * velocidade_atual
	velocity.z = direcao.z * velocidade_atual

	if direcao != Vector3.ZERO:
		var angulo_alvo: float = atan2(direcao.x, direcao.z)
		personagem.rotation.y = lerp_angle(personagem.rotation.y, angulo_alvo, velocidade_rotacao * delta)

	_atualizar_animacao(direcao, esta_correndo)

	move_and_slide()

func _atualizar_animacao(direcao: Vector3, esta_correndo: bool) -> void:
	var animacao_alvo: String = "idle"
	if direcao != Vector3.ZERO:
		animacao_alvo = "sprint" if esta_correndo else "walk"

	if animation_player.current_animation != animacao_alvo:
		animation_player.play(animacao_alvo)
