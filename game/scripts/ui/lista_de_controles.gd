class_name ListaDeControles
extends GridContainer

## A tabela de controles, montada a partir de um GuiaDeControles: uma linha de títulos e
## uma linha por ação, em três colunas (ação, teclado e mouse, controle).

const COR_DO_TITULO: Color = Color(0.2, 0.95, 1.0)
const COR_DA_ACAO: Color = Color(0.92, 0.95, 1.0)
const COR_DA_TECLA: Color = Color(1.0, 0.85, 0.35)
const LARGURA_DA_COLUNA_DA_ACAO: float = 330.0

@export var guia: GuiaDeControles
## Zero usa o tamanho de letra do tema. O menu principal pede uma letra menor, para a
## tabela caber embaixo do título.
@export var tamanho_da_fonte: int = 0

func _ready() -> void:
	columns = 3
	if guia == null:
		push_warning("ListaDeControles sem guia.")
		return
	_adicionar_celula("Ação", COR_DO_TITULO)
	_adicionar_celula("Teclado e mouse", COR_DO_TITULO)
	_adicionar_celula("Controle", COR_DO_TITULO)
	for indice in guia.acoes.size():
		var tecla: String = guia.teclado[indice] if indice < guia.teclado.size() else ""
		var botao: String = guia.controle[indice] if indice < guia.controle.size() else ""
		var rotulo_da_acao: Label = _adicionar_celula(guia.acoes[indice], COR_DA_ACAO)
		# Só a primeira coluna quebra linha: a ação é a frase mais longa da tabela.
		rotulo_da_acao.custom_minimum_size.x = LARGURA_DA_COLUNA_DA_ACAO
		rotulo_da_acao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_adicionar_celula(tecla, COR_DA_TECLA)
		_adicionar_celula(botao, COR_DA_TECLA)

func _adicionar_celula(texto: String, cor: Color) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rotulo.add_theme_color_override(&"font_color", cor)
	if tamanho_da_fonte > 0:
		rotulo.add_theme_font_size_override(&"font_size", tamanho_da_fonte)
	add_child(rotulo)
	return rotulo
