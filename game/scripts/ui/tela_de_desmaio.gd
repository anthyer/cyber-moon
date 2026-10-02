extends Control

## Tela preta que cobre a troca de dia quando o jogador desmaia ou é derrotado.
##
## Sem tela de game over: perder é perder um dia. A tela escurece, o StatusManager
## avança o dia e restaura o status com a penalidade enquanto nada aparece, um texto
## curto conta o que aconteceu, e a tela clareia com o jogador já em casa.

const DURACAO_DO_ESCURECER: float = 1.0
const DURACAO_DO_TEXTO: float = 3.0
const DURACAO_DO_CLAREAR: float = 1.0

const TEXTO_DE_EXAUSTAO: String = "Você desmaiou de cansaço.\nAcordou em casa no dia seguinte, com menos fôlego."
const TEXTO_DE_FERIMENTO: String = "Você foi derrotado.\nAcordou em casa no dia seguinte, ainda machucado."
const TEXTO_DE_SONO: String = "Já passava da 1:00 e você caiu de sono onde estava.\nAcordou em casa no dia seguinte, com menos fôlego."
const TEXTO_DE_DORMIR: String = "Você dormiu bem.\nUm novo dia começou."

@onready var escuro: ColorRect = $Escuro
@onready var texto: Label = $Texto

var _em_andamento: bool = false

func _ready() -> void:
	# A sequência não pode parar se o jogo pausar no meio, senão a tela ficaria preta
	# para sempre. O tween segue o modo de processo deste nó.
	process_mode = Node.PROCESS_MODE_ALWAYS
	escuro.color.a = 0.0
	texto.modulate.a = 0.0
	StatusManager.player_fainted.connect(_ao_desmaiar)
	DayCycleManager.player_slept.connect(_ao_dormir)

func _ao_desmaiar(motivo: int) -> void:
	if _em_andamento:
		return
	_em_andamento = true
	match motivo:
		StatusManager.Motivo.FERIMENTO:
			texto.text = TEXTO_DE_FERIMENTO
		StatusManager.Motivo.SONO:
			texto.text = TEXTO_DE_SONO
		_:
			texto.text = TEXTO_DE_EXAUSTAO

	var sequencia: Tween = create_tween()
	sequencia.tween_property(escuro, "color:a", 1.0, DURACAO_DO_ESCURECER)
	# O dia só vira com a tela toda preta, para o jogador não ver o personagem ser
	# levado para casa.
	sequencia.tween_callback(StatusManager.acordar_no_dia_seguinte)
	sequencia.tween_property(texto, "modulate:a", 1.0, 0.3)
	sequencia.tween_interval(DURACAO_DO_TEXTO)
	sequencia.tween_property(texto, "modulate:a", 0.0, 0.3)
	sequencia.tween_property(escuro, "color:a", 0.0, DURACAO_DO_CLAREAR)
	sequencia.tween_callback(_ao_terminar)

## Dormir na cama usa a mesma tela, sem queda e sem penalidade: escurece, vira o dia e
## clareia. O sono forçado da 1:00 não passa por aqui, ele chega como desmaio.
func _ao_dormir(forcado: bool) -> void:
	if forcado or _em_andamento:
		return
	_em_andamento = true
	texto.text = TEXTO_DE_DORMIR
	var sequencia: Tween = create_tween()
	sequencia.tween_property(escuro, "color:a", 1.0, DURACAO_DO_ESCURECER)
	sequencia.tween_callback(DayCycleManager.avancar_para_o_proximo_dia)
	sequencia.tween_property(texto, "modulate:a", 1.0, 0.3)
	sequencia.tween_interval(DURACAO_DO_TEXTO * 0.6)
	sequencia.tween_property(texto, "modulate:a", 0.0, 0.3)
	sequencia.tween_property(escuro, "color:a", 0.0, DURACAO_DO_CLAREAR)
	sequencia.tween_callback(_ao_terminar)

func _ao_terminar() -> void:
	_em_andamento = false
