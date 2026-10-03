class_name PerfilEstacao
extends Resource

## O que muda no mundo em uma estação. Os valores são ajustes sobre o ciclo do dia do
## plano 10, e não uma paleta nova: a luz e a grama de cada hora continuam vindo de lá, e
## a estação só multiplica e tinge.

@export var id: StringName = &""
@export var nome_exibido: String = ""
## Faixa tocada ao entrar na estação. Vazio mantém a música que já está tocando.
@export var musica: AudioStream
## Multiplica a cor do sol de cada hora. Branco não muda nada.
@export var cor_da_luz: Color = Color.WHITE
## Multiplica a energia do sol e do ambiente. Abaixo de 1 deixa a estação mais escura.
@export var multiplicador_de_energia: float = 1.0
## Hora em que o sol se põe. Substitui a constante HORA_ANOITECER na iluminação.
@export var hora_do_anoitecer: float = 18.0
## Multiplica a cor do material da grama. Branco não muda nada.
@export var cor_da_grama: Color = Color.WHITE
## Chance de o dia amanhecer chovendo. Usado pelo clima, no plano 13.
@export var chance_de_chuva: float = 0.2
