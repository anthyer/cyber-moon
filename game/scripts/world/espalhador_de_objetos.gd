class_name EspalhadorDeObjetos
extends Node3D

## Espalha cópias de um modelo numa área retangular: cactos, pedras, capim.
##
## As cópias são desenhadas de uma vez só, com um MultiMeshInstance3D por malha do modelo.
## Cem cactos assim custam o mesmo que um no desenho, enquanto cem instâncias da cena
## custariam cem. É o que deixa o deserto cheio sem pesar.
##
## As posições saem de um sorteio com semente fixa: o mesmo espalhador gera sempre o mesmo
## deserto, nos dois jogos e em toda vez que o jogo abre. A colisão, quando pedida, é um
## cilindro simples por cópia, e não a malha inteira.

## A cena do modelo (um .glb importado).
@export var modelo: PackedScene
@export var quantidade: int = 20
## Tamanho da área, centrada no nó, em x e z.
@export var tamanho_da_area: Vector2 = Vector2(20.0, 20.0)
@export var semente: int = 1
@export var escala_minima: float = 0.85
@export var escala_maxima: float = 1.2
## Distância mínima entre duas cópias. Sorteio que cai perto demais de outra é descartado.
@export var distancia_minima: float = 1.5
## Retângulos (em x e z, no espaço deste nó) onde nada é posto: estrada, praça, talhão.
@export var areas_livres: Array[Rect2] = []
## Círculos livres, cada um como (x, z, raio) no espaço deste nó. Servem para caminho
## curvo (uma trilha vira uma fileira de círculos), que retângulo não acompanha.
@export var circulos_livres: PackedVector3Array = PackedVector3Array()
## Posições prontas, cada uma como (x, z, graus) no espaço deste nó. Com elas não há
## sorteio de lugar (só de tamanho): serve para a borda dos corredores, que segue uma linha.
@export var posicoes_fixas: PackedVector3Array = PackedVector3Array()
## Com o chão em relevo, cada cópia desce (ou sobe) até o chão por um raio. Sem isto, as
## cópias ficam todas na altura do nó.
@export var seguir_o_chao: bool = false

@export_group("Colisão")
## Zero deixa as cópias sem colisão (capim, mancha de chão).
@export var raio_da_colisao: float = 0.0
@export var altura_da_colisao: float = 1.5

@export_group("Desenho")
@export var projeta_sombra: bool = true
## A partir desta distância da câmera as cópias somem. Zero mantém sempre visível.
@export var some_a_partir_de: float = 0.0

const CAMADA_MUNDO: int = 1
## A camada "chao" (a 10), onde as cópias procuram o chão.
const CAMADA_CHAO: int = 512
## Quantas vezes tentar achar lugar para cada cópia antes de desistir dela.
const TENTATIVAS_POR_COPIA: int = 12

func _ready() -> void:
	if modelo == null:
		push_warning("EspalhadorDeObjetos sem modelo: %s" % name)
		return
	var posicoes: Array[Transform3D] = _sortear_posicoes() if posicoes_fixas.is_empty() else _usar_posicoes_fixas()
	if seguir_o_chao:
		# O chão é um corpo de física, que só responde a raio depois do primeiro quadro de
		# física. Por isso as cópias esperam um quadro para descer até ele.
		await get_tree().physics_frame
		_assentar_no_chao(posicoes)
	_montar_desenho(posicoes)
	if raio_da_colisao > 0.0:
		_montar_colisao(posicoes)

func _sortear_posicoes() -> Array[Transform3D]:
	var sorteio: RandomNumberGenerator = RandomNumberGenerator.new()
	sorteio.seed = semente
	var resultado: Array[Transform3D] = []
	var pontos: Array[Vector2] = []
	var metade: Vector2 = tamanho_da_area * 0.5
	for copia in quantidade:
		for tentativa in TENTATIVAS_POR_COPIA:
			var ponto: Vector2 = Vector2(sorteio.randf_range(-metade.x, metade.x), sorteio.randf_range(-metade.y, metade.y))
			if not _lugar_livre(ponto, pontos):
				continue
			pontos.append(ponto)
			var escala: float = sorteio.randf_range(escala_minima, escala_maxima)
			var giro: Basis = Basis(Vector3.UP, sorteio.randf() * TAU).scaled(Vector3.ONE * escala)
			resultado.append(Transform3D(giro, Vector3(ponto.x, 0.0, ponto.y)))
			break
	return resultado

