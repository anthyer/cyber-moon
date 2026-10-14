class_name ObjetivoDeResgate
extends ObjetivoParalelo

## Objetivo paralelo: achar e pegar todas as peças escondidas pela dungeon.
##
## As peças são as PecaDeResgate abaixo deste nó, em qualquer profundidade. O índice de
## cada uma é a ordem em que aparecem na árvore, igual em todos os jogos.

const EVENTO_DE_PECA: String = "objetivo_peca"

## O nome do que está sendo resgatado, como aparece na tela: "Sementes resgatadas".
@export var nome_das_pecas: String = "Peças resgatadas"

var _pecas: Array[PecaDeResgate] = []

func _init() -> void:
	mensagem_de_conclusao = "Você resgatou tudo."

func _preparar() -> void:
	for no in find_children("*", "Node3D", true, false):
		var peca: PecaDeResgate = no as PecaDeResgate
		if peca == null:
			continue
		var indice: int = _pecas.size()
		_pecas.append(peca)
		peca.picked.connect(_ao_pegar.bind(indice))
		peca.collected.connect(_ao_coletar)

func texto_de_progresso() -> String:
	return "%s: %d de %d" % [nome_das_pecas, _coletadas(), _pecas.size()]

## Um jogador deste jogo pegou: os outros marcam a mesma peça como pega.
func _ao_pegar(indice: int) -> void:
	_avisar_os_outros(EVENTO_DE_PECA, {"alvo": indice})

func _ao_receber_evento(_de: String, tipo: String, campos: Dictionary) -> void:
	if tipo != EVENTO_DE_PECA:
		return
	var indice: int = int(campos.get("alvo", -1))
	if indice >= 0 and indice < _pecas.size():
		# coletar, e não interagir: a peça que veio da rede não é reenviada.
		_pecas[indice].coletar()

func _ao_coletar() -> void:
	_anunciar()
	if not _pecas.is_empty() and _coletadas() == _pecas.size():
		_concluir()

func _coletadas() -> int:
	var total: int = 0
	for peca in _pecas:
		if peca.coletada:
			total += 1
	return total
