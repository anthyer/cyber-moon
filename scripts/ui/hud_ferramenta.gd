extends Control

@onready var rotulo: Label = $RotuloFerramenta

func _ready() -> void:
	EquipmentManager.tool_equipped.connect(_ao_trocar_ferramenta)
	_ao_trocar_ferramenta(EquipmentManager.ferramenta_atual())

func _ao_trocar_ferramenta(ferramenta: Ferramenta) -> void:
	rotulo.text = ferramenta.nome if ferramenta else "Socos"
