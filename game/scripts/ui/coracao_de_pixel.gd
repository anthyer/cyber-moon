class_name CoracaoDePixel
extends RefCounted

## O coração de pixel da interface (corações da amizade, aniversário no calendário). As
## fontes de pixel do jogo não têm o caractere de coração, então ele é desenhado aqui, a
## partir do desenho abaixo, uma vez só, em branco. Quem mostra pinta com o modulate
## (CoresDaInterface.rosa() cheio, borda_escura() vazio).

## Cada texto é uma linha do desenho; "#" é pixel aceso.
const DESENHO: Array[String] = [
	".##.##.",
	"#######",
	"#######",
	".#####.",
	"..###..",
	"...#...",
]
## Cada pixel do desenho vira um quadrado deste tamanho na tela.
const ESCALA: int = 2

static var _textura: Texture2D

static func textura() -> Texture2D:
	if _textura != null:
		return _textura
	var largura: int = DESENHO[0].length()
	var imagem: Image = Image.create_empty(largura, DESENHO.size(), false, Image.FORMAT_RGBA8)
	for y in DESENHO.size():
		for x in largura:
			if DESENHO[y][x] == "#":
				imagem.set_pixel(x, y, Color.WHITE)
	_textura = ImageTexture.create_from_image(imagem)
	return _textura

## Um coração pronto para pôr num container, já na cor pedida.
static func novo(cor: Color) -> TextureRect:
	var coracao: TextureRect = TextureRect.new()
	coracao.texture = textura()
	coracao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coracao.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coracao.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coracao.custom_minimum_size = Vector2(DESENHO[0].length() * ESCALA, DESENHO.size() * ESCALA)
	coracao.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coracao.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coracao.modulate = cor
	return coracao
