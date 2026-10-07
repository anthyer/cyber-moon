extends Node

## A conexão com o servidor de repasse: abre, mantém, reconecta, envia e recebe.
##
## O servidor não simula o jogo, só repassa mensagens JSON entre os jogos conectados (é o
## que o API Gateway WebSocket da AWS faz). Este autoload não sabe o que as mensagens
## significam: ele entrega cada uma pelo sinal message_received, e quem entende do assunto
## (o chat, o lobby, a dungeon) escuta. Aqui só ficam a conexão e a lista de quem está
## online.
##
## Sem servidor no ar o jogo funciona igual, só que offline. O protocolo está em
## equipe/planos/21-rede-e-chat.md.

signal connected
signal disconnected
## Toda mensagem que chega do servidor. O tipo é o campo "tipo" dela.
signal message_received(tipo: String, dados: Dictionary)
signal player_joined(id: String, nome: String)
signal player_left(id: String, nome: String)

const CAMINHO_DA_CONFIGURACAO: String = "res://resources/rede/configuracao.tres"
const ARQUIVO_DO_JOGADOR: String = "user://jogador.cfg"
## Argumentos de linha de comando, para abrir dois jogos na mesma máquina com nomes
## diferentes: godot --path game -- --nome=Ana --servidor=ws://localhost:8765
const ARGUMENTO_DO_NOME: String = "--nome="
const ARGUMENTO_DO_SERVIDOR: String = "--servidor="

## O id que o servidor deu a este jogo. Vazio enquanto não entrou.
var meu_id: String = ""
var meu_nome: String = ""
## Os outros jogadores conectados: id para nome. Não inclui este jogo.
var online: Dictionary[String, String] = {}

var _configuracao: ConfiguracaoDeRede
var _endereco: String = ""
var _socket: WebSocketPeer = WebSocketPeer.new()
## Verdadeiro entre pedir a conexão e ela cair ou ser fechada de propósito.
var _quer_estar_conectado: bool = false
var _socket_aberto: bool = false
var _segundos_ate_tentar_de_novo: float = 0.0

func _ready() -> void:
	# A rede continua andando com o jogo pausado: o chat e os convites não param porque o
	# jogador abriu o inventário.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configuracao = load(CAMINHO_DA_CONFIGURACAO) as ConfiguracaoDeRede
	_endereco = _configuracao.endereco
	meu_nome = _carregar_nome()
	for argumento in OS.get_cmdline_user_args():
		if argumento.begins_with(ARGUMENTO_DO_NOME):
			meu_nome = argumento.trim_prefix(ARGUMENTO_DO_NOME)
		elif argumento.begins_with(ARGUMENTO_DO_SERVIDOR):
			_endereco = argumento.trim_prefix(ARGUMENTO_DO_SERVIDOR)
	if _configuracao.conectar_ao_iniciar:
		conectar()

func _process(delta: float) -> void:
	if not _quer_estar_conectado:
		return
	_socket.poll()
	match _socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not _socket_aberto:
				_socket_aberto = true
				enviar("entrar", {"nome": meu_nome})
			while _socket.get_available_packet_count() > 0:
				_receber(_socket.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CLOSED:
			_ao_cair()
			_segundos_ate_tentar_de_novo -= delta
			if _segundos_ate_tentar_de_novo <= 0.0:
				_abrir_socket()

func conectar() -> void:
	_quer_estar_conectado = true
	_abrir_socket()

func desconectar() -> void:
	_quer_estar_conectado = false
	_socket.close()
	_ao_cair()

## Conectado de verdade: o servidor já respondeu com o id deste jogo.
func esta_conectado() -> bool:
	return meu_id != ""

## Troca o nome do jogador e guarda para a próxima vez. Vale a partir da próxima conexão.
func definir_nome(nome: String) -> void:
	meu_nome = nome.strip_edges()
	var arquivo: ConfigFile = ConfigFile.new()
	arquivo.set_value("jogador", "nome", meu_nome)
	arquivo.save(ARQUIVO_DO_JOGADOR)

## Manda uma mensagem ao servidor. A ação é a rota (o campo "action", como no API
## Gateway). Sem conexão, a mensagem é descartada em silêncio.
func enviar(acao: String, campos: Dictionary = {}) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var mensagem: Dictionary = campos.duplicate()
	mensagem["action"] = acao
	_socket.send_text(JSON.stringify(mensagem))

func nome_de(id: String) -> String:
	if id == meu_id:
		return meu_nome
	return online.get(id, "?")

func _abrir_socket() -> void:
	_segundos_ate_tentar_de_novo = _configuracao.segundos_entre_tentativas
	_socket = WebSocketPeer.new()
	_socket.connect_to_url(_endereco)

func _receber(texto: String) -> void:
	var dados: Variant = JSON.parse_string(texto)
	if not dados is Dictionary or not (dados as Dictionary).has("tipo"):
		return
	var mensagem: Dictionary = dados
	var tipo: String = mensagem["tipo"]
	match tipo:
		"bem_vindo":
			meu_id = mensagem["id"]
			meu_nome = mensagem["nome"]
			online.clear()
			for jogador: Dictionary in mensagem["online"]:
				online[jogador["id"]] = jogador["nome"]
			connected.emit()
		"jogador_entrou":
			online[mensagem["id"]] = mensagem["nome"]
			player_joined.emit(mensagem["id"], mensagem["nome"])
		"jogador_saiu":
			online.erase(mensagem["id"])
			player_left.emit(mensagem["id"], mensagem["nome"])
	message_received.emit(tipo, mensagem)

## A conexão caiu, ou nunca abriu. Só avisa uma vez por queda.
func _ao_cair() -> void:
	_socket_aberto = false
	if meu_id == "":
		return
	meu_id = ""
	online.clear()
	disconnected.emit()

## O nome guardado da última vez. Na primeira, inventa um, que o jogador pode trocar.
func _carregar_nome() -> String:
	var arquivo: ConfigFile = ConfigFile.new()
	if arquivo.load(ARQUIVO_DO_JOGADOR) == OK:
		var guardado: String = arquivo.get_value("jogador", "nome", "")
		if guardado != "":
			return guardado
	var novo: String = "Jogador%03d" % (randi() % 1000)
	arquivo.set_value("jogador", "nome", novo)
	arquivo.save(ARQUIVO_DO_JOGADOR)
	return novo
