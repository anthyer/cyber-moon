"""Inimigos, subchefe e chefe da Galeria de Manutenção.

São máquinas de malha rígida, sem esqueleto. Cada modelo é um nó vazio com as partes
como filhas, e o nome da parte diz como o jogo a anima (veja `maquina_animada.gd`):
`Gira...` roda sem parar, `Flutua...` sobe e desce, `Braco...` balança no golpe.
A frente de todo inimigo é o lado -Y do Blender.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/inimigos_da_galeria.py", run_name="__main__")
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import dentes, espinho, faixa_de_aviso, olhar_bravo, serra


def inimigo_drone_de_solda():
    """Inimigo comum: drone de solda que flutua, com o maçarico aceso na frente."""
    raiz = kit.vazio("inimigo_drone_de_solda")
    corpo = kit.Modelo("FlutuaCorpo")
    corpo.caixa((0.34, 0.3, 0.2), pos=(0, 0, 0), cor="laranja", chanfro=0.05, degrade=True)
    corpo.caixa((0.38, 0.2, 0.06), pos=(0, 0.02, 0.07), cor="chumbo")
    olhar_bravo(corpo, (0, -0.155, 0.1), largura=0.2, cor="azul_claro")
    corpo.cilindro(0.035, 0.16, pos=(0, -0.3, 0.04), cor="grafite", lados=6, rot=(-90, 0, 0))
    corpo.cilindro(0.045, 0.05, pos=(0, -0.33, 0.04), cor="amarelo", lados=6, rot=(-90, 0, 0), brilho=True)
    for x in (-0.24, 0.24):
        corpo.caixa((0.14, 0.05, 0.03), pos=(x * 0.85, 0, 0.16), cor="grafite")
        corpo.cilindro(0.03, 0.08, pos=(x, 0, 0.14), cor="chumbo", lados=6)
    espinho(corpo, (0, 0.1, 0.2), 0.14, cor="grafite", rot=(-25, 0, 0))
    corpo.finalizar(pai=raiz, pos=(0, 0, 0.45))
    for nome, x in (("GiraHeliceEsquerda", -0.24), ("GiraHeliceDireita", 0.24)):
        helice = kit.Modelo(nome)
        helice.caixa((0.3, 0.05, 0.012), pos=(0, 0, 0), cor="cinza")
        helice.caixa((0.05, 0.3, 0.012), pos=(0, 0, 0), cor="cinza")
        helice.finalizar(pai=raiz.children[0], pos=(x, 0, 0.225))
    return raiz


def inimigo_rato_de_sucata():
    """Inimigo comum: máquina rasteira de quatro patas, feita de sobra, com mandíbula."""
    raiz = kit.vazio("inimigo_rato_de_sucata")
    corpo = kit.Modelo("Corpo")
    corpo.caixa((0.3, 0.5, 0.18), pos=(0, 0, 0.14), cor="ferrugem", chanfro=0.05, degrade=True)
    corpo.caixa((0.24, 0.2, 0.16), pos=(0, -0.3, 0.16), cor="cinza_escuro", chanfro=0.04)
    olhar_bravo(corpo, (0, -0.405, 0.24), largura=0.18, cor="amarelo")
    dentes(corpo, (0, -0.4, 0.16), largura=0.2, quantidade=4, tamanho=0.06)
    for x in (-0.2, 0.2):
        for y in (-0.16, 0.18):
            corpo.caixa((0.06, 0.08, 0.2), pos=(x, y, 0.0), cor="chumbo", rot=(0, 20 if x > 0 else -20, 0))
            corpo.caixa((0.12, 0.06, 0.05), pos=(x * 0.75, y, 0.17), cor="grafite")
    for y in (-0.1, 0.05, 0.2):
        espinho(corpo, (0, y, 0.32), 0.12, cor="cinza_metal")
    corpo.cilindro(0.025, 0.3, pos=(0, 0.24, 0.24), cor="grafite", lados=5, rot=(60, 0, 0))
    corpo.finalizar(pai=raiz)
    return raiz


def chefe_zelador():
    """Subchefe da galeria: o robô de limpeza que ninguém desligou, reformado com serras.

    Corpo baixo e largo, visor bravo, um limpa-trilho dentado na frente, duas serras que
    giram (`GiraSerraEsquerda` e `GiraSerraDireita`) e a sirene no alto (`GiraSirene`).
    """
    raiz = kit.vazio("chefe_zelador")
    corpo = kit.Modelo("Corpo")
    corpo.caixa((0.7, 0.62, 0.14), pos=(0, 0, 0.04), cor="chumbo", chanfro=0.03)
    corpo.caixa((0.62, 0.54, 0.32), pos=(0, 0, 0.18), cor="azul", chanfro=0.06, degrade=True)
    corpo.caixa((0.46, 0.4, 0.18), pos=(0, 0.03, 0.5), cor="cinza_escuro", chanfro=0.05)
    olhar_bravo(corpo, (0, -0.175, 0.57), largura=0.36, cor="magenta")
    faixa_de_aviso(corpo, 0.62, (0, -0.275, 0.3), altura=0.08)
    corpo.prisma([(-0.36, 0.0), (0.36, 0.0), (0.3, 0.2), (-0.3, 0.2)], 0.1, pos=(0, -0.33, 0.04),
                 cor="cinza_escuro", rot=(25, 0, 0))
    dentes(corpo, (0, -0.4, 0.04), largura=0.66, quantidade=7, tamanho=0.1, cor="amarelo")
    for x in (-0.3, 0.3):
        corpo.cilindro(0.11, 0.1, pos=(x - 0.05, 0.14, 0.11), cor="grafite", lados=8, rot=(0, 90, 0))
        espinho(corpo, (x, 0.1, 0.5), 0.26, cor="cinza_metal", rot=(0, 35 if x > 0 else -35, 0))
        corpo.cilindro(0.05, 0.22, pos=(x * 0.6, 0.26, 0.5), cor="grafite", lados=6)
    corpo.caixa((0.2, 0.2, 0.05), pos=(0, 0.06, 0.68), cor="chumbo")
    corpo.finalizar(pai=raiz)
    for nome, x in (("GiraSerraEsquerda", -0.3), ("GiraSerraDireita", 0.3)):
        peca = kit.Modelo(nome)
        serra(peca, 0.2)
        peca.finalizar(pai=raiz, pos=(x, -0.5, 0.14))
    sirene = kit.Modelo("GiraSirene")
    sirene.cilindro(0.07, 0.08, pos=(0, 0, 0), cor="amarelo", lados=6, brilho=True)
    sirene.caixa((0.03, 0.16, 0.05), pos=(0, 0, 0.015), cor="laranja", brilho=True)
    sirene.finalizar(pai=raiz, pos=(0, 0.06, 0.73))
    return raiz


def chefe_compactador():
    """Chefe da galeria: a prensa de sucata que decidiu que tudo é sucata.

    Esteiras, tronco de máquina pesada, ombreiras com espinhos, grelha de dentes, visor
    bravo e dois braços de pistão que terminam em placa cravejada (`BracoEsquerdo` e
    `BracoDireito`, com o pivô no ombro). O reator do peito (`GiraReator`) gira.
    """
    raiz = kit.vazio("chefe_compactador")
    corpo = kit.Modelo("Corpo")
    for x in (-0.3, 0.3):
        corpo.caixa((0.2, 0.74, 0.22), pos=(x, 0, 0), cor="grafite", chanfro=0.07)
        corpo.caixa((0.22, 0.52, 0.1), pos=(x, 0, 0.06), cor="chumbo")
    corpo.caixa((0.46, 0.5, 0.14), pos=(0, 0, 0.12), cor="chumbo")
    corpo.caixa((0.66, 0.5, 0.36), pos=(0, 0, 0.26), cor="laranja", chanfro=0.05, degrade=True)
    corpo.caixa((0.86, 0.44, 0.14), pos=(0, 0.02, 0.6), cor="cinza_escuro", chanfro=0.04)
    faixa_de_aviso(corpo, 0.66, (0, -0.255, 0.27), altura=0.08)
    corpo.cilindro(0.13, 0.04, pos=(0, -0.25, 0.47), cor="grafite", lados=8, rot=(90, 0, 0))
    for x in (-0.36, 0.36):
        sinal = 1 if x > 0 else -1
        espinho(corpo, (x, 0.02, 0.72), 0.3, raio=0.07, cor="cinza_metal", rot=(0, sinal * 30, 0))
        espinho(corpo, (x * 0.7, 0.12, 0.72), 0.2, raio=0.05, cor="cinza_metal", rot=(0, sinal * 15, 0))
    for x in (-0.14, 0.14):
        corpo.cilindro(0.06, 0.34, pos=(x, 0.22, 0.7), cor="cinza_metal", lados=8)
        corpo.cilindro(0.075, 0.05, pos=(x, 0.22, 1.02), cor="grafite", lados=8)
    corpo.finalizar(pai=raiz)
    reator = kit.Modelo("GiraReator")
    reator.cilindro(0.09, 0.03, pos=(0, 0, -0.015), cor="magenta", lados=6, brilho=True)
    reator.caixa((0.22, 0.04, 0.02), pos=(0, 0, -0.01), cor="roxo")
    reator.caixa((0.04, 0.22, 0.02), pos=(0, 0, -0.01), cor="roxo")
    objeto = reator.finalizar(pai=raiz, pos=(0, -0.3, 0.47))
    objeto.rotation_euler = (1.5708, 0, 0)
    cabeca = kit.Modelo("Cabeca")
    cabeca.caixa((0.32, 0.28, 0.2), pos=(0, 0, 0), cor="amarelo", chanfro=0.05)
    cabeca.caixa((0.36, 0.22, 0.05), pos=(0, 0.03, 0.19), cor="chumbo")
    olhar_bravo(cabeca, (0, -0.145, 0.11), largura=0.28, cor="magenta")
    cabeca.caixa((0.26, 0.05, 0.07), pos=(0, -0.14, -0.02), cor="grafite")
    dentes(cabeca, (0, -0.17, 0.045), largura=0.24, quantidade=5, tamanho=0.06, para_baixo=True)
    for x in (-0.13, 0.13):
        espinho(cabeca, (x, 0.04, 0.22), 0.16, raio=0.035, cor="grafite", rot=(0, 20 if x > 0 else -20, 0))
    cabeca.finalizar(pai=raiz, pos=(0, -0.08, 0.74))
    for nome, lado in (("BracoEsquerdo", -1.0), ("BracoDireito", 1.0)):
        braco = kit.Modelo(nome)
        braco.esfera(0.14, pos=(0, 0, 0), cor="chumbo")
        braco.cilindro(0.1, 0.3, pos=(0, 0, -0.3), cor="cinza_escuro", lados=8)
        braco.cilindro(0.055, 0.3, pos=(0, 0, -0.48), cor="branco", lados=8)
        braco.caixa((0.3, 0.38, 0.12), pos=(0, -0.04, -0.6), cor="chumbo", chanfro=0.03)
        braco.caixa((0.32, 0.4, 0.04), pos=(0, -0.04, -0.6), cor="amarelo")
        for x in (-0.09, 0.09):
            for y in (-0.16, 0.0, 0.1):
                espinho(braco, (x, y - 0.04, -0.6), 0.09, raio=0.035, cor="cinza_metal", rot=(180, 0, 0))
        braco.finalizar(pai=raiz, pos=(lado * 0.58, -0.04, 0.68))
    return raiz


MODELOS = [inimigo_drone_de_solda, inimigo_rato_de_sucata, chefe_zelador, chefe_compactador]

if __name__ == "__main__":
    kit.produzir(MODELOS, "inimigos_da_galeria", espaco=0.5)
