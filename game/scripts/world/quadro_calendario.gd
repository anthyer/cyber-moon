class_name QuadroCalendario
extends Node3D

## O quadro de calendário no mundo: interagir com ele abre a mesma tela que a tecla C.
## É o jeito de abrir o calendário pelo controle, que não tem botão sobrando para ele.
## O quadro não conhece a tela; ele só pede pelo EventBus, e quem estiver ouvindo abre.

func interagir() -> void:
	EventBus.calendar_requested.emit()
