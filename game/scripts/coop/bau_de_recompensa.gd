class_name BauDeRecompensa
extends Node3D

## O baú que aparece quando o chefe final da dungeon cai. Abrir entrega a recompensa:
## créditos e materiais raros, o bônus do objetivo paralelo, e o troféu na primeira
## vitória de todas.
##
## O baú é de cada jogador: em equipe, cada um abre o seu no próprio jogo, e a regra de
## uma recompensa por dia vale por jogador. Quem dá e quem lembra é o DungeonManager; o
## baú só pede.

const GRUPO_DO_OBJETIVO: StringName = &"objetivo_paralelo"
const CAMADA_MUNDO: int = 1
const CAMADA_DE_INTERACAO: int = 32

## A tampa é uma parte do modelo importado, achada pelo nome dado no Blender.
@onready var _tampa: Node3D = $Modelo.find_child("Tampa", true, false) as Node3D
@onready var _corpo: StaticBody3D = $Corpo
@onready var _area: Area3D = $AreaDoBau

var _aberto: bool = false

func _ready() -> void:
	# Escondido e sem colisão até o chefe cair: antes disso ele não existe para o jogador.
	visible = false
	_corpo.collision_layer = 0
	_area.collision_layer = 0
	EventBus.boss_defeated.connect(_ao_cair_chefe)

## Contrato de interação do jogo (ver AreaDeInteracao).
func interagir() -> void:
	if not visible:
		return
	var recompensa: Dictionary = DungeonManager.receber_recompensa(DungeonManager.definicao_atual(), _objetivo_cumprido())
	if recompensa.is_empty():
		EventBus.notice_requested.emit("Você já pegou a recompensa deste chefe hoje.")
		return
	EventBus.notice_requested.emit(_texto_da_recompensa(recompensa))
	EventBus.dungeon_reward_claimed.emit(global_position)
	_abrir()

## Só o chefe do fim da dungeon faz o baú aparecer. O subchefe não.
func _ao_cair_chefe(chefe: Node3D) -> void:
	if visible or chefe == null:
		return
	var perfil: PerfilChefe = chefe.get(&"perfil") as PerfilChefe
	if perfil == null or not perfil.eh_chefe_final:
		return
	visible = true
	_corpo.collision_layer = CAMADA_MUNDO
	_area.collision_layer = CAMADA_DE_INTERACAO
	EventBus.notice_requested.emit("O chefe caiu. O baú de recompensa apareceu.")

## O objetivo paralelo da dungeon é um nó no grupo "objetivo_paralelo", com a propriedade
## concluido. Sem objetivo na dungeon, não há bônus.
func _objetivo_cumprido() -> bool:
	var dungeon: Dungeon = DungeonManager.dungeon_atual()
	if dungeon == null:
		return false
	for objetivo in get_tree().get_nodes_in_group(GRUPO_DO_OBJETIVO):
		if dungeon.is_ancestor_of(objetivo):
			return bool(objetivo.get(&"concluido"))
	return false

func _texto_da_recompensa(recompensa: Dictionary) -> String:
	var partes: PackedStringArray = ["%d créditos" % int(recompensa.get("creditos", 0))]
	var materiais: Array = recompensa.get("materiais", [])
	if materiais.size() == 1:
		partes.append("1 material raro")
	elif materiais.size() > 1:
		partes.append("%d materiais raros" % materiais.size())
	var trofeu: Item = recompensa.get("trofeu", null) as Item
	if trofeu != null:
		partes.append("o troféu %s" % trofeu.nome)
	# "a, b e c": vírgula entre as partes e "e" antes da última.
	var texto: String = partes[0]
	for indice in range(1, partes.size()):
		texto += (" e " if indice == partes.size() - 1 else ", ") + partes[indice]
	return "Recompensa: %s." % texto

## A tampa levanta e fica aberta, para dar para ver que este baú já foi usado.
func _abrir() -> void:
	if _aberto:
		return
	_aberto = true
	var giro: Tween = create_tween()
	giro.tween_property(_tampa, "rotation_degrees:x", -70.0, 0.4)
