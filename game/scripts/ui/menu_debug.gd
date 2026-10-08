class_name MenuDebug
extends Control

## Menu de debug para testar os sistemas do jogo sem esperar o tempo passar nem procurar
## itens: trocar a hora, encher a vida, amadurecer as plantas, criar inimigos e assim
## por diante. Abre e fecha com F3.
##
## Não pausa o jogo, de propósito: a graça é ver a luz mudar e os inimigos agirem
## enquanto se mexe nos controles. Fica em PROCESS_MODE_ALWAYS para funcionar também com
## o menu de pausa aberto.
##
## Os botões são montados em código, um método por ação, para ficar fácil de achar e de
## acrescentar uma ação nova. Tudo que o menu mexe na fase (jogador, grade de solo, luz)
## é procurado na hora do clique, com checagem de nulo, para o menu não quebrar numa fase
## que não tenha esse nó.

const HORA_MINIMA: float = 6.0
const HORA_MAXIMA: float = 25.0
const INTERVALO_DO_CONTADOR_DE_QUADROS: float = 0.25
## Onde o jogador vai ao pedir a área de inimigos: a faixa livre em z = -15 do playground.
const POSICAO_DA_AREA_DE_INIMIGOS: Vector3 = Vector3(0.0, 0.3, -15.0)
const DISTANCIA_DO_INIMIGO_CRIADO: float = 6.0

const CULTURAS: Array[String] = ["beterraba", "repolho", "cenoura", "milho", "tomate", "trigo"]
const ARMAS: Array[String] = ["cestos", "foice_curva", "bastao_choque", "espadao_sucata", "escopeta_serrada"]
const SUCATAS: Array[String] = ["sucata_metal", "placa_queimada", "celula_energia", "fio_optico", "servomotor", "nucleo_sintetico"]

const COLUNAS_DO_SUBMENU_DE_ITENS: int = 6
const TAMANHO_DO_BOTAO_DE_ITEM: Vector2 = Vector2(40.0, 40.0)
const QUANTIDADE_COM_SHIFT: int = 10
## O nome de cada categoria na ordem do enum Item.Categoria, para os títulos do submenu.
const NOMES_DAS_CATEGORIAS: Array[String] = ["Recursos", "Sementes", "Colheitas", "Ferramentas", "Armas", "Armaduras", "Consumíveis", "Materiais", "Especiais", "Acessórios"]

const CENA_DO_INIMIGO: String = "res://scenes/combat/inimigo.tscn"
const PERFIL_DO_DRONE: String = "res://resources/combat/inimigos/drone_rastejador.tres"
const PERFIL_DO_CIBORGUE: String = "res://resources/combat/inimigos/ciborgue_operario.tres"
const PERFIL_DA_SENTINELA: String = "res://resources/combat/inimigos/sentinela_pesada.tres"

@onready var painel: PanelContainer = %Painel
@onready var lista: VBoxContainer = %Lista
@onready var rotulo_de_quadros: Label = %RotuloDeQuadros

var _rotulo_do_relogio: Label
var _slider_de_hora: HSlider
var _rotulo_da_hora_do_slider: Label
var _caixa_congelar: CheckBox
var _caixa_invencivel: CheckBox
var _caixa_sombra: CheckBox
var _segundos_ate_atualizar_quadros: float = 0.0

func _ready() -> void:
	# A raiz ocupa a tela, mas não pode engolir o clique do mouse: quem recebe clique
	# são só os controles do painel.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	painel.visible = false
	rotulo_de_quadros.visible = false
	_montar_secoes()
	DayCycleManager.hour_changed.connect(_ao_mudar_hora.unbind(1))
	DayCycleManager.day_started.connect(_ao_mudar_hora.unbind(1))
	_ao_mudar_hora()

func _process(delta: float) -> void:
	if InputManager.menu_debug_pressionado():
		painel.visible = not painel.visible
		if painel.visible:
			_sincronizar_caixas()
	if rotulo_de_quadros.visible:
		_segundos_ate_atualizar_quadros -= delta
		if _segundos_ate_atualizar_quadros <= 0.0:
			_segundos_ate_atualizar_quadros = INTERVALO_DO_CONTADOR_DE_QUADROS
			rotulo_de_quadros.text = "%d quadros por segundo" % Engine.get_frames_per_second()

