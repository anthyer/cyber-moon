"""Peças da Torre de Retransmissão: servidores, terminais, neon e a antena pirata.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/torre.py", run_name="__main__")
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit


def chao_tecnologico_placa():
    """Placa de 2 por 2 de piso elevado de sala de servidor, com um filete aceso."""
    m = kit.Modelo("chao_tecnologico_placa")
    m.caixa((2.0, 2.0, 0.1), pos=(0, 0, -0.12), cor="preto")
    for x in (-0.5, 0.5):
        for y in (-0.5, 0.5):
            m.caixa((0.95, 0.95, 0.02), pos=(x, y, -0.02), cor="cinza_escuro")
    m.caixa((2.0, 0.035, 0.012), pos=(0, 0, -0.012), cor="azul_claro", brilho=True)
    return m.finalizar()


def chao_tecnologico_circuito():
    """Variação da placa de servidor com uma trilha de circuito acesa, para marcar caminho."""
    m = kit.Modelo("chao_tecnologico_circuito")
    m.caixa((2.0, 2.0, 0.1), pos=(0, 0, -0.12), cor="preto")
    m.caixa((1.96, 1.96, 0.02), pos=(0, 0, -0.02), cor="cinza_escuro")
    trilha = ((0.0, -0.75, 0.05, 0.5), (0.25, -0.5, 0.55, 0.05), (0.5, -0.1, 0.05, 0.85),
              (0.0, 0.3, 1.05, 0.05), (-0.5, 0.62, 0.05, 0.7))
    for x, y, largura, comprimento in trilha:
        m.caixa((largura, comprimento, 0.004), pos=(x, y, 0.0), cor="magenta", brilho=True)
    for x, y in ((0.0, -0.98), (-0.5, 0.96), (0.5, 0.3)):
        m.cilindro(0.06, 0.005, pos=(x, y * 0.97, 0.0), cor="azul_claro", lados=6, brilho=True)
    return m.finalizar()


def parede_tecnologica():
    """Módulo de parede da torre, 2 por 2: painéis escuros, respiro e um filete de neon."""
    m = kit.Modelo("parede_tecnologica")
    m.caixa((2.0, 0.3, 1.9), pos=(0, 0, 0), cor="cinza_escuro", degrade=True)
    m.caixa((2.0, 0.36, 0.24), pos=(0, 0, 0), cor="preto", chanfro=0.03)
    m.caixa((2.0, 0.36, 0.12), pos=(0, 0, 1.88), cor="preto", chanfro=0.03)
    for x in (-0.5, 0.5):
        m.caixa((0.9, 0.34, 0.7), pos=(x, 0, 0.42), cor="chumbo", chanfro=0.03)
        for indice in range(3):
            m.caixa((0.6, 0.36, 0.035), pos=(x, 0, 1.52 + indice * 0.09), cor="preto")
    m.caixa((2.0, 0.33, 0.05), pos=(0, 0, 1.28), cor="magenta", brilho=True)
    return m.finalizar()


def parede_tecnologica_baixa():
    """Guarda-corpo baixo da torre para o lado da câmera, com um filete azul aceso."""
    m = kit.Modelo("parede_tecnologica_baixa")
    m.caixa((2.0, 0.26, 0.26), pos=(0, 0, 0), cor="preto", chanfro=0.03)
    m.caixa((2.0, 0.28, 0.04), pos=(0, 0, 0.26), cor="azul_claro", brilho=True)
    for x in (-0.9, 0.0, 0.9):
        m.caixa((0.12, 0.3, 0.34), pos=(x, 0, 0), cor="chumbo")
    return m.finalizar()


def _luzes_de_servidor(m, largura, y, z_inicial, linhas, cores):
    passo = largura / 5.0
    for linha in range(linhas):
        z = z_inicial + linha * 0.17
        m.caixa((largura, 0.02, 0.1), pos=(0, y + 0.005, z), cor="preto")
        for coluna in range(4):
            cor = cores[(linha * 3 + coluna) % len(cores)]
            m.caixa((0.06, 0.03, 0.035), pos=(-largura / 2.0 + passo * (coluna + 0.8), y, z + 0.03),
                    cor=cor, brilho=True)


def rack_de_servidor():
    """Armário de servidor de 1,7 de altura. É peça alta: fica no fundo ou some com o jogador atrás."""
    m = kit.Modelo("rack_de_servidor")
    m.caixa((0.7, 0.6, 1.66), pos=(0, 0, 0.04), cor="grafite", chanfro=0.03)
    m.caixa((0.74, 0.64, 0.06), pos=(0, 0, 0), cor="chumbo")
    m.caixa((0.74, 0.64, 0.06), pos=(0, 0, 1.66), cor="chumbo")
    _luzes_de_servidor(m, 0.56, -0.305, 0.2, 8, ("azul_claro", "verde", "azul_claro", "magenta", "amarelo"))
    return m.finalizar()


def rack_de_servidor_baixo():
    """Módulo de servidor de meia altura, que não cobre o jogador."""
    m = kit.Modelo("rack_de_servidor_baixo")
    m.caixa((0.9, 0.6, 0.6), pos=(0, 0, 0.04), cor="grafite", chanfro=0.03)
    m.caixa((0.94, 0.64, 0.06), pos=(0, 0, 0), cor="chumbo")
    m.caixa((0.94, 0.64, 0.05), pos=(0, 0, 0.62), cor="chumbo")
    _luzes_de_servidor(m, 0.74, -0.305, 0.14, 3, ("magenta", "azul_claro", "verde"))
    return m.finalizar()


def terminal():
    """Console de operador com a tela inclinada acesa."""
    m = kit.Modelo("terminal")
    m.caixa((0.9, 0.5, 0.42), pos=(0, 0.05, 0), cor="cinza_escuro", chanfro=0.03)
    m.prisma([(-0.3, 0.0), (0.3, 0.0), (0.3, 0.12), (-0.3, 0.34)], 0.9, pos=(0, 0.02, 0.42),
             cor="chumbo", rot=(0, 0, 90))
    m.caixa((0.74, 0.03, 0.3), pos=(0, -0.06, 0.5), cor="azul_claro", brilho=True, rot=(-52, 0, 0))
    for indice in range(3):
        m.caixa((0.5 - indice * 0.14, 0.035, 0.03), pos=(-0.1, -0.075 + indice * 0.075, 0.535 + indice * 0.06),
                cor="azul", brilho=True, rot=(-52, 0, 0))
    m.caixa((0.6, 0.03, 0.1), pos=(0, -0.205, 0.2), cor="preto")
    for x in (-0.2, 0.0, 0.2):
        m.caixa((0.06, 0.035, 0.04), pos=(x, -0.21, 0.23), cor="magenta", brilho=True)
    return m.finalizar()


def painel_neon():
    """Letreiro de neon de parede, com a marca da corporação. A origem fica no plano da parede."""
    m = kit.Modelo("painel_neon")
    m.caixa((1.5, 0.08, 0.7), pos=(0, -0.04, 1.05), cor="preto", chanfro=0.02)
    m.prisma([(-0.28, 0.0), (0.28, 0.0), (0.0, 0.46)], 0.05, pos=(-0.38, -0.1, 1.17), cor="magenta", brilho=True)
    m.prisma([(-0.13, 0.0), (0.13, 0.0), (0.0, 0.2)], 0.06, pos=(-0.38, -0.1, 1.22), cor="preto")
    for indice, largura in enumerate((0.62, 0.44, 0.54)):
        m.caixa((largura, 0.05, 0.08), pos=(0.02 + largura / 2.0, -0.1, 1.5 - indice * 0.15),
                cor="azul_claro", brilho=True)
    return m.finalizar()


def torre_de_resfriamento():
    """Unidade de resfriamento dos servidores. A hélice de cima é o nó `GiraHelice`."""
    raiz = kit.vazio("torre_de_resfriamento")
    corpo = kit.Modelo("Corpo")
    corpo.caixa((0.9, 0.9, 0.8), pos=(0, 0, 0.06), cor="cinza_medio", chanfro=0.04, degrade=True)
    corpo.caixa((0.96, 0.96, 0.08), pos=(0, 0, 0), cor="chumbo")
    for indice in range(4):
        corpo.caixa((0.7, 0.03, 0.06), pos=(0, -0.455, 0.2 + indice * 0.13), cor="preto")
    corpo.cilindro(0.38, 0.1, pos=(0, 0, 0.86), cor="chumbo", lados=12)
    corpo.cilindro(0.33, 0.02, pos=(0, 0, 0.95), cor="preto", lados=12)
    corpo.caixa((0.2, 0.03, 0.08), pos=(0.26, -0.455, 0.72), cor="azul_claro", brilho=True)
    corpo.finalizar(pai=raiz)
    helice = kit.Modelo("GiraHelice")
    helice.cilindro(0.07, 0.05, pos=(0, 0, 0), cor="amarelo", lados=6)
    for angulo in (0, 90):
        helice.caixa((0.6, 0.1, 0.015), pos=(0, 0, 0.02), cor="cinza", rot=(0, 0, angulo))
    helice.finalizar(pai=raiz, pos=(0, 0, 0.97))
    return raiz


def bateria_de_reserva():
    """Banco de bateria: um bloco baixo com bornes e a faixa de aviso."""
    m = kit.Modelo("bateria_de_reserva")
    m.caixa((1.0, 0.5, 0.5), pos=(0, 0, 0), cor="chumbo", chanfro=0.03)
    for indice in range(4):
        cor = "amarelo" if indice % 2 == 0 else "grafite"
        m.caixa((0.25, 0.52, 0.1), pos=(-0.375 + indice * 0.25, 0, 0.08), cor=cor)
    for x in (-0.3, 0.0, 0.3):
        m.cilindro(0.05, 0.08, pos=(x, 0, 0.5), cor="amarelo", lados=6)
    m.caixa((0.5, 0.03, 0.08), pos=(0, -0.255, 0.32), cor="verde", brilho=True)
    return m.finalizar()


def enfeite_cabos():
    """Feixe de cabos correndo pelo chão. Sem colisão: o jogador passa por cima."""
    m = kit.Modelo("enfeite_cabos")
    trechos = ((-0.75, 0.0, 0.55, 0), (-0.3, 0.12, 0.5, 28), (0.15, 0.2, 0.5, -8), (0.65, 0.1, 0.55, -22))
    for x, y, comprimento, giro in trechos:
        m.caixa((comprimento, 0.05, 0.03), pos=(x, y, 0.0), cor="preto", rot=(0, 0, giro))
        m.caixa((comprimento, 0.04, 0.025), pos=(x, y + 0.07, 0.0), cor="indigo", rot=(0, 0, giro))
    m.caixa((0.12, 0.2, 0.05), pos=(0.0, 0.2, 0.0), cor="chumbo")
    return m.finalizar()


def movel_antena_pirata():
    """A antena pirata do Kenji, que o objetivo paralelo manda proteger.

    Feita de sobra: base de caixote, mastro remendado e um prato que gira (`GiraPrato`).
    """
    raiz = kit.vazio("movel_antena_pirata")
    base = kit.Modelo("Base")
    base.caixa((0.7, 0.7, 0.3), pos=(0, 0, 0), cor="ferrugem", chanfro=0.03)
    base.caixa((0.74, 0.74, 0.06), pos=(0, 0, 0.12), cor="chumbo")
    base.caixa((0.3, 0.03, 0.14), pos=(0, -0.355, 0.14), cor="verde", brilho=True)
    base.cilindro(0.06, 1.3, pos=(0, 0, 0.3), cor="cinza_metal", lados=6)
    base.cilindro(0.08, 0.08, pos=(0, 0, 0.8), cor="amarelo", lados=6)
    for angulo in (0, 120, 240):
        escora = base.caixa((0.04, 0.04, 0.7), pos=(0.3, 0, 0.3), cor="chumbo", rot=(0, -24, 0))
        base.mover(escora, rot=(0, 0, angulo))
    base.caixa((0.26, 0.2, 0.18), pos=(0.26, 0.2, 0.3), cor="grafite")
    base.cilindro(0.015, 0.4, pos=(0.3, 0.24, 0.48), cor="grafite", lados=4)
    base.finalizar(pai=raiz)
    prato = kit.Modelo("GiraPrato")
    prato.cilindro(0.12, 0.14, pos=(0, 0, 0), cor="chumbo", lados=6)
    disco = prato.cilindro(0.2, 0.16, pos=(0, 0, 0), cor="cinza", lados=10, raio_do_topo=0.5, cor_das_tampas="branco")
    prato.mover(disco, pos=(0, -0.1, 0.22), rot=(60, 0, 0))
    haste = prato.cilindro(0.015, 0.36, pos=(0, 0, 0.1), cor="grafite", lados=4)
    prato.mover(haste, pos=(0, -0.1, 0.22), rot=(60, 0, 0))
    ponta = prato.esfera(0.05, pos=(0, 0, 0.48), cor="verde", brilho=True)
    prato.mover(ponta, pos=(0, -0.1, 0.22), rot=(60, 0, 0))
    prato.finalizar(pai=raiz, pos=(0, 0, 1.6))
    return raiz


def predio_de_fundo():
    """Editado de `kenney_city_kit_commercial/building_skyscraper_a.glb`.

    O arranha-céu, três vezes maior e repintado de escuro, com fileiras de janela acesa.
    Fica fora da arena, atrás da parede do fundo, para dar a vista da cidade.
    """
    importados = kit.importar_glb("kenney_city_kit_commercial/building_skyscraper_a.glb")
    m = kit.Modelo("predio_de_fundo")
    minimo = [1e9, 1e9, 1e9]
    maximo = [-1e9, -1e9, -1e9]
    for origem in importados:
        if origem.type != "MESH":
            continue
        vertices = m.malha_de(origem, escala=(3, 3, 3), cor="chumbo")
        for vertice in vertices:
            for eixo in range(3):
                minimo[eixo] = min(minimo[eixo], vertice.co[eixo])
                maximo[eixo] = max(maximo[eixo], vertice.co[eixo])
    kit.apagar(importados)
    largura = maximo[0] - minimo[0]
    altura = maximo[2] - minimo[2]
    cores = ("magenta", "azul_claro", "amarelo", "azul_claro")
    andares = int(altura / 0.7)
    for andar in range(1, andares):
        cor = cores[andar % len(cores)]
        comprimento = largura * (0.3 + 0.12 * ((andar * 7) % 3))
        desvio = (((andar * 5) % 4) - 1.5) * largura * 0.05
        m.caixa((comprimento, 0.04, 0.16), pos=(desvio, minimo[1] - 0.02, minimo[2] + andar * 0.7),
                cor=cor, brilho=True)
    return m.finalizar()


MODELOS = [
    chao_tecnologico_placa, chao_tecnologico_circuito, parede_tecnologica, parede_tecnologica_baixa,
    rack_de_servidor, rack_de_servidor_baixo, terminal, painel_neon, torre_de_resfriamento,
    bateria_de_reserva, enfeite_cabos, movel_antena_pirata, predio_de_fundo,
]

if __name__ == "__main__":
    kit.produzir(MODELOS, "torre")
