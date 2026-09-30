class_name ItemNoMundo
extends Node3D

## Um item caído no chão, esperando o jogador pegar.
##
## É uma cena só para todos os itens: a aparência vem do ícone do Item que ela
## representa, mostrado como um quadrado em pé. Gira devagar e flutua de leve, como o
## item dropado do Minecraft, para chamar atenção no cenário.
##
## A coleta é automática, também como no Minecraft: quando o jogador entra no raio da
## AreaDeAtracao, o item voa até ele ganhando velocidade, e entra no inventário ao
## encostar no corpo do jogador (AreaDeColeta). Não precisa apertar botão. O quadrado não usa
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

## Tempo em que um item recém-solto não é atraído. Sem isso, um item que cai do lado do
## jogador (colheita, drop de inimigo, item largado com Q) voltaria para ele no mesmo
## instante, antes de dar para ver que caiu.
const ESPERA_AO_SOLTAR: float = 0.6

## Altura, a partir dos pés do jogador, do ponto para onde o item voa. Mira o meio do
## corpo, e não os pés, para o contato acontecer de frente.
const ALTURA_DO_ALVO_NO_JOGADOR: float = 0.6

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

## Velocidade com que o item sai do lugar quando começa a ser atraído, quanto ela
## cresce por segundo, e o teto. O teto fica acima da velocidade do dash (12), para o
## item alcançar o jogador mesmo que ele fuja.
@export var velocidade_inicial_de_atracao: float = 1.0
@export var aceleracao_de_atracao: float = 18.0
@export var velocidade_maxima_de_atracao: float = 16.0

## Segundos antes de o item poder ser atraído. A cena colocada no mapa começa em 0; o
## soltar() usa ESPERA_AO_SOLTAR.
@export var espera_para_atrair: float = 0.0

@onready var visual: Sprite3D = $Visual
@onready var area_de_atracao: Area3D = $AreaDeAtracao
@onready var area_de_coleta: Area3D = $AreaDeColeta

var _altura_inicial_do_visual: float = 0.0
var _tempo: float = 0.0
var _jogador_alvo: Node3D = null
var _velocidade_de_atracao: float = 0.0

func _ready() -> void:
	_altura_inicial_do_visual = visual.position.y
	if item != null and item.icone != null:
		visual.texture = item.icone
	_criar_copias_de_espessura()
	area_de_atracao.body_entered.connect(_ao_jogador_chegar_perto)
	area_de_coleta.body_entered.connect(_ao_encostar_no_jogador)

## A atração mexe na posição de um nó com área de colisão, por isso fica no passo de
## física. O giro e a flutuação, que são só visuais, ficam no _process.
func _physics_process(delta: float) -> void:
	if espera_para_atrair > 0.0:
		espera_para_atrair -= delta
		if espera_para_atrair <= 0.0:
			_procurar_jogador_ja_dentro_do_raio()
		return
	if _jogador_alvo == null or not is_instance_valid(_jogador_alvo):
		return

	_velocidade_de_atracao = minf(
		_velocidade_de_atracao + aceleracao_de_atracao * delta,
		velocidade_maxima_de_atracao
	)
	var destino: Vector3 = _jogador_alvo.global_position + Vector3.UP * ALTURA_DO_ALVO_NO_JOGADOR
	global_position = global_position.move_toward(destino, _velocidade_de_atracao * delta)

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
	instancia.espera_para_atrair = ESPERA_AO_SOLTAR
	pai.add_child(instancia)
	instancia.global_position = posicao + empurrao
	return instancia

## Coloca o item no inventário e tira ele do mundo. Retorna false quando o inventário
## estava cheio, e aí o item continua onde está. Por enquanto sempre dá certo: o
## InventoryManager ainda não tem limite, e o caso de inventário cheio nasce no plano 04.
func coletar() -> bool:
	if item == null:
		return false
	InventoryManager.adicionar_item(item, quantidade)
	EventBus.item_picked_up.emit(item, quantidade)
	queue_free()
	return true

## As duas áreas só enxergam a camada do jogador, então todo corpo que chega aqui é ele.
func _ao_jogador_chegar_perto(corpo: Node3D) -> void:
	if espera_para_atrair > 0.0:
		return
	_comecar_atracao(corpo)

func _ao_encostar_no_jogador(_corpo: Node3D) -> void:
	if espera_para_atrair > 0.0:
		return
	if not coletar():
		# Inventário cheio: o item para de perseguir o jogador e fica onde parou.
		_jogador_alvo = null
		_velocidade_de_atracao = 0.0

## Quando a espera acaba com o jogador já dentro do raio, o body_entered não dispara de
## novo, então é preciso olhar quem já está lá dentro.
func _procurar_jogador_ja_dentro_do_raio() -> void:
	for corpo in area_de_atracao.get_overlapping_bodies():
		_comecar_atracao(corpo)
	for corpo in area_de_coleta.get_overlapping_bodies():
		_ao_encostar_no_jogador(corpo)

func _comecar_atracao(jogador: Node3D) -> void:
	if _jogador_alvo != null:
		return
	_jogador_alvo = jogador
	_velocidade_de_atracao = velocidade_inicial_de_atracao
