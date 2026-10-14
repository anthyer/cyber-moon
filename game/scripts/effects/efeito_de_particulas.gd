class_name EfeitoDeParticulas
extends CPUParticles3D

## Um sopro de partículas que dispara uma vez e se apaga sozinho.
##
## Usa CPUParticles3D, e não GPUParticles3D, porque o jogo roda no renderizador
## Compatibility com a web como alvo, onde as partículas de CPU funcionam igual em
## qualquer máquina. Os efeitos do jogo são pequenos, então não há ganho em usar a GPU.

func _ready() -> void:
	one_shot = true
	finished.connect(queue_free)
	emitting = true

## Cria o efeito na posição, com a cor e a quantidade pedidas. O pai é quem segura o
## efeito na cena: precisa ser a fase, e não quem disparou, senão as partículas andam
## junto com o personagem.
static func soltar(cena: PackedScene, posicao: Vector3, cor: Color, quantidade: int, pai: Node) -> EfeitoDeParticulas:
	var efeito: EfeitoDeParticulas = cena.instantiate() as EfeitoDeParticulas
	efeito.color = cor
	efeito.amount = quantidade
	# A posição entra antes de o efeito ir para a árvore. Ele começa a emitir no _ready, e
	# as partículas ficam onde nascem: posicionando depois, a maior parte nasceria na
	# origem do pai, longe da ação.
	var pai_3d: Node3D = pai as Node3D
	efeito.position = pai_3d.to_local(posicao) if pai_3d != null else posicao
	pai.add_child(efeito)
	return efeito
