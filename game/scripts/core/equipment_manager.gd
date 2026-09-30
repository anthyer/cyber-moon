extends Node

signal tool_equipped(ferramenta: Ferramenta)

# Este @export nao tem efeito em runtime: este autoload eh registrado como
# script puro (nao cena), entao nao existe Inspector pra editar esse array.
# Na pratica ele funciona como uma constante populada pelos preload() abaixo.
@export var ferramentas: Array[Ferramenta] = [
	preload("res://resources/items/ferramentas/enxada.tres"),
	preload("res://resources/items/ferramentas/regador.tres"),
	preload("res://resources/items/ferramentas/picareta.tres"),
]
var indice_atual: int = -1

## A ferramenta em uso é a mesma coisa que o espaço de solo do inventário. As duas
## pontas ficam sincronizadas: trocar pelas teclas atualiza o espaço, e equipar pelo
## menu atualiza a ferramenta. Até o plano 05 trocar as teclas pela barra rápida, as
## duas formas de trocar convivem.
func _ready() -> void:
	# O jogador começa com as ferramentas no inventário, senão não haveria o que
	# equipar no espaço de solo. Este autoload vem depois do InventoryManager na lista
	# do project.godot, então o inventário já existe aqui.
	for ferramenta in ferramentas:
		InventoryManager.adicionar_item(ferramenta, 1)
	InventoryManager.equipment_changed.connect(_ao_mudar_equipamento)

func equipar_indice(indice: int) -> void:
	if indice < -1 or indice >= ferramentas.size():
		return
	indice_atual = indice
	tool_equipped.emit(ferramenta_atual())
	_sincronizar_espaco_de_solo()

func ciclar(direcao: int) -> void:
	var total: int = ferramentas.size() + 1
	var posicao: int = indice_atual + 1
	posicao = (posicao + direcao + total) % total
	equipar_indice(posicao - 1)

func ferramenta_atual() -> Ferramenta:
	return ferramentas[indice_atual] if indice_atual >= 0 else null

func _sincronizar_espaco_de_solo() -> void:
	var ferramenta: Ferramenta = ferramenta_atual()
	var indice_do_slot: int = InventoryManager.indice_do_item(ferramenta) if ferramenta != null else -1
	if indice_do_slot == -1:
		InventoryManager.desequipar(InventoryManager.Espaco.SOLO)
	else:
		InventoryManager.equipar(InventoryManager.Espaco.SOLO, indice_do_slot)

## Só reage quando a ferramenta mudou de fato, o que corta o vaivém entre os dois
## autoloads: o inventário avisa, esta função troca e não devolve o aviso.
func _ao_mudar_equipamento(espaco: InventoryManager.Espaco, item: Item) -> void:
	if espaco != InventoryManager.Espaco.SOLO:
		return
	var novo_indice: int = ferramentas.find(item as Ferramenta) if item != null else -1
	if novo_indice == indice_atual:
		return
	indice_atual = novo_indice
	tool_equipped.emit(ferramenta_atual())
