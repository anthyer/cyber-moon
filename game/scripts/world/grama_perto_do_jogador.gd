class_name GramaPertoDoJogador
extends Node3D

## Graminha que só existe perto do jogador, no enquadramento da câmera.
##
## Cada tufo é um punhado de folhas finas de geometria opaca, feito uma vez aqui mesmo,
## e repetido por MultiMesh.
##
## O chão em volta do jogador é dividido em pedaços de 4 por 4. Cada pedaço visível ganha
## um MultiMesh de tufos (uma chamada de desenho para o pedaço inteiro) e é apagado quando
## sai de perto. A posição de cada tufo sai de um sorteio com a semente do pedaço, então
## a grama de um lugar é sempre a mesma: andar para longe e voltar não a embaralha.
##
## Onde nasce grama vem de uma máscara (vermelho é a densidade, verde a umidade), gravada
## pelo script do terreno: nada na água, nas trilhas e na praça; mais verde perto do rio.
## Sem máscara (a fazenda), nasce em todo lugar, menos nos talhões.

@export var material: ShaderMaterial
## A máscara do mapa, com um pixel por unidade, começando em (0, 0) no canto noroeste.
@export var mascara: Texture2D
## Umidade usada quando não há máscara.
@export_range(0.0, 1.0) var umidade_sem_mascara: float = 0.0
@export var tufos_por_metro_quadrado: float = 5.0
@export var altura_do_tufo: float = 0.32
@export var folhas_por_tufo: int = 7
@export var tamanho_do_pedaco: float = 4.0
## Quanto a grama vai para cada lado do jogador. A câmera vê mais para o norte do que
## para o sul, então o alcance também.
@export var alcance_para_os_lados: float = 11.0
@export var alcance_para_o_norte: float = 13.0
@export var alcance_para_o_sul: float = 7.0
## Pedaços novos por quadro, no máximo. Espalha o trabalho e evita engasgo ao correr.
@export var pedacos_por_quadro: int = 3

## A camada "chao" (a 10): só o terreno e o chão da fazenda.
const CAMADA_DO_CHAO: int = 512
## Chão mais inclinado que isto (barranco) não ganha grama.
const INCLINACAO_MAXIMA: float = 0.75

var _pedacos: Dictionary[Vector2i, MultiMeshInstance3D] = {}
var _malha: ArrayMesh
var _imagem: Image

func _ready() -> void:
	_malha = _montar_tufo()
	if mascara != null:
		_imagem = mascara.get_image()
		if _imagem != null and _imagem.is_compressed():
			_imagem.decompress()

## Um tufo: folhas triangulares finas saindo do centro, cada uma inclinada para um lado.
## A cor do vértice guarda a altura relativa na folha, que o shader usa para o vento e o
## degradê.
func _montar_tufo() -> ArrayMesh:
	var sorteio: RandomNumberGenerator = RandomNumberGenerator.new()
	sorteio.seed = 7
	var vertices: PackedVector3Array = PackedVector3Array()
	var cores: PackedColorArray = PackedColorArray()
	var normais: PackedVector3Array = PackedVector3Array()
	for folha in folhas_por_tufo:
		var angulo: float = TAU * folha / folhas_por_tufo + sorteio.randf_range(-0.3, 0.3)
		var direcao: Vector3 = Vector3(cos(angulo), 0.0, sin(angulo))
		var lado: Vector3 = Vector3(-direcao.z, 0.0, direcao.x)
		var base: Vector3 = direcao * sorteio.randf_range(0.0, 0.06)
		var altura: float = altura_do_tufo * sorteio.randf_range(0.6, 1.15)
		var ponta: Vector3 = base + direcao * altura * sorteio.randf_range(0.25, 0.55) + Vector3.UP * altura
		var largura: float = sorteio.randf_range(0.022, 0.034)
		vertices.append_array([base - lado * largura, base + lado * largura, ponta])
		cores.append_array([Color(0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0), Color(1.0, 0.0, 0.0)])
		var normal: Vector3 = (Vector3.UP + direcao * 0.3).normalized()
		normais.append_array([normal, normal, normal])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = cores
	arrays[Mesh.ARRAY_NORMAL] = normais
	var malha: ArrayMesh = ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	malha.surface_set_material(0, material)
	return malha

