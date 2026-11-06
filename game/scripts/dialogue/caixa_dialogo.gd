class_name CaixaDialogo
extends Control

## A tela da conversa: a caixa de texto na parte de baixo e, atrás dela, os modelos 3D
## dos dois personagens, o jogador à esquerda e o NPC à direita, animados.
##
## Os modelos são de verdade, e não retratos: cada um fica no seu palco de modelo
## (ModelStage, scenes/ui/palco_de_modelo.tscn), desenhado atrás da caixa. Quem fala
## fica aceso e um pouco à frente; quem escuta fica mais escuro.
##
## Quem conduz a conversa é o DialogueManager. Esta tela só mostra e repassa o aperto de
## botão.

const CARACTERES_POR_SEGUNDO: float = 40.0
## Pelo mesmo motivo da trava do DialogueManager: o aperto que abriu a conversa não pode
## também completar a primeira fala.
const SEGUNDOS_DE_TRAVA_AO_ABRIR: float = 0.2
const ANIMACAO_PARADA: StringName = &"idle"
const NOME_DO_JOGADOR: String = "Você"

@onready var palco_do_jogador: ModelStage = %PalcoDoJogador
@onready var palco_do_morador: ModelStage = %PalcoDoMorador
@onready var nome_do_falante: Label = %NomeDoFalante
@onready var texto_da_fala: RichTextLabel = %TextoDaFala
@onready var indicador_de_avancar: Label = %IndicadorDeAvancar

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
	palco_do_morador.mostrar_cena(npc.perfil.modelo)
	palco_do_jogador.mostrar_jogador()
	palco_do_morador.definir_aceso(true, true)
	palco_do_jogador.definir_aceso(true, true)
	_segundos_aberta = 0.0
	visible = true

func _ao_mostrar_fala(no: NoDialogo) -> void:
	var fala_o_jogador: bool = no.falante_id == DialogueManager.ID_DO_JOGADOR
	nome_do_falante.text = NOME_DO_JOGADOR if fala_o_jogador else _nome_do_npc
	# O nome fica do lado de quem fala, na cor dele, para dar para saber de relance.
	nome_do_falante.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if fala_o_jogador else HORIZONTAL_ALIGNMENT_RIGHT
	nome_do_falante.add_theme_color_override(&"font_color", CoresDaInterface.ouro() if fala_o_jogador else CoresDaInterface.ciano())
	texto_da_fala.text = no.texto
	texto_da_fala.visible_characters = 0
	_caracteres_mostrados = 0.0
	var quem_fala: ModelStage = palco_do_jogador if fala_o_jogador else palco_do_morador
	var quem_escuta: ModelStage = palco_do_morador if fala_o_jogador else palco_do_jogador
	quem_fala.tocar(no.animacao)
	quem_fala.definir_aceso(true)
	quem_escuta.tocar(ANIMACAO_PARADA)
	quem_escuta.definir_aceso(false)

func _ao_terminar(_npc_id: String) -> void:
	visible = false
	palco_do_jogador.limpar()
	palco_do_morador.limpar()

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
