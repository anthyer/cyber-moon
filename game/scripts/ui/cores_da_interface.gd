class_name CoresDaInterface
extends RefCounted

## As cores da interface, lidas do Theme do projeto (resources/ui/tema_cyber_moon.tres,
## type "Cores"). Script de tela não declara constante de cor própria: pergunta aqui.
## Assim a cor muda num lugar só, no gerador do Theme (scripts/utils/gerar_tema.gd).
##
##     rotulo.add_theme_color_override(&"font_color", CoresDaInterface.ouro())
##
## A tabela das cores e o papel de cada uma estão em docs/arquitetura.md, na seção
## "Interface: Theme e palco de modelo". Nada vermelho: aviso e falta são âmbar, dano é
## magenta.

const TIPO_DAS_CORES: StringName = &"Cores"
const CAMINHO_DO_TEMA: String = "res://resources/ui/tema_cyber_moon.tres"

static var _tema: Theme

## O Theme do projeto (o mesmo de gui/theme/custom no project.godot).
static func tema() -> Theme:
	if _tema == null:
		_tema = ThemeDB.get_project_theme()
	if _tema == null:
		_tema = load(CAMINHO_DO_TEMA) as Theme
	return _tema

## A cor pelo nome. Nome que não existe no Theme dá magenta forte e um aviso, para o erro
## aparecer na tela em vez de passar despercebido.
static func cor(nome: StringName) -> Color:
	if not tema().has_color(nome, TIPO_DAS_CORES):
		push_warning("Cor de interface desconhecida: %s" % nome)
		return Color.MAGENTA
	return tema().get_color(nome, TIPO_DAS_CORES)

## Foco, informação, golpe crítico.
static func ciano() -> Color:
	return cor(&"ciano")

## Segurando item, dano, convite, ação destrutiva.
static func magenta() -> Color:
	return cor(&"magenta")

## Dinheiro, preço, item na mão, stamina, recompensa.
static func ouro() -> Color:
	return cor(&"ouro")

## Vida, ganho, cura, o que se tem.
static func verde() -> Color:
	return cor(&"verde")

## Corações, aniversário.
static func rosa() -> Color:
	return cor(&"rosa")

## Fase 2 do chefe, desmaio, madrugada.
static func violeta() -> Color:
	return cor(&"violeta")

## Aviso, erro, o que falta. É o que antes era vermelho.
static func ambar() -> Color:
	return cor(&"ambar")

static func texto() -> Color:
	return cor(&"texto")

static func texto_apagado() -> Color:
	return cor(&"texto_apagado")

## Texto e borda de coisa desligada (botão sem uso, item que não dá para pagar).
static func desligado() -> Color:
	return cor(&"desligado")

static func fundo_painel() -> Color:
	return cor(&"fundo_painel")

static func borda() -> Color:
	return cor(&"borda")

static func borda_escura() -> Color:
	return cor(&"borda_escura")

## O azul quase preto do fundo, usado como cor de texto sobre fundo aceso (aba ativa,
## tecla na tela).
static func noite() -> Color:
	return cor(&"noite")

## O roxo escuro da lixeira do inventário.
static func lixeira() -> Color:
	return cor(&"lixeira")
