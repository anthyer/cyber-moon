class_name Ferramenta
extends Item

@export var id_acao: StringName = &""
@export var som_de_uso: AudioStream
## Stamina gasta e experiência ganha cada vez que a ferramenta tem efeito. Usar a
## ferramenta onde ela não faz nada não custa.
@export var custo_de_stamina: float = 1.0
@export var experiencia_ao_usar: int = 0
