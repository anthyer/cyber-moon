"""O verde do mapa: palmeira, árvore frutífera, arbustos, grama, flores, cerca viva e os
juncos da beira d'água. Também o que é seco no deserto: arbusto seco e bola de feno.

Pacote `cyber_moon_mundo`. A fazenda é um oásis no deserto: é ali, e em volta da água,
que o verde se concentra.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/verde.py", run_name="__main__")
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit

PACOTE = "cyber_moon_mundo"


def _folha_de_palmeira(m, topo, angulo, comprimento, cor):
    """Folha comprida e caída, feita de três gomos de prisma, cada um mais inclinado."""
    x0, y0, z0 = topo
    inclinacoes = (15, 35, 60)
    pedaco = comprimento / 3.0
    x, z = 0.0, 0.0
    for indice, inclinacao in enumerate(inclinacoes):
        largura = 0.32 - indice * 0.08
        gomo = m.prisma([(0.0, -largura / 2), (pedaco, -largura * 0.35), (pedaco, largura * 0.35), (0.0, largura / 2)],
                        0.03, cor=cor, rot=(90, 0, 0))
        m.mover(gomo, rot=(0, inclinacao, 0))
        m.mover(gomo, pos=(x, 0, z))
        m.mover(gomo, rot=(0, 0, angulo))
        m.mover(gomo, pos=(x0, y0, z0))
        x += pedaco * math.cos(math.radians(inclinacao))
        z -= pedaco * math.sin(math.radians(inclinacao))


def palmeira():
    """Palmeira do oásis: tronco em gomos levemente curvo e uma coroa de folhas caídas."""
    m = kit.Modelo("palmeira")
    x, z = 0.0, 0.0
    for indice in range(7):
        raio = 0.17 - indice * 0.01
        m.cilindro(raio, 0.46, pos=(x, 0, z), cor="marrom" if indice % 2 else "ferrugem", lados=7, raio_do_topo=raio * 0.9)
        x += 0.05
        z += 0.44
    topo = (x, 0, z)
    for indice in range(7):
        _folha_de_palmeira(m, topo, indice * 51 + 10, 1.5, "verde" if indice % 2 else "verde_folha")
    for angulo in (0, 120, 240):
        coco = m.esfera(0.08, pos=(0.12, 0, -0.1), cor="marrom")
        m.mover(coco, rot=(0, 0, angulo))
        m.mover(coco, pos=topo)
    return m.finalizar()


def arvore_frutifera():
    """Editado de `kenney_nature_kit/tree_default.glb`: a árvore do pomar, repintada na
    paleta e com laranjas na copa."""
    m = kit.Modelo("arvore_frutifera")
    importados = kit.importar_glb("kenney_nature_kit/tree_default.glb")
    for origem in importados:
        if origem.type == "MESH":
            m.malha_de(origem, escala=(1.3, 1.3, 1.3), cor={"leafs": "verde", "wood": "marrom", "": "verde"})
    kit.apagar(importados)
    sorteio = random.Random(3)
    for indice in range(9):
        angulo = indice * 40
        altura = sorteio.uniform(1.05, 1.9)
        raio = 0.42 * (1.0 - abs(altura - 1.45) * 0.6)
        fruta = m.esfera(0.06, pos=(raio, 0, altura), cor="laranja")
        m.mover(fruta, rot=(0, 0, angulo))
    return m.finalizar()


def arbusto_do_oasis():
    """Arbusto verde e cheio, de três bolas facetadas."""
    m = kit.Modelo("arbusto_do_oasis")
    for pos, raio, cor in (((0, 0, 0.3), 0.42, "verde"), ((0.32, 0.1, 0.22), 0.3, "verde_folha"),
                           ((-0.28, -0.08, 0.2), 0.28, "verde"), ((0.05, 0.05, 0.6), 0.25, "verde_folha")):
        m.esfera(raio, pos=pos, cor=cor, escala=(1, 1, 0.85))
    return m.finalizar()


def cerca_viva():
    """Dois de cerca viva baixa, aparada. Bloqueia, mas não esconde ninguém."""
    m = kit.Modelo("cerca_viva")
    m.caixa((2.0, 0.6, 0.7), cor="verde", chanfro=0.12, degrade=True)
    for x in (-0.6, 0.2, 0.75):
        m.esfera(0.2, pos=(x, -0.15, 0.62), cor="verde_folha", escala=(1.2, 1, 0.6))
    return m.finalizar()


def enfeite_tufo_de_grama():
    """Tufo de grama verde, de folhas largas em leque. Sem colisão."""
    m = kit.Modelo("enfeite_tufo_de_grama")
    sorteio = random.Random(17)
    for indice in range(14):
        angulo = indice * 26 + sorteio.uniform(-8, 8)
        inclinacao = sorteio.uniform(10, 35)
        altura = sorteio.uniform(0.18, 0.3)
        folha = m.prisma([(-0.04, 0.0), (0.04, 0.0), (0.0, altura)], 0.015,
                         cor="verde" if indice % 2 else "verde_folha", rot=(inclinacao, 0, 0))
        m.mover(folha, rot=(0, 0, angulo))
    return m.finalizar()


def enfeite_flores():
    """Um punhado de flores baixas: magenta, amarelo e branco, com folhas. Sem colisão."""
    m = kit.Modelo("enfeite_flores")
    sorteio = random.Random(5)
    for indice in range(9):
        x = sorteio.uniform(-0.35, 0.35)
        y = sorteio.uniform(-0.35, 0.35)
        altura = sorteio.uniform(0.12, 0.26)
        m.cilindro(0.012, altura, pos=(x, y, 0), cor="verde_folha", lados=4)
        m.esfera(0.05, pos=(x, y, altura), cor=("magenta", "amarelo", "branco", "rosa")[indice % 4], escala=(1, 1, 0.6))
        folha = m.prisma([(-0.04, 0.0), (0.04, 0.0), (0.0, 0.12)], 0.01, cor="verde", rot=(50, 0, 0))
        m.mover(folha, rot=(0, 0, indice * 70))
        m.mover(folha, pos=(x, y, 0))
    return m.finalizar()


def enfeite_juncos():
    """Juncos da beira d'água: hastes altas e finas com a ponta marrom. Sem colisão."""
    m = kit.Modelo("enfeite_juncos")
    sorteio = random.Random(8)
    for indice in range(8):
        x = sorteio.uniform(-0.25, 0.25)
        y = sorteio.uniform(-0.25, 0.25)
        altura = sorteio.uniform(0.5, 0.85)
        haste = m.cilindro(0.015, altura, pos=(x, y, 0), cor="verde_folha", lados=4, rot=(sorteio.uniform(-8, 8), 0, 0))
        m.cilindro(0.035, 0.14, pos=(x, y, altura - 0.12), cor="marrom", lados=5)
        folha = m.prisma([(-0.025, 0.0), (0.025, 0.0), (0.0, altura * 0.6)], 0.01, cor="verde", rot=(20, 0, 0))
        m.mover(folha, rot=(0, 0, indice * 45))
        m.mover(folha, pos=(x, y, 0))
    return m.finalizar()


