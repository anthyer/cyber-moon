class_name PerfilProtagonista
extends Resource

## Um dos seis visuais que o jogador escolhe antes do jogo (plano 39). O tipo de corpo
## não muda nada na mecânica: vida, stamina, golpe, animação e preço são os mesmos. Só o
## visual muda.
##
## A tela diz "Tipo 1" e "Tipo 2", sem citar gênero, e o identificador também não cita.

const PASTA: String = "res://resources/protagonistas/"
## Quem não escolheu (jogo salvo antes do plano 39) fica com este: é a mesma base do
## modelo que o jogador usava antes, e ninguém percebe a troca.
const ID_PADRAO: StringName = &"protagonista_2c"

@export var id: StringName = &""
## 1 ou 2.
@export_range(1, 2) var body_type: int = 1
## O nome do visual na tela ("Palha").
@export var nome_do_visual: String = ""
@export var modelo: PackedScene

## O perfil com este id, ou null se ele não existe (ainda não foi modelado).
static func carregar(id_do_perfil: StringName) -> PerfilProtagonista:
	var caminho: String = PASTA + String(id_do_perfil) + ".tres"
	if not ResourceLoader.exists(caminho):
		return null
	return load(caminho) as PerfilProtagonista

## Veste um modelo de gente que já está na cena com este visual. Todos os modelos de gente
## saem do mesmo esqueleto da Kenney, então basta trocar a malha e a pele de cada parte do
## corpo: o nó do modelo e o AnimationPlayer dele continuam os mesmos, e quem guardou
## referência a eles não percebe a troca.
func vestir(modelo_na_cena: Node) -> void:
	if modelo == null or modelo_na_cena == null:
		return
	var modelo_novo: Node = modelo.instantiate()
	var esqueleto_novo: Skeleton3D = modelo_novo.find_children("*", "Skeleton3D", true, false)[0]
	var esqueleto_atual: Skeleton3D = modelo_na_cena.find_children("*", "Skeleton3D", true, false)[0]
	for parte_nova in esqueleto_novo.get_children():
		var nova: MeshInstance3D = parte_nova as MeshInstance3D
		var atual: MeshInstance3D = esqueleto_atual.get_node_or_null(NodePath(parte_nova.name)) as MeshInstance3D
		if nova == null or atual == null:
			continue
		atual.mesh = nova.mesh
		atual.skin = nova.skin
	modelo_novo.free()
