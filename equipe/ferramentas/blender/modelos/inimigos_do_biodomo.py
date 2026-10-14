"""Inimigos, subchefe e chefe do Biodomo Abandonado.

Máquinas de jardinagem da corporação que continuaram trabalhando sem ninguém mandar.
Mesma regra dos outros inimigos: malha rígida, partes nomeadas, frente em -Y.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/inimigos_do_biodomo.py", run_name="__main__")
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import dentes, espinho, faixa_de_aviso, olhar_bravo, serra


def _lamina(m, comprimento, pos, rot=(0, 0, 0), cor="branco"):
    """Lâmina chata e pontuda ao longo de -Y, com a base em `pos`."""
    pontos = [(-0.04, 0.0), (0.04, 0.0), (0.0, comprimento)]
    peca = m.prisma(pontos, 0.02, cor=cor, rot=(90, 0, 0))
    m.mover(peca, pos=pos, rot=rot)
    return peca


def inimigo_podador():
    """Inimigo comum: drone de poda que flutua, com duas lâminas de tesoura na frente."""
    raiz = kit.vazio("inimigo_podador")
    corpo = kit.Modelo("FlutuaCorpo")
    corpo.esfera(0.19, pos=(0, 0, 0.1), cor="verde", escala=(1.0, 1.15, 0.8), degrade=True)
    corpo.caixa((0.3, 0.2, 0.05), pos=(0, 0.02, 0.2), cor="chumbo")
    olhar_bravo(corpo, (0, -0.2, 0.15), largura=0.2, cor="magenta")
    _lamina(corpo, 0.3, (-0.07, -0.18, 0.02), rot=(0, 0, 14))
    _lamina(corpo, 0.3, (0.07, -0.18, 0.02), rot=(0, 0, -14))
    corpo.cilindro(0.03, 0.05, pos=(0, -0.2, 0.0), cor="amarelo", lados=6)
    for x in (-0.22, 0.22):
        corpo.caixa((0.12, 0.05, 0.03), pos=(x * 0.8, 0.02, 0.2), cor="grafite")
    espinho(corpo, (0, 0.14, 0.2), 0.12, cor="verde_folha", rot=(-30, 0, 0))
    corpo.finalizar(pai=raiz, pos=(0, 0, 0.42))
    for nome, x in (("GiraHeliceEsquerda", -0.24), ("GiraHeliceDireita", 0.24)):
        helice = kit.Modelo(nome)
        helice.caixa((0.28, 0.05, 0.012), pos=(0, 0, 0), cor="cinza")
        helice.caixa((0.05, 0.28, 0.012), pos=(0, 0, 0), cor="cinza")
        helice.finalizar(pai=raiz.children[0], pos=(x, 0.02, 0.26))
    return raiz


def inimigo_semeador():
    """Inimigo comum de distância: torre de três pernas que cospe sementes pelo cano."""
    raiz = kit.vazio("inimigo_semeador")
    corpo = kit.Modelo("Corpo")
    for angulo in (30, 150, 270):
        perna = corpo.caixa((0.05, 0.05, 0.34), pos=(0.14, 0, 0.0), cor="chumbo", rot=(0, 25, 0))
        corpo.mover(perna, rot=(0, 0, angulo))
    corpo.cilindro(0.17, 0.2, pos=(0, 0, 0.26), cor="creme", lados=8, degrade=True)
    corpo.cilindro(0.19, 0.05, pos=(0, 0, 0.3), cor="verde", lados=8)
    corpo.cilindro(0.12, 0.1, pos=(0, 0, 0.46), cor="verde", lados=8, raio_do_topo=0.04)
    corpo.cilindro(0.055, 0.26, pos=(0, -0.12, 0.36), cor="grafite", lados=6, rot=(90, 0, 0))
    corpo.cilindro(0.07, 0.05, pos=(0, -0.36, 0.36), cor="amarelo", lados=6, rot=(90, 0, 0), brilho=True)
    olhar_bravo(corpo, (0, -0.165, 0.46), largura=0.16, cor="amarelo", altura=0.045)
    for x in (-0.14, 0.14):
        espinho(corpo, (x, 0.02, 0.44), 0.14, raio=0.035, cor="verde_folha", rot=(0, 30 if x > 0 else -30, 0))
    corpo.finalizar(pai=raiz)
    return raiz


def chefe_enxertador():
    """Subchefe do biodomo: a máquina de enxerto, uma aranha de seis pernas com seringas.

    O corpo balança (`FlutuaCorpo`) e os dois braços de seringa (`BracoEsquerdo` e
    `BracoDireito`) atacam. As pernas ficam paradas, fincadas no chão.
    """
    raiz = kit.vazio("chefe_enxertador")
    pernas = kit.Modelo("Pernas")
    for indice in range(6):
        angulo = 30 + indice * 60
        coxa = pernas.caixa((0.3, 0.06, 0.06), pos=(0.18, 0, 0.36), cor="chumbo", rot=(0, -28, 0))
        canela = pernas.cilindro(0.035, 0.44, pos=(0.5, 0, 0.0), cor="cinza_metal", lados=5, raio_do_topo=0.05,
                                 rot=(0, -12, 0))
        junta = pernas.esfera(0.06, pos=(0.44, 0, 0.44), cor="verde")
        for peca in (coxa, canela, junta):
            pernas.mover(peca, rot=(0, 0, angulo))
    pernas.finalizar(pai=raiz)
    corpo = kit.Modelo("FlutuaCorpo")
    corpo.esfera(0.26, pos=(0, 0.06, 0.1), cor="verde", escala=(1.0, 1.25, 0.75), degrade=True)
    corpo.caixa((0.34, 0.3, 0.2), pos=(0, -0.2, -0.02), cor="cinza_escuro", chanfro=0.05)
    olhar_bravo(corpo, (0, -0.355, 0.13), largura=0.28, cor="magenta")
    dentes(corpo, (0, -0.36, -0.02), largura=0.26, quantidade=5, tamanho=0.07, cor="branco", para_baixo=True)
    for y in (-0.05, 0.12, 0.28):
        espinho(corpo, (0, y, 0.27), 0.2, raio=0.05, cor="verde_folha", rot=(-15, 0, 0))
    corpo.cilindro(0.11, 0.26, pos=(0, 0.3, 0.02), cor="magenta", lados=8, brilho=True, rot=(-70, 0, 0))
    corpo.cilindro(0.125, 0.05, pos=(0, 0.34, 0.03), cor="chumbo", lados=8, rot=(-70, 0, 0))
    objeto_do_corpo = corpo.finalizar(pai=raiz, pos=(0, 0, 0.42))
    for nome, lado in (("BracoEsquerdo", -1.0), ("BracoDireito", 1.0)):
        braco = kit.Modelo(nome)
        braco.esfera(0.07, pos=(0, 0, 0), cor="chumbo")
        braco.cilindro(0.04, 0.3, pos=(0, 0, 0), cor="cinza_escuro", lados=6, rot=(100, 0, 0))
        braco.cilindro(0.06, 0.2, pos=(0, -0.3, -0.05), cor="branco", lados=6, rot=(100, 0, 0))
        braco.cilindro(0.045, 0.12, pos=(0, -0.33, -0.055), cor="magenta", lados=6, rot=(100, 0, 0), brilho=True)
        braco.cilindro(0.02, 0.26, pos=(0, -0.5, -0.085), cor="cinza_metal", lados=4, raio_do_topo=0.0, rot=(100, 0, 0))
        braco.finalizar(pai=objeto_do_corpo, pos=(lado * 0.26, -0.22, 0.12))
    return raiz


def chefe_colheitadeira():
    """Chefe do biodomo: a colheitadeira que colhe tudo o que se mexe.

    Corpo de máquina agrícola verde, cabine com visor bravo, chifres de escapamento e, na
    frente, o molinete de lâminas (`GiraMolinete`), que roda em torno do eixo da largura.
    Atrás, as duas rodas grandes (`GiraRodaEsquerda` e `GiraRodaDireita`).
    """
    raiz = kit.vazio("chefe_colheitadeira")
    corpo = kit.Modelo("Corpo")
    corpo.caixa((0.6, 0.66, 0.34), pos=(0, 0.1, 0.16), cor="verde", chanfro=0.06, degrade=True)
    corpo.caixa((0.66, 0.2, 0.12), pos=(0, 0.3, 0.44), cor="chumbo", chanfro=0.03)
    corpo.caixa((0.4, 0.34, 0.26), pos=(0, 0.02, 0.5), cor="amarelo", chanfro=0.05)
    corpo.caixa((0.44, 0.3, 0.05), pos=(0, 0.04, 0.75), cor="chumbo")
    olhar_bravo(corpo, (0, -0.155, 0.66), largura=0.34, cor="magenta", altura=0.08)
    faixa_de_aviso(corpo, 0.6, (0, -0.235, 0.2), altura=0.08)
    corpo.caixa((0.94, 0.14, 0.3), pos=(0, -0.34, 0.06), cor="cinza_escuro", chanfro=0.03)
    corpo.prisma([(-0.2, 0.0), (0.2, 0.0), (0.2, 0.06), (-0.2, 0.2)], 0.94, pos=(0, -0.5, 0.0),
                 cor="chumbo", rot=(0, 0, 90))
    dentes(corpo, (0, -0.68, 0.0), largura=0.9, quantidade=9, tamanho=0.1, cor="branco")
    for x in (-0.47, 0.47):
        corpo.caixa((0.05, 0.44, 0.4), pos=(x, -0.5, 0.0), cor="cinza_escuro")
        sinal = 1 if x > 0 else -1
        espinho(corpo, (x * 0.6, 0.08, 0.76), 0.34, raio=0.06, cor="cinza_metal", rot=(-20, sinal * 35, 0))
    for x in (-0.2, 0.2):
        corpo.cilindro(0.05, 0.36, pos=(x, 0.34, 0.5), cor="grafite", lados=6)
        corpo.cilindro(0.065, 0.05, pos=(x, 0.34, 0.84), cor="laranja", lados=6, brilho=True)
    for x in (-0.3, 0.3):
        corpo.cilindro(0.09, 0.08, pos=(x - 0.04, -0.12, 0.09), cor="grafite", lados=8, rot=(0, 90, 0))
    corpo.finalizar(pai=raiz)
    molinete = kit.Modelo("GiraMolinete")
    molinete.cilindro(0.04, 0.86, pos=(0, 0, -0.43), cor="chumbo", lados=6)
    for z in (-0.4, 0.0, 0.4):
        molinete.cilindro(0.17, 0.03, pos=(0, 0, z - 0.015), cor="amarelo", lados=6)
    for indice in range(6):
        angulo = indice * 60
        barra = molinete.caixa((0.03, 0.08, 0.84), pos=(0.17, 0, -0.42), cor="branco")
        molinete.mover(barra, rot=(0, 0, angulo))
        for z in (-0.3, -0.1, 0.1, 0.3):
            ponta = molinete.cilindro(0.03, 0.09, pos=(0.18, 0, z), cor="cinza_metal", lados=4, raio_do_topo=0.0,
                                      rot=(0, 90, 0))
            molinete.mover(ponta, rot=(0, 0, angulo))
    objeto = molinete.finalizar(pai=raiz, pos=(0, -0.52, 0.3))
    objeto.rotation_euler = (0, math.radians(90), 0)
    for nome, x in (("GiraRodaEsquerda", -0.37), ("GiraRodaDireita", 0.37)):
        roda = kit.Modelo(nome)
        roda.cilindro(0.2, 0.12, pos=(0, 0, -0.06), cor="grafite", lados=10)
        roda.cilindro(0.09, 0.14, pos=(0, 0, -0.07), cor="amarelo", lados=6)
        for indice in range(5):
            cravo = roda.caixa((0.06, 0.05, 0.12), pos=(0.2, 0, -0.06), cor="chumbo")
            roda.mover(cravo, rot=(0, 0, indice * 72))
        objeto = roda.finalizar(pai=raiz, pos=(x, 0.26, 0.2))
        objeto.rotation_euler = (0, math.radians(90), 0)
    return raiz


MODELOS = [inimigo_podador, inimigo_semeador, chefe_enxertador, chefe_colheitadeira]

if __name__ == "__main__":
    kit.produzir(MODELOS, "inimigos_do_biodomo", espaco=0.5)
