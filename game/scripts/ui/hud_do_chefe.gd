class_name HudDoChefe
extends Control

## A barra de vida do chefe, no alto da tela, com o nome dele, a fase e os golpes que ele
## pode usar nela. Aparece quando a luta começa e some quando o chefe cai.
##
## Esta HUD não conhece a dungeon nem a sala do chefe: ela só escuta o EventBus. O chefe
## avisa que a luta começou, que trocou de fase e que caiu, e a barra reage. A vida é lida
## do próprio chefe a cada quadro, porque ela muda a cada golpe e, no jogo do convidado,
## chega pela rede sem sinal nenhum.
##
## A cor da fase vem do Theme: na fase 1 a barra é BarraChefe (ouro) e na fase 2 é
## BarraChefeFase2 (violeta), e o nome e a fase são pintados na mesma cor. A troca é mais
## agressiva para ser notada.

## O grupo pelo qual outras HUDs acham esta barra sem conhecer a classe dela. O aviso
## (HudAviso) usa para descer quando a barra está na tela, em vez de cobri-la.
const GRUPO: StringName = &"barra_do_chefe"
## O separador entre os nomes dos golpes na linha de baixo da barra.
const SEPARADOR_DOS_GOLPES: String = ", "

@onready var _titulo: Label = %Titulo
@onready var _rotulo_da_fase: Label = %Fase
@onready var _barra: ProgressBar = %Barra
@onready var _golpes: Label = %Golpes
@onready var _porcentagem: Label = %Porcentagem

var _chefe: Chefe

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir. É a mesma
	# saída das outras HUDs.
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group(GRUPO)
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
	_porcentagem.text = "%d%%" % ceili(_barra.value * 100.0)

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
	var segunda_fase: bool = fase >= 2
	_barra.theme_type_variation = &"BarraChefeFase2" if segunda_fase else &"BarraChefe"
	var cor: Color = CoresDaInterface.violeta() if segunda_fase else CoresDaInterface.ouro()
	_titulo.add_theme_color_override(&"font_color", cor)
	_rotulo_da_fase.add_theme_color_override(&"font_color", cor)
	_rotulo_da_fase.text = "Fase %d" % fase
	_golpes.text = SEPARADOR_DOS_GOLPES.join(_nomes_dos_golpes(segunda_fase))

## Os nomes dos ataques que o chefe pode sortear na fase em que está, na ordem do perfil.
func _nomes_dos_golpes(segunda_fase: bool) -> PackedStringArray:
	var nomes: PackedStringArray = []
	var perfil: PerfilChefe = _chefe.perfil as PerfilChefe
	for ataque: AtaqueDeChefe in perfil.ataques:
		if ataque.so_na_fase_2 and not segunda_fase:
			continue
		if ataque.nome != "":
			nomes.append(ataque.nome)
	return nomes
