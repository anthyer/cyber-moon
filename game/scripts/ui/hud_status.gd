extends Control

## Vida e stamina no canto da tela durante o jogo. As barras em si são o componente
## BarrasDeStatus; este script só cuida de quando a HUD aparece.

func _ready() -> void:
	# Processa sempre, mesmo com o jogo pausado, só para saber a hora de sumir. O menu
	# de pausa mostra as mesmas barras, e sem isso elas apareceriam duas vezes. É a
	# mesma saída da barra rápida.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	visible = not get_tree().paused
