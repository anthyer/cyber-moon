class_name AtaqueDoJogador
extends Node3D

## Cuida do que o golpe do jogador faz no mundo: mostra a arma na mão, aplica o dano em
## quem está na área de acerto e dispara o projétil da arma de distância. Quem decide
## quando atacar e qual animação tocar é o player.gd.
##
## Contrato de dano: quem pode levar dano tem o método
## receber_dano(quantidade: int, origem: Node3D). A área de acerto detecta o corpo de
## colisão e sobe pela árvore até o primeiro nó com esse método, do mesmo jeito que a
## AreaDeInteracao faz com interagir().

## As animações vêm prontas dentro do .glb e não aceitam marcação de quadro, então o
## golpe acerta numa fração da duração do clipe: entre estes dois pontos a arma está
## passando pela frente do corpo.
const INICIO_DA_JANELA_DE_ACERTO: float = 0.35
const FIM_DA_JANELA_DE_ACERTO: float = 0.65

const OSSO_DA_MAO: StringName = &"arm-right"
## Altura do centro da área de acerto, que é a altura do peito do personagem.
const ALTURA_DO_GOLPE: float = 0.3
## Distância à frente do jogador de onde saem o projétil e o laser.
const DISTANCIA_DA_BOCA_DA_ARMA: float = 0.4

@export var caminho_do_personagem: NodePath = ^"../Personagem"
@export var caminho_da_hitbox: NodePath = ^"../HitboxAtaque"

@export_group("Mira laser")
@export var cor_do_laser: Color = Color(1.0, 0.15, 0.2, 0.85)
@export var espessura_do_laser: float = 0.012
## O laser para no primeiro obstáculo destas camadas: mundo (1) e inimigo (8).
@export_flags_3d_physics var mascara_do_laser: int = 9

@onready var _personagem: Node3D = get_node(caminho_do_personagem)
@onready var _hitbox: Area3D = get_node(caminho_da_hitbox)
@onready var _forma_da_hitbox: CollisionShape3D = _hitbox.get_node("FormaHitbox")

var _suporte_da_mao: BoneAttachment3D
var _modelo_atual: Node3D
var _arma_do_modelo: Arma

var _feixe_do_laser: MeshInstance3D
var _ponto_do_laser: MeshInstance3D
## As duas bordas do cone, mostradas só na arma que dispara em leque.
var _bordas_do_cone: Array[MeshInstance3D] = []

var _arma_do_golpe: Arma
var _segundos_desde_o_golpe: float = 0.0
var _inicio_da_janela: float = 0.0
var _fim_da_janela: float = 0.0
var _ja_atingidos: Array[Node] = []
var _stamina_ja_cobrada: bool = false

func _ready() -> void:
	_criar_suporte_da_mao()
	_criar_mira_laser()

## A mira é só visual, então acompanha o quadro de desenho, e não o de física, para não
## tremer quando o personagem vira.
func _process(_delta: float) -> void:
	_atualizar_mira_laser()

func _physics_process(delta: float) -> void:
	if _arma_do_golpe == null:
		return
	_segundos_desde_o_golpe += delta
	if _segundos_desde_o_golpe >= _inicio_da_janela:
		_acertar_quem_esta_na_area()
	if _segundos_desde_o_golpe >= _fim_da_janela:
		_arma_do_golpe = null

## Começa um golpe corpo a corpo. A duração é a do clipe de animação já dividida pela
## velocidade em que ele vai tocar.
func executar_golpe(arma: Arma, duracao_do_clipe: float) -> void:
	_arma_do_golpe = arma
	_segundos_desde_o_golpe = 0.0
	_inicio_da_janela = duracao_do_clipe * INICIO_DA_JANELA_DE_ACERTO
	_fim_da_janela = duracao_do_clipe * FIM_DA_JANELA_DE_ACERTO
	_ja_atingidos.clear()
	_stamina_ja_cobrada = false
	_posicionar_hitbox(arma.alcance)

## Dispara a arma de distância na direção em que o personagem está virado. Arma com
## mais de um projétil por disparo solta todos de uma vez, espalhados por igual dentro
## do cone, como uma escopeta.
func disparar(arma: Arma) -> void:
	if arma.projetil == null:
		return
	var dono: Node3D = get_parent() as Node3D
	var estado_do_disparo: Dictionary = {}
	for direcao in _direcoes_do_cone(arma):
		Projetil.disparar(arma.projetil, _boca_da_arma(), direcao, arma, dono, estado_do_disparo, dono.get_parent())

