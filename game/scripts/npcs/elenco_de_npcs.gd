class_name ElencoDeNpcs
extends Node3D

## Põe na fase um NPC para cada perfil de resources/npcs/. Cada um nasce na própria casa
## e segue a rotina dali.
##
## A fase não lista os NPCs um por um: basta ter este nó e os marcadores de rotina. Criar
## um NPC novo é criar o .tres dele, e ele aparece em toda fase que tiver o elenco.

const PASTA_DOS_PERFIS: String = "res://resources/npcs/"
const CENA_DO_NPC: PackedScene = preload("res://scenes/npcs/npc.tscn")

func _ready() -> void:
	for perfil in carregar_perfis():
		if perfil.modelo == null:
			continue
		var npc: Npc = CENA_DO_NPC.instantiate() as Npc
		npc.perfil = perfil
		npc.name = perfil.id.capitalize()
		add_child(npc)

## Todos os perfis da pasta. No jogo exportado o Godot lista os recursos com ".remap" no
## fim do nome, e o load precisa do nome sem ele.
static func carregar_perfis() -> Array[PerfilNpc]:
	var perfis: Array[PerfilNpc] = []
	var pasta: DirAccess = DirAccess.open(PASTA_DOS_PERFIS)
	if pasta == null:
		return perfis
	for arquivo in pasta.get_files():
		var nome: String = arquivo.trim_suffix(".remap")
		if not nome.ends_with(".tres"):
			continue
		var perfil: PerfilNpc = load(PASTA_DOS_PERFIS + nome) as PerfilNpc
		if perfil != null:
			perfis.append(perfil)
	return perfis
