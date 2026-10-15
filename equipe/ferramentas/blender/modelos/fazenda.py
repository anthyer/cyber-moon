"""Peças do mapa da fazenda: a casa, o galpão, a caixa d'água, a porteira, o espantalho e
a borda dos talhões. Também a cerca de arame, que fecha o mapa da fazenda e trechos do
mundo.

Pacote `cyber_moon_mundo`.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/fazenda.py", run_name="__main__")
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import faixa_de_aviso, olhar_bravo

PACOTE = "cyber_moon_mundo"


def casa_da_fazenda():
    """A casa do jogador: barro claro, telhado chato com painel solar e caixa d'água,
    varanda com toldo e as janelas acesas. Frente em -Y, para a câmera."""
    m = kit.Modelo("casa_da_fazenda")
    m.caixa((6.4, 5.0, 0.2), cor="cinza_medio")
    m.caixa((6.0, 4.4, 2.7), pos=(0, 0.2, 0.2), cor="creme", chanfro=0.12, degrade=True)
    m.caixa((6.2, 4.6, 0.25), pos=(0, 0.2, 2.9), cor="pessego", chanfro=0.06)
    m.caixa((0.9, 0.08, 1.7), pos=(-0.8, -2.02, 0.2), cor="marrom")
    m.caixa((0.08, 0.1, 0.08), pos=(-0.5, -2.08, 1.0), cor="amarelo")
    for x in (0.9, 2.2):
        m.caixa((0.9, 0.08, 0.7), pos=(x, -2.02, 1.1), cor="amarelo", brilho=True)
        m.caixa((1.0, 0.12, 0.1), pos=(x, -2.04, 1.05), cor="marrom")
    m.caixa((6.4, 1.6, 0.08), pos=(0, -2.6, 2.3), cor="laranja", rot=(-8, 0, 0))
    for x in (-3.0, -1.0, 1.0, 3.0):
        m.caixa((0.12, 0.12, 2.3), pos=(x, -3.3, 0.2), cor="marrom")
    m.caixa((6.4, 1.6, 0.12), pos=(0, -2.6, 0.08), cor="ferrugem")
    painel = m.caixa((2.4, 1.4, 0.08), pos=(0, 0, 0), cor="indigo")
    m.mover(painel, pos=(-1.3, 0.6, 3.4), rot=(-20, 0, 0))
    m.cilindro(0.6, 1.0, pos=(1.8, 1.0, 3.15), cor="azul", lados=10, cor_das_tampas="cinza_medio")
    m.caixa((0.3, 0.06, 0.18), pos=(1.8, 0.4, 3.6), cor="verde", brilho=True)
    return m.finalizar()


def galpao_da_fazenda():
    """O galpão de chapa onde ficam os baús e as ferramentas."""
    m = kit.Modelo("galpao_da_fazenda")
    m.caixa((4.2, 3.2, 0.15), cor="cinza_medio")
    m.caixa((4.0, 3.0, 2.2), pos=(0, 0, 0.15), cor="cinza_metal", degrade=True)
    for indice in range(8):
        m.caixa((0.05, 3.02, 2.2), pos=(-1.75 + indice * 0.5, 0, 0.15), cor="cinza_medio")
    m.prisma([(-2.2, 0.0), (2.2, 0.0), (0.0, 0.7)], 3.3, pos=(0, 0, 2.35), cor="ferrugem")
    m.caixa((1.6, 0.06, 1.8), pos=(0, -1.52, 0.15), cor="cinza_escuro")
    faixa_de_aviso(m, 1.8, (0, -1.56, 1.95), altura=0.12, partes=6)
    m.caixa((0.3, 0.06, 0.18), pos=(1.4, -1.53, 1.9), cor="amarelo", brilho=True)
    return m.finalizar()


def caixa_dagua_da_fazenda():
    """A caixa d'água em torre, onde o regador enche. Fica no canto norte."""
    m = kit.Modelo("caixa_dagua_da_fazenda")
    for x in (-0.7, 0.7):
        for y in (-0.7, 0.7):
            m.caixa((0.12, 0.12, 2.6), pos=(x, y, 0), cor="ferrugem")
    m.caixa((1.6, 1.6, 0.12), pos=(0, 0, 2.6), cor="marrom")
    m.cilindro(1.0, 1.5, pos=(0, 0, 2.72), cor="azul", lados=10, degrade=True, cor_das_tampas="cinza_medio")
    for z in (3.0, 3.8):
        m.cilindro(1.02, 0.08, pos=(0, 0, z), cor="cinza_escuro", lados=10)
    m.cilindro(0.08, 2.6, pos=(0.9, -0.9, 0), cor="cinza_metal", lados=6)
    m.cilindro(0.15, 0.3, pos=(0.9, -0.9, 0.3), cor="amarelo", lados=6)
    return m.finalizar()


