"""Peças do mapa da fazenda: a casa, o galpão, a caixa d'água, a porteira, o espantalho e
a borda dos talhões. Também a cerca de arame, que fecha o mapa da fazenda e trechos do
mundo.

Pacote `cyber_moon_mundo`.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/fazenda.py", run_name="__main__")
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import faixa_de_aviso, olhar_bravo
from casas import janela, porta, vaso, telhado_de_duas_aguas, caixa_dagua_de_telhado, plantinha_de_parede

PACOTE = "cyber_moon_mundo"


def casa_da_fazenda():
    """A casa do jogador: barro claro, telhado de duas águas com painel solar, chaminé,
    varanda de tábua com guarda-corpo, lampião, banco, vasos e as botas na porta. Frente em
    -Y, para a câmera. Pegada igual à de antes (6 por 4,4 e a varanda até -3,4), para a
    cama, o calendário e os baús continuarem no lugar."""
    m = kit.Modelo("casa_da_fazenda")
    largura, profundidade, altura = 6.0, 4.2, 2.4
    centro_y = 0.2
    m.caixa((largura + 0.4, profundidade + 0.6, 0.18), pos=(0, centro_y, 0), cor="cinza_medio", chanfro=0.03)
    m.caixa((largura, profundidade, altura), pos=(0, centro_y, 0.18), cor="creme", chanfro=0.08, degrade=True)
    m.caixa((largura + 0.04, profundidade + 0.04, 0.25), pos=(0, centro_y, 0.18), cor="ferrugem")
    for x in (-largura / 2, largura / 2):
        for y in (centro_y - profundidade / 2, centro_y + profundidade / 2):
            m.caixa((0.16, 0.16, altura), pos=(x, y, 0.18), cor="marrom")
    frente = centro_y - profundidade / 2
    # Porta com degrau, duas janelas acesas com cortina e floreira.
    porta(m, -0.8, frente, largura=0.9, altura=1.5, cor="marrom", macaneta="amarelo")
    janela(m, 1.0, frente, 1.2, largura=0.85, altura=0.7, cortina="verde")
    janela(m, 2.25, frente, 1.2, largura=0.6, altura=0.7, cortina="verde")
    janela(m, -2.25, frente, 1.2, largura=0.6, altura=0.7, cortina="verde")
    plantinha_de_parede(m, 1.0, frente - 0.12, 0.72)
    plantinha_de_parede(m, -2.25, frente - 0.12, 0.72)
    # O número da casa e a luminária da porta.
    m.caixa((0.3, 0.05, 0.2), pos=(-0.8, frente - 0.04, 1.85), cor="azul_claro", brilho=True)
    # Telhado de duas águas, de telha ferrugem, com painel solar na água da frente.
    telhado_de_duas_aguas(m, largura, profundidade, 2.58, altura=1.2, cor="ferrugem", beiral=0.3, centro=(0, centro_y))
    # A água da frente cai de 1,2 em 2,4 (uns 27 graus). O painel deita nela, um pouco
    # acima da telha, com as linhas das células por cima.
    inclinacao = math.degrees(math.atan2(1.2, profundidade / 2 + 0.3))
    for indice in range(3):
        painel = m.caixa((1.1, 1.3, 0.06), pos=(0, 0, 0), cor="indigo")
        m.mover(painel, rot=(inclinacao, 0, 0))
        m.mover(painel, pos=(-1.6 + indice * 1.2, centro_y - 1.1, 3.33))
        for k in range(3):
            linha = m.caixa((1.1, 0.03, 0.02), pos=(0, -0.4 + k * 0.4, 0.04), cor="azul_claro")
            m.mover(linha, rot=(inclinacao, 0, 0))
            m.mover(linha, pos=(-1.6 + indice * 1.2, centro_y - 1.1, 3.33))
    # Chaminé atrás e a caixa d'água no telhado.
    m.caixa((0.5, 0.5, 1.4), pos=(1.9, centro_y + 0.9, 2.9), cor="salmao", chanfro=0.03)
    m.caixa((0.6, 0.6, 0.12), pos=(1.9, centro_y + 0.9, 4.3), cor="chumbo")
    caixa_dagua_de_telhado(m, -2.1, centro_y + 1.2, 3.0)
    # Varanda: piso de tábua, esteios, guarda-corpo com o vão da escada e o toldo de chapa.
    m.caixa((largura + 0.4, 1.5, 0.14), pos=(0, frente - 0.75, 0.0), cor="marrom")
    for indice in range(9):
        m.caixa((0.03, 1.5, 0.15), pos=(-largura / 2 + 0.3 + indice * 0.7, frente - 0.75, 0.0), cor="ferrugem")
    for x in (-3.0, -1.0, 1.0, 3.0):
        m.caixa((0.14, 0.14, 2.4), pos=(x, frente - 1.4, 0.14), cor="marrom", chanfro=0.02)
    for x1, x2 in ((-3.0, -1.35), (-0.25, 3.0)):
        meio, tamanho = (x1 + x2) / 2, x2 - x1
        m.caixa((tamanho, 0.08, 0.08), pos=(meio, frente - 1.4, 0.75), cor="marrom")
        for k in range(int(tamanho / 0.3)):
            m.caixa((0.05, 0.05, 0.6), pos=(x1 + 0.15 + k * 0.3, frente - 1.4, 0.14), cor="ferrugem")
    m.caixa((1.0, 0.4, 0.08), pos=(-0.8, frente - 1.7, 0.0), cor="marrom")
    toldo_de_chapa = m.caixa((largura + 0.5, 1.7, 0.08), pos=(0, 0, 0), cor="laranja")
    m.mover(toldo_de_chapa, rot=(-10, 0, 0))
    m.mover(toldo_de_chapa, pos=(0, frente - 0.75, 2.5))
    for indice in range(12):
        onda = m.caixa((0.05, 1.7, 0.03), pos=(0, 0, 0.05), cor="coral")
        m.mover(onda, rot=(-10, 0, 0))
        m.mover(onda, pos=(-largura / 2 + 0.05 + indice * 0.52, frente - 0.75, 2.5))
    # O lampião pendurado, o banco, os vasos, o regador e as botas na porta.
    m.cilindro(0.02, 0.35, pos=(0.2, frente - 1.1, 2.05), cor="grafite", lados=4)
    m.cilindro(0.12, 0.22, pos=(0.2, frente - 1.1, 1.85), cor="amarelo", lados=6, brilho=True)
    m.caixa((1.2, 0.4, 0.08), pos=(1.9, frente - 0.4, 0.48), cor="marrom", chanfro=0.02)
    for x in (1.4, 2.4):
        m.caixa((0.08, 0.36, 0.34), pos=(x, frente - 0.4, 0.14), cor="ferrugem")
    m.caixa((1.2, 0.06, 0.4), pos=(1.9, frente - 0.2, 0.56), cor="marrom")
    for x, cor in ((-2.7, "coral"), (-1.9, "ferrugem"), (2.75, "salmao")):
        vaso(m, x, frente - 1.05, z=0.14, cor_do_vaso=cor)
    m.cilindro(0.12, 0.2, pos=(-1.55, frente - 0.35, 0.14), cor="azul", lados=8)
    m.cilindro(0.03, 0.2, pos=(-1.42, frente - 0.35, 0.3), cor="azul", lados=4, rot=(0, 50, 0))
    for dx in (0.0, 0.16):
        m.caixa((0.12, 0.22, 0.18), pos=(0.0 + dx, frente - 0.3, 0.14), cor="grafite", chanfro=0.02)
    # Do lado direito, a bateria do painel com o cabo subindo.
    m.caixa((0.6, 0.5, 0.8), pos=(largura / 2 + 0.35, centro_y - 0.6, 0.18), cor="cinza_metal", chanfro=0.04)
    m.caixa((0.25, 0.05, 0.12), pos=(largura / 2 + 0.35, centro_y - 0.86, 0.75), cor="verde", brilho=True)
    m.cilindro(0.025, 2.3, pos=(largura / 2 + 0.6, centro_y - 0.6, 0.9), cor="grafite", lados=4)
    return m.finalizar()


def galpao_da_fazenda():
    """O galpão de chapa onde ficam os baús e as ferramentas: chapa ondulada com ferrugem,
    porta de correr com faixa de aviso, exaustor no telhado, janela alta, lâmpada sobre a
    porta e um puxadinho do lado com as ferramentas penduradas. Pegada de 4,2 por 3,2."""
    m = kit.Modelo("galpao_da_fazenda")
    m.caixa((4.4, 3.4, 0.15), cor="cinza_medio", chanfro=0.03)
    m.caixa((4.0, 3.0, 2.3), pos=(0, 0, 0.15), cor="cinza_metal", degrade=True)
    for indice in range(16):
        x = -1.875 + indice * 0.25
        m.caixa((0.05, 3.02, 2.3), pos=(x, 0, 0.15), cor="cinza_medio")
    for x in (-2.0, 2.0):
        for indice in range(12):
            m.caixa((0.05, 0.05, 2.3), pos=(x, -1.375 + indice * 0.25, 0.15), cor="cinza_medio")
    # Manchas de ferrugem na chapa.
    for x, z, tamanho in ((-1.5, 0.4, 0.5), (1.6, 1.6, 0.35), (-0.9, 1.9, 0.3)):
        m.caixa((tamanho, 0.04, tamanho * 0.8), pos=(x, -1.52, z), cor="ferrugem")
    # Telhado de duas águas de chapa e o exaustor.
    m.prisma([(-2.3, 0.0), (2.3, 0.0), (0.0, 0.8)], 3.4, pos=(0, 0, 2.45), cor="ferrugem")
    for indice in range(9):
        y = -1.6 + indice * 0.4
        for lado in (-1, 1):
            onda = m.caixa((2.45, 0.05, 0.03), pos=(0, 0, 0), cor="coral")
            m.mover(onda, rot=(0, lado * 19.2, 0))
            m.mover(onda, pos=(lado * 1.15, y, 2.86))
    m.cilindro(0.08, 0.3, pos=(0.6, 0, 3.15), cor="cinza_escuro", lados=6)
    m.esfera(0.25, pos=(0.6, 0, 3.5), cor="cinza_metal", escala=(1, 1, 0.8), subdivisoes=1)
    # A porta de correr no trilho, com a faixa de aviso e o puxador.
    m.caixa((2.4, 0.1, 0.1), pos=(0, -1.6, 2.15), cor="grafite")
    m.caixa((1.7, 0.08, 1.95), pos=(-0.15, -1.56, 0.15), cor="cinza_escuro")
    for indice in range(5):
        m.caixa((0.04, 0.09, 1.95), pos=(-0.85 + indice * 0.35, -1.57, 0.15), cor="grafite")
    faixa_de_aviso(m, 1.7, (-0.15, -1.62, 1.85), altura=0.12, partes=7)
    m.caixa((0.06, 0.06, 0.4), pos=(0.55, -1.64, 0.85), cor="amarelo")
    m.cilindro(0.06, 0.12, pos=(0, -1.65, 2.25), cor="amarelo", lados=6, brilho=True)
    m.caixa((0.6, 0.06, 0.4), pos=(1.35, -1.53, 1.6), cor="azul_palido")
    m.caixa((0.7, 0.07, 0.06), pos=(1.35, -1.55, 1.38), cor="grafite")
    # O puxadinho do lado direito: telhado de uma água, ferramentas e caixotes.
    puxadinho = m.caixa((1.2, 2.4, 0.06), pos=(0, 0, 0), cor="cinza_metal")
    m.mover(puxadinho, rot=(0, -12, 0))
    m.mover(puxadinho, pos=(2.6, 0, 1.8))
    for y in (-1.1, 1.1):
        m.caixa((0.08, 0.08, 1.75), pos=(3.15, y, 0.0), cor="marrom")
    m.caixa((0.05, 2.2, 0.05), pos=(2.06, 0, 1.5), cor="marrom")
    for y, cor in ((-0.6, "cinza_metal"), (-0.2, "marrom"), (0.3, "cinza_metal")):
        m.cilindro(0.025, 0.9, pos=(2.1, y, 0.6), cor="marrom", lados=4)
        m.caixa((0.12, 0.18, 0.06), pos=(2.12, y, 0.55), cor=cor)
    for x, y, z, cor in ((2.6, 0.6, 0.0, "marrom"), (2.65, 0.6, 0.42, "ferrugem"), (2.6, -0.9, 0.0, "marrom")):
        m.caixa((0.55, 0.45, 0.42), pos=(x, y, z), cor=cor, chanfro=0.03)
    return m.finalizar()


def caixa_dagua_da_fazenda():
    """A caixa d'água em torre, onde o regador enche: quatro pernas com trava em X,
    escada, a caixa azul com o marcador de nível, o cano descendo até a torneira com o
    balde e a bombinha solar do lado."""
    m = kit.Modelo("caixa_dagua_da_fazenda")
    for x in (-0.7, 0.7):
        for y in (-0.7, 0.7):
            m.caixa((0.14, 0.14, 2.6), pos=(x, y, 0), cor="ferrugem", chanfro=0.02)
            m.caixa((0.3, 0.3, 0.12), pos=(x, y, 0), cor="cinza_medio")
    for lado, y in ((1, -0.7), (-1, 0.7)):
        for z in (0.5, 1.6):
            trava = m.caixa((1.95, 0.06, 0.06), pos=(0, 0, 0), cor="marrom")
            m.mover(trava, rot=(0, 34 * lado, 0))
            m.mover(trava, pos=(0, y, z + 0.5))
    for lado, x in ((1, -0.7), (-1, 0.7)):
        trava = m.caixa((0.06, 1.95, 0.06), pos=(0, 0, 0), cor="marrom")
        m.mover(trava, rot=(34 * lado, 0, 0))
        m.mover(trava, pos=(x, 0, 1.1))
    m.caixa((1.7, 1.7, 0.12), pos=(0, 0, 2.6), cor="marrom")
    m.cilindro(1.0, 1.5, pos=(0, 0, 2.72), cor="azul", lados=12, degrade=True, cor_das_tampas="cinza_medio")
    m.cilindro(1.05, 0.25, pos=(0, 0, 4.22), cor="cinza_medio", lados=12, raio_do_topo=0.3)
    for z in (3.0, 3.8):
        m.cilindro(1.02, 0.08, pos=(0, 0, z), cor="cinza_escuro", lados=12)
    m.caixa((0.08, 0.05, 1.2), pos=(-0.35, -0.98, 2.85), cor="azul_palido")
    m.caixa((0.1, 0.06, 0.7), pos=(-0.35, -1.0, 2.85), cor="azul_claro", brilho=True)
    # A escada na lateral.
    for x in (0.55, 0.85):
        m.caixa((0.05, 0.05, 4.1), pos=(x + 0.4, -0.2, 0), cor="cinza_metal")
    for z in range(13):
        m.caixa((0.35, 0.04, 0.04), pos=(1.1, -0.2, 0.25 + z * 0.3), cor="cinza_metal")
    # O cano descendo até a torneira, com o balde embaixo.
    m.cilindro(0.06, 2.6, pos=(0.0, -0.95, 0.4), cor="cinza_metal", lados=6)
    m.caixa((0.06, 0.4, 0.06), pos=(0.0, -1.15, 0.4), cor="cinza_metal")
    m.cilindro(0.08, 0.1, pos=(0.0, -1.33, 0.48), cor="amarelo", lados=6, rot=(90, 0, 0))
    m.cilindro(0.18, 0.28, pos=(0.0, -1.35, 0.0), cor="cinza_medio", lados=8, raio_do_topo=0.22)
    m.cilindro(0.17, 0.02, pos=(0.0, -1.35, 0.24), cor="azul_claro", lados=8)
    # A bombinha solar.
    m.caixa((0.4, 0.3, 0.35), pos=(-0.9, -0.9, 0.0), cor="cinza_metal", chanfro=0.03)
    painel = m.caixa((0.6, 0.45, 0.04), pos=(0, 0, 0), cor="indigo")
    m.mover(painel, rot=(-30, 0, 0))
    m.mover(painel, pos=(-0.9, -0.9, 0.6))
    m.cilindro(0.025, 0.3, pos=(-0.9, -0.9, 0.35), cor="grafite", lados=4)
    return m.finalizar()


def porteira_da_fazenda():
    """A porteira da fazenda: mourões de tronco com lâmpadas na trave, a placa de neon,
    as duas folhas de tábua com trava em diagonal, abertas, vasos no pé dos mourões e a
    roda de carroça encostada. O vão tem 4 de largura. É a passagem entre a fazenda e o
    mundo."""
    m = kit.Modelo("porteira_da_fazenda")
    for x in (-2.3, 2.3):
        m.cilindro(0.22, 3.0, pos=(x, 0, 0), cor="marrom", lados=8, degrade=True)
        m.cilindro(0.28, 0.25, pos=(x, 0, 0), cor="ferrugem", lados=8)
        m.cilindro(0.26, 0.15, pos=(x, 0, 3.0), cor="ferrugem", lados=8, raio_do_topo=0.1)
    m.caixa((5.4, 0.3, 0.28), pos=(0, 0, 2.7), cor="marrom", chanfro=0.03)
    for x in (-1.8, 1.8):
        trava = m.caixa((0.9, 0.18, 0.14), pos=(0, 0, 0), cor="ferrugem")
        m.mover(trava, rot=(0, 45 if x > 0 else -45, 0))
        m.mover(trava, pos=(x, 0, 2.45))
    for x in (-1.5, -0.5, 0.5, 1.5):
        m.cilindro(0.015, 0.15, pos=(x, -0.1, 2.55), cor="grafite", lados=4)
        m.esfera(0.07, pos=(x, -0.1, 2.5), cor="amarelo", brilho=True)
    m.caixa((2.4, 0.12, 0.7), pos=(0, -0.2, 1.95), cor="preto", chanfro=0.03)
    m.caixa((2.1, 0.14, 0.4), pos=(0, -0.26, 2.1), cor="verde", brilho=True)
    for x in (-0.85, 0.85):
        m.caixa((0.04, 0.04, 0.3), pos=(x, -0.15, 2.65), cor="grafite")
    # As duas folhas de tábua, abertas para dentro.
    for lado in (-1, 1):
        partes = []
        for z in (0.25, 0.65, 1.05):
            partes.append(m.caixa((1.9, 0.07, 0.2), pos=(0, 0, z), cor="marrom"))
        partes.append(m.caixa((0.12, 0.08, 1.2), pos=(-0.9, 0, 0.15), cor="ferrugem"))
        partes.append(m.caixa((0.12, 0.08, 1.2), pos=(0.9, 0, 0.15), cor="ferrugem"))
        diagonal = m.caixa((2.1, 0.06, 0.12), pos=(0, 0, 0), cor="ferrugem")
        m.mover(diagonal, rot=(0, -27 * lado, 0))
        m.mover(diagonal, pos=(0, 0, 0.75))
        for parte in partes + [diagonal]:
            m.mover(parte, pos=(lado * 1.05, 0, 0))
            m.mover(parte, rot=(0, 0, lado * 80))
            m.mover(parte, pos=(lado * 1.25, -0.95 * 0, 0))
    # Vasos no pé dos mourões e a roda de carroça encostada.
    for x in (-2.85, 2.85):
        vaso(m, x, -0.35, cor_do_vaso="coral", altura=0.3)
    roda = m.cilindro(0.45, 0.08, pos=(0, 0, 0), cor="marrom", lados=12)
    raios = [m.caixa((0.85, 0.05, 0.09), pos=(0, 0, 0.0), cor="ferrugem", rot=(0, 0, angulo)) for angulo in (0, 60, 120)]
    for parte in [roda] + raios:
        m.mover(parte, rot=(80, 0, 0))
        m.mover(parte, pos=(3.0, 0.35, 0.45))
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
    """O espantalho da fazenda: um robô velho num poste, de chapéu de palha e poncho
    remendado, com palha saindo das juntas, braço de cano com um trapo, um passarinho no
    ombro e o visor rachado e apagado. Não é inimigo; o olhar é sem brilho."""
    m = kit.Modelo("espantalho_robo")
    m.cilindro(0.06, 1.6, cor="marrom", lados=6)
    m.cilindro(0.18, 0.12, pos=(0, 0, 0), cor="ferrugem", lados=6)
    m.caixa((1.5, 0.08, 0.08), pos=(0, 0, 1.1), cor="marrom")
    # O corpo de lata, coberto pelo poncho remendado.
    m.caixa((0.5, 0.3, 0.55), pos=(0, 0, 0.8), cor="cinza_metal", chanfro=0.05)
    poncho = m.prisma([(-0.42, 0.0), (0.42, 0.0), (0.3, 0.42), (-0.3, 0.42)], 0.38, cor="laranja")
    m.mover(poncho, pos=(0, 0, 0.72))
    for x, z, cor in ((-0.2, 0.85, "pessego"), (0.18, 0.95, "coral"), (0.05, 0.76, "marrom")):
        m.caixa((0.14, 0.03, 0.12), pos=(x, -0.2, z), cor=cor)
    for x in (-0.3, -0.1, 0.12, 0.3):
        m.caixa((0.03, 0.02, 0.14), pos=(x, -0.2, 0.62), cor="creme", rot=(0, (x * 60), 0))
    # A cabeça: visor rachado e apagado, antena torta.
    m.caixa((0.36, 0.32, 0.3), pos=(0, 0, 1.38), cor="cinza_medio", chanfro=0.05)
    m.caixa((0.28, 0.03, 0.1), pos=(0, -0.17, 1.5), cor="grafite")
    racha = m.caixa((0.12, 0.035, 0.015), pos=(0, 0, 0), cor="cinza_escuro", rot=(0, 35, 0))
    m.mover(racha, pos=(0.05, -0.19, 1.55))
    m.caixa((0.06, 0.04, 0.05), pos=(-0.08, -0.17, 1.42), cor="chumbo")
    antena = m.cilindro(0.015, 0.3, cor="grafite", lados=4, rot=(0, 20, 0))
    m.mover(antena, pos=(0.12, 0.05, 1.68))
    m.esfera(0.03, pos=(0.22, 0.05, 1.97), cor="chumbo")
    # O chapéu de palha, com fiapos na aba.
    m.cilindro(0.4, 0.05, pos=(0, 0, 1.68), cor="amarelo", lados=12)
    m.cilindro(0.18, 0.2, pos=(0, 0, 1.72), cor="amarelo", lados=10, raio_do_topo=0.14)
    m.cilindro(0.185, 0.05, pos=(0, 0, 1.76), cor="laranja", lados=10)
    for angulo in range(0, 360, 40):
        fiapo = m.caixa((0.1, 0.015, 0.012), pos=(0.42, 0, 0), cor="creme")
        m.mover(fiapo, pos=(0, 0, 1.69), rot=(0, 0, angulo))
    # Os braços de cano, a palha saindo das juntas e o trapo pendurado.
    for lado in (-1, 1):
        m.cilindro(0.06, 0.45, pos=(lado * 0.72, 0, 0.75), cor="cinza_metal", lados=6)
        m.cilindro(0.075, 0.08, pos=(lado * 0.72, 0, 1.06), cor="chumbo", lados=6)
        for k in range(3):
            palha = m.caixa((0.02, 0.02, 0.16), pos=(0, 0, 0), cor="amarelo", rot=(0, 25 * (k - 1), 0))
            m.mover(palha, pos=(lado * 0.72 + (k - 1) * 0.03, 0, 0.62))
    m.caixa((0.25, 0.02, 0.35), pos=(-0.55, -0.05, 0.75), cor="azul_palido", rot=(0, 8, 0))
    # O passarinho no ombro, que não tem medo do espantalho.
    m.esfera(0.06, pos=(0.5, 0, 1.2), cor="grafite", escala=(1.3, 1, 0.9))
    m.esfera(0.04, pos=(0.56, 0, 1.26), cor="grafite")
    m.caixa((0.04, 0.015, 0.015), pos=(0.61, 0, 1.26), cor="amarelo")
    m.caixa((0.06, 0.02, 0.03), pos=(0.43, 0, 1.22), cor="grafite", rot=(0, -20, 0))
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
