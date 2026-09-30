extends Control

@onready var rotulo: Label = $RotuloFerramenta

func _ready() -> void:
	EquipmentManager.tool_equipped.connect(_ao_trocar_ferramenta)
	_ao_trocar_ferramenta(EquipmentManager.ferramenta_atual())

## Sem ferramenta, o item em uso é a soqueira, e o nome dela vem do .tres.
func _ao_trocar_ferramenta(_ferramenta: Ferramenta) -> void:
	rotulo.text = EquipmentManager.item_em_uso().nome
