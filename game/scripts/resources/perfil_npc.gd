class_name PerfilNpc
extends Resource

@export var id: String = ""
@export var nome_exibido: String = ""
@export var retrato: Texture2D
@export var relacionamento_inicial: int = 0
@export var relacionamento_maximo: int = 100
## O aniversário: o id da estação (um dos SeasonManager.ESTACOES) e o dia dentro dela,
## de 1 a 30. O calendário mostra, e o presente de aniversário vale mais (plano 16).
@export var estacao_do_aniversario: StringName = &"brotacao"
@export var dia_do_aniversario: int = 1
