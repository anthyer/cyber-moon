class_name AtaqueDeChefe
extends Resource

## Um ataque próprio de chefe. Todo ataque é anunciado: uma marca aparece no chão, dura o
## tempo de aviso, e só então o dano cai em quem estiver dentro dela. É o aviso que deixa a
## luta justa: o jogador vê e sai.

enum Forma {
	## Um círculo no chão em volta do próprio chefe.
	CIRCULO_NO_CHEFE,
	## Um círculo no chão onde o alvo estava quando o aviso começou.
	CIRCULO_NO_ALVO,
	## Uma faixa reta do chefe na direção do alvo.
	FAIXA_NA_DIRECAO_DO_ALVO,
	## Vários círculos espalhados em volta do alvo.
	CHUVA_EM_VOLTA_DO_ALVO,
}

@export var id: StringName = &""
@export var nome: String = ""
@export var forma: Forma = Forma.CIRCULO_NO_ALVO
@export var dano: int = 15
## O raio do círculo, ou a meia largura da faixa.
@export var raio: float = 1.6
## O comprimento da faixa. Só vale para a faixa.
@export var comprimento: float = 7.0
## Quantos círculos caem. Só vale para a chuva.
@export var quantidade: int = 5
## O raio em volta do alvo onde os círculos da chuva caem.
@export var espalhamento: float = 3.5
## Segundos entre a marca aparecer e o dano cair.
@export var segundos_de_aviso: float = 1.1
## A cor da marca no chão. Nunca vermelha: o jogo não tem sangue.
@export var cor: Color = Color(1.0, 0.75, 0.2)
## Verdadeiro para o ataque que só entra na segunda fase.
@export var so_na_fase_2: bool = false
