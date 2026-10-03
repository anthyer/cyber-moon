class_name GramaDaEstacao
extends Node

## Tinge a grama do chão com a cor da estação: verde vivo na Brotação, amarelada na
## Estiagem, ocre na Colheita e acinzentada no Apagão. Mexe só na cor do material, o que
## é barato e muda bastante a leitura da cena sem arte nova.

## O material compartilhado pelos planos de grama da cena. Mudar ele muda todos de uma vez.
@export var material_da_grama: StandardMaterial3D

## A cor que o material tinha no editor. A estação multiplica esta, e não a cor atual,
## senão cada virada de estação tingiria por cima da anterior.
var _cor_original: Color = Color.WHITE

func _ready() -> void:
	if material_da_grama == null:
		push_warning("GramaDaEstacao sem material, a grama não muda com a estação.")
		return
	_cor_original = material_da_grama.albedo_color
	SeasonManager.season_changed.connect(_ao_mudar_estacao)
	_aplicar(SeasonManager.perfil_atual())

func _ao_mudar_estacao(_nova: StringName) -> void:
	_aplicar(SeasonManager.perfil_atual())

func _aplicar(perfil: PerfilEstacao) -> void:
	var cor: Color = _cor_original * perfil.cor_da_grama
	cor.r = clampf(cor.r, 0.0, 1.0)
	cor.g = clampf(cor.g, 0.0, 1.0)
	cor.b = clampf(cor.b, 0.0, 1.0)
	cor.a = _cor_original.a
	material_da_grama.albedo_color = cor
