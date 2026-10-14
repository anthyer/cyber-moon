"""Peças que se repetem nos inimigos das dungeons: olhar, dentes, espinho, serra.

É o vocabulário que deixa uma máquina com cara de ameaça sem sair do estilo: forma
simples, ponta, e um visor aceso inclinado para dentro, como sobrancelha franzida.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit


def faixa_de_aviso(m, largura, pos, altura=0.12, profundidade=0.04, partes=6):
    """Faixa amarela e grafite na horizontal, a marca de perigo do jogo."""
    passo = largura / partes
    for indice in range(partes):
        cor = "amarelo" if indice % 2 == 0 else "grafite"
        x = pos[0] - largura / 2.0 + passo * (indice + 0.5)
        m.caixa((passo, profundidade, altura), pos=(x, pos[1], pos[2]), cor=cor)


def espinho(m, pos, altura, raio=0.05, cor="cinza_metal", rot=(0, 0, 0), lados=5):
    """Cone pontudo com a base em `pos`. Sem `rot`, aponta para cima."""
    return m.cilindro(raio, altura, pos=pos, cor=cor, raio_do_topo=0.0, lados=lados, rot=rot)


def dentes(m, pos, largura, quantidade, tamanho=0.08, cor="branco", para_baixo=False):
    """Fileira de dentes ao longo de X, apontando para cima (ou para baixo)."""
    passo = largura / quantidade
    for indice in range(quantidade):
        x = pos[0] - largura / 2.0 + passo * (indice + 0.5)
        giro = (180, 0, 0) if para_baixo else (0, 0, 0)
        m.cilindro(passo * 0.5, tamanho, pos=(x, pos[1], pos[2]), cor=cor, raio_do_topo=0.0,
                   lados=4, rot=giro)


def olhar_bravo(m, pos, largura=0.3, cor="magenta", altura=0.07):
    """Visor aceso em duas metades inclinadas para o centro, a sobrancelha franzida.

    `pos` é o centro do visor, na face da frente (-Y) da cabeça.
    """
    m.caixa((largura + 0.04, 0.03, altura * 2.2), pos=(pos[0], pos[1] + 0.005, pos[2] - altura * 1.1),
            cor="grafite")
    metade = largura / 2.0
    for sinal in (-1, 1):
        m.caixa((metade * 0.9, 0.035, altura), pos=(pos[0] + sinal * metade * 0.52, pos[1] - 0.012, pos[2] - altura / 2.0),
                cor=cor, brilho=True, rot=(0, sinal * 16, 0))


def serra(m, raio, cor_do_disco="cinza", cor_do_miolo="amarelo", dentes_da_serra=8):
    """Disco de serra deitado, centrado na origem do modelo, para girar em torno de Z."""
    m.cilindro(raio, 0.03, pos=(0, 0, -0.015), cor=cor_do_disco, lados=dentes_da_serra)
    m.cilindro(raio * 0.35, 0.06, pos=(0, 0, -0.03), cor=cor_do_miolo, lados=6)
    for indice in range(dentes_da_serra):
        angulo = 360.0 / dentes_da_serra * indice
        ponta = m.prisma([(0.0, 0.0), (raio * 0.45, 0.0), (0.0, raio * 0.4)], 0.03, cor="branco",
                         rot=(90, 0, 0))
        m.mover(ponta, pos=(raio * 0.86, 0, 0))
        m.mover(ponta, rot=(0, 0, angulo))
