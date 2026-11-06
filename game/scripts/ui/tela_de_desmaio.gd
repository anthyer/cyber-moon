extends Control

## Tela preta que cobre a troca de dia quando o jogador desmaia ou é derrotado.
##
## Sem tela de game over: perder é perder um dia. A tela escurece, o StatusManager
## avança o dia e restaura o status com a penalidade enquanto nada aparece, um texto
## curto conta o que aconteceu, e a tela clareia com o jogador já em casa.
##
## O visual do desmaio é o do mock: sem sangue e sem vermelho, a tela sai do ar como um
## sinal perdido, em violeta com o deslocamento de cor em magenta e ciano, e diz o que a
## queda custou. Dormir na cama usa a mesma tela, só com o texto.

const DURACAO_DO_ESCURECER: float = 1.0
const DURACAO_DO_TEXTO: float = 3.0
const DURACAO_DO_CLAREAR: float = 1.0

const TEXTO_DE_EXAUSTAO: String = "Você desmaiou de cansaço.\nAcordou em casa no dia seguinte, com menos fôlego."
const TEXTO_DE_FERIMENTO: String = "Você apagou na luta.\nAcordou em casa no dia seguinte, ainda com os machucados."
const TEXTO_DE_SONO: String = "Já passava da 1:00 e você caiu de sono onde estava.\nAcordou em casa no dia seguinte, com menos fôlego."
const TEXTO_DE_DORMIR: String = "Você dormiu bem.\nUm novo dia começou."

## O deslocamento de cor do "SINAL PERDIDO": as cópias em magenta e ciano ficam meio
## transparentes atrás do violeta.
const OPACIDADE_DO_DESLOCAMENTO: float = 0.8

@onready var escuro: ColorRect = $Escuro
## O que aparece e some junto: o título, o texto e o custo.
@onready var conteudo: Control = $Conteudo
@onready var sinal_perdido: Control = $Conteudo/SinalPerdido
@onready var texto: Label = $Conteudo/Texto
@onready var custo: Label = $Conteudo/Custo

var _em_andamento: bool = false

## A transição que pediram enquanto outra rodava. Fica guardada e roda logo depois.
var _pendente: Callable = Callable()

func _ready() -> void:
	# A sequência não pode parar se o jogo pausar no meio, senão a tela ficaria preta
	# para sempre. O tween segue o modo de processo deste nó.
	process_mode = Node.PROCESS_MODE_ALWAYS
	escuro.color = Color(CoresDaInterface.noite(), 0.0)
	conteudo.modulate.a = 0.0
	_pintar_sinal_perdido()
	StatusManager.player_fainted.connect(_ao_desmaiar)
	DayCycleManager.player_slept.connect(_ao_dormir)

func _ao_desmaiar(motivo: int) -> void:
	if _em_andamento:
		# Um desmaio que chega no meio de outra transição (o menu de debug pulando a hora
		# para a 1:00 enquanto a tela de dormir ainda está escura, por exemplo) não pode ser
		# descartado: o StatusManager já marcou o jogador como caído e o relógio já parou, e
		# só esta tela os solta. Ele espera a transição atual acabar e roda em seguida.
		_pendente = _ao_desmaiar.bind(motivo)
		return
	_em_andamento = true
	match motivo:
		StatusManager.Motivo.FERIMENTO:
			texto.text = TEXTO_DE_FERIMENTO
		StatusManager.Motivo.SONO:
			texto.text = TEXTO_DE_SONO
		_:
			texto.text = TEXTO_DE_EXAUSTAO
	sinal_perdido.visible = true
	custo.visible = true
	custo.text = _texto_do_custo(motivo)

	var sequencia: Tween = create_tween()
	sequencia.tween_property(escuro, "color:a", 1.0, DURACAO_DO_ESCURECER)
	# O dia só vira com a tela toda preta, para o jogador não ver o personagem ser
	# levado para casa.
	sequencia.tween_callback(StatusManager.acordar_no_dia_seguinte)
	sequencia.tween_property(conteudo, "modulate:a", 1.0, 0.3)
	sequencia.tween_interval(DURACAO_DO_TEXTO)
	sequencia.tween_property(conteudo, "modulate:a", 0.0, 0.3)
	sequencia.tween_property(escuro, "color:a", 0.0, DURACAO_DO_CLAREAR)
	sequencia.tween_callback(_ao_terminar)

## Dormir na cama usa a mesma tela, sem queda e sem penalidade: escurece, vira o dia e
## clareia. O sono forçado da 1:00 não passa por aqui, ele chega como desmaio.
func _ao_dormir(forcado: bool) -> void:
	if forcado:
		return
	if _em_andamento:
		# Mesmo motivo do desmaio: o DayCycleManager já está dormindo e espera a virada.
		_pendente = _ao_dormir.bind(false)
		return
	_em_andamento = true
	texto.text = TEXTO_DE_DORMIR
	sinal_perdido.visible = false
	custo.visible = false
	var sequencia: Tween = create_tween()
	sequencia.tween_property(escuro, "color:a", 1.0, DURACAO_DO_ESCURECER)
	sequencia.tween_callback(DayCycleManager.avancar_para_o_proximo_dia)
	sequencia.tween_property(conteudo, "modulate:a", 1.0, 0.3)
	sequencia.tween_interval(DURACAO_DO_TEXTO * 0.6)
	sequencia.tween_property(conteudo, "modulate:a", 0.0, 0.3)
	sequencia.tween_property(escuro, "color:a", 0.0, DURACAO_DO_CLAREAR)
	sequencia.tween_callback(_ao_terminar)

func _ao_terminar() -> void:
	_em_andamento = false
	if _pendente.is_valid():
		var proxima: Callable = _pendente
		_pendente = Callable()
		proxima.call()

## O que a queda custa, tirado da penalidade do StatusManager: a stamina sempre, e a vida
## também quando foi derrota na luta.
func _texto_do_custo(motivo: int) -> String:
	var stamina: int = roundi(StatusManager.FRACAO_DE_STAMINA_APOS_QUEDA * 100.0)
	if motivo == StatusManager.Motivo.FERIMENTO:
		var vida: int = roundi(StatusManager.FRACAO_DE_VIDA_APOS_DERROTA * 100.0)
		return "Custo: amanhã a vida começa em %d%% e a stamina em %d%%." % [vida, stamina]
	return "Custo: amanhã a stamina começa em %d%%." % stamina

func _pintar_sinal_perdido() -> void:
	var magenta: Label = sinal_perdido.get_node("Magenta") as Label
	var ciano: Label = sinal_perdido.get_node("Ciano") as Label
	var violeta: Label = sinal_perdido.get_node("Violeta") as Label
	magenta.add_theme_color_override(&"font_color", CoresDaInterface.magenta())
	ciano.add_theme_color_override(&"font_color", CoresDaInterface.ciano())
	violeta.add_theme_color_override(&"font_color", CoresDaInterface.violeta())
	magenta.modulate.a = OPACIDADE_DO_DESLOCAMENTO
	ciano.modulate.a = OPACIDADE_DO_DESLOCAMENTO