# ---------------------------------------------------------------------------
# Montagem do painel
# ---------------------------------------------------------------------------

func _montar_secoes() -> void:
	_novo_titulo_de_secao("Tempo")
	_rotulo_do_relogio = _novo_rotulo("")
	var linha_do_slider: HBoxContainer = HBoxContainer.new()
	_slider_de_hora = HSlider.new()
	_slider_de_hora.min_value = HORA_MINIMA
	_slider_de_hora.max_value = HORA_MAXIMA
	_slider_de_hora.step = 0.25
	_slider_de_hora.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider_de_hora.focus_mode = Control.FOCUS_NONE
	_slider_de_hora.value_changed.connect(_ao_mover_slider_de_hora)
	_rotulo_da_hora_do_slider = Label.new()
	_rotulo_da_hora_do_slider.custom_minimum_size = Vector2(46, 0)
	linha_do_slider.add_child(_slider_de_hora)
	linha_do_slider.add_child(_rotulo_da_hora_do_slider)
	lista.add_child(linha_do_slider)
	var atalhos: HBoxContainer = HBoxContainer.new()
	for hora in [6.0, 12.0, 18.0, 21.0, 24.5]:
		var botao: Button = _novo_botao_solto(_formatar_hora(hora), _ir_para_a_hora.bind(hora))
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		atalhos.add_child(botao)
	lista.add_child(atalhos)
	_novo_botao("Avançar um dia", _avancar_um_dia)
	_novo_botao("Pular para a próxima estação", _pular_para_a_proxima_estacao)
	_novo_botao("Abrir o calendário", _abrir_o_calendario)
	var climas: HBoxContainer = HBoxContainer.new()
	for clima in WeatherManager.CLIMAS:
		var botao_do_clima: Button = _novo_botao_solto(WeatherManager.perfil_do_clima(clima).nome_exibido, WeatherManager.definir_clima.bind(clima))
		botao_do_clima.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		climas.add_child(botao_do_clima)
	lista.add_child(climas)
	_novo_botao("Cair um raio agora", _cair_um_raio)
	_caixa_congelar = _nova_caixa("Congelar relógio", _ao_marcar_congelar)
	_novo_botao("Cair de sono agora", _cair_de_sono_agora)

	_novo_titulo_de_secao("Jogador")
	_novo_botao("Vida cheia", _encher_vida)
	_novo_botao("Stamina cheia", _encher_stamina)
	_novo_botao("Stamina quase zerada", _quase_zerar_stamina)
	_novo_botao("Tomar 20 de dano", _tomar_dano)
	_novo_botao("+100 de experiência", _ganhar_experiencia)
	_caixa_invencivel = _nova_caixa("Invencível", _ao_marcar_invencivel)
	_novo_botao("Voltar para casa", _voltar_para_casa)
	_novo_botao("Ir para a área de inimigos", _ir_para_a_area_de_inimigos)

	_novo_titulo_de_secao("Fazenda")
	_novo_botao("Molhar todo o solo", _molhar_todo_o_solo)
	_novo_botao("Amadurecer todas as plantas", _amadurecer_todas_as_plantas)
	_novo_botao("+10 de cada semente", _dar_sementes)

	_novo_titulo_de_secao("Itens")
	_montar_submenu_de_itens()
	_novo_botao("+5 pães", _dar_paes)
	_novo_botao("Todas as armas", _dar_todas_as_armas)
	_novo_botao("Soltar sucata no chão", _soltar_sucata)

	_novo_titulo_de_secao("Inimigos")
	_novo_botao("Criar drone perto", _criar_inimigo.bind(PERFIL_DO_DRONE))
	_novo_botao("Criar ciborgue perto", _criar_inimigo.bind(PERFIL_DO_CIBORGUE))
	_novo_botao("Criar sentinela perto", _criar_inimigo.bind(PERFIL_DA_SENTINELA))
	_novo_botao("Matar todos os inimigos", _matar_todos_os_inimigos)

	_novo_titulo_de_secao("Save")
	_novo_botao("Salvar agora", func() -> void: SaveManager.salvar_jogo())
	_novo_botao("Carregar agora", func() -> void: SaveManager.carregar_jogo())
	_novo_botao("Apagar o save (jogo novo ao reabrir)", SaveManager.apagar_save)

	_novo_titulo_de_secao("Economia")
	_novo_botao("+1000 créditos", func() -> void: EconomyManager.receber(1000))
	_novo_botao("Zerar créditos", func() -> void: EconomyManager.gastar(EconomyManager.creditos))
	_novo_botao("Contar +2000 em vendas (marcos)", _contar_vendas)
	_novo_botao("Abrir a loja da Marta", _abrir_loja.bind("marta"))
	_novo_botao("Abrir a loja do Vitor", _abrir_loja.bind("vitor"))

	_novo_titulo_de_secao("Amizade")
	_novo_botao("+1 coração com todos", _dar_um_coracao_a_todos)
	_novo_botao("Zerar amizades e namoro", _zerar_amizades)
	_novo_botao("Liberar o presente da semana", func() -> void: RelationshipManager.semana_do_ultimo_presente.clear())
	_novo_botao("+1 de cada item de presente", _dar_itens_de_presente)

	_novo_titulo_de_secao("Dungeon")
	_novo_botao("Abrir o lobby", func() -> void: EventBus.lobby_requested.emit())
	_novo_botao("Entrar sozinho agora", DungeonManager.entrar)
	_novo_botao("Sair da dungeon", DungeonManager.sair)

	_novo_titulo_de_secao("Tela")
	_nova_caixa("Mostrar quadros por segundo", _ao_marcar_quadros)
	_caixa_sombra = _nova_caixa("Sombra do sol", _ao_marcar_sombra)

