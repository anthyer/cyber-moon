"""Os marcos novos do mapa mundi orgânico e o que enche a paisagem em volta deles.

Cada um é um ponto de referência: o jogador não gira a câmera, então precisa ver um
destes a cada poucos passos para saber onde está (plano 26, segunda versão).

Pacote `cyber_moon_mundo`.
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import faixa_de_aviso, olhar_bravo

PACOTE = "cyber_moon_mundo"


def _rochedo(nome, largura, profundidade, altura, semente, camadas=4):
    """Formação de rocha em camadas de contorno irregular, como as mesas, mas com o topo
    torto e pedras soltas no pé. Varia pela semente."""
    m = kit.Modelo(nome)
    sorteio = random.Random(semente)
    z = 0.0
    for indice in range(camadas):
        espessura = altura / camadas * sorteio.uniform(0.8, 1.2)
        encolhe = 1.0 - 0.12 * indice - sorteio.uniform(0.0, 0.08)
        pontos = []
        for k in range(10):
            angulo = math.tau * k / 10
            fator = sorteio.uniform(0.78, 1.15)
            pontos.append((math.cos(angulo) * largura * 0.5 * encolhe * fator, math.sin(angulo) * profundidade * 0.5 * encolhe * fator))
        camada = m.prisma(pontos, espessura + 0.04, cor=("ferrugem", "salmao", "ferrugem", "pessego", "salmao")[indice % 5],
                          rot=(90, 0, 0), degrade=True)
        m.mover(camada, pos=(sorteio.uniform(-0.15, 0.15) * largura, sorteio.uniform(-0.15, 0.15) * profundidade, z + espessura / 2))
        z += espessura
    for k in range(5):
        angulo = sorteio.uniform(0, math.tau)
        tamanho = sorteio.uniform(0.25, 0.55) * min(largura, profundidade) * 0.4
        m.esfera(tamanho, pos=(math.cos(angulo) * largura * 0.55, math.sin(angulo) * profundidade * 0.55, tamanho * 0.25),
                 cor="ferrugem", escala=(1.2, 0.9, 0.6), subdivisoes=1)
    if sorteio.random() < 0.6:
        m.cilindro(0.12, 0.5, pos=(sorteio.uniform(-0.2, 0.2) * largura, 0, z), cor="verde", lados=6)
    return m


def rochedo_a():
    """Rochedo alto e estreito, de 2,5 por 2 e 4 de altura."""
    return _rochedo("rochedo_a", 2.5, 2.0, 4.0, 11, camadas=5).finalizar()


def rochedo_b():
    """Rochedo largo e baixo, de 4,5 por 3 e 1,8 de altura."""
    return _rochedo("rochedo_b", 4.5, 3.0, 1.8, 12, camadas=3).finalizar()


def rochedo_c():
    """Rochedo médio, de 3 por 3 e 2,8 de altura."""
    return _rochedo("rochedo_c", 3.0, 3.0, 2.8, 13, camadas=4).finalizar()


def rochedo_d():
    """Paredão comprido, de 7 por 2,5 e 3,5 de altura, para fechar borda."""
    return _rochedo("rochedo_d", 7.0, 2.5, 3.5, 14, camadas=4).finalizar()


def rochas_baixas():
    """Grupo de rochas baixas e redondas, de 2 por 1,5. O enfeite que mais se repete."""
    m = kit.Modelo("rochas_baixas")
    sorteio = random.Random(15)
    for k in range(4):
        tamanho = sorteio.uniform(0.3, 0.6)
        m.esfera(tamanho, pos=(sorteio.uniform(-0.8, 0.8), sorteio.uniform(-0.5, 0.5), tamanho * 0.3),
                 cor=("ferrugem", "salmao")[k % 2], escala=(1.3, 1.0, 0.65), subdivisoes=1)
    return m.finalizar()


def cisterna_velha():
    """A cisterna de concreto da corporação, rachada, com escada e um mirante em cima.
    Alta (5), vista de longe: o marco do sul do bairro."""
    m = kit.Modelo("cisterna_velha")
    m.cilindro(2.2, 0.3, cor="cinza_medio", lados=14)
    m.cilindro(2.0, 3.6, pos=(0, 0, 0.3), cor="cinza", lados=14, degrade=True)
    for z in (1.2, 2.4):
        m.cilindro(2.04, 0.12, pos=(0, 0, z), cor="cinza_escuro", lados=14)
    m.cilindro(2.15, 0.25, pos=(0, 0, 3.9), cor="chumbo", lados=14)
    m.cilindro(1.0, 0.8, pos=(0, 0, 4.15), cor="cinza_medio", lados=10, raio_do_topo=0.7)
    for k in range(6):
        rachado = m.caixa((0.05, 0.03, 0.9), pos=(0, -2.01, 0.6 + k * 0.4), cor="grafite", rot=(0, 25 if k % 2 else -25, 0))
        m.mover(rachado, rot=(0, 0, -20))
    for z in range(10):
        m.caixa((0.6, 0.06, 0.05), pos=(1.0, -1.85, 0.4 + z * 0.38), cor="ferrugem", rot=(0, 0, 25))
    for dx in (0.72, 1.28):
        m.caixa((0.05, 0.06, 3.8), pos=(dx, -1.85, 0.3), cor="ferrugem", rot=(0, 0, 25))
    for k in range(10):
        angulo = k * 36
        poste = m.caixa((0.05, 0.05, 0.6), pos=(2.0, 0, 4.15), cor="grafite")
        m.mover(poste, rot=(0, 0, angulo))
    m.cilindro(2.05, 0.05, pos=(0, 0, 4.7), cor="amarelo", lados=14)
    m.caixa((1.6, 0.1, 0.5), pos=(-0.6, -2.02, 2.6), cor="azul")
    m.caixa((1.3, 0.11, 0.25), pos=(-0.6, -2.04, 2.7), cor="branco")
    return m.finalizar()


def poco_de_petroleo():
    """Poço de petróleo parado (o cavalo-de-pau): base, torre em A e o braço com a cabeça.
    O marco do campo solar sul."""
    m = kit.Modelo("poco_de_petroleo")
    m.caixa((4.0, 1.6, 0.3), cor="cinza_medio", chanfro=0.04)
    for y in (-0.5, 0.5):
        perna = m.caixa((0.15, 0.15, 2.6), pos=(0, 0, 0), cor="amarelo")
        m.mover(perna, rot=(-12 if y < 0 else 12, 0, 0))
        m.mover(perna, pos=(0.3, y, 0.3))
    braco = m.caixa((3.6, 0.3, 0.3), pos=(0, 0, 0), cor="amarelo", chanfro=0.03)
    m.mover(braco, rot=(0, 10, 0))
    m.mover(braco, pos=(0.3, 0, 2.75))
    cabeca = m.prisma([(-0.2, -0.6), (0.4, -0.6), (0.4, 0.6), (-0.2, 0.6)], 0.4, cor="grafite")
    m.mover(cabeca, rot=(0, 10, 0))
    m.mover(cabeca, pos=(-1.6, 0, 3.0))
    m.cilindro(0.04, 2.4, pos=(-1.75, 0, 0.3), cor="grafite", lados=4)
    m.caixa((1.0, 1.0, 0.8), pos=(1.3, 0, 0.3), cor="chumbo", chanfro=0.04)
    m.cilindro(0.35, 0.15, pos=(1.3, -0.55, 0.7), cor="cinza_metal", lados=8, rot=(90, 0, 0))
    faixa_de_aviso(m, 4.0, (0, -0.81, 0.05), altura=0.18, partes=10)
    return m.finalizar()


def onibus_abandonado():
    """Ônibus velho sem rodas, virado bar das motoqueiras: grafite, toldo e luzinhas."""
    m = kit.Modelo("onibus_abandonado")
    for x in (-2.2, 2.2):
        for y in (-0.7, 0.7):
            m.caixa((0.4, 0.3, 0.3), pos=(x, y, 0), cor="cinza_medio")
    m.caixa((6.0, 1.8, 1.8), pos=(0, 0, 0.3), cor="amarelo", chanfro=0.2, degrade=True)
    m.caixa((6.02, 1.82, 0.25), pos=(0, 0, 0.55), cor="grafite")
    for x in (-2.1, -1.2, -0.3, 0.6, 1.5):
        m.caixa((0.75, 0.05, 0.6), pos=(x, -0.91, 1.25), cor="amarelo" if x < 0 else "azul_palido", brilho=x < 0)
    m.caixa((0.5, 0.05, 1.3), pos=(2.4, -0.91, 0.5), cor="grafite")
    for x, cor, w in ((-1.5, "magenta", 1.2), (0.3, "azul", 0.9), (1.4, "verde", 0.7)):
        m.caixa((w, 0.05, 0.4), pos=(x, -0.92, 0.75), cor=cor)
    toldo = m.caixa((3.0, 1.4, 0.05), pos=(0, 0, 0), cor="magenta")
    m.mover(toldo, rot=(-15, 0, 0))
    m.mover(toldo, pos=(-0.6, -1.6, 2.0))
    for x in (-2.0, 0.8):
        m.cilindro(0.04, 1.85, pos=(x, -2.25, 0), cor="grafite", lados=4)
    for k in range(8):
        m.esfera(0.05, pos=(-2.0 + k * 0.4, -2.2, 1.8 - 0.1 * math.sin(k * 0.8)), cor=("amarelo", "magenta", "azul_claro")[k % 3], brilho=True)
    return m.finalizar()


def guindaste_da_pedreira():
    """O guindaste de treliça da pedreira, parado com a caçamba pendurada. Alto, fica
    nas Badlands, no nordeste."""
    m = kit.Modelo("guindaste_da_pedreira")
    m.caixa((2.4, 2.4, 0.6), cor="amarelo", chanfro=0.05)
    m.caixa((1.6, 1.2, 1.2), pos=(-0.2, 0.3, 0.6), cor="amarelo", chanfro=0.05)
    m.caixa((0.6, 0.05, 0.5), pos=(-0.4, -0.31, 1.1), cor="azul_palido")
    for k in range(8):
        altura = 1.8 + k * 0.7
        for dx in (-0.25, 0.25):
            m.caixa((0.06, 0.06, 0.72), pos=(0.6 + dx, 0.0, altura - 0.35), cor="laranja")
        m.caixa((0.56, 0.05, 0.05), pos=(0.6, 0, altura), cor="laranja", rot=(0, 30 if k % 2 else -30, 0))
    braco = m.caixa((5.5, 0.2, 0.2), pos=(0, 0, 0), cor="laranja")
    m.mover(braco, rot=(0, -18, 0))
    m.mover(braco, pos=(3.0, 0, 7.2))
    m.cilindro(0.02, 2.6, pos=(5.5, 0, 5.4), cor="grafite", lados=4)
    m.prisma([(-0.4, 0.0), (0.4, 0.0), (0.3, 0.5), (-0.3, 0.5)], 0.6, pos=(5.5, 0, 4.9), cor="grafite")
    return m.finalizar()


def costela_gigante():
    """A ossada de um bicho enorme no Campo de ossos: costelas em arco e o crânio."""
    m = kit.Modelo("costela_gigante")
    # Cada costela é um arco de contas facetadas encostadas umas nas outras: com caixas
    # inclinadas o arco abria frestas, com contas ele fica contínuo de qualquer ângulo.
    for k in range(6):
        x = -2.5 + k * 1.0
        raio = 1.7 - k * 0.15
        for passo in range(22):
            angulo = math.radians(-95 + passo * 9)
            m.esfera(0.2, pos=(x, raio * math.sin(angulo), raio * math.cos(angulo) * 0.9 + 0.15), cor="branco", subdivisoes=0)
    m.caixa((6.0, 0.25, 0.25), pos=(0, 0, 0.0), cor="creme")
    m.esfera(0.9, pos=(3.6, 0, 0.5), cor="creme", escala=(1.3, 0.9, 0.7))
    for lado in (-1, 1):
        m.cilindro(0.15, 1.1, pos=(3.8, lado * 0.6, 0.8), cor="creme", lados=5, raio_do_topo=0.0, rot=(lado * -60, 0, 0))
        m.caixa((0.25, 0.05, 0.2), pos=(4.4, lado * 0.25, 0.65), cor="grafite")
    return m.finalizar()


def carcaca_de_drone():
    """A carcaça de um drone de carga da corporação, caído e meio enterrado na areia,
    com a hélice torta e o visor apagado. O marco da Reserva das raposas."""
    m = kit.Modelo("carcaca_de_drone")
    corpo = m.caixa((3.4, 2.0, 1.1), pos=(0, 0, 0), cor="cinza_metal", chanfro=0.18, degrade=True)
    m.mover(corpo, rot=(8, -12, 20))
    m.mover(corpo, pos=(0, 0, -0.2))
    m.caixa((1.2, 0.06, 0.4), pos=(-0.6, -1.0, 0.55), cor="grafite", rot=(8, 0, 20))
    m.caixa((1.6, 0.06, 0.3), pos=(0.6, -1.05, 0.2), cor="magenta", rot=(8, 0, 20))
    for x, y, angulo in ((-1.8, 1.4, 40), (1.9, 1.3, -30), (2.1, -1.2, 70)):
        m.cilindro(0.12, 0.6, pos=(x, y, 0), cor="grafite", lados=6, rot=(0, angulo * 0.3, 0))
        helice = m.caixa((1.6, 0.18, 0.04), pos=(0, 0, 0), cor="cinza")
        m.mover(helice, rot=(angulo * 0.2, 10, angulo))
        m.mover(helice, pos=(x, y, 0.6))
    for k in range(3):
        m.esfera(0.4, pos=(-0.5 + k * 0.6, 1.1, 0.0), cor="pessego", escala=(1.5, 1.0, 0.5))
    return m.finalizar()


def cerca_de_sucata():
    """Quatro de cerca feita de chapa, palete e arame: fecha as reservas."""
    m = kit.Modelo("cerca_de_sucata")
    for x in (-1.9, 0.0, 1.9):
        m.caixa((0.14, 0.14, 1.3), pos=(x, 0, 0), cor="marrom")
    for x, w, h, cor in ((-0.95, 1.7, 0.9, "cinza_metal"), (0.95, 1.7, 0.75, "ferrugem")):
        m.caixa((w, 0.05, h), pos=(x, 0.05, 0.15), cor=cor)
    for z in (1.05, 1.25):
        m.caixa((4.0, 0.03, 0.03), pos=(0, 0, z), cor="grafite")
    m.caixa((0.6, 0.06, 0.3), pos=(1.2, -0.02, 0.6), cor="amarelo")
    return m.finalizar()


def poste_de_energia():
    """Poste de madeira com cruzeta e isoladores; em fila ao longo das trilhas."""
    m = kit.Modelo("poste_de_energia")
    m.cilindro(0.1, 4.2, cor="marrom", lados=6)
    m.caixa((1.6, 0.1, 0.1), pos=(0, 0, 3.8), cor="marrom")
    for x in (-0.7, 0.0, 0.7):
        m.cilindro(0.05, 0.14, pos=(x, 0, 3.9), cor="verde", lados=5)
    m.caixa((0.25, 0.2, 0.3), pos=(0, -0.12, 3.2), cor="cinza_medio")
    return m.finalizar()


def enfeite_rachadura():
    """Rachaduras rasas no chão de terra, rente ao chão. Sem colisão."""
    m = kit.Modelo("enfeite_rachadura")
    sorteio = random.Random(21)
    for k in range(9):
        x, y = sorteio.uniform(-1.2, 1.2), sorteio.uniform(-1.2, 1.2)
        comprimento = sorteio.uniform(0.6, 1.4)
        m.caixa((comprimento, 0.05, 0.012), pos=(x, y, 0.0), cor="marrom", rot=(0, 0, sorteio.uniform(0, 180)))
    return m.finalizar()


def enfeite_ossos():
    """Ossos espalhados: uma costela e dois ossos compridos. Sem colisão."""
    m = kit.Modelo("enfeite_ossos")
    m.caixa((0.6, 0.07, 0.06), pos=(0, 0, 0.02), cor="branco", rot=(0, 0, 20))
    m.caixa((0.45, 0.06, 0.05), pos=(0.3, 0.3, 0.02), cor="creme", rot=(0, 0, -40))
    for k in range(4):
        arco = m.caixa((0.04, 0.4, 0.04), pos=(-0.3 + k * 0.12, -0.25, 0.08), cor="branco", rot=(35, 0, 0))
    return m.finalizar()


MODELOS = [
    rochedo_a, rochedo_b, rochedo_c, rochedo_d, rochas_baixas, cisterna_velha, poco_de_petroleo,
    onibus_abandonado, guindaste_da_pedreira, costela_gigante, carcaca_de_drone, cerca_de_sucata,
    poste_de_energia, enfeite_rachadura, enfeite_ossos,
]

if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.produzir(MODELOS, "marcos")
