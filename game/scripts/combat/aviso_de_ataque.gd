class_name AvisoDeAtaque
extends Node3D

## A marca no chão que anuncia um ataque de chefe. Ela nasce fraca, vai enchendo até o
## tempo acabar, dá um clarão e some. Quem criou a marca escuta o sinal finished para
## saber a hora de o dano cair, e pergunta em contem() quem estava dentro dela.
##
## A marca não tira vida de ninguém: ela só mostra e mede. Assim a mesma cena serve no
## jogo do anfitrião, onde o dano cai, e no dos outros, onde ela é só o desenho.
##
## São duas formas: o círculo, com o centro na posição da marca, e a faixa, que sai da
## posição da marca e segue para a frente dela.

## Emitido quando o tempo do aviso acaba, antes do clarão. É a hora do dano.
signal finished

enum Forma { CIRCULO, FAIXA }

const CAMINHO_DA_CENA: String = "res://scenes/combat/aviso_de_ataque.tscn"
## A marca fica um pouco acima do chão, senão as duas superfícies brigam e ela pisca.
const ALTURA_ACIMA_DO_CHAO: float = 0.02
## O enchimento fica um fio acima do contorno, pelo mesmo motivo.
const ALTURA_DO_ENCHIMENTO: float = 0.005
const ALFA_DO_CONTORNO: float = 0.22
const ALFA_DO_ENCHIMENTO: float = 0.5
const ALFA_DO_CLARAO: float = 0.95
const SEGUNDOS_DE_CLARAO: float = 0.15
## Quanto a cor da marca clareia no clarão. Vai para o branco, nunca para o vermelho.
const CLAREAMENTO_DO_CLARAO: float = 0.6
## Escala zero deixa a malha sem volume e o motor reclama; o enchimento começa quase nulo.
const ENCHIMENTO_MINIMO: float = 0.001

## As malhas têm tamanho 1 e são esticadas pelo código até o tamanho da marca.
@export var malha_do_circulo: Mesh
@export var malha_da_faixa: Mesh
@export var material_da_marca: StandardMaterial3D

@onready var _contorno: MeshInstance3D = $Contorno
@onready var _enchimento: MeshInstance3D = $Enchimento

var _forma: Forma = Forma.CIRCULO
var _raio: float = 1.0
var _comprimento: float = 1.0
var _meia_largura: float = 1.0
var _segundos: float = 1.0
var _cor: Color = Color.WHITE

var _decorrido: float = 0.0
var _terminou: bool = false
var _segundos_de_clarao_restantes: float = 0.0
var _material_do_contorno: StandardMaterial3D
var _material_do_enchimento: StandardMaterial3D

## Cria um círculo no chão. A posição é o ponto do chão no centro dele.
static func criar_circulo(pai: Node, posicao: Vector3, raio: float, segundos: float, cor: Color) -> AvisoDeAtaque:
	var aviso: AvisoDeAtaque = _instanciar()
	aviso._forma = Forma.CIRCULO
	aviso._raio = raio
	aviso._segundos = maxf(segundos, 0.05)
	aviso._cor = cor
	pai.add_child(aviso)
	aviso.global_position = posicao + Vector3.UP * ALTURA_ACIMA_DO_CHAO
	return aviso

## Cria uma faixa no chão. Ela começa na origem e segue na direção do giro (o mesmo giro
## em Y do modelo de um personagem), com o comprimento e a meia largura dados.
static func criar_faixa(pai: Node, origem: Vector3, giro: float, comprimento: float, meia_largura: float, segundos: float, cor: Color) -> AvisoDeAtaque:
	var aviso: AvisoDeAtaque = _instanciar()
	aviso._forma = Forma.FAIXA
	aviso._comprimento = comprimento
	aviso._meia_largura = meia_largura
	aviso._segundos = maxf(segundos, 0.05)
	aviso._cor = cor
	pai.add_child(aviso)
	aviso.global_position = origem + Vector3.UP * ALTURA_ACIMA_DO_CHAO
	aviso.global_rotation = Vector3(0.0, giro, 0.0)
	return aviso

## A cena é carregada pelo caminho, e não com preload, porque ela aponta para este script
## e um preload daqui para ela fecharia um círculo.
static func _instanciar() -> AvisoDeAtaque:
	var cena: PackedScene = load(CAMINHO_DA_CENA) as PackedScene
	return cena.instantiate() as AvisoDeAtaque

