class_name NoDialogo
extends Resource

## Uma fala de um diálogo: quem fala, o texto, e quando ela pode aparecer.

@export var id: String = ""
## O id do PerfilNpc de quem fala, ou "jogador" quando é o personagem do jogador.
@export var falante_id: String = ""
@export_multiline var texto: String = ""
## Ids das falas que vêm depois desta, na mesma Conversa. Vazio encerra o diálogo. Hoje
## as conversas são lineares e só a primeira é seguida; a lista existe para diálogo com
## escolha, mais adiante.
@export var proximos_nos: Array[String] = []
## A fala só entra no sorteio do dia se o relacionamento com o NPC estiver neste
## intervalo. Deixa o NPC falar diferente conforme a amizade (plano 16).
@export var relacionamento_minimo: int = 0
@export var relacionamento_maximo: int = 9999
## Ids de SeasonManager.ESTACOES. Vazio vale para qualquer estação.
@export var estacoes: Array[StringName] = []
## Animação que o modelo de quem fala toca durante a fala.
@export var animacao: StringName = &"idle"
## Verdadeiro para a fala que só aparece como continuação de outra, e nunca abre um
## diálogo sozinha.
@export var so_como_continuacao: bool = false

func serve_para(relacionamento: int, estacao: StringName) -> bool:
	if so_como_continuacao:
		return false
	if relacionamento < relacionamento_minimo or relacionamento > relacionamento_maximo:
		return false
	return estacoes.is_empty() or estacoes.has(estacao)
