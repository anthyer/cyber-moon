extends Node

## A equipe da dungeon: a sala do servidor vista pelo jogo.
##
## Uma sala tem um anfitrião (quem convidou) e os membros. O anfitrião é quem simula os
## inimigos na dungeon. Sem sala, o jogador está sozinho e é o próprio anfitrião, e é
## assim que a dungeon funciona offline.
##
## Também é por aqui que a dungeon troca mensagens: enviar_para_a_sala manda para os
## outros membros, e room_message entrega o que chega.

signal room_changed
signal invite_received(de: String, nome: String)
signal invite_declined(nome: String)
## A sala acabou porque o anfitrião saiu ou caiu.
signal room_closed
## Hora de entrar na dungeon. Chega para todos os membros, e também para quem está sozinho.
signal dungeon_started
signal room_message(de: String, tipo: String, campos: Dictionary)

## Id da sala. Vazio quando o jogador não está em nenhuma.
var sala: String = ""
var anfitriao: String = ""
## Cada membro é {"id", "nome"}, com o anfitrião primeiro. Vazio sem sala.
var membros: Array[Dictionary] = []

## A sala do convite que ainda não foi respondido. Vazio quando não há convite.
var _sala_do_convite: String = ""
## A sala de que este jogo acabou de sair. Uma atualização dela ainda pode estar a caminho
## (o servidor a mandou antes de processar a saída), e não pode recolocar o jogador lá.
var _sala_abandonada: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	NetworkManager.message_received.connect(_ao_receber)
	NetworkManager.disconnected.connect(_ao_perder_a_conexao)

func esta_em_sala() -> bool:
	return sala != ""

## Verdadeiro também sem sala: quem joga sozinho manda nos próprios inimigos.
func sou_anfitriao() -> bool:
	return sala == "" or anfitriao == NetworkManager.meu_id

## Os outros membros da sala, sem este jogo.
func outros_membros() -> Array[Dictionary]:
	var outros: Array[Dictionary] = []
	for membro in membros:
		if membro["id"] != NetworkManager.meu_id:
			outros.append(membro)
	return outros

func convidar(id: String) -> void:
	NetworkManager.enviar("convidar", {"para": id})

func tem_convite_pendente() -> bool:
	return _sala_do_convite != ""

func responder_convite(aceita: bool) -> void:
	if _sala_do_convite == "":
		return
	NetworkManager.enviar("responder_convite", {"sala": _sala_do_convite, "aceita": aceita})
	_sala_do_convite = ""

func sair() -> void:
	if sala == "":
		return
	NetworkManager.enviar("sair_da_sala")
	_sala_abandonada = sala
	_limpar()
	room_changed.emit()

## Começa a dungeon. Em sala, o servidor avisa todos os membros (inclusive este jogo).
## Sozinho ou offline, começa na hora.
func iniciar() -> void:
	if not sou_anfitriao():
		return
	if sala != "" and NetworkManager.esta_conectado():
		NetworkManager.enviar("iniciar_dungeon")
	else:
		dungeon_started.emit()

## Manda uma mensagem do jogo aos outros membros da sala. Sem sala, não faz nada.
func enviar_para_a_sala(tipo: String, campos: Dictionary = {}) -> void:
	if sala == "":
		return
	var dados: Dictionary = campos.duplicate()
	dados["tipo"] = tipo
	NetworkManager.enviar("sala", {"dados": dados})

func _ao_receber(tipo: String, dados: Dictionary) -> void:
	match tipo:
		"convite":
			_sala_abandonada = ""
			_sala_do_convite = dados["sala"]
			invite_received.emit(dados["de"], dados["nome"])
		"convite_recusado":
			invite_declined.emit(dados["nome"])
		"sala_atualizada":
			if dados["sala"] == _sala_abandonada:
				return
			_guardar_sala(dados)
			room_changed.emit()
		"sala_encerrada":
			_limpar()
			room_closed.emit()
			room_changed.emit()
		"dungeon_iniciada":
			_guardar_sala(dados)
			dungeon_started.emit()
		"sala":
			var campos: Dictionary = dados["dados"]
			room_message.emit(dados["de"], campos.get("tipo", ""), campos)

func _guardar_sala(dados: Dictionary) -> void:
	sala = dados["sala"]
	anfitriao = dados["anfitriao"]
	membros.assign(dados["membros"])

## Sem conexão não há sala. Quem estava numa é avisado como se o anfitrião tivesse saído.
func _ao_perder_a_conexao() -> void:
	if sala == "":
		return
	_limpar()
	room_closed.emit()
	room_changed.emit()

func _limpar() -> void:
	sala = ""
	anfitriao = ""
	membros.clear()
