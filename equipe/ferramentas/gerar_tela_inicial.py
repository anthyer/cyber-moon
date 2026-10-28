#!/usr/bin/env python3
"""Desenha as pixel arts da tela inicial da demo: o céu, a cidade em camadas, a via
elevada, os carros voadores e o título.

A tela é pensada em 384x216 pixels e o jogo amplia 3 vezes (1152x648, o tamanho base da
janela). Cada camada da cidade e a via repetem na horizontal sem emenda, porque o menu
as faz rolar em velocidades diferentes (o efeito de parallax, como a tela de título do
Stardew Valley, com a cidade no lugar das montanhas).

Os desenhos saem de números sorteados com semente fixa: rodar de novo dá as mesmas
imagens. Para mudar a cara de uma camada, mude a semente ou os parâmetros dela aqui.

Uso, a partir da raiz do repositório:

    ./equipe/ferramentas/gerar_tela_inicial.py

Grava em game/assets/textures/tela_inicial/.
"""

import math
import random
from pathlib import Path

from PIL import Image

LARGURA = 384
ALTURA = 216
PASTA = Path(__file__).resolve().parents[2] / "game" / "assets" / "textures" / "tela_inicial"


def cor(hexa: str, alfa: int = 255) -> tuple:
    hexa = hexa.lstrip("#")
    return (int(hexa[0:2], 16), int(hexa[2:4], 16), int(hexa[4:6], 16), alfa)


def misturar(a: tuple, b: tuple, t: float) -> tuple:
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(4))


# Paleta. Noite roxa, com o neon do jogo (o ciano, o magenta e o amarelo da interface).
CEU_ALTO = cor("0a0720")
CEU_MEIO = cor("1d1240")
CEU_HORIZONTE = cor("5a2266")
BRILHO_DO_HORIZONTE = cor("9a3a78")
CIANO = cor("4ff0ff")
MAGENTA = cor("ff4fd8")
AMARELO = cor("ffd86b")
BRANCO = cor("f4f0ff")
CONTORNO = cor("120a26")
TRANSPARENTE = (0, 0, 0, 0)


class Tela:
    """Uma imagem que dá a volta na horizontal: x fora da largura cai do outro lado."""

    def __init__(self, largura: int, altura: int, repete: bool = True):
        self.imagem = Image.new("RGBA", (largura, altura), TRANSPARENTE)
        self.largura = largura
        self.altura = altura
        self.repete = repete

    def pintar(self, x: int, y: int, c: tuple) -> None:
        if self.repete:
            x %= self.largura
        if 0 <= x < self.largura and 0 <= y < self.altura:
            self.imagem.putpixel((x, y), c)

    def ler(self, x: int, y: int) -> tuple:
        if self.repete:
            x %= self.largura
        if 0 <= x < self.largura and 0 <= y < self.altura:
            return self.imagem.getpixel((x, y))
        return TRANSPARENTE

    def retangulo(self, x: int, y: int, l: int, a: int, c: tuple) -> None:
        for yy in range(y, y + a):
            for xx in range(x, x + l):
                self.pintar(xx, yy, c)

    def salvar(self, nome: str) -> None:
        PASTA.mkdir(parents=True, exist_ok=True)
        self.imagem.save(PASTA / nome)
        print("gravado", nome, self.imagem.size)


# Céu e lua

def cor_do_ceu(t: float) -> tuple:
    """A cor do céu na altura t (0 no alto, 1 no pé da tela)."""
    if t < 0.5:
        alvo = misturar(CEU_ALTO, CEU_MEIO, t / 0.5)
    else:
        alvo = misturar(CEU_MEIO, CEU_HORIZONTE, (t - 0.5) / 0.5)
    if t > 0.72:
        alvo = misturar(alvo, BRILHO_DO_HORIZONTE, min((t - 0.72) / 0.2, 1.0) * 0.6)
    return alvo


