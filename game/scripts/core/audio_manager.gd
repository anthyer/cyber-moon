extends Node

## Ponto único de reprodução de som do jogo.
##
## Efeito espacial sai de uma piscina de tocadores reaproveitados, em vez de um nó
## novo por som. Criar e destruir nó a cada passo geraria lixo constante numa ação
## que acontece duas vezes por segundo enquanto o jogador anda.

const TAMANHO_DA_PISCINA: int = 16
const DISTANCIA_MAXIMA_SFX: float = 30.0
const CAMINHO_MUSICA_PADRAO: String = "res://assets/audio/music/blush_response.wav"

var _piscina: Array[AudioStreamPlayer3D] = []
var _tocador_de_musica: AudioStreamPlayer
var _musica_atual: AudioStream = null

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
	add_child(_tocador_de_musica)
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
	
	# Força loop para arquivos .wav independentemente do .import cacheado
	if fluxo is AudioStreamWAV:
		fluxo.loop_mode = AudioStreamWAV.LOOP_FORWARD
		
	if not _tocador_de_musica.playing:
		_tocador_de_musica.stream = fluxo
		_tocador_de_musica.volume_db = -12.0
		_tocador_de_musica.play()
		return
	var transicao := create_tween()
	transicao.tween_property(_tocador_de_musica, "volume_db", -40.0, duracao_do_fade)
	transicao.tween_callback(func() -> void:
		_tocador_de_musica.stream = fluxo
		_tocador_de_musica.play()
	)
	transicao.tween_property(_tocador_de_musica, "volume_db", -12.0, duracao_do_fade)

func parar_musica(duracao_do_fade: float = 1.5) -> void:
	_musica_atual = null
	if not _tocador_de_musica.playing:
		return
	var transicao := create_tween()
	transicao.tween_property(_tocador_de_musica, "volume_db", -40.0, duracao_do_fade)
	transicao.tween_callback(_tocador_de_musica.stop)

func _tocador_livre() -> AudioStreamPlayer3D:
	for tocador in _piscina:
		if not tocador.playing:
			return tocador
	return null

func _tocar_musica_padrao() -> void:
	if not ResourceLoader.exists(CAMINHO_MUSICA_PADRAO):
		return
	tocar_musica(load(CAMINHO_MUSICA_PADRAO) as AudioStream, 0.0)
