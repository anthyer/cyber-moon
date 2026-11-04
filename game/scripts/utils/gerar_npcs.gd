extends Node

## Gera os .tres dos NPCs, com a rotina de cada um, a partir das tabelas abaixo.
##
##     godot --headless --path game res://scenes/utils/gerar_npcs.tscn
##
## Roda como cena, e não com --script, porque o catálogo de loja consulta autoloads do
## jogo, que só existem com o projeto carregado.
##
## A rotina é dado: mora no .tres e pode ser editada no Inspector. Este script existe
## porque escrever dezenas de compromissos à mão no editor é lento e fácil de errar, e a
## tabela aqui mostra a semana inteira de cada um de uma vez. Para mudar um horário, edite
## a tabela e rode de novo: os .tres são sobrescritos.
##
## Os lugares são nomes de Marker3D da fase (filhos de PontosDeRotina). Mapa novo não
## muda nada aqui, só a posição dos marcadores.

const PASTA_DOS_NPCS: String = "res://resources/npcs/"
const PASTA_DAS_FIGURANTES: String = "res://resources/npcs/figurantes/"
## O modelo de cada um é personagem_<id>.glb, feito no Blender a partir de um personagem da
## Kenney (equipe/ferramentas/blender/modelos/personagens.py).
const PASTA_DOS_MODELOS: String = "res://assets/models/cyber_moon_personagens/"

const PASTA_DOS_ITENS: String = "res://resources/items/"
const DIAS_DE_TRABALHO: Array[int] = [0, 1, 2, 3, 4]

## O que cada um ama, gosta, não gosta e odeia ganhar, pelos ids dos itens. Item fora das
## listas é neutro. Cada gosto conta algo do personagem: a Iara odeia estimulante porque é
## médica e vê o estrago que ele faz; a Sol odeia chapa reciclada porque é feita da sucata
## da corporação de onde ela fugiu; o Vitor odeia nanogel porque não confia em remédio da
## cidade. Do elenco novo: o Bento odeia biocombustível, que tem o cheiro das máquinas da
## Galeria; o Hélio odeia núcleo sintético, que é peça da corporação que levou as sementes;
## a Lúcia odeia biocombustível, porque a cidade jura que ele não existe; o Téo odeia
## verdura e remédio, como toda criança.
const GOSTOS: Dictionary = {
	"vitor": [[&"servomotor", &"chapa_reciclada"], [&"sucata_metal", &"minerio_ferro", &"placa_queimada"], [&"buque"], [&"nanogel"]],
	"kenji": [[&"nucleo_sintetico", &"fio_optico"], [&"celula_energia", &"placa_queimada", &"estimulante"], [&"pedra", &"fibra"], [&"composto_organico"]],
	"rafa": [[&"biocombustivel", &"estimulante"], [&"pao_de_trigo", &"milho", &"celula_energia"], [&"pedra"], [&"sucata_metal"]],
	"marta": [[&"sopa_de_legumes", &"repolho"], [&"cenoura", &"beterraba", &"tomate", &"trigo"], [&"sucata_metal"], [&"placa_queimada"]],
	"iara": [[&"nanogel", &"sopa_de_legumes"], [&"beterraba", &"fibra", &"composto_organico"], [&"sucata_metal"], [&"estimulante"]],
	"sol": [[&"nucleo_sintetico", &"tomate"], [&"celula_energia", &"pao_de_trigo", &"milho"], [&"minerio_cobre"], [&"chapa_reciclada"]],
	"bento": [[&"sopa_de_legumes", &"pao_de_trigo"], [&"cenoura", &"sucata_metal", &"fio_optico"], [&"estimulante"], [&"biocombustivel"]],
	"helio": [[&"composto_organico", &"nutrisolo"], [&"beterraba", &"repolho", &"fibra", &"semente_milho"], [&"sucata_metal"], [&"nucleo_sintetico"]],
	"dandara": [[&"biocombustivel", &"servomotor"], [&"celula_energia", &"sucata_metal", &"pao_de_trigo"], [&"repolho"], [&"nanogel"]],
	"lucia": [[&"tomate", &"nucleo_sintetico"], [&"chapa_reciclada", &"celula_energia", &"milho"], [&"sucata_metal", &"fibra"], [&"biocombustivel"]],
	"teo": [[&"milho", &"pao_de_trigo"], [&"pedra", &"minerio_cobre", &"placa_queimada"], [&"repolho", &"beterraba"], [&"nanogel"]],
	"zeca": [[&"biocombustivel", &"sopa_de_legumes"], [&"pao_de_trigo", &"tomate", &"fio_optico"], [&"fibra"], [&"composto_organico"]],
}

