"""Os protagonistas que o jogador escolhe antes do jogo novo (plano 39).

Pacote `cyber_moon_personagens`, o mesmo dos moradores. Cada protagonista parte de um
modelo do pacote de personagens da Kenney, como os moradores (`personagens.py`), mas com o
cuidado de herói: a mochila de campo nas costas (`kit.mochila_de_campo`), o verde-broto
aceso (`kit.COR_DO_JOGADOR`, a cor que nenhum morador usa), uma peça grande na cabeça que
muda o contorno e a roupa de trabalho com o contraste mais forte da paleta. A escala é a
mesma dos moradores e as peças ficam só nos ossos `head` e `torso`.

No jogo não há palavra de gênero: os protagonistas são do corpo "tipo 1" ou "tipo 2". O
nome da base da Kenney só aparece aqui, no script: tipo 1 sai das bases `male_*`, tipo 2
das bases `female_*`.

Rodar no Blender, ou sem janela:
    flatpak run org.blender.Blender -b --python <repositorio>/equipe/ferramentas/blender/modelos/protagonistas.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit

# A base da Kenney de cada tipo de corpo. Fica só aqui: o resto do projeto fala em tipo.
BASE_DO_TIPO_1 = "male"
BASE_DO_TIPO_2 = "female"


# Medidas da cabeça e do tronco em repouso, iguais nos doze modelos (ver kit.Personagem).
FRENTE_DO_ROSTO = -0.16
ALTURA_DOS_OLHOS = 0.485
ALTURA_DA_TESTA = 0.57
ALTURA_DA_CINTURA = 0.18


# -- regiões do corpo, para separar partes que a Kenney pinta com a mesma cor ----------------

def abaixo_da_cintura(centro):
    """Calça e sapato."""
    return centro.z < ALTURA_DA_CINTURA


def acima_da_cintura(centro):
    """Camisa, jaqueta e colete."""
    return centro.z >= ALTURA_DA_CINTURA


def nos_pes(centro):
    """Só o sapato."""
    return centro.z < 0.05


def cabelo_comprido_nas_costas(centro):
    """A ponta do cabelo que desce pelas costas e bateria na mochila."""
    return centro.z < 0.45 and centro.y > 0.1


# -- peças --------------------------------------------------------------------------------

def chapeu_de_palha(cor_da_faixa=kit.COR_DO_JOGADOR):
    """Chapéu de palha de aba larga, com a faixa de LED em volta da copa.

    A aba passa da largura dos ombros: de cima, que é como a câmera vê, o contorno vira um
    disco claro que nenhum morador tem. A aba fica acima da mochila para não esconder a
    luz de status.
    """
    m = kit.Modelo("chapeu_de_palha")
    # Inclinado para trás, para a câmera do jogo, que fica alta, ainda ver o rosto.
    inclinacao = (-18, 0, 0)
    m.cilindro(0.36, 0.03, pos=(0, -0.02, 0.6), cor="areia", lados=12, raio_do_topo=0.33, rot=inclinacao)
    m.cilindro(0.29, 0.15, pos=(0, -0.02, 0.61), cor="areia", lados=10, raio_do_topo=0.24,
               cor_das_tampas="areia", rot=inclinacao)
    m.cilindro(0.285, 0.04, pos=(0, -0.02, 0.625), cor=cor_da_faixa, lados=10, raio_do_topo=0.275,
               brilho=True, rot=inclinacao)
    return m


def oculos_de_solda(cor_das_lentes=kit.COR_DO_JOGADOR):
    """Óculos de solda puxados para a testa: dois copos grandes de cromo, virados para a
    frente e para cima, com as lentes acesas. Maiores que os óculos de moto dos moradores,
    para aparecerem de longe."""
    m = kit.Modelo("oculos_de_solda")
    m.caixa((0.42, 0.38, 0.05), pos=(0, -0.01, ALTURA_DA_TESTA), cor="couro")
    # Inclinados 25 graus para cima: na testa, e não na frente dos olhos.
    inclinacao = (65, 0, 0)
    for x in (-0.09, 0.09):
        m.cilindro(0.075, 0.06, pos=(x, FRENTE_DO_ROSTO - 0.02, ALTURA_DA_TESTA + 0.02), rot=inclinacao,
                   cor="cromo", lados=8, cor_das_tampas="grafite")
        m.cilindro(0.055, 0.015, pos=(x, FRENTE_DO_ROSTO - 0.075, ALTURA_DA_TESTA + 0.045), rot=inclinacao,
                   cor=cor_das_lentes, lados=8, brilho=True)
    m.caixa((0.06, 0.03, 0.03), pos=(0, FRENTE_DO_ROSTO - 0.05, ALTURA_DA_TESTA + 0.04), cor="grafite")
    return m


def gola_alta(cor, cor_de_dentro="couro"):
    """Gola alta de jaqueta de trabalho, em pé em volta do pescoço e aberta na frente.

    A gola fica por fora da cabeça (que é mais larga que o tronco), e por isso a cabeça
    parece encaixada nela: de trás e de cima, é um colarinho claro em volta do cabelo.
    """
    m = kit.Modelo("gola_alta")
    # A parte de trás, entre a nuca e a mochila.
    m.caixa((0.48, 0.04, 0.16), pos=(0, 0.18, 0.3), cor=cor, rot=(-10, 0, 0), chanfro=0.01)
    # Os lados em rampa: altos atrás, junto da nuca, e baixos na frente, onde a gola abre.
    # O contorno é desenhado de lado (x do desenho vira o y do personagem com o giro de 90).
    contorno_do_lado = [(-0.16, 0.0), (0.2, 0.0), (0.2, 0.16), (-0.16, 0.05)]
    for lado in (-1, 1):
        m.prisma(contorno_do_lado, 0.04, pos=(lado * 0.235, 0.0, 0.3), rot=(0, 0, 90), cor=cor)
    # O forro escuro aparecendo na abertura da frente.
    for lado in (-1, 1):
        m.caixa((0.09, 0.03, 0.05), pos=(lado * 0.17, -0.15, 0.3), cor=cor_de_dentro)
    return m


def capuz(cor, cor_de_dentro="preto"):
    """Capuz largo de lona, cobrindo a cabeça inteira menos o rosto.

    O capuz começa logo atrás da frente do rosto, e o rosto fica para fora dele, com a
    borda escura em volta. Atrás, ele para acima da luz da mochila, para a câmera do jogo
    continuar vendo a luz.
    """
    m = kit.Modelo("capuz")
    m.caixa((0.52, 0.33, 0.35), pos=(0, 0.025, 0.43), cor=cor, chanfro=0.1)
    # O pano que desce até os ombros, só dos lados e na frente da nuca.
    m.caixa((0.52, 0.26, 0.11), pos=(0, -0.01, 0.34), cor=cor, chanfro=0.03)
    # A borda em volta do rosto.
    m.caixa((0.46, 0.03, 0.05), pos=(0, FRENTE_DO_ROSTO - 0.005, 0.66), cor=cor_de_dentro)
    for x in (-0.215, 0.215):
        m.caixa((0.04, 0.03, 0.27), pos=(x, FRENTE_DO_ROSTO - 0.005, 0.39), cor=cor_de_dentro)
    return m


def fone_de_antena(cor=kit.COR_DO_JOGADOR):
    """Fone grande debaixo do capuz, com uma antena saindo de um lado.

    O arco fica escondido no capuz; só os dois copos aparecem, saindo pelos lados com o
    anel aceso. A antena atravessa o capuz e sobe acima da cabeça: é o traço que muda o
    contorno.
    """
    m = kit.Modelo("fone_de_antena")
    altura_dos_copos = 0.47
    for lado in (-1, 1):
        m.cilindro(0.085, 0.07, pos=(lado * 0.235, 0.02, altura_dos_copos), rot=(0, lado * 90, 0), cor="grafite", lados=8)
        m.cilindro(0.06, 0.015, pos=(lado * 0.305, 0.02, altura_dos_copos), rot=(0, lado * 90, 0), cor=cor,
                   lados=8, brilho=True)
    # A antena, no copo da direita, inclinada para fora, com a ponta acesa.
    m.cilindro(0.014, 0.4, pos=(0.27, 0.05, altura_dos_copos + 0.06), rot=(0, 12, 0), cor="cromo", lados=6)
    m.esfera(0.032, pos=(0.353, 0.05, altura_dos_copos + 0.45), cor=cor, brilho=True)
    return m


def bone_virado(cor, cor_da_costura=kit.COR_DO_JOGADOR):
    """Boné de aba reta virado para trás, com a costura do topo acesa.

    A costura cruza o topo de frente para trás e de lado a lado: é o que a câmera do jogo,
    alta e atrás, mais vê. O coque do cabelo sai pela abertura de trás.
    """
    m = kit.Modelo("bone_virado")
    m.caixa((0.47, 0.43, 0.12), pos=(0, -0.025, 0.6), cor=cor, chanfro=0.03)
    m.caixa((0.36, 0.17, 0.025), pos=(0, 0.27, 0.6), cor=cor)
    m.caixa((0.025, 0.44, 0.012), pos=(0, -0.025, 0.72), cor=cor_da_costura, brilho=True)
    m.caixa((0.48, 0.025, 0.012), pos=(0, -0.025, 0.72), cor=cor_da_costura, brilho=True)
    m.caixa((0.34, 0.02, 0.012), pos=(0, 0.35, 0.625), cor=cor_da_costura, brilho=True)
    m.cilindro(0.03, 0.02, pos=(0, -0.025, 0.725), cor=cor, lados=6)
    return m


def lenco_longo(cor):
    """Lenço comprido amarrado no pescoço, com as duas pontas caindo nas costas e abertas
    para o lado, como se o vento batesse. As pontas ficam do lado do tanque, fora da
    bateria e da luz da mochila."""
    m = kit.Modelo("lenco_longo")
    m.caixa((0.3, 0.27, 0.07), pos=(0, 0.01, 0.3), cor=cor, chanfro=0.025)
    m.caixa((0.08, 0.07, 0.07), pos=(-0.12, 0.15, 0.29), cor=cor, chanfro=0.015)
    m.caixa((0.075, 0.025, 0.32), pos=(-0.255, 0.185, 0.03), cor=cor, rot=(0, 25, 0))
    m.caixa((0.065, 0.025, 0.27), pos=(-0.3, 0.215, 0.09), cor=cor, rot=(0, 42, 0))
    return m


def visor_de_uma_peca(cor=kit.COR_DO_JOGADOR):
    """Visor largo de uma peça só, aceso, passando dos lados da cabeça.

    Mais largo e mais alto que o visor de qualquer morador, com a armação escura em
    volta, para ler como uma faixa de luz na frente do rosto.
    """
    m = kit.Modelo("visor_de_uma_peca")
    base = ALTURA_DOS_OLHOS - 0.05
    m.caixa((0.47, 0.04, 0.1), pos=(0, FRENTE_DO_ROSTO - 0.03, base), cor=cor, brilho=True)
    m.caixa((0.5, 0.05, 0.025), pos=(0, FRENTE_DO_ROSTO - 0.03, base + 0.1), cor="grafite")
    m.caixa((0.5, 0.05, 0.02), pos=(0, FRENTE_DO_ROSTO - 0.03, base - 0.02), cor="grafite")
    for x in (-0.24, 0.24):
        m.caixa((0.05, 0.22, 0.09), pos=(x, -0.07, base + 0.005), cor="grafite", chanfro=0.01)
    m.caixa((0.44, 0.04, 0.05), pos=(0, 0.165, base + 0.02), cor="grafite")
    return m


def rabo_de_cabelo_alto(cor, cor_do_prendedor="couro"):
    """Rabo de cabelo preso no alto da cabeça, saindo para trás e para cima.

    Termina acima da mochila. De trás, é o contorno que sobe da cabeça.
    """
    m = kit.Modelo("rabo_de_cabelo_alto")
    m.caixa((0.11, 0.11, 0.06), pos=(0, 0.12, 0.66), cor=cor, chanfro=0.02)
    m.cilindro(0.05, 0.05, pos=(0, 0.14, 0.7), rot=(-40, 0, 0), cor=cor_do_prendedor, lados=8)
    m.caixa((0.11, 0.08, 0.25), pos=(0, 0.33, 0.55), rot=(45, 0, 0), cor=cor, chanfro=0.025)
    m.caixa((0.08, 0.07, 0.12), pos=(0, 0.36, 0.46), rot=(15, 0, 0), cor=cor, chanfro=0.02)
    return m


def ombreira_de_sucata(cor_do_detalhe=kit.COR_DO_JOGADOR):
    """Ombreira grande num ombro só, feita de chapas de sucata, com a correia cruzando o
    peito e uma tira acesa na borda.

    Num ombro só, o contorno fica torto: de longe, é a única figura que não é simétrica.
    """
    m = kit.Modelo("ombreira_de_sucata")
    x = 0.25
    m.caixa((0.27, 0.32, 0.06), pos=(x, 0.0, 0.34), rot=(0, 18, 0), cor="ferrugem", chanfro=0.015)
    m.caixa((0.22, 0.27, 0.05), pos=(x + 0.005, 0.0, 0.39), rot=(0, 18, 0), cor="cromo", chanfro=0.012)
    m.caixa((0.15, 0.2, 0.045), pos=(x, 0.0, 0.43), rot=(0, 18, 0), cor="ferrugem", chanfro=0.01)
    # A tira acesa na borda de fora e a da frente, que aparece de frente para a câmera.
    m.caixa((0.035, 0.3, 0.035), pos=(x + 0.13, 0.0, 0.3), rot=(0, 18, 0), cor=cor_do_detalhe, brilho=True)
    m.caixa((0.2, 0.02, 0.03), pos=(x + 0.01, -0.14, 0.385), rot=(0, 18, 0), cor=cor_do_detalhe, brilho=True)
    # As pontas de chapa para cima, que fazem o contorno.
    m.prisma([(-0.045, 0.0), (0.045, 0.0), (0.0, 0.13)], 0.03, pos=(x - 0.02, -0.07, 0.45), rot=(0, 18, 0), cor="cromo")
    m.prisma([(-0.04, 0.0), (0.04, 0.0), (0.0, 0.1)], 0.03, pos=(x - 0.02, 0.07, 0.45), rot=(0, 18, 0), cor="cromo")
    # A correia que segura a ombreira, cruzando o peito na diagonal.
    m.caixa((0.035, 0.02, 0.26), pos=(0.0, -0.118, 0.17), rot=(0, 40, 0), cor="couro")
    return m


def bandana(cor):
    """Bandana amarrada na cabeça, com o nó e as duas pontas atrás."""
    m = kit.Modelo("bandana")
    m.caixa((0.44, 0.43, 0.06), pos=(0, -0.01, 0.625), cor=cor, chanfro=0.025)
    m.caixa((0.43, 0.04, 0.06), pos=(0, -0.215, 0.6), cor=cor)
    m.caixa((0.08, 0.05, 0.06), pos=(0, 0.205, 0.6), cor=cor, chanfro=0.01)
    m.caixa((0.05, 0.02, 0.13), pos=(-0.03, 0.235, 0.48), rot=(0, -15, 0), cor=cor)
    m.caixa((0.05, 0.02, 0.11), pos=(0.03, 0.235, 0.5), rot=(0, 20, 0), cor=cor)
    return m


# -- os protagonistas ----------------------------------------------------------------------

def protagonista_1a():
    """Palha: chapéu de palha de aba larga com a faixa acesa, camisa jeans, calça de lona
    clara, luva e bota escuras. A roupa de quem trabalha na terra, no contraste mais forte.

    A base é a mesma do Hélio, então sai o que é dele: os óculos (apagados) e o cabelo
    castanho (agora preto)."""
    p = kit.Personagem("protagonista_1a", BASE_DO_TIPO_1 + "_e")
    p.apagar_cor(["cinza_lilas", "branco"], parte="cabeca")
    p.trocar_cor("pele_escura", "preto", parte="cabeca")
    p.trocar_cor("amarelo", "areia", parte="corpo")
    p.trocar_cor("branco", "jeans", parte="corpo")
    p.trocar_cor("grafite", "preto", parte="corpo")
    p.trocar_cor("cinza", "couro", parte="corpo")
    p.peca("head", chapeu_de_palha())
    p.peca("torso", kit.mochila_de_campo())
    return p


def protagonista_1b():
    """Solda: óculos de solda na testa com as lentes acesas, jaqueta de lona cor de
    ferrugem com a gola alta clara em pé, calça jeans e bota preta.

    A base é a mesma do Kenji, então sai o que é dele: o quepe (apagado) e a farda azul.
    O cabelo e o bigode ruivos ficam pretos."""
    p = kit.Personagem("protagonista_1b", BASE_DO_TIPO_1 + "_c")
    p.apagar_cor(["azul", "amarelo"], parte="cabeca")
    p.trocar_cor("pele_media", "preto", parte="cabeca")
    p.trocar_cor("azul", "ferrugem", parte="corpo")
    p.trocar_cor("amarelo", "cromo", parte="corpo")
    p.trocar_cor("grafite", "jeans", parte="corpo", onde=abaixo_da_cintura)
    p.trocar_cor("grafite", "preto", parte="corpo", onde=acima_da_cintura)
    p.trocar_cor("cinza", "preto", parte="corpo")
    p.peca("head", oculos_de_solda())
    p.peca("torso", gola_alta("creme"))
    p.peca("torso", kit.mochila_de_campo())
    return p


def protagonista_1c():
    """Capuz: capuz largo de lona oliva por cima de um fone de antena aceso, jaqueta da
    mesma lona, camiseta preta, calça preta e bota de couro.

    A base é a mesma do Rafa, que usa jaqueta de couro e capacete laranja: aqui o terno
    vira lona oliva, a gravata some na camiseta e o cabelo ruivo fica castanho."""
    p = kit.Personagem("protagonista_1c", BASE_DO_TIPO_1 + "_d")
    p.trocar_cor("pele_media", "couro", parte="cabeca")
    p.trocar_cor("grafite", "couro", parte="corpo", onde=nos_pes)
    p.trocar_cor("grafite", "preto", parte="corpo", onde=abaixo_da_cintura)
    p.trocar_cor("grafite", "oliva", parte="corpo", onde=acima_da_cintura)
    p.trocar_cor("branco", "preto", parte="corpo")
    p.trocar_cor("vermelho", "preto", parte="corpo")
    p.peca("head", capuz("oliva"))
    p.peca("head", fone_de_antena())
    p.peca("torso", kit.mochila_de_campo())
    return p


def protagonista_2a():
    """Lenço: lenço amarelo comprido com as pontas soltas nas costas, boné preto virado
    com a costura acesa, jaqueta verde militar, calça de lona clara e bota de couro.

    A base é a mesma da Lúcia, que usa terninho cinza e tem o cabelo ruivo: o terno vira
    roupa de trabalho, o cabelo fica castanho e os brincos saem."""
    p = kit.Personagem("protagonista_2a", BASE_DO_TIPO_2 + "_d")
    p.apagar_cor(["branco"], parte="cabeca")
    p.trocar_cor("pele_media", "couro", parte="cabeca")
    p.trocar_cor("cinza", "verde_militar", parte="corpo", onde=acima_da_cintura)
    p.trocar_cor("cinza", "areia", parte="corpo", onde=abaixo_da_cintura)
    p.trocar_cor("branco", "creme", parte="corpo")
    p.trocar_cor("grafite", "couro", parte="corpo")
    p.peca("head", bone_virado("preto"))
    p.peca("torso", lenco_longo("amarelo"))
    p.peca("torso", kit.mochila_de_campo())
    return p


def protagonista_2b():
    """Visor: visor largo aceso e rabo de cabelo loiro preso no alto, jaqueta jeans,
    luva de couro, calça e bota pretas.

    A base é a mesma da motoqueira de jaqueta preta, que tem o cabelo preto solto e os
    óculos de moto: aqui o cabelo fica loiro, a ponta comprida que descia pelas costas
    sai (bateria na mochila) e vira o rabo preso no alto."""
    p = kit.Personagem("protagonista_2b", BASE_DO_TIPO_2 + "_e")
    p.apagar_cor(["grafite"], parte="cabeca", onde=cabelo_comprido_nas_costas)
    p.trocar_cor("grafite", "areia", parte="cabeca")
    p.trocar_cor("branco", "preto", parte="corpo", onde=nos_pes)
    p.trocar_cor("branco", "jeans", parte="corpo")
    p.trocar_cor("cinza_lilas", "cromo", parte="corpo")
    p.trocar_cor("azul", "couro", parte="corpo")
    p.trocar_cor("grafite", "preto", parte="corpo")
    p.peca("head", visor_de_uma_peca())
    p.peca("head", rabo_de_cabelo_alto("areia"))
    p.peca("torso", kit.mochila_de_campo())
    return p


def protagonista_2c():
    """Ombreira: ombreira de sucata num ombro só com a tira acesa, bandana cor de
    terracota, camiseta creme, colete e correia de couro, calça jeans.

    A base é a mesma da Dandara, que usa couro preto, cabelo vinho e ombreira nos dois
    ombros: aqui o cabelo fica castanho, a roupa clara e a ombreira é uma só, de chapa."""
    p = kit.Personagem("protagonista_2c", BASE_DO_TIPO_2 + "_f")
    p.trocar_cor("grafite", "creme", parte="corpo")
    p.trocar_cor("amarelo", "couro", parte="corpo")
    p.trocar_cor("cinza_lilas", "couro", parte="corpo")
    p.trocar_cor("azul", "jeans", parte="corpo")
    p.trocar_cor("roxo", "preto", parte="corpo")
    p.trocar_cor("cinza", "preto", parte="corpo")
    p.trocar_cor("pele_media", "pele_escura", parte="cabeca")
    p.peca("head", bandana("terracota"))
    p.peca("torso", ombreira_de_sucata())
    p.peca("torso", kit.mochila_de_campo())
    return p


PROTAGONISTAS = [protagonista_1a, protagonista_1b, protagonista_1c, protagonista_2a, protagonista_2b, protagonista_2c]

if __name__ == "__main__":
    kit.usar_paleta_de_personagens()
    kit.produzir_personagens(PROTAGONISTAS, "protagonistas")
