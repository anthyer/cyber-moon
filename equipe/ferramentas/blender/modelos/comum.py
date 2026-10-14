"""Peças comuns às três dungeons: piso, parede, porta e baú de recompensa.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/comum.py", run_name="__main__")
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit


def chao_metal_placa():
    """Placa de piso de 2 por 2, com o topo em z = 0. Quatro chapas com junta entre elas."""
    m = kit.Modelo("chao_metal_placa")
    m.caixa((2.0, 2.0, 0.1), pos=(0, 0, -0.12), cor="grafite")
    for x in (-0.5, 0.5):
        for y in (-0.5, 0.5):
            m.caixa((0.96, 0.96, 0.02), pos=(x, y, -0.02), cor="cinza_medio")
    for x in (-0.86, 0.86):
        for y in (-0.86, 0.86):
            m.cilindro(0.03, 0.004, pos=(x, y, 0.0), cor="chumbo", lados=6)
    return m.finalizar()


def chao_concreto_placa():
    """Placa de concreto de 2 por 2, com uma junta de dilatação em cruz."""
    m = kit.Modelo("chao_concreto_placa")
    m.caixa((2.0, 2.0, 0.1), pos=(0, 0, -0.12), cor="cinza_medio")
    for x in (-0.5, 0.5):
        for y in (-0.5, 0.5):
            m.caixa((0.98, 0.98, 0.02), pos=(x, y, -0.02), cor="cinza")
    return m.finalizar()


def chao_grade():
    """Grade de piso de 2 por 2: barras de metal sobre um fundo escuro."""
    m = kit.Modelo("chao_grade")
    m.caixa((2.0, 2.0, 0.1), pos=(0, 0, -0.12), cor="preto")
    m.caixa((2.0, 0.12, 0.02), pos=(0, -0.94, -0.02), cor="chumbo")
    m.caixa((2.0, 0.12, 0.02), pos=(0, 0.94, -0.02), cor="chumbo")
    m.caixa((0.12, 2.0, 0.02), pos=(-0.94, 0, -0.02), cor="chumbo")
    m.caixa((0.12, 2.0, 0.02), pos=(0.94, 0, -0.02), cor="chumbo")
    for indice in range(7):
        x = -0.72 + indice * 0.24
        m.caixa((0.08, 1.8, 0.02), pos=(x, 0, -0.02), cor="cinza_medio")
    return m.finalizar()


def chao_faixa_de_aviso():
    """Placa de 2 por 2 com uma faixa amarela e grafite, para a soleira de porta e de arena."""
    m = kit.Modelo("chao_faixa_de_aviso")
    m.caixa((2.0, 2.0, 0.1), pos=(0, 0, -0.12), cor="grafite")
    m.caixa((2.0, 1.4, 0.02), pos=(0, 0.3, -0.02), cor="cinza_medio")
    for indice in range(8):
        cor = "amarelo" if indice % 2 == 0 else "grafite"
        m.caixa((0.25, 0.56, 0.02), pos=(-0.875 + indice * 0.25, -0.7, -0.02), cor=cor)
    return m.finalizar()


def parede_concreto():
    """Módulo de parede de 2 de largura por 2 de altura. Rodapé, pano e capa."""
    m = kit.Modelo("parede_concreto")
    m.caixa((2.0, 0.3, 1.9), pos=(0, 0, 0), cor="cinza", degrade=True)
    m.caixa((2.0, 0.36, 0.28), pos=(0, 0, 0), cor="chumbo", chanfro=0.03)
    m.caixa((2.0, 0.38, 0.12), pos=(0, 0, 1.88), cor="cinza_escuro", chanfro=0.03)
    for x in (-0.5, 0.5):
        m.caixa((0.03, 0.31, 1.6), pos=(x, 0, 0.28), cor="cinza_medio")
    return m.finalizar()


def parede_concreto_baixa():
    """Mureta de 2 de largura por 0,35 de altura, para o lado da câmera.

    Fecha a sala sem esconder o jogador. A faixa amarela avisa que ali não passa.
    """
    m = kit.Modelo("parede_concreto_baixa")
    m.caixa((2.0, 0.3, 0.3), pos=(0, 0, 0), cor="chumbo", chanfro=0.03)
    m.caixa((2.0, 0.32, 0.06), pos=(0, 0, 0.3), cor="amarelo")
    return m.finalizar()


def parede_pilar():
    """Pilar de canto e de emenda, 0,44 de lado por 2,15 de altura."""
    m = kit.Modelo("parede_pilar")
    m.caixa((0.44, 0.44, 2.05), pos=(0, 0, 0), cor="cinza_medio", degrade=True, chanfro=0.04)
    m.caixa((0.52, 0.52, 0.3), pos=(0, 0, 0), cor="chumbo", chanfro=0.04)
    m.caixa((0.52, 0.52, 0.12), pos=(0, 0, 2.03), cor="cinza_escuro", chanfro=0.03)
    return m.finalizar()


def moldura_de_porta():
    """A moldura fixa em volta da porta: dois batentes e a verga, com a luz de aviso.

    O vão livre tem 2 de largura e 2,2 de altura, o tamanho da folha.
    """
    m = kit.Modelo("moldura_de_porta")
    for x in (-1.2, 1.2):
        m.caixa((0.4, 0.5, 2.3), pos=(x, 0, 0), cor="cinza_escuro", chanfro=0.04)
        m.caixa((0.46, 0.56, 0.3), pos=(x, 0, 0), cor="chumbo", chanfro=0.03)
        m.caixa((0.06, 0.52, 1.6), pos=(x * 0.845, 0, 0.4), cor="amarelo")
    m.caixa((2.8, 0.5, 0.35), pos=(0, 0, 2.3), cor="cinza_escuro", chanfro=0.04)
    m.caixa((0.5, 0.54, 0.12), pos=(0, 0, 2.4), cor="amarelo", brilho=True)
    return m.finalizar()


def movel_porta_de_dungeon():
    """A folha da porta, 2 por 2,2. No jogo ela desce para dentro do chão ao abrir."""
    m = kit.Modelo("movel_porta_de_dungeon")
    m.caixa((2.0, 0.2, 2.2), pos=(0, 0, 0), cor="cinza_medio", degrade=True)
    m.caixa((2.0, 0.26, 0.16), pos=(0, 0, 0), cor="chumbo")
    m.caixa((2.0, 0.26, 0.12), pos=(0, 0, 2.08), cor="chumbo")
    m.caixa((0.08, 0.24, 1.92), pos=(0, 0, 0.16), cor="grafite")
    for x in (-0.5, 0.5):
        m.caixa((0.78, 0.24, 0.5), pos=(x, 0, 1.35), cor="cinza_escuro", chanfro=0.03)
    for indice in range(8):
        cor = "amarelo" if indice % 2 == 0 else "grafite"
        m.caixa((0.25, 0.25, 0.26), pos=(-0.875 + indice * 0.25, 0, 0.5), cor=cor)
    return m.finalizar()


def movel_bau_de_recompensa():
    """Baú de recompensa em duas partes: a base e a tampa, que gira no jogo.

    A tampa tem o pivô na dobradiça de trás (0, 0.3, 0.5), igual à cena do baú.
    """
    raiz = kit.vazio("movel_bau_de_recompensa")
    base = kit.Modelo("Base")
    base.caixa((0.9, 0.6, 0.5), pos=(0, 0, 0), cor="indigo", chanfro=0.03)
    for x in (-0.38, 0.38):
        base.caixa((0.1, 0.64, 0.5), pos=(x, 0, 0), cor="amarelo")
    base.caixa((0.94, 0.64, 0.08), pos=(0, 0, 0), cor="chumbo")
    base.caixa((0.16, 0.05, 0.16), pos=(0, -0.31, 0.3), cor="amarelo", brilho=True)
    base.finalizar(pai=raiz)
    tampa = kit.Modelo("Tampa")
    tampa.caixa((0.94, 0.64, 0.14), pos=(0, -0.3, 0), cor="indigo", chanfro=0.04)
    for x in (-0.38, 0.38):
        tampa.caixa((0.1, 0.66, 0.15), pos=(x, -0.3, 0), cor="amarelo")
    tampa.caixa((0.5, 0.3, 0.03), pos=(0, -0.3, 0.14), cor="azul_claro", brilho=True)
    tampa.finalizar(pai=raiz, pos=(0, 0.3, 0.5))
    return raiz


MODELOS = [
    chao_metal_placa, chao_concreto_placa, chao_grade, chao_faixa_de_aviso,
    parede_concreto, parede_concreto_baixa, parede_pilar,
    moldura_de_porta, movel_porta_de_dungeon, movel_bau_de_recompensa,
]

if __name__ == "__main__":
    kit.produzir(MODELOS, "comum")
