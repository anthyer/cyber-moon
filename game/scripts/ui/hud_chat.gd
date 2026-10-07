class_name HudChat
extends Control

## O chat na tela: o histórico no canto inferior esquerdo e o campo de texto.
##
## Tem dois estados. Fechado, que é o normal, ele só mostra as últimas mensagens, sem
## fundo, e some aos poucos quando ninguém fala, para não cobrir o jogo. Aberto, ganha o
## fundo escuro, mostra o histórico inteiro com rolagem e o campo recebe o teclado.
##
## Enquanto o campo está aberto o InputManager.teclado_capturado fica ligado: sem isso,
## digitar "wasd" numa mensagem andaria com o personagem. A tela não fala com a rede;
## ela só mostra o que o ChatManager guarda e entrega a ele o que o jogador escreveu.

const SEGUNDOS_ATE_SUMIR: float = 6.0
const SEGUNDOS_DO_FADE: float = 0.6
const LIMITE_DE_CARACTERES: int = 200

const COR_DO_NOME_DOS_OUTROS: Color = Color(0.2, 0.95, 1.0)
const COR_DO_MEU_NOME: Color = Color(1.0, 0.85, 0.3)
const COR_DO_SISTEMA: Color = Color(0.6, 0.66, 0.8)
const COR_DO_TEXTO: Color = Color(0.92, 0.95, 1.0)

@onready var painel: PanelContainer = %Painel
@onready var historico: RichTextLabel = %Historico
@onready var rotulo_de_status: Label = %Status
@onready var campo: LineEdit = %Campo

var _aberto: bool = false
var _segundos_sem_mensagem: float = SEGUNDOS_ATE_SUMIR
## O fundo escuro do estado aberto, tirado da cena, e o fundo vazio do estado fechado.
## O vazio tem as mesmas margens, para o texto não pular de lugar ao abrir e fechar.
var _fundo_aberto: StyleBox
var _fundo_fechado: StyleBoxEmpty
## Quadro em que o campo fechou. A tecla que fecha (Enter ou Esc) ainda conta como
## "acabou de ser pressionada" nesse quadro: sem esta marca, o mesmo Enter que envia
## reabriria o chat, e o mesmo Esc que fecha abriria o menu de pausa.
var _quadro_em_que_fechou: int = -10
var _devolver_o_teclado: bool = false
## Ligado ao abrir e desligado na primeira tecla nova. Enquanto ligado, a repetição da
## tecla que abriu o chat (T ou Enter segurado) é descartada, senão ela seria digitada
## no campo ou enviaria uma mensagem vazia.
var _descartando_repeticao: bool = false

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir, como a
	# HUD de status e o relógio.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fundo_aberto = painel.get_theme_stylebox(&"panel")
	_fundo_fechado = StyleBoxEmpty.new()
	for lado: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		_fundo_fechado.set_content_margin(lado, _fundo_aberto.get_content_margin(lado))
	campo.max_length = LIMITE_DE_CARACTERES
	campo.text_submitted.connect(_ao_enviar)
	campo.gui_input.connect(_ao_teclar_no_campo)
	campo.focus_exited.connect(_ao_perder_o_foco)
	ChatManager.message_added.connect(_ao_chegar_mensagem)
	NetworkManager.connected.connect(_atualizar_status)
	NetworkManager.disconnected.connect(_atualizar_status)
	for mensagem in ChatManager.historico:
		_escrever(mensagem)
	_aplicar_estado()
	_atualizar_status()

func _process(delta: float) -> void:
	# O teclado volta para o jogo só no quadro seguinte ao do fechamento, pelo motivo
	# explicado em _quadro_em_que_fechou.
	if _devolver_o_teclado and Engine.get_process_frames() > _quadro_em_que_fechou:
		_devolver_o_teclado = false
		InputManager.teclado_capturado = false

	if get_tree().paused:
		if _aberto:
			fechar()
		visible = false
		return
	visible = true

	if _aberto:
		if Input.is_action_just_pressed(&"ui_cancel"):
			fechar()
		return

	_segundos_sem_mensagem += delta
	var passou_do_tempo: float = _segundos_sem_mensagem - SEGUNDOS_ATE_SUMIR
	historico.modulate.a = 1.0 - clampf(passou_do_tempo / SEGUNDOS_DO_FADE, 0.0, 1.0)

	var fechou_agora: bool = Engine.get_process_frames() - _quadro_em_que_fechou <= 1
	if not fechou_agora and InputManager.abrir_chat_pressionado():
		abrir()

