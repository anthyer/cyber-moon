class_name PerfilChefe
extends PerfilInimigo

## O perfil de um subchefe ou chefe de dungeon. Tem tudo de um inimigo comum (vida,
## velocidade, percepção, saque) e mais os ataques próprios, anunciados antes de acertar,
## e a segunda fase. A cena usada é a do Chefe, e não a do inimigo comum.

## O nome que aparece na barra de vida do chefe.
@export var titulo: String = ""
## Verdadeiro para o chefe do fim da dungeon; falso para o subchefe.
@export var eh_chefe_final: bool = false
## O tamanho do modelo e da cápsula, em relação a um inimigo comum.
@export var escala: float = 2.0
## Os ataques próprios. O chefe sorteia um entre os que valem na fase em que está.
@export var ataques: Array[AtaqueDeChefe] = []
## Segundos entre o fim de um ataque e o começo do próximo.
@export var intervalo_entre_ataques_especiais: float = 3.0

@export_group("Segunda fase")
## Abaixo desta fração da vida o chefe entra na segunda fase. Zero desliga a fase (subchefe).
@export_range(0.0, 1.0) var fracao_de_vida_da_fase_2: float = 0.5
@export var multiplicador_de_velocidade_na_fase_2: float = 1.4
@export var multiplicador_de_intervalo_na_fase_2: float = 0.65