## As direções dos projéteis de um disparo: uma só, reta, ou várias abertas em leque em
## torno da direção do personagem.
func _direcoes_do_cone(arma: Arma) -> Array[Vector3]:
	var centro: Vector3 = _direcao_do_personagem()
	var direcoes: Array[Vector3] = []
	var quantidade: int = maxi(arma.projeteis_por_disparo, 1)
	if quantidade == 1 or arma.abertura_do_cone_em_graus <= 0.0:
		direcoes.append(centro)
		return direcoes
	var meia_abertura: float = deg_to_rad(arma.abertura_do_cone_em_graus) * 0.5
	for indice in quantidade:
		var angulo: float = lerpf(-meia_abertura, meia_abertura, float(indice) / float(quantidade - 1))
		direcoes.append(centro.rotated(Vector3.UP, angulo))
	return direcoes

func _boca_da_arma() -> Vector3:
	var dono: Node3D = get_parent() as Node3D
	return dono.global_position + _direcao_do_personagem() * DISTANCIA_DA_BOCA_DA_ARMA + Vector3.UP * ALTURA_DO_GOLPE

## Troca o modelo preso na mão quando o item na mão muda. Item que não é arma, ou arma
## sem modelo, deixa a mão vazia.
func trocar_modelo(arma: Arma) -> void:
	if arma == _arma_do_modelo:
		return
	_arma_do_modelo = arma
	if _modelo_atual != null:
		_modelo_atual.queue_free()
		_modelo_atual = null
	if arma == null or arma.modelo == null or _suporte_da_mao == null:
		return
	_modelo_atual = arma.modelo.instantiate() as Node3D
	_suporte_da_mao.add_child(_modelo_atual)
	_modelo_atual.position = arma.posicao_do_modelo
	_modelo_atual.rotation_degrees = arma.rotacao_do_modelo_em_graus
	_modelo_atual.scale = arma.escala_do_modelo

## Cada feixe é uma caixa fina de 1 metro, esticada até o comprimento do laser, e o
## ponto é um cubinho onde o laser bate. Ficam desligados de qualquer nó que gire, e a
## posição é calculada a cada quadro. As bordas do cone são mais apagadas que o centro.
func _criar_mira_laser() -> void:
	var material: StandardMaterial3D = _material_do_laser(cor_do_laser)
	_feixe_do_laser = _novo_feixe("FeixeDoLaser", material)

	var cor_da_borda: Color = cor_do_laser
	cor_da_borda.a *= 0.45
	var material_da_borda: StandardMaterial3D = _material_do_laser(cor_da_borda)
	for nome in ["BordaEsquerdaDoCone", "BordaDireitaDoCone"]:
		_bordas_do_cone.append(_novo_feixe(nome, material_da_borda))

	var malha_do_ponto: BoxMesh = BoxMesh.new()
	malha_do_ponto.size = Vector3.ONE * espessura_do_laser * 4.0
	malha_do_ponto.material = material
	_ponto_do_laser = MeshInstance3D.new()
	_ponto_do_laser.name = "PontoDoLaser"
	_ponto_do_laser.mesh = malha_do_ponto
	_ponto_do_laser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ponto_do_laser.top_level = true
	_ponto_do_laser.visible = false
	add_child(_ponto_do_laser)