def arbusto_seco():
    """Arbusto seco do deserto: galhos finos e tortos, cor de palha."""
    m = kit.Modelo("arbusto_seco")
    sorteio = random.Random(13)
    for indice in range(11):
        angulo = indice * 33
        inclinacao = sorteio.uniform(25, 55)
        comprimento = sorteio.uniform(0.35, 0.6)
        galho = m.cilindro(0.02, comprimento, cor="marrom" if indice % 2 else "creme", lados=3, raio_do_topo=0.006,
                           rot=(inclinacao, 0, 0))
        m.mover(galho, rot=(0, 0, angulo))
    m.esfera(0.12, pos=(0, 0, 0.08), cor="marrom", escala=(1, 1, 0.5))
    return m.finalizar()


def enfeite_bola_de_feno():
    """A bola de mato seco que rola pelo deserto. Sem colisão."""
    m = kit.Modelo("enfeite_bola_de_feno")
    m.esfera(0.32, pos=(0, 0, 0.32), cor="creme", subdivisoes=1)
    for angulo in range(0, 360, 45):
        galho = m.caixa((0.7, 0.03, 0.03), pos=(0, 0, 0.32), cor="marrom", rot=(angulo * 0.5, angulo, 0))
    return m.finalizar()


MODELOS = [
    palmeira, arvore_frutifera, arbusto_do_oasis, cerca_viva, enfeite_tufo_de_grama, enfeite_flores,
    enfeite_juncos, arbusto_seco, enfeite_bola_de_feno,
]

if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.produzir(MODELOS, "verde")
