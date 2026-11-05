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