func _novo_titulo_de_secao(texto: String) -> void:
	var titulo: Label = Label.new()
	titulo.text = texto
	titulo.add_theme_color_override(&"font_color", Color(0.2, 0.95, 1.0))
	lista.add_child(titulo)

func _novo_rotulo(texto: String) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	lista.add_child(rotulo)
	return rotulo

## Botões e caixas não pegam foco: assim as teclas de movimento continuam indo para o
## jogo mesmo depois de clicar num botão do menu.
func _novo_botao_solto(texto: String, acao: Callable) -> Button:
	var botao: Button = Button.new()
	botao.text = texto
	botao.focus_mode = Control.FOCUS_NONE
	botao.pressed.connect(acao)
	return botao

func _novo_botao(texto: String, acao: Callable) -> Button:
	var botao: Button = _novo_botao_solto(texto, acao)
	lista.add_child(botao)
	return botao

func _nova_caixa(texto: String, acao: Callable) -> CheckBox:
	var caixa: CheckBox = CheckBox.new()
	caixa.text = texto
	caixa.focus_mode = Control.FOCUS_NONE
	caixa.toggled.connect(acao)
	lista.add_child(caixa)
	return caixa

## As caixas mostram o estado real ao abrir o menu, porque ele pode ter mudado por fora
## (a sombra desligada em outro lugar, por exemplo). set_pressed_no_signal não dispara a
## ação, só acerta o desenho.
func _sincronizar_caixas() -> void:
	_caixa_congelar.set_pressed_no_signal(DayCycleManager.tempo_congelado)
	_caixa_invencivel.set_pressed_no_signal(StatusManager.invencivel_para_teste)
	var luz: DirectionalLight3D = _luz_do_sol()
	_caixa_sombra.disabled = luz == null
	if luz != null:
		_caixa_sombra.set_pressed_no_signal(luz.shadow_enabled)

# ---------------------------------------------------------------------------
# Tempo
# ---------------------------------------------------------------------------

func _ao_mudar_hora() -> void:
	_rotulo_do_relogio.text = "Dia %d, %s" % [DayCycleManager.numero_do_dia, DayCycleManager.hora_formatada()]
	_slider_de_hora.set_value_no_signal(DayCycleManager.hora_atual)
	_rotulo_da_hora_do_slider.text = DayCycleManager.hora_formatada()

func _ao_mover_slider_de_hora(hora: float) -> void:
	DayCycleManager.definir_hora(hora)

func _ir_para_a_hora(hora: float) -> void:
	DayCycleManager.definir_hora(hora)

