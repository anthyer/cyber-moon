class_name TelaDeLobby
extends Control

## O lobby da dungeon: quem está na equipe, quem está online para ser chamado, qual
## dungeon, e o botão de entrar. Abre pelo portal da fazenda, que pede pelo EventBus.
##
## Diferente do calendário e do inventário, esta tela NÃO pausa o jogo. Pausar pararia a
## árvore, e a rede precisa continuar andando para o convite ir e a resposta voltar. No
## lugar da pausa ela liga InputManager.teclado_capturado, e o personagem fica parado
## porque o gameplay deixa de ler a entrada.
##
## A tela não guarda estado de sala: ela só desenha o que o LobbyManager e o
## NetworkManager dizem, e redesenha quando eles avisam que algo mudou.

const COR_DO_TEXTO: Color = Color(0.92, 0.95, 1.0)
const COR_DO_TEXTO_APAGADO: Color = Color(0.6, 0.66, 0.8)
const COR_DO_ANFITRIAO: Color = Color(0.2, 0.95, 1.0)
const TAMANHO_DA_DESCRICAO: int = 12
const LARGURA_DA_DESCRICAO: float = 380.0

@onready var rotulo_de_status: Label = %Status
@onready var lista_da_equipe: VBoxContainer = %ListaDaEquipe
@onready var lista_de_online: VBoxContainer = %ListaDeOnline
@onready var lista_de_dungeons: VBoxContainer = %ListaDeDungeons
@onready var botao_entrar: Button = %BotaoEntrar
@onready var rotulo_de_espera: Label = %Espera
@onready var botao_sair_da_equipe: Button = %BotaoSairDaEquipe
@onready var botao_fechar: Button = %BotaoFechar

## Quem já recebeu convite desde a última mudança da sala. O servidor não avisa que o
## convite chegou, então é a tela que lembra, para o botão não ser clicado duas vezes.
var _convidados: Dictionary[String, bool] = {}
## O id da dungeon escolhida. Vazio até a tela abrir, quando vira a última liberada. Fica
## guardado entre os redesenhos, porque a lista de botões é refeita a cada um.
var _dungeon_escolhida: StringName = &""

func _ready() -> void:
	visible = false
	botao_entrar.pressed.connect(_ao_pedir_para_entrar)
	botao_sair_da_equipe.pressed.connect(_ao_sair_da_equipe)
	botao_fechar.pressed.connect(fechar)
	EventBus.lobby_requested.connect(abrir)
	LobbyManager.room_changed.connect(_ao_mudar_a_sala)
	LobbyManager.room_closed.connect(_ao_mudar_a_sala)
	LobbyManager.invite_declined.connect(_ao_recusarem_o_convite)
	LobbyManager.dungeon_started.connect(fechar.unbind(1))
	NetworkManager.connected.connect(_redesenhar)
	NetworkManager.disconnected.connect(_redesenhar)
	NetworkManager.player_joined.connect(_ao_mudar_quem_esta_online)
	NetworkManager.player_left.connect(_ao_mudar_quem_esta_online)

func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed(&"ui_cancel"):
		fechar()

## Não abre por cima de uma tela que pausou o jogo, nem com o jogador caído.
## Vindo da entrada de uma dungeon, a escolha já é a dela. Entrada de dungeon ainda
## trancada não abre a tela: avisa o que falta para abrir.
func abrir(dungeon_id: StringName = &"") -> void:
	if visible or get_tree().paused or StatusManager.esta_desmaiado:
		return
	var definicao: DefinicaoDeDungeon = DungeonManager.definicao_de(dungeon_id) if dungeon_id != &"" else null
	if definicao != null and not DungeonManager.esta_liberada(definicao):
		var anterior: DefinicaoDeDungeon = DungeonManager.definicao_de(definicao.requer)
		var falta: String = anterior.nome if anterior != null else "a dungeon anterior"
		EventBus.notice_requested.emit("A entrada de %s está trancada. Vença o chefe de %s primeiro." % [definicao.nome, falta])
		return
	visible = true
	InputManager.teclado_capturado = true
	# Sem entrada definida (o menu de debug), a escolha volta para a última dungeon
	# liberada: é a que o jogador mais provavelmente quer.
	_dungeon_escolhida = definicao.id if definicao != null else _ultima_liberada()
	_redesenhar()

func fechar() -> void:
	if not visible:
		return
	visible = false
	InputManager.teclado_capturado = false
	get_viewport().gui_release_focus()

func _ao_pedir_para_entrar() -> void:
	LobbyManager.iniciar(String(_dungeon_escolhida))

func _ao_sair_da_equipe() -> void:
	LobbyManager.sair()

## A sala mudou (alguém entrou, saiu, ou ela acabou): os convites antigos não valem mais
## como "pendentes", e quem não entrou pode ser chamado de novo.
func _ao_mudar_a_sala() -> void:
	_convidados.clear()
	_redesenhar()

func _ao_mudar_quem_esta_online(_id: String, _nome: String) -> void:
	_redesenhar()

func _ao_recusarem_o_convite(nome: String) -> void:
	EventBus.notice_requested.emit("%s recusou o convite." % nome)
	# Não dá para saber o id de quem recusou por este sinal, então todos os botões
	# voltam a "Convidar". É raro ter dois convites no ar ao mesmo tempo.
	_convidados.clear()
	_redesenhar()

func _ao_convidar(id: String) -> void:
	LobbyManager.convidar(id)
	_convidados[id] = true
	_redesenhar()

