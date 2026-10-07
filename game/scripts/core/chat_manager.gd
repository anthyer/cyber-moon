extends Node

## O chat global: guarda o histórico e envia mensagens.
##
## O histórico mora aqui, e não na tela, para a HUD mostrar as mensagens antigas ao ser
## criada e para nada se perder quando o jogador entra e sai da dungeon. Cada mensagem é
## um dicionário {"nome", "texto", "minha", "sistema"}; as de sistema (entrou, saiu,
## conectou) vêm sem nome.

signal message_added(mensagem: Dictionary)

const MAXIMO_NO_HISTORICO: int = 100
const MAXIMO_DE_CARACTERES: int = 200

var historico: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	NetworkManager.message_received.connect(_ao_receber)
	NetworkManager.connected.connect(_ao_conectar)
	NetworkManager.disconnected.connect(_avisar.bind("Conexão perdida. O chat está offline."))
	NetworkManager.player_joined.connect(func(_id: String, nome: String) -> void: _avisar("%s entrou." % nome))
	NetworkManager.player_left.connect(func(_id: String, nome: String) -> void: _avisar("%s saiu." % nome))

## Manda uma mensagem a todos. A própria mensagem volta do servidor como as outras, e é
## aí que ela entra no histórico: assim a ordem é a mesma para todo mundo.
func enviar(texto: String) -> void:
	var limpo: String = texto.strip_edges().left(MAXIMO_DE_CARACTERES)
	if limpo == "":
		return
	if not NetworkManager.esta_conectado():
		_avisar("Você está offline. A mensagem não foi enviada.")
		return
	NetworkManager.enviar("chat", {"texto": limpo})

func _ao_receber(tipo: String, dados: Dictionary) -> void:
	if tipo != "chat":
		return
	_acrescentar({"nome": dados["nome"], "texto": dados["texto"], "minha": dados["de"] == NetworkManager.meu_id, "sistema": false})

func _ao_conectar() -> void:
	_avisar("Conectado como %s. %d online." % [NetworkManager.meu_nome, NetworkManager.online.size()])

func _avisar(texto: String) -> void:
	_acrescentar({"nome": "", "texto": texto, "minha": false, "sistema": true})

func _acrescentar(mensagem: Dictionary) -> void:
	historico.append(mensagem)
	if historico.size() > MAXIMO_NO_HISTORICO:
		historico.pop_front()
	message_added.emit(mensagem)
