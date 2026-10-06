class_name QuadroCalendario
extends Node3D

## O quadro de calendário no mundo: interagir com ele abre a tela do calendário. É o único
## jeito de abrir, no teclado e no controle; não existe tecla de atalho, por decisão de
## design. O quadro não conhece a tela; ele só pede pelo EventBus, e quem estiver ouvindo abre.

func interagir() -> void:
	EventBus.calendar_requested.emit()
