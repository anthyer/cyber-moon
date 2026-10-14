"""Inimigos, subchefe e chefe da Torre de Retransmissão.

A segurança da corporação: câmeras que voam, guardas blindados, o programa de defesa e
o executivo de metal que manda em tudo. Malha rígida, partes nomeadas, frente em -Y.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/inimigos_da_torre.py", run_name="__main__")
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import dentes, espinho, faixa_de_aviso, olhar_bravo


def inimigo_olho_de_vigia():
    """Inimigo comum de distância: câmera que flutua, um olho só, com um anel que gira."""
    raiz = kit.vazio("inimigo_olho_de_vigia")
    corpo = kit.Modelo("FlutuaCorpo")
    corpo.esfera(0.17, pos=(0, 0, 0), cor="cinza_escuro", subdivisoes=2)
    corpo.cilindro(0.11, 0.05, pos=(0, -0.13, 0), cor="preto", lados=8, rot=(90, 0, 0))
    corpo.cilindro(0.075, 0.03, pos=(0, -0.175, 0), cor="magenta", lados=8, rot=(90, 0, 0), brilho=True)
    corpo.cilindro(0.03, 0.02, pos=(0, -0.2, 0), cor="branco", lados=6, rot=(90, 0, 0), brilho=True)
    corpo.caixa((0.26, 0.1, 0.05), pos=(0, -0.1, 0.1), cor="preto", rot=(-20, 0, 0))
    espinho(corpo, (0, 0.02, 0.15), 0.16, raio=0.035, cor="grafite")
    for x in (-0.1, 0.1):
        espinho(corpo, (x, 0.02, -0.14), 0.14, raio=0.03, cor="grafite", rot=(180, 0, 0))
    objeto = corpo.finalizar(pai=raiz, pos=(0, 0, 0.5))
    anel = kit.Modelo("GiraAnel")
    for indice in range(8):
        gomo = anel.caixa((0.2, 0.035, 0.035), pos=(0, 0.26, -0.017), cor="azul_claro", brilho=indice % 2 == 0)
        anel.mover(gomo, rot=(0, 0, indice * 45))
    anel.finalizar(pai=objeto, pos=(0, 0, 0))
    return raiz


def inimigo_guarda_blindado():
    """Inimigo comum: guarda de choque sobre uma roda, com escudo num braço e bastão no outro."""
    raiz = kit.vazio("inimigo_guarda_blindado")
    corpo = kit.Modelo("Corpo")
    corpo.cilindro(0.13, 0.1, pos=(-0.05, 0, 0.13), cor="grafite", lados=8, rot=(0, 90, 0))
    corpo.caixa((0.16, 0.14, 0.14), pos=(0, 0, 0.16), cor="chumbo")
    corpo.prisma([(-0.14, 0.0), (0.14, 0.0), (0.22, 0.34), (-0.22, 0.34)], 0.22, pos=(0, 0, 0.28),
                 cor="indigo")
    corpo.caixa((0.48, 0.24, 0.07), pos=(0, 0, 0.6), cor="preto", chanfro=0.02)
    corpo.caixa((0.22, 0.2, 0.16), pos=(0, -0.01, 0.67), cor="preto", chanfro=0.04)
    olhar_bravo(corpo, (0, -0.115, 0.775), largura=0.2, cor="azul_claro", altura=0.05)
    corpo.caixa((0.14, 0.03, 0.12), pos=(0, -0.115, 0.4), cor="magenta", brilho=True)
    corpo.caixa((0.06, 0.4, 0.5), pos=(-0.3, -0.12, 0.22), cor="chumbo", chanfro=0.02)
    corpo.caixa((0.07, 0.3, 0.06), pos=(-0.31, -0.12, 0.5), cor="azul_claro", brilho=True)
    corpo.caixa((0.08, 0.08, 0.26), pos=(0.27, 0, 0.36), cor="preto")
    corpo.cilindro(0.03, 0.4, pos=(0.27, -0.02, 0.36), cor="amarelo", lados=6, rot=(80, 0, 0), brilho=True)
    for x in (-0.22, 0.22):
        espinho(corpo, (x, 0, 0.66), 0.12, raio=0.04, cor="grafite", rot=(0, 25 if x > 0 else -25, 0))
    corpo.finalizar(pai=raiz)
    return raiz


def chefe_firewall():
    """Subchefe da torre: o programa de defesa, um núcleo que flutua atrás de escudos.

    O núcleo sobe e desce (`FlutuaNucleo`), três placas de escudo giram em volta dele
    (`GiraEscudos`) e a coroa de pontas gira ao contrário, mais devagar (`GiraCoroa`).
    """
    raiz = kit.vazio("chefe_firewall")
    nucleo = kit.Modelo("FlutuaNucleo")
    nucleo.esfera(0.24, pos=(0, 0, 0), cor="preto", escala=(1.0, 1.0, 1.3))
    nucleo.esfera(0.13, pos=(0, -0.16, 0.02), cor="magenta", brilho=True)
    olhar_bravo(nucleo, (0, -0.245, 0.16), largura=0.26, cor="amarelo", altura=0.05)
    espinho(nucleo, (0, 0, -0.28), 0.3, raio=0.09, cor="grafite", rot=(180, 0, 0))
    for x in (-0.16, 0.16):
        espinho(nucleo, (x, 0, 0.2), 0.26, raio=0.05, cor="grafite", rot=(0, 30 if x > 0 else -30, 0))
    objeto = nucleo.finalizar(pai=raiz, pos=(0, 0, 0.62))
    escudos = kit.Modelo("GiraEscudos")
    for indice in range(3):
        angulo = indice * 120
        placa = escudos.prisma([(-0.17, -0.24), (0.17, -0.24), (0.22, 0.14), (0.0, 0.3), (-0.22, 0.14)], 0.05,
                               pos=(0, -0.46, 0), cor="indigo")
        filete = escudos.caixa((0.3, 0.06, 0.04), pos=(0, -0.46, -0.02), cor="azul_claro", brilho=True)
        ponta = escudos.cilindro(0.04, 0.14, pos=(0, -0.48, 0.0), cor="branco", lados=4, raio_do_topo=0.0,
                                 rot=(90, 0, 0))
        for peca in (placa, filete, ponta):
            escudos.mover(peca, rot=(0, 0, angulo))
    escudos.finalizar(pai=objeto, pos=(0, 0, 0))
    coroa = kit.Modelo("GiraCoroa")
    for indice in range(6):
        ponta = coroa.cilindro(0.035, 0.18, pos=(0.2, 0, 0), cor="amarelo", lados=4, raio_do_topo=0.0,
                               rot=(0, 25, 0), brilho=True)
        coroa.mover(ponta, rot=(0, 0, indice * 60))
    coroa.finalizar(pai=objeto, pos=(0, 0, 0.3))
    return raiz


def chefe_auditor():
    """Chefe da torre: o Auditor, o executivo de metal que fecha as contas da corporação.

    Tronco em V de terno escuro com gravata de neon, ombreiras de ponta, cabeça de tela
    com o olhar bravo, e dois braços que acabam em lâmina (`BracoEsquerdo` e
    `BracoDireito`). Não tem pernas: flutua sobre um propulsor (`FlutuaCorpo`), com um
    anel de dados girando na cintura (`GiraAnel`).
    """
    raiz = kit.vazio("chefe_auditor")
    corpo = kit.Modelo("FlutuaCorpo")
    corpo.cilindro(0.16, 0.26, pos=(0, 0, -0.3), cor="grafite", lados=8, raio_do_topo=0.1)
    corpo.cilindro(0.1, 0.06, pos=(0, 0, -0.36), cor="azul_claro", lados=8, brilho=True)
    corpo.prisma([(-0.15, 0.0), (0.15, 0.0), (0.34, 0.5), (-0.34, 0.5)], 0.26, pos=(0, 0, -0.04),
                 cor="preto")
    corpo.prisma([(-0.05, 0.0), (0.05, 0.0), (0.2, 0.46), (-0.2, 0.46)], 0.02, pos=(0, -0.135, 0.0),
                 cor="branco")
    corpo.prisma([(0.0, 0.0), (0.06, 0.12), (0.035, 0.42), (-0.035, 0.42), (-0.06, 0.12)], 0.02,
                 pos=(0, -0.15, 0.02), cor="magenta", brilho=True)
    corpo.caixa((0.86, 0.3, 0.1), pos=(0, 0, 0.46), cor="chumbo", chanfro=0.03)
    for x in (-0.36, 0.36):
        sinal = 1 if x > 0 else -1
        espinho(corpo, (x, 0, 0.54), 0.36, raio=0.08, cor="grafite", rot=(0, sinal * 40, 0))
        espinho(corpo, (x * 0.6, 0.06, 0.54), 0.2, raio=0.05, cor="grafite", rot=(0, sinal * 20, 0))
    corpo.caixa((0.1, 0.1, 0.08), pos=(0, 0, 0.56), cor="grafite")
    corpo.caixa((0.34, 0.24, 0.26), pos=(0, -0.02, 0.63), cor="preto", chanfro=0.04)
    corpo.caixa((0.28, 0.02, 0.2), pos=(0, -0.145, 0.66), cor="indigo")
    olhar_bravo(corpo, (0, -0.15, 0.83), largura=0.24, cor="magenta", altura=0.06)
    dentes(corpo, (0, -0.16, 0.74), largura=0.2, quantidade=5, tamanho=0.045, cor="azul_claro", para_baixo=True)
    for x in (-0.12, 0.12):
        espinho(corpo, (x, 0.02, 0.89), 0.2, raio=0.03, cor="amarelo", rot=(0, 15 if x > 0 else -15, 0))
    objeto = corpo.finalizar(pai=raiz, pos=(0, 0, 0.5))
    anel = kit.Modelo("GiraAnel")
    for indice in range(10):
        gomo = anel.caixa((0.16, 0.03, 0.05), pos=(0, 0.34, -0.025), cor="azul_claro" if indice % 2 else "magenta",
                          brilho=True)
        anel.mover(gomo, rot=(0, 0, indice * 36))
    anel.finalizar(pai=objeto, pos=(0, 0, 0.0))
    for nome, lado in (("BracoEsquerdo", -1.0), ("BracoDireito", 1.0)):
        braco = kit.Modelo(nome)
        braco.esfera(0.09, pos=(0, 0, 0), cor="chumbo")
        braco.caixa((0.1, 0.1, 0.3), pos=(0, 0, -0.3), cor="preto", chanfro=0.02)
        braco.caixa((0.12, 0.12, 0.06), pos=(0, 0, -0.34), cor="branco")
        braco.prisma([(-0.06, 0.0), (0.06, 0.0), (0.02, -0.5), (0.0, -0.6)], 0.025, pos=(0, 0, -0.3),
                     cor="azul_claro", brilho=True, rot=(0, 0, 90))
        braco.finalizar(pai=objeto, pos=(lado * 0.44, 0, 0.44))
    return raiz


MODELOS = [inimigo_olho_de_vigia, inimigo_guarda_blindado, chefe_firewall, chefe_auditor]

if __name__ == "__main__":
    kit.produzir(MODELOS, "inimigos_da_torre", espaco=0.5)