def desenhar_ceu() -> None:
    """O céu não rola: degradê, estrelas e um brilho rosado no horizonte. O degradê é em
    faixas de cor chapada, com pontilhado na troca de uma faixa para a outra, como pixel
    art de verdade, e não liso."""
    tela = Tela(LARGURA, ALTURA, repete=False)
    sorteio = random.Random(7)
    faixas = 18
    for y in range(ALTURA):
        posicao = y / (ALTURA - 1) * faixas
        faixa = math.floor(posicao)
        resto = posicao - faixa
        for x in range(LARGURA):
            # Pontilhado ordenado 2x2: no fim da faixa, parte dos pixels já usa a cor
            # da faixa seguinte, e a parte cresce até a troca.
            limiar = [[0.2, 0.6], [0.8, 0.4]][y % 2][x % 2]
            indice = faixa + 1 if resto > limiar + 0.15 else faixa
            tela.pintar(x, y, cor_do_ceu(min(indice / faixas, 1.0)))
    # O degradê acima dá a cor; agora as estrelas, mais densas no alto.
    for _ in range(170):
        x = sorteio.randrange(LARGURA)
        y = int(sorteio.random() ** 1.6 * 130)
        brilho = sorteio.random()
        if brilho > 0.93:
            for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
                tela.pintar(x + dx, y + dy, BRANCO if (dx, dy) == (0, 0) else cor("a8a0ff", 200))
        elif brilho > 0.6:
            tela.pintar(x, y, cor("d8d4ff"))
        else:
            tela.pintar(x, y, cor("7a70c0"))
    tela.salvar("ceu.png")


def desenhar_lua() -> None:
    """A lua do título: grande, com crateras e linhas de circuito em ciano, e um halo."""
    tamanho = 64
    tela = Tela(tamanho, tamanho, repete=False)
    centro = tamanho / 2 - 0.5
    raio = 21
    sorteio = random.Random(3)
    crateras = [(-6, -5, 4), (7, 6, 5), (-9, 9, 3), (5, -10, 3), (11, -3, 2), (-2, 2, 2)]
    for y in range(tamanho):
        for x in range(tamanho):
            dx, dy = x - centro, y - centro
            d = math.hypot(dx, dy)
            if d <= raio:
                # Luz vindo de cima e da direita: o lado de baixo e da esquerda é sombra.
                luz = (dx * 0.5 - dy * 0.6) / raio
                base = cor("eae6ff") if luz > -0.15 else cor("c4bcec") if luz > -0.55 else cor("9a90d0")
                if d > raio - 1:
                    base = cor("8a80c8")
                for cx, cy, cr in crateras:
                    dc = math.hypot(dx - cx, dy - cy)
                    if dc <= cr:
                        base = misturar(base, cor("8a80c8"), 0.55 if dc > cr - 1 else 0.35)
                tela.pintar(x, y, base)
            elif d <= raio + 2.5:
                tela.pintar(x, y, cor("ff4fd8", 70 if d > raio + 1.5 else 120))
            elif d <= raio + 6:
                tela.pintar(x, y, cor("ff4fd8", 28))
    # Circuitos: trilhas que andam em ângulo reto e terminam numa bolinha.
    for inicio in ((-14, 2), (2, 12), (8, -14), (-4, -15), (12, 4), (-10, -8)):
        x, y = inicio
        direcao = sorteio.choice(((1, 0), (0, 1), (-1, 0), (0, -1)))
        for passo in range(sorteio.randint(10, 18)):
            px, py = int(centro + x), int(centro + y)
            if math.hypot(x, y) > raio - 2:
                break
            tela.pintar(px, py, CIANO)
            if passo % 5 == 4:
                direcao = sorteio.choice(((1, 0), (0, 1), (-1, 0), (0, -1)))
            x += direcao[0]
            y += direcao[1]
        tela.pintar(int(centro + x), int(centro + y), BRANCO)
    tela.salvar("lua.png")


def desenhar_nevoa() -> None:
    """Faixas finas de névoa roxa, pontilhadas, que passam devagar na frente da lua."""
    tela = Tela(LARGURA, 90)
    sorteio = random.Random(11)
    for _ in range(9):
        y0 = sorteio.randrange(5, 80)
        x0 = sorteio.randrange(LARGURA)
        comprimento = sorteio.randrange(60, 160)
        espessura = sorteio.randrange(2, 5)
        for x in range(comprimento):
            borda = min(x, comprimento - x) / 20
            for y in range(espessura):
                if (x + y) % 2 == 0 or borda > 1 and y not in (0, espessura - 1):
                    tela.pintar(x0 + x, y0 + y, cor("6a3a8a", 90 if borda > 1 else 50))
    tela.salvar("nevoa.png")


# Cidade

