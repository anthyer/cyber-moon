class_name AlvoDeTreino
extends StaticBody3D

## Boneco parado para testar golpes e tiros.
##
## Não revida e não morre: serve para medir dano, alcance e ritmo das armas com calma,
## o que não dá para fazer com um inimigo batendo de volta. Fica no playground junto dos
## inimigos de teste, enquanto o combate estiver sendo ajustado.
##
## Segue o contrato de dano do jogo: tem o método receber_dano(quantidade, origem). Fica
## na camada inimigo, que é a que a hitbox de ataque e o projétil enxergam.

signal atingido(quantidade: int)

const SEGUNDOS_DO_NUMERO: float = 0.8
const ALTURA_QUE_O_NUMERO_SOBE: float = 0.5
const SEGUNDOS_DO_TRANCO: float = 0.12

## Soma de todo o dano recebido, para conferir os números das armas no teste.
@export var dano_total: int = 0

@onready var visual: Node3D = $Visual

func receber_dano(quantidade: int, _origem: Node3D) -> void:
	dano_total += quantidade
	atingido.emit(quantidade)
	_dar_tranco()
	_mostrar_numero(quantidade)

## O boneco encolhe e volta, para o acerto ser visível mesmo sem som.
func _dar_tranco() -> void:
	var tranco: Tween = create_tween()
	tranco.tween_property(visual, "scale", Vector3(1.2, 0.8, 1.2), SEGUNDOS_DO_TRANCO * 0.5)
	tranco.tween_property(visual, "scale", Vector3.ONE, SEGUNDOS_DO_TRANCO * 0.5)

func _mostrar_numero(quantidade: int) -> void:
	var numero: Label3D = Label3D.new()
	numero.text = str(quantidade)
	numero.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	numero.no_depth_test = true
	numero.font_size = 48
	numero.outline_size = 10
	numero.modulate = Color(1.0, 0.9, 0.3)
	add_child(numero)
	numero.position = Vector3(0.0, 1.0, 0.0)
	var subida: Tween = create_tween()
	subida.set_parallel(true)
	subida.tween_property(numero, "position:y", numero.position.y + ALTURA_QUE_O_NUMERO_SOBE, SEGUNDOS_DO_NUMERO)
	subida.tween_property(numero, "modulate:a", 0.0, SEGUNDOS_DO_NUMERO)
	subida.chain().tween_callback(numero.queue_free)
