"""Objetos de uso que enchem os lugares: feira, banco, máquina de venda, carro velho,
placa, vagonete e trilho, barco, mesa e toldo do acampamento, e as coisas da fazenda
(feno, carrinho de mão, varal, bancada).

Pacote `cyber_moon_mundo`.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/utensilios.py", run_name="__main__")
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import faixa_de_aviso

PACOTE = "cyber_moon_mundo"


def barraca_de_feira():
    """Barraca da feira da praça: balcão com caixotes de fruta e o toldo listrado."""
    m = kit.Modelo("barraca_de_feira")
    m.caixa((1.8, 0.8, 0.8), cor="marrom", chanfro=0.03)
    m.caixa((1.9, 0.9, 0.06), pos=(0, 0, 0.8), cor="ferrugem")
    for x, cor in ((-0.55, "laranja"), (0.0, "verde"), (0.55, "amarelo")):
        m.caixa((0.5, 0.5, 0.12), pos=(x, -0.05, 0.86), cor="marrom")
        for dx in (-0.12, 0.12):
            m.esfera(0.08, pos=(x + dx, -0.05, 1.02), cor=cor)
    for x in (-0.9, 0.9):
        m.cilindro(0.03, 1.9, pos=(x, 0.38, 0), cor="grafite", lados=5)
        m.cilindro(0.03, 1.6, pos=(x, -0.45, 0), cor="grafite", lados=5)
    for indice in range(6):
        cor = "magenta" if indice % 2 == 0 else "branco"
        faixa = m.caixa((0.34, 1.2, 0.05), pos=(-0.85 + indice * 0.34, -0.05, 1.75), cor=cor)
        m.mover(faixa, rot=(-12, 0, 0))
    return m.finalizar()


def banco_de_praca():
    """Banco de praça de concreto com assento de madeira."""
    m = kit.Modelo("banco_de_praca")
    for x in (-0.65, 0.65):
        m.caixa((0.18, 0.5, 0.4), pos=(x, 0, 0), cor="cinza_medio", chanfro=0.03)
    m.caixa((1.6, 0.5, 0.08), pos=(0, 0, 0.4), cor="marrom")
    m.caixa((1.6, 0.08, 0.35), pos=(0, 0.22, 0.48), cor="marrom")
    return m.finalizar()


def maquina_de_venda():
    """Máquina de venda de rua, com a frente acesa. Encostada em parede ou poste."""
    m = kit.Modelo("maquina_de_venda")
    m.caixa((0.8, 0.6, 1.7), cor="indigo", chanfro=0.04)
    m.caixa((0.6, 0.04, 1.0), pos=(-0.04, -0.3, 0.55), cor="azul_claro", brilho=True)
    for linha in range(4):
        for coluna in range(3):
            m.caixa((0.12, 0.05, 0.12), pos=(-0.22 + coluna * 0.18, -0.32, 0.65 + linha * 0.22),
                    cor=("magenta", "amarelo", "verde")[coluna])
    m.caixa((0.14, 0.05, 0.5), pos=(0.3, -0.31, 0.8), cor="grafite")
    m.caixa((0.82, 0.62, 0.2), pos=(0, 0, 1.7), cor="magenta", brilho=True)
    return m.finalizar()


def carro_velho():
    """Carro abandonado sem rodas, apoiado em tijolos, com a ferrugem tomando a lataria."""
    m = kit.Modelo("carro_velho")
    for x in (-0.9, 0.9):
        for y in (-0.55, 0.55):
            m.caixa((0.3, 0.2, 0.25), pos=(x, y, 0), cor="cinza_medio")
    m.caixa((2.6, 1.3, 0.45), pos=(0, 0, 0.25), cor="azul", chanfro=0.1, degrade=True)
    m.caixa((1.4, 1.2, 0.45), pos=(-0.15, 0, 0.7), cor="azul", chanfro=0.12)
    m.caixa((1.2, 1.22, 0.3), pos=(-0.15, 0, 0.75), cor="gelo")
    m.caixa((0.6, 0.04, 0.3), pos=(0.6, -0.66, 0.35), cor="ferrugem")
    m.caixa((0.5, 1.32, 0.2), pos=(-1.0, 0, 0.35), cor="ferrugem")
    for y in (-0.45, 0.45):
        m.caixa((0.05, 0.25, 0.12), pos=(1.31, y, 0.45), cor="amarelo")
    return m.finalizar()


def placa_de_estrada():
    """Placa de beira de estrada, torta, com a seta para a vila."""
    m = kit.Modelo("placa_de_estrada")
    poste = m.cilindro(0.04, 1.6, cor="grafite", lados=5, rot=(4, 0, 0))
    m.caixa((0.9, 0.06, 0.4), pos=(0.1, 0, 1.25), cor="verde")
    m.prisma([(0.0, -0.15), (0.2, 0.0), (0.0, 0.15)], 0.07, pos=(0.38, -0.01, 1.45), cor="branco")
    m.caixa((0.55, 0.07, 0.06), pos=(0.0, -0.01, 1.45), cor="branco")
    return m.finalizar()


def vagonete():
    """Vagonete da pedreira, cheio de minério."""
    m = kit.Modelo("vagonete")
    m.prisma([(-0.6, 0.0), (0.6, 0.0), (0.75, 0.6), (-0.75, 0.6)], 0.8, pos=(0, 0, 0.2), cor="ferrugem")
    for x in (-0.4, 0.4):
        for y in (-0.42, 0.42):
            m.cilindro(0.14, 0.08, pos=(x, y - 0.04 * (1 if y > 0 else -1), 0.14), cor="grafite", lados=8, rot=(90, 0, 0))
    for x, y, cor in ((-0.25, 0.1, "cinza_metal"), (0.2, -0.1, "laranja"), (0.0, 0.15, "cinza_medio"), (0.3, 0.2, "cinza_metal")):
        m.esfera(0.18, pos=(x, y, 0.82), cor=cor, subdivisoes=1)
    return m.finalizar()


def enfeite_trilho():
    """Quatro de trilho de mina, ao longo de Y. Rente ao chão e sem colisão (o nome
    começa com enfeite_), para o jogador andar por cima."""
    m = kit.Modelo("enfeite_trilho")
    for indice in range(8):
        m.caixa((1.1, 0.16, 0.06), pos=(0, -1.75 + indice * 0.5, 0), cor="marrom")
    for x in (-0.4, 0.4):
        m.caixa((0.06, 4.0, 0.06), pos=(x, 0, 0.06), cor="cinza_metal")
    return m.finalizar()


def barco_velho():
    """Barco de alumínio velho, atracado no píer. Comprido ao longo de Y, proa em -Y."""
    m = kit.Modelo("barco_velho")
    m.caixa((1.1, 2.0, 0.4), pos=(0, 0.2, 0), cor="cinza_metal", chanfro=0.08, degrade=True)
    proa = m.cilindro(0.55, 0.4, cor="cinza_metal", lados=3, raio_do_topo=0.55)
    m.mover(proa, rot=(0, 0, 90))
    m.mover(proa, pos=(0, -0.95, 0))
    m.caixa((0.95, 1.8, 0.05), pos=(0, 0.25, 0.3), cor="cinza_medio")
    m.caixa((0.9, 0.18, 0.06), pos=(0, 0.1, 0.36), cor="marrom")
    m.caixa((0.3, 0.3, 0.35), pos=(0, 1.15, 0.2), cor="grafite")
    m.caixa((1.12, 0.06, 0.08), pos=(0, -0.3, 0.34), cor="laranja")
    return m.finalizar()


def mesa_de_acampamento():
    """Mesa dobrável do acampamento com dois banquinhos e latas em cima."""
    m = kit.Modelo("mesa_de_acampamento")
    m.caixa((1.2, 0.7, 0.05), pos=(0, 0, 0.62), cor="cinza_metal")
    for x in (-0.5, 0.5):
        for y in (-0.28, 0.28):
            m.cilindro(0.025, 0.62, pos=(x, y, 0), cor="grafite", lados=4)
    for x, cor in ((-0.3, "magenta"), (0.1, "amarelo"), (0.35, "azul")):
        m.cilindro(0.04, 0.12, pos=(x, 0.05, 0.67), cor=cor, lados=6)
    for y in (-0.65, 0.65):
        m.cilindro(0.16, 0.35, pos=(0, y, 0), cor="laranja", lados=6)
    return m.finalizar()


def toldo_de_lona():
    """Toldo de lona esticado em quatro varas, a sombra do acampamento."""
    m = kit.Modelo("toldo_de_lona")
    for x in (-1.4, 1.4):
        for y in (-1.0, 1.0):
            m.cilindro(0.04, 2.0 if y > 0 else 1.7, pos=(x, y, 0), cor="grafite", lados=5)
    lona = m.caixa((3.0, 2.2, 0.04), pos=(0, 0, 0), cor="laranja")
    m.mover(lona, rot=(-8, 0, 0))
    m.mover(lona, pos=(0, 0, 1.85))
    faixa = m.caixa((3.0, 0.3, 0.045), pos=(0, -0.9, 0), cor="grafite")
    m.mover(faixa, rot=(-8, 0, 0))
    m.mover(faixa, pos=(0, 0, 1.85))
    return m.finalizar()


def fardo_de_feno():
    """Fardo de feno amarrado, para a fazenda."""
    m = kit.Modelo("fardo_de_feno")
    m.caixa((0.9, 0.55, 0.5), cor="amarelo", chanfro=0.06, degrade=True)
    for x in (-0.22, 0.22):
        m.caixa((0.04, 0.57, 0.52), pos=(x, 0, 0), cor="marrom")
    return m.finalizar()


def carrinho_de_mao():
    """Carrinho de mão com terra, encostado perto da horta."""
    m = kit.Modelo("carrinho_de_mao")
    m.prisma([(-0.35, 0.0), (0.3, 0.0), (0.45, 0.35), (-0.45, 0.35)], 0.6, pos=(0, 0, 0.2), cor="verde", rot=(0, 0, 90))
    m.caixa((0.5, 0.75, 0.04), pos=(0, 0, 0.52), cor="marrom")
    m.cilindro(0.14, 0.06, pos=(0, -0.55, 0.14), cor="grafite", lados=8, rot=(0, 90, 0))
    for x in (-0.22, 0.22):
        m.caixa((0.04, 0.9, 0.04), pos=(x, 0.25, 0.32), cor="marrom", rot=(-8, 0, 0))
        m.caixa((0.04, 0.04, 0.2), pos=(x, 0.3, 0.0), cor="grafite")
    return m.finalizar()


def varal():
    """Varal com roupas penduradas, entre dois postes."""
    m = kit.Modelo("varal")
    for x in (-1.5, 1.5):
        m.cilindro(0.04, 1.6, pos=(x, 0, 0), cor="marrom", lados=5)
    m.caixa((3.0, 0.02, 0.02), pos=(0, 0, 1.5), cor="branco")
    for x, cor, altura in ((-1.0, "azul", 0.5), (-0.4, "magenta", 0.4), (0.25, "amarelo", 0.45), (0.9, "branco", 0.55)):
        m.caixa((0.45, 0.02, altura), pos=(x, 0, 1.5 - altura), cor=cor)
    return m.finalizar()


def bancada_de_ferramentas():
    """Bancada encostada no galpão, com ferramentas e um regador."""
    m = kit.Modelo("bancada_de_ferramentas")
    m.caixa((1.4, 0.6, 0.06), pos=(0, 0, 0.75), cor="marrom")
    for x in (-0.62, 0.62):
        m.caixa((0.08, 0.5, 0.75), pos=(x, 0, 0), cor="ferrugem")
    m.caixa((1.4, 0.06, 0.6), pos=(0, 0.28, 0.81), cor="marrom")
    for x, cor in ((-0.4, "cinza_metal"), (-0.1, "marrom"), (0.15, "cinza_metal")):
        m.caixa((0.04, 0.04, 0.45), pos=(x, 0.24, 0.95), cor=cor)
    m.cilindro(0.1, 0.18, pos=(0.4, -0.05, 0.81), cor="azul", lados=8)
    m.cilindro(0.02, 0.16, pos=(0.52, -0.05, 0.9), cor="azul", lados=4, rot=(0, 50, 0))
    return m.finalizar()


MODELOS = [
    barraca_de_feira, banco_de_praca, maquina_de_venda, carro_velho, placa_de_estrada, vagonete, enfeite_trilho,
    barco_velho, mesa_de_acampamento, toldo_de_lona, fardo_de_feno, carrinho_de_mao, varal,
    bancada_de_ferramentas,
]

if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.produzir(MODELOS, "utensilios")