func _ready() -> void:
	# Cada marca tem as próprias cópias do material, senão mudar a cor de uma mudaria a
	# de todas as que estão no chão.
	_material_do_contorno = material_da_marca.duplicate() as StandardMaterial3D
	_material_do_enchimento = material_da_marca.duplicate() as StandardMaterial3D
	_material_do_contorno.albedo_color = Color(_cor, ALFA_DO_CONTORNO)
	_material_do_enchimento.albedo_color = Color(_cor, ALFA_DO_ENCHIMENTO)
	var malha: Mesh = malha_do_circulo if _forma == Forma.CIRCULO else malha_da_faixa
	_contorno.mesh = malha
	_enchimento.mesh = malha
	_contorno.material_override = _material_do_contorno
	_enchimento.material_override = _material_do_enchimento
	_enchimento.position.y = ALTURA_DO_ENCHIMENTO
	_ajustar_tamanho(_contorno, 1.0)
	_ajustar_tamanho(_enchimento, ENCHIMENTO_MINIMO)

func _process(delta: float) -> void:
	if _terminou:
		_processar_clarao(delta)
		return
	_decorrido += delta
	var fracao: float = clampf(_decorrido / _segundos, ENCHIMENTO_MINIMO, 1.0)
	_ajustar_tamanho(_enchimento, fracao)
	if _decorrido >= _segundos:
		_terminar()

## Verdadeiro quando o ponto está dentro da marca. A altura não conta: a marca é um
## desenho no chão, e pular não tira ninguém de dentro dela.
func contem(ponto: Vector3) -> bool:
	var no_espaco_da_marca: Vector3 = to_local(ponto)
	if _forma == Forma.CIRCULO:
		return Vector2(no_espaco_da_marca.x, no_espaco_da_marca.z).length() <= _raio
	var dentro_da_largura: bool = absf(no_espaco_da_marca.x) <= _meia_largura
	var dentro_do_comprimento: bool = no_espaco_da_marca.z >= 0.0 and no_espaco_da_marca.z <= _comprimento
	return dentro_da_largura and dentro_do_comprimento

## O raio para efeitos de fora, como a partícula do impacto. Na faixa, a meia largura.
func raio_visual() -> float:
	return _raio if _forma == Forma.CIRCULO else _meia_largura

## O centro da marca no chão. No círculo é a própria posição; na faixa, o meio dela.
func centro() -> Vector3:
	if _forma == Forma.CIRCULO:
		return global_position
	return to_global(Vector3(0.0, 0.0, _comprimento * 0.5))

## Tira a marca do chão sem avisar ninguém. Usado quando o chefe cai no meio do aviso:
## o ataque dele não chega a acertar.
func cancelar() -> void:
	_terminou = true
	queue_free()

func _terminar() -> void:
	_terminou = true
	_segundos_de_clarao_restantes = SEGUNDOS_DE_CLARAO
	_contorno.visible = false
	_material_do_enchimento.albedo_color = Color(_cor.lerp(Color.WHITE, CLAREAMENTO_DO_CLARAO), ALFA_DO_CLARAO)
	finished.emit()

## O clarão começa forte e apaga por igual até sumir, e então a marca se desfaz.
func _processar_clarao(delta: float) -> void:
	_segundos_de_clarao_restantes -= delta
	if _segundos_de_clarao_restantes <= 0.0:
		queue_free()
		return
	_material_do_enchimento.albedo_color.a = ALFA_DO_CLARAO * (_segundos_de_clarao_restantes / SEGUNDOS_DE_CLARAO)

## Estica a malha de tamanho 1 até a fração pedida da marca. O círculo cresce do centro
## para fora; a faixa cresce da origem para a ponta, como se o ataque avançasse.
func _ajustar_tamanho(malha: MeshInstance3D, fracao: float) -> void:
	if _forma == Forma.CIRCULO:
		malha.scale = Vector3(_raio * fracao, 1.0, _raio * fracao)
		return
	var comprimento_agora: float = _comprimento * fracao
	malha.scale = Vector3(_meia_largura * 2.0, 1.0, comprimento_agora)
	malha.position.z = comprimento_agora * 0.5
