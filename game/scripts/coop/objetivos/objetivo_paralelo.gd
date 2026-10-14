class_name ObjetivoParalelo
extends Node3D

## A base do objetivo paralelo de uma dungeon: algo a mais para fazer além de vencer o
## chefe. Cada dungeon tem um só, um nó na cena dela com os alvos como filhos. Cumprir
## melhora a recompensa do chefe: o baú lê a propriedade concluido do nó que estiver no
## grupo "objetivo_paralelo".
##
## Em equipe os dois jogos precisam concordar. Todo estado que muda por ação de um jogador
## é avisado aos outros com Dungeon.enviar_evento e aplicado por quem recebe, sem reenviar.
## Sozinho, enviar_evento não faz nada.
##
## As filhas dizem o progresso em texto_de_progresso() e chamam _concluir() ou _falhar().

const GRUPO: StringName = &"objetivo_paralelo"

@export var mensagem_de_conclusao: String = "Objetivo cumprido."
@export var mensagem_de_falha: String = "O objetivo falhou."

var concluido: bool = false
## Verdadeiro quando o objetivo não pode mais ser cumprido nesta entrada na dungeon.
var falhou: bool = false

## A dungeon em que este objetivo está. Null se a cena for aberta fora de uma.
var dungeon: Dungeon

func _ready() -> void:
	add_to_group(GRUPO)
	dungeon = _achar_dungeon()
	if dungeon != null:
		dungeon.event_received.connect(_ao_receber_evento)
	_preparar()
	# Um quadro depois, para a interface da dungeon já estar ouvindo o sinal.
	_anunciar.call_deferred()

## O progresso em texto pronto para a tela, como "Geradores: 2 de 3".
func texto_de_progresso() -> String:
	return ""

## Chamado no _ready, depois de a dungeon ser achada. As filhas ligam os alvos aqui.
func _preparar() -> void:
	pass

## Um aviso das peças da dungeon que veio de outro jogo. As filhas tratam os tipos delas.
func _ao_receber_evento(_de: String, _tipo: String, _campos: Dictionary) -> void:
	pass

func _anunciar() -> void:
	EventBus.dungeon_objective_changed.emit(texto_de_progresso(), concluido)

func _concluir() -> void:
	if concluido or falhou:
		return
	concluido = true
	_anunciar()
	EventBus.notice_requested.emit(mensagem_de_conclusao)

func _falhar() -> void:
	if concluido or falhou:
		return
	falhou = true
	_anunciar()
	EventBus.notice_requested.emit(mensagem_de_falha)

## Manda um aviso deste objetivo aos outros jogos. Sem dungeon ou sozinho, não faz nada.
func _avisar_os_outros(tipo: String, campos: Dictionary) -> void:
	if dungeon != null:
		dungeon.enviar_evento(tipo, campos)

func _sou_anfitriao() -> bool:
	return dungeon == null or dungeon.sou_anfitriao()

## Sobe pela árvore até a Dungeon. O grupo serve de reserva, para o objetivo que não for
## descendente direto dela.
func _achar_dungeon() -> Dungeon:
	var pai: Node = get_parent()
	while pai != null:
		if pai is Dungeon:
			return pai as Dungeon
		pai = pai.get_parent()
	return get_tree().get_first_node_in_group(Dungeon.GRUPO) as Dungeon
