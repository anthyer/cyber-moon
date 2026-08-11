extends CharacterBody3D

@export var velocidade_andar: float = 3.0
@export var velocidade_correr: float = 6.0
@export var velocidade_rotacao: float = 10.0
@export var velocidade_dash: float = 12.0
@export var duracao_dash: float = 0.2
@export var cooldown_dash: float = 0.8
@export var velocidade_ataque: float = 1.6
@export var folga_pos_golpe: float = 0.1
@export var janela_combo_ataque: float = 0.6
@export var cooldown_ataque: float = 0.3

const CLIPES_COMBO_ATAQUE: Array[String] = ["attack-melee-left", "attack-melee-left", "attack-melee-right"]

@onready var personagem: Node3D = $Personagem
@onready var animation_player: AnimationPlayer = $Personagem/AnimationPlayer

var _tempo_dash_restante: float = 0.0
var _tempo_cooldown_restante: float = 0.0
var _direcao_dash: Vector3 = Vector3.ZERO

var _indice_combo: int = 0
var _tempo_ataque_restante: float = 0.0
var _tempo_janela_combo_restante: float = 0.0
var _tempo_cooldown_ataque_restante: float = 0.0

func _physics_process(delta: float) -> void:
	_tempo_cooldown_restante = max(_tempo_cooldown_restante - delta, 0.0)
	_tempo_ataque_restante = max(_tempo_ataque_restante - delta, 0.0)
	_tempo_janela_combo_restante = max(_tempo_janela_combo_restante - delta, 0.0)
	_tempo_cooldown_ataque_restante = max(_tempo_cooldown_ataque_restante - delta, 0.0)

	if _tempo_janela_combo_restante <= 0.0:
		_indice_combo = 0

	if _tempo_dash_restante <= 0.0 and _tempo_ataque_restante <= 0.0 and _tempo_cooldown_restante <= 0.0 and InputManager.dash_pressionado():
		_direcao_dash = Vector3(sin(personagem.rotation.y), 0.0, cos(personagem.rotation.y))
		_tempo_dash_restante = duracao_dash
		_tempo_cooldown_restante = cooldown_dash + duracao_dash

	if _tempo_dash_restante <= 0.0 and _tempo_ataque_restante <= 0.0 and _tempo_cooldown_ataque_restante <= 0.0 and InputManager.atacar_pressionado():
		var nome_clipe: String = CLIPES_COMBO_ATAQUE[_indice_combo]
		animation_player.play(nome_clipe, -1.0, velocidade_ataque)
		_tempo_ataque_restante = animation_player.get_animation(nome_clipe).length / velocidade_ataque + folga_pos_golpe
		_tempo_janela_combo_restante = janela_combo_ataque

		_indice_combo += 1
		if _indice_combo >= CLIPES_COMBO_ATAQUE.size():
			_indice_combo = 0
			_tempo_cooldown_ataque_restante = cooldown_ataque
			_tempo_janela_combo_restante = 0.0

	if _tempo_dash_restante > 0.0:
		_tempo_dash_restante = max(_tempo_dash_restante - delta, 0.0)

		velocity.x = _direcao_dash.x * velocidade_dash
		velocity.z = _direcao_dash.z * velocidade_dash

		_atualizar_animacao(Vector3.ZERO, false, true)
	elif _tempo_ataque_restante > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var entrada: Vector2 = InputManager.obter_direcao_movimento()
		var direcao: Vector3 = Vector3(entrada.x, 0.0, entrada.y)

		var esta_correndo: bool = direcao != Vector3.ZERO and InputManager.correr_pressionado()
		var velocidade_atual: float = velocidade_correr if esta_correndo else velocidade_andar

		velocity.x = direcao.x * velocidade_atual
		velocity.z = direcao.z * velocidade_atual

		if direcao != Vector3.ZERO:
			var angulo_alvo: float = atan2(direcao.x, direcao.z)
			personagem.rotation.y = lerp_angle(personagem.rotation.y, angulo_alvo, velocidade_rotacao * delta)

		_atualizar_animacao(direcao, esta_correndo, false)

	move_and_slide()

func _atualizar_animacao(direcao: Vector3, esta_correndo: bool, esta_dando_dash: bool) -> void:
	var animacao_alvo: String = "idle"
	if esta_dando_dash:
		animacao_alvo = "jump"
	elif direcao != Vector3.ZERO:
		animacao_alvo = "sprint" if esta_correndo else "walk"

	if animation_player.current_animation != animacao_alvo:
		animation_player.play(animacao_alvo)
