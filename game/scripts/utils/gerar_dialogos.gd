extends SceneTree

## Gera os .tres de Conversa dos NPCs a partir de equipe/biblioteca-de-dialogos.md.
##
##     godot --headless --path game --script res://scripts/utils/gerar_dialogos.gd
##
## A biblioteca é o texto que a equipe escreve e revisa; este script só a transcreve para
## o formato do jogo, para ninguém copiar duzentas falas à mão. Para mudar uma fala,
## edite a biblioteca e rode de novo: os .tres são sobrescritos.
##
## As falas do dia a dia (as faixas de relacionamento, as de namoro, as de estação e as de
## situação, com as condições entre colchetes) viram NoDialogo. O formato da biblioteca e
## a lista de condições estão em equipe/personas/leiame.md. As de presente, de aniversário e de buquê são disparadas por evento, e vão
## para o dicionário falas_de_evento da Conversa. As "Falas de sistema" do fim da
## biblioteca valem para todos, e são copiadas para a Conversa de cada NPC.

const CAMINHO_DA_BIBLIOTECA: String = "../equipe/biblioteca-de-dialogos.md"
const PASTA_DAS_CONVERSAS: String = "res://resources/dialogue/"

## O primeiro nome no título da seção para o id do PerfilNpc.
const IDS_POR_NOME: Dictionary = {
	"Vitor": "vitor", "Kenji": "kenji", "Rafael": "rafa", "Marta": "marta", "Iara": "iara", "Sol": "sol",
	"Bento": "bento", "Hélio": "helio", "Dandara": "dandara", "Lúcia": "lucia", "Téo": "teo", "Zeca": "zeca",
}
## Faixa de relacionamento para [mínimo, máximo], em pontos, como na tabela da biblioteca.
const FAIXAS: Dictionary = {
	"Distante": [0, 749], "Conhecido": [750, 1499], "Amigo": [1500, 2499], "Íntimo": [2500, 9999],
}
const ESTACOES_POR_NOME: Dictionary = {
	"Brotação": &"brotacao", "Estiagem": &"estiagem", "Colheita": &"colheita", "Apagão": &"apagao",
}
const SECAO_DE_ESTACAO: String = "Por estação"
const SECAO_DE_NAMORO: String = "Namorando"
const SECAO_DE_SITUACOES: String = "Situações"
## O "+" no fim da faixa quer dizer "desta faixa para cima".
const SUFIXO_PARA_CIMA: String = "+"
## A faixa escrita como condição, entre colchetes, para o nome dela em FAIXAS.
const FAIXAS_POR_CONDICAO: Dictionary = {
	"distante": "Distante", "conhecido": "Conhecido", "amigo": "Amigo", "intimo": "Íntimo",
}
const ESTACOES_POR_CONDICAO: Array[StringName] = [&"brotacao", &"estiagem", &"colheita", &"apagao"]
## As situações que o DialogueManager sabe avaliar. Uma condição fora desta lista é erro
## de digitação na biblioteca: a fala nunca apareceria no jogo, então o gerador avisa.
const SITUACOES_CONHECIDAS: Array[String] = [
	"sol", "chuva", "tempestade", "choveu_ontem", "tempestade_ontem",
	"trabalho", "folga", "vespera_de_folga", "manha", "tarde", "noite",
	"aniversario", "primeiro_dia_da_estacao", "ultimo_dia_da_estacao", "primeiro_dia_do_ano",
	"primeiro_encontro", "sumido", "desmaiou_ontem", "vida_baixa", "saiu_da_dungeon",
	"namorando_outro", "marco_1", "marco_2", "marco_3",
]
## Situações com um complemento depois dos dois pontos, e os complementos aceitos.
const LUGARES: Array[String] = [
	"praca", "oficina", "mercado", "clinica", "torre_antena", "posto_entrega", "mirante", "ponte", "beira_rio", "casa",
	# Os lugares do elenco do plano 30.
	"porta_da_galeria", "cisterna", "oficina_das_motoqueiras", "fogueira", "parada_do_caminhao",
]
const SECAO_DE_PRESENTE: String = "Presente"
const SECAO_DE_SISTEMA: String = "Falas de sistema"
## Rótulo na biblioteca para a chave em Conversa.falas_de_evento.
const EVENTOS_POR_ROTULO: Dictionary = {
	"Amou": &"amou", "Gostou": &"gostou", "Neutro": &"neutro", "Não gostou": &"nao_gostou", "Odiou": &"odiou",
	"Aniversário": &"aniversario", "Buquê aceito": &"buque_aceito",
	"Já presenteou esta semana": &"ja_presenteou",
	"Buquê recusado, poucos corações": &"buque_poucos_coracoes",
	"Buquê recusado, não romanceável": &"buque_nao_romanceavel",
	"Buquê recusado, já namorando": &"buque_ja_namorando",
	"Loja fechada, Folga": &"loja_fechada_folga",
	"Loja fechada, fora de horário": &"loja_fechada_horario",
	"Sem crédito suficiente": &"sem_credito",
}

