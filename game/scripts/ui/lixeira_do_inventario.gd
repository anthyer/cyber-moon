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

const COR_DE_FUNDO: Color = Color(0.12, 0.06, 0.08, 0.85)
const COR_DA_BORDA: Color = Color(0.5, 0.25, 0.3, 1.0)
const COR_DA_BORDA_FOCADA: Color = Color(1.0, 0.35, 0.4, 1.0)

var _estilo: StyleBoxFlat = StyleBoxFlat.new()

func _ready() -> void:
	_estilo.bg_color = COR_DE_FUNDO
	_estilo.set_corner_radius_all(4)
	_estilo.set_border_width_all(2)
	add_theme_stylebox_override(&"panel", _estilo)
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

func _atualizar_estilo() -> void:
	_estilo.border_color = COR_DA_BORDA_FOCADA if has_focus() else COR_DA_BORDA
