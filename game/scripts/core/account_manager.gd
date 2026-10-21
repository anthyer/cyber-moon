extends Node

## A conta do jogador no Cognito da AWS: criar, confirmar, entrar, sair e renovar o token.
##
## O token serve para uma coisa só: o authorizer do API Gateway (plano 18) só aceita a
## conexão de quem manda um ID token válido. O NetworkManager pergunta o token a este
## autoload na hora de conectar, e este autoload não sabe nada de WebSocket.
##
## Cada operação é um POST ao Cognito com o nome dela no cabeçalho X-Amz-Target. Não há
## SDK da AWS no Godot, e o Cognito aceita essas chamadas sem assinatura porque o cliente
## do User Pool foi criado sem segredo.
##
## A senha nunca é guardada. Fica guardado o RefreshToken, que vale 30 dias, e com ele o
## ID token é renovado ao abrir o jogo, sem pedir a senha de novo. O plano é o
## equipe/planos/36-login-no-jogo.md.

signal logged_in
signal logged_out
## A conta foi criada e o Cognito mandou o código de confirmação para o e-mail.
signal sign_up_finished(email: String)
signal account_confirmed(email: String)
## Tentou entrar numa conta criada e ainda não confirmada. O código do e-mail vale 24 horas.
signal confirmation_required(email: String)
## Uma operação falhou. A mensagem já vem em português, pronta para a tela.
signal request_failed(mensagem: String)

const CAMINHO_DA_CONFIGURACAO: String = "res://resources/rede/configuracao.tres"
const ARQUIVO_DA_CONTA: String = "user://conta.cfg"
## O ID token do Cognito vale 1 hora. Passados 50 minutos ele é renovado antes de abrir
## uma conexão nova, para não vencer no meio do caminho.
const SEGUNDOS_ATE_RENOVAR: float = 50.0 * 60.0
## Os erros do Cognito que um jogador consegue causar, no campo __type da resposta.
const MENSAGENS_DE_ERRO: Dictionary[String, String] = {
	"UsernameExistsException": "Já existe uma conta com esse e-mail.",
	"UserNotFoundException": "Não existe conta com esse e-mail.",
	"NotAuthorizedException": "E-mail ou senha errados.",
	"UserNotConfirmedException": "Conta ainda não confirmada. Digite o código do e-mail.",
	"CodeMismatchException": "Código errado.",
	"ExpiredCodeException": "O código venceu. Crie a conta de novo para receber outro.",
	"InvalidPasswordException": "Senha fraca: pelo menos 8 caracteres, com letras minúsculas e números.",
	"InvalidParameterException": "Algum campo está inválido. Confira o e-mail e o nome.",
	"TooManyRequestsException": "Muitas tentativas. Espere um pouco e tente de novo.",
	"LimitExceededException": "Muitas tentativas. Espere um pouco e tente de novo.",
}

var nome_da_conta: String = ""
var email_da_conta: String = ""
## Verdadeiro enquanto uma requisição está no ar. As telas desabilitam os botões.
var ocupado: bool = false

var _configuracao: ConfiguracaoDeRede
var _http: HTTPRequest
var _id_token: String = ""
var _refresh_token: String = ""
## Quando o ID token atual foi recebido, em segundos desde 1970. Zero sem token.
var _recebido_em: float = 0.0

func _ready() -> void:
	# Como a rede, a conta continua andando com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configuracao = load(CAMINHO_DA_CONFIGURACAO) as ConfiguracaoDeRede
	_http = HTTPRequest.new()
	add_child(_http)
	_carregar_conta()

## O login só existe quando a configuração aponta para um User Pool.
func login_disponivel() -> bool:
	return _configuracao.cognito_client_id != ""

## Logado quer dizer que há uma conta guardada. O ID token pode estar vencido: quem vai
## usar pergunta token_vencendo() e renova antes.
func esta_logado() -> bool:
	return _refresh_token != ""

## O token que vai na conexão, ou vazio quando não há conta.
func token_de_conexao() -> String:
	return _id_token

func token_vencendo() -> bool:
	if not esta_logado():
		return false
	return Time.get_unix_time_from_system() - _recebido_em >= SEGUNDOS_ATE_RENOVAR

func criar_conta(email: String, senha: String, nome: String) -> void:
	var resposta: Dictionary = await _chamar("SignUp", {
		"ClientId": _configuracao.cognito_client_id,
		"Username": email,
		"Password": senha,
		"UserAttributes": [{"Name": "custom:nome", "Value": nome}],
	})
	if resposta.has("__ok"):
		sign_up_finished.emit(email)

func confirmar_conta(email: String, codigo: String) -> void:
	var resposta: Dictionary = await _chamar("ConfirmSignUp", {
		"ClientId": _configuracao.cognito_client_id,
		"Username": email,
		"ConfirmationCode": codigo,
	})
	# A resposta de sucesso do ConfirmSignUp é um objeto vazio. Quem diz que deu certo é
	# a marca que _chamar acrescenta.
	if resposta.has("__ok"):
		account_confirmed.emit(email)

