class_name PontoDeInimigo
extends Marker3D

## Marca onde nasce um inimigo da dungeon, e qual. A cena da dungeon tem um destes por
## inimigo; a ordem deles na árvore é o número do inimigo na rede, igual em todos os jogos.
## Com um PerfilChefe, o que nasce é um subchefe ou um chefe.

const CENA_DO_INIMIGO: PackedScene = preload("res://scenes/combat/inimigo.tscn")
const CAMINHO_DA_CENA_DO_CHEFE: String = "res://scenes/combat/chefe.tscn"

@export var perfil: PerfilInimigo

## Cria o inimigo deste ponto, ainda fora da árvore. O chefe usa uma cena própria, carregada
## só quando faz falta.
func criar_inimigo() -> Inimigo:
	if perfil == null:
		return null
	var cena: PackedScene = CENA_DO_INIMIGO
	if perfil is PerfilChefe:
		cena = load(CAMINHO_DA_CENA_DO_CHEFE) as PackedScene
	var inimigo: Inimigo = cena.instantiate() as Inimigo
	inimigo.perfil = perfil
	return inimigo
