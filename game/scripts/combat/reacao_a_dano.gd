class_name ReacaoADano
extends Node

## O que acontece com quem leva um golpe: empurrão para trás, piscada branca, um
## instante de invencibilidade e o som do impacto.
##
## É um nó só, usado tanto pelo jogador quanto pelos inimigos, porque a reação é a
## mesma nos dois lados. Ele não move o corpo sozinho: o dono (um CharacterBody3D) lê o
## empurrão em empurrao_atual() e soma na própria velocidade. Assim cada dono continua
## sendo o único que mexe no próprio movimento.

@export var forca_do_empurrao: float = 3.0
@export var duracao_do_empurrao: float = 0.15
@export var duracao_da_piscada: float = 0.08
## Tempo depois de um golpe em que o dono não leva outro. Sem isso, uma área de acerto
## que fica vários quadros encostada tiraria vida em todos eles.
@export var duracao_da_invencibilidade: float = 0.4
@export var som: AudioStream
## Nó cujos MeshInstance3D descendentes piscam de branco.
@export var caminho_do_modelo: NodePath = ^"../Personagem"

## Alfa da camada branca no auge da piscada.
const ALFA_DA_PISCADA: float = 0.85

## A piscada usa material_overlay, uma camada desenhada por cima do material normal, em
## vez de trocar o material das malhas. O inimigo tinge a cor sobrescrevendo o material
## de cada superfície, e trocar esse material apagaria o tingimento.
var _camada_branca: StandardMaterial3D
var _malhas: Array[MeshInstance3D] = []

var _direcao_do_empurrao: Vector3 = Vector3.ZERO
var _segundos_de_empurrao: float = 0.0
var _segundos_de_piscada: float = 0.0
var _segundos_de_invencibilidade: float = 0.0

func _ready() -> void:
	_camada_branca = StandardMaterial3D.new()
	_camada_branca.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_camada_branca.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_camada_branca.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
	var modelo: Node3D = get_node_or_null(caminho_do_modelo) as Node3D
	if modelo != null:
		ligar_modelo(modelo)

func _physics_process(delta: float) -> void:
	_segundos_de_empurrao = maxf(_segundos_de_empurrao - delta, 0.0)
	_segundos_de_invencibilidade = maxf(_segundos_de_invencibilidade - delta, 0.0)
	if _segundos_de_piscada > 0.0:
		_segundos_de_piscada = maxf(_segundos_de_piscada - delta, 0.0)
		# A camada começa no máximo e some por igual até o fim da piscada.
		_camada_branca.albedo_color.a = ALFA_DA_PISCADA * (_segundos_de_piscada / duracao_da_piscada)

## O dono que instancia o modelo em código chama isto depois de criar o modelo, porque
## no _ready deste nó ele ainda pode não existir.
func ligar_modelo(modelo: Node3D) -> void:
	_malhas.clear()
	for no in modelo.find_children("*", "MeshInstance3D", true, false):
		var malha: MeshInstance3D = no as MeshInstance3D
		malha.material_overlay = _camada_branca
		_malhas.append(malha)

func pode_levar_dano() -> bool:
	return _segundos_de_invencibilidade <= 0.0

func reagir(posicao_de_quem_bateu: Vector3) -> void:
	var dono: Node3D = get_parent() as Node3D
	if _malhas.is_empty():
		var modelo: Node3D = get_node_or_null(caminho_do_modelo) as Node3D
		if modelo != null:
			ligar_modelo(modelo)

	var afastamento: Vector3 = dono.global_position - posicao_de_quem_bateu
	afastamento.y = 0.0
	if afastamento.length() < 0.01:
		# Atacante e dono no mesmo ponto: empurra para trás da frente do dono.
		afastamento = dono.global_transform.basis.z
		afastamento.y = 0.0
		if afastamento.length() < 0.01:
			afastamento = Vector3.BACK
	_direcao_do_empurrao = afastamento.normalized()
	_segundos_de_empurrao = duracao_do_empurrao
	_segundos_de_invencibilidade = duracao_da_invencibilidade

	if duracao_da_piscada > 0.0:
		_segundos_de_piscada = duracao_da_piscada
		_camada_branca.albedo_color.a = ALFA_DA_PISCADA

	AudioManager.tocar_sfx(som, dono.global_position)

## Velocidade horizontal do empurrão neste quadro, que cai em linha reta até zero no fim
## do empurrão. Fora dele é zero.
func empurrao_atual() -> Vector3:
	if _segundos_de_empurrao <= 0.0 or duracao_do_empurrao <= 0.0:
		return Vector3.ZERO
	var fracao_restante: float = _segundos_de_empurrao / duracao_do_empurrao
	return _direcao_do_empurrao * forca_do_empurrao * fracao_restante

func esta_sendo_empurrado() -> bool:
	return _segundos_de_empurrao > 0.0
