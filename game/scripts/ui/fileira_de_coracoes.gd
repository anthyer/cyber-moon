class_name FileiraDeCoracoes
extends HBoxContainer

## Os dez corações da amizade numa fileira, como no mock da conversa: cheios em rosa até o
## número de corações, o resto apagado. Cada coração é o CoracaoDePixel, o mesmo desenho
## da aba de relacionamentos e do calendário.
##
##     coracoes.mostrar(RelationshipManager.coracoes(npc_id))

const ESPACO_ENTRE_CORACOES: int = 3

var _coracoes: Array[TextureRect] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override(&"separation", ESPACO_ENTRE_CORACOES)
	for indice in RelationshipManager.CORACOES_MAXIMOS:
		var coracao: TextureRect = CoracaoDePixel.novo(CoresDaInterface.borda())
		add_child(coracao)
		_coracoes.append(coracao)

func mostrar(cheios: int) -> void:
	for indice in _coracoes.size():
		_coracoes[indice].modulate = CoresDaInterface.rosa() if indice < cheios else CoresDaInterface.borda()
