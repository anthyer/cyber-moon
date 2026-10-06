extends Node

## Ponto único de reprodução de som do jogo.
##
## Efeito espacial sai de uma piscina de tocadores reaproveitados, em vez de um nó
## novo por som. Criar e destruir nó a cada passo geraria lixo constante numa ação
## que acontece duas vezes por segundo enquanto o jogador anda.

const TAMANHO_DA_PISCINA: int = 16
const DISTANCIA_MAXIMA_SFX: float = 30.0
const VOLUME_SILENCIO_DB: float = -40.0
const VOLUME_DO_AMBIENTE_DB: float = -10.0
const CAMINHO_MUSICA_PADRAO: String = "res://assets/audio/music/blush_response.ogg"

var _piscina: Array[AudioStreamPlayer3D] = []
var _tocador_de_musica: AudioStreamPlayer
var _musica_atual: AudioStream = null
## Som de ambiente em loop (a chuva). Não é posicionado, porque vem de todo lado.
var _tocador_de_ambiente: AudioStreamPlayer
var _ambiente_atual: AudioStream = null
var _transicao_do_ambiente: Tween

func _ready() -> void:
	EventBus.musica_solicitada.connect(tocar_musica.bind(1.5))
	for indice in TAMANHO_DA_PISCINA:
		var tocador := AudioStreamPlayer3D.new()
		tocador.bus = &"SFX"
		tocador.max_distance = DISTANCIA_MAXIMA_SFX
		add_child(tocador)
		_piscina.append(tocador)

	_tocador_de_musica = AudioStreamPlayer.new()
	_tocador_de_musica.bus = &"Musica"
	_tocador_de_musica.finished.connect(_tocador_de_musica.play)
	add_child(_tocador_de_musica)
	_tocador_de_ambiente = AudioStreamPlayer.new()
	_tocador_de_ambiente.bus = &"Ambiente"
	_tocador_de_ambiente.volume_db = VOLUME_SILENCIO_DB
	_tocador_de_ambiente.finished.connect(_ao_terminar_o_ambiente)
	add_child(_tocador_de_ambiente)
	EventBus.ambience_requested.connect(tocar_ambiente)
	_tocar_musica_padrao()

## Toca um efeito posicionado no mundo. Ignora a chamada quando o fluxo é nulo, que
## é o caso normal enquanto os clipes de áudio ainda não chegaram.
func tocar_sfx(fluxo: AudioStream, posicao: Vector3, volume_db: float = 0.0, tom: float = 1.0) -> AudioStreamPlayer3D:
	if fluxo == null:
		return null
	var tocador: AudioStreamPlayer3D = _tocador_livre()
	if tocador == null:
		return null
	tocador.stream = fluxo
	tocador.global_position = posicao
	tocador.volume_db = volume_db
	tocador.pitch_scale = tom
	tocador.play()
	return tocador

func tocar_musica(fluxo: AudioStream, duracao_do_fade: float = 1.5) -> void:
	if fluxo == null or fluxo == _musica_atual:
		return
	_musica_atual = fluxo
		
	if not _tocador_de_musica.playing:
		_tocador_de_musica.stream = fluxo
		_tocador_de_musica.volume_db = -18.0
		_tocador_de_musica.play()
		return
	var transicao := create_tween()
	transicao.tween_property(_tocador_de_musica, "volume_db", -40.0, duracao_do_fade)
	transicao.tween_callback(func() -> void:
		_tocador_de_musica.stream = fluxo
		_tocador_de_musica.play()
	)
	transicao.tween_property(_tocador_de_musica, "volume_db", -18.0, duracao_do_fade)

func parar_musica(duracao_do_fade: float = 1.5) -> void:
	_musica_atual = null
	if not _tocador_de_musica.playing:
		return
	var transicao := create_tween()
	transicao.tween_property(_tocador_de_musica, "volume_db", -40.0, duracao_do_fade)
	transicao.tween_callback(_tocador_de_musica.stop)

## Liga um som de ambiente em loop, com fade. Nulo desliga o que estiver tocando, que é o
## caso normal enquanto o clipe de chuva não chegou: nada toca e nada dá erro.
func tocar_ambiente(fluxo: AudioStream, duracao_do_fade: float = 2.0) -> void:
	if fluxo == _ambiente_atual:
		return
	_ambiente_atual = fluxo
	if _transicao_do_ambiente != null:
		_transicao_do_ambiente.kill()
	_transicao_do_ambiente = create_tween()
	if _tocador_de_ambiente.playing:
		_transicao_do_ambiente.tween_property(_tocador_de_ambiente, "volume_db", VOLUME_SILENCIO_DB, duracao_do_fade)
		_transicao_do_ambiente.tween_callback(_tocador_de_ambiente.stop)
	if fluxo == null:
		return
	_transicao_do_ambiente.tween_callback(func() -> void:
		_tocador_de_ambiente.stream = fluxo
		_tocador_de_ambiente.play()
	)
	_transicao_do_ambiente.tween_property(_tocador_de_ambiente, "volume_db", VOLUME_DO_AMBIENTE_DB, duracao_do_fade)

## Toca um som sem posição, uma vez, no bus de ambiente. É o trovão.
func tocar_no_ambiente(fluxo: AudioStream, volume_db: float = 0.0) -> void:
	if fluxo == null:
		return
	var tocador := AudioStreamPlayer.new()
	tocador.bus = &"Ambiente"
	tocador.stream = fluxo
	tocador.volume_db = volume_db
	tocador.finished.connect(tocador.queue_free)
	add_child(tocador)
	tocador.play()

func _ao_terminar_o_ambiente() -> void:
	if _ambiente_atual != null:
		_tocador_de_ambiente.play()

func _tocador_livre() -> AudioStreamPlayer3D:
	for tocador in _piscina:
		if not tocador.playing:
			return tocador
	return null

func _tocar_musica_padrao() -> void:
	if not ResourceLoader.exists(CAMINHO_MUSICA_PADRAO):
		return
	tocar_musica(load(CAMINHO_MUSICA_PADRAO) as AudioStream, 0.0)
