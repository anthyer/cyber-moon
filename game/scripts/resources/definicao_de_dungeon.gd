class_name DefinicaoDeDungeon
extends Resource

## Uma dungeon do jogo: como se chama, qual cena é, o que a libera e o que ela dá.
## Um .tres por dungeon em resources/dungeons/. O lobby lista as definições, e o
## DungeonManager cria a cena da que foi escolhida.

@export var id: StringName = &""
@export var nome: String = ""
@export_multiline var descricao: String = ""
## A posição na lista do lobby, da primeira para a última.
@export var ordem: int = 0
@export_file("*.tscn") var cena: String = ""
## Id da dungeon cujo chefe precisa ter sido vencido para esta abrir. Vazio para a que
## está aberta desde o começo.
@export var requer: StringName = &""

@export_group("Recompensa do chefe")
## Dada na primeira vitória do dia. Os materiais saem da faixa rara.
@export var creditos: int = 300
@export var materiais_raros: int = 2
## A mais, quando o objetivo paralelo foi cumprido.
@export var creditos_do_objetivo: int = 150
@export var materiais_raros_do_objetivo: int = 1
## O troféu, dado só na primeira vitória de todas. É um item-chave.
@export var trofeu: Item

@export_group("Em equipe")
## Quanto de vida a mais o subchefe e o chefe ganham por jogador além do primeiro.
@export var vida_a_mais_por_jogador: float = 0.6