func _physics_process(_delta: float) -> void:
	var jogador: Node3D = get_tree().get_first_node_in_group(&"jogador") as Node3D
	if jogador == null or not is_visible_in_tree():
		return
	var local: Vector3 = to_local(jogador.global_position)
	var minimo: Vector2i = _pedaco_de(Vector2(local.x - alcance_para_os_lados, local.z - alcance_para_o_norte))
	var maximo: Vector2i = _pedaco_de(Vector2(local.x + alcance_para_os_lados, local.z + alcance_para_o_sul))
	var criados: int = 0
	for px in range(minimo.x, maximo.x + 1):
		for pz in range(minimo.y, maximo.y + 1):
			var chave: Vector2i = Vector2i(px, pz)
			if not _pedacos.has(chave) and criados < pedacos_por_quadro:
				_pedacos[chave] = _criar_pedaco(chave)
				criados += 1
	for chave: Vector2i in _pedacos.keys():
		if chave.x < minimo.x - 1 or chave.x > maximo.x + 1 or chave.y < minimo.y - 1 or chave.y > maximo.y + 1:
			_pedacos[chave].queue_free()
			_pedacos.erase(chave)

func _pedaco_de(ponto: Vector2) -> Vector2i:
	return Vector2i(floori(ponto.x / tamanho_do_pedaco), floori(ponto.y / tamanho_do_pedaco))

func _criar_pedaco(chave: Vector2i) -> MultiMeshInstance3D:
	var sorteio: RandomNumberGenerator = RandomNumberGenerator.new()
	sorteio.seed = hash(chave) ^ hash(name)
	var espaco: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var talhoes: Array[Node] = []
	if _imagem == null:
		talhoes = get_tree().get_nodes_in_group(TalhaoDeCultivo.GRUPO)
	var tentativas: int = int(tamanho_do_pedaco * tamanho_do_pedaco * tufos_por_metro_quadrado)
	var transformacoes: Array[Transform3D] = []
	var dados: Array[Color] = []
	for indice in tentativas:
		var x: float = (chave.x + sorteio.randf()) * tamanho_do_pedaco
		var z: float = (chave.y + sorteio.randf()) * tamanho_do_pedaco
		var densidade: float = 1.0
		var umidade: float = umidade_sem_mascara
		if _imagem != null:
			var px: int = clampi(int(x), 0, _imagem.get_width() - 1)
			var pz: int = clampi(int(z), 0, _imagem.get_height() - 1)
			var amostra: Color = _imagem.get_pixel(px, pz)
			densidade = amostra.r if x >= 0.0 and z >= 0.0 and x < _imagem.get_width() and z < _imagem.get_height() else 0.0
			umidade = amostra.g
		elif _dentro_de_talhao(x, z, talhoes):
			densidade = 0.0
		var tom: float = sorteio.randf()
		var fase: float = sorteio.randf()
		var escala: float = sorteio.randf_range(0.75, 1.3)
		if sorteio.randf() > densidade:
			continue
		var no_mundo: Vector3 = to_global(Vector3(x, 0.0, z))
		var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(no_mundo + Vector3.UP * 4.0, no_mundo + Vector3.DOWN * 6.0, CAMADA_DO_CHAO)
		var acerto: Dictionary = espaco.intersect_ray(consulta)
		if acerto.is_empty() or (acerto["normal"] as Vector3).y < INCLINACAO_MAXIMA:
			continue
		var y: float = to_local(acerto["position"] as Vector3).y
		transformacoes.append(Transform3D(Basis().scaled(Vector3.ONE * escala), Vector3(x, y, z)))
		dados.append(Color(tom, umidade, fase, 0.0))
	var multi: MultiMesh = MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_custom_data = true
	multi.mesh = _malha
	multi.instance_count = transformacoes.size()
	for indice in transformacoes.size():
		multi.set_instance_transform(indice, transformacoes[indice])
		multi.set_instance_custom_data(indice, dados[indice])
	var desenho: MultiMeshInstance3D = MultiMeshInstance3D.new()
	desenho.multimesh = multi
	desenho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(desenho)
	return desenho

func _dentro_de_talhao(x: float, z: float, talhoes: Array[Node]) -> bool:
	for no in talhoes:
		var talhao: TalhaoDeCultivo = no as TalhaoDeCultivo
		var canto: Vector3 = to_local(talhao.global_position)
		var tamanho: Vector2 = Vector2(talhao.tamanho_em_celulas)
		if x > canto.x - 0.4 and x < canto.x + tamanho.x + 0.4 and z > canto.z - 0.4 and z < canto.z + tamanho.y + 0.4:
			return true
	return false
