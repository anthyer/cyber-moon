class_name TelaDeConta
extends Control

## A conta online do jogador: entrar, criar conta, confirmar o código do e-mail e sair.
##
## Mora dentro da tela do lobby, que abre esta tela pelo botão "Conta" e volta a
## aparecer quando ela fecha. Por isso não liga InputManager.teclado_capturado: o lobby
## já ligou, e continua aberto por baixo.
##
## A tela não fala com o Cognito; quem fala é o AccountManager. Ela só entrega o que o
## jogador digitou e mostra o que volta pelos sinais. A mesma tela tem três modos, e só
## um aparece por vez: entrar ou criar conta, digitar o código, e já logado.

## Avisa o lobby que a tela fechou, para ele aparecer de novo.
signal closed

## Amarelo, e não vermelho: o jogo não usa vermelho nem para dano.
const COR_DO_ERRO: Color = Color(1.0, 0.8, 0.3)
const COR_DO_STATUS: Color = Color(0.6, 0.66, 0.8)

@onready var formulario_de_entrada: VBoxContainer = %FormularioDeEntrada
@onready var campo_email: LineEdit = %CampoEmail
@onready var campo_senha: LineEdit = %CampoSenha
@onready var campo_nome: LineEdit = %CampoNome
@onready var botao_entrar: Button = %BotaoEntrar
@onready var botao_criar_conta: Button = %BotaoCriarConta
@onready var formulario_de_codigo: VBoxContainer = %FormularioDeCodigo
@onready var rotulo_do_codigo: Label = %RotuloDoCodigo
@onready var campo_codigo: LineEdit = %CampoCodigo
@onready var botao_confirmar: Button = %BotaoConfirmar
@onready var painel_logado: VBoxContainer = %PainelLogado
@onready var rotulo_da_conta: Label = %RotuloDaConta
@onready var botao_sair_da_conta: Button = %BotaoSairDaConta
@onready var rotulo_de_status: Label = %Status
@onready var botao_voltar: Button = %BotaoVoltar

## O e-mail da conta criada que ainda espera o código. Vazio quando não há nenhuma.
var _email_esperando_codigo: String = ""

func _ready() -> void:
	visible = false
	botao_entrar.pressed.connect(_ao_entrar)
	botao_criar_conta.pressed.connect(_ao_criar_conta)
	botao_confirmar.pressed.connect(_ao_confirmar)
	botao_sair_da_conta.pressed.connect(AccountManager.sair)
	botao_voltar.pressed.connect(fechar)
	# Enter no último campo de cada formulário faz a ação principal dele.
	campo_senha.text_submitted.connect(_ao_entrar.unbind(1))
	campo_codigo.text_submitted.connect(_ao_confirmar.unbind(1))
	AccountManager.sign_up_finished.connect(_ao_pedir_o_codigo)
	AccountManager.confirmation_required.connect(_ao_pedir_o_codigo)
	AccountManager.account_confirmed.connect(_ao_confirmar_a_conta)
	AccountManager.logged_in.connect(_ao_entrar_na_conta)
	AccountManager.logged_out.connect(_ao_sair_da_conta)
	AccountManager.request_failed.connect(_mostrar_status.bind(true))

## Enquanto uma requisição está no ar, os botões ficam desabilitados, para o jogador não
## mandar a mesma coisa duas vezes.
func _process(_delta: float) -> void:
	if not visible:
		return
	for botao: Button in [botao_entrar, botao_criar_conta, botao_confirmar, botao_sair_da_conta]:
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
	var email: String = campo_email.text.strip_edges()
	if email == "" or campo_senha.text == "":
		_mostrar_status("Digite o e-mail e a senha.", true)
		return
	_mostrar_status("Entrando...")
	AccountManager.entrar(email, campo_senha.text)

func _ao_criar_conta() -> void:
	var email: String = campo_email.text.strip_edges()
	var nome: String = campo_nome.text.strip_edges()
	if email == "" or campo_senha.text == "" or nome == "":
		_mostrar_status("Para criar conta, preencha o e-mail, a senha e o nome.", true)
		return
	_mostrar_status("Criando a conta...")
	AccountManager.criar_conta(email, campo_senha.text, nome)

func _ao_confirmar() -> void:
	var codigo: String = campo_codigo.text.strip_edges()
	if codigo == "":
		_mostrar_status("Digite o código que chegou no e-mail.", true)
		return
	_mostrar_status("Confirmando...")
	AccountManager.confirmar_conta(_email_esperando_codigo, codigo)

func _ao_pedir_o_codigo(email: String) -> void:
	_email_esperando_codigo = email
	campo_codigo.clear()
	_mostrar_modo()
	_mostrar_status("")

## Confirmada a conta, entra direto com a senha que ainda está no campo, para o jogador
## não ter que digitar tudo de novo. Se o campo estiver vazio (o jogo foi fechado entre
## criar e confirmar), volta para o formulário de entrada.
func _ao_confirmar_a_conta(email: String) -> void:
	_email_esperando_codigo = ""
	campo_email.text = email
	if campo_senha.text == "":
		_mostrar_modo()
		_mostrar_status("Conta confirmada. Digite a senha para entrar.")
		return
	_mostrar_status("Conta confirmada. Entrando...")
	AccountManager.entrar(email, campo_senha.text)

func _ao_entrar_na_conta() -> void:
	campo_senha.clear()
	_mostrar_modo()
	_mostrar_status("Conectando com a conta...")

func _ao_sair_da_conta() -> void:
	_mostrar_modo()
	_mostrar_status("Você saiu da conta.")

## Mostra o formulário que vale agora e põe o foco nele, para o controle e o teclado
## terem onde começar.
func _mostrar_modo() -> void:
	var logado: bool = AccountManager.esta_logado()
	var esperando_codigo: bool = not logado and _email_esperando_codigo != ""
	painel_logado.visible = logado
	formulario_de_codigo.visible = esperando_codigo
	formulario_de_entrada.visible = not logado and not esperando_codigo
	if logado:
		rotulo_da_conta.text = "%s\n%s" % [AccountManager.nome_da_conta, AccountManager.email_da_conta]
		botao_sair_da_conta.grab_focus()
	elif esperando_codigo:
		rotulo_do_codigo.text = "Digite o código que chegou em %s" % _email_esperando_codigo
		campo_codigo.grab_focus()
	else:
		campo_email.grab_focus()

func _mostrar_status(texto: String, erro: bool = false) -> void:
	rotulo_de_status.text = texto
	rotulo_de_status.add_theme_color_override(&"font_color", COR_DO_ERRO if erro else COR_DO_STATUS)
