class_name HudDoChefe
extends Control

## A barra de vida do chefe, no alto da tela, com o nome dele em cima. Aparece quando a
## luta começa e some quando o chefe cai.
##
## Esta HUD não conhece a dungeon nem a sala do chefe: ela só escuta o EventBus. O chefe
## avisa que a luta começou, que trocou de fase e que caiu, e a barra reage. A vida é lida
## do próprio chefe a cada quadro, porque ela muda a cada golpe e, no jogo do convidado,
## chega pela rede sem sinal nenhum.

## A cor do enchimento em cada fase. A segunda é mais agressiva, para a troca ser notada.
@export var cor_da_fase_1: Color = Color(1.0, 0.75, 0.2)
@export var cor_da_fase_2: Color = Color(0.85, 0.35, 1.0)

@onready var _titulo: Label = $Centro/Linhas/Titulo
@onready var _barra: ProgressBar = $Centro/Linhas/Barra

var _chefe: Chefe
var _enchimento: StyleBoxFlat

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir. É a mesma
	# saída das outras HUDs.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	# O estilo do enchimento é copiado para a troca de cor não vazar para outra barra que
	# use o mesmo recurso.
	_enchimento = (_barra.get_theme_stylebox(&"fill") as StyleBoxFlat).duplicate() as StyleBoxFlat
	_barra.add_theme_stylebox_override(&"fill", _enchimento)
	EventBus.boss_engaged.connect(_ao_comecar_a_luta)
	EventBus.boss_phase_changed.connect(_ao_trocar_de_fase)
	EventBus.boss_defeated.connect(_ao_cair_o_chefe)

func _process(_delta: float) -> void:
	# O chefe pode sumir sem cair (a equipe saiu da dungeon). Sem conferir, a barra
	# ficaria na tela apontando para um nó que não existe mais.
	if _chefe != null and not is_instance_valid(_chefe):
		_chefe = null
	if _chefe == null:
		visible = false
		return
	visible = not get_tree().paused
	_barra.value = float(_chefe.vida_atual) / float(maxi(_chefe.vida_maxima_efetiva, 1))

func _ao_comecar_a_luta(chefe: Node3D) -> void:
	_chefe = chefe as Chefe
	if _chefe == null:
		return
	var perfil: PerfilChefe = _chefe.perfil as PerfilChefe
	_titulo.text = perfil.titulo if perfil.titulo != "" else perfil.nome
	_pintar_a_fase(_chefe.fase)

func _ao_trocar_de_fase(chefe: Node3D, fase: int) -> void:
	if chefe == _chefe:
		_pintar_a_fase(fase)

func _ao_cair_o_chefe(chefe: Node3D) -> void:
	if chefe == _chefe:
		_chefe = null

func _pintar_a_fase(fase: int) -> void:
	_enchimento.bg_color = cor_da_fase_2 if fase >= 2 else cor_da_fase_1
