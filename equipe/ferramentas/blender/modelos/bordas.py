"""As peças da borda dos corredores do mapa mundi.

O jogador anda só pelas trilhas e pelos lugares (plano 26, corredores). Onde o deserto
fecha, a parede invisível precisa de algo que se veja e que leia como "não passa": muro
de pedra, cerca, barreira, moita, árvore seca, pilha de sucata. As peças compridas
(muro, cerca, barreira) têm 2 de comprimento ao longo de X, para seguir a curva da borda
emendando uma na outra.

Pacote `cyber_moon_mundo`.
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import faixa_de_aviso

PACOTE = "cyber_moon_mundo"


def muro_de_pedra():
    """Muro de pedra seca, de 2 por 0,55 e 0,75 de altura: três fiadas de pedra chata
    empilhada, sem argamassa, com um tufo de mato no pé."""
    m = kit.Modelo("muro_de_pedra")
    sorteio = random.Random(21)
    cores = ("ferrugem", "salmao", "pessego", "ferrugem", "marrom")
    z = 0.0
    for fiada in range(3):
        altura = (0.28, 0.25, 0.22)[fiada]
        x = -1.05 + sorteio.uniform(0.0, 0.2) * (fiada % 2)
        while x < 1.0:
            largura = sorteio.uniform(0.32, 0.55)
            meio = min(x + largura / 2, 1.0 - largura / 4)
            m.caixa((largura, 0.55 - fiada * 0.06, altura), pos=(meio, sorteio.uniform(-0.03, 0.03), z),
                    cor=cores[sorteio.randrange(len(cores))], chanfro=0.05, rot=(0, sorteio.uniform(-4, 4), sorteio.uniform(-5, 5)))
            x += largura + 0.02
        z += altura - 0.02
    for k in range(3):
        m.cilindro(0.025, 0.25, pos=(sorteio.uniform(-0.9, 0.9), -0.32, 0), cor="verde", lados=3, raio_do_topo=0.005,
                   rot=(sorteio.uniform(-20, 20), 0, 0))
    return m.finalizar()


def cerca_de_estaca():
    """Cerca de estaca torta, de 2 de comprimento e 1 de altura: dois mourões, duas
    travessas e tábuas de altura desencontrada."""
    m = kit.Modelo("cerca_de_estaca")
    sorteio = random.Random(22)
    for x in (-0.95, 0.95):
        m.caixa((0.13, 0.13, 1.05), pos=(x, 0, 0), cor="marrom", rot=(sorteio.uniform(-3, 3), 0, 0))
    for z in (0.3, 0.75):
        m.caixa((2.0, 0.06, 0.08), pos=(0, 0.06, z), cor="ferrugem", rot=(0, sorteio.uniform(-2, 2), 0))
    x = -0.78
    while x < 0.85:
        altura = sorteio.uniform(0.8, 1.0)
        m.caixa((0.16, 0.04, altura), pos=(x, -0.02, 0.02), cor=("creme", "pessego", "marrom")[sorteio.randrange(3)],
                rot=(0, sorteio.uniform(-4, 4), 0))
        x += 0.22
    return m.finalizar()


def barreira_de_concreto():
    """Barreira de concreto de pista (o perfil de New Jersey), de 2 por 0,6 e 0,8 de
    altura, com faixa de aviso e um lascado."""
    m = kit.Modelo("barreira_de_concreto")
    perfil = [(-0.3, 0.0), (0.3, 0.0), (0.3, 0.12), (0.12, 0.3), (0.09, 0.8), (-0.09, 0.8), (-0.12, 0.3), (-0.3, 0.12)]
    # O prisma extruda ao longo de Y; girado, a peça fica comprida em X.
    corpo = m.prisma([(y, z) for y, z in perfil], 1.96, cor="cinza", degrade=True)
    m.mover(corpo, rot=(0, 0, 90))
    faixa_de_aviso(m, 1.4, (0, -0.11, 0.62), altura=0.1, partes=7)
    m.caixa((0.25, 0.1, 0.12), pos=(0.7, 0.05, 0.72), cor="cinza_escuro", rot=(0, 20, 0))
    return m.finalizar()


def moita_de_cacto():
    """Moita fechada de cacto e mato seco, de 1,6 por 1,2 e 1,1 de altura."""
    m = kit.Modelo("moita_de_cacto")
    sorteio = random.Random(23)
    for k in range(3):
        x, y = sorteio.uniform(-0.5, 0.5), sorteio.uniform(-0.3, 0.3)
        altura = sorteio.uniform(0.6, 1.1)
        m.cilindro(0.14, altura, pos=(x, y, 0), cor="verde", lados=7, degrade=True)
        m.esfera(0.14, pos=(x, y, altura), cor="verde", escala=(1, 1, 0.7))
        if k != 1:
            braco = sorteio.choice((-1, 1))
            m.cilindro(0.08, 0.28, pos=(x + braco * 0.15, y, altura * 0.45), cor="verde", lados=6, rot=(0, braco * 70, 0))
            m.cilindro(0.08, 0.25, pos=(x + braco * 0.3, y, altura * 0.5), cor="verde", lados=6)
    for k in range(4):
        tamanho = sorteio.uniform(0.2, 0.32)
        m.cilindro(tamanho, tamanho * 0.9, pos=(sorteio.uniform(-0.75, 0.75), sorteio.uniform(-0.5, 0.5), 0), cor="verde_folha",
                   lados=9, raio_do_topo=tamanho * 0.75, degrade=True)
    for k in range(10):
        angulo = k * 36 + sorteio.uniform(-10, 10)
        galho = m.cilindro(0.02, sorteio.uniform(0.35, 0.55), cor="creme" if k % 2 else "marrom", lados=3, raio_do_topo=0.006,
                           rot=(sorteio.uniform(30, 60), 0, 0))
        m.mover(galho, pos=(sorteio.uniform(-0.6, 0.6), sorteio.uniform(-0.4, 0.4), 0), rot=(0, 0, angulo))
    return m.finalizar()


def arvore_seca():
    """Árvore morta do deserto, de 2,8 de altura: tronco torto e galhos sem folha.
    Alta: só vai na borda do norte, que não esconde o jogador."""
    m = kit.Modelo("arvore_seca")
    sorteio = random.Random(24)
    m.cilindro(0.2, 1.4, cor="marrom", lados=7, raio_do_topo=0.13, rot=(4, 3, 0), degrade=True)
    m.cilindro(0.13, 1.0, pos=(0.08, 0.05, 1.35), cor="marrom", lados=6, raio_do_topo=0.07, rot=(-12, 8, 0))
    for k, (altura, comprimento, inclinacao, giro) in enumerate(((1.1, 0.9, 55, 20), (1.5, 0.8, 50, 150), (1.9, 0.7, 45, 260),
                                                                   (2.1, 0.55, 35, 90), (1.3, 0.6, 65, 300))):
        galho = m.cilindro(0.06, comprimento, cor="marrom" if k % 2 else "ferrugem", lados=5, raio_do_topo=0.02,
                           rot=(inclinacao, 0, 0))
        m.mover(galho, pos=(0, 0, altura), rot=(0, 0, giro))
        ponta = m.cilindro(0.025, comprimento * 0.5, cor="ferrugem", lados=4, raio_do_topo=0.008, rot=(inclinacao - 30, 0, 0))
        m.mover(ponta, pos=(0, 0, altura + comprimento * 0.7), rot=(0, 0, giro + 25))
    for k in range(4):
        angulo = math.radians(k * 90 + 30)
        raiz = m.cilindro(0.07, 0.4, cor="marrom", lados=4, raio_do_topo=0.02, rot=(75, 0, 0))
        m.mover(raiz, pos=(0, 0, 0.05), rot=(0, 0, math.degrees(angulo)))
    m.esfera(0.25, pos=(0.35, -0.2, 0.05), cor="ferrugem", escala=(1.3, 1, 0.5), subdivisoes=1)
    return m.finalizar()


def pilha_de_sucata():
    """Pilha de sucata, de 1,8 por 1,2 e 1 de altura: pneus, chapa, tambor e cano."""
    m = kit.Modelo("pilha_de_sucata")
    for indice, (x, y, z) in enumerate(((-0.5, 0.1, 0), (-0.45, 0.12, 0.24))):
        m.cilindro(0.34, 0.22, pos=(x, y, z), cor="grafite", lados=10, cor_das_tampas="preto")
    m.cilindro(0.22, 0.6, pos=(0.45, -0.15, 0), cor="ferrugem", lados=10, degrade=True, cor_das_tampas="chumbo")
    m.caixa((1.1, 0.05, 0.7), pos=(0.05, 0.3, 0.0), cor="cinza_metal", rot=(0, -25, 8))
    m.caixa((0.9, 0.04, 0.5), pos=(-0.1, -0.35, 0.0), cor="ferrugem", rot=(0, 30, -12))
    m.cilindro(0.05, 1.2, pos=(0.1, 0.0, 0.5), cor="chumbo", lados=6, rot=(0, 80, 20))
    m.caixa((0.35, 0.3, 0.3), pos=(0.7, 0.3, 0.0), cor="amarelo", chanfro=0.03, rot=(0, 0, 15))
    return m.finalizar()


MODELOS = [muro_de_pedra, cerca_de_estaca, barreira_de_concreto, moita_de_cacto, arvore_seca, pilha_de_sucata]

if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.produzir(MODELOS, "bordas")