func _init() -> void:
	var caminho: String = ProjectSettings.globalize_path("res://").path_join(CAMINHO_DA_BIBLIOTECA)
	var arquivo: FileAccess = FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		push_error("Biblioteca não encontrada: %s" % caminho)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(PASTA_DAS_CONVERSAS)

	var conversas: Array[Conversa] = []
	## As falas de sistema, que no fim são copiadas para todas as conversas.
	var falas_de_sistema: Dictionary[StringName, String] = {}
	var conversa: Conversa = null
	var na_secao_de_sistema: bool = false
	## A subseção em que as linhas estão: uma faixa, "Por estação", "Presente", ou outra.
	var secao: String = ""
	## A fala do dia em construção, e a de evento em construção (o dicionário e a chave),
	## porque uma fala longa continua na linha de baixo.
	var no_atual: NoDialogo = null
	var eventos_atuais: Dictionary[StringName, String] = {}
	var evento_atual: StringName = &""
	while not arquivo.eof_reached():
		var linha: String = arquivo.get_line()
		var e_texto: bool = linha.strip_edges() != "" and not linha.begins_with("---")
		if linha.begins_with("## "):
			var titulo: String = linha.trim_prefix("## ").strip_edges()
			conversa = _nova_conversa(titulo)
			if conversa != null:
				conversas.append(conversa)
			na_secao_de_sistema = titulo == SECAO_DE_SISTEMA
			secao = ""
			no_atual = null
			evento_atual = &""
		elif linha.begins_with("**"):
			# "**Distante**" abre uma subseção. "**Aniversário:** texto" é uma fala de
			# evento inteira, com o rótulo em negrito e o texto na mesma linha.
			secao = linha.get_slice("**", 1).trim_suffix(":")
			no_atual = null
			evento_atual = &""
			var texto_na_linha: String = linha.get_slice("**", 2).strip_edges()
			var tem_dono: bool = na_secao_de_sistema or conversa != null
			if texto_na_linha != "" and EVENTOS_POR_ROTULO.has(secao) and tem_dono:
				eventos_atuais = falas_de_sistema if na_secao_de_sistema else conversa.falas_de_evento
				evento_atual = EVENTOS_POR_ROTULO[secao]
				eventos_atuais[evento_atual] = texto_na_linha
		elif linha.begins_with("- ") and conversa != null:
			var texto: String = linha.trim_prefix("- ").strip_edges()
			no_atual = null
			evento_atual = &""
			if secao == SECAO_DE_PRESENTE:
				# "Amou: Isso aqui é peça de verdade." é a reação a um tipo de presente.
				var rotulo: String = texto.get_slice(":", 0)
				if EVENTOS_POR_ROTULO.has(rotulo):
					eventos_atuais = conversa.falas_de_evento
					evento_atual = EVENTOS_POR_ROTULO[rotulo]
					eventos_atuais[evento_atual] = texto.substr(rotulo.length() + 1).strip_edges()
			else:
				no_atual = _novo_no(conversa, secao, texto)
		elif e_texto and no_atual != null:
			no_atual.texto += " " + linha.strip_edges()
		elif e_texto and evento_atual != &"":
			eventos_atuais[evento_atual] += " " + linha.strip_edges()
		else:
			no_atual = null
			evento_atual = &""

	for pronta in conversas:
		for evento: StringName in falas_de_sistema:
			pronta.falas_de_evento[evento] = falas_de_sistema[evento]
		_salvar(pronta)
	quit()