func _redesenhar() -> void:
	if not visible:
		return
	if NetworkManager.esta_conectado():
		rotulo_de_status.text = "Conectado como %s" % NetworkManager.meu_nome
	else:
		rotulo_de_status.text = "Offline: dá para entrar sozinho"
	_redesenhar_equipe()
	_redesenhar_online()
	_redesenhar_dungeons()

	var sou_anfitriao: bool = LobbyManager.sou_anfitriao()
	botao_entrar.visible = sou_anfitriao
	rotulo_de_espera.visible = not sou_anfitriao
	botao_sair_da_equipe.visible = LobbyManager.esta_em_sala()
	_dar_foco()

func _redesenhar_equipe() -> void:
	_esvaziar(lista_da_equipe)
	if not LobbyManager.esta_em_sala():
		lista_da_equipe.add_child(_novo_rotulo("Você", COR_DO_TEXTO))
		return
	for membro: Dictionary in LobbyManager.membros:
		var id: String = membro["id"]
		var texto: String = membro["nome"]
		if id == NetworkManager.meu_id:
			texto += " (você)"
		var e_anfitriao: bool = id == LobbyManager.anfitriao
		if e_anfitriao:
			texto += ", anfitrião"
		lista_da_equipe.add_child(_novo_rotulo(texto, COR_DO_ANFITRIAO if e_anfitriao else COR_DO_TEXTO))

func _redesenhar_online() -> void:
	_esvaziar(lista_de_online)
	var algum: bool = false
	for id: String in NetworkManager.online:
		if _esta_na_equipe(id):
			continue
		algum = true
		lista_de_online.add_child(_nova_linha_de_online(id, NetworkManager.online[id]))
	if not algum:
		lista_de_online.add_child(_novo_rotulo("Ninguém online.", COR_DO_TEXTO_APAGADO))

func _nova_linha_de_online(id: String, nome: String) -> HBoxContainer:
	var linha: HBoxContainer = HBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 12)
	var rotulo: Label = _novo_rotulo(nome, COR_DO_TEXTO)
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo)
	# Só o anfitrião convida, para a sala ter um dono só. Quem está sozinho é anfitrião
	# da sala que o primeiro convite vai criar.
	if LobbyManager.sou_anfitriao():
		var botao: Button = Button.new()
		botao.custom_minimum_size = Vector2(110.0, 0.0)
		if _convidados.has(id):
			botao.text = "Convidado"
			botao.disabled = true
		else:
			botao.text = "Convidar"
			botao.pressed.connect(_ao_convidar.bind(id))
		linha.add_child(botao)
	return linha

## Um botão por dungeon, na ordem do DungeonManager. A liberada é um botão de alternar,
## num grupo, para só uma ficar marcada. A trancada fica desabilitada e diz o que falta.
## Quem escolhe é o anfitrião: o convidado vê a lista, mas com os botões desabilitados.
func _redesenhar_dungeons() -> void:
	_esvaziar(lista_de_dungeons)
	var grupo: ButtonGroup = ButtonGroup.new()
	var pode_escolher: bool = LobbyManager.sou_anfitriao()
	for definicao in DungeonManager.definicoes():
		var liberada: bool = DungeonManager.esta_liberada(definicao)
		var botao: Button = Button.new()
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.text = definicao.nome
		if DungeonManager.chefe_ja_foi_vencido(definicao.id):
			botao.text += " (chefe vencido)"
		botao.toggle_mode = true
		botao.button_group = grupo
		botao.disabled = not liberada or not pode_escolher
		botao.set_pressed_no_signal(liberada and definicao.id == _dungeon_escolhida)
		botao.pressed.connect(_ao_escolher_dungeon.bind(definicao.id))
		lista_de_dungeons.add_child(botao)
		var texto: String = definicao.descricao
		if not liberada:
			var anterior: DefinicaoDeDungeon = DungeonManager.definicao_de(definicao.requer)
			texto = "Trancada: vença o chefe de %s" % (anterior.nome if anterior != null else "outra dungeon")
		if texto != "":
			var descricao: Label = _novo_rotulo(texto, COR_DO_TEXTO_APAGADO)
			descricao.add_theme_font_size_override(&"font_size", TAMANHO_DA_DESCRICAO)
			descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			descricao.custom_minimum_size = Vector2(LARGURA_DA_DESCRICAO, 0.0)
			lista_de_dungeons.add_child(descricao)

## Só guarda a escolha. A lista não é redesenhada aqui, para o foco não sair do botão que
## acabou de ser apertado; o grupo de botões já cuida de desmarcar o outro.
func _ao_escolher_dungeon(id: StringName) -> void:
	_dungeon_escolhida = id

## O id da última dungeon liberada, na ordem do lobby, ou vazio quando não há nenhuma.
func _ultima_liberada() -> StringName:
	var ultima: StringName = &""
	for definicao in DungeonManager.definicoes():
		if DungeonManager.esta_liberada(definicao):
			ultima = definicao.id
	return ultima

func _esta_na_equipe(id: String) -> bool:
	for membro: Dictionary in LobbyManager.membros:
		if membro["id"] == id:
			return true
	return false

## As listas são refeitas a cada redesenho, e o botão que tinha o foco pode ter sumido.
## Para o controle não ficar sem ter onde navegar, o foco volta para o botão mais útil
## do rodapé, a não ser que ainda esteja num botão vivo da tela.
func _dar_foco() -> void:
	var com_foco: Control = get_viewport().gui_get_focus_owner()
	if com_foco != null and is_ancestor_of(com_foco) and not com_foco.is_queued_for_deletion():
		return
	if botao_entrar.visible:
		botao_entrar.grab_focus()
	else:
		botao_fechar.grab_focus()

func _esvaziar(lista: VBoxContainer) -> void:
	for filho in lista.get_children():
		lista.remove_child(filho)
		filho.queue_free()

func _novo_rotulo(texto: String, cor: Color) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override(&"font_size", 15)
	rotulo.add_theme_color_override(&"font_color", cor)
	return rotulo
