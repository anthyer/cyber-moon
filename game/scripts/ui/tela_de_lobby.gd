class_name TelaDeLobby
extends Control

## O lobby da dungeon: quem está na equipe, quem está online para ser chamado, e o botão
## de entrar. Abre pelo portal da fazenda, que pede pelo EventBus.
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

@onready var rotulo_de_status: Label = %Status
@onready var lista_da_equipe: VBoxContainer = %ListaDaEquipe
@onready var lista_de_online: VBoxContainer = %ListaDeOnline
@onready var botao_entrar: Button = %BotaoEntrar
@onready var rotulo_de_espera: Label = %Espera
@onready var botao_sair_da_equipe: Button = %BotaoSairDaEquipe
@onready var botao_fechar: Button = %BotaoFechar

## Quem já recebeu convite desde a última mudança da sala. O servidor não avisa que o
## convite chegou, então é a tela que lembra, para o botão não ser clicado duas vezes.
var _convidados: Dictionary[String, bool] = {}

func _ready() -> void:
	visible = false
	botao_entrar.pressed.connect(_ao_pedir_para_entrar)
	botao_sair_da_equipe.pressed.connect(_ao_sair_da_equipe)
	botao_fechar.pressed.connect(fechar)
	EventBus.lobby_requested.connect(abrir)
	LobbyManager.room_changed.connect(_ao_mudar_a_sala)
	LobbyManager.room_closed.connect(_ao_mudar_a_sala)
	LobbyManager.invite_declined.connect(_ao_recusarem_o_convite)
	LobbyManager.dungeon_started.connect(fechar)
	NetworkManager.connected.connect(_redesenhar)
	NetworkManager.disconnected.connect(_redesenhar)
	NetworkManager.player_joined.connect(_ao_mudar_quem_esta_online)
	NetworkManager.player_left.connect(_ao_mudar_quem_esta_online)

func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed(&"ui_cancel"):
		fechar()

## Não abre por cima de uma tela que pausou o jogo, nem com o jogador caído.
func abrir() -> void:
	if visible or get_tree().paused or StatusManager.esta_desmaiado:
		return
	visible = true
	InputManager.teclado_capturado = true
	_redesenhar()

func fechar() -> void:
	if not visible:
		return
	visible = false
	InputManager.teclado_capturado = false
	get_viewport().gui_release_focus()

func _ao_pedir_para_entrar() -> void:
	LobbyManager.iniciar()

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
