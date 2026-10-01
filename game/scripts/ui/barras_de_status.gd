class_name BarrasDeStatus
extends VBoxContainer

## Barras de vida e stamina do jogador, com o nível e a experiência.
##
## É um componente só, usado em dois lugares: na HUD durante o jogo e dentro do menu de
## pausa. Ele só mostra. Quem guarda os números é o StatusManager, e o componente
## escuta os sinais dele e não conhece mais nada.

## Abaixo desta fração da stamina máxima a barra pisca. É um aviso barato de que o
## desmaio está perto.
const FRACAO_DE_STAMINA_BAIXA: float = 0.2
const DURACAO_DA_PISCADA: float = 0.35
const OPACIDADE_DA_PISCADA: float = 0.35

@onready var barra_de_vida: ProgressBar = $Vida
@onready var valor_da_vida: Label = $Vida/Valor
@onready var barra_de_stamina: ProgressBar = $Stamina
@onready var valor_da_stamina: Label = $Stamina/Valor
@onready var rotulo_do_nivel: Label = $LinhaDoNivel/Nivel
@onready var barra_de_experiencia: ProgressBar = $LinhaDoNivel/Experiencia

var _piscada: Tween = null

func _ready() -> void:
	# O componente aparece dentro do menu de pausa, e a piscada da stamina precisa
	# continuar com o jogo pausado. O tween segue o modo de processo do nó dele.
	process_mode = Node.PROCESS_MODE_ALWAYS
	StatusManager.health_changed.connect(_ao_mudar_vida)
	StatusManager.stamina_changed.connect(_ao_mudar_stamina)
	StatusManager.level_changed.connect(_ao_mudar_nivel)
	StatusManager.experience_changed.connect(_ao_mudar_experiencia)
	_ao_mudar_vida(StatusManager.vida_atual, StatusManager.vida_maxima())
	_ao_mudar_stamina(StatusManager.stamina_atual, StatusManager.stamina_maxima())
	_ao_mudar_nivel(StatusManager.nivel)
	_ao_mudar_experiencia(StatusManager.experiencia, StatusManager.experiencia_para_o_proximo_nivel())

func _ao_mudar_vida(atual: int, maxima: int) -> void:
	barra_de_vida.max_value = maxima
	barra_de_vida.value = atual
	valor_da_vida.text = "%d / %d" % [atual, maxima]

func _ao_mudar_stamina(atual: float, maxima: float) -> void:
	barra_de_stamina.max_value = maxima
	barra_de_stamina.value = atual
	# Arredonda para cima para a barra não mostrar 0 enquanto ainda resta um pouco.
	valor_da_stamina.text = "%d / %d" % [ceili(atual), ceili(maxima)]
	_definir_piscada(maxima > 0.0 and atual / maxima < FRACAO_DE_STAMINA_BAIXA)

func _ao_mudar_nivel(novo_nivel: int) -> void:
	rotulo_do_nivel.text = "Nv. %d" % novo_nivel

func _ao_mudar_experiencia(atual: int, para_o_proximo: int) -> void:
	barra_de_experiencia.max_value = maxi(para_o_proximo, 1)
	barra_de_experiencia.value = atual

func _definir_piscada(deve_piscar: bool) -> void:
	if deve_piscar == (_piscada != null):
		return
	if not deve_piscar:
		_piscada.kill()
		_piscada = null
		barra_de_stamina.modulate.a = 1.0
		return
	_piscada = create_tween().set_loops()
	_piscada.tween_property(barra_de_stamina, "modulate:a", OPACIDADE_DA_PISCADA, DURACAO_DA_PISCADA)
	_piscada.tween_property(barra_de_stamina, "modulate:a", 1.0, DURACAO_DA_PISCADA)
