class_name CenarioDoMenu
extends Node2D

## O fundo animado da tela inicial: céu com a lua, cidade em camadas que rolam em
## velocidades diferentes, a via elevada na frente e os carros voadores.
##
## Tudo é pixel art pensada em 384x216 (as imagens saem de
## equipe/ferramentas/gerar_tela_inicial.py). Este nó amplia por um número inteiro, o maior
## que cabe na altura da janela, para o pixel ficar quadrado e nítido. Se a janela for
## mais larga, as camadas só leem um pedaço maior da textura, que repete.

const ALTURA_EM_PIXELS: float = 216.0
const CARROS: Array[Texture2D] = [
	preload("res://assets/textures/tela_inicial/carro_a.png"),
	preload("res://assets/textures/tela_inicial/carro_b.png"),
	preload("res://assets/textures/tela_inicial/carro_c.png"),
]
## As pistas dos carros: altura (em pixels da arte), sentido (1 para a direita, -1 para
## a esquerda), faixa de velocidade e se a pista é a do fundo, entre as camadas da
## cidade, onde os carros ficam mais escuros.
const PISTAS: Array[Dictionary] = [
	{"altura": 118, "sentido": 1, "velocidade": Vector2(14, 22), "fundo": true},
	{"altura": 132, "sentido": -1, "velocidade": Vector2(16, 26), "fundo": true},
	{"altura": 170, "sentido": 1, "velocidade": Vector2(40, 60), "fundo": false},
	{"altura": 179, "sentido": -1, "velocidade": Vector2(46, 70), "fundo": false},
]
const COR_DO_CARRO_AO_FUNDO: Color = Color(0.55, 0.5, 0.75)
const SEGUNDOS_ENTRE_CARROS: Vector2 = Vector2(0.6, 1.8)
## O título sobe e desce um pixel da arte, devagar.
const SEGUNDOS_DA_FLUTUACAO: float = 1.4

@onready var _lua: Sprite2D = $Lua
@onready var _titulo: Sprite2D = $Titulo
@onready var _carros_ao_fundo: Node2D = $CarrosAoFundo
@onready var _carros_na_frente: Node2D = $CarrosNaFrente

var escala: int = 1
var _largura_em_pixels: float = 384.0
var _segundos_ate_o_proximo_carro: float = 0.0
var _tempo: float = 0.0
var _altura_do_titulo: float = 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(_ajustar_ao_tamanho_da_janela)
	_ajustar_ao_tamanho_da_janela()
	# A tela já abre com trânsito, em vez de começar com a via vazia.
	for indice in 6:
		_soltar_carro(randf_range(0.0, _largura_em_pixels))

func _ajustar_ao_tamanho_da_janela() -> void:
	var tamanho: Vector2 = get_viewport_rect().size
	escala = maxi(1, floori(tamanho.y / ALTURA_EM_PIXELS))
	scale = Vector2(escala, escala)
	_largura_em_pixels = ceilf(tamanho.x / escala)
	# A arte encosta no pé da janela. Sobrando altura, o que aparece em cima é a cor do
	# céu, pintada pelo menu atrás deste nó.
	position = Vector2(0.0, tamanho.y - ALTURA_EM_PIXELS * escala)
	for filho in get_children():
		var camada: CamadaDeParallax = filho as CamadaDeParallax
		if camada != null:
			camada.ajustar_largura(_largura_em_pixels)
	# A lua fica no canto direito, fora do caminho do título, que é centralizado.
	_lua.position = Vector2(_largura_em_pixels - _lua.texture.get_width() - 6.0, 4.0)
	# Canto de cima à esquerda, e não o centro: com largura ímpar o centro cairia no
	# meio de um pixel, e a ampliação borraria a letra.
	_altura_do_titulo = 22.0
	_titulo.position = Vector2(floorf((_largura_em_pixels - _titulo.texture.get_width()) / 2.0), _altura_do_titulo)

func _process(delta: float) -> void:
	_tempo += delta
	# Degrau de um pixel inteiro, e não deslize: sobe e desce como sprite de pixel art.
	var subindo: bool = fmod(_tempo, SEGUNDOS_DA_FLUTUACAO * 2.0) < SEGUNDOS_DA_FLUTUACAO
	_titulo.position.y = _altura_do_titulo - (1.0 if subindo else 0.0)
	_segundos_ate_o_proximo_carro -= delta
	if _segundos_ate_o_proximo_carro <= 0.0:
		_segundos_ate_o_proximo_carro = randf_range(SEGUNDOS_ENTRE_CARROS.x, SEGUNDOS_ENTRE_CARROS.y)
		_soltar_carro(-1.0)
	_andar_carros(_carros_ao_fundo, delta)
	_andar_carros(_carros_na_frente, delta)

## Solta um carro numa pista sorteada. Sem posição (x negativo), ele entra pela borda de
## onde a pista vem; com posição, aparece já no meio da tela.
func _soltar_carro(x: float) -> void:
	var pista: Dictionary = PISTAS.pick_random()
	var carro: Sprite2D = Sprite2D.new()
	carro.texture = CARROS.pick_random()
	carro.centered = false
	var sentido: int = pista["sentido"]
	carro.flip_h = sentido < 0
	if x < 0.0:
		x = -carro.texture.get_width() if sentido > 0 else _largura_em_pixels
	carro.position = Vector2(x, pista["altura"])
	# A posição de verdade fica guardada à parte; a do desenho é ela arredondada, para o
	# carro andar de pixel em pixel da arte.
	carro.set_meta(&"x", x)
	carro.set_meta(&"velocidade", randf_range(pista["velocidade"].x, pista["velocidade"].y) * sentido)
	if pista["fundo"]:
		carro.modulate = COR_DO_CARRO_AO_FUNDO
		_carros_ao_fundo.add_child(carro)
	else:
		_carros_na_frente.add_child(carro)

func _andar_carros(pista: Node2D, delta: float) -> void:
	for filho in pista.get_children():
		var carro: Sprite2D = filho as Sprite2D
		var x: float = float(carro.get_meta(&"x")) + float(carro.get_meta(&"velocidade")) * delta
		carro.set_meta(&"x", x)
		carro.position.x = roundf(x)
		var saiu: bool = x > _largura_em_pixels + 4.0 or x < -carro.texture.get_width() - 4.0
		if saiu:
			carro.queue_free()
