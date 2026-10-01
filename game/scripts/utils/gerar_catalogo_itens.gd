extends SceneTree

## Gera os .tres do catálogo de itens a partir das tabelas abaixo.
##
## Roda uma vez pela linha de comando, a partir da raiz do repositório:
##
##     godot --headless --path game --script res://scripts/utils/gerar_catalogo_itens.gd
##
## Fica versionado como documentação de onde vieram os números. Para mudar um valor,
## edite a tabela e rode de novo: os .tres são sobrescritos. As ferramentas não passam
## por aqui, porque têm som e ação próprios e são editadas à mão em
## resources/items/ferramentas/.
##
## Os valores de venda são o primeiro chute do plano 03. O balanceamento de verdade é o
## plano 17.

const PASTA_DOS_ITENS: String = "res://resources/items/"
const PASTA_DOS_ICONES: String = "res://assets/textures/icones_itens/"
const PASTA_DOS_CROPS: String = "res://assets/textures/tiny_farm_crops/"
const PASTA_DOS_CULTIVOS: String = "res://resources/farming/cultivos/"
const ESTAGIOS_POR_CULTIVO: int = 3

## id, nome, venda, nome da cultura no arquivo de arte (tiny_farm_crops/<cultura>_icon.png),
## dias por estágio, estágio de rebrota (0 para não rebrotar) e escala da planta madura.
## O ritmo varia para o plantio não ficar todo igual: cenoura e trigo são rápidos,
## tomate é lento mas rebrota e rende várias colheitas. O milho e o tomate maduros são
## maiores que as outras plantas, porque na vida real são pés altos, o milho mais.
const COLHEITAS: Array = [
	[&"beterraba", "Beterraba", 35, "beetroot", 2, 0, 1.0],
	[&"repolho", "Repolho", 50, "cabbage", 2, 0, 1.0],
	[&"cenoura", "Cenoura", 25, "carrot", 1, 0, 1.0],
	[&"milho", "Milho", 40, "corn", 2, 1, 1.4],
	[&"tomate", "Tomate", 30, "tomato", 3, 1, 1.25],
	[&"trigo", "Trigo", 20, "wheat", 1, 0, 1.0],
]

## Toda cultura rende de 2 a 4 itens por colheita, sorteado na hora de colher.
const COLHEITA_MINIMA: int = 2
const COLHEITA_MAXIMA: int = 4

## id, nome, venda. A sucata é RECURSO, como madeira e pedra: é matéria-prima que cai de
## inimigo. MATERIAL fica só para o que é processado.
const SUCATA: Array = [
	[&"sucata_metal", "Sucata de metal", 8],
	[&"placa_queimada", "Placa queimada", 15],
	[&"celula_energia", "Célula de energia", 45],
	[&"fio_optico", "Fio óptico", 22],
	[&"servomotor", "Servomotor", 60],
	[&"nucleo_sintetico", "Núcleo sintético", 140],
]

const RECURSOS_DO_CAMPO: Array = [
	[&"madeira", "Madeira", 5],
	[&"pedra", "Pedra", 4],
	[&"fibra", "Fibra", 3],
	[&"minerio_cobre", "Minério de cobre", 18],
	[&"minerio_ferro", "Minério de ferro", 26],
]

const MATERIAIS: Array = [
	[&"composto_organico", "Composto orgânico", 30],
	[&"biocombustivel", "Biocombustível", 90],
	[&"nutrisolo", "Nutrisolo", 75],
	[&"chapa_reciclada", "Chapa reciclada", 40],
]

## id, nome, venda, vida, stamina. A venda de quem é cozinhado vale mais que os
## ingredientes: o pão sai de um trigo (20), a sopa de vários legumes.
const CONSUMIVEIS: Array = [
	[&"pao_de_trigo", "Pão de trigo", 30, 20, 15],
	[&"sopa_de_legumes", "Sopa de legumes", 70, 40, 35],
	[&"estimulante", "Estimulante", 55, 0, 70],
	[&"nanogel", "Nanogel", 80, 60, 0],
]

## id, nome, venda, pode ser presente. O crédito não vai para o inventário (plano 17): o
## item existe só para dar o ícone da moeda na interface.
const ESPECIAIS: Array = [
	[&"buque", "Buquê", 60, true],
	[&"credito", "Crédito", 0, false],
]

const PASTA_DOS_MODELOS_DE_ARMA: String = "res://assets/models/kenney_mini_characters/"
## O gerador roda sem os autoloads do jogo, e o script do projétil usa o StatusManager.
## Por isso carregar esta cena aqui imprime um erro de compilação no terminal. O .tres
## da arma sai certo mesmo assim, porque só guarda o caminho da cena.
const CENA_DO_PROJETIL: String = "res://scenes/combat/projetil.tscn"
const SOM_DO_GOLPE: String = "res://assets/audio/sfx/punch.wav"
## Com arma de distância na mão o personagem vira este tanto mais rápido, para a mira
## acompanhar o direcional.
const GIRO_DA_ARMA_DE_DISTANCIA: float = 2.5
## A escopeta de cano serrado solta 6 projéteis num cone pequeno. O dano da tabela é o
## de cada projétil, então o disparo inteiro acertando vale 36, o maior do jogo, mas só
## de perto: de longe o cone abre e poucos projéteis acertam. O alcance de 5 metros é o
## maior entre as armas, e não é infinito.
const PROJETEIS_DA_ESCOPETA: int = 6
const ABERTURA_DO_CONE_DA_ESCOPETA: float = 16.0
const VELOCIDADE_DO_PROJETIL_DA_ESCOPETA: float = 22.0

