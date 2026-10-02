class_name PerfilInimigo
extends Resource

## Tudo que diferencia um tipo de inimigo do outro. A cena e o script do inimigo são um
## só para todos os tipos: o que muda entre o drone, o ciborgue e a sentinela é este
## Resource.

enum ComportamentoOcioso {
	## Corre em círculo em volta de onde nasceu.
	CIRCULO,
	## Vai e volta entre onde nasceu e um ponto de patrulha.
	PATRULHA,
	## Fica parado, girando devagar.
	PARADO,
}

@export var id: StringName = &""
@export var nome: String = ""
## Modelo placeholder, tingido com a cor abaixo para não ser confundido com NPC.
@export var modelo: PackedScene
@export var cor: Color = Color.WHITE

@export_group("Combate")
@export var vida_maxima: int = 50
@export var velocidade: float = 3.0
@export var dano: int = 10
@export var alcance_de_ataque: float = 1.4
@export var intervalo_entre_ataques: float = 1.5
@export var animacao_de_ataque: StringName = &"attack-melee-right"
@export var velocidade_da_animacao_de_ataque: float = 1.0

@export_group("Ataque de distância")
## Com um projétil aqui, o ataque deixa de ser corpo a corpo: o inimigo para ao chegar
## no alcance de ataque e dispara. O dano do perfil passa a ser o de cada projétil.
@export var projetil: PackedScene
@export var projeteis_por_disparo: int = 1
## Abertura total do leque, em graus, quando há mais de um projétil.
@export var abertura_do_cone_em_graus: float = 0.0
## Lento de propósito: o jogador vê o tiro vindo e pode desviar.
@export var velocidade_do_projetil: float = 5.0
## Distância que o projétil percorre antes de sumir.
@export var alcance_do_projetil: float = 9.0

@export_group("Percepção")
@export var raio_de_percepcao: float = 10.0
## Maior que o raio de percepção de propósito. Se fossem iguais, o inimigo ligaria e
## desligaria a perseguição na borda exata, tremendo no lugar.
@export var raio_de_desistencia: float = 15.0
@export var comportamento_ocioso: ComportamentoOcioso = ComportamentoOcioso.PATRULHA

@export_group("Recompensa")
@export var experiencia_concedida: int = 30
## Ao morrer, solta um destes itens, sorteado, com a chance abaixo.
@export var itens_dropados: Array[Item] = []
@export_range(0.0, 1.0) var chance_de_drop: float = 0.6
