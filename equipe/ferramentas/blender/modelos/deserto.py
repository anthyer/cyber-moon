"""Natureza do deserto em volta da vila: cactos, mesas de pedra, capim seco e manchas de chão.

Pacote `cyber_moon_mundo`. As formas seguem o Nature Kit (sólido facetado, poucas faces),
mas com a cor tirada da paleta, como o resto do pacote próprio.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/deserto.py", run_name="__main__")
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit

PACOTE = "cyber_moon_mundo"


def _braco_de_cacto(m, base, lado, altura_do_cotovelo, comprimento, raio):
    """Um braço de cacto: sai de lado e sobe, em dois gomos."""
    x, y, z = base
    m.cilindro(raio, abs(lado) * 0.36, pos=(x, y, z), cor="verde", lados=8, rot=(0, 90 if lado > 0 else -90, 0))
    m.esfera(raio * 1.02, pos=(x + lado * 0.36, y, z), cor="verde", subdivisoes=1)
    m.cilindro(raio, comprimento, pos=(x + lado * 0.36, y, z), cor="verde", lados=8, degrade=True)
    m.esfera(raio * 1.02, pos=(x + lado * 0.36, y, z + comprimento), cor="verde", subdivisoes=1, escala=(1, 1, 0.8))


def cacto_alto():
    """Cacto de braços, do tamanho de três personagens. É o marco da paisagem."""
    m = kit.Modelo("cacto_alto")
    m.cilindro(0.24, 1.9, cor="verde", lados=8, degrade=True)
    m.esfera(0.245, pos=(0, 0, 1.9), cor="verde", escala=(1, 1, 0.8))
    _braco_de_cacto(m, (0.12, 0, 0.8), 1, 0.8, 0.55, 0.15)
    _braco_de_cacto(m, (-0.12, 0, 1.15), -1, 1.15, 0.45, 0.13)
    for z in (0.5, 1.0, 1.5):
        for angulo in (0, 120, 240):
            espinho = m.cilindro(0.015, 0.08, pos=(0.24, 0, z), cor="creme", lados=3, raio_do_topo=0.0, rot=(0, 90, 0))
            m.mover(espinho, rot=(0, 0, angulo + z * 40))
    m.esfera(0.07, pos=(0.05, 0, 2.08), cor="magenta")
    m.cilindro(0.3, 0.06, cor="ferrugem", lados=7)
    return m.finalizar()


def cacto_redondo():
    """Cacto bola, baixo, com gomos e uma flor."""
    m = kit.Modelo("cacto_redondo")
    m.cilindro(0.3, 0.32, cor="verde", lados=10, raio_do_topo=0.26, degrade=True)
    m.cilindro(0.26, 0.12, pos=(0, 0, 0.32), cor="verde", lados=10, raio_do_topo=0.12)
    for angulo in range(0, 360, 36):
        gomo = m.caixa((0.04, 0.03, 0.36), pos=(0.29, 0, 0.02), cor="verde_folha", rot=(0, -5, 0))
        m.mover(gomo, rot=(0, 0, angulo))
    m.esfera(0.08, pos=(0, 0, 0.47), cor="rosa", escala=(1, 1, 0.6))
    m.esfera(0.035, pos=(0, 0, 0.5), cor="amarelo")
    return m.finalizar()


def cacto_de_raquete():
    """Palma: raquetes achatadas empilhadas, com frutinhas magenta na borda."""
    m = kit.Modelo("cacto_de_raquete")
    raquetes = (
        ((0, 0, 0.22), (0.22, 0.07, 0.24), 0),
        ((0.12, 0, 0.55), (0.18, 0.06, 0.2), -25),
        ((-0.14, 0.02, 0.5), (0.17, 0.06, 0.19), 30),
        ((0.02, 0, 0.82), (0.15, 0.055, 0.17), 10),
    )
    for pos, escala, giro in raquetes:
        m.esfera(1.0, pos=pos, cor="verde", escala=escala, rot=(0, giro, 0), subdivisoes=1)
    for pos in ((0.2, 0, 0.72), (-0.27, 0, 0.62), (0.08, 0, 0.98)):
        m.esfera(0.045, pos=pos, cor="magenta")
    return m.finalizar()


def _contorno_irregular(sorteio, meia_largura, meia_profundidade, pontos=11, tremor=0.14):
    contorno = []
    for indice in range(pontos):
        angulo = math.tau * indice / pontos
        fator = 1.0 + sorteio.uniform(-tremor, tremor)
        contorno.append((math.cos(angulo) * meia_largura * fator, math.sin(angulo) * meia_profundidade * fator))
    return contorno


def _mesa(m, largura, profundidade, altura, semente):
    """Rochedo de topo chato, em camadas de rocha de contorno irregular.

    Cada camada é um contorno de 11 pontos extrudado na vertical. As de baixo são um
    pouco mais largas, e as faixas alternam ferrugem e salmão, como estrato de pedra.
    """
    sorteio = random.Random(semente)
    camadas = 5
    for indice in range(camadas):
        espessura = altura / camadas
        z = espessura * indice
        encolhe = 1.0 - 0.05 * indice
        cor = ("ferrugem", "salmao", "ferrugem", "salmao", "pessego")[indice]
        contorno = _contorno_irregular(sorteio, largura * 0.5 * encolhe, profundidade * 0.5 * encolhe)
        camada = m.prisma(contorno, espessura + 0.03, cor=cor, rot=(90, 0, 0), degrade=True)
        m.mover(camada, pos=(sorteio.uniform(-0.1, 0.1), sorteio.uniform(-0.1, 0.1), z + espessura * 0.5))
    for indice in range(6):
        angulo = sorteio.uniform(0, math.tau)
        x = math.cos(angulo) * largura * 0.52
        y = math.sin(angulo) * profundidade * 0.52
        tamanho = sorteio.uniform(0.35, 0.75)
        m.esfera(tamanho, pos=(x, y, tamanho * 0.25), cor="ferrugem", escala=(1.2, 0.9, 0.6), subdivisoes=1)


def mesa_de_pedra_grande():
    """Mesa de pedra de 8 por 6 e 4,5 de altura. Só fica nas bordas do norte e do leste."""
    m = kit.Modelo("mesa_de_pedra_grande")
    _mesa(m, 8.0, 6.0, 4.5, 3)
    return m.finalizar()


def mesa_de_pedra_media():
    """Mesa de pedra de 4 por 3 e 2,4 de altura."""
    m = kit.Modelo("mesa_de_pedra_media")
    _mesa(m, 4.0, 3.0, 2.4, 7)
    return m.finalizar()


def rocha_do_deserto():
    """Editado de `kenney_nature_kit/rock_large_a.glb`: a rocha repintada de ferrugem."""
    m = kit.Modelo("rocha_do_deserto")
    importados = kit.importar_glb("kenney_nature_kit/rock_large_a.glb")
    for origem in importados:
        if origem.type == "MESH":
            m.malha_de(origem, escala=(1.6, 1.6, 1.6), cor={"": "ferrugem"})
    kit.apagar(importados)
    return m.finalizar()


def pedras_do_deserto():
    """Editado de `kenney_nature_kit/stone_small_a.glb`: um grupinho de pedras cor de areia."""
    m = kit.Modelo("pedras_do_deserto")
    importados = kit.importar_glb("kenney_nature_kit/stone_small_a.glb")
    for origem in importados:
        if origem.type == "MESH":
            for pos, escala, giro in (((0, 0, 0), 2.2, 0), ((0.45, 0.2, 0), 1.5, 70), ((-0.35, 0.25, 0), 1.2, 150)):
                m.malha_de(origem, pos=pos, rot=(0, 0, giro), escala=(escala, escala, escala),
                           cor={"": "pessego"})
    kit.apagar(importados)
    return m.finalizar()


def enfeite_capim_seco():
    """Tufo de capim seco: folhas largas em leque, do amarelo ao creme. Sem colisão."""
    m = kit.Modelo("enfeite_capim_seco")
    sorteio = random.Random(11)
    for indice in range(12):
        angulo = indice * 30 + sorteio.uniform(-10, 10)
        inclinacao = sorteio.uniform(15, 40)
        altura = sorteio.uniform(0.2, 0.36)
        folha = m.prisma([(-0.045, 0.0), (0.045, 0.0), (0.0, altura)], 0.015,
                         cor=("amarelo", "creme", "pessego")[indice % 3], rot=(inclinacao, 0, 0))
        m.mover(folha, rot=(0, 0, angulo))
    return m.finalizar()


def enfeite_caveira_de_boi():
    """Caveira de boi no chão, o clichê de deserto que todo mundo reconhece de longe."""
    m = kit.Modelo("enfeite_caveira_de_boi")
    m.caixa((0.18, 0.26, 0.12), pos=(0, 0, 0), cor="branco", chanfro=0.03)
    m.caixa((0.12, 0.12, 0.09), pos=(0, -0.17, 0), cor="branco", chanfro=0.03)
    for lado in (-1, 1):
        chifre = m.cilindro(0.03, 0.22, pos=(lado * 0.08, 0.05, 0.08), cor="creme", lados=5, raio_do_topo=0.0,
                            rot=(0, lado * 70, 0))
        m.mover(chifre, rot=(0, 0, 0))
        m.caixa((0.04, 0.02, 0.04), pos=(lado * 0.045, -0.115, 0.07), cor="preto")
    return m.finalizar()


def _mancha(m, raio, cor, semente, pontos=12):
    sorteio = random.Random(semente)
    contorno = []
    for indice in range(pontos):
        angulo = math.tau * indice / pontos
        r = raio * sorteio.uniform(0.75, 1.15)
        contorno.append((math.cos(angulo) * r, math.sin(angulo) * r * 0.75))
    peca = m.prisma(contorno, 0.01, cor=cor, rot=(90, 0, 0))
    m.mover(peca, pos=(0, 0, 0.005))


def enfeite_mancha_de_terra():
    """Mancha de terra batida, rente ao chão, para quebrar a areia lisa. Sem colisão."""
    m = kit.Modelo("enfeite_mancha_de_terra")
    _mancha(m, 2.4, "salmao", 5)
    return m.finalizar()


def enfeite_mancha_de_areia():
    """Mancha de areia clara, rente ao chão. Sem colisão."""
    m = kit.Modelo("enfeite_mancha_de_areia")
    _mancha(m, 2.0, "creme", 9)
    return m.finalizar()


MODELOS = [
    cacto_alto, cacto_redondo, cacto_de_raquete, mesa_de_pedra_grande, mesa_de_pedra_media,
    rocha_do_deserto, pedras_do_deserto, enfeite_capim_seco, enfeite_caveira_de_boi,
    enfeite_mancha_de_terra, enfeite_mancha_de_areia,
]

if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.produzir(MODELOS, "deserto")
