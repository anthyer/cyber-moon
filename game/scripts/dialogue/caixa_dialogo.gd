class_name CaixaDialogo
extends Control

## A tela da conversa: a caixa de texto na parte de baixo e, atrás dela, os modelos 3D
## dos dois personagens, o jogador à esquerda e o NPC à direita, animados.
##
## Os modelos são de verdade, e não retratos: ficam num SubViewport com mundo próprio
## (own_world_3d), câmera e luz próprias, desenhado como textura atrás da caixa. Assim a
## cena do jogo não aparece nesse palco, e os modelos do palco não aparecem no jogo.
##
## Quem conduz a conversa é o DialogueManager. Esta tela só mostra e repassa o aperto de
## botão.

const CARACTERES_POR_SEGUNDO: float = 40.0
## Pelo mesmo motivo da trava do DialogueManager: o aperto que abriu a conversa não pode
## também completar a primeira fala.
const SEGUNDOS_DE_TRAVA_AO_ABRIR: float = 0.2
const ANIMACOES_EM_LOOP: Array[StringName] = [&"idle"]
const NOME_DO_JOGADOR: String = "Você"
const COR_DO_NOME_DO_NPC: Color = Color(0.3, 0.95, 1.0)
const COR_DO_NOME_DO_JOGADOR: Color = Color(1.0, 0.85, 0.35)

@onready var suporte_esquerda: Node3D = %SuporteEsquerda
@onready var suporte_direita: Node3D = %SuporteDireita
@onready var nome_do_falante: Label = %NomeDoFalante
@onready var texto_da_fala: RichTextLabel = %TextoDaFala
@onready var indicador_de_avancar: Label = %IndicadorDeAvancar

var _animacao_do_jogador: AnimationPlayer
var _animacao_do_npc: AnimationPlayer
var _nome_do_npc: String = ""
## Quantos caracteres da fala já apareceram. É float para somar fração a cada quadro.
var _caracteres_mostrados: float = 0.0
var _segundos_aberta: float = 0.0

func _ready() -> void:
	visible = false
	DialogueManager.dialogue_started.connect(_ao_comecar)
	DialogueManager.line_shown.connect(_ao_mostrar_fala)
	DialogueManager.dialogue_ended.connect(_ao_terminar)

func _process(delta: float) -> void:
	if not visible:
		return
	_segundos_aberta += delta
	_escrever(delta)
	if _segundos_aberta < SEGUNDOS_DE_TRAVA_AO_ABRIR:
		return
	if InputManager.interagir_pressionado() or InputManager.atacar_pressionado():
		# O primeiro aperto completa a fala que ainda está sendo escrita; o seguinte avança.
		if _esta_escrevendo():
			_caracteres_mostrados = float(texto_da_fala.get_total_character_count())
			texto_da_fala.visible_characters = -1
		else:
			DialogueManager.avancar()
	elif Input.is_action_just_pressed(&"ui_cancel"):
		DialogueManager.encerrar()

func _ao_comecar(npc: Npc) -> void:
	_nome_do_npc = npc.perfil.nome_exibido
	_animacao_do_npc = _por_modelo(suporte_direita, npc.perfil.modelo)
	var jogador: Node = get_tree().get_first_node_in_group(&"jogador")
	var personagem: Node = jogador.get_node_or_null("Personagem") if jogador != null else null
	if personagem != null and personagem.scene_file_path != "":
		_animacao_do_jogador = _por_modelo(suporte_esquerda, load(personagem.scene_file_path) as PackedScene)
	_segundos_aberta = 0.0
	visible = true

func _ao_mostrar_fala(no: NoDialogo) -> void:
	var fala_o_jogador: bool = no.falante_id == DialogueManager.ID_DO_JOGADOR
	nome_do_falante.text = NOME_DO_JOGADOR if fala_o_jogador else _nome_do_npc
	# O nome fica do lado de quem fala, na cor dele, para dar para saber de relance.
	nome_do_falante.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if fala_o_jogador else HORIZONTAL_ALIGNMENT_RIGHT
	nome_do_falante.add_theme_color_override(&"font_color", COR_DO_NOME_DO_JOGADOR if fala_o_jogador else COR_DO_NOME_DO_NPC)
	texto_da_fala.text = no.texto
	texto_da_fala.visible_characters = 0
	_caracteres_mostrados = 0.0
	_tocar(_animacao_do_jogador if fala_o_jogador else _animacao_do_npc, no.animacao)
	_tocar(_animacao_do_npc if fala_o_jogador else _animacao_do_jogador, &"idle")

func _ao_terminar(_npc_id: String) -> void:
	visible = false
	for suporte: Node3D in [suporte_esquerda, suporte_direita]:
		for filho in suporte.get_children():
			filho.queue_free()
	_animacao_do_jogador = null
	_animacao_do_npc = null

## O texto aparece letra por letra, no ritmo de leitura.
func _escrever(delta: float) -> void:
	indicador_de_avancar.visible = not _esta_escrevendo()
	if not _esta_escrevendo():
		return
	_caracteres_mostrados += CARACTERES_POR_SEGUNDO * delta
	texto_da_fala.visible_characters = int(_caracteres_mostrados)
	if int(_caracteres_mostrados) >= texto_da_fala.get_total_character_count():
		texto_da_fala.visible_characters = -1

func _esta_escrevendo() -> bool:
	return texto_da_fala.visible_characters != -1

## Põe uma cópia do modelo no suporte e devolve o AnimationPlayer dela, já em idle.
func _por_modelo(suporte: Node3D, cena: PackedScene) -> AnimationPlayer:
	for filho in suporte.get_children():
		filho.queue_free()
	if cena == null:
		return null
	var modelo: Node3D = cena.instantiate() as Node3D
	suporte.add_child(modelo)
	var animacoes: Array[Node] = modelo.find_children("*", "AnimationPlayer", true, false)
	if animacoes.is_empty():
		return null
	var animacao: AnimationPlayer = animacoes[0] as AnimationPlayer
	for clipe in ANIMACOES_EM_LOOP:
		if animacao.has_animation(clipe):
			animacao.get_animation(clipe).loop_mode = Animation.LOOP_LINEAR
	animacao.play(&"idle")
	return animacao

func _tocar(animacao: AnimationPlayer, clipe: StringName) -> void:
	if animacao == null:
		return
	var escolhido: StringName = clipe if animacao.has_animation(clipe) else &"idle"
	if animacao.current_animation != escolhido:
		animacao.play(escolhido)
