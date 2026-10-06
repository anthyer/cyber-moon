extends Node

## Gera a malha de navegação de uma fase e salva num .tres. É o "bake" do NavMesh.
##
##   godot --headless --path game res://scenes/utils/gerar_malha_de_navegacao.tscn -- res://scenes/levels/NOME.tscn
##
## Sem o caminho da fase, usa o playground. A fase precisa ter um nó RegiaoDeNavegacao,
## que guarda os limites do chão e o tamanho do personagem; este script só carrega a
## fase, manda a região calcular e salva. Depois de gerar pela primeira vez numa fase
## nova, aponte o navigation_mesh da região para o arquivo salvo.

const FASE_PADRAO: String = "res://scenes/levels/playground.tscn"
const PASTA_DAS_MALHAS: String = "res://resources/navigation/"

func _ready() -> void:
	var argumentos: PackedStringArray = OS.get_cmdline_user_args()
	var caminho_da_fase: String = argumentos[0] if not argumentos.is_empty() else FASE_PADRAO
	var cena: PackedScene = load(caminho_da_fase) as PackedScene
	if cena == null:
		push_error("Fase não encontrada: %s" % caminho_da_fase)
		get_tree().quit(1)
		return
	var fase: Node = cena.instantiate()
	add_child(fase)
	# Alguns quadros de física para as colisões entrarem no mundo antes da leitura.
	for quadro in 3:
		await get_tree().physics_frame

	var regioes: Array[Node] = fase.find_children("*", "NavigationRegion3D", true, false)
	var regiao: RegiaoDeNavegacao = regioes[0] as RegiaoDeNavegacao if not regioes.is_empty() else null
	if regiao == null:
		push_error("A fase %s não tem um nó RegiaoDeNavegacao." % caminho_da_fase)
		get_tree().quit(1)
		return

	var malha: NavigationMesh = regiao.gerar(fase)
	var destino: String = regiao.arquivo_da_malha
	if destino.is_empty():
		destino = PASTA_DAS_MALHAS + caminho_da_fase.get_file().get_basename() + ".tres"
	DirAccess.make_dir_recursive_absolute(destino.get_base_dir())
	var erro: Error = ResourceSaver.save(malha, destino)
	print("Malha de navegação de %s: %d polígonos, salva em %s (erro %d)" % [caminho_da_fase.get_file(), malha.get_polygon_count(), destino, erro])
	get_tree().quit()