## id, nome, estação e dia do aniversário, casa, romanceável.
const ELENCO: Array = [
	["vitor", "Vitor Alencar", &"estiagem", 12, &"casa_vitor", false],
	["kenji", "Kenji Moura", &"brotacao", 9, &"casa_kenji", true],
	["rafa", "Rafael Duarte", &"colheita", 3, &"casa_rafa", true],
	["marta", "Marta Bueno", &"colheita", 20, &"casa_marta", false],
	["iara", "Iara Nakamura", &"apagao", 15, &"casa_iara", true],
	["sol", "Sol Vasques", &"estiagem", 27, &"casa_sol", true],
	# Elenco do plano 30. O Téo mora com o tio, o Kenji, na casa geminada.
	["bento", "Bento Arruda", &"apagao", 2, &"casa_bento", false],
	["helio", "Hélio Tavares", &"brotacao", 18, &"casa_helio", false],
	["dandara", "Dandara Reis", &"estiagem", 5, &"casa_dandara", true],
	["lucia", "Lúcia Prado", &"colheita", 11, &"ponto_de_onibus", false],
	["teo", "Téo", &"brotacao", 25, &"casa_kenji", false],
	["zeca", "Zeca", &"apagao", 24, &"fim_da_estrada", false],
]

## Quem mora fora do mapa e só vem de visita: a casa no ELENCO é o ponto por onde chega.
const MORAM_FORA_DO_MAPA: Array[String] = ["lucia", "zeca"]

## As figurantes: id, nome, casa. Sem gostos, sem aniversário e sem conversa; ficam numa
## pasta à parte para não entrar no calendário nem na amizade.
const FIGURANTES: Array = [
	["motoqueira_a", "Motoqueira", &"fogueira"],
	["motoqueira_b", "Motoqueira", &"fogueira"],
]

