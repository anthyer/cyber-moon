class_name LixeiraDoInventario
extends Panel

## A lixeira do menu de inventário: o que é solto aqui é apagado para sempre.
##
## Ela só recebe o pedido. Quem decide se o item pode ir embora e quem o tira do
## inventário é o menu, que também trata o pegar e soltar do controle.

## Um slot foi arrastado para cá, com o índice dele no InventoryManager.
signal descarte_pedido(indice_do_slot: int)
## O jogador confirmou (ui_accept) com a lixeira focada. Só faz algo se o menu tiver um
## item seguro pelo controle.
signal acionada

func _ready() -> void:
	focus_entered.connect(_atualizar_estilo)
	focus_exited.connect(_atualizar_estilo)
	_atualizar_estilo()

func _can_drop_data(_posicao: Vector2, dados: Variant) -> bool:
	return dados is Dictionary and dados.has("indice_origem")

func _drop_data(_posicao: Vector2, dados: Variant) -> void:
	descarte_pedido.emit(dados["indice_origem"])

func _gui_input(evento: InputEvent) -> void:
	if evento.is_action_pressed(&"ui_accept"):
		acionada.emit()
		accept_event()

## Roxo escuro parada e ciano com o foco, como qualquer slot. Nada vermelho: jogar fora
## é destrutivo, mas não é dano.
func _atualizar_estilo() -> void:
	theme_type_variation = &"SlotFocado" if has_focus() else &"SlotLixeira"