func _material_do_laser(cor: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = cor
	return material

func _novo_feixe(nome: String, material: StandardMaterial3D) -> MeshInstance3D:
	var malha: BoxMesh = BoxMesh.new()
	malha.size = Vector3(espessura_do_laser, espessura_do_laser, 1.0)
	malha.material = material
	var feixe: MeshInstance3D = MeshInstance3D.new()
	feixe.name = nome
	feixe.mesh = malha
	feixe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	feixe.top_level = true
	feixe.visible = false
	add_child(feixe)
	return feixe

## O laser sai do mesmo ponto e nas mesmas direções dos projéteis, então mostra
## exatamente por onde o tiro vai passar. Cada linha para no primeiro obstáculo ou no
## alcance da arma. Arma que dispara em leque mostra o centro e as duas bordas do cone.
func _atualizar_mira_laser() -> void:
	var arma: Arma = _arma_do_modelo
	var mostrar: bool = arma != null and arma.tem_mira_laser and not StatusManager.esta_desmaiado
	_feixe_do_laser.visible = false
	_ponto_do_laser.visible = false
	for borda in _bordas_do_cone:
		borda.visible = false
	if not mostrar:
		return

	var origem: Vector3 = _boca_da_arma()
	var fim_do_centro: Vector3 = _esticar_feixe(_feixe_do_laser, origem, _direcao_do_personagem(), arma.alcance)
	if fim_do_centro.distance_to(origem) < arma.alcance - 0.01:
		_ponto_do_laser.visible = true
		_ponto_do_laser.global_position = fim_do_centro

	var direcoes: Array[Vector3] = _direcoes_do_cone(arma)
	if direcoes.size() > 1:
		_esticar_feixe(_bordas_do_cone[0], origem, direcoes[0], arma.alcance)
		_esticar_feixe(_bordas_do_cone[1], origem, direcoes[direcoes.size() - 1], arma.alcance)

## Posiciona o feixe da origem até o primeiro obstáculo na direção, ou até o alcance, e
## devolve o ponto onde ele termina.
func _esticar_feixe(feixe: MeshInstance3D, origem: Vector3, direcao: Vector3, alcance: float) -> Vector3:
	var dono: CollisionObject3D = get_parent() as CollisionObject3D
	var fim: Vector3 = origem + direcao * alcance
	var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origem, fim, mascara_do_laser)
	consulta.exclude = [dono.get_rid()]
	var acerto: Dictionary = get_world_3d().direct_space_state.intersect_ray(consulta)
	if not acerto.is_empty():
		fim = acerto.position
	var comprimento: float = origem.distance_to(fim)
	feixe.visible = comprimento >= 0.01
	if feixe.visible:
		feixe.global_transform = Transform3D(Basis.looking_at(direcao, Vector3.UP), (origem + fim) * 0.5)
		feixe.scale = Vector3(1.0, 1.0, comprimento)
	return fim

## O osso da mão fica dentro da cena do personagem, que vem pronta do .glb, então o
## suporte que segue o osso é criado em código em vez de ser um nó da cena do jogador.
func _criar_suporte_da_mao() -> void:
	var esqueletos: Array[Node] = _personagem.find_children("*", "Skeleton3D", true, false)
	if esqueletos.is_empty():
		push_warning("AtaqueDoJogador: o personagem não tem Skeleton3D, a arma não aparece na mão.")
		return
	_suporte_da_mao = BoneAttachment3D.new()
	_suporte_da_mao.name = "MaoDireita"
	esqueletos[0].add_child(_suporte_da_mao)
	_suporte_da_mao.bone_name = OSSO_DA_MAO

## A área de acerto é uma esfera à frente do jogador que chega até o alcance da arma e
## não pega quem está atrás dele.
func _posicionar_hitbox(alcance: float) -> void:
	var raio: float = alcance * 0.5
	(_forma_da_hitbox.shape as SphereShape3D).radius = raio
	_hitbox.position = _direcao_do_personagem() * raio + Vector3.UP * ALTURA_DO_GOLPE

func _direcao_do_personagem() -> Vector3:
	var rotacao: float = _personagem.rotation.y
	return Vector3(sin(rotacao), 0.0, cos(rotacao))

func _acertar_quem_esta_na_area() -> void:
	var dono: Node3D = get_parent() as Node3D
	for corpo in _hitbox.get_overlapping_bodies() + _hitbox.get_overlapping_areas():
		var alvo: Node = _quem_leva_dano(corpo)
		if alvo == null or alvo == dono or _ja_atingidos.has(alvo):
			continue
		_ja_atingidos.append(alvo)
		alvo.call(&"receber_dano", _arma_do_golpe.dano, dono)
		_cobrar_stamina_do_acerto()

## O golpe só gasta stamina quando acerta um oponente, e uma vez só, mesmo que pegue
## vários de uma vez. Com menos stamina que o custo, gasta o que resta.
func _cobrar_stamina_do_acerto() -> void:
	if _stamina_ja_cobrada:
		return
	_stamina_ja_cobrada = true
	StatusManager.gastar_stamina(minf(_arma_do_golpe.custo_de_stamina, StatusManager.stamina_atual))

func _quem_leva_dano(corpo: Node) -> Node:
	var no: Node = corpo
	while no != null:
		if no.has_method(&"receber_dano"):
			return no
		no = no.get_parent()
	return null
