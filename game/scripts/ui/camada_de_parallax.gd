class_name CamadaDeParallax
extends Sprite2D

## Uma camada do fundo da tela inicial que rola na horizontal sem fim.
##
## A textura repete (texture_repeat) e o que anda é a janela de leitura dela
## (region_rect), e não o nó: assim a camada nunca acaba, e não é preciso duas cópias
## lado a lado. Quanto mais perto do jogador a camada, mais rápida ela é, e é essa
## diferença de velocidade que dá a sensação de profundidade (parallax).

## Pixels da textura por segundo. Zero deixa a camada parada (o céu).
@export var velocidade: float = 0.0

func _ready() -> void:
	centered = false
	region_enabled = true
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

## A camada cobre esta largura, em pixels da textura.
func ajustar_largura(largura: float) -> void:
	region_rect = Rect2(region_rect.position, Vector2(largura, texture.get_height()))

func _process(delta: float) -> void:
	if velocidade == 0.0:
		return
	var deslocamento: float = fposmod(region_rect.position.x + velocidade * delta, texture.get_width())
	region_rect = Rect2(Vector2(deslocamento, 0.0), region_rect.size)
