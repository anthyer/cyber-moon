class_name RegiaoDeNavegacao
extends NavigationRegion3D

## A região de navegação de uma fase, com o que o gerador precisa saber para refazer a
## malha: onde fica o chão e de que tamanho é o personagem.
##
## A malha de navegação (NavMesh) é o mapa de por onde os personagens podem andar. Ela é
## calculada uma vez, salva num .tres e carregada pronta; não é refeita com o jogo
## rodando. Toda vez que o mapa muda (prédio, cerca ou árvore que entra, sai ou muda de
## lugar), rode de novo o gerador:
##
##   godot --headless --path game res://scenes/utils/gerar_malha_de_navegacao.tscn -- res://scenes/levels/NOME.tscn
##
## Fase nova: ponha um nó destes na cena, ajuste limite_do_chao para cobrir o mapa, e rode
## o gerador com o caminho da fase. Nada mais é fixo no código.

## Onde a malha desta fase é salva. Vazio usa resources/navigation/<nome da cena>.tres.
@export_file("*.tres") var arquivo_da_malha: String = ""
## Retângulo do chão andável, em x e z. O chão das fases é um plano infinito de colisão,
## que o gerador não enxerga, então este retângulo é somado à geometria como chão.
@export var limite_do_chao: Rect2 = Rect2(-20.0, -20.0, 40.0, 40.0)
@export var altura_do_chao: float = 0.0

@export_group("Personagem")
## A cápsula de quem anda na malha: jogador, inimigos e NPCs usam raio 0,25 e altura 0,7.
## Com altura maior a malha some debaixo de copa de árvore e de beiral.
@export var raio_do_agente: float = 0.25
@export var altura_do_agente: float = 0.75
@export var degrau_maximo: float = 0.25
@export var inclinacao_maxima: float = 40.0

const CAMADA_MUNDO: int = 1
const TAMANHO_DA_CELULA: float = 0.125

## Calcula a malha a partir da colisão da camada "mundo" de tudo que está sob a raiz dada.
## Usa a colisão, e não as malhas visuais, porque é ela que diz por onde se passa.
func gerar(raiz: Node) -> NavigationMesh:
	var malha: NavigationMesh = NavigationMesh.new()
	malha.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	malha.geometry_collision_mask = CAMADA_MUNDO
	malha.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	malha.cell_size = TAMANHO_DA_CELULA
	malha.cell_height = TAMANHO_DA_CELULA
	malha.agent_radius = raio_do_agente
	malha.agent_height = altura_do_agente
	malha.agent_max_climb = degrau_maximo
	malha.agent_max_slope = inclinacao_maxima
	# Ilha de malha menor que isto (o topo de um canteiro) é descartada.
	malha.region_min_size = 8.0
	# Só a faixa perto do chão entra na conta. Sem isso sairia malha em cima de telhado,
	# e um destino poderia grudar lá. O que fica acima da cabeça do personagem não
	# atrapalha a passagem, então pode ficar de fora.
	malha.filter_baking_aabb = AABB(
		Vector3(limite_do_chao.position.x, altura_do_chao - 0.5, limite_do_chao.position.y),
		Vector3(limite_do_chao.size.x, altura_do_agente + 0.75, limite_do_chao.size.y))

	var geometria: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(malha, geometria, raiz)
	geometria.add_faces(_faces_do_chao(), Transform3D.IDENTITY)
	NavigationServer3D.bake_from_source_geometry_data(malha, geometria)
	return malha

## Dois triângulos cobrindo o chão do mapa, virados para cima.
func _faces_do_chao() -> PackedVector3Array:
	var a: Vector3 = Vector3(limite_do_chao.position.x, altura_do_chao, limite_do_chao.position.y)
	var b: Vector3 = Vector3(limite_do_chao.end.x, altura_do_chao, limite_do_chao.position.y)
	var c: Vector3 = Vector3(limite_do_chao.end.x, altura_do_chao, limite_do_chao.end.y)
	var d: Vector3 = Vector3(limite_do_chao.position.x, altura_do_chao, limite_do_chao.end.y)
	return PackedVector3Array([a, b, c, a, c, d])
