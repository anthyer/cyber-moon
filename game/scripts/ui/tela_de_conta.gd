class_name TelaDeConta
extends Control

## A conta online do jogador: entrar, criar conta e sair.
##
## Mora dentro da tela do lobby, que abre esta tela pelo botão "Conta" e volta a
## aparecer quando ela fecha. Por isso não liga InputManager.teclado_capturado: o lobby
## já ligou, e continua aberto por baixo.
##
## A tela não fala com o Cognito; quem fala é o AccountManager. Ela só entrega o que o
## jogador digitou e mostra o que volta pelos sinais. A conta é só nome de usuário e
## senha (plano 38), e a tela tem dois modos, um por vez: entrar ou criar conta, e já
## logado.
##
## O visual é o painel ciano do Theme, com cara de terminal de acesso. O erro aparece em
## âmbar, e não em vermelho: o jogo não usa vermelho nem para dano.

## Avisa o lobby que a tela fechou, para ele aparecer de novo.
signal closed

@onready var formulario_de_entrada: VBoxContainer = %FormularioDeEntrada
@onready var campo_usuario: LineEdit = %CampoUsuario
@onready var campo_senha: LineEdit = %CampoSenha
@onready var botao_entrar: Button = %BotaoEntrar
@onready var botao_criar_conta: Button = %BotaoCriarConta
@onready var painel_logado: VBoxContainer = %PainelLogado
@onready var rotulo_da_conta: Label = %RotuloDaConta
@onready var botao_sair_da_conta: Button = %BotaoSairDaConta
@onready var rotulo_de_status: Label = %Status
@onready var botao_voltar: Button = %BotaoVoltar

func _ready() -> void:
	visible = false
	rotulo_da_conta.add_theme_color_override(&"font_color", CoresDaInterface.ciano())
	botao_entrar.pressed.connect(_ao_entrar)
	botao_criar_conta.pressed.connect(_ao_criar_conta)
	botao_sair_da_conta.pressed.connect(AccountManager.sair)
	botao_voltar.pressed.connect(fechar)
	# Enter no campo da senha entra na conta.
	campo_senha.text_submitted.connect(_ao_entrar.unbind(1))
	AccountManager.logged_in.connect(_ao_entrar_na_conta)
	AccountManager.logged_out.connect(_ao_sair_da_conta)
	AccountManager.request_failed.connect(_mostrar_status.bind(true))
	NetworkManager.connected.connect(_ao_conectar)

## Enquanto uma requisição está no ar, os botões ficam desabilitados, para o jogador não
## mandar a mesma coisa duas vezes.
func _process(_delta: float) -> void:
	if not visible:
		return
	for botao: Button in [botao_entrar, botao_criar_conta, botao_sair_da_conta]:
		botao.disabled = AccountManager.ocupado
	if Input.is_action_just_pressed(&"ui_cancel"):
		fechar()

func abrir() -> void:
	visible = true
	_mostrar_status("")
	_mostrar_modo()

func fechar() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _ao_entrar() -> void:
	var usuario: String = campo_usuario.text.strip_edges()
	if usuario == "" or campo_senha.text == "":
		_mostrar_status("Digite o nome de usuário e a senha.", true)
		return
	_mostrar_status("Entrando...")
	AccountManager.entrar(usuario, campo_senha.text)

## O AccountManager confere o nome e, se der certo, já entra na conta criada.
func _ao_criar_conta() -> void:
	var usuario: String = campo_usuario.text.strip_edges()
	if usuario == "" or campo_senha.text == "":
		_mostrar_status("Para criar conta, escolha um nome de usuário e uma senha.", true)
		return
	_mostrar_status("Criando a conta...")
	AccountManager.criar_conta(usuario, campo_senha.text)

func _ao_entrar_na_conta() -> void:
	campo_senha.clear()
	_mostrar_modo()
	_mostrar_status("Conectando com a conta...")

## Entrar na conta reconecta. Quando o servidor responde, troca o "Conectando..." pelo
## nome com que o jogo entrou.
func _ao_conectar() -> void:
	if not visible or not AccountManager.esta_logado():
		return
	_mostrar_status("Conectado como %s." % NetworkManager.meu_nome)

func _ao_sair_da_conta() -> void:
	_mostrar_modo()
	_mostrar_status("Você saiu da conta.")

## Mostra o formulário que vale agora e põe o foco nele, para o controle e o teclado
## terem onde começar.
func _mostrar_modo() -> void:
	var logado: bool = AccountManager.esta_logado()
	painel_logado.visible = logado
	formulario_de_entrada.visible = not logado
	if logado:
		rotulo_da_conta.text = AccountManager.nome_da_conta
		botao_sair_da_conta.grab_focus()
	else:
		campo_usuario.grab_focus()

func _mostrar_status(texto: String, erro: bool = false) -> void:
	rotulo_de_status.text = texto
	rotulo_de_status.add_theme_color_override(&"font_color", CoresDaInterface.ambar() if erro else CoresDaInterface.texto_apagado())