## id, nome, venda, tipo, dano, alcance, stamina por acerto, velocidade da animação,
## cooldown, arquivo do modelo (vazio para nenhum) e escala do modelo.
##
## Os modelos são placeholder: bengalas e muleta do pacote de acessibilidade, que por
## acaso têm formato de bastão comprido. Trocar por modelo de arma de verdade é só mudar
## o campo modelo no .tres. A posição e a rotação do modelo na mão estão na tabela
## ENCAIXE_NA_MAO, porque foram ajustadas olhando o jogo.
const ARMAS: Array = [
	[&"cestos", "Cestos", 15, Arma.Tipo.PUNHO, 8, 1.0, 1.0, 1.8, 0.3, "", 1.0],
	[&"foice_curva", "Foice curva", 60, Arma.Tipo.LEVE, 12, 1.2, 1.5, 1.8, 0.25, "aid_cane.glb", 1.0],
	[&"bastao_choque", "Bastão de choque", 120, Arma.Tipo.LEVE, 20, 1.3, 2.0, 1.5, 0.35, "aid_cane_low_vision.glb", 1.0],
	[&"espadao_sucata", "Espadão de sucata", 180, Arma.Tipo.PESADA, 34, 1.9, 4.0, 0.55, 0.6, "aid_crutch.glb", 2.5],
	[&"escopeta_serrada", "Escopeta de cano serrado", 220, Arma.Tipo.DISTANCIA, 6, 5.0, 3.0, 1.0, 0.8, "aid_cane_blind.glb", 0.6],
]

## id da arma para [posição, rotação em graus] do modelo dentro do osso da mão direita.
## O braço se estende no eixo X negativo do osso, então a mão fica em x = -0.14. As
## armas de corpo a corpo ficam inclinadas para cima; a escopeta fica deitada ao longo do
## braço, para apontar para a frente na pose de segurar com as duas mãos.
const ENCAIXE_NA_MAO: Dictionary = {
	&"foice_curva": [Vector3(-0.14, 0.0, 0.0), Vector3(40.0, 0.0, 0.0)],
	&"bastao_choque": [Vector3(-0.14, 0.0, 0.0), Vector3(40.0, 0.0, 0.0)],
	&"espadao_sucata": [Vector3(-0.14, 0.0, 0.0), Vector3(30.0, 0.0, 0.0)],
	&"escopeta_serrada": [Vector3(-0.04, -0.02, 0.0), Vector3(0.0, 0.0, 90.0)],
}