func entrar(email: String, senha: String) -> void:
	var resposta: Dictionary = await _chamar("InitiateAuth", {
		"ClientId": _configuracao.cognito_client_id,
		"AuthFlow": "USER_PASSWORD_AUTH",
		"AuthParameters": {"USERNAME": email, "PASSWORD": senha},
	})
	if not resposta.has("AuthenticationResult"):
		if resposta.get("__type", "") == "UserNotConfirmedException":
			confirmation_required.emit(email)
		return
	var resultado: Dictionary = resposta["AuthenticationResult"]
	_refresh_token = resultado["RefreshToken"]
	email_da_conta = email
	_guardar_id_token(resultado["IdToken"])
	_salvar_conta()
	logged_in.emit()

func sair() -> void:
	_id_token = ""
	_refresh_token = ""
	_recebido_em = 0.0
	nome_da_conta = ""
	email_da_conta = ""
	DirAccess.remove_absolute(ARQUIVO_DA_CONTA)
	logged_out.emit()

## Troca o RefreshToken guardado por um ID token novo. Devolve se deu certo. Se o
## RefreshToken não vale mais (venceu, ou a conta foi apagada), a conta sai sozinha.
func renovar_token() -> bool:
	if not esta_logado():
		return false
	var resposta: Dictionary = await _chamar("InitiateAuth", {
		"ClientId": _configuracao.cognito_client_id,
		"AuthFlow": "REFRESH_TOKEN_AUTH",
		"AuthParameters": {"REFRESH_TOKEN": _refresh_token},
	})
	if not resposta.has("AuthenticationResult"):
		if resposta.get("__type", "") == "NotAuthorizedException":
			sair()
		return false
	# A renovação não devolve RefreshToken novo: o de antes continua valendo.
	_guardar_id_token(resposta["AuthenticationResult"]["IdToken"])
	return true

## Faz uma chamada ao Cognito e devolve a resposta. Em caso de erro, emite
## request_failed e devolve só o __type do erro (ou nada, quando nem houve resposta).
## Em caso de sucesso, a resposta ganha a marca __ok, porque algumas operações
## respondem com um objeto vazio.
func _chamar(operacao: String, corpo: Dictionary) -> Dictionary:
	if ocupado:
		return {}
	ocupado = true
	var endereco: String = "https://cognito-idp.%s.amazonaws.com/" % _configuracao.cognito_regiao
	var cabecalhos: PackedStringArray = [
		"Content-Type: application/x-amz-json-1.1",
		"X-Amz-Target: AWSCognitoIdentityProviderService.%s" % operacao,
	]
	var erro: Error = _http.request(endereco, cabecalhos, HTTPClient.METHOD_POST, JSON.stringify(corpo))
	if erro != OK:
		ocupado = false
		request_failed.emit("Não deu para falar com o servidor de contas.")
		return {}
	var retorno: Array = await _http.request_completed
	ocupado = false
	var resultado: int = retorno[0]
	var codigo_http: int = retorno[1]
	var texto: String = (retorno[3] as PackedByteArray).get_string_from_utf8()
	if resultado != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit("Sem conexão com o servidor de contas.")
		return {}
	var dados: Variant = JSON.parse_string(texto)
	var resposta: Dictionary = dados if dados is Dictionary else {}
	if codigo_http != 200:
		var tipo: String = resposta.get("__type", "")
		# O __type às vezes vem com o nome do serviço na frente, separado por #.
		if tipo.contains("#"):
			tipo = tipo.get_slice("#", 1)
		request_failed.emit(MENSAGENS_DE_ERRO.get(tipo, "Erro no servidor de contas (%s)." % tipo))
		return {"__type": tipo}
	resposta["__ok"] = true
	return resposta

## Guarda o ID token e lê dele o nome da conta. O token é um JWT: três pedaços em
## base64 separados por ponto, e o do meio é um JSON com os dados da conta. A assinatura
## não é conferida aqui; quem confere é o authorizer, do lado da AWS.
func _guardar_id_token(token: String) -> void:
	_id_token = token
	_recebido_em = Time.get_unix_time_from_system()
	var pedacos: PackedStringArray = token.split(".")
	if pedacos.size() != 3:
		return
	var meio: String = pedacos[1].replace("-", "+").replace("_", "/")
	while meio.length() % 4 != 0:
		meio += "="
	var dados: Variant = JSON.parse_string(Marshalls.base64_to_raw(meio).get_string_from_utf8())
	if dados is Dictionary:
		nome_da_conta = (dados as Dictionary).get("custom:nome", "")
		email_da_conta = (dados as Dictionary).get("email", email_da_conta)

func _salvar_conta() -> void:
	var arquivo: ConfigFile = ConfigFile.new()
	arquivo.set_value("conta", "email", email_da_conta)
	arquivo.set_value("conta", "nome", nome_da_conta)
	arquivo.set_value("conta", "refresh_token", _refresh_token)
	arquivo.save(ARQUIVO_DA_CONTA)

## Só lê o que ficou guardado. O ID token não é guardado: _recebido_em fica zero, então
## token_vencendo() responde que sim, e a primeira conexão renova antes de abrir.
func _carregar_conta() -> void:
	if not login_disponivel():
		return
	var arquivo: ConfigFile = ConfigFile.new()
	if arquivo.load(ARQUIVO_DA_CONTA) != OK:
		return
	email_da_conta = arquivo.get_value("conta", "email", "")
	nome_da_conta = arquivo.get_value("conta", "nome", "")
	_refresh_token = arquivo.get_value("conta", "refresh_token", "")