## Os compromissos fora de casa de cada um: hora inicial, hora final, destino, animação,
## e um dicionário opcional de condições (estacoes, dias, climas, aniversario). O que a
## tabela não cobre, o NPC passa em casa; a Folga e a tempestade são regra do próprio Npc.
##
## Os horários se cruzam de propósito, porque é o cruzamento que faz dois NPCs pararem
## perto um do outro e encenarem conversa: Vitor e Marta na praça no fim da tarde, Rafa
## passando pelo mercado e pela clínica nas entregas, Kenji e Rafa na ponte à noite, Iara
## e Sol na beira do rio.
const ROTINAS: Dictionary = {
	"vitor": [
		[8.0, 12.0, &"oficina", &"interact-left", {"dias": DIAS_DE_TRABALHO}],
		[12.0, 13.0, &"praca", &"sit", {"dias": DIAS_DE_TRABALHO}],
		[13.0, 18.0, &"oficina", &"interact-left", {"dias": DIAS_DE_TRABALHO}],
		[18.0, 22.0, &"praca", &"idle", {}],
	],
	"marta": [
		[8.0, 12.0, &"mercado", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[12.0, 13.0, &"praca", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[13.0, 18.0, &"mercado", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[18.0, 20.0, &"praca", &"idle", {}],
	],
	"kenji": [
		[9.0, 13.0, &"torre_antena", &"interact-left", {"dias": DIAS_DE_TRABALHO}],
		[13.0, 14.0, &"praca", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[14.0, 19.0, &"torre_antena", &"interact-left", {"dias": DIAS_DE_TRABALHO}],
		[19.0, 23.0, &"ponte", &"idle", {}],
		# No Apagão a antena fica sem energia à tarde, e ele vai ao mercado.
		[14.0, 19.0, &"mercado", &"idle", {"dias": DIAS_DE_TRABALHO, "estacoes": [&"apagao"]}],
	],
	"rafa": [
		[7.0, 10.0, &"posto_entrega", &"interact-left", {"dias": DIAS_DE_TRABALHO}],
		[10.0, 12.0, &"mercado", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[12.0, 13.0, &"praca", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[13.0, 16.0, &"clinica", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[16.0, 18.0, &"oficina", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[18.0, 22.0, &"ponte", &"idle", {}],
	],
	"iara": [
		[8.0, 12.0, &"clinica", &"interact-left", {"dias": DIAS_DE_TRABALHO}],
		[12.0, 13.0, &"praca", &"sit", {"dias": DIAS_DE_TRABALHO}],
		[13.0, 18.0, &"clinica", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[18.0, 21.0, &"beira_rio", &"idle", {}],
		# Com chuva ela não desce para o rio.
		[18.0, 21.0, &"casa_iara", &"idle", {"climas": [&"chuva"]}],
	],
	"sol": [
		[8.0, 11.0, &"mirante", &"idle", {}],
		[11.0, 14.0, &"beira_rio", &"sit", {}],
		[14.0, 18.0, &"mirante", &"idle", {}],
		[18.0, 21.0, &"beira_rio", &"idle", {}],
		# Na Estiagem o calor a leva para a sombra da ponte no meio do dia.
		[11.0, 14.0, &"ponte", &"idle", {"estacoes": [&"estiagem"]}],
		# No aniversário ela passa o dia na praça, à vista de todo mundo.
		[8.0, 21.0, &"praca", &"idle", {"aniversario": true}],
	],
	# O Bento ainda vigia a porta da Galeria, de onde saiu há anos, e desce à praça para
	# contar causo no almoço. À noite encontra o Kenji e o Rafa na ponte.
	"bento": [
		[7.0, 11.0, &"porta_da_galeria", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[11.0, 13.0, &"praca", &"sit", {"dias": DIAS_DE_TRABALHO}],
		[13.0, 17.0, &"porta_da_galeria", &"idle", {"dias": DIAS_DE_TRABALHO}],
		[17.0, 20.0, &"ponte", &"idle", {}],
	],
	# O Hélio cuida do caderno de sementes na cisterna e, dia sim dia não, vai trocar
	# conversa e semente com a Marta no mercado.
	"helio": [
		[8.0, 12.0, &"cisterna", &"interact-left", {"dias": DIAS_DE_TRABALHO}],
		[12.0, 13.0, &"praca", &"sit", {"dias": DIAS_DE_TRABALHO}],
		[13.0, 17.0, &"mercado", &"idle", {"dias": [0, 2, 4]}],
		[13.0, 17.0, &"cisterna", &"interact-left", {"dias": [1, 3]}],
		[18.0, 20.0, &"beira_rio", &"idle", {}],
	],
	# A Dandara mexe nas motos de manhã, e duas tardes por semana sobe na antena com o
	# Kenji para ouvir o que passa no sinal da cidade.
	"dandara": [
		[9.0, 13.0, &"oficina_das_motoqueiras", &"interact-left", {"dias": DIAS_DE_TRABALHO}],
		[13.0, 15.0, &"fogueira", &"sit", {}],
		[15.0, 18.0, &"torre_antena", &"idle", {"dias": [1, 3]}],
		[15.0, 18.0, &"oficina_das_motoqueiras", &"interact-left", {"dias": [0, 2, 4]}],
		[18.0, 23.0, &"fogueira", &"idle", {}],
	],
	# A Lúcia desce do ônibus uma vez por semana, olha o mercado, a praça e a oficina, e
	# volta para a cidade no fim da tarde.
	"lucia": [
		[9.0, 12.0, &"mercado", &"idle", {"dias": [2]}],
		[12.0, 14.0, &"praca", &"idle", {"dias": [2]}],
		[14.0, 17.0, &"oficina", &"idle", {"dias": [2]}],
	],
	# O Téo corre o mapa inteiro: rio, praça, mirante, a porta da Galeria (por causa das
	# histórias do Bento) e, no fim do dia, a antena do tio.
	"teo": [
		[8.0, 11.0, &"beira_rio", &"idle", {}],
		[11.0, 13.0, &"praca", &"idle", {}],
		[13.0, 16.0, &"mirante", &"idle", {}],
		[16.0, 19.0, &"porta_da_galeria", &"idle", {}],
		[19.0, 21.0, &"torre_antena", &"idle", {}],
	],
	# O Zeca para o caminhão debaixo do viaduto um dia por semana, no horário da loja.
	"zeca": [
		[9.0, 18.0, &"parada_do_caminhao", &"idle", {"dias": [3]}],
	],
	"motoqueira_a": [
		[8.0, 18.0, &"oficina_das_motoqueiras", &"interact-left", {"dias": DIAS_DE_TRABALHO}],
	],
	"motoqueira_b": [
		[10.0, 18.0, &"fogueira", &"sit", {}],
	],
}

const PASTA_DAS_LOJAS: String = "res://resources/lojas/"
## O que cada comerciante vende: id do item e o marco de progressão que o libera (vazio
## para o que está à venda desde o começo). A Marta vende semente e comida; o Vitor,
## equipamento e arma. Os catálogos não se sobrepõem, para o jogador aprender aonde ir.
const CATALOGOS: Dictionary = {
	"marta": [
		[&"semente_cenoura", ""], [&"semente_trigo", ""], [&"semente_beterraba", ""], [&"semente_repolho", ""],
		[&"semente_milho", ""], [&"semente_tomate", ""], [&"pao_de_trigo", ""], [&"sopa_de_legumes", ""],
		[&"nutrisolo", "marco_1"], [&"buque", ""],
	],
	"vitor": [
		[&"nanogel", ""], [&"estimulante", ""], [&"bastao_choque", ""],
		[&"foice_curva", "marco_1"], [&"espadao_sucata", "marco_2"], [&"escopeta_serrada", "marco_2"],
	],
	# O Zeca traz o que ninguém da vila vende: peça e energia da estrada.
	"zeca": [
		[&"fio_optico", ""], [&"celula_energia", ""], [&"biocombustivel", ""],
		[&"servomotor", "marco_1"], [&"nucleo_sintetico", "marco_2"],
	],
}

## Quem, além de vender, aprimora armas e ferramentas.
const FERREIROS: Array[String] = ["vitor"]

var _itens_por_id: Dictionary = {}

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA_DOS_NPCS)
	_carregar_itens(PASTA_DOS_ITENS)
	for linha in ELENCO:
		var perfil: PerfilNpc = _novo_perfil(linha[0], linha[1], linha[4])
		perfil.estacao_do_aniversario = linha[2]
		perfil.dia_do_aniversario = linha[3]
		perfil.eh_romanceavel = linha[5]
		perfil.mora_fora_do_mapa = MORAM_FORA_DO_MAPA.has(perfil.id)
		var gostos: Array = GOSTOS[perfil.id]
		perfil.itens_amados.assign(_itens(gostos[0]))
		perfil.itens_queridos.assign(_itens(gostos[1]))
		perfil.itens_indesejados.assign(_itens(gostos[2]))
		perfil.itens_odiados.assign(_itens(gostos[3]))
		if CATALOGOS.has(perfil.id):
			perfil.catalogo = _novo_catalogo(perfil.id)
		perfil.eh_ferreiro = FERREIROS.has(perfil.id)
		var caminho: String = PASTA_DOS_NPCS + perfil.id + ".tres"
		var erro: Error = ResourceSaver.save(perfil, caminho)
		print("%s: %d compromissos (erro %d)" % [caminho, perfil.rotina.size(), erro])
	DirAccess.make_dir_recursive_absolute(PASTA_DAS_FIGURANTES)
	for linha in FIGURANTES:
		var figurante: PerfilNpc = _novo_perfil(linha[0], linha[1], linha[2])
		figurante.eh_figurante = true
		var caminho_da_figurante: String = PASTA_DAS_FIGURANTES + figurante.id + ".tres"
		var erro_da_figurante: Error = ResourceSaver.save(figurante, caminho_da_figurante)
		print("%s: %d compromissos (erro %d)" % [caminho_da_figurante, figurante.rotina.size(), erro_da_figurante])
	get_tree().quit()

## O que todo NPC tem, morador ou figurante: quem é, o modelo, a casa e a rotina.
func _novo_perfil(id: String, nome: String, casa: StringName) -> PerfilNpc:
	var perfil: PerfilNpc = PerfilNpc.new()
	perfil.id = id
	perfil.nome_exibido = nome
	perfil.modelo = load(PASTA_DOS_MODELOS + "personagem_" + id + ".glb")
	perfil.casa = casa
	for item in ROTINAS[id]:
		perfil.rotina.append(_novo_compromisso(item))
	return perfil

## Percorre a pasta de itens e guarda cada um pelo id, para os gostos acima poderem citar
## o id sem saber em que subpasta o item mora.
func _carregar_itens(pasta: String) -> void:
	for subpasta in DirAccess.get_directories_at(pasta):
		_carregar_itens(pasta + subpasta + "/")
	for arquivo in DirAccess.get_files_at(pasta):
		if arquivo.ends_with(".tres"):
			var item: Item = load(pasta + arquivo) as Item
			if item != null:
				_itens_por_id[item.id] = item

func _itens(ids: Array) -> Array[Item]:
	var lista: Array[Item] = []
	for id: StringName in ids:
		if _itens_por_id.has(id):
			lista.append(_itens_por_id[id])
		else:
			push_error("Item de gosto não encontrado: %s" % id)
	return lista

## O catálogo é salvo num arquivo próprio, e o perfil aponta para ele.
func _novo_catalogo(npc_id: String) -> CatalogoDeLoja:
	var catalogo: CatalogoDeLoja = CatalogoDeLoja.new()
	catalogo.npc_id = npc_id
	for linha in CATALOGOS[npc_id]:
		if not _itens_por_id.has(linha[0]):
			push_error("Item de catálogo não encontrado: %s" % linha[0])
			continue
		catalogo.itens.append(_itens_por_id[linha[0]])
		catalogo.marco_necessario.append(linha[1])
	DirAccess.make_dir_recursive_absolute(PASTA_DAS_LOJAS)
	var caminho: String = PASTA_DAS_LOJAS + npc_id + ".tres"
	ResourceSaver.save(catalogo, caminho)
	catalogo.take_over_path(caminho)
	return catalogo

func _novo_compromisso(item: Array) -> Compromisso:
	var compromisso: Compromisso = Compromisso.new()
	compromisso.hora_inicial = item[0]
	compromisso.hora_final = item[1]
	compromisso.destino = item[2]
	compromisso.animacao_parado = item[3]
	var condicoes: Dictionary = item[4]
	compromisso.dias_da_semana.assign(condicoes.get("dias", []))
	compromisso.estacoes.assign(condicoes.get("estacoes", []))
	compromisso.climas.assign(condicoes.get("climas", []))
	compromisso.apenas_no_aniversario = condicoes.get("aniversario", false)
	return compromisso
