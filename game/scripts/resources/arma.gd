class_name Arma
extends Item

## Uma arma do jogador. Os tipos não são sistemas diferentes, são configurações do
## mesmo golpe: muda o número, a velocidade da animação e, na arma de distância, o
## disparo de um projétil no lugar da área de acerto.

enum Tipo {
	## Soco em combo de três golpes: as mãos vazias e os cestos.
	PUNHO,
	## Um golpe rápido por vez.
	LEVE,
	## Um golpe lento, de dano e alcance grandes. Usa a mesma animação da leve,
	## desacelerada, que é o que dá a sensação de peso.
	PESADA,
	## Dispara um projétil que viaja até bater em alguma coisa.
	DISTANCIA,
}

@export var tipo: Tipo = Tipo.LEVE
@export var dano: int = 10
## Até onde o golpe alcança à frente do jogador, em metros. Na arma de distância não é
## usado: o alcance é o tempo de vida do projétil.
@export var alcance: float = 1.2
## Cobrado só quando o golpe acerta um oponente. Golpe no ar é de graça.
@export var custo_de_stamina: float = 1.5
@export var velocidade_da_animacao: float = 1.6
## Espera, depois do golpe, até poder atacar de novo.
@export var cooldown: float = 0.3
@export var som_do_golpe: AudioStream

@export_group("Modelo na mão")
## Modelo 3D preso na mão direita enquanto a arma está em uso. Vazio não mostra nada.
@export var modelo: PackedScene
@export var escala_do_modelo: Vector3 = Vector3.ONE
@export var posicao_do_modelo: Vector3 = Vector3.ZERO
@export var rotacao_do_modelo_em_graus: Vector3 = Vector3.ZERO

@export_group("Projétil")
@export var projetil: PackedScene
@export var velocidade_do_projetil: float = 18.0

@export_group("Mira")
## Mostra uma linha de laser saindo da arma até o primeiro obstáculo, para o jogador
## ver para onde o tiro vai. O comprimento máximo é o alcance da arma.
@export var tem_mira_laser: bool = false
## Multiplica a velocidade com que o personagem vira enquanto a arma está na mão. Arma
## de mira pede giro rápido, senão o tiro sai antes de o personagem terminar de virar.
@export var multiplicador_de_giro: float = 1.0
