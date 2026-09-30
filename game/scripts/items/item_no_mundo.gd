class_name ItemNoMundo
extends Node3D

## Um item caído no chão, esperando o jogador pegar.
##
## É uma cena só para todos os itens: a aparência vem do ícone do Item que ela
## representa, mostrado como um quadrado em pé. Gira devagar e flutua de leve, como o
## item dropado do Minecraft, para chamar atenção no cenário. O quadrado não usa
## billboard (sempre virado para a câmera) porque billboard anula a rotação e o
## giro deixaria de aparecer.

## Carregada com load() dentro de soltar(), e não com preload(), porque a cena já
## aponta para este script e o preload criaria uma referência circular.
const CAMINHO_DA_CENA: String = "res://scenes/items/item_no_mundo.tscn"

## Raio máximo do empurrão aleatório ao soltar, para dois itens soltos no mesmo
## ponto não nascerem um exatamente em cima do outro.
const ESPALHAMENTO_AO_SOLTAR: float = 0.3

@export var item: Item
@export var quantidade: int = 1

@export var velocidade_de_giro: float = 1.5
@export var altura_da_flutuacao: float = 0.08
@export var velocidade_da_flutuacao: float = 2.0

@onready var visual: Sprite3D = $Visual

var _altura_inicial_do_visual: float = 0.0
var _tempo: float = 0.0

func _ready() -> void:
	_altura_inicial_do_visual = visual.position.y
	if item != null and item.icone != null:
		visual.texture = item.icone

func _process(delta: float) -> void:
	_tempo += delta
	rotate_y(velocidade_de_giro * delta)
	visual.position.y = _altura_inicial_do_visual + sin(_tempo * velocidade_da_flutuacao) * altura_da_flutuacao

## Cria uma instância já configurada e adiciona na cena, com um empurrão para
## o item não nascer exatamente em cima de outro.
static func soltar(item_solto: Item, quantidade_solta: int, posicao: Vector3, pai: Node) -> ItemNoMundo:
	var cena: PackedScene = load(CAMINHO_DA_CENA) as PackedScene
	var instancia: ItemNoMundo = cena.instantiate() as ItemNoMundo
	instancia.item = item_solto
	instancia.quantidade = quantidade_solta
	var empurrao: Vector3 = Vector3(
		randf_range(-ESPALHAMENTO_AO_SOLTAR, ESPALHAMENTO_AO_SOLTAR),
		0.0,
		randf_range(-ESPALHAMENTO_AO_SOLTAR, ESPALHAMENTO_AO_SOLTAR)
	)
	pai.add_child(instancia)
	instancia.global_position = posicao + empurrao
	return instancia

## Chamado quando o jogador interage. Tenta colocar no inventário e se some.
## Retorna false quando o inventário estava cheio, e aí o item continua no chão.
## Por enquanto sempre dá certo: o InventoryManager ainda não tem limite, e o caso
## de inventário cheio nasce no plano 04.
func coletar() -> bool:
	if item == null:
		return false
	InventoryManager.adicionar_item(item, quantidade)
	EventBus.item_picked_up.emit(item, quantidade)
	queue_free()
	return true

## Contrato de interação: todo nó interagível tem este método, e a AreaInteracao do
## jogador só chama ele, sem saber se o alvo é item, NPC ou baú.
func interagir() -> void:
	coletar()
