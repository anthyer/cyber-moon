class_name Conversa
extends Resource

## Todas as falas de um NPC, num arquivo só. O DialogueManager escolhe uma por dia entre
## as que servem para o relacionamento e a estação.

@export var id: StringName = &""
@export var npc_id: String = ""
@export var nos: Array[NoDialogo] = []
## Falas disparadas por evento, e não sorteadas no dia: a reação a cada tipo de presente
## (amou, gostou, neutro, nao_gostou, odiou), o aniversario, o presente repetido na semana
## (ja_presenteou) e as respostas ao buquê (buque_aceito, buque_poucos_coracoes,
## buque_nao_romanceavel, buque_ja_namorando).
@export var falas_de_evento: Dictionary[StringName, String] = {}

func fala_de_evento(evento: StringName) -> String:
	return falas_de_evento.get(evento, "")

func no_por_id(id_do_no: String) -> NoDialogo:
	for no in nos:
		if no.id == id_do_no:
			return no
	return null

## As falas que podem abrir o diálogo de hoje.
func candidatos(relacionamento: int, estacao: StringName) -> Array[NoDialogo]:
	var lista: Array[NoDialogo] = []
	for no in nos:
		if no.serve_para(relacionamento, estacao):
			lista.append(no)
	return lista
