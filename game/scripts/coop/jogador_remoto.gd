class_name JogadorRemoto
extends AnimatableBody3D

## O outro jogador da dungeon, visto no meu jogo. É um fantoche: não tem controle nem
## inteligência, só mostra a posição, o giro e a animação que chegam pela rede.
##
## Ele fica na camada "jogador" para a área de golpe do inimigo encontrá-lo, mas não tem
## vida. Quando leva um golpe só avisa por sinal, e quem criou o fantoche manda a
## mensagem de dano para o jogador de verdade, que é quem cuida da própria vida.

## O fantoche levou um golpe de um inimigo do meu jogo.
signal hit_taken(quantidade: int)

const GRUPO_DE_ALVOS: StringName = &"alvos_de_inimigo"
const CENA_DO_SOPRO: PackedScene = preload("res://scenes/effects/poeira_de_passo.tscn")
const COR_DO_SOPRO: Color = Color(0.3, 0.95, 1.0)
const QUANTIDADE_DO_SOPRO: int = 14
const ALTURA_DO_SOPRO: float = 0.4
## As mensagens chegam umas 12 vezes por segundo. Sem seguir o alvo aos poucos, o boneco
## andaria aos pulos. Quanto maior, mais colado no alvo e menos suave.
const SUAVIDADE: float = 14.0
## Acima desta distância não é atraso de rede, é teleporte (entrou na sala, voltou ao
## começo), e deslizar até lá atravessaria as paredes na frente do jogador.
const DISTANCIA_DE_TELEPORTE: float = 4.0
const ANIMACAO_PADRAO: StringName = &"idle"
## Nem todos os clipes vêm marcados como loop no modelo, e sem isso o boneco congelava
## no último quadro.
const ANIMACOES_EM_LOOP: Array[StringName] = [&"idle", &"walk", &"sprint"]

var id_do_jogador: String = ""

@onready var _modelo: Node3D = $Modelo
@onready var _rotulo_do_nome: Label3D = $Nome
@onready var _reacao: ReacaoADano = $ReacaoADano

var _animacao: AnimationPlayer
var _posicao_alvo: Vector3
var _giro_alvo: float = 0.0
var _animacao_pedida: StringName = ANIMACAO_PADRAO
## Falso até chegar o primeiro estado. Antes disso ele não segue alvo nenhum, para não
## deslizar da origem da cena até onde o jogador realmente está.
var _recebeu_estado: bool = false

func _ready() -> void:
	add_to_group(GRUPO_DE_ALVOS)
	var animacoes: Array[Node] = _modelo.find_children("*", "AnimationPlayer", true, false)
	_animacao = animacoes[0] as AnimationPlayer
	for clipe in ANIMACOES_EM_LOOP:
		if _animacao.has_animation(clipe):
			_animacao.get_animation(clipe).loop_mode = Animation.LOOP_LINEAR
	_animacao.play(ANIMACAO_PADRAO)
	# Quem cria o fantoche define a posição depois de pôr na árvore, então o sopro de
	# chegada espera o fim do quadro para sair no lugar certo.
	_soltar_sopro.call_deferred()

func _physics_process(delta: float) -> void:
	if not _recebeu_estado:
		return
	var peso: float = minf(SUAVIDADE * delta, 1.0)
	global_position = global_position.lerp(_posicao_alvo, peso)
	_modelo.rotation.y = lerp_angle(_modelo.rotation.y, _giro_alvo, peso)

func definir_nome(nome: String) -> void:
	_rotulo_do_nome.text = nome

## Guarda o que a rede mandou. O primeiro estado posiciona direto; os seguintes viram o
## alvo que o _physics_process persegue.
func aplicar_estado(posicao: Vector3, giro: float, animacao: StringName) -> void:
	_posicao_alvo = posicao
	_giro_alvo = giro
	if not _recebeu_estado or global_position.distance_to(posicao) > DISTANCIA_DE_TELEPORTE:
		_recebeu_estado = true
		global_position = posicao
		_modelo.rotation.y = giro
	_tocar(animacao)

## Contrato de dano do jogo. O fantoche não tem vida: pisca, para o golpe aparecer na
## tela, e avisa por sinal.
func receber_dano(quantidade: int, origem: Node3D) -> void:
	if not _reacao.pode_levar_dano():
		return
	var posicao_de_quem_bateu: Vector3 = origem.global_position if origem != null else global_position
	_reacao.reagir(posicao_de_quem_bateu)
	hit_taken.emit(quantidade)

func sumir() -> void:
	_soltar_sopro()
	queue_free()

## Toca só quando o clipe muda, senão a animação recomeçaria a cada mensagem. Clipe que
## este modelo não tem vira a pose parada.
func _tocar(animacao: StringName) -> void:
	var clipe: StringName = animacao if _animacao.has_animation(animacao) else ANIMACAO_PADRAO
	if clipe == _animacao_pedida and _animacao.is_playing():
		return
	_animacao_pedida = clipe
	_animacao.play(clipe)

func _soltar_sopro() -> void:
	var pai: Node = get_parent()
	if pai == null:
		return
	EfeitoDeParticulas.soltar(CENA_DO_SOPRO, global_position + Vector3.UP * ALTURA_DO_SOPRO, COR_DO_SOPRO, QUANTIDADE_DO_SOPRO, pai)
