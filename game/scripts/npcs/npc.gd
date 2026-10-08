class_name Npc
extends CharacterBody3D

## Um morador do mapa. A cena é a mesma para todos; quem ele é vem do PerfilNpc.
##
## A cada minuto de jogo ele confere a rotina: se o lugar em que deveria estar mudou, anda
## até lá pela malha de navegação (NavigationAgent3D), contornando prédio e cerca, e ao
## chegar toca a animação do compromisso. Fora dos compromissos, na Folga e na tempestade
## ele fica em casa.
##
## O NPC não conhece o mapa. Os lugares são Marker3D com nome, filhos de um nó do grupo
## "pontos_de_rotina" na fase, e a rotina só cita o nome. Trocar o mapa é reposicionar os
## marcadores e gerar a malha de novo.

const GRUPO: StringName = &"npcs"
const GRUPO_DOS_PONTOS: StringName = &"pontos_de_rotina"
const ANIMACAO_EM_CASA: StringName = &"idle"
## Vários NPCs podem ter o mesmo destino (a praça). Cada um para num ponto de um círculo
## deste raio em volta do marcador, para não ficarem um dentro do outro.
const RAIO_NO_DESTINO: float = 0.8
## Distância em que dois NPCs parados em idle encenam uma conversa.
const DISTANCIA_DE_CONVERSA: float = 3.0
const PAUSA_MINIMA_DA_CONVERSA: float = 1.5
const PAUSA_MAXIMA_DA_CONVERSA: float = 4.0
const DISTANCIA_DE_CHEGADA: float = 0.2
## Clipes que precisam ficar repetindo. Nem todos vêm marcados como loop no modelo, e sem
## isso o NPC congelava no último quadro. Sentar e os gestos tocam uma vez só.
const ANIMACOES_EM_LOOP: Array[StringName] = [&"idle", &"walk", &"interact-left", &"interact-right"]
## Andando há este tempo sem sair do lugar, ele está preso em algo que a malha não viu.
const SEGUNDOS_PARA_DESISTIR: float = 1.5
const PROGRESSO_MINIMO: float = 0.15
## O indicador de conversa: amarelo quando ainda há fala nova hoje, branco quando a
## conversa do dia já aconteceu e falar de novo só repete.
const COR_DE_FALA_NOVA: Color = Color(1.0, 0.85, 0.2)
const COR_DE_FALA_REPETIDA: Color = Color(1.0, 1.0, 1.0)
const ID_DO_BUQUE: StringName = &"buque"
## A fala de evento da Conversa que responde a cada reação e a cada resposta ao buquê.
const EVENTOS_POR_REACAO: Dictionary = {
	RelationshipManager.ResultadoPresente.AMOU: &"amou",
	RelationshipManager.ResultadoPresente.GOSTOU: &"gostou",
	RelationshipManager.ResultadoPresente.NEUTRO: &"neutro",
	RelationshipManager.ResultadoPresente.NAO_GOSTOU: &"nao_gostou",
	RelationshipManager.ResultadoPresente.ODIOU: &"odiou",
}
const EVENTOS_POR_RESPOSTA_AO_BUQUE: Dictionary = {
	RelationshipManager.ResultadoBuque.ACEITO: &"buque_aceito",
	RelationshipManager.ResultadoBuque.POUCOS_CORACOES: &"buque_poucos_coracoes",
	RelationshipManager.ResultadoBuque.NAO_ROMANCEAVEL: &"buque_nao_romanceavel",
	RelationshipManager.ResultadoBuque.JA_NAMORANDO: &"buque_ja_namorando",
}
const GESTOS_DA_CONVERSA: Array[StringName] = [&"emote-yes", &"emote-no"]

@export var perfil: PerfilNpc
@export var gravidade: float = 24.0
@export var velocidade_de_giro: float = 8.0

@onready var _agente: NavigationAgent3D = $Agente
@onready var _balao: Sprite3D = $Balao
@onready var _indicador: Sprite3D = $Indicador

