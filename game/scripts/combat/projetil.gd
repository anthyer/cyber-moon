class_name Projetil
extends Area3D

## Um disparo que viaja em linha reta até acertar alguma coisa ou cansar.
##
## É projétil de verdade, e não um raio instantâneo, porque dá para ver, dá para errar
## e é mais fácil de depurar. Some ao bater em qualquer corpo ou área que não seja de
## quem disparou, e some sozinho depois de um tempo para não voar para sempre.
##
## Contrato de dano do jogo: quem leva dano tem o método
## receber_dano(quantidade: int, origem: Node3D). O projétil sobe pela árvore a partir
## do que acertou até achar um nó com esse método.

const SEGUNDOS_DE_VIDA: float = 3.0

var dano: int = 0
var velocidade: float = 18.0
var direcao: Vector3 = Vector3.FORWARD
## Quem disparou. O projétil ignora o dono e os filhos dele, para o tiro do jogador não
## acertar o jogador e, mais tarde, o do inimigo não acertar o inimigo.
var dono: Node3D
## O golpe só gasta stamina quando acerta um oponente, então o custo viaja com o
## projétil e é cobrado no acerto, e não no disparo.
var custo_de_stamina: float = 0.0

var _segundos_restantes: float = SEGUNDOS_DE_VIDA

## Cria o projétil já configurado, coloca no pai e posiciona na origem.
static func disparar(cena: PackedScene, origem: Vector3, direcao_do_tiro: Vector3, dano_do_tiro: int, velocidade_do_tiro: float, dono_do_tiro: Node3D, custo: float, pai: Node) -> Projetil:
	var projetil: Projetil = cena.instantiate() as Projetil
	projetil.dano = dano_do_tiro
	projetil.velocidade = velocidade_do_tiro
	projetil.direcao = direcao_do_tiro
	projetil.dono = dono_do_tiro
	projetil.custo_de_stamina = custo
	pai.add_child(projetil)
	projetil.global_position = origem
	return projetil

func _ready() -> void:
	direcao = direcao.normalized()
	body_entered.connect(_ao_acertar)
	area_entered.connect(_ao_acertar)

func _physics_process(delta: float) -> void:
	global_position += direcao * velocidade * delta
	_segundos_restantes -= delta
	if _segundos_restantes <= 0.0:
		queue_free()

func _ao_acertar(corpo: Node3D) -> void:
	if _eh_do_dono(corpo):
		return
	var alvo: Node = _alvo_que_leva_dano(corpo)
	if alvo != null:
		alvo.call(&"receber_dano", dano, dono)
		if custo_de_stamina > 0.0:
			# Com pouca stamina o tiro ainda acerta, e cobra só o que o jogador tem.
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