func _avancar_um_dia() -> void:
	DayCycleManager.avancar_para_o_proximo_dia()

## Pula direto para o primeiro dia da próxima estação. Os dias do meio não acontecem:
## o contador anda até a véspera e só a última virada roda, então as plantas contam um
## dia só e a troca de estação dispara pelo caminho normal do day_started.
func _pular_para_a_proxima_estacao() -> void:
	DayCycleManager.numero_do_dia += SeasonManager.dias_ate_a_proxima_estacao() - 1
	DayCycleManager.avancar_para_o_proximo_dia()

## Pelo mesmo pedido que o quadro de calendário faz, para testar a tela de longe dele.
func _abrir_o_calendario() -> void:
	EventBus.calendar_requested.emit()

# Economia

## Soma ao total vendido sem dar créditos, para testar o desbloqueio dos marcos.
func _contar_vendas() -> void:
	EconomyManager.total_vendido += 2000
	EconomyManager._conferir_marcos()

## Abre a loja direto, sem conversar e sem olhar o horário.
func _abrir_loja(npc_id: String) -> void:
	var perfil: PerfilNpc = RelationshipManager.perfil_de(npc_id)
	if perfil != null and perfil.catalogo != null:
		EventBus.shop_requested.emit(perfil)

# Amizade

func _dar_um_coracao_a_todos() -> void:
	for perfil in ElencoDeNpcs.carregar_perfis():
		RelationshipManager.somar_pontos(perfil.id, RelationshipManager.PONTOS_POR_CORACAO)

func _zerar_amizades() -> void:
	RelationshipManager.namorando = ""
	for perfil in ElencoDeNpcs.carregar_perfis():
		RelationshipManager.somar_pontos(perfil.id, -RelationshipManager.PONTOS_MAXIMOS)

## Um de cada item que algum NPC ama, mais o buquê, para testar reação e namoro.
func _dar_itens_de_presente() -> void:
	InventoryManager.adicionar_item(load("res://resources/items/especiais/buque.tres") as Item, 1)
	for perfil in ElencoDeNpcs.carregar_perfis():
		for item in perfil.itens_amados:
			InventoryManager.adicionar_item(item, 1)

func _cair_um_raio() -> void:
	var cena: Node = get_tree().current_scene
	var raios: RaiosDaTempestade = cena.get_node_or_null("RaiosDaTempestade") as RaiosDaTempestade if cena != null else null
	if raios != null:
		raios.cair_um_raio()

func _ao_marcar_congelar(marcado: bool) -> void:
	DayCycleManager.tempo_congelado = marcado

## Um pouco antes da 1:00, para o próprio relógio disparar o sono forçado no quadro
## seguinte, pelo caminho normal.
func _cair_de_sono_agora() -> void:
	DayCycleManager.definir_hora(24.99)

## "07:30". A hora passa de 24 depois da meia-noite, e só na tela ela volta para 0.
func _formatar_hora(hora: float) -> String:
	var hora_do_relogio: float = fmod(hora, 24.0)
	var horas: int = int(hora_do_relogio)
	var minutos: int = int((hora_do_relogio - horas) * 60.0)
	return "%02d:%02d" % [horas, minutos]

# ---------------------------------------------------------------------------
# Jogador
# ---------------------------------------------------------------------------

func _encher_vida() -> void:
	StatusManager.curar(9999)

func _encher_stamina() -> void:
	StatusManager.recuperar_stamina(9999.0)

## Deixa 1 de stamina, para testar o desmaio no próximo golpe ou ação de fazenda.
func _quase_zerar_stamina() -> void:
	if StatusManager.stamina_atual > 1.0:
		StatusManager.gastar_stamina(StatusManager.stamina_atual - 1.0)

func _tomar_dano() -> void:
	StatusManager.receber_dano(20)

func _ganhar_experiencia() -> void:
	StatusManager.ganhar_experiencia(100)

func _ao_marcar_invencivel(marcado: bool) -> void:
	StatusManager.invencivel_para_teste = marcado

