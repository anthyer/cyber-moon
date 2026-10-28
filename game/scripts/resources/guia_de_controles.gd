class_name GuiaDeControles
extends Resource

## A tabela de controles que a demo mostra ao jogador: no tutorial do começo, no menu
## principal e na aba Controles do menu de pausa. Cada linha é uma ação, com o que se
## aperta no teclado e mouse e no controle.
##
## O texto é escrito à mão, e não lido do Input Map, porque o nome que o Godot dá a um
## botão de controle ("Joypad Button 2, Sony Square, Xbox X...") não serve para tela.
## Mudou um bind no project.godot? Mude a linha aqui e em game/docs/entrada.md.

@export var acoes: Array[String] = []
## O que se aperta no teclado e mouse, na mesma ordem de acoes.
@export var teclado: Array[String] = []
## O que se aperta no controle, na mesma ordem de acoes.
@export var controle: Array[String] = []
