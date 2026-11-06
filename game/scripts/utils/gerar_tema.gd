extends SceneTree

## Gera o Theme da interface (resources/ui/tema_cyber_moon.tres) e as texturas de pixel
## que ele usa (assets/textures/ui/), a partir dos mocks aprovados do plano 40
## (equipe/mocks-de-interface/, seção "Folha de componentes", e o estilo.css ao lado).
##
##     godot --headless --path game --script res://scripts/utils/gerar_tema.gd
##     godot --headless --path game --import
##
## O script desenha as texturas e monta o Theme apontando para elas. Na primeira vez, as
## texturas ainda não foram importadas e o Theme não sai: rode o --import e rode o script
## de novo. Depois disso, mudar um desenho só precisa do --import (o Theme guarda o
## caminho, não o desenho), e mudar uma cor, um tamanho ou uma variation só precisa do
## script.
##
## Fica versionado como documentação de onde veio cada peça. Para mudar o visual, edite
## as tabelas e funções abaixo e rode de novo: o .tres e os .png são sobrescritos. Não
## edite o .tres no Inspector, porque a próxima geração apaga a mudança.
##
## Tudo é desenhado em pixel de tela (1 texel = 1 pixel em 1152 por 648), com borda de
## 3 px, como no mock. O projeto usa filtro nearest no 2D, então o desenho não borra
## quando a janela cresce.

const CAMINHO_DO_TEMA: String = "res://resources/ui/tema_cyber_moon.tres"
const PASTA_DAS_TEXTURAS: String = "res://assets/textures/ui/"

const FONTE_DE_TEXTO: String = "res://assets/fonts/vt323/vt323_regular.ttf"
const FONTE_DE_TITULO: String = "res://assets/fonts/silkscreen/silkscreen_regular.ttf"
const FONTE_DE_TITULO_NEGRITO: String = "res://assets/fonts/silkscreen/silkscreen_bold.ttf"

## VT323 em 24 é o texto corrido do mock (20 px em 960 por 540) na escala do jogo.
const TAMANHO_DO_TEXTO: int = 24
## Silkscreen fica nítida em múltiplos de 8.
const TAMANHO_DO_TITULO: int = 16
const TAMANHO_DO_NUMERO_GRANDE: int = 24
const TAMANHO_DO_TITULO_GRANDE: int = 32

## A largura da borda de todas as peças, e o tamanho de cada degrau do canto.
const BORDA: int = 3
## A sombra preta que painel, botão e tecla têm embaixo.
const SOMBRA: int = 3
## O botão tem a altura de uma linha de VT323 24 com as margens. A seta fica no canto de
## cima à esquerda da textura, dentro das margens que não esticam.
const LARGURA_DO_BOTAO: int = 24
const ALTURA_DO_BOTAO: int = 32
const MARGEM_DE_CIMA_DO_BOTAO: int = 22
const MARGEM_ESQUERDA_DO_BOTAO: int = 12
const X_DA_SETA: int = 5
const Y_DA_SETA: int = 11

## As cores da tabela "Cores" do plano 40. São as mesmas constantes que os scripts de
## game/scripts/ui/ já usavam, para o jogo não mudar de cara. Nada vermelho.
const CORES: Dictionary = {
	&"fundo_painel": Color(0.06, 0.07, 0.12, 0.92),
	&"borda": Color(0.25, 0.3, 0.45),
	&"borda_escura": Color(0.12, 0.145, 0.25),
	&"ciano": Color(0.2, 0.95, 1.0),
	&"magenta": Color(1.0, 0.25, 0.8),
	&"ouro": Color(1.0, 0.85, 0.3),
	&"verde": Color(0.4, 1.0, 0.5),
	&"rosa": Color(1.0, 0.45, 0.75),
	&"violeta": Color(0.6, 0.36, 1.0),
	&"ambar": Color(1.0, 0.7, 0.28),
	&"texto": Color(0.92, 0.95, 1.0),
	&"texto_apagado": Color(0.6, 0.66, 0.8),
	&"desligado": Color(0.3, 0.34, 0.47),
	&"noite": Color(0.027, 0.035, 0.07),
	&"lixeira": Color(0.36, 0.23, 0.4),
}

