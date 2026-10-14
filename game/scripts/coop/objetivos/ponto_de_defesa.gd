class_name PontoDeDefesa
extends Node3D

## O ponto que o jogador protege no objetivo de defesa (a antena pirata, no tema). Não tem
## regra nenhuma: só mostra a vida que o objetivo manda. Treme enquanto perde vida e tomba
## quando ela acaba.

const SEGUNDOS_DO_TREMOR: float = 0.1
const FORCA_DO_TREMOR: float = 0.04
const SEGUNDOS_PARA_TOMBAR: float = 0.8
const GRAUS_TOMBADO: float = 85.0

@onready var modelo: Node3D = $Modelo

## De 0 a 1.
var fracao_de_vida: float = 1.0
var caido: bool = false

var _posicao_do_modelo: Vector3
var _tremor: Tween

func _ready() -> void:
	_posicao_do_modelo = modelo.position

## Mostra a vida nova. Se ela diminuiu, o ponto treme; se zerou, tomba.
func definir_vida(fracao: float) -> void:
	var nova: float = clampf(fracao, 0.0, 1.0)
	var perdeu: bool = nova < fracao_de_vida
	fracao_de_vida = nova
	if caido:
		return
	if fracao_de_vida <= 0.0:
		_tombar()
	elif perdeu:
		_tremer()

## Um tremor curto para os lados. Se já está tremendo, o anterior termina sozinho.
func _tremer() -> void:
	if _tremor != null and _tremor.is_running():
		return
	var desvio: Vector3 = Vector3(randf_range(-FORCA_DO_TREMOR, FORCA_DO_TREMOR), 0.0, randf_range(-FORCA_DO_TREMOR, FORCA_DO_TREMOR))
	_tremor = create_tween()
	_tremor.tween_property(modelo, "position", _posicao_do_modelo + desvio, SEGUNDOS_DO_TREMOR * 0.5)
	_tremor.tween_property(modelo, "position", _posicao_do_modelo, SEGUNDOS_DO_TREMOR * 0.5)

func _tombar() -> void:
	caido = true
	if _tremor != null:
		_tremor.kill()
	modelo.position = _posicao_do_modelo
	var queda: Tween = create_tween()
	queda.tween_property(modelo, "rotation_degrees:z", GRAUS_TOMBADO, SEGUNDOS_PARA_TOMBAR).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
