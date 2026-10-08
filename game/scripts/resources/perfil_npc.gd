class_name PerfilNpc
extends Resource

## Os dados de um NPC: quem ele é, como aparece, onde mora e a rotina dele. A cena do NPC
## (npc.tscn) é uma só para todos, e é este Resource que a transforma no Vitor ou na Marta.

@export var id: String = ""
@export var nome_exibido: String = ""
@export var retrato: Texture2D
@export var relacionamento_inicial: int = 0
@export var relacionamento_maximo: int = 2500
## O aniversário: o id da estação (um dos SeasonManager.ESTACOES) e o dia dentro dela,
## de 1 a 30. O calendário mostra, e o presente de aniversário vale mais (plano 16).
@export var estacao_do_aniversario: StringName = &"brotacao"
@export var dia_do_aniversario: int = 1

## O que ele vende. Vazio para quem não é comerciante.
@export var catalogo: CatalogoDeLoja

@export_group("Gostos")
## O que ele pensa de cada presente. Item fora das quatro listas é neutro. Cada gosto diz
## algo sobre o personagem, e descobrir faz parte do jogo: a interface não mostra.
@export var itens_amados: Array[Item] = []
@export var itens_queridos: Array[Item] = []
@export var itens_indesejados: Array[Item] = []
@export var itens_odiados: Array[Item] = []

@export_group("No mundo")
@export var modelo: PackedScene
@export var velocidade: float = 2.2
## Nome do Marker3D da casa (filho do nó PontosDeRotina da fase). É onde o NPC nasce e
## para onde ele vai quando nenhum compromisso serve, na Folga e na tempestade.
@export var casa: StringName = &""
## Os compromissos fora de casa. O que a rotina não cobre, ele passa em casa.
@export var rotina: Array[Compromisso] = []
@export var eh_romanceavel: bool = false

func faz_aniversario(estacao: StringName, dia_da_estacao: int) -> bool:
	return estacao == estacao_do_aniversario and dia_da_estacao == dia_do_aniversario

## O compromisso que vale para o momento dado, ou null se nenhum serve (aí é casa). Entre
## os que servem vence o mais específico; no empate, o que vem antes na lista.
func compromisso_para(hora: float, estacao: StringName, dia_da_semana: int, clima: StringName, e_aniversario: bool) -> Compromisso:
	var escolhido: Compromisso = null
	for compromisso in rotina:
		if not compromisso.serve_para(hora, estacao, dia_da_semana, clima, e_aniversario):
			continue
		if escolhido == null or compromisso.especificidade() > escolhido.especificidade():
			escolhido = compromisso
	return escolhido
