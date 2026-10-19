class_name DestaqueDeInteracao
extends Control

## Mostra o que vai responder se o jogador apertar interagir agora (plano 28).
##
## Duas coisas, no alvo que a AreaDeInteracao do jogador escolheu: um brilho pulsante
## nas malhas dele (uma camada por cima do material, que não apaga a cor original) e um
## balão acima dele com a tecla e o verbo ("F  Abrir baú"). O alvo chega pelo EventBus;
## esta tela não conhece o jogador nem os tipos de interagível. O verbo vem do método
## opcional texto_de_interacao() do alvo, e o que brilha, de no_do_destaque().

const BRILHO: Shader = preload("res://assets/shaders/destaque_de_interacao.gdshader")
## Quanto acima do alvo o balão fica, em unidades do mundo.
const ALTURA_DO_BALAO: float = 1.4

@onready var balao: PanelContainer = %Balao
@onready var rotulo_da_tecla: Label = %Tecla
@onready var rotulo_do_texto: Label = %Texto

var _alvo: Node3D = null
var _material_do_brilho: ShaderMaterial
## As malhas que estão brilhando, e a camada que cada uma tinha antes (quase sempre nula).
var _malhas_brilhando: Array[MeshInstance3D] = []
var _camadas_de_antes: Array[Material] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	balao.visible = false
	_material_do_brilho = ShaderMaterial.new()
	_material_do_brilho.shader = BRILHO
	EventBus.interaction_target_changed.connect(_ao_mudar_alvo)

func _ao_mudar_alvo(alvo: Node3D) -> void:
	_apagar_brilho()
	_alvo = alvo
	if _alvo == null:
		balao.visible = false
		return
	rotulo_do_texto.text = String(_alvo.call(&"texto_de_interacao")) if _alvo.has_method(&"texto_de_interacao") else "Interagir"
	_acender_brilho()

## O balão segue o alvo na tela. Some com o jogo pausado (menu, baú, calendário) e com o
## alvo atrás da câmera.
func _process(_delta: float) -> void:
	if _alvo == null or not is_instance_valid(_alvo):
		balao.visible = false
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	var ponto: Vector3 = _alvo.global_position + Vector3.UP * ALTURA_DO_BALAO
	if camera == null or get_tree().paused or camera.is_position_behind(ponto):
		balao.visible = false
		return
	rotulo_da_tecla.text = InputManager.nome_da_tecla(&"interagir")
	balao.visible = true
	balao.reset_size()
	balao.position = camera.unproject_position(ponto) - Vector2(balao.size.x / 2.0, balao.size.y)

func _acender_brilho() -> void:
	var no: Node3D = _alvo.call(&"no_do_destaque") as Node3D if _alvo.has_method(&"no_do_destaque") else _alvo
	if no == null:
		return
	var malhas: Array[Node] = no.find_children("*", "MeshInstance3D", true, false)
	if no is MeshInstance3D:
		malhas.append(no)
	for item in malhas:
		var malha: MeshInstance3D = item as MeshInstance3D
		_malhas_brilhando.append(malha)
		_camadas_de_antes.append(malha.material_overlay)
		malha.material_overlay = _material_do_brilho

func _apagar_brilho() -> void:
	for indice in _malhas_brilhando.size():
		var malha: MeshInstance3D = _malhas_brilhando[indice]
		# Só devolve a camada antiga se ninguém trocou a camada no meio (a piscada de dano
		# usa a mesma camada e cuida de si).
		if is_instance_valid(malha) and malha.material_overlay == _material_do_brilho:
			malha.material_overlay = _camadas_de_antes[indice]
	_malhas_brilhando.clear()
	_camadas_de_antes.clear()