func abrir() -> void:
	if _aberto or get_tree().paused:
		return
	_aberto = true
	_devolver_o_teclado = false
	_descartando_repeticao = true
	InputManager.teclado_capturado = true
	_aplicar_estado()
	campo.clear()
	campo.grab_focus()

func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	_quadro_em_que_fechou = Engine.get_process_frames()
	_devolver_o_teclado = true
	# Fechar conta como atividade: o histórico fica à vista mais um pouco antes de sumir.
	_segundos_sem_mensagem = 0.0
	campo.clear()
	if campo.has_focus():
		campo.release_focus()
	_aplicar_estado()

## Tudo que muda entre aberto e fechado, num lugar só.
func _aplicar_estado() -> void:
	painel.add_theme_stylebox_override(&"panel", _fundo_aberto if _aberto else _fundo_fechado)
	campo.visible = _aberto
	# Fechado, o chat não pode roubar clique do jogo (o botão esquerdo é o ataque).
	# Aberto, o histórico precisa do mouse para rolar.
	var filtro: Control.MouseFilter = Control.MOUSE_FILTER_STOP if _aberto else Control.MOUSE_FILTER_IGNORE
	historico.mouse_filter = filtro
	var barra: VScrollBar = historico.get_v_scroll_bar()
	barra.mouse_filter = filtro
	barra.modulate.a = 1.0 if _aberto else 0.0
	if _aberto:
		historico.modulate.a = 1.0
	_atualizar_status()

func _ao_enviar(texto: String) -> void:
	var limpo: String = texto.strip_edges()
	if not limpo.is_empty():
		ChatManager.enviar(limpo)
	fechar()

func _ao_teclar_no_campo(evento: InputEvent) -> void:
	if not _descartando_repeticao or not (evento is InputEventKey):
		return
	if (evento as InputEventKey).echo:
		campo.accept_event()
	else:
		_descartando_repeticao = false

## Clicar fora do campo tira o foco dele. Um campo aberto sem foco prenderia o teclado
## sem o jogador conseguir digitar, então o chat fecha junto.
func _ao_perder_o_foco() -> void:
	if _aberto:
		fechar()

func _ao_chegar_mensagem(mensagem: Dictionary) -> void:
	_escrever(mensagem)
	_segundos_sem_mensagem = 0.0

func _escrever(mensagem: Dictionary) -> void:
	var texto: String = _sem_marcacao(String(mensagem.get("texto", "")))
	var linha: String = ""
	if mensagem.get("sistema", false):
		linha = "[color=#%s]%s[/color]" % [COR_DO_SISTEMA.to_html(false), texto]
	else:
		var cor_do_nome: Color = COR_DO_MEU_NOME if mensagem.get("minha", false) else COR_DO_NOME_DOS_OUTROS
		var nome: String = _sem_marcacao(String(mensagem.get("nome", "")))
		linha = "[color=#%s]%s:[/color] [color=#%s]%s[/color]" % [cor_do_nome.to_html(false), nome, COR_DO_TEXTO.to_html(false), texto]
	if historico.get_parsed_text().length() > 0:
		linha = "\n" + linha
	historico.append_text(linha)

## O histórico usa BBCode para as cores. Um colchete escrito pelo jogador não pode virar
## marcação, senão uma mensagem conseguiria pintar ou quebrar as seguintes.
func _sem_marcacao(texto: String) -> String:
	return texto.replace("[", "[lb]")

func _atualizar_status() -> void:
	if not NetworkManager.esta_conectado():
		rotulo_de_status.text = "Offline"
		rotulo_de_status.visible = true
	elif _aberto:
		rotulo_de_status.text = "Conectado como %s. Enter envia, Esc fecha." % NetworkManager.meu_nome
		rotulo_de_status.visible = true
	else:
		rotulo_de_status.visible = false