func _voltar_para_casa() -> void:
	var jogador: Node3D = _jogador()
	if jogador == null:
		return
	var cena: Node = get_tree().current_scene
	var ponto_de_spawn: Node3D = cena.get_node_or_null("PontoDeSpawn") as Node3D if cena != null else null
	# Sem ponto de spawn na fase, volta para a origem, que é onde o jogador nasce.
	var destino: Vector3 = ponto_de_spawn.global_position if ponto_de_spawn != null else Vector3(0.0, 0.5, 0.0)
	_teleportar(jogador, destino)

func _ir_para_a_area_de_inimigos() -> void:
	var jogador: Node3D = _jogador()
	if jogador != null:
		_teleportar(jogador, POSICAO_DA_AREA_DE_INIMIGOS)

## Zera a velocidade junto, senão um empurrão ou queda em andamento continua depois do
## teleporte.
func _teleportar(jogador: Node3D, destino: Vector3) -> void:
	jogador.global_position = destino
	if jogador is CharacterBody3D:
		(jogador as CharacterBody3D).velocity = Vector3.ZERO

# ---------------------------------------------------------------------------
# Fazenda
# ---------------------------------------------------------------------------

func _molhar_todo_o_solo() -> void:
	var grade: GradeSolo = _grade_de_solo()
	if grade != null:
		grade.molhar_todo_o_solo()

func _amadurecer_todas_as_plantas() -> void:
	var grade: GradeSolo = _grade_de_solo()
	if grade != null:
		grade.amadurecer_todas_as_plantas()

func _dar_sementes() -> void:
	for cultura in CULTURAS:
		_dar_item("res://resources/items/sementes/semente_%s.tres" % cultura, 10)

# ---------------------------------------------------------------------------
# Itens
# ---------------------------------------------------------------------------

func _dar_paes() -> void:
	_dar_item("res://resources/items/consumiveis/pao_de_trigo.tres", 5)

## Arma não empilha, então só entra a que o jogador ainda não tem, para o inventário não
## encher de cópias a cada clique.
func _dar_todas_as_armas() -> void:
	for arma in ARMAS:
		var item: Item = load("res://resources/items/armas/%s.tres" % arma) as Item
		if item != null and InventoryManager.obter_quantidade(item) == 0:
			InventoryManager.adicionar_item(item, 1)

func _soltar_sucata() -> void:
	var jogador: Node3D = _jogador()
	var cena: Node = get_tree().current_scene
	if jogador == null or cena == null:
		return
	for sucata in SUCATAS:
		var item: Item = load("res://resources/items/sucata/%s.tres" % sucata) as Item
		if item != null:
			ItemNoMundo.soltar(item, 1, jogador.global_position + Vector3(1.5, 0.0, 0.0), cena)

## O submenu com todos os itens do jogo: um botão por item, com o ícone dele, agrupados
## por categoria. Clicar põe um no inventário; com Shift, dez. A lista vem do
## CatalogoDeItens, então item novo aparece aqui sem mexer neste script.
func _montar_submenu_de_itens() -> void:
	var conteudo: VBoxContainer = VBoxContainer.new()
	conteudo.visible = false
	var abrir: Button = _novo_botao("Todos os itens (clique dá 1, Shift dá %d)" % QUANTIDADE_COM_SHIFT, func() -> void: conteudo.visible = not conteudo.visible)
	abrir.toggle_mode = true
	lista.add_child(conteudo)

	var por_categoria: Dictionary = {}
	for item in CatalogoDeItens.todos():
		if not por_categoria.has(item.categoria):
			por_categoria[item.categoria] = []
		por_categoria[item.categoria].append(item)
	for categoria: int in NOMES_DAS_CATEGORIAS.size():
		if not por_categoria.has(categoria):
			continue
		var titulo: Label = Label.new()
		titulo.text = NOMES_DAS_CATEGORIAS[categoria]
		titulo.add_theme_font_size_override(&"font_size", 12)
		titulo.add_theme_color_override(&"font_color", Color(0.6, 0.66, 0.8))
		conteudo.add_child(titulo)
		var grade: GridContainer = GridContainer.new()
		grade.columns = COLUNAS_DO_SUBMENU_DE_ITENS
		conteudo.add_child(grade)
		var itens: Array = por_categoria[categoria]
		itens.sort_custom(func(a: Item, b: Item) -> bool: return a.nome < b.nome)
		for item: Item in itens:
			grade.add_child(_novo_botao_de_item(item))

