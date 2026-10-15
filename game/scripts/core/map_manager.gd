extends Node

## Liga um mapa e desliga o outro: a fazenda ou o mundo.
##
## Os dois mapas estão dentro da cena principal o tempo todo, em lugares distantes. Trocar
## de mapa é levar o jogador até o marcador de chegada do outro e trocar qual dos dois está
## visível e processando (ver Mapa). Não é troca de cena: o jogador, a câmera, a HUD e os
## sistemas continuam os mesmos.
##
## O mapa atual vai para o save. Ao acordar (dormindo ou desmaiado), o jogador está sempre
## na fazenda, então a fazenda volta a ser o mapa ativo.

const MAPA_INICIAL: StringName = &"fazenda"

var mapa_atual: StringName = MAPA_INICIAL

func _ready() -> void:
	StatusManager.player_woke_up.connect(_ao_acordar)
	# Um quadro depois do começo, para os mapas da fase já terem entrado no grupo.
	_ativar.call_deferred(mapa_atual)

func mapa(id: StringName) -> Mapa:
	for no in get_tree().get_nodes_in_group(Mapa.GRUPO):
		var candidato: Mapa = no as Mapa
		if candidato != null and candidato.id == id:
			return candidato
	return null

## Leva o jogador para o mapa dado, no marcador de chegada com esse nome.
func ir_para(id: StringName, chegada: StringName) -> void:
	var destino: Mapa = mapa(id)
	var jogador: CharacterBody3D = get_tree().get_first_node_in_group(&"jogador") as CharacterBody3D
	if destino == null or jogador == null:
		push_warning("Mapa '%s' não encontrado." % id)
		return
	var ponto: Node3D = destino.ponto_de_chegada(chegada)
	if ponto != null:
		jogador.global_position = ponto.global_position
		jogador.velocity = Vector3.ZERO
	# O sinal sai depois de o jogador chegar: a poeira da chegada aparece em volta dele.
	_ativar(id)

func _ativar(id: StringName) -> void:
	mapa_atual = id
	for no in get_tree().get_nodes_in_group(Mapa.GRUPO):
		var cada: Mapa = no as Mapa
		if cada != null:
			cada.ativar(cada.id == id)
	EventBus.map_changed.emit(id)

func _ao_acordar(_motivo: StatusManager.Motivo) -> void:
	if mapa_atual != MAPA_INICIAL:
		_ativar(MAPA_INICIAL)

func exportar_estado() -> Dictionary:
	return {"mapa": String(mapa_atual)}

func importar_estado(dados: Dictionary) -> void:
	_ativar(StringName(dados.get("mapa", String(MAPA_INICIAL))))
	# Save de antes dos dois mapas (plano 26) guarda a posição do jogador no playground
	# antigo, que agora é o meio do nada. Depois que tudo carregar, ele vai para casa.
	if not dados.has("mapa"):
		EventBus.game_loaded.connect(_levar_para_casa, CONNECT_ONE_SHOT)

func _levar_para_casa() -> void:
	ir_para(MAPA_INICIAL, &"PontoDeSpawn")