func _init() -> void:
	var total: int = 0
	for linha in COLHEITAS:
		var colheita: Item = Item.new()
		_preencher(colheita, linha[0], linha[1], linha[2], Item.Categoria.COLHEITA)
		colheita.icone = load(PASTA_DOS_CROPS + linha[3] + "_icon.png")
		total += _salvar(colheita, "colheitas")
		var cultivo: Cultivo = _gerar_cultivo(linha, colheita)

		# A semente vale um terço da colheita, arredondado para baixo. O preço de compra
		# na loja é do plano 17.
		var semente: Semente = Semente.new()
		var id_da_semente: StringName = StringName("semente_" + String(linha[0]))
		var nome_da_semente: String = "Semente de " + String(linha[1]).to_lower()
		_preencher(semente, id_da_semente, nome_da_semente, floori(int(linha[2]) / 3.0), Item.Categoria.SEMENTE)
		semente.cultivo = cultivo
		total += _salvar(semente, "sementes")

	for linha in SUCATA:
		var sucata: Item = Item.new()
		_preencher(sucata, linha[0], linha[1], linha[2], Item.Categoria.RECURSO)
		total += _salvar(sucata, "sucata")

	for linha in RECURSOS_DO_CAMPO:
		var recurso: Item = Item.new()
		_preencher(recurso, linha[0], linha[1], linha[2], Item.Categoria.RECURSO)
		total += _salvar(recurso, "recursos")

	for linha in MATERIAIS:
		var material: Item = Item.new()
		_preencher(material, linha[0], linha[1], linha[2], Item.Categoria.MATERIAL)
		total += _salvar(material, "materiais")

	for linha in CONSUMIVEIS:
		var consumivel: Consumivel = Consumivel.new()
		_preencher(consumivel, linha[0], linha[1], linha[2], Item.Categoria.CONSUMIVEL)
		consumivel.recupera_vida = linha[3]
		consumivel.recupera_stamina = linha[4]
		total += _salvar(consumivel, "consumiveis")

	for linha in ESPECIAIS:
		var especial: Item = Item.new()
		_preencher(especial, linha[0], linha[1], linha[2], Item.Categoria.ESPECIAL)
		especial.pode_ser_presente = linha[3]
		total += _salvar(especial, "especiais")

	for linha in ARMAS:
		var arma: Arma = Arma.new()
		_preencher(arma, linha[0], linha[1], linha[2], Item.Categoria.ARMA)
		arma.empilhavel = false
		arma.quantidade_maxima_por_pilha = 1
		arma.pode_ser_presente = false
		arma.tipo = linha[3]
		arma.dano = linha[4]
		arma.alcance = linha[5]
		arma.custo_de_stamina = linha[6]
		arma.velocidade_da_animacao = linha[7]
		arma.cooldown = linha[8]
		arma.som_do_golpe = load(SOM_DO_GOLPE)
		if linha[9] != "":
			arma.modelo = load(PASTA_DOS_MODELOS_DE_ARMA + linha[9])
			arma.escala_do_modelo = Vector3.ONE * float(linha[10])
		if ENCAIXE_NA_MAO.has(linha[0]):
			arma.posicao_do_modelo = ENCAIXE_NA_MAO[linha[0]][0]
			arma.rotacao_do_modelo_em_graus = ENCAIXE_NA_MAO[linha[0]][1]
		if arma.tipo == Arma.Tipo.DISTANCIA:
			arma.projetil = load(CENA_DO_PROJETIL)
			arma.tem_mira_laser = true
			arma.multiplicador_de_giro = GIRO_DA_ARMA_DE_DISTANCIA
			arma.projeteis_por_disparo = PROJETEIS_DA_ESCOPETA
			arma.abertura_do_cone_em_graus = ABERTURA_DO_CONE_DA_ESCOPETA
			arma.velocidade_do_projetil = VELOCIDADE_DO_PROJETIL_DA_ESCOPETA
		total += _salvar(arma, "armas")

	print("Catálogo gerado: %d itens." % total)
	quit()

## Cria o .tres do cultivo, apontando para o item colhido já salvo. O cultivo fica em
## resources/farming/cultivos/, fora da pasta de itens, porque não é item de inventário.
func _gerar_cultivo(linha: Array, colheita: Item) -> Cultivo:
	var cultivo: Cultivo = Cultivo.new()
	cultivo.id = linha[0]
	cultivo.nome = linha[1]
	for numero in range(1, ESTAGIOS_POR_CULTIVO + 1):
		cultivo.estagios_de_crescimento.append(load("%s%s_%d.png" % [PASTA_DOS_CROPS, linha[3], numero]))
	cultivo.textura_murcha = load("%s%s_withered.png" % [PASTA_DOS_CROPS, linha[3]])
	cultivo.dias_por_estagio = linha[4]
	cultivo.estagio_de_rebrota = linha[5]
	cultivo.escala_da_planta_madura = linha[6]
	cultivo.quantidade_colhida_minima = COLHEITA_MINIMA
	cultivo.quantidade_colhida_maxima = COLHEITA_MAXIMA
	cultivo.item_colhido = colheita

	DirAccess.make_dir_recursive_absolute(PASTA_DOS_CULTIVOS)
	var caminho: String = "%s%s.tres" % [PASTA_DOS_CULTIVOS, cultivo.id]
	var erro: Error = ResourceSaver.save(cultivo, caminho)
	if erro != OK:
		push_error("Falha ao salvar %s: %s" % [caminho, error_string(erro)])
	# Assumir o caminho faz a semente gravar o cultivo como referência ao arquivo, e não
	# como uma cópia embutida dentro do .tres dela.
	cultivo.take_over_path(caminho)
	return cultivo

## Preenche os campos comuns. O ícone padrão é o placeholder com o nome do id; as
## colheitas trocam pelo ícone de verdade depois desta chamada.
func _preencher(item: Item, id: StringName, nome: String, venda: int, categoria: Item.Categoria) -> void:
	item.id = id
	item.nome = nome
	item.valor_de_venda = venda
	item.categoria = categoria
	var caminho_do_icone: String = PASTA_DOS_ICONES + String(id) + ".png"
	if ResourceLoader.exists(caminho_do_icone):
		item.icone = load(caminho_do_icone)

## Retorna 1 quando salvou, para somar no total, e 0 quando falhou.
func _salvar(item: Item, subpasta: String) -> int:
	var pasta: String = PASTA_DOS_ITENS + subpasta
	DirAccess.make_dir_recursive_absolute(pasta)
	var caminho: String = "%s/%s.tres" % [pasta, item.id]
	var erro: Error = ResourceSaver.save(item, caminho)
	if erro != OK:
		push_error("Falha ao salvar %s: %s" % [caminho, error_string(erro)])
		return 0
	# Assumir o caminho faz quem aponta para este item (o cultivo, no caso da colheita)
	# gravar uma referência ao arquivo, e não uma cópia embutida.
	item.take_over_path(caminho)
	return 1