func _novo_botao_de_item(item: Item) -> Button:
	var botao: Button = Button.new()
	botao.focus_mode = Control.FOCUS_NONE
	botao.custom_minimum_size = TAMANHO_DO_BOTAO_DE_ITEM
	botao.icon = item.icone
	botao.expand_icon = true
	botao.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Pixel art: sem isso o ícone de 16 pixels fica borrado ao ser ampliado.
	botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	botao.tooltip_text = item.nome
	if item.icone == null:
		botao.text = item.nome.left(3)
	botao.pressed.connect(_dar_pelo_submenu.bind(item))
	return botao

func _dar_pelo_submenu(item: Item) -> void:
	var quantidade: int = QUANTIDADE_COM_SHIFT if Input.is_key_pressed(KEY_SHIFT) else 1
	var sobra: int = InventoryManager.adicionar_item(item, quantidade)
	if sobra > 0:
		EventBus.notice_requested.emit("Inventário cheio.")

func _dar_item(caminho: String, quantidade: int) -> void:
	var item: Item = load(caminho) as Item
	if item != null:
		InventoryManager.adicionar_item(item, quantidade)

# ---------------------------------------------------------------------------
# Inimigos
# ---------------------------------------------------------------------------

## O perfil entra antes de o inimigo ir para a árvore, porque o _ready dele já monta o
## modelo a partir do perfil.
func _criar_inimigo(caminho_do_perfil: String) -> void:
	var jogador: Node3D = _jogador()
	var cena: Node = get_tree().current_scene
	if jogador == null or cena == null:
		return
	var inimigo: Inimigo = (load(CENA_DO_INIMIGO) as PackedScene).instantiate() as Inimigo
	inimigo.perfil = load(caminho_do_perfil) as PerfilInimigo
	inimigo.position = jogador.global_position + _frente_do_jogador(jogador) * DISTANCIA_DO_INIMIGO_CRIADO
	cena.add_child(inimigo)

func _matar_todos_os_inimigos() -> void:
	var jogador: Node3D = _jogador()
	var cena: Node = get_tree().current_scene
	if cena == null:
		return
	# O filtro de tipo do find_children enxerga só classes do motor, e não o class_name
	# de um script, então a busca é por CharacterBody3D e o teste é com "is".
	for no in cena.find_children("*", "CharacterBody3D", true, false):
		var inimigo: Inimigo = no as Inimigo
		if inimigo != null and inimigo.esta_vivo():
			inimigo.receber_dano(99999, jogador)

## A frente é para onde o modelo do jogador está virado, e não a frente do corpo, que
## não gira.
func _frente_do_jogador(jogador: Node3D) -> Vector3:
	var personagem: Node3D = jogador.get_node_or_null("Personagem") as Node3D
	var angulo: float = personagem.rotation.y if personagem != null else 0.0
	return Vector3(sin(angulo), 0.0, cos(angulo))

# ---------------------------------------------------------------------------
# Tela
# ---------------------------------------------------------------------------

## O contador fica fora do painel, então continua na tela depois de fechar o menu.
func _ao_marcar_quadros(marcado: bool) -> void:
	rotulo_de_quadros.visible = marcado
	_segundos_ate_atualizar_quadros = 0.0

func _ao_marcar_sombra(marcado: bool) -> void:
	var luz: DirectionalLight3D = _luz_do_sol()
	if luz != null:
		luz.shadow_enabled = marcado

# ---------------------------------------------------------------------------
# Busca dos nós da fase
# ---------------------------------------------------------------------------

func _jogador() -> Node3D:
	return get_tree().get_first_node_in_group(&"jogador") as Node3D

func _grade_de_solo() -> GradeSolo:
	var cena: Node = get_tree().current_scene
	if cena == null:
		return null
	var grade: GradeSolo = cena.get_node_or_null("GradeSolo") as GradeSolo
	if grade != null:
		return grade
	for no in cena.find_children("*", "GridMap", true, false):
		if no is GradeSolo:
			return no as GradeSolo
	return null

func _luz_do_sol() -> DirectionalLight3D:
	var cena: Node = get_tree().current_scene
	if cena == null:
		return null
	return cena.get_node_or_null("Luz") as DirectionalLight3D