func _usar_posicoes_fixas() -> Array[Transform3D]:
	var sorteio: RandomNumberGenerator = RandomNumberGenerator.new()
	sorteio.seed = semente
	var resultado: Array[Transform3D] = []
	for posicao in posicoes_fixas:
		var escala: float = sorteio.randf_range(escala_minima, escala_maxima)
		var giro: Basis = Basis(Vector3.UP, deg_to_rad(posicao.z)).scaled(Vector3.ONE * escala)
		resultado.append(Transform3D(giro, Vector3(posicao.x, 0.0, posicao.y)))
	return resultado

func _lugar_livre(ponto: Vector2, ocupados: Array[Vector2]) -> bool:
	for area in areas_livres:
		if area.has_point(ponto):
			return false
	for circulo in circulos_livres:
		if Vector2(circulo.x, circulo.y).distance_to(ponto) < circulo.z:
			return false
	for outro in ocupados:
		if outro.distance_to(ponto) < distancia_minima:
			return false
	return true

func _assentar_no_chao(posicoes: Array[Transform3D]) -> void:
	var espaco: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	for indice in posicoes.size():
		var no_mundo: Vector3 = global_transform * posicoes[indice].origin
		var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(no_mundo + Vector3.UP * 6.0, no_mundo + Vector3.DOWN * 8.0, CAMADA_CHAO)
		var acerto: Dictionary = espaco.intersect_ray(consulta)
		if not acerto.is_empty():
			posicoes[indice].origin.y = (acerto["position"] as Vector3).y - global_position.y

## Um MultiMeshInstance3D por malha do modelo, cada um com a posição da malha dentro do
## modelo somada à posição da cópia.
func _montar_desenho(posicoes: Array[Transform3D]) -> void:
	var exemplo: Node3D = modelo.instantiate() as Node3D
	for no in exemplo.find_children("*", "MeshInstance3D", true, false):
		var malha: MeshInstance3D = no as MeshInstance3D
		var dentro_do_modelo: Transform3D = _transformacao_ate(malha, exemplo)
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = malha.mesh
		multi.instance_count = posicoes.size()
		for indice in posicoes.size():
			multi.set_instance_transform(indice, posicoes[indice] * dentro_do_modelo)
		var desenho: MultiMeshInstance3D = MultiMeshInstance3D.new()
		desenho.name = "Copias_%s" % malha.name
		desenho.multimesh = multi
		desenho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if projeta_sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if some_a_partir_de > 0.0:
			desenho.visibility_range_end = some_a_partir_de
		add_child(desenho)
	exemplo.free()

func _transformacao_ate(no: Node3D, raiz: Node3D) -> Transform3D:
	var resultado: Transform3D = Transform3D.IDENTITY
	var atual: Node = no
	while atual != null and atual != raiz:
		if atual is Node3D:
			resultado = (atual as Node3D).transform * resultado
		atual = atual.get_parent()
	return resultado

## Um corpo só, com um cilindro por cópia. Fica na camada do mundo, que é a que a malha de
## navegação lê.
func _montar_colisao(posicoes: Array[Transform3D]) -> void:
	var corpo: StaticBody3D = StaticBody3D.new()
	corpo.name = "Colisao"
	corpo.collision_layer = CAMADA_MUNDO
	corpo.collision_mask = 0
	add_child(corpo)
	for posicao in posicoes:
		var escala: float = posicao.basis.get_scale().x
		var forma: CylinderShape3D = CylinderShape3D.new()
		forma.radius = raio_da_colisao * escala
		forma.height = altura_da_colisao * escala
		var no_da_forma: CollisionShape3D = CollisionShape3D.new()
		no_da_forma.shape = forma
		no_da_forma.position = posicao.origin + Vector3.UP * forma.height * 0.5
		corpo.add_child(no_da_forma)
