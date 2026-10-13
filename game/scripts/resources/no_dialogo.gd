class_name NoDialogo
extends Resource

## Uma fala de um diálogo: quem fala, o texto, e quando ela pode aparecer.
##
## As condições se somam: a fala só serve quando todas valem. Quanto mais condições, mais
## específica ela é, e a mais específica vence as outras na escolha da fala do dia (ver
## DialogueManager). Assim uma fala geral de "conhecido" convive com a fala de "primeiro
## dia do Apagão, chovendo".

## Quanto cada condição pesa na conta da especificidade. Nem toda condição vale o mesmo:
## uma fala sobre o jogador ter desmaiado ontem precisa vencer uma fala sobre a chuva, que
## precisa vencer a fala comum da faixa de amizade. Do mais leve ao mais pesado:
##
## - a faixa de amizade, a estação e os marcos, que valem por muito tempo;
## - o ambiente do momento: clima, dia da semana, hora e lugar;
## - o que aconteceu no mundo: o clima de ontem, datas do calendário, aniversário de outro;
## - o que aconteceu com o jogador: sumiu, desmaiou, está ferido, voltou da dungeon;
## - o momento único: o primeiro encontro e o aniversário do próprio personagem.
const PESO_DE_CONDICAO_DURADOURA: int = 1
const PESO_DO_AMBIENTE: int = 2
const PESO_DO_NAMORO: int = 2
const PESO_DO_MUNDO: int = 3
const PESO_DO_JOGADOR: int = 4
const PESO_DE_MOMENTO_UNICO: int = 8
const SITUACOES_DURADOURAS: Array[StringName] = [&"marco_1", &"marco_2", &"marco_3"]
const SITUACOES_DO_MUNDO: Array[StringName] = [&"choveu_ontem", &"tempestade_ontem", &"primeiro_dia_da_estacao", &"ultimo_dia_da_estacao", &"primeiro_dia_do_ano"]
const SITUACOES_DO_JOGADOR: Array[StringName] = [&"sumido", &"desmaiou_ontem", &"vida_baixa", &"saiu_da_dungeon", &"namorando_outro"]
const MOMENTOS_UNICOS: Array[StringName] = [&"primeiro_encontro", &"aniversario"]
const PREFIXO_DE_ANIVERSARIO_DE_OUTRO: String = "aniversario_de:"
const RELACIONAMENTO_SEM_TETO: int = 9999

@export var id: String = ""
## O id do PerfilNpc de quem fala, ou "jogador" quando é o personagem do jogador.
@export var falante_id: String = ""
@export_multiline var texto: String = ""
## Ids das falas que vêm depois desta, na mesma Conversa. Vazio encerra o diálogo. Hoje
## as conversas são lineares e só a primeira é seguida; a lista existe para diálogo com
## escolha, mais adiante.
@export var proximos_nos: Array[String] = []
## A fala só entra na escolha do dia se o relacionamento com o NPC estiver neste
## intervalo, em pontos. Deixa o NPC falar diferente conforme a amizade.
@export var relacionamento_minimo: int = 0
@export var relacionamento_maximo: int = RELACIONAMENTO_SEM_TETO
## Só vale quando este NPC namora o jogador.
@export var so_namorando: bool = false
## Ids de SeasonManager.ESTACOES. Vazio vale para qualquer estação.
@export var estacoes: Array[StringName] = []
## Outras condições, pelo nome: o clima (chuva), o dia (folga), a hora (noite), o lugar
## (em:praca), uma data (aniversario) ou uma situação do jogador (desmaiou_ontem). A lista
## completa e o que cada uma quer dizer estão em equipe/personas/leiame.md. Quem diz
## quais valem agora é o DialogueManager.
@export var situacoes: Array[StringName] = []
## A fala só é dita uma vez no jogo inteiro.
@export var uma_vez: bool = false
## Animação que o modelo de quem fala toca durante a fala.
@export var animacao: StringName = &"idle"
## Verdadeiro para a fala que só aparece como continuação de outra, e nunca abre um
## diálogo sozinha.
@export var so_como_continuacao: bool = false

## situacoes_ativas tem como chave o nome de cada situação que vale agora.
func serve_para(relacionamento: int, estacao: StringName, situacoes_ativas: Dictionary, namorando: bool) -> bool:
	if so_como_continuacao:
		return false
	if relacionamento < relacionamento_minimo or relacionamento > relacionamento_maximo:
		return false
	if so_namorando and not namorando:
		return false
	if not estacoes.is_empty() and not estacoes.has(estacao):
		return false
	for situacao in situacoes:
		if not situacoes_ativas.has(situacao):
			return false
	return true

## A soma dos pesos das condições que esta fala exige. A fala sem condição vale zero.
func especificidade() -> int:
	var total: int = 0
	if relacionamento_minimo > 0 or relacionamento_maximo < RELACIONAMENTO_SEM_TETO:
		total += PESO_DE_CONDICAO_DURADOURA
	if not estacoes.is_empty():
		total += PESO_DE_CONDICAO_DURADOURA
	if so_namorando:
		total += PESO_DO_NAMORO
	for situacao in situacoes:
		total += _peso_da_situacao(situacao)
	return total

func _peso_da_situacao(situacao: StringName) -> int:
	if MOMENTOS_UNICOS.has(situacao):
		return PESO_DE_MOMENTO_UNICO
	if SITUACOES_DO_JOGADOR.has(situacao):
		return PESO_DO_JOGADOR
	if SITUACOES_DO_MUNDO.has(situacao) or String(situacao).begins_with(PREFIXO_DE_ANIVERSARIO_DE_OUTRO):
		return PESO_DO_MUNDO
	if SITUACOES_DURADOURAS.has(situacao):
		return PESO_DE_CONDICAO_DURADOURA
	return PESO_DO_AMBIENTE