def porteira_da_fazenda():
    """A porteira da fazenda: dois mourões, a trave com a placa acesa e a porteira aberta.
    O vão tem 4 de largura. É a passagem entre a fazenda e o mundo."""
    m = kit.Modelo("porteira_da_fazenda")
    for x in (-2.3, 2.3):
        m.caixa((0.4, 0.4, 3.0), pos=(x, 0, 0), cor="marrom", chanfro=0.04)
        m.caixa((0.5, 0.5, 0.2), pos=(x, 0, 3.0), cor="ferrugem")
    m.caixa((5.2, 0.3, 0.3), pos=(0, 0, 2.7), cor="ferrugem")
    m.caixa((2.4, 0.12, 0.7), pos=(0, -0.2, 1.95), cor="preto")
    m.caixa((2.1, 0.14, 0.4), pos=(0, -0.26, 2.1), cor="verde", brilho=True)
    for lado in (-1, 1):
        folha = m.caixa((1.9, 0.08, 1.1), pos=(0, 0, 0.1), cor="cinza_metal")
        m.mover(folha, pos=(lado * 2.1, -0.95 * 1, 0), rot=(0, 0, lado * 80))
    return m.finalizar()


def cerca_de_arame():
    """Quatro de cerca de arame: mourões de madeira e três fios. Fecha a borda do mapa."""
    m = kit.Modelo("cerca_de_arame")
    for x in (-1.9, 0.0, 1.9):
        m.caixa((0.14, 0.14, 1.2), pos=(x, 0, 0), cor="marrom")
    for z in (0.35, 0.7, 1.05):
        m.caixa((4.0, 0.03, 0.03), pos=(0, 0, z), cor="cinza_metal")
    return m.finalizar()


def enfeite_borda_de_talhao():
    """Dois de tábua deitada na beira do talhão, rente ao chão. Sem colisão: o jogador
    entra no talhão andando. Marca até onde a enxada funciona."""
    m = kit.Modelo("enfeite_borda_de_talhao")
    m.caixa((2.0, 0.16, 0.06), cor="marrom", chanfro=0.015)
    for x in (-0.95, 0.95):
        m.caixa((0.06, 0.18, 0.08), pos=(x, 0, 0), cor="ferrugem")
    return m.finalizar()


def espantalho_robo():
    """O espantalho da fazenda: um robô velho num poste, com chapéu de palha e o visor
    apagado. Não é inimigo; o olhar é sem brilho."""
    m = kit.Modelo("espantalho_robo")
    m.cilindro(0.06, 1.6, cor="marrom", lados=6)
    m.caixa((1.4, 0.08, 0.08), pos=(0, 0, 1.1), cor="marrom")
    m.caixa((0.5, 0.3, 0.55), pos=(0, 0, 0.8), cor="cinza_metal", chanfro=0.05)
    m.caixa((0.52, 0.32, 0.12), pos=(0, 0, 0.95), cor="laranja")
    m.caixa((0.34, 0.3, 0.3), pos=(0, 0, 1.38), cor="cinza_medio", chanfro=0.05)
    m.caixa((0.26, 0.03, 0.08), pos=(0, -0.16, 1.5), cor="grafite")
    m.cilindro(0.38, 0.05, pos=(0, 0, 1.68), cor="amarelo", lados=10)
    m.cilindro(0.18, 0.18, pos=(0, 0, 1.72), cor="amarelo", lados=10, raio_do_topo=0.14)
    for lado in (-1, 1):
        m.caixa((0.14, 0.14, 0.4), pos=(lado * 0.72, 0, 0.75), cor="cinza_metal")
    return m.finalizar()


def caixa_de_correio():
    """A caixa de correio na porteira, com a bandeirinha levantada."""
    m = kit.Modelo("caixa_de_correio")
    m.caixa((0.1, 0.1, 0.9), cor="marrom")
    m.caixa((0.3, 0.5, 0.3), pos=(0, 0, 0.9), cor="azul", chanfro=0.06)
    m.caixa((0.03, 0.04, 0.3), pos=(0.17, 0.1, 1.05), cor="grafite")
    m.caixa((0.03, 0.14, 0.1), pos=(0.17, 0.17, 1.3), cor="magenta")
    return m.finalizar()


MODELOS = [
    casa_da_fazenda, galpao_da_fazenda, caixa_dagua_da_fazenda, porteira_da_fazenda, cerca_de_arame,
    enfeite_borda_de_talhao, espantalho_robo, caixa_de_correio,
]

if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.produzir(MODELOS, "fazenda")
