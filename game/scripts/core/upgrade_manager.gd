extends Node

## O nível das armas e das ferramentas do jogador, e o aprimoramento delas no ferreiro.
##
## Cada arma e cada ferramenta é única: o jogador tem no máximo uma de cada. Por isso o
## nível é guardado aqui, pelo id do item, e não em cada pilha do inventário. Todo item
## começa no nível 1. Subir de nível custa materiais (a sucata dos inimigos) e créditos.
##
## Na arma, o nível aumenta o dano. Na ferramenta de fazenda, aumenta a área que ela
## alcança quando o jogador segura o botão. Os números estão em
## resources/combat/aprimoramento.tres.

signal item_upgraded(item: Item, nivel: int)

const CAMINHO_DA_TABELA: String = "res://resources/combat/aprimoramento.tres"
const NIVEL_INICIAL: int = 1
const NIVEL_MAXIMO: int = 3
const GRUPO_DOS_BAUS: StringName = &"baus"
## O nome da área da ferramenta em cada nível, para a tela do ferreiro.
const NOMES_DAS_AREAS: Array[String] = ["1 quadrado", "3 em linha", "3 por 3"]

## Id do item para o nível dele. Quem não está aqui está no nível inicial.
var niveis: Dictionary[StringName, int] = {}

var _tabela: TabelaDeAprimoramento

func _ready() -> void:
	_tabela = load(CAMINHO_DA_TABELA) as TabelaDeAprimoramento
	EconomyManager.item_sold.connect(_ao_vender)

func tabela() -> TabelaDeAprimoramento:
	return _tabela

## Arma e ferramenta são aprimoráveis. O resto não tem nível.
func pode_ser_aprimorado(item: Item) -> bool:
	return item != null and item.e_unico()

func nivel_de(item: Item) -> int:
	if item == null:
		return NIVEL_INICIAL
	return niveis.get(item.id, NIVEL_INICIAL)

## As armas e ferramentas que estão no inventário, sem repetição, na ordem dos slots.
func itens_aprimoraveis_do_jogador() -> Array[Item]:
	var lista: Array[Item] = []
	for pilha in InventoryManager.slots:
		if pilha != null and not pilha.esta_vazia() and pode_ser_aprimorado(pilha.item) and not lista.has(pilha.item):
			lista.append(pilha.item)
	return lista

## Verdadeiro se o jogador tem o item, no inventário ou guardado em algum baú. É o que
## impede comprar uma segunda arma igual.
func jogador_possui(item: Item) -> bool:
	if InventoryManager.obter_quantidade(item) > 0:
		return true
	for no in get_tree().get_nodes_in_group(GRUPO_DOS_BAUS):
		var bau: Bau = no as Bau
		if bau == null:
			continue
		for pilha in bau.conteudo.pilhas():
			if pilha.item == item:
				return true
	return false

## A receita para subir ao próximo nível, ou null quando o item já está no máximo ou não
## é aprimorável.
func receita_para(item: Item) -> ReceitaDeAprimoramento:
	if not pode_ser_aprimorado(item) or nivel_de(item) >= NIVEL_MAXIMO:
		return null
	var receitas: Array[ReceitaDeAprimoramento] = _tabela.receitas_de_ferramenta if item is Ferramenta else _tabela.receitas_de_arma
	var indice: int = nivel_de(item) - NIVEL_INICIAL
	return receitas[indice] if indice < receitas.size() else null

## Quanto custa, em créditos, subir ao próximo nível.
func creditos_para(item: Item) -> int:
	var receita: ReceitaDeAprimoramento = receita_para(item)
	if receita == null:
		return 0
	return receita.creditos + roundi(item.valor_de_venda * receita.creditos_por_valor_de_venda)

func pode_aprimorar(item: Item) -> bool:
	var receita: ReceitaDeAprimoramento = receita_para(item)
	if receita == null or not EconomyManager.pode_pagar(creditos_para(item)):
		return false
	for indice in receita.materiais.size():
		if InventoryManager.obter_quantidade(receita.materiais[indice]) < receita.quantidades[indice]:
			return false
	return true

## Consome os materiais e os créditos e sobe o item um nível. Devolve false, sem mexer em
## nada, quando falta alguma coisa.
func aprimorar(item: Item) -> bool:
	if not pode_aprimorar(item):
		return false
	var receita: ReceitaDeAprimoramento = receita_para(item)
	EconomyManager.gastar(creditos_para(item))
	for indice in receita.materiais.size():
		InventoryManager.remover_item(receita.materiais[indice], receita.quantidades[indice])
	niveis[item.id] = nivel_de(item) + 1
	item_upgraded.emit(item, niveis[item.id])
	return true

## O dano da arma já com o nível dela.
func dano_de(arma: Arma) -> int:
	if arma == null:
		return 0
	return roundi(arma.dano * _multiplicador_de_dano(nivel_de(arma)))

## Quantas etapas de área a ferramenta alcança: 0 é um quadrado só, 1 é três em linha, 2
## é três por três. É o nível menos um.
func etapa_maxima_de_area(ferramenta: Ferramenta) -> int:
	return nivel_de(ferramenta) - NIVEL_INICIAL

## O que o nível dá ao item, em texto pronto para a tela: o dano, para a arma, e a área,
## para a ferramenta.
func descricao_do_nivel(item: Item, nivel: int) -> String:
	if item is Arma:
		return "Dano %d" % roundi((item as Arma).dano * _multiplicador_de_dano(nivel))
	if item is Ferramenta:
		return "Área: %s" % NOMES_DAS_AREAS[clampi(nivel - NIVEL_INICIAL, 0, NOMES_DAS_AREAS.size() - 1)]
	return ""

func _multiplicador_de_dano(nivel: int) -> float:
	var lista: Array[float] = _tabela.multiplicador_de_dano_por_nivel
	return lista[clampi(nivel - NIVEL_INICIAL, 0, lista.size() - 1)]

## Vender a arma aprimorada perde o nível: comprar de novo começa do 1.
func _ao_vender(item: Item) -> void:
	niveis.erase(item.id)

# Save

func exportar_estado() -> Dictionary:
	var salvos: Dictionary = {}
	for id: StringName in niveis:
		salvos[String(id)] = niveis[id]
	return {"niveis": salvos}

func importar_estado(dados: Dictionary) -> void:
	niveis.clear()
	for id: String in dados.get("niveis", {}):
		niveis[StringName(id)] = clampi(int(dados["niveis"][id]), NIVEL_INICIAL, NIVEL_MAXIMO)
