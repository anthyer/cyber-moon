class_name ObjetivoDeGeradores
extends ObjetivoParalelo

## Objetivo paralelo: destruir todos os geradores da corporação espalhados pelas salas,
## antes de o chefe cair. Cumprido, o chefe final perde parte da vida.
##
## Os geradores são os GeradorDaCorporacao abaixo deste nó, em qualquer profundidade. O
## índice de cada um é a ordem em que aparecem na árvore, igual em todos os jogos.

const EVENTO_DE_GOLPE: String = "objetivo_golpe"

## A fração da vida atual que o chefe final perde quando todos os geradores caem.
@export_range(0.0, 0.9) var fracao_de_vida_tirada_do_chefe: float = 0.25

var _geradores: Array[GeradorDaCorporacao] = []

func _init() -> void:
	mensagem_de_conclusao = "Geradores destruídos. O chefe perdeu força."
	mensagem_de_falha = "O chefe caiu com geradores de pé."

func _preparar() -> void:
	for no in find_children("*", "StaticBody3D", true, false):
		var gerador: GeradorDaCorporacao = no as GeradorDaCorporacao
		if gerador == null:
			continue
		var indice: int = _geradores.size()
		_geradores.append(gerador)
		gerador.hit.connect(_ao_acertar.bind(indice))
		gerador.destroyed.connect(_ao_destruir)
	if dungeon != null:
		dungeon.enemy_defeated.connect(_ao_cair_inimigo)

func texto_de_progresso() -> String:
	return "Geradores: %d de %d" % [_destruidos(), _geradores.size()]

## Um golpe deste jogo: os outros aplicam o mesmo dano no mesmo gerador.
func _ao_acertar(quantidade: int, indice: int) -> void:
	_avisar_os_outros(EVENTO_DE_GOLPE, {"alvo": indice, "dano": quantidade})

func _ao_receber_evento(_de: String, tipo: String, campos: Dictionary) -> void:
	if tipo != EVENTO_DE_GOLPE:
		return
	var indice: int = int(campos.get("alvo", -1))
	if indice >= 0 and indice < _geradores.size():
		# aplicar_dano, e não receber_dano: o golpe que veio da rede não é reenviado.
		_geradores[indice].aplicar_dano(int(campos.get("dano", 0)))

func _ao_destruir() -> void:
	_anunciar()
	if not _geradores.is_empty() and _destruidos() == _geradores.size():
		_enfraquecer_o_chefe()
		_concluir()

## O chefe final caiu antes dos geradores: o objetivo não pode mais ser cumprido.
func _ao_cair_inimigo(inimigo: Inimigo) -> void:
	if _eh_chefe_final(inimigo):
		_falhar()

## Só o jogo anfitrião mexe na vida do chefe: é ele quem manda nos inimigos, e a vida nova
## chega aos outros jogos na transmissão de sempre.
func _enfraquecer_o_chefe() -> void:
	if dungeon == null or not _sou_anfitriao():
		return
	for no in dungeon.get_children():
		var chefe: Inimigo = no as Inimigo
		if chefe == null or not chefe.esta_vivo() or not _eh_chefe_final(chefe):
			continue
		var tirada: int = int(chefe.vida_atual * fracao_de_vida_tirada_do_chefe)
		# Nunca até zero: o objetivo enfraquece o chefe, quem o derruba é o jogador.
		chefe.vida_atual = maxi(chefe.vida_atual - tirada, 1)

func _eh_chefe_final(inimigo: Inimigo) -> bool:
	if inimigo == null:
		return false
	var perfil: PerfilChefe = inimigo.perfil as PerfilChefe
	return perfil != null and perfil.eh_chefe_final

func _destruidos() -> int:
	var total: int = 0
	for gerador in _geradores:
		if gerador.destruido:
			total += 1
	return total
