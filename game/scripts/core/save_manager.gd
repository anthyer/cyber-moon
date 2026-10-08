extends Node

## Salva e carrega o jogo inteiro, num arquivo JSON em user://.
##
## Este autoload não conhece o interior de ninguém. Cada sistema sabe exportar e importar
## o próprio estado, com dois métodos:
##
##   func exportar_estado() -> Dictionary
##   func importar_estado(dados: Dictionary) -> void
##
## O SaveManager só junta os dicionários, um por sistema, e grava. Os autoloads estão na
## lista abaixo; os nós da fase (a grade de solo, o jogador, os baús) entram pelo grupo
## "salvaveis" e dizem a própria chave com chave_de_save(). Sistema novo entra no save
## acrescentando uma linha na lista, ou pondo o nó no grupo.
##
## O jogo salva sozinho quando o dia começa (dormir, cair de sono ou desmaiar) e ao fechar
## a janela, e carrega ao abrir, se houver save. O arquivo tem uma versão: quem importa
## usa valor padrão para o que faltar, então um save antigo abre num jogo mais novo.

signal game_saved
signal game_loaded

const CAMINHO_DO_SAVE: String = "user://save_game.json"
const VERSAO: int = 1
const GRUPO_DOS_SALVAVEIS: StringName = &"salvaveis"
## Abrir o jogo com este argumento ignora o save e não grava nada. Serve para teste e para
## abrir dois jogos na mesma máquina sem um atropelar o save do outro:
## godot --path game -- --sem-save
const ARGUMENTO_SEM_SAVE: String = "--sem-save"
const CENA_DO_BRILHO: PackedScene = preload("res://scenes/effects/poeira_de_passo.tscn")
const COR_DO_BRILHO: Color = Color(0.4, 1.0, 0.55)

## Falso com --sem-save: nada é lido nem gravado sozinho.
var ativo: bool = true

func _ready() -> void:
	ativo = not OS.get_cmdline_user_args().has(ARGUMENTO_SEM_SAVE)
	# O pedido de fechar a janela passa por aqui antes, para dar tempo de salvar.
	get_tree().auto_accept_quit = false
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)
	if ativo and existe_save():
		_carregar_quando_a_fase_estiver_pronta.call_deferred()

func _notification(o_que: int) -> void:
	if o_que == NOTIFICATION_WM_CLOSE_REQUEST:
		if ativo:
			salvar_jogo()
		get_tree().quit()

func existe_save() -> bool:
	return FileAccess.file_exists(CAMINHO_DO_SAVE)

func apagar_save() -> void:
	if existe_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CAMINHO_DO_SAVE))

func salvar_jogo() -> bool:
	var dados: Dictionary = {"versao": VERSAO}
	for chave: String in _autoloads_salvos():
		dados[chave] = _autoloads_salvos()[chave].call(&"exportar_estado")
	for no in get_tree().get_nodes_in_group(GRUPO_DOS_SALVAVEIS):
		dados[no.call(&"chave_de_save")] = no.call(&"exportar_estado")
	var arquivo: FileAccess = FileAccess.open(CAMINHO_DO_SAVE, FileAccess.WRITE)
	if arquivo == null:
		push_error("Não foi possível abrir o arquivo de save para escrita: %s" % error_string(FileAccess.get_open_error()))
		return false
	arquivo.store_string(JSON.stringify(dados, "\t"))
	game_saved.emit()
	return true

func carregar_jogo() -> bool:
	if not existe_save():
		return false
	var arquivo: FileAccess = FileAccess.open(CAMINHO_DO_SAVE, FileAccess.READ)
	if arquivo == null:
		push_error("Não foi possível abrir o arquivo de save para leitura: %s" % error_string(FileAccess.get_open_error()))
		return false
	var lido: Variant = JSON.parse_string(arquivo.get_as_text())
	if not lido is Dictionary:
		push_error("O arquivo de save está corrompido e foi ignorado.")
		return false
	var dados: Dictionary = lido
	# A ordem da lista importa: o dia vem antes de quem depende dele, e o inventário antes
	# de quem aponta para os slots dele. Sistema sem dados no arquivo (save antigo) recebe
	# um dicionário vazio e fica com os valores padrão.
	for chave: String in _autoloads_salvos():
		_autoloads_salvos()[chave].call(&"importar_estado", dados.get(chave, {}))
	for no in get_tree().get_nodes_in_group(GRUPO_DOS_SALVAVEIS):
		no.call(&"importar_estado", dados.get(no.call(&"chave_de_save"), {}))
	# Quem mostra o estado na tela (relógio, luz, NPCs) se atualiza por este sinal.
	EventBus.game_loaded.emit()
	game_loaded.emit()
	return true

## Os autoloads que têm estado para salvar, na ordem em que são importados.
func _autoloads_salvos() -> Dictionary:
	return {
		"dia": DayCycleManager,
		"jogo": GameManager,
		"clima": WeatherManager,
		"status": StatusManager,
		"inventario": InventoryManager,
		"equipamento": EquipmentManager,
		"economia": EconomyManager,
		"amizade": RelationshipManager,
		"dialogo": DialogueManager,
	}

## Os nós da fase só existem depois de a cena entrar na árvore, o que acontece depois do
## _ready dos autoloads. Dois quadros bastam para todos terem passado pelo próprio _ready.
func _carregar_quando_a_fase_estiver_pronta() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	carregar_jogo()

## O jogo salva quando o dia começa: é o momento em que o jogador acabou de dormir (ou de
## cair), como em Stardew Valley. Salvar a qualquer hora deixaria desfazer escolhas.
func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	if not ativo:
		return
	# Um quadro depois, para todos os sistemas terem terminado a própria virada do dia.
	await get_tree().process_frame
	if salvar_jogo():
		EventBus.notice_requested.emit("Jogo salvo.")
		_soltar_brilho()

## O aviso visível de que salvou: um brilho verde em volta do jogador.
func _soltar_brilho() -> void:
	var jogador: Node3D = get_tree().get_first_node_in_group(&"jogador") as Node3D
	if jogador != null and get_tree().current_scene != null:
		EfeitoDeParticulas.soltar(CENA_DO_BRILHO, jogador.global_position + Vector3.UP * 0.5, COR_DO_BRILHO, 20, get_tree().current_scene)
