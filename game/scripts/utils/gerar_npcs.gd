extends SceneTree

## Gera os .tres dos NPCs, com a rotina de cada um, a partir das tabelas abaixo.
##
##     godot --headless --path game --script res://scripts/utils/gerar_npcs.gd
##
## A rotina é dado: mora no .tres e pode ser editada no Inspector. Este script existe
## porque escrever dezenas de compromissos à mão no editor é lento e fácil de errar, e a
## tabela aqui mostra a semana inteira de cada um de uma vez. Para mudar um horário, edite
## a tabela e rode de novo: os .tres são sobrescritos.
##
## Os lugares são nomes de Marker3D da fase (filhos de PontosDeRotina). Mapa novo não
## muda nada aqui, só a posição dos marcadores.

const PASTA_DOS_NPCS: String = "res://resources/npcs/"
const PASTA_DOS_MODELOS: String = "res://assets/models/kenney_mini_characters/"

const DIAS_DE_TRABALHO: Array[int] = [0, 1, 2, 3, 4]

## id, nome, modelo, estação e dia do aniversário, casa, romanceável.
const ELENCO: Array = [
	["vitor", "Vitor Alencar", "character_male_b.glb", &"estiagem", 12, &"casa_vitor", false],
	["kenji", "Kenji Moura", "character_male_c.glb", &"brotacao", 9, &"casa_kenji", true],
	["rafa", "Rafael Duarte", "character_male_d.glb", &"colheita", 3, &"casa_rafa", true],
	["marta", "Marta Bueno", "character_female_a.glb", &"colheita", 20, &"casa_marta", false],
	["iara", "Iara Nakamura", "character_female_b.glb", &"apagao", 15, &"casa_iara", true],
	["sol", "Sol Vasques", "character_female_c.glb", &"estiagem", 27, &"casa_sol", true],
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
}

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(PASTA_DOS_NPCS)
	for linha in ELENCO:
		var perfil: PerfilNpc = PerfilNpc.new()
		perfil.id = linha[0]
		perfil.nome_exibido = linha[1]
		perfil.modelo = load(PASTA_DOS_MODELOS + String(linha[2]))
		perfil.estacao_do_aniversario = linha[3]
		perfil.dia_do_aniversario = linha[4]
		perfil.casa = linha[5]
		perfil.eh_romanceavel = linha[6]
		for item in ROTINAS[perfil.id]:
			perfil.rotina.append(_novo_compromisso(item))
		var caminho: String = PASTA_DOS_NPCS + perfil.id + ".tres"
		var erro: Error = ResourceSaver.save(perfil, caminho)
		print("%s: %d compromissos (erro %d)" % [caminho, perfil.rotina.size(), erro])
	quit()

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