## Cores só do desenho das peças (a borda de dentro de cada variante, o fundo do botão).
## Não entram no Theme como cor, porque tela nenhuma precisa delas.
const BORDA_INTERNA_NEUTRA: Color = Color(0.12, 0.145, 0.25)
const BORDA_INTERNA_CIANO: Color = Color(0.05, 0.23, 0.27)
const BORDA_INTERNA_MAGENTA: Color = Color(0.27, 0.06, 0.23)
const BORDA_INTERNA_OURO: Color = Color(0.27, 0.23, 0.06)
const FUNDO_DO_BOTAO: Color = Color(0.08, 0.1, 0.18)
const FUNDO_DO_BOTAO_FOCADO: Color = Color(0.05, 0.15, 0.19)
const FUNDO_DO_BOTAO_DESTRUTIVO_FOCADO: Color = Color(0.17, 0.04, 0.15)
const BASE_ESCURA_DO_BOTAO: Color = Color(0.04, 0.055, 0.1)
const FUNDO_DO_SLOT: Color = Color(0.024, 0.027, 0.047, 0.85)
const FUNDO_DO_SLOT_TRANCADO: Color = Color(0.043, 0.05, 0.094)
const LISTRA_DO_SLOT_TRANCADO: Color = Color(0.067, 0.078, 0.14)
const FUNDO_DA_LIXEIRA: Color = Color(0.11, 0.04, 0.12, 0.85)
const FUNDO_DA_BARRA: Color = Color(0.043, 0.055, 0.1)
const PRETO: Color = Color(0.0, 0.0, 0.0)
const SOMBRA_DA_TECLA: Color = Color(0.42, 0.46, 0.6)
const SOMBRA_DA_TECLA_PRINCIPAL: Color = Color(0.075, 0.5, 0.54)
const FUNDO_DO_CABECALHO_EM_CIMA: Color = Color(0.12, 0.145, 0.25)
const FUNDO_DO_CABECALHO_EMBAIXO: Color = Color(0.08, 0.1, 0.18)
const REBITE: Color = Color(0.35, 0.4, 0.56)
const SOMBRA_DO_REBITE: Color = Color(0.16, 0.19, 0.31)
const FUNDO_DA_ABA: Color = Color(0.063, 0.078, 0.165)

var _tema: Theme = Theme.new()
var _faltou_importar: bool = false

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_DAS_TEXTURAS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAMINHO_DO_TEMA.get_base_dir()))
	_desenhar_texturas()
	_montar_tema()
	if _faltou_importar:
		print("As texturas foram desenhadas, mas ainda não foram importadas. Rode o --import e rode este script de novo.")
		quit(1)
		return
	var erro: Error = ResourceSaver.save(_tema, CAMINHO_DO_TEMA)
	if erro != OK:
		push_error("Não deu para salvar o Theme: %s" % error_string(erro))
		quit(1)
		return
	print("Theme salvo em %s" % CAMINHO_DO_TEMA)
	quit()

# Desenho das texturas