## Só as seções dos seis NPCs viram conversa. As outras ("Como transcrever", "Falas de
## sistema") devolvem null e as linhas delas são ignoradas.
func _nova_conversa(titulo: String) -> Conversa:
	var primeiro_nome: String = titulo.get_slice(" ", 0)
	if not IDS_POR_NOME.has(primeiro_nome):
		return null
	var conversa: Conversa = Conversa.new()
	conversa.npc_id = IDS_POR_NOME[primeiro_nome]
	conversa.id = StringName(conversa.npc_id)
	return conversa

func _novo_no(conversa: Conversa, secao: String, texto: String) -> NoDialogo:
	var no: NoDialogo = NoDialogo.new()
	no.falante_id = conversa.npc_id
	if FAIXAS.has(secao):
		no.relacionamento_minimo = FAIXAS[secao][0]
		no.relacionamento_maximo = FAIXAS[secao][1]
		no.texto = texto
	elif secao == SECAO_DE_NAMORO:
		no.so_namorando = true
		no.texto = texto
	elif secao == SECAO_DE_ESTACAO:
		# "Brotação: Chuva boa pra planta..." vale só naquela estação, em qualquer faixa.
		var nome_da_estacao: String = texto.get_slice(":", 0)
		if not ESTACOES_POR_NOME.has(nome_da_estacao):
			return null
		no.estacoes.append(ESTACOES_POR_NOME[nome_da_estacao])
		no.texto = texto.substr(nome_da_estacao.length() + 1).strip_edges()
	elif secao == SECAO_DE_SITUACOES:
		# "[chuva, amigo+] Fala." tem as condições entre colchetes, antes do texto.
		if not texto.begins_with("[") or not texto.contains("]"):
			push_error("Fala de situação sem condições entre colchetes: %s" % texto)
			return null
		var fim: int = texto.find("]")
		for condicao in texto.substr(1, fim - 1).split(","):
			_aplicar_condicao(no, condicao.strip_edges())
		no.texto = texto.substr(fim + 1).strip_edges()
	else:
		return null
	conversa.nos.append(no)
	return no

## Traduz uma condição escrita na biblioteca para o campo certo da fala. Faixa de amizade,
## estação, namoro e "uma_vez" têm campo próprio; todo o resto é uma situação pelo nome.
func _aplicar_condicao(no: NoDialogo, condicao: String) -> void:
	var para_cima: bool = condicao.ends_with(SUFIXO_PARA_CIMA)
	var base: String = condicao.trim_suffix(SUFIXO_PARA_CIMA)
	if FAIXAS_POR_CONDICAO.has(base):
		var faixa: Array = FAIXAS[FAIXAS_POR_CONDICAO[base]]
		no.relacionamento_minimo = faixa[0]
		no.relacionamento_maximo = NoDialogo.RELACIONAMENTO_SEM_TETO if para_cima else faixa[1]
	elif ESTACOES_POR_CONDICAO.has(StringName(condicao)):
		no.estacoes.append(StringName(condicao))
	elif condicao == "namorando":
		no.so_namorando = true
	elif condicao == "uma_vez":
		no.uma_vez = true
	elif condicao != "":
		if not _situacao_existe(condicao):
			push_error("Condição desconhecida na biblioteca: [%s] (fala de %s)" % [condicao, no.falante_id])
		no.situacoes.append(StringName(condicao))

func _situacao_existe(condicao: String) -> bool:
	if SITUACOES_CONHECIDAS.has(condicao):
		return true
	if condicao.begins_with("em:"):
		return LUGARES.has(condicao.trim_prefix("em:"))
	if condicao.begins_with("aniversario_de:"):
		return IDS_POR_NOME.values().has(condicao.trim_prefix("aniversario_de:"))
	return false

## O id da fala sai do texto dela, e não da posição na biblioteca. A memória do que já foi
## dito é guardada por id, e assim reordenar ou acrescentar falas não a embaralha.
func _dar_ids(conversa: Conversa) -> void:
	for no in conversa.nos:
		no.id = "%s_%s" % [conversa.npc_id, no.texto.md5_text().left(8)]

func _salvar(conversa: Conversa) -> void:
	if conversa == null:
		return
	_dar_ids(conversa)
	var caminho: String = PASTA_DAS_CONVERSAS + conversa.npc_id + ".tres"
	var erro: Error = ResourceSaver.save(conversa, caminho)
	print("%s: %d falas (erro %d)" % [caminho, conversa.nos.size(), erro])
