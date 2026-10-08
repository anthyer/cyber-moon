extends SceneTree

## Gera os .tres de Conversa dos NPCs a partir de equipe/biblioteca-de-dialogos.md.
##
##     godot --headless --path game --script res://scripts/utils/gerar_dialogos.gd
##
## A biblioteca é o texto que a equipe escreve e revisa; este script só a transcreve para
## o formato do jogo, para ninguém copiar duzentas falas à mão. Para mudar uma fala,
## edite a biblioteca e rode de novo: os .tres são sobrescritos.
##
## As falas do dia a dia (as quatro faixas de relacionamento e as de estação) viram
## NoDialogo. As de presente, de aniversário e de buquê são disparadas por evento, e vão
## para o dicionário falas_de_evento da Conversa. As "Falas de sistema" do fim da
## biblioteca valem para todos, e são copiadas para a Conversa de cada NPC.

const CAMINHO_DA_BIBLIOTECA: String = "../equipe/biblioteca-de-dialogos.md"
const PASTA_DAS_CONVERSAS: String = "res://resources/dialogue/"

## O primeiro nome no título da seção para o id do PerfilNpc.
const IDS_POR_NOME: Dictionary = {
	"Vitor": "vitor", "Kenji": "kenji", "Rafael": "rafa", "Marta": "marta", "Iara": "iara", "Sol": "sol",
}
## Faixa de relacionamento para [mínimo, máximo], em pontos, como na tabela da biblioteca.
const FAIXAS: Dictionary = {
	"Distante": [0, 749], "Conhecido": [750, 1499], "Amigo": [1500, 2499], "Íntimo": [2500, 9999],
}
const ESTACOES_POR_NOME: Dictionary = {
	"Brotação": &"brotacao", "Estiagem": &"estiagem", "Colheita": &"colheita", "Apagão": &"apagao",
}
const SECAO_DE_ESTACAO: String = "Por estação"
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
	elif secao == SECAO_DE_ESTACAO:
		# "Brotação: Chuva boa pra planta..." vale só naquela estação, em qualquer faixa.
		var nome_da_estacao: String = texto.get_slice(":", 0)
		if not ESTACOES_POR_NOME.has(nome_da_estacao):
			return null
		no.estacoes.append(ESTACOES_POR_NOME[nome_da_estacao])
		no.texto = texto.substr(nome_da_estacao.length() + 1).strip_edges()
	else:
		return null
	no.id = "%s_%02d" % [conversa.npc_id, conversa.nos.size() + 1]
	conversa.nos.append(no)
	return no

func _salvar(conversa: Conversa) -> void:
	if conversa == null:
		return
	var caminho: String = PASTA_DAS_CONVERSAS + conversa.npc_id + ".tres"
	var erro: Error = ResourceSaver.save(conversa, caminho)
	print("%s: %d falas (erro %d)" % [caminho, conversa.nos.size(), erro])
