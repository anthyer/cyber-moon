class_name Cultivo
extends Resource

@export var nome: String = ""
@export var tempo_de_crescimento_dias: int = 1
@export var estagios_de_crescimento: Array[Texture2D] = []
@export var item_colhido: Item
@export var quantidade_colhida: int = 1
