class_name ItemNoMundo
extends Node3D

## Um item caído no chão, esperando o jogador pegar.
##
## É uma cena só para todos os itens: a aparência vem do ícone do Item que ela
## representa, mostrado como um quadrado em pé. Gira devagar e flutua de leve, como o
## item dropado do Minecraft, para chamar atenção no cenário. O quadrado não usa
## billboard (sempre virado para a câmera) porque billboard anula a rotação e o
## giro deixaria de aparecer.
##
## Um quadrado sozinho vira uma linha quando fica de lado para a câmera. Para o item
## parecer ter espessura, o Visual ganha cópias do próprio sprite logo atrás dele,
## deslocadas um pouco, como um ícone recortado em papelão grosso. A última cópia é a
## face de trás e fica com a cor normal, para o item não escurecer quando vira de
## costas. As do meio ficam mais escuras e fazem o papel da lateral.

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

## Quantas cópias do sprite ficam atrás do Visual e a distância entre cada uma. Com o
## pixel_size de 0.025 do Visual, duas cópias a 0.0125 somam um pixel de espessura.
@export var copias_de_espessura: int = 2
@export var distancia_entre_copias: float = 0.0125
## Cor das cópias do meio, para a borda do item ler como lateral e não como um
## segundo ícone.
@export var cor_das_copias: Color = Color(0.6, 0.6, 0.6)

@onready var visual: Sprite3D = $Visual

var _altura_inicial_do_visual: float = 0.0
var _tempo: float = 0.0

func _ready() -> void:
	_altura_inicial_do_visual = visual.position.y
	if item != null and item.icone != null:
		visual.texture = item.icone
	_criar_copias_de_espessura()

func _process(delta: float) -> void:
	_tempo += delta
	rotate_y(velocidade_de_giro * delta)
	visual.position.y = _altura_inicial_do_visual + sin(_tempo * velocidade_da_flutuacao) * altura_da_flutuacao

## As cópias são filhas do Visual para acompanharem a flutuação e o giro sem código
## extra. Criadas depois da textura, para herdarem o ícone certo no duplicate().
func _criar_copias_de_espessura() -> void:
	for indice in copias_de_espessura:
		var copia: Sprite3D = visual.duplicate() as Sprite3D
		copia.name = "Espessura%d" % (indice + 1)
		copia.transform = Transform3D.IDENTITY
		copia.position.z = -distancia_entre_copias * (indice + 1)
		var eh_a_face_de_tras: bool = indice == copias_de_espessura - 1
		if not eh_a_face_de_tras:
			copia.modulate = cor_das_copias
		visual.add_child(copia)

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
