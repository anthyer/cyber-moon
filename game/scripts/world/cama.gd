class_name Cama
extends Node3D

## A cama da casa do jogador. Interagir com ela é ir dormir: o dia vira sem penalidade e
## a stamina volta cheia. É o caminho bom; a alternativa é cair de sono à 1:00.

## Segue o contrato de interação do jogo (ver AreaDeInteracao): a área desta cena fica na
## camada area_interacao, e o jogador só chama este método.
func interagir() -> void:
	DayCycleManager.dormir(false)