var _modelo: Node3D
var _animacao: AnimationPlayer
## Nome do marcador para onde ele está indo ou onde está parado.
var _destino: StringName = &""
var _animacao_parado: StringName = ANIMACAO_EM_CASA
var _andando: bool = false
## Para onde olhar ao chegar: a frente do marcador.
var _frente_no_destino: Vector3 = Vector3.BACK
var _pausa_da_conversa: float = 0.0
## Para notar que ficou preso: onde estava na última conferência e há quanto tempo.
var _posicao_conferida: Vector3
var _segundos_sem_progresso: float = 0.0

func _ready() -> void:
	add_to_group(GRUPO)
	_balao.visible = false
	_indicador.visible = false
	if perfil == null:
		push_warning("Npc sem perfil: %s" % name)
		return
	_montar_modelo()
	DayCycleManager.hour_changed.connect(_ao_mudar_hora)
	if perfil.catalogo != null:
		DialogueManager.dialogue_ended.connect(_ao_terminar_dialogo)
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)
	WeatherManager.weather_changed.connect(_ao_mudar_clima)
	# No primeiro quadro a malha de navegação ainda não está pronta, e os marcadores da
	# fase podem não ter entrado na árvore. Por isso a primeira posição espera um quadro.
	_aparecer_no_lugar_certo.call_deferred()

## O indicador aparece quando o jogador está perto o bastante para conversar, ou seja,
## quando este NPC é o alvo que o botão de interagir acionaria. A pergunta vai para a
## própria área de interação do jogador, para o indicador nunca prometer uma conversa que
## o botão não abriria.
func _process(_delta: float) -> void:
	if perfil == null:
		return
	var ao_alcance: bool = not DialogueManager.em_dialogo and _sou_o_alvo_do_jogador()
	_indicador.visible = ao_alcance
	if ao_alcance:
		_indicador.modulate = COR_DE_FALA_REPETIDA if DialogueManager.ja_conversou_hoje(perfil.id) else COR_DE_FALA_NOVA
		# O balão da encenação entre NPCs ocupa o mesmo lugar: enquanto o indicador
		# aparece, o balão não é mostrado (veja _encenar_conversa).

func _sou_o_alvo_do_jogador() -> bool:
	var jogador: Node = get_tree().get_first_node_in_group(&"jogador")
	if jogador == null:
		return false
	var area: AreaDeInteracao = jogador.get_node_or_null("AreaInteracao") as AreaDeInteracao
	return area != null and area.alvo_mais_proximo() == self

