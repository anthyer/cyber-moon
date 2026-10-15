"""Construções do mapa mundi: viaduto, canal, reservatório, entradas das dungeons, vila e
acampamento das motoqueiras.

Pacote `cyber_moon_mundo`. Peça alta (viaduto, letreiro, outdoor, comporta) fica no
norte do mapa ou nas laterais, pela regra da câmera (ver `game/docs/biblia_3d.md`).

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/mundo.py", run_name="__main__")
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import faixa_de_aviso

PACOTE = "cyber_moon_mundo"
ALTURA_DO_VIADUTO = 4.2


# -- viaduto e estrada -------------------------------------------------------------

def viaduto_modulo():
    """Um trecho de 8 do viaduto que leva a Night City: pista no alto, dois pilares e a
    mureta com filete de neon. Vai na borda norte, onde pode ser alto."""
    m = kit.Modelo("viaduto_modulo")
    h = ALTURA_DO_VIADUTO
    m.caixa((8.0, 5.0, 0.6), pos=(0, 0, h), cor="cinza_medio", chanfro=0.06, degrade=True)
    m.caixa((8.0, 4.4, 0.04), pos=(0, 0, h + 0.6), cor="grafite")
    for x in (-3.0, -1.0, 1.0, 3.0):
        m.caixa((1.0, 0.12, 0.012), pos=(x, 0, h + 0.64), cor="amarelo")
    for y in (-2.4, 2.4):
        m.caixa((8.0, 0.25, 0.55), pos=(0, y, h + 0.6), cor="cinza", chanfro=0.03)
        m.caixa((8.0, 0.27, 0.06), pos=(0, y, h + 0.95), cor="magenta" if y < 0 else "azul_claro", brilho=True)
    for x in (-2.0, 2.0):
        m.caixa((1.0, 1.4, h), pos=(x, 0, 0), cor="cinza", chanfro=0.08, degrade=True)
        m.caixa((1.6, 2.6, 0.5), pos=(x, 0, h - 0.5), cor="cinza_medio", chanfro=0.05)
        m.caixa((1.2, 1.6, 0.3), pos=(x, 0, 0), cor="chumbo")
    m.caixa((0.6, 0.05, 1.0), pos=(-2.0, -0.73, 1.2), cor="magenta")
    m.caixa((0.5, 0.05, 0.6), pos=(2.0, -0.73, 1.6), cor="amarelo")
    return m.finalizar()


def ponto_de_onibus():
    """Abrigo do ponto de ônibus, debaixo do viaduto: banco, cobertura e a placa acesa."""
    m = kit.Modelo("ponto_de_onibus")
    for x in (-1.2, 1.2):
        m.caixa((0.1, 0.1, 1.6), pos=(x, 0.45, 0), cor="grafite")
    m.caixa((2.8, 1.2, 0.08), pos=(0, 0.1, 1.6), cor="cinza_escuro", chanfro=0.02)
    m.caixa((2.6, 0.05, 1.1), pos=(0, 0.48, 0.4), cor="azul_palido")
    m.caixa((2.0, 0.4, 0.06), pos=(0, 0.25, 0.4), cor="ferrugem")
    m.caixa((2.0, 0.06, 0.3), pos=(0, 0.42, 0.5), cor="ferrugem")
    m.cilindro(0.05, 2.2, pos=(1.6, -0.3, 0), cor="grafite", lados=6)
    m.caixa((0.55, 0.08, 0.4), pos=(1.6, -0.3, 1.9), cor="azul", brilho=True)
    m.caixa((0.3, 0.09, 0.08), pos=(1.6, -0.3, 2.05), cor="branco", brilho=True)
    return m.finalizar()


def outdoor_neon():
    """Outdoor de neon num poste alto, com a propaganda da corporação."""
    m = kit.Modelo("outdoor_neon")
    for x in (-1.0, 1.0):
        m.cilindro(0.1, 3.2, pos=(x, 0, 0), cor="grafite", lados=6)
    m.caixa((4.0, 0.25, 2.0), pos=(0, 0, 3.0), cor="preto", chanfro=0.04)
    m.caixa((3.7, 0.05, 1.7), pos=(0, -0.14, 3.15), cor="indigo")
    m.prisma([(-0.5, 0.0), (0.5, 0.0), (0.0, 0.85)], 0.06, pos=(-1.1, -0.18, 3.45), cor="magenta", brilho=True)
    for indice, largura in enumerate((1.8, 1.3, 1.6)):
        m.caixa((largura, 0.06, 0.16), pos=(0.4, -0.18, 4.25 - indice * 0.32), cor="azul_claro", brilho=True)
    m.caixa((4.1, 0.6, 0.08), pos=(0, -0.3, 2.95), cor="chumbo")
    return m.finalizar()


def poste_de_luz():
    """Poste de rua com a luminária acesa, para a vila e as estradas."""
    m = kit.Modelo("poste_de_luz")
    m.cilindro(0.14, 0.2, cor="chumbo", lados=8)
    m.cilindro(0.06, 2.8, pos=(0, 0, 0.2), cor="grafite", lados=6)
    m.caixa((0.08, 0.8, 0.08), pos=(0, -0.38, 2.9), cor="grafite")
    m.caixa((0.3, 0.42, 0.12), pos=(0, -0.78, 2.84), cor="chumbo", chanfro=0.02)
    m.caixa((0.24, 0.34, 0.04), pos=(0, -0.78, 2.8), cor="amarelo", brilho=True)
    m.caixa((0.1, 0.03, 0.5), pos=(0, 0.07, 1.2), cor="magenta", brilho=True)
    return m.finalizar()


# -- canal e reservatório -------------------------------------------------------------

def canal_reto():
    """Quatro de canal de concreto, ao longo de Y (norte e sul do mapa).

    As bordas sobem 0,3 do chão: o personagem não sobe degrau, então elas seguram o
    jogador fora da água sem parede invisível.
    """
    m = kit.Modelo("canal_reto")
    # A água fica um fio acima do chão do mapa (que é um plano de areia em y = 0): mais
    # funda, ela some debaixo da areia. As bordas de 0,3 é que dão a ideia de canal.
    m.caixa((2.6, 4.0, 0.03), pos=(0, 0, 0.0), cor="azul")
    for y in (-1.2, 0.4):
        m.caixa((1.6, 0.12, 0.01), pos=(-0.2, y, 0.03), cor="azul_claro")
    for x in (-1.5, 1.5):
        m.caixa((0.4, 4.0, 0.62), pos=(x, 0, -0.32), cor="cinza", chanfro=0.03, cor_do_topo="cinza_medio")
        m.caixa((0.42, 4.0, 0.05), pos=(x, 0, 0.27), cor="amarelo" if x < 0 else "cinza_medio")
    return m.finalizar()


def canal_ponte():
    """Ponte por cima do canal. O tabuleiro fica rente ao chão, onde o jogador já anda."""
    m = kit.Modelo("canal_ponte")
    m.caixa((2.6, 4.0, 0.03), pos=(0, 0, 0.0), cor="azul")
    m.caixa((4.0, 3.0, 0.08), pos=(0, 0, -0.02), cor="cinza_medio", chanfro=0.02)
    for y in (-1.45, 1.45):
        m.caixa((4.0, 0.12, 0.08), pos=(0, y, 0.55), cor="amarelo")
        for x in (-1.8, -0.6, 0.6, 1.8):
            m.caixa((0.08, 0.08, 0.6), pos=(x, y, 0), cor="grafite")
    for x in (-1.5, 1.5):
        for y in (-1.85, 1.85):
            m.caixa((0.4, 0.3, 0.62), pos=(x, y, -0.32), cor="cinza", chanfro=0.03)
    return m.finalizar()


def canal_comporta():
    """A comporta da corporação, por cima do canal: pórtico, a placa de aço e a sirene."""
    m = kit.Modelo("canal_comporta")
    m.caixa((2.6, 4.0, 0.03), pos=(0, 0, 0.0), cor="azul")
    for x in (-1.6, 1.6):
        m.caixa((0.6, 1.0, 3.0), pos=(x, 0, -0.3), cor="cinza_medio", chanfro=0.05, degrade=True)
        m.caixa((0.42, 4.0, 0.62), pos=(x, 0, -0.32), cor="cinza", chanfro=0.03)
    m.caixa((3.8, 1.0, 0.5), pos=(0, 0, 2.7), cor="chumbo", chanfro=0.04)
    m.caixa((2.6, 0.2, 1.6), pos=(0, 0, 1.0), cor="cinza_escuro")
    faixa_de_aviso(m, 2.6, (0, -0.12, 1.1), altura=0.18, partes=8)
    m.cilindro(0.12, 0.16, pos=(1.6, 0, 3.2), cor="amarelo", lados=6, brilho=True)
    m.caixa((0.8, 0.06, 0.3), pos=(-0.8, -0.53, 2.8), cor="magenta", brilho=True)
    return m.finalizar()


def reservatorio_borda():
    """Quatro de borda de reservatório, ao longo de X, com a água para o lado +Y."""
    m = kit.Modelo("reservatorio_borda")
    m.caixa((4.0, 0.5, 0.62), pos=(0, 0, -0.32), cor="cinza", chanfro=0.03, cor_do_topo="cinza_medio")
    m.caixa((4.0, 0.52, 0.05), pos=(0, 0, 0.27), cor="amarelo")
    for x in (-1.5, 0.5):
        m.caixa((0.08, 0.08, 0.5), pos=(x, -0.1, 0.3), cor="grafite")
    return m.finalizar()


def reservatorio_quina():
    """A quina da borda do reservatório."""
    m = kit.Modelo("reservatorio_quina")
    m.caixa((0.5, 0.5, 0.65), pos=(0, 0, -0.32), cor="cinza_medio", chanfro=0.04)
    m.caixa((0.54, 0.54, 0.06), pos=(0, 0, 0.3), cor="amarelo")
    return m.finalizar()


def pier_de_madeira():
    """Píer de 2 por 8 que entra no reservatório. Tem guarda-corpo dos dois lados e na
    ponta: o chão do jogo é um plano, e sem isso daria para sair andando na água."""
    m = kit.Modelo("pier_de_madeira")
    for indice in range(16):
        y = 0.25 + indice * 0.5
        m.caixa((2.0, 0.46, 0.06), pos=(0, y, 0.0), cor="marrom" if indice % 2 else "ferrugem")
    for x in (-0.95, 0.95):
        for y in (0.4, 2.6, 4.8, 7.0, 7.9):
            m.cilindro(0.08, 1.4, pos=(x, y, -0.6), cor="marrom", lados=6)
        m.caixa((0.08, 7.8, 0.08), pos=(x, 4.1, 0.75), cor="ferrugem")
    m.caixa((2.0, 0.08, 0.08), pos=(0, 7.95, 0.75), cor="ferrugem")
    m.cilindro(0.05, 0.9, pos=(0.85, 7.6, 0.0), cor="grafite", lados=5)
    m.caixa((0.3, 0.08, 0.12), pos=(0.85, 7.6, 0.9), cor="amarelo", brilho=True)
    return m.finalizar()


def casa_de_bombas():
    """A casa de bombas do reservatório: galpão baixo de concreto com tubos e luz."""
    m = kit.Modelo("casa_de_bombas")
    m.caixa((3.0, 2.4, 1.8), cor="cinza", chanfro=0.05, degrade=True)
    m.caixa((3.2, 2.6, 0.18), pos=(0, 0, 1.8), cor="cinza_escuro", chanfro=0.04)
    m.caixa((0.9, 0.06, 1.3), pos=(-0.6, -1.22, 0), cor="cinza_escuro")
    faixa_de_aviso(m, 0.9, (-0.6, -1.25, 1.32), altura=0.12, partes=5)
    for x in (0.5, 1.0):
        m.cilindro(0.14, 1.6, pos=(x, 0.6, 0), cor="azul", lados=8)
    m.caixa((0.3, 0.06, 0.2), pos=(0.8, -1.23, 1.4), cor="amarelo", brilho=True)
    return m.finalizar()


# -- entradas das dungeons ---------------------------------------------------------------

def entrada_da_galeria():
    """O alçapão de serviço que desce para a Galeria de Manutenção."""
    m = kit.Modelo("entrada_da_galeria")
    m.caixa((2.4, 2.4, 0.5), cor="cinza_medio", chanfro=0.06)
    m.caixa((1.7, 1.7, 0.06), pos=(0, 0, 0.5), cor="grafite")
    faixa_de_aviso(m, 2.4, (0, -1.21, 0.1), altura=0.24, partes=8)
    tampa = m.caixa((1.6, 0.12, 1.4), pos=(0, 0.85, 0.5), cor="cinza_escuro", chanfro=0.03)
    m.mover(tampa, pos=(0, 0, 0))
    for z in (0.75, 1.15):
        m.caixa((1.6, 0.14, 0.05), pos=(0, 0.85, z), cor="amarelo")
    m.cilindro(0.05, 1.6, pos=(-1.0, -1.0, 0.5), cor="grafite", lados=6)
    m.cilindro(0.1, 0.14, pos=(-1.0, -1.0, 2.1), cor="amarelo", lados=6, brilho=True)
    m.caixa((0.6, 0.06, 0.35), pos=(0.5, -1.22, 0.55), cor="azul_claro", brilho=True)
    return m.finalizar()


def entrada_do_biodomo():
    """As ruínas da estufa onde começa o Biodomo Abandonado: arcos quebrados e a porta."""
    m = kit.Modelo("entrada_do_biodomo")
    m.caixa((6.0, 4.0, 0.25), cor="cinza_medio", chanfro=0.04)
    sorteio = random.Random(4)
    for indice, x in enumerate((-2.4, -1.2, 0.0, 1.2, 2.4)):
        altura = 3.0 if indice % 2 == 0 else 2.2
        if indice == 3:
            altura = 1.2
        for y in (-1.8, 1.8):
            m.caixa((0.14, 0.14, altura), pos=(x, y, 0.25), cor="branco", rot=(sorteio.uniform(-5, 5), 0, 0))
        if indice in (0, 2, 4):
            m.caixa((0.14, 3.7, 0.14), pos=(x, 0, 0.25 + altura), cor="branco")
    m.caixa((2.4, 0.06, 1.4), pos=(-1.2, 1.8, 0.4), cor="azul_palido")
    m.caixa((1.6, 0.06, 1.0), pos=(1.8, -1.8, 0.4), cor="azul_palido", rot=(0, 15, 0))
    m.caixa((1.4, 0.4, 2.0), pos=(0, -1.9, 0.25), cor="cinza_escuro", chanfro=0.03)
    m.caixa((1.0, 0.06, 1.6), pos=(0, -2.12, 0.3), cor="verde", brilho=True)
    for pos in ((-2.0, -1.0, 0.25), (2.2, 0.8, 0.25), (-0.8, 1.2, 0.25)):
        m.esfera(0.5, pos=pos, cor="verde", escala=(1.2, 1.0, 0.8))
    return m.finalizar()


def entrada_da_torre():
    """O elevador ao lado do viaduto que sobe para a Torre de Retransmissão."""
    m = kit.Modelo("entrada_da_torre")
    m.caixa((2.4, 2.4, 0.3), cor="chumbo", chanfro=0.04)
    m.caixa((2.0, 2.0, 4.6), pos=(0, 0, 0.3), cor="grafite", chanfro=0.05, degrade=True)
    m.caixa((1.2, 0.06, 2.0), pos=(0, -1.02, 0.3), cor="indigo")
    m.caixa((0.04, 0.07, 2.0), pos=(0, -1.04, 0.3), cor="azul_claro", brilho=True)
    for z in (2.8, 3.4, 4.0):
        m.caixa((2.04, 2.04, 0.06), pos=(0, 0, z), cor="magenta", brilho=True)
    m.caixa((2.2, 2.2, 0.3), pos=(0, 0, 4.9), cor="chumbo", chanfro=0.03)
    m.cilindro(0.04, 1.2, pos=(0.6, 0.6, 5.2), cor="grafite", lados=4)
    m.esfera(0.08, pos=(0.6, 0.6, 6.4), cor="magenta", brilho=True)
    return m.finalizar()


# -- vila ---------------------------------------------------------------------------------

def letreiro_da_vila():
    """O marco da praça: o letreiro de neon com a lua da vila, num poste alto."""
    m = kit.Modelo("letreiro_da_vila")
    m.cilindro(0.5, 0.4, cor="cinza_medio", lados=8)
    m.cilindro(0.16, 4.2, pos=(0, 0, 0.4), cor="grafite", lados=8)
    m.caixa((3.4, 0.3, 1.5), pos=(0, 0, 4.4), cor="preto", chanfro=0.04)
    m.cilindro(0.6, 0.08, pos=(-0.9, -0.18, 5.15), cor="amarelo", lados=12, rot=(90, 0, 0), brilho=True)
    m.cilindro(0.5, 0.1, pos=(-0.7, -0.2, 5.25), cor="preto", lados=12, rot=(90, 0, 0))
    for indice, largura in enumerate((1.5, 1.1)):
        m.caixa((largura, 0.06, 0.24), pos=(0.65, -0.17, 5.25 - indice * 0.45), cor="magenta" if indice == 0 else "azul_claro",
                brilho=True)
    m.caixa((3.5, 0.32, 0.06), pos=(0, 0, 5.86), cor="magenta", brilho=True)
    return m.finalizar()


def bomba_solar():
    """O poço da praça: tanque, bomba e o painel solar que move a bomba."""
    m = kit.Modelo("bomba_solar")
    m.cilindro(0.8, 0.5, cor="cinza_medio", lados=10, cor_das_tampas="azul")
    m.cilindro(0.82, 0.08, pos=(0, 0, 0.5), cor="amarelo", lados=10)
    m.caixa((0.3, 0.3, 1.0), pos=(0.9, 0, 0), cor="chumbo")
    m.cilindro(0.05, 1.8, pos=(-0.9, 0.3, 0), cor="grafite", lados=6)
    painel = m.caixa((1.2, 0.8, 0.06), pos=(0, 0, 0), cor="indigo")
    m.mover(painel, pos=(-0.9, 0.3, 1.8), rot=(-30, 0, 0))
    m.caixa((0.25, 0.06, 0.12), pos=(0.9, -0.16, 0.8), cor="verde", brilho=True)
    return m.finalizar()


def bar_de_beira_de_estrada():
    """Editado de `kenney_city_kit_commercial/building_b.glb`: o bar da vila.

    O prédio do kit, três vezes maior, repintado de escuro, com o letreiro de neon em
    cima e o toldo listrado.
    """
    m = kit.Modelo("bar_de_beira_de_estrada")
    importados = kit.importar_glb("kenney_city_kit_commercial/building_b.glb")
    for origem in importados:
        if origem.type == "MESH":
            m.malha_de(origem, escala=(3, 3, 3), cor="cinza_escuro")
    kit.apagar(importados)
    m.caixa((2.6, 0.1, 0.7), pos=(0, -1.6, 4.0), cor="preto")
    m.caixa((2.3, 0.12, 0.3), pos=(0, -1.66, 4.25), cor="magenta", brilho=True)
    for indice in range(6):
        cor = "amarelo" if indice % 2 == 0 else "grafite"
        m.caixa((0.42, 0.9, 0.08), pos=(-1.05 + indice * 0.42, -1.85, 2.4), cor=cor, rot=(-15, 0, 0))
    return m.finalizar()


# -- acampamento das motoqueiras ------------------------------------------------------------

def trailer():
    """Trailer das motoqueiras, com faixa, janela acesa e o toldo puxado."""
    m = kit.Modelo("trailer")
    m.caixa((3.4, 1.7, 1.6), pos=(0, 0, 0.35), cor="branco", chanfro=0.18, degrade=True)
    m.caixa((3.42, 1.72, 0.2), pos=(0, 0, 0.8), cor="laranja")
    m.caixa((0.8, 0.05, 0.4), pos=(0.7, -0.86, 1.2), cor="amarelo", brilho=True)
    m.caixa((0.6, 0.05, 1.1), pos=(-0.8, -0.86, 0.4), cor="cinza_escuro")
    for x in (-0.9, 0.9):
        m.cilindro(0.28, 0.2, pos=(x, -0.85, 0.28), cor="grafite", lados=8, rot=(90, 0, 0))
    m.caixa((1.6, 1.2, 0.05), pos=(0.4, -1.4, 1.9), cor="magenta", rot=(8, 0, 0))
    for x in (-0.3, 1.1):
        m.cilindro(0.03, 1.9, pos=(x, -1.95, 0), cor="grafite", lados=4)
    m.caixa((0.5, 0.25, 0.2), pos=(1.95, 0, 0.3), cor="grafite")
    return m.finalizar()


def moto():
    """A moto de uma motoqueira: rígida, pequena, preta com magenta."""
    m = kit.Modelo("moto")
    for y in (-0.42, 0.42):
        m.cilindro(0.2, 0.1, pos=(0, y, 0.2), cor="grafite", lados=10, rot=(0, 90, 0))
        m.mover(m.cilindro(0.2, 0.1, pos=(-0.05, y, 0.2), cor="grafite", lados=10, rot=(0, 90, 0)), pos=(0, 0, 0))
        m.cilindro(0.08, 0.12, pos=(-0.06, y, 0.2), cor="cinza_metal", lados=6, rot=(0, 90, 0))
    m.caixa((0.22, 0.8, 0.22), pos=(0, 0, 0.32), cor="preto", chanfro=0.04)
    m.caixa((0.24, 0.36, 0.14), pos=(0, 0.05, 0.54), cor="magenta", chanfro=0.04)
    m.caixa((0.2, 0.3, 0.08), pos=(0, 0.32, 0.56), cor="grafite")
    m.caixa((0.5, 0.06, 0.06), pos=(0, -0.4, 0.72), cor="cinza_metal")
    m.caixa((0.14, 0.06, 0.1), pos=(0, -0.48, 0.55), cor="amarelo", brilho=True)
    m.caixa((0.12, 0.05, 0.06), pos=(0, 0.6, 0.42), cor="magenta", brilho=True)
    # Medida pela foto: no tamanho de cima ela ficava menor que o personagem.
    m.escalar_tudo(1.3)
    return m.finalizar()


def rampa_de_salto():
    """Rampa de salto improvisada, de chapa e madeira, com a faixa de aviso na boca."""
    m = kit.Modelo("rampa_de_salto")
    m.prisma([(-1.5, 0.0), (1.5, 0.0), (1.5, 0.9), (1.2, 0.9)], 1.8, cor="cinza_metal", rot=(0, 0, 90))
    for y in (-0.95, 0.95):
        m.prisma([(-1.5, 0.0), (1.5, 0.0), (1.5, 0.9)], 0.1, pos=(y * 0.0, 0, 0), cor="ferrugem", rot=(0, 0, 90))
    faixa_de_aviso(m, 1.8, (0, 0, 0.0), altura=0.06, partes=6)
    return m.finalizar()


def pilha_de_pneus():
    """Pneus empilhados, o enfeite de todo ferro-velho."""
    m = kit.Modelo("pilha_de_pneus")
    for indice, (x, y, z) in enumerate(((0, 0, 0), (0.05, 0.02, 0.26), (-0.04, 0, 0.52), (0.75, 0.1, 0))):
        m.cilindro(0.38, 0.24, pos=(x, y, z), cor="grafite", lados=10, cor_das_tampas="preto")
        m.cilindro(0.18, 0.245, pos=(x, y, z), cor="preto", lados=8)
    return m.finalizar()


def muro_grafitado():
    """Muro de 4 com grafite colorido das motoqueiras."""
    m = kit.Modelo("muro_grafitado")
    m.caixa((4.0, 0.3, 1.6), cor="cinza", chanfro=0.03, degrade=True)
    m.caixa((4.0, 0.34, 0.12), pos=(0, 0, 1.6), cor="cinza_escuro")
    pinturas = (("magenta", -1.3, 0.5, 0.9, 0.7), ("amarelo", -0.4, 0.3, 0.7, 1.0), ("azul", 0.6, 0.6, 1.1, 0.6),
                ("verde", 1.4, 0.25, 0.6, 0.8), ("roxo", -1.6, 1.0, 0.5, 0.4))
    for cor, x, z, largura, altura in pinturas:
        m.caixa((largura, 0.02, altura), pos=(x, -0.16, z), cor=cor, rot=(0, (x * 23) % 20 - 10, 0))
    return m.finalizar()


def oficina_das_motoqueiras():
    """A oficina das motoqueiras: galpão de chapa com a porta de garagem aberta, a faixa
    de aviso na boca e o letreiro laranja. A frente é o lado -Y, que vai para a câmera."""
    m = kit.Modelo("oficina_das_motoqueiras")
    m.caixa((5.0, 4.0, 0.15), cor="cinza_medio")
    for x in (-2.4, 2.4):
        m.caixa((0.2, 4.0, 2.6), pos=(x, 0, 0.15), cor="ferrugem", degrade=True)
    m.caixa((5.0, 0.2, 2.6), pos=(0, 1.9, 0.15), cor="ferrugem", degrade=True)
    for indice in range(9):
        m.caixa((0.05, 4.02, 2.6), pos=(-2.0 + indice * 0.5, 0, 0.15), cor="marrom")
    for x in (-1.85, 1.85):
        m.caixa((1.1, 0.2, 2.6), pos=(x, -1.9, 0.15), cor="ferrugem", degrade=True)
    m.caixa((5.0, 0.2, 0.6), pos=(0, -1.9, 2.15), cor="cinza_escuro")
    m.prisma([(-2.7, 0.0), (2.7, 0.0), (0.0, 0.9)], 4.4, pos=(0, 0, 2.75), cor="cinza_metal")
    m.caixa((2.6, 0.06, 0.4), pos=(0, -1.95, 2.0), cor="grafite")
    faixa_de_aviso(m, 2.6, (0, -2.03, 2.0), altura=0.16, partes=8)
    m.caixa((2.4, 0.12, 0.5), pos=(0, -2.05, 2.25), cor="preto")
    m.caixa((2.1, 0.14, 0.26), pos=(0, -2.1, 2.36), cor="laranja", brilho=True)
    m.caixa((1.4, 0.6, 0.8), pos=(-1.6, 1.3, 0.15), cor="grafite")
    m.caixa((1.2, 0.05, 0.3), pos=(-1.6, 0.98, 0.7), cor="azul_claro", brilho=True)
    return m.finalizar()


def cata_vento_enferrujado():
    """Editado de `kenney_city_kit_industrial/windmill.glb`: o cata-vento da corporação,
    ferrugem e torto, o marco das fazendas solares."""
    m = kit.Modelo("cata_vento_enferrujado")
    importados = kit.importar_glb("kenney_city_kit_industrial/windmill.glb")
    for origem in importados:
        if origem.type == "MESH":
            m.malha_de(origem, escala=(4, 4, 4), rot=(4, 3, 0), cor={"": "ferrugem"})
    kit.apagar(importados)
    m.cilindro(1.0, 0.2, cor="cinza_medio", lados=8)
    return m.finalizar()


MODELOS = [
    viaduto_modulo, ponto_de_onibus, outdoor_neon, poste_de_luz,
    canal_reto, canal_ponte, canal_comporta, reservatorio_borda, reservatorio_quina, pier_de_madeira,
    casa_de_bombas, entrada_da_galeria, entrada_do_biodomo, entrada_da_torre,
    letreiro_da_vila, bomba_solar, bar_de_beira_de_estrada,
    trailer, moto, rampa_de_salto, pilha_de_pneus, muro_grafitado, oficina_das_motoqueiras,
    cata_vento_enferrujado,
]

if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.produzir(MODELOS, "mundo")