def predio(tela: Tela, x: int, largura: int, topo: int, base: int, corpo: tuple, borda: tuple,
           janelas: list, chance_acesa: float, passo_x: int, passo_y: int, sorteio: random.Random,
           neon: bool = False) -> None:
    """Um prédio: corpo, quina iluminada, janelas em grade, e às vezes um telhado
    escalonado, uma antena e um letreiro neon vertical."""
    tela.retangulo(x, topo, largura, base - topo, corpo)
    tela.retangulo(x, topo, 1, base - topo, borda)
    tela.retangulo(x, topo, largura, 1, borda)
    if sorteio.random() < 0.45 and largura > 8:
        recuo = sorteio.randint(2, max(2, largura // 4))
        altura_extra = sorteio.randint(3, 8)
        tela.retangulo(x + recuo, topo - altura_extra, largura - 2 * recuo, altura_extra, corpo)
        tela.retangulo(x + recuo, topo - altura_extra, largura - 2 * recuo, 1, borda)
        topo -= altura_extra
    if sorteio.random() < 0.5:
        ax = x + sorteio.randint(2, max(2, largura - 3))
        altura_da_antena = sorteio.randint(4, 12)
        tela.retangulo(ax, topo - altura_da_antena, 1, altura_da_antena, borda)
        tela.pintar(ax, topo - altura_da_antena - 1, MAGENTA if sorteio.random() < 0.5 else CIANO)
    for jy in range(topo + 3, base - 2, passo_y):
        for jx in range(x + 2, x + largura - 2, passo_x):
            if sorteio.random() < chance_acesa:
                tela.pintar(jx, jy, sorteio.choice(janelas))
    if neon and largura >= 10 and base - topo > 30:
        nx = x + largura - 4
        ny = topo + sorteio.randint(4, 10)
        cor_do_neon = sorteio.choice((MAGENTA, CIANO, AMARELO))
        tela.retangulo(nx - 1, ny - 1, 5, 22, CONTORNO)
        for i in range(6):
            # Cada "letra" do letreiro é um bloquinho de 3x2 com um furo.
            tela.retangulo(nx, ny + i * 3, 3, 2, cor_do_neon)
            tela.pintar(nx + 1 + (i % 2) - (i % 2), ny + i * 3 + (i % 2), misturar(cor_do_neon, CONTORNO, 0.6))


def desenhar_cidade(nome: str, semente: int, base: int, topo_min: int, topo_max: int,
                    larguras: tuple, corpo: tuple, borda: tuple, janelas: list,
                    chance_acesa: float, passo: tuple, neon: bool, lacuna: tuple) -> None:
    tela = Tela(LARGURA, ALTURA)
    sorteio = random.Random(semente)
    x = 0
    while x < LARGURA:
        largura = sorteio.randint(*larguras)
        topo = sorteio.randint(topo_min, topo_max)
        predio(tela, x, largura, topo, base, corpo, borda, janelas, chance_acesa, passo[0], passo[1], sorteio, neon)
        x += largura + sorteio.randint(*lacuna)
    # Abaixo da linha de base é tudo corpo: a camada da frente tapa o resto.
    tela.retangulo(0, base, LARGURA, ALTURA - base, corpo)
    tela.salvar(nome)


# Via elevada

def desenhar_via() -> None:
    """A estradinha da frente: uma via elevada com mureta de neon, faixa amarela,
    postes e pilares. Fica no pé da tela e rola mais rápido que tudo."""
    altura = 44
    tela = Tela(LARGURA, altura)
    pista = cor("221a3c")
    pista_clara = cor("2e2450")
    tela.retangulo(0, 0, LARGURA, altura, TRANSPARENTE)
    # Mureta de trás, pista, mureta da frente, viga e pilares.
    tela.retangulo(0, 10, LARGURA, 2, cor("3a2e66"))
    tela.retangulo(0, 12, LARGURA, 14, pista)
    for x in range(LARGURA):
        if x % 4 < 2:
            tela.pintar(x, 12, pista_clara)
        if x % 24 < 12:
            tela.retangulo(x, 18, 1, 2, AMARELO)
    tela.retangulo(0, 26, LARGURA, 1, CIANO)
    tela.retangulo(0, 27, LARGURA, 4, cor("2a2050"))
    for x in range(0, LARGURA, 6):
        tela.retangulo(x, 27, 1, 4, cor("3d3070"))
    tela.retangulo(0, 31, LARGURA, 3, cor("140e28"))
    for x in range(0, LARGURA, 96):
        tela.retangulo(x + 40, 34, 10, altura - 34, cor("120c22"))
        tela.retangulo(x + 40, 34, 1, altura - 34, cor("2a2050"))
    # Postes curvos com a luz em cima, de 64 em 64 pixels.
    for x in range(10, LARGURA, 64):
        tela.retangulo(x, 0, 1, 12, cor("4a3e7a"))
        tela.retangulo(x, 0, 4, 1, cor("4a3e7a"))
        tela.retangulo(x + 3, 1, 2, 1, AMARELO)
        for dx, dy in ((-1, 0), (2, 0), (0, 1), (1, 1)):
            tela.pintar(x + 3 + dx, 1 + dy, cor("ffd86b", 90))
    tela.salvar("via.png")


# Carros voadores

def desenhar_carro(nome: str, corpo: tuple, sombra: tuple, comprimento: int, altura: int) -> None:
    """Carro voador virado para a direita: capô em cunha, vidro ciano, farol amarelo
    na frente, lanterna magenta atrás e o brilho das turbinas embaixo."""
    tela = Tela(comprimento + 4, altura + 4, repete=False)
    for y in range(altura):
        recuo_frente = max(0, (altura // 2 - y)) if y < altura // 2 else 0
        recuo_tras = 1 if y == 0 else 0
        for x in range(recuo_tras, comprimento - recuo_frente):
            tela.pintar(x + 2, y + 1, corpo if y < altura - 2 else sombra)
    # Cabine.
    for x in range(comprimento // 3, comprimento - 4):
        tela.pintar(x + 2, 1, cor("9af6ff"))
        tela.pintar(x + 2, 2, CIANO)
    tela.pintar(comprimento + 1, altura // 2 + 1, AMARELO)
    tela.pintar(comprimento, altura // 2 + 1, AMARELO)
    tela.pintar(2, altura // 2, MAGENTA)
    # Turbinas embaixo.
    for x in (4, comprimento - 4):
        tela.pintar(x + 2, altura + 1, CIANO)
        tela.pintar(x + 2, altura + 2, cor("4ff0ff", 110))
    # Contorno escuro de 1 pixel em volta do que foi desenhado.
    pintados = [(x, y) for y in range(tela.altura) for x in range(tela.largura) if tela.ler(x, y)[3] == 255]
    for x, y in pintados:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if tela.ler(x + dx, y + dy)[3] == 0:
                tela.pintar(x + dx, y + dy, CONTORNO)
    tela.salvar(nome)


# Título

FONTE_GRANDE = {
    "C": [".####.", "##..##", "##....", "##....", "##....", "##..##", ".####."],
    "Y": ["##..##", "##..##", ".####.", "..##..", "..##..", "..##..", "..##.."],
    "B": ["#####.", "##..##", "##..##", "#####.", "##..##", "##..##", "#####."],
    "E": ["######", "##....", "##....", "#####.", "##....", "##....", "######"],
    "R": ["#####.", "##..##", "##..##", "#####.", "##.##.", "##..##", "##..##"],
    "M": ["##...##", "###.###", "#######", "##.#.##", "##...##", "##...##", "##...##"],
    "O": [".####.", "##..##", "##..##", "##..##", "##..##", "##..##", ".####."],
    "N": ["##..##", "###.##", "######", "##.###", "##..##", "##..##", "##..##"],
    " ": ["...", "...", "...", "...", "...", "...", "..."],
}

FONTE_PEQUENA = {
    "D": ["###.", "#..#", "#..#", "#..#", "###."],
    "E": ["####", "#...", "###.", "#...", "####"],
    "M": ["#...#", "##.##", "#.#.#", "#...#", "#...#"],
    "O": [".##.", "#..#", "#..#", "#..#", ".##."],
}


def mascara_do_texto(texto: str, fonte: dict, escala: int, espaco: int) -> set:
    pontos = set()
    cursor = 0
    for letra in texto:
        glifo = fonte[letra]
        for gy, linha in enumerate(glifo):
            for gx, marca in enumerate(linha):
                if marca == "#":
                    for sy in range(escala):
                        for sx in range(escala):
                            pontos.add((cursor + gx * escala + sx, gy * escala + sy))
        cursor += (len(glifo[0]) + espaco) * escala
    return pontos


def desenhar_titulo() -> None:
    """CYBER MOON em letras grossas: degradê do ciano ao magenta, brilho na beirada de
    cima, relevo roxo para baixo, contorno escuro e o selo DEMO no canto."""
    escala = 3
    letras = mascara_do_texto("CYBER MOON", FONTE_GRANDE, escala, 1)
    largura_do_texto = max(x for x, _ in letras) + 1
    altura_do_texto = 7 * escala
    relevo = 4
    margem = 3
    tela = Tela(largura_do_texto + margem * 2, altura_do_texto + relevo + margem * 2 + 9, repete=False)
    # Paradas do degradê, de cima para baixo da letra. Entre duas paradas a cor anda em
    # degraus de pixel inteiro, sem meio-tom.
    paradas = [CIANO, cor("39b8ff"), cor("8a6cff"), MAGENTA, cor("c030a8")]

    def cor_da_linha(y: int) -> tuple:
        t = y / (altura_do_texto - 1) * (len(paradas) - 1)
        indice = min(int(t), len(paradas) - 2)
        return misturar(paradas[indice], paradas[indice + 1], round((t - indice) * 2) / 2)

    # Relevo primeiro, para as letras ficarem por cima.
    for passo in range(relevo, 0, -1):
        tom = misturar(cor("5a1f7e"), cor("2a0f4a"), passo / relevo)
        for x, y in letras:
            tela.pintar(x + margem, y + margem + passo, tom)
    for x, y in letras:
        tom = cor_da_linha(y)
        # Só a beirada de cima da letra brilha, como luz batendo. A beirada dos furos
        # (o meio do B, do E) fica de fora, senão a letra vira listra.
        if y < escala and (x, y - 1) not in letras:
            tom = misturar(tom, BRANCO, 0.7)
        tela.pintar(x + margem, y + margem, tom)
    contornar(tela)
    # Selo DEMO, pequeno, amarelo, alinhado à direita embaixo do título.
    selo = mascara_do_texto("DEMO", FONTE_PEQUENA, 1, 1)
    largura_do_selo = max(x for x, _ in selo) + 1
    sx = tela.largura - margem - largura_do_selo - 1
    sy = margem + altura_do_texto + relevo + 3
    tela.retangulo(sx - 2, sy - 2, largura_do_selo + 4, 9, cor("2a1450"))
    for x, y in selo:
        tela.pintar(sx + x, sy + y, AMARELO)
    contornar(tela)
    tela.salvar("titulo.png")


def contornar(tela: Tela) -> None:
    pintados = [(x, y) for y in range(tela.altura) for x in range(tela.largura)
                if tela.ler(x, y)[3] == 255 and tela.ler(x, y) != CONTORNO]
    for x, y in pintados:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if tela.ler(x + dx, y + dy)[3] == 0:
                    tela.pintar(x + dx, y + dy, CONTORNO)


if __name__ == "__main__":
    desenhar_ceu()
    desenhar_lua()
    desenhar_nevoa()
    desenhar_cidade("cidade_longe.png", semente=21, base=176, topo_min=92, topo_max=150,
                    larguras=(10, 26), corpo=cor("2c1c52"), borda=cor("3e2a6c"),
                    janelas=[cor("5a3f8a"), cor("6a4a9a"), cor("8a5a9a")], chance_acesa=0.35,
                    passo=(3, 4), neon=False, lacuna=(0, 2))
    desenhar_cidade("cidade_meio.png", semente=42, base=186, topo_min=78, topo_max=145,
                    larguras=(14, 34), corpo=cor("1a1034"), borda=cor("34245e"),
                    janelas=[AMARELO, cor("ffb84f"), CIANO, cor("9a7aff")], chance_acesa=0.28,
                    passo=(3, 3), neon=True, lacuna=(2, 9))
    desenhar_cidade("cidade_perto.png", semente=77, base=200, topo_min=128, topo_max=176,
                    larguras=(22, 44), corpo=cor("0e0820"), borda=cor("2a1c4c"),
                    janelas=[AMARELO, CIANO, MAGENTA, cor("ffe9b0")], chance_acesa=0.22,
                    passo=(4, 4), neon=True, lacuna=(14, 40))
    desenhar_via()
    desenhar_carro("carro_a.png", corpo=cor("ff4fd8"), sombra=cor("9a2a8a"), comprimento=20, altura=6)
    desenhar_carro("carro_b.png", corpo=cor("4ff0ff"), sombra=cor("2a8aa8"), comprimento=18, altura=6)
    desenhar_carro("carro_c.png", corpo=cor("ffd86b"), sombra=cor("b0802a"), comprimento=22, altura=7)
    desenhar_titulo()