func _physics_process(delta: float) -> void:
	if perfil == null:
		return
	if _em_conversa_com_o_jogador():
		_ficar_de_frente_para_o_jogador(delta)
	elif _andando:
		_andar(delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_encenar_conversa(delta)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravidade * delta
	move_and_slide()

## O compromisso da rotina que vale agora, ou null quando é hora de ficar em casa.
func compromisso_atual() -> Compromisso:
	if _todos_ficam_em_casa():
		return null
	var estacao: StringName = SeasonManager.estacao_atual()
	var e_aniversario: bool = perfil.faz_aniversario(estacao, SeasonManager.dia_da_estacao())
	return perfil.compromisso_para(DayCycleManager.hora_atual, estacao, SeasonManager.dia_da_semana(), WeatherManager.clima_atual, e_aniversario)

func ir_para(destino: Vector3) -> void:
	_agente.target_position = destino
	_andando = true
	_posicao_conferida = global_position
	_segundos_sem_progresso = 0.0
	_balao.visible = false

## Contrato de interação do jogo (ver AreaDeInteracao): o jogador chegou perto e apertou
## o botão. Abre a conversa do dia. Vale também no meio do caminho: ele para, conversa, e
## depois segue para onde ia.
func interagir() -> void:
	DialogueManager.iniciar(self)

## Só para comerciante: depois da conversa do dia, a loja abre. Fora do horário ou na
## Folga, ele explica que está fechado, numa fala só, em vez de abrir a tela.
func _ao_terminar_dialogo(npc_id: String) -> void:
	if npc_id != perfil.id or not DialogueManager.e_conversa_do_dia:
		return
	if perfil.catalogo.esta_aberta():
		EventBus.shop_requested.emit(perfil)
	elif perfil.catalogo.e_folga():
		DialogueManager.mostrar_fala_de_evento(self, &"loja_fechada_folga")
	else:
		DialogueManager.mostrar_fala_de_evento(self, &"loja_fechada_horario")

## O jogador soltou o item da mão perto deste NPC: é um presente. Devolve true quando o
## item foi aceito e deve sair do inventário. Presente repetido na semana e buquê recusado
## devolvem false: o item fica com o jogador, porque consumi-lo seria punição sem aviso.
func receber_presente(item: Item) -> bool:
	if item == null or perfil == null or DialogueManager.em_dialogo:
		return false
	if not item.pode_ser_presente or not item.pode_ser_descartado():
		EventBus.notice_requested.emit("Isso não serve de presente.")
		return false
	if item.id == ID_DO_BUQUE:
		return _receber_buque()
	var resultado: RelationshipManager.ResultadoPresente = RelationshipManager.presentear(perfil.id, item)
	if resultado == RelationshipManager.ResultadoPresente.JA_PRESENTEOU_ESTA_SEMANA:
		DialogueManager.mostrar_fala_de_evento(self, &"ja_presenteou")
		return false
	var gostou: bool = resultado in [RelationshipManager.ResultadoPresente.AMOU, RelationshipManager.ResultadoPresente.GOSTOU]
	var detestou: bool = resultado in [RelationshipManager.ResultadoPresente.NAO_GOSTOU, RelationshipManager.ResultadoPresente.ODIOU]
	var gesto: StringName = &"emote-yes" if gostou else (&"emote-no" if detestou else &"idle")
	# No aniversário, o presente de que ele gosta ganha a fala de aniversário no lugar da
	# reação comum.
	var evento: StringName = EVENTOS_POR_REACAO[resultado]
	if gostou and RelationshipManager.e_aniversario_de(perfil.id):
		evento = &"aniversario"
	DialogueManager.mostrar_fala_de_evento(self, evento, gesto)
	return true

func _receber_buque() -> bool:
	# Outro buquê para quem já é o namorado não é pedido nenhum. A fala de recusa "você já
	# tem alguém" não faria sentido vinda dele, então só um aviso, e o buquê fica.
	if RelationshipManager.esta_namorando(perfil.id):
		EventBus.notice_requested.emit("Vocês já estão namorando.")
		return false
	var resposta: RelationshipManager.ResultadoBuque = RelationshipManager.pedir_em_namoro(perfil.id)
	var aceito: bool = resposta == RelationshipManager.ResultadoBuque.ACEITO
	DialogueManager.mostrar_fala_de_evento(self, EVENTOS_POR_RESPOSTA_AO_BUQUE[resposta], &"emote-yes" if aceito else &"idle")
	return aceito

## Parado num lugar, e não no meio do caminho.
func esta_disponivel_para_conversa() -> bool:
	return not _andando

func _em_conversa_com_o_jogador() -> bool:
	return DialogueManager.em_dialogo and DialogueManager.interlocutor == self

## Durante a conversa ele para onde está e vira para o jogador. O destino continua
## guardado no agente, então ao fim da conversa ele retoma o caminho sozinho.
func _ficar_de_frente_para_o_jogador(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_balao.visible = false
	_tocar(&"idle")
	var jogador: Node3D = get_tree().get_first_node_in_group(&"jogador") as Node3D
	if jogador != null:
		_virar_para(jogador.global_position - global_position, delta)

func esta_parado_em_idle() -> bool:
	return not _andando and _animacao_parado == &"idle"

## Regra global, fácil de perceber jogando: na Folga e na tempestade ninguém sai.
func _todos_ficam_em_casa() -> bool:
	return SeasonManager.dia_da_semana() == SeasonManager.DIA_DE_FOLGA or WeatherManager.perfil_atual().npcs_ficam_em_casa

func _ao_mudar_hora(_hora: float) -> void:
	_conferir_a_rotina(false)

func _ao_mudar_clima(_clima: StringName) -> void:
	_conferir_a_rotina(false)

## O dia vira com a tela escura. Em vez de sair andando de onde a noite o deixou, ele já
## aparece onde a rotina manda de manhã.
func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	_conferir_a_rotina(true)

func _aparecer_no_lugar_certo() -> void:
	_conferir_a_rotina(true)

## Compara onde ele deveria estar com onde está indo, e muda de rumo se for diferente.
## Com direto, ele é colocado no lugar em vez de andar até lá.
func _conferir_a_rotina(direto: bool) -> void:
	var compromisso: Compromisso = compromisso_atual()
	var destino: StringName = compromisso.destino if compromisso != null else perfil.casa
	var animacao: StringName = compromisso.animacao_parado if compromisso != null else ANIMACAO_EM_CASA
	if destino == _destino and not direto:
		# Mesmo lugar, mas a pose pode mudar (trabalhar de manhã, sentar no almoço).
		if animacao != _animacao_parado:
			_animacao_parado = animacao
			if not _andando:
				_tocar(_animacao_parado)
		return
	var marcador: Node3D = _marcador(destino)
	if marcador == null:
		push_warning("%s: a fase não tem o ponto de rotina '%s'." % [perfil.id, destino])
		return
	_destino = destino
	_animacao_parado = animacao
	_frente_no_destino = marcador.global_basis.z
	var posicao: Vector3 = marcador.global_position + _deslocamento_no_destino()
	if direto:
		global_position = posicao
		velocity = Vector3.ZERO
		_agente.target_position = posicao
		_chegar()
	else:
		ir_para(posicao)

func _andar(delta: float) -> void:
	# A chegada é medida aqui, na horizontal, e não só pelo agente: ele mede em 3D, e a
	# malha fica um pouco acima do chão, o que deixava o NPC andando no lugar a um palmo
	# do destino. A folga cresce com a velocidade para ele não passar do ponto.
	var ate_o_fim: Vector3 = _agente.get_final_position() - global_position
	ate_o_fim.y = 0.0
	if _agente.is_navigation_finished() or ate_o_fim.length() <= maxf(DISTANCIA_DE_CHEGADA, perfil.velocidade * delta):
		_chegar()
		return
	if _esta_preso(delta):
		_destravar()
		return
	var proximo: Vector3 = _agente.get_next_path_position()
	var direcao: Vector3 = proximo - global_position
	direcao.y = 0.0
	if direcao.length() < 0.01:
		return
	direcao = direcao.normalized()
	velocity.x = direcao.x * perfil.velocidade
	velocity.z = direcao.z * perfil.velocidade
	_virar_para(direcao, delta)
	_tocar(&"walk")

## Verdadeiro quando ele passou SEGUNDOS_PARA_DESISTIR andando sem sair do lugar.
func _esta_preso(delta: float) -> bool:
	if global_position.distance_to(_posicao_conferida) >= PROGRESSO_MINIMO:
		_posicao_conferida = global_position
		_segundos_sem_progresso = 0.0
		return false
	_segundos_sem_progresso += delta
	return _segundos_sem_progresso >= SEGUNDOS_PARA_DESISTIR

## A malha e a colisão nem sempre concordam (um degrau, um objeto posto depois de gerar a
## malha). Em vez de andar no lugar para sempre, ele pula para o próximo ponto do caminho
## e segue dali. É um remendo de propósito: o conserto de verdade é gerar a malha de novo.
func _destravar() -> void:
	global_position = _agente.get_next_path_position()
	_posicao_conferida = global_position
	_segundos_sem_progresso = 0.0

func _chegar() -> void:
	_andando = false
	velocity.x = 0.0
	velocity.z = 0.0
	_modelo.rotation.y = atan2(_frente_no_destino.x, _frente_no_destino.z)
	_tocar(_animacao_parado)
	_pausa_da_conversa = randf_range(PAUSA_MINIMA_DA_CONVERSA, PAUSA_MAXIMA_DA_CONVERSA)

## Dois NPCs parados em idle perto um do outro se viram um para o outro e fazem gestos
## com pausas, cada um no seu tempo. Não é conversa de verdade, é encenação: vista de
## cima, vende a ideia de que o mundo está vivo. O balão aparece enquanto ele "fala".
func _encenar_conversa(delta: float) -> void:
	var gesticulando: bool = GESTOS_DA_CONVERSA.has(_animacao.current_animation) and _animacao.is_playing()
	_balao.visible = gesticulando and not _indicador.visible
	if not esta_parado_em_idle():
		return
	var parceiro: Npc = _parceiro_de_conversa()
	if parceiro == null:
		if not gesticulando:
			_tocar(&"idle")
		return
	_virar_para(parceiro.global_position - global_position, delta)
	if gesticulando:
		return
	_tocar(&"idle")
	_pausa_da_conversa -= delta
	if _pausa_da_conversa <= 0.0:
		_animacao.play(GESTOS_DA_CONVERSA.pick_random())
		_pausa_da_conversa = randf_range(PAUSA_MINIMA_DA_CONVERSA, PAUSA_MAXIMA_DA_CONVERSA)

func _parceiro_de_conversa() -> Npc:
	for no in get_tree().get_nodes_in_group(GRUPO):
		var outro: Npc = no as Npc
		if outro == null or outro == self or not outro.esta_parado_em_idle():
			continue
		if global_position.distance_to(outro.global_position) <= DISTANCIA_DE_CONVERSA:
			return outro
	return null

func _marcador(nome: StringName) -> Node3D:
	if nome == &"":
		return null
	for pontos in get_tree().get_nodes_in_group(GRUPO_DOS_PONTOS):
		var marcador: Node3D = pontos.get_node_or_null(NodePath(String(nome))) as Node3D
		if marcador != null:
			return marcador
	return null

## Um ponto fixo para cada NPC no círculo em volta do marcador, tirado do id dele. Assim
## ele para sempre no mesmo canto da praça, e nunca em cima de outro.
func _deslocamento_no_destino() -> Vector3:
	var angulo: float = float(perfil.id.hash() % 360) * TAU / 360.0
	return Vector3(cos(angulo), 0.0, sin(angulo)) * RAIO_NO_DESTINO

func _montar_modelo() -> void:
	_modelo = perfil.modelo.instantiate() as Node3D
	_modelo.name = "Modelo"
	add_child(_modelo)
	var animacoes: Array[Node] = _modelo.find_children("*", "AnimationPlayer", true, false)
	_animacao = animacoes[0] as AnimationPlayer
	for clipe in ANIMACOES_EM_LOOP:
		if _animacao.has_animation(clipe):
			_animacao.get_animation(clipe).loop_mode = Animation.LOOP_LINEAR
	# Depois de um gesto de conversa, volta para a pose parada em vez de congelar no fim.
	_animacao.animation_finished.connect(_ao_terminar_animacao)
	_tocar(&"idle")

func _ao_terminar_animacao(clipe: StringName) -> void:
	if _andando:
		return
	if GESTOS_DA_CONVERSA.has(clipe):
		_animacao.play(_animacao_parado)

func _virar_para(direcao: Vector3, delta: float) -> void:
	if Vector2(direcao.x, direcao.z).length() < 0.01:
		return
	var angulo_alvo: float = atan2(direcao.x, direcao.z)
	_modelo.rotation.y = lerp_angle(_modelo.rotation.y, angulo_alvo, minf(velocidade_de_giro * delta, 1.0))

func _tocar(clipe: StringName) -> void:
	if _animacao.current_animation != clipe:
		_animacao.play(clipe)
