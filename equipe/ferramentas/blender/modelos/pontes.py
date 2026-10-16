"""As três pontes do mapa mundi: de sucata, de madeira e de cabo (a do cânion).

O vão vai ao longo de X, centrado na origem, com o tabuleiro rente ao chão (y = 0 no
jogo): o rio e o cânion são afundados, e a ponte é o chão por cima deles. Os pilares
descem até o leito. Os guarda-corpos dos dois lados seguram o jogador em cima.

Pacote `cyber_moon_mundo`.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import faixa_de_aviso

PACOTE = "cyber_moon_mundo"


def ponte_de_sucata():
    """Ponte de chapa e viga de aço, remendada, com faixa de aviso. 7 de vão."""
    m = kit.Modelo("ponte_de_sucata")
    comprimento = 7.0
    m.caixa((comprimento, 2.8, 0.12), pos=(0, 0, -0.08), cor="cinza_metal")
    for x in (-2.4, -0.8, 0.8, 2.4):
        m.caixa((1.5, 2.6, 0.03), pos=(x, 0, 0.04), cor="cinza_medio" if x < 0 else "chumbo")
    m.caixa((0.9, 1.2, 0.035), pos=(0.6, 0.4, 0.06), cor="ferrugem")
    for y in (-1.35, 1.35):
        m.caixa((comprimento, 0.16, 0.16), pos=(0, y, 0.75), cor="ferrugem")
        for x in (-3.2, -1.6, 0.0, 1.6, 3.2):
            m.caixa((0.12, 0.12, 0.8), pos=(x, y, 0), cor="grafite")
        m.caixa((comprimento, 0.2, 0.25), pos=(0, y, -0.3), cor="grafite")
    faixa_de_aviso(m, comprimento, (0, -1.45, 0.45), altura=0.12, partes=14)
    for x in (-1.5, 1.5):
        m.caixa((0.4, 0.4, 1.6), pos=(x, 0, -1.6), cor="cinza", chanfro=0.04)
    return m.finalizar()


def ponte_de_madeira():
    """Ponte de tábua com corrimão de corda. 6,5 de vão."""
    m = kit.Modelo("ponte_de_madeira")
    comprimento = 6.5
    for indice in range(13):
        x = -comprimento / 2 + 0.25 + indice * 0.5
        m.caixa((0.46, 2.6, 0.08), pos=(x, 0, -0.04), cor="marrom" if indice % 2 else "ferrugem", rot=(0, 0, (indice % 3 - 1) * 1.5))
    for y in (-1.15, 1.15):
        m.caixa((comprimento, 0.12, 0.12), pos=(0, y, -0.2), cor="marrom")
        for x in (-3.0, -1.0, 1.0, 3.0):
            m.cilindro(0.07, 0.95, pos=(x, y * 1.08, 0), cor="marrom", lados=6)
            m.cilindro(0.08, 1.4, pos=(x, y * 1.08, -1.45), cor="ferrugem", lados=6)
        m.caixa((comprimento, 0.04, 0.04), pos=(0, y * 1.08, 0.85), cor="creme")
        m.caixa((comprimento, 0.04, 0.04), pos=(0, y * 1.08, 0.5), cor="creme")
    return m.finalizar()


def ponte_de_cabo():
    """A ponte do cânion: tábuas penduradas em cabos, entre dois pares de mourões. 9 de vão."""
    m = kit.Modelo("ponte_de_cabo")
    comprimento = 9.0
    for indice in range(18):
        x = -comprimento / 2 + 0.25 + indice * 0.5
        afunda = -0.12 * (1.0 - (x / (comprimento / 2)) ** 2)
        m.caixa((0.42, 2.2, 0.07), pos=(x, 0, afunda - 0.03), cor="marrom" if indice % 2 else "ferrugem")
    for x in (-4.6, 4.6):
        for y in (-1.25, 1.25):
            m.caixa((0.22, 0.22, 1.6), pos=(x, y, -0.2), cor="ferrugem", chanfro=0.03)
    for y in (-1.15, 1.15):
        for altura in (0.55, 0.95):
            for indice in range(9):
                x0 = -comprimento / 2 + indice * 1.0
                meio = x0 + 0.5
                afunda = -0.25 * (1.0 - (meio / (comprimento / 2)) ** 2)
                m.caixa((1.02, 0.04, 0.04), pos=(meio, y, altura + afunda), cor="grafite")
        for indice in range(1, 9):
            x = -comprimento / 2 + indice * 1.0
            afunda = -0.25 * (1.0 - (x / (comprimento / 2)) ** 2)
            m.caixa((0.03, 0.03, 0.9 + afunda), pos=(x, y, 0.0), cor="grafite")
    m.caixa((0.6, 0.06, 0.4), pos=(-4.6, -1.42, 1.0), cor="amarelo")
    return m.finalizar()


MODELOS = [ponte_de_sucata, ponte_de_madeira, ponte_de_cabo]

if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.produzir(MODELOS, "pontes")
