extends SceneTree

## Gera os .tres de Conversa dos NPCs a partir de equipe/biblioteca-de-dialogos.md.
##
##     godot --headless --path game --script res://scripts/utils/gerar_dialogos.gd
##
## A biblioteca é o texto que a equipe escreve e revisa; este script só a transcreve para
## o formato do jogo, para ninguém copiar duzentas falas à mão. Para mudar uma fala,
## edite a biblioteca e rode de novo: os .tres são sobrescritos.
##
## Entram as falas do dia a dia: as quatro faixas de relacionamento e as de estação. As de
## presente, de aniversário e de buquê são disparadas por evento, e entram no plano 16.

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

func _init() -> void:
	var caminho: String = ProjectSettings.globalize_path("res://").path_join(CAMINHO_DA_BIBLIOTECA)
	var arquivo: FileAccess = FileAccess.open(caminho, FileAccess.READ)
	if arquivo == null:
		push_error("Biblioteca não encontrada: %s" % caminho)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(PASTA_DAS_CONVERSAS)

	var conversa: Conversa = null
	## A subseção em que as linhas estão: uma faixa, "Por estação", ou outra (ignorada).
	var secao: String = ""
	## A fala em construção, porque uma fala longa continua na linha de baixo.
	var no_atual: NoDialogo = null
	while not arquivo.eof_reached():
		var linha: String = arquivo.get_line()
		if linha.begins_with("## "):
			_salvar(conversa)
			conversa = _nova_conversa(linha.trim_prefix("## ").strip_edges())
			secao = ""
			no_atual = null
		elif linha.begins_with("**"):
			secao = linha.get_slice("**", 1).trim_suffix(":")
			no_atual = null
		elif linha.begins_with("- ") and conversa != null:
			no_atual = _novo_no(conversa, secao, linha.trim_prefix("- ").strip_edges())
		elif linha.begins_with("  ") and no_atual != null:
			no_atual.texto += " " + linha.strip_edges()
		else:
			no_atual = null
	_salvar(conversa)
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