func _desenhar_texturas() -> void:
	_salvar(_painel(CORES[&"borda"], BORDA_INTERNA_NEUTRA), "painel_neutro")
	_salvar(_painel(CORES[&"ciano"], BORDA_INTERNA_CIANO), "painel_ciano")
	_salvar(_painel(CORES[&"magenta"], BORDA_INTERNA_MAGENTA), "painel_magenta")
	_salvar(_painel(CORES[&"ouro"], BORDA_INTERNA_OURO), "painel_ouro")
	_salvar(_cabecalho(), "painel_cabecalho")

	_salvar(_botao(CORES[&"borda"], FUNDO_DO_BOTAO, true, false), "botao_normal")
	_salvar(_botao(CORES[&"ciano"], FUNDO_DO_BOTAO_FOCADO, true, true), "botao_focado")
	_salvar(_botao(CORES[&"ciano"], BASE_ESCURA_DO_BOTAO, false, true), "botao_pressionado")
	_salvar(_botao(CORES[&"borda_escura"], FUNDO_DO_BOTAO, true, false), "botao_desligado")
	_salvar(_botao(CORES[&"magenta"], FUNDO_DO_BOTAO, true, false), "botao_destrutivo")
	_salvar(_botao(CORES[&"magenta"], FUNDO_DO_BOTAO_DESTRUTIVO_FOCADO, true, true), "botao_destrutivo_focado")
	_salvar(_botao(CORES[&"magenta"], BASE_ESCURA_DO_BOTAO, false, true), "botao_destrutivo_pressionado")
	_salvar(_anel_de_foco(CORES[&"ciano"], FUNDO_DO_BOTAO_FOCADO), "botao_anel_de_foco")
	_salvar(_anel_de_foco(CORES[&"magenta"], FUNDO_DO_BOTAO_DESTRUTIVO_FOCADO), "botao_destrutivo_anel_de_foco")

	_salvar(_aba(CORES[&"borda_escura"], FUNDO_DA_ABA), "aba")
	_salvar(_aba(CORES[&"ciano"], FUNDO_DA_ABA), "aba_sob_o_mouse")
	_salvar(_aba(CORES[&"ciano"], CORES[&"ciano"]), "aba_ativa")

	_salvar(_fundo_da_barra(), "barra_fundo")
	_salvar(_segmento_da_barra(), "barra_segmento")

	_salvar(_slot(CORES[&"borda"], FUNDO_DO_SLOT), "slot_normal")
	_salvar(_slot(CORES[&"ciano"], FUNDO_DO_SLOT), "slot_focado")
	_salvar(_slot(CORES[&"magenta"], FUNDO_DO_SLOT), "slot_segurando")
	_salvar(_slot(CORES[&"ouro"], FUNDO_DO_SLOT), "slot_na_mao")
	_salvar(_slot(CORES[&"lixeira"], FUNDO_DA_LIXEIRA), "slot_lixeira")
	_salvar(_slot_trancado(), "slot_trancado")

	_salvar(_tecla(CORES[&"texto"], SOMBRA_DA_TECLA), "tecla_na_tela")
	_salvar(_tecla(CORES[&"ciano"], SOMBRA_DA_TECLA_PRINCIPAL), "tecla_principal")

func _salvar(imagem: Image, nome: String) -> void:
	imagem.save_png(ProjectSettings.globalize_path(PASTA_DAS_TEXTURAS + nome + ".png"))

func _imagem_vazia(largura: int, altura: int) -> Image:
	var imagem: Image = Image.create_empty(largura, altura, false, Image.FORMAT_RGBA8)
	imagem.fill(Color(0, 0, 0, 0))
	return imagem

## Verdadeiro para o pixel que fica dentro da chapa. Com degrau maior que zero, cada
## canto perde dois degraus de pixel (o clip-path do .painel do mock).
func _dentro_da_chapa(x: int, y: int, largura: int, altura: int, degrau: int) -> bool:
	if x < 0 or y < 0 or x >= largura or y >= altura:
		return false
	if degrau <= 0:
		return true
	var dx: int = mini(x, largura - 1 - x)
	var dy: int = mini(y, altura - 1 - y)
	if dx < degrau and dy < degrau * 2:
		return false
	if dx < degrau * 2 and dy < degrau:
		return false
	return true

## Quantos pixels cada ponto da chapa está para dentro da beirada, contando em volta
## (vizinhos nas oito direções). É o que faz a borda seguir o degrau do canto.
func _profundidade(largura: int, altura: int, degrau: int) -> Array[PackedInt32Array]:
	var profundidade: Array[PackedInt32Array] = []
	for y in altura:
		var linha: PackedInt32Array = PackedInt32Array()
		linha.resize(largura)
		for x in largura:
			linha[x] = -1
		profundidade.append(linha)
	var restantes: Array[Vector2i] = []
	for y in altura:
		for x in largura:
			if _dentro_da_chapa(x, y, largura, altura, degrau):
				restantes.append(Vector2i(x, y))
	var camada: int = 0
	while not restantes.is_empty():
		var beirada: Array[Vector2i] = []
		var miolo: Array[Vector2i] = []
		for ponto in restantes:
			if _encosta_fora(ponto, profundidade, largura, altura, degrau):
				beirada.append(ponto)
			else:
				miolo.append(ponto)
		for ponto in beirada:
			profundidade[ponto.y][ponto.x] = camada
		restantes = miolo
		camada += 1
	return profundidade

