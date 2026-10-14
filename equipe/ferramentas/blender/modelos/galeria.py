"""Peças da Galeria de Manutenção: tubulação, quadro elétrico, gerador e cenário.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/galeria.py", run_name="__main__")
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit


def _faixa_de_aviso(m, largura, pos, altura=0.12, profundidade=0.04, partes=6):
    """Faixa amarela e grafite na horizontal, a marca de perigo do jogo."""
    passo = largura / partes
    for indice in range(partes):
        cor = "amarelo" if indice % 2 == 0 else "grafite"
        x = pos[0] - largura / 2.0 + passo * (indice + 0.5)
        m.caixa((passo, profundidade, altura), pos=(x, pos[1], pos[2]), cor=cor)


def _tubo_deitado(m, comprimento, raio, pos, cor):
    """Tubo ao longo de X, centrado em `pos`, com um flange em cada ponta e um no meio."""
    m.cilindro(raio, comprimento, pos=(pos[0] - comprimento / 2.0, pos[1], pos[2]), cor=cor,
               rot=(0, 90, 0), lados=10)
    for desvio in (-comprimento / 2.0 + 0.04, -0.03, comprimento / 2.0 - 0.1):
        m.cilindro(raio + 0.035, 0.06, pos=(pos[0] + desvio, pos[1], pos[2]), cor="chumbo",
                   rot=(0, 90, 0), lados=10)


def tubo_reto():
    """Tubo de 2 de comprimento preso à parede. A origem fica no plano da parede."""
    m = kit.Modelo("tubo_reto")
    _tubo_deitado(m, 2.0, 0.13, (0, -0.26, 1.25), "ferrugem")
    for x in (-0.6, 0.6):
        m.caixa((0.08, 0.3, 0.08), pos=(x, -0.15, 1.21), cor="grafite")
    return m.finalizar()


def tubo_duplo():
    """Dois tubos paralelos de 2 de comprimento, um grosso e um fino, presos à parede."""
    m = kit.Modelo("tubo_duplo")
    _tubo_deitado(m, 2.0, 0.16, (0, -0.3, 0.75), "azul")
    _tubo_deitado(m, 2.0, 0.08, (0, -0.2, 1.2), "cinza_metal")
    for x in (-0.6, 0.6):
        m.caixa((0.08, 0.3, 0.7), pos=(x, -0.15, 0.6), cor="grafite")
    return m.finalizar()


def tubo_descida():
    """Tubo que vem pela parede e desce até o chão, com uma curva em gomos."""
    m = kit.Modelo("tubo_descida")
    raio = 0.13
    m.cilindro(raio, 0.8, pos=(-1.0, -0.26, 1.25), cor="ferrugem", rot=(0, 90, 0), lados=10)
    m.cilindro(raio + 0.035, 0.06, pos=(-0.96, -0.26, 1.25), cor="chumbo", rot=(0, 90, 0), lados=10)
    m.cilindro(raio, 0.3, pos=(-0.24, -0.26, 1.25), cor="ferrugem", rot=(0, 135, 0), lados=10)
    m.esfera(raio * 1.05, pos=(-0.22, -0.26, 1.25), cor="ferrugem")
    m.esfera(raio * 1.05, pos=(0.0, -0.26, 1.03), cor="ferrugem")
    m.cilindro(raio, 1.03, pos=(0.0, -0.26, 0.0), cor="ferrugem", lados=10)
    m.cilindro(raio + 0.035, 0.06, pos=(0.0, -0.26, 0.86), cor="chumbo", lados=10)
    m.cilindro(raio + 0.06, 0.08, pos=(0.0, -0.26, 0.0), cor="chumbo", lados=10)
    m.caixa((0.08, 0.3, 0.08), pos=(-0.7, -0.15, 1.21), cor="grafite")
    return m.finalizar()


def tubo_coluna():
    """Tubo grosso em pé, do chão ao teto. É a peça alta que pode cobrir o jogador."""
    m = kit.Modelo("tubo_coluna")
    m.cilindro(0.26, 2.3, pos=(0, 0, 0), cor="cinza_metal", lados=12, degrade=True)
    m.cilindro(0.34, 0.14, pos=(0, 0, 0), cor="chumbo", lados=12)
    for z in (0.75, 1.5):
        m.cilindro(0.31, 0.08, pos=(0, 0, z), cor="chumbo", lados=12)
    m.cilindro(0.34, 0.12, pos=(0, 0, 2.2), cor="chumbo", lados=12)
    m.caixa((0.2, 0.05, 0.14), pos=(0, -0.26, 1.05), cor="amarelo")
    return m.finalizar()


def valvula():
    """Registro de chão: um toco de tubo com o volante em cima."""
    m = kit.Modelo("valvula")
    m.cilindro(0.2, 0.08, pos=(0, 0, 0), cor="chumbo", lados=10)
    m.cilindro(0.13, 0.5, pos=(0, 0, 0.08), cor="azul", lados=10)
    m.cilindro(0.17, 0.07, pos=(0, 0, 0.5), cor="chumbo", lados=10)
    m.cilindro(0.035, 0.22, pos=(0, 0, 0.57), cor="grafite", lados=6)
    m.cilindro(0.2, 0.045, pos=(0, 0, 0.76), cor="amarelo", lados=8)
    m.cilindro(0.13, 0.05, pos=(0, 0, 0.759), cor="grafite", lados=8)
    m.caixa((0.38, 0.04, 0.03), pos=(0, 0, 0.775), cor="amarelo")
    m.caixa((0.04, 0.38, 0.03), pos=(0, 0, 0.775), cor="amarelo")
    return m.finalizar()


def painel_eletrico():
    """Quadro elétrico de parede, com luzes acesas. A origem fica no plano da parede."""
    m = kit.Modelo("painel_eletrico")
    m.caixa((0.9, 0.22, 1.2), pos=(0, -0.11, 0.35), cor="cinza_medio", chanfro=0.03)
    m.caixa((0.74, 0.04, 0.6), pos=(0, -0.235, 0.5), cor="cinza_escuro")
    m.caixa((0.05, 0.05, 0.16), pos=(0.27, -0.26, 0.7), cor="grafite")
    _faixa_de_aviso(m, 0.74, (0, -0.235, 1.34))
    for indice, cor in enumerate(("amarelo", "azul_claro", "verde", "azul_claro")):
        m.caixa((0.09, 0.04, 0.09), pos=(-0.27 + indice * 0.18, -0.235, 1.18), cor=cor, brilho=True)
    m.cilindro(0.04, 0.35, pos=(0.3, -0.11, 0.0), cor="grafite", lados=6)
    m.cilindro(0.04, 0.35, pos=(-0.3, -0.11, 0.0), cor="grafite", lados=6)
    return m.finalizar()


def luminaria_de_tunel():
    """Luminária de parede com grade. A origem fica no plano da parede, na altura do chão."""
    m = kit.Modelo("luminaria_de_tunel")
    m.caixa((0.3, 0.08, 0.2), pos=(0, -0.04, 1.6), cor="chumbo")
    m.caixa((0.22, 0.14, 0.26), pos=(0, -0.15, 1.57), cor="amarelo", brilho=True)
    for x in (-0.12, 0.0, 0.12):
        m.caixa((0.025, 0.18, 0.3), pos=(x, -0.15, 1.55), cor="grafite")
    m.caixa((0.3, 0.2, 0.03), pos=(0, -0.14, 1.84), cor="grafite")
    m.caixa((0.3, 0.2, 0.03), pos=(0, -0.14, 1.53), cor="grafite")
    return m.finalizar()


def barril():
    """Barril de produto químico, com dois aros."""
    m = kit.Modelo("barril")
    m.cilindro(0.2, 0.52, pos=(0, 0, 0), cor="azul", lados=10, degrade=True, cor_das_tampas="chumbo")
    for z in (0.12, 0.36):
        m.cilindro(0.215, 0.04, pos=(0, 0, z), cor="chumbo", lados=10)
    m.cilindro(0.05, 0.03, pos=(0.08, 0, 0.52), cor="amarelo", lados=6)
    return m.finalizar()


def barril_de_aviso():
    """Barril amarelo com faixa escura, o que guarda coisa perigosa."""
    m = kit.Modelo("barril_de_aviso")
    m.cilindro(0.2, 0.52, pos=(0, 0, 0), cor="amarelo", lados=10, degrade=True, cor_das_tampas="chumbo")
    m.cilindro(0.208, 0.14, pos=(0, 0, 0.19), cor="grafite", lados=10)
    for z in (0.08, 0.42):
        m.cilindro(0.215, 0.04, pos=(0, 0, z), cor="chumbo", lados=10)
    return m.finalizar()


def caixote_de_metal():
    """Caixote de ferramenta, meio metro de lado, com cantoneiras."""
    m = kit.Modelo("caixote_de_metal")
    m.caixa((0.5, 0.5, 0.46), pos=(0, 0, 0), cor="cinza_medio", chanfro=0.02)
    for x in (-0.22, 0.22):
        for y in (-0.22, 0.22):
            m.caixa((0.08, 0.08, 0.48), pos=(x, y, 0), cor="chumbo")
    m.caixa((0.52, 0.52, 0.05), pos=(0, 0, 0.43), cor="chumbo")
    m.caixa((0.2, 0.03, 0.12), pos=(0, -0.26, 0.18), cor="amarelo")
    return m.finalizar()


def ventilador_de_parede():
    """Exaustor redondo de parede. A hélice é um nó à parte, `GiraHelice`, que gira no jogo.

    A origem fica no plano da parede, na altura do chão.
    """
    raiz = kit.vazio("ventilador_de_parede")
    carcaca = kit.Modelo("Carcaca")
    carcaca.caixa((1.5, 0.2, 1.5), pos=(0, -0.1, 0.4), cor="chumbo", chanfro=0.04)
    carcaca.cilindro(0.64, 0.06, pos=(0, -0.2, 1.15), cor="preto", lados=14, rot=(90, 0, 0))
    for angulo in (0, 45, 90, 135):
        carcaca.caixa((1.3, 0.03, 0.04), pos=(0, -0.3, 1.13), cor="cinza_medio", rot=(0, angulo, 0))
    carcaca.mover([], pos=(0, 0, 0))
    carcaca.finalizar(pai=raiz)
    helice = kit.Modelo("GiraHelice")
    helice.cilindro(0.12, 0.08, pos=(0, 0.04, 0), cor="amarelo", lados=8, rot=(90, 0, 0))
    for angulo in (0, 120, 240):
        helice.caixa((0.22, 0.03, 0.5), pos=(0, 0, 0.06), cor="cinza_metal", rot=(0, angulo, 0))
    helice.finalizar(pai=raiz, pos=(0, -0.25, 1.15))
    return raiz


def movel_gerador_da_corporacao():
    """O gerador que o objetivo paralelo manda destruir. Duas partes: `Corpo` e `Nucleo`.

    O núcleo é a parte acesa; o jogo apaga quando o gerador cai.
    """
    raiz = kit.vazio("movel_gerador_da_corporacao")
    corpo = kit.Modelo("Corpo")
    corpo.caixa((0.86, 0.86, 0.2), pos=(0, 0, 0), cor="chumbo", chanfro=0.03)
    corpo.caixa((0.74, 0.74, 0.34), pos=(0, 0, 0.2), cor="cinza_escuro")
    for x in (-0.3, 0.3):
        for y in (-0.3, 0.3):
            corpo.caixa((0.12, 0.12, 0.9), pos=(x, y, 0.2), cor="cinza_medio", chanfro=0.02)
    corpo.caixa((0.8, 0.8, 0.14), pos=(0, 0, 0.98), cor="chumbo", chanfro=0.03)
    corpo.cilindro(0.1, 0.16, pos=(0.2, 0.2, 1.12), cor="grafite", lados=8)
    corpo.caixa((0.4, 0.03, 0.14), pos=(0, -0.375, 0.3), cor="magenta")
    _faixa_de_aviso(corpo, 0.74, (0, -0.42, 0.04), altura=0.1)
    corpo.finalizar(pai=raiz)
    nucleo = kit.Modelo("Nucleo")
    nucleo.cilindro(0.2, 0.44, pos=(0, 0, -0.22), cor="magenta", lados=8, brilho=True)
    for z in (-0.16, 0.0, 0.16):
        nucleo.cilindro(0.23, 0.04, pos=(0, 0, z - 0.02), cor="roxo", lados=8)
    nucleo.finalizar(pai=raiz, pos=(0, 0, 0.76))
    return raiz


def conteiner_de_manutencao():
    """Editado de `kenney_city_kit_industrial/shipping_container_a.glb`.

    O contêiner original, três vezes maior, com ferrugem, um tubo saindo do teto e a
    faixa de aviso da galeria.
    """
    importados = kit.importar_glb("kenney_city_kit_industrial/shipping_container_a.glb")
    origem = next(objeto for objeto in importados if objeto.type == "MESH")
    m = kit.Modelo("conteiner_de_manutencao")
    m.malha_de(origem, escala=(3, 3, 3))
    kit.apagar(importados)
    m.caixa((0.5, 0.03, 0.4), pos=(-0.2, -1.245, 0.1), cor="ferrugem")
    m.caixa((0.03, 0.7, 0.3), pos=(0.565, 0.4, 0.0), cor="ferrugem")
    m.caixa((0.03, 0.4, 0.5), pos=(-0.565, -0.5, 0.3), cor="ferrugem")
    m.cilindro(0.1, 0.4, pos=(0.25, 0.7, 1.05), cor="cinza_metal", lados=8)
    m.cilindro(0.14, 0.06, pos=(0.25, 0.7, 1.4), cor="chumbo", lados=8)
    return m.finalizar()


def tanque_de_pressao():
    """Editado de `kenney_city_kit_industrial/detail_tank.glb`.

    O tanque original, duas vezes e meia maior, com manômetro, registro e base de aviso.
    """
    importados = kit.importar_glb("kenney_city_kit_industrial/detail_tank.glb")
    origem = next(objeto for objeto in importados if objeto.type == "MESH")
    m = kit.Modelo("tanque_de_pressao")
    m.malha_de(origem, pos=(0, 0, 0.08), escala=(2.5, 2.5, 2.5))
    kit.apagar(importados)
    m.caixa((2.3, 1.45, 0.08), pos=(0, 0, 0), cor="grafite")
    _faixa_de_aviso(m, 2.3, (0, -0.735, 0.0), altura=0.08, partes=10)
    m.cilindro(0.11, 0.05, pos=(0.5, -0.66, 0.75), cor="branco", lados=8, rot=(90, 0, 0))
    m.cilindro(0.13, 0.03, pos=(0.5, -0.65, 0.75), cor="chumbo", lados=8, rot=(90, 0, 0))
    return m.finalizar()


MODELOS = [
    tubo_reto, tubo_duplo, tubo_descida, tubo_coluna, valvula, painel_eletrico,
    luminaria_de_tunel, barril, barril_de_aviso, caixote_de_metal, ventilador_de_parede,
    movel_gerador_da_corporacao, conteiner_de_manutencao, tanque_de_pressao,
]

if __name__ == "__main__":
    kit.produzir(MODELOS, "galeria")
