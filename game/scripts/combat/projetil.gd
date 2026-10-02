class_name Projetil
extends Area3D

## Um disparo que viaja em linha reta até acertar alguma coisa ou chegar ao alcance.
##
## É projétil de verdade, e não um raio instantâneo, porque dá para ver, dá para errar
## e é mais fácil de depurar. Some ao bater em qualquer corpo ou área que não seja de
## quem disparou, some ao percorrer o alcance da arma, e por garantia some depois de
## um tempo para não voar para sempre.
##
## Contrato de dano do jogo: quem leva dano tem o método
## receber_dano(quantidade: int, origem: Node3D). O projétil sobe pela árvore a partir
## do que acertou até achar um nó com esse método.

const SEGUNDOS_DE_VIDA: float = 3.0
## Camadas mundo (1) e jogador (2): o tiro do inimigo para na parede e acerta o jogador.
const MASCARA_DO_TIRO_DE_INIMIGO: int = 3
## O tiro do inimigo é lento e feito para ser desviado, então é maior para ser visto.
const ESCALA_DO_TIRO_DE_INIMIGO: float = 1.8

var dano: int = 0
var velocidade: float = 18.0
var direcao: Vector3 = Vector3.FORWARD
## Quem disparou. O projétil ignora o dono e os filhos dele, para o tiro do jogador não
## acertar o jogador e, mais tarde, o do inimigo não acertar o inimigo.
var dono: Node3D
## O golpe só gasta stamina quando acerta um oponente, então o custo viaja com o
## projétil e é cobrado no acerto, e não no disparo.
var custo_de_stamina: float = 0.0
## Distância máxima que o projétil percorre. Zero deixa só o limite de tempo.
var alcance: float = 0.0
## Estado dividido entre os projéteis do mesmo disparo. Uma escopeta solta vários de
## uma vez, e a stamina do disparo é cobrada uma vez só, não uma por projétil.
var disparo: Dictionary = {}

var _segundos_restantes: float = SEGUNDOS_DE_VIDA
var _distancia_percorrida: float = 0.0

## Cria o projétil já configurado, coloca no pai e posiciona na origem.
static func disparar(cena: PackedScene, origem: Vector3, direcao_do_tiro: Vector3, arma: Arma, dono_do_tiro: Node3D, estado_do_disparo: Dictionary, pai: Node) -> Projetil:
	var projetil: Projetil = cena.instantiate() as Projetil
	projetil.dano = arma.dano
	projetil.velocidade = arma.velocidade_do_projetil
	projetil.alcance = arma.alcance
	projetil.direcao = direcao_do_tiro
	projetil.dono = dono_do_tiro
	projetil.custo_de_stamina = arma.custo_de_stamina
	projetil.disparo = estado_do_disparo
	pai.add_child(projetil)
	projetil.global_position = origem
	return projetil

## Disparo de inimigo. Usa a mesma cena, mas procura o jogador em vez dos inimigos, não
## cobra stamina de ninguém, e sai tingido para o jogador saber de quem é o tiro.
static func disparar_de_inimigo(cena: PackedScene, origem: Vector3, direcao_do_tiro: Vector3, dano_do_tiro: int, velocidade_do_tiro: float, alcance_do_tiro: float, cor: Color, dono_do_tiro: Node3D, pai: Node) -> Projetil:
	var projetil: Projetil = cena.instantiate() as Projetil
	projetil.dano = dano_do_tiro
	projetil.velocidade = velocidade_do_tiro
	projetil.alcance = alcance_do_tiro
	projetil.direcao = direcao_do_tiro
	projetil.dono = dono_do_tiro
	projetil.collision_mask = MASCARA_DO_TIRO_DE_INIMIGO
	projetil._tingir(cor)
	pai.add_child(projetil)
	projetil.global_position = origem
	return projetil

## O material da cena é dividido por todos os projéteis, então tingir troca por uma
## cópia só deste.
func _tingir(cor: Color) -> void:
	var visual: MeshInstance3D = get_node_or_null(^"Visual") as MeshInstance3D
	if visual == null:
		return
	var material: StandardMaterial3D = (visual.mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	material.albedo_color = cor
	visual.material_override = material
	visual.scale = Vector3.ONE * ESCALA_DO_TIRO_DE_INIMIGO

func _ready() -> void:
	direcao = direcao.normalized()
	body_entered.connect(_ao_acertar)
	area_entered.connect(_ao_acertar)

func _physics_process(delta: float) -> void:
	var passo: float = velocidade * delta
	global_position += direcao * passo
	_distancia_percorrida += passo
	_segundos_restantes -= delta
	if _segundos_restantes <= 0.0 or (alcance > 0.0 and _distancia_percorrida >= alcance):
		queue_free()

func _ao_acertar(corpo: Node3D) -> void:
	if _eh_do_dono(corpo):
		return
	var alvo: Node = _alvo_que_leva_dano(corpo)
	if alvo != null:
		alvo.call(&"receber_dano", dano, dono)
		if custo_de_stamina > 0.0 and not disparo.get(&"stamina_cobrada", false):
			# Com pouca stamina o tiro ainda acerta, e cobra só o que o jogador tem.
			disparo[&"stamina_cobrada"] = true
			StatusManager.gastar_stamina(minf(custo_de_stamina, StatusManager.stamina_atual))
	queue_free()

func _eh_do_dono(no: Node) -> bool:
	if dono == null or not is_instance_valid(dono):
		return false
	return no == dono or dono.is_ancestor_of(no)

func _alvo_que_leva_dano(corpo: Node) -> Node:
	var no: Node = corpo
	while no != null:
		if no.has_method(&"receber_dano"):
			return no
		no = no.get_parent()
	return null