func _encosta_fora(ponto: Vector2i, profundidade: Array[PackedInt32Array], largura: int, altura: int, degrau: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var x: int = ponto.x + dx
			var y: int = ponto.y + dy
			if not _dentro_da_chapa(x, y, largura, altura, degrau):
				return true
			if profundidade[y][x] != -1:
				return true
	return false

## Uma chapa com borda, borda de dentro e fundo, e a sombra preta embaixo. A sombra é a
## própria chapa deslocada para baixo, então ela também tem o canto em degrau.
func _chapa(largura: int, altura: int, degrau: int, cor_da_borda: Color, cor_de_dentro: Color, cor_do_fundo: Color, sombra: int) -> Image:
	var imagem: Image = _imagem_vazia(largura, altura + sombra)
	var profundidade: Array[PackedInt32Array] = _profundidade(largura, altura, degrau)
	if sombra > 0:
		for y in altura:
			for x in largura:
				if profundidade[y][x] >= 0:
					imagem.set_pixel(x, y + sombra, PRETO)
	for y in altura:
		for x in largura:
			var camada: int = profundidade[y][x]
			if camada < 0:
				continue
			if camada < BORDA:
				imagem.set_pixel(x, y, cor_da_borda)
			elif camada < BORDA * 2:
				imagem.set_pixel(x, y, cor_de_dentro)
			else:
				imagem.set_pixel(x, y, cor_do_fundo)
	return imagem

## Painel: 36 por 36 mais a sombra. As margens de 12 guardam o canto e as duas bordas;
## o miolo é uma cor só, então esticar não estraga.
func _painel(cor_da_borda: Color, cor_de_dentro: Color) -> Image:
	return _chapa(36, 36, BORDA, cor_da_borda, cor_de_dentro, CORES[&"fundo_painel"], SOMBRA)

## A faixa de cabeçalho: degradê do mock, linha de borda embaixo e um rebite em cada
## ponta. Os rebites ficam nos cantos de cima da textura, que não esticam.
func _cabecalho() -> Image:
	var largura: int = 48
	var altura: int = 32
	var imagem: Image = _imagem_vazia(largura, altura)
	for y in altura:
		var cor: Color = CORES[&"borda"]
		if y < altura - BORDA:
			var peso: float = clampf(float(y) / 18.0, 0.0, 1.0)
			cor = FUNDO_DO_CABECALHO_EM_CIMA.lerp(FUNDO_DO_CABECALHO_EMBAIXO, peso)
		for x in largura:
			imagem.set_pixel(x, y, cor)
	for esquerda: int in [8, largura - 8 - 6]:
		for y in range(11, 17):
			for x in range(esquerda, esquerda + 6):
				var na_sombra: bool = x >= esquerda + 4 or y >= 15
				imagem.set_pixel(x, y, SOMBRA_DO_REBITE if na_sombra else REBITE)
	return imagem

## Botão de chapa, de canto reto como no mock. Com sombra, tem também a base escura por
## dentro, embaixo; sem sombra é o botão afundado (pressionado). Com seta, ganha o "▶" do
## mock na frente, na cor da borda.
##
## A seta mora na textura, no canto de cima à esquerda, que não estica (margem de cima de
## 22 px, veja _montar_botoes). Ela não é o ícone do tema do botão porque o ícone do tema
## também pinta o ícone próprio de quem tem um (o botão de item da bancada): apagar a
## seta no estado normal apagaria esse ícone junto.
func _botao(cor_da_borda: Color, cor_do_fundo: Color, com_sombra: bool, com_seta: bool) -> Image:
	var imagem: Image = _chapa(LARGURA_DO_BOTAO, ALTURA_DO_BOTAO, 0, cor_da_borda, cor_do_fundo, cor_do_fundo, SOMBRA)
	if com_sombra:
		for y in range(ALTURA_DO_BOTAO - BORDA * 2, ALTURA_DO_BOTAO - BORDA):
			for x in range(BORDA, LARGURA_DO_BOTAO - BORDA):
				imagem.set_pixel(x, y, BASE_ESCURA_DO_BOTAO)
	else:
		for y in range(ALTURA_DO_BOTAO, ALTURA_DO_BOTAO + SOMBRA):
			for x in LARGURA_DO_BOTAO:
				imagem.set_pixel(x, y, Color(0, 0, 0, 0))
	if com_seta:
		_desenhar_seta(imagem, cor_da_borda)
	return imagem

## O que o foco do teclado ou do controle desenha por cima do botão: a borda acesa, o
## fundo aceso quase opaco e a seta. O Godot desenha o foco por cima do estado (normal,
## sob o mouse, pressionado), então ele não pode ter sombra nem deslocamento próprios.
func _anel_de_foco(cor_da_borda: Color, cor_do_fundo: Color) -> Image:
	var fundo_translucido: Color = Color(cor_do_fundo, 0.9)
	var imagem: Image = _chapa(LARGURA_DO_BOTAO, ALTURA_DO_BOTAO, 0, cor_da_borda, fundo_translucido, fundo_translucido, 0)
	_desenhar_seta(imagem, cor_da_borda)
	return imagem

## Triângulo de 5 por 10 px, centrado na altura de um botão de uma linha de texto.
func _desenhar_seta(imagem: Image, cor: Color) -> void:
	for y in 10:
		var largura_da_linha: int = mini(mini(y + 1, 10 - y), 5)
		for x in largura_da_linha:
			imagem.set_pixel(X_DA_SETA + x, Y_DA_SETA + y, cor)

## Aba: borda em cima e nos lados, aberta embaixo, para encostar no painel.
func _aba(cor_da_borda: Color, cor_do_fundo: Color) -> Image:
	var largura: int = 18
	var altura: int = 15
	var imagem: Image = _imagem_vazia(largura, altura)
	for y in altura:
		for x in largura:
			var na_borda: bool = y < BORDA or x < BORDA or x >= largura - BORDA
			imagem.set_pixel(x, y, cor_da_borda if na_borda else cor_do_fundo)
	return imagem

## Fundo da barra de bateria: contorno de 2 px na cor da borda, 3 px pretos e o fundo.
## As margens são 5 em volta; o miolo estica para a altura que a tela pedir.
func _fundo_da_barra() -> Image:
	var tamanho: int = 20
	var imagem: Image = _imagem_vazia(tamanho, tamanho)
	for y in tamanho:
		for x in tamanho:
			var beirada: int = mini(mini(x, y), mini(tamanho - 1 - x, tamanho - 1 - y))
			var cor: Color = FUNDO_DA_BARRA
			if beirada < 2:
				cor = CORES[&"borda"]
			elif beirada < 5:
				cor = PRETO
			imagem.set_pixel(x, y, cor)
	return imagem

## Um segmento da bateria: 8 px de carga e 2 px de vão, branco para o Theme pintar com a
## cor de cada barra. As margens de 5 são transparentes e casam com a borda do fundo; o
## miolo de 10 px se repete (tile) na largura da carga.
func _segmento_da_barra() -> Image:
	var imagem: Image = _imagem_vazia(20, 20)
	for y in range(5, 15):
		for x in range(5, 13):
			imagem.set_pixel(x, y, Color.WHITE)
	return imagem

func _slot(cor_da_borda: Color, cor_do_fundo: Color) -> Image:
	return _chapa(9, 9, 0, cor_da_borda, cor_do_fundo, cor_do_fundo, 0)

## Slot trancado: listras diagonais no miolo, que se repete (tile) e não estica.
func _slot_trancado() -> Image:
	var tamanho: int = BORDA + 8 + BORDA
	var imagem: Image = _imagem_vazia(tamanho, tamanho)
	for y in tamanho:
		for x in tamanho:
			var na_borda: bool = x < BORDA or y < BORDA or x >= tamanho - BORDA or y >= tamanho - BORDA
			if na_borda:
				imagem.set_pixel(x, y, CORES[&"borda_escura"])
				continue
			var listra: bool = posmod((x - BORDA) + (y - BORDA), 8) < 4
			imagem.set_pixel(x, y, LISTRA_DO_SLOT_TRANCADO if listra else FUNDO_DO_SLOT_TRANCADO)
	return imagem

## Tecla física clara com a sombra embaixo.
func _tecla(cor: Color, cor_da_sombra: Color) -> Image:
	var largura: int = 12
	var altura: int = 12
	var imagem: Image = _imagem_vazia(largura, altura + SOMBRA)
	for y in altura + SOMBRA:
		for x in largura:
			imagem.set_pixel(x, y, cor if y < altura else cor_da_sombra)
	return imagem

# Montagem do Theme

func _textura(nome: String) -> Texture2D:
	var caminho: String = PASTA_DAS_TEXTURAS + nome + ".png"
	if not ResourceLoader.exists(caminho):
		_faltou_importar = true
		return null
	return load(caminho) as Texture2D

## StyleBoxTexture de 9 fatias. As margens dizem quanto da beirada da textura não estica;
## a sombra fica fora do retângulo do controle (expand_margin_bottom), para não ocupar
## espaço no layout.
func _caixa(nome: String, margem: int, margem_de_baixo: int, conteudo: Vector4, sombra: int = 0) -> StyleBoxTexture:
	var caixa: StyleBoxTexture = StyleBoxTexture.new()
	caixa.texture = _textura(nome)
	caixa.texture_margin_left = margem
	caixa.texture_margin_top = margem
	caixa.texture_margin_right = margem
	caixa.texture_margin_bottom = margem_de_baixo
	caixa.expand_margin_bottom = sombra
	caixa.content_margin_left = conteudo.x
	caixa.content_margin_top = conteudo.y
	caixa.content_margin_right = conteudo.z
	caixa.content_margin_bottom = conteudo.w
	return caixa

func _montar_tema() -> void:
	var fonte_de_texto: FontFile = load(FONTE_DE_TEXTO) as FontFile
	var fonte_de_titulo: FontFile = load(FONTE_DE_TITULO) as FontFile
	var fonte_de_titulo_negrito: FontFile = load(FONTE_DE_TITULO_NEGRITO) as FontFile
	_tema.default_font = fonte_de_texto
	_tema.default_font_size = TAMANHO_DO_TEXTO

	for nome: StringName in CORES:
		_tema.set_color(nome, &"Cores", CORES[nome])

	_montar_textos(fonte_de_titulo, fonte_de_titulo_negrito)
	_montar_paineis()
	_montar_botoes()
	_montar_abas(fonte_de_titulo)
	_montar_barras()
	_montar_slots()
	_montar_teclas(fonte_de_titulo)
	_montar_campo_de_texto()

func _montar_textos(fonte_de_titulo: FontFile, fonte_de_titulo_negrito: FontFile) -> void:
	_tema.set_color(&"font_color", &"Label", CORES[&"texto"])
	_tema.set_color(&"default_color", &"RichTextLabel", CORES[&"texto"])

	_variacao_de_texto(&"Titulo", fonte_de_titulo, TAMANHO_DO_TITULO, CORES[&"texto"])
	_variacao_de_texto(&"TituloDoCabecalho", fonte_de_titulo, TAMANHO_DO_TITULO, CORES[&"ciano"])
	_variacao_de_texto(&"TituloGrande", fonte_de_titulo_negrito, TAMANHO_DO_TITULO_GRANDE, CORES[&"texto"])
	_variacao_de_texto(&"NumeroGrande", fonte_de_titulo_negrito, TAMANHO_DO_NUMERO_GRANDE, CORES[&"texto"])
	_tema.set_type_variation(&"TextoApagado", &"Label")
	_tema.set_color(&"font_color", &"TextoApagado", CORES[&"texto_apagado"])

	_tema.set_stylebox(&"panel", &"TooltipPanel", _caixa("painel_neutro", 12, 15, Vector4(10, 6, 10, 6), SOMBRA))
	_tema.set_color(&"font_color", &"TooltipLabel", CORES[&"texto"])

func _variacao_de_texto(nome: StringName, fonte: FontFile, tamanho: int, cor: Color) -> void:
	_tema.set_type_variation(nome, &"Label")
	_tema.set_font(&"font", nome, fonte)
	_tema.set_font_size(&"font_size", nome, tamanho)
	_tema.set_color(&"font_color", nome, cor)

func _montar_paineis() -> void:
	var conteudo: Vector4 = Vector4(14, 12, 14, 12)
	var neutro: StyleBoxTexture = _caixa("painel_neutro", 12, 15, conteudo, SOMBRA)
	_tema.set_stylebox(&"panel", &"PanelContainer", neutro)
	_tema.set_stylebox(&"panel", &"Panel", neutro)
	var variantes: Dictionary = {
		&"PainelNeutro": "painel_neutro",
		&"PainelCiano": "painel_ciano",
		&"PainelMagenta": "painel_magenta",
		&"PainelOuro": "painel_ouro",
	}
	for variacao: StringName in variantes:
		_tema.set_type_variation(variacao, &"PanelContainer")
		_tema.set_stylebox(&"panel", variacao, _caixa(variantes[variacao], 12, 15, conteudo, SOMBRA))

	_tema.set_type_variation(&"PainelCabecalho", &"PanelContainer")
	var cabecalho: StyleBoxTexture = _caixa("painel_cabecalho", 20, 4, Vector4(26, 4, 26, 7))
	_tema.set_stylebox(&"panel", &"PainelCabecalho", cabecalho)

func _montar_botoes() -> void:
	_tema.set_stylebox(&"normal", &"Button", _caixa_de_botao("botao_normal", true))
	_tema.set_stylebox(&"hover", &"Button", _caixa_de_botao("botao_focado", true))
	_tema.set_stylebox(&"pressed", &"Button", _caixa_de_botao("botao_pressionado", true))
	_tema.set_stylebox(&"hover_pressed", &"Button", _caixa_de_botao("botao_pressionado", true))
	_tema.set_stylebox(&"disabled", &"Button", _caixa_de_botao("botao_desligado", true))
	_tema.set_stylebox(&"focus", &"Button", _caixa_de_botao("botao_anel_de_foco", false))
	_cores_do_botao(&"Button", CORES[&"texto"], CORES[&"ciano"])
	_tema.set_constant(&"h_separation", &"Button", 8)

	_tema.set_type_variation(&"BotaoDestrutivo", &"Button")
	_tema.set_stylebox(&"normal", &"BotaoDestrutivo", _caixa_de_botao("botao_destrutivo", true))
	_tema.set_stylebox(&"hover", &"BotaoDestrutivo", _caixa_de_botao("botao_destrutivo_focado", true))
	_tema.set_stylebox(&"pressed", &"BotaoDestrutivo", _caixa_de_botao("botao_destrutivo_pressionado", true))
	_tema.set_stylebox(&"hover_pressed", &"BotaoDestrutivo", _caixa_de_botao("botao_destrutivo_pressionado", true))
	_tema.set_stylebox(&"focus", &"BotaoDestrutivo", _caixa_de_botao("botao_destrutivo_anel_de_foco", false))
	_cores_do_botao(&"BotaoDestrutivo", CORES[&"magenta"], CORES[&"magenta"])

## As margens guardam a borda, a seta (canto de cima à esquerda) e a sombra embaixo.
func _caixa_de_botao(nome: String, com_sombra: bool) -> StyleBoxTexture:
	var sombra: int = SOMBRA if com_sombra else 0
	var caixa: StyleBoxTexture = _caixa(nome, 6, 6 + sombra, Vector4(16, 4, 16, 4), sombra)
	caixa.texture_margin_left = MARGEM_ESQUERDA_DO_BOTAO
	caixa.texture_margin_top = MARGEM_DE_CIMA_DO_BOTAO
	return caixa

func _cores_do_botao(tipo: StringName, cor_normal: Color, cor_acesa: Color) -> void:
	_tema.set_color(&"font_color", tipo, cor_normal)
	_tema.set_color(&"font_hover_color", tipo, cor_acesa)
	_tema.set_color(&"font_focus_color", tipo, cor_acesa)
	_tema.set_color(&"font_pressed_color", tipo, cor_acesa)
	_tema.set_color(&"font_hover_pressed_color", tipo, cor_acesa)
	_tema.set_color(&"font_disabled_color", tipo, CORES[&"desligado"])

func _montar_abas(fonte_de_titulo: FontFile) -> void:
	var conteudo: Vector4 = Vector4(12, 6, 12, 4)
	for tipo: StringName in [&"TabBar", &"TabContainer"]:
		_tema.set_stylebox(&"tab_unselected", tipo, _caixa("aba", 6, 3, conteudo))
		_tema.set_stylebox(&"tab_hovered", tipo, _caixa("aba_sob_o_mouse", 6, 3, conteudo))
		_tema.set_stylebox(&"tab_selected", tipo, _caixa("aba_ativa", 6, 3, conteudo))
		_tema.set_stylebox(&"tab_disabled", tipo, _caixa("aba", 6, 3, conteudo))
		_tema.set_stylebox(&"tab_focus", tipo, StyleBoxEmpty.new())
		_tema.set_font(&"font", tipo, fonte_de_titulo)
		_tema.set_font_size(&"font_size", tipo, TAMANHO_DO_TITULO)
		_tema.set_color(&"font_unselected_color", tipo, CORES[&"texto_apagado"])
		_tema.set_color(&"font_hovered_color", tipo, CORES[&"ciano"])
		_tema.set_color(&"font_selected_color", tipo, CORES[&"noite"])
		_tema.set_color(&"font_disabled_color", tipo, CORES[&"desligado"])
		_tema.set_constant(&"h_separation", tipo, 4)
	_tema.set_stylebox(&"panel", &"TabContainer", _caixa("painel_neutro", 12, 15, Vector4(14, 12, 14, 12), SOMBRA))
	_tema.set_stylebox(&"tabbar_background", &"TabContainer", StyleBoxEmpty.new())

## As barras de bateria. O fundo é um só; a carga é o mesmo segmento branco, pintado com
## a cor de cada variation pelo modulate da StyleBoxTexture.
func _montar_barras() -> void:
	var fundo: StyleBoxTexture = _caixa("barra_fundo", 5, 5, Vector4(5, 5, 5, 5))
	_tema.set_stylebox(&"background", &"ProgressBar", fundo)
	_tema.set_stylebox(&"fill", &"ProgressBar", _carga(CORES[&"verde"]))
	_tema.set_color(&"font_color", &"ProgressBar", CORES[&"texto"])
	var variantes: Dictionary = {
		&"BarraVida": CORES[&"verde"],
		&"BarraStamina": CORES[&"ouro"],
		&"BarraExperiencia": CORES[&"ciano"],
		&"BarraChefe": CORES[&"ouro"],
		&"BarraChefeFase2": CORES[&"violeta"],
	}
	for variacao: StringName in variantes:
		_tema.set_type_variation(variacao, &"ProgressBar")
		_tema.set_stylebox(&"fill", variacao, _carga(variantes[variacao]))

func _carga(cor: Color) -> StyleBoxTexture:
	var carga: StyleBoxTexture = _caixa("barra_segmento", 5, 5, Vector4(5, 5, 5, 5))
	carga.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	carga.modulate_color = cor
	return carga

func _montar_slots() -> void:
	var variantes: Dictionary = {
		&"SlotNormal": "slot_normal",
		&"SlotFocado": "slot_focado",
		&"SlotSegurando": "slot_segurando",
		&"SlotNaMao": "slot_na_mao",
		&"SlotLixeira": "slot_lixeira",
	}
	for variacao: StringName in variantes:
		_tema.set_type_variation(variacao, &"Panel")
		_tema.set_stylebox(&"panel", variacao, _caixa(variantes[variacao], 3, 3, Vector4(3, 3, 3, 3)))
	_tema.set_type_variation(&"SlotTrancado", &"Panel")
	var trancado: StyleBoxTexture = _caixa("slot_trancado", 3, 3, Vector4(3, 3, 3, 3))
	trancado.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	trancado.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	_tema.set_stylebox(&"panel", &"SlotTrancado", trancado)

## Tecla na tela é uma variation de Label: o fundo de tecla vem do estilo "normal" do
## Label, então basta um Label com o nome da tecla.
func _montar_teclas(fonte_de_titulo: FontFile) -> void:
	var conteudo: Vector4 = Vector4(5, 2, 5, 0)
	for variacao: StringName in [&"TeclaNaTela", &"TeclaPrincipal"]:
		_tema.set_type_variation(variacao, &"Label")
		_tema.set_font(&"font", variacao, fonte_de_titulo)
		_tema.set_font_size(&"font_size", variacao, TAMANHO_DO_TITULO)
		_tema.set_color(&"font_color", variacao, CORES[&"noite"])
	_tema.set_stylebox(&"normal", &"TeclaNaTela", _caixa("tecla_na_tela", 2, 5, conteudo, SOMBRA))
	_tema.set_stylebox(&"normal", &"TeclaPrincipal", _caixa("tecla_principal", 2, 5, conteudo, SOMBRA))

func _montar_campo_de_texto() -> void:
	var conteudo: Vector4 = Vector4(8, 4, 8, 4)
	_tema.set_stylebox(&"normal", &"LineEdit", _caixa("slot_normal", 3, 3, conteudo))
	_tema.set_stylebox(&"focus", &"LineEdit", _caixa("slot_focado", 3, 3, conteudo))
	_tema.set_stylebox(&"read_only", &"LineEdit", _caixa("slot_normal", 3, 3, conteudo))
	_tema.set_color(&"font_color", &"LineEdit", CORES[&"texto"])
	_tema.set_color(&"font_placeholder_color", &"LineEdit", CORES[&"texto_apagado"])
	_tema.set_color(&"caret_color", &"LineEdit", CORES[&"ciano"])
	_tema.set_color(&"selection_color", &"LineEdit", Color(CORES[&"ciano"], 0.35))
