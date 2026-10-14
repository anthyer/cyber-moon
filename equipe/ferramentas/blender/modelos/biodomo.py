"""Peças do Biodomo Abandonado: estufa, canteiros, plantas que tomaram conta e as sementes.

As plantas vêm do `kenney_nature_kit`, repintadas na paleta do pacote e juntadas a peças
novas (vaso, canteiro, contêiner). Isso é o que o projeto chama de modelo editado.

Rodar dentro do Blender:
    import runpy; runpy.run_path("<repositorio>/equipe/ferramentas/blender/modelos/biodomo.py", run_name="__main__")
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit

# Como cada material do Nature Kit entra na paleta do pacote.
CORES_DE_PLANTA = {
    "leafs": "verde", "grass": "verde", "wood": "marrom", "dirt": "marrom",
    "corn": "amarelo", "purple": "roxo", "": "verde",
}


def _planta(m, arquivo, pos=(0, 0, 0), escala=1.0, rot=(0, 0, 0), cores=None):
    """Copia um modelo do Nature Kit para dentro de `m`, já repintado."""
    importados = kit.importar_glb("kenney_nature_kit/" + arquivo + ".glb")
    for origem in importados:
        if origem.type == "MESH":
            m.malha_de(origem, pos=pos, rot=rot, escala=(escala, escala, escala),
                       cor=cores if cores is not None else CORES_DE_PLANTA)
    kit.apagar(importados)


def chao_terra_placa():
    """Placa de 2 por 2 de terra de canteiro, com moldura de concreto."""
    m = kit.Modelo("chao_terra_placa")
    m.caixa((2.0, 2.0, 0.1), pos=(0, 0, -0.12), cor="cinza_medio")
    m.caixa((1.84, 1.84, 0.02), pos=(0, 0, -0.02), cor="marrom")
    for y in (-0.55, 0.0, 0.55):
        m.caixa((1.7, 0.2, 0.004), pos=(0, y, 0.0), cor="ferrugem")
    return m.finalizar()


def chao_grama_placa():
    """Placa de 2 por 2 de piso tomado pelo mato: verde com manchas mais escuras."""
    m = kit.Modelo("chao_grama_placa")
    m.caixa((2.0, 2.0, 0.1), pos=(0, 0, -0.12), cor="cinza_medio")
    m.caixa((2.0, 2.0, 0.02), pos=(0, 0, -0.02), cor="verde")
    for x, y, tamanho in ((-0.5, 0.4, 0.5), (0.5, -0.5, 0.6), (0.3, 0.6, 0.3), (-0.6, -0.5, 0.35)):
        m.cilindro(tamanho / 2.0, 0.004, pos=(x, y, 0.0), cor="verde_folha", lados=7, degrade=True)
    return m.finalizar()


def parede_de_estufa():
    """Módulo de parede da estufa, 2 de largura por 2 de altura: caixilho de metal e vidro."""
    m = kit.Modelo("parede_de_estufa")
    m.caixa((2.0, 0.36, 0.4), pos=(0, 0, 0), cor="cinza_medio", chanfro=0.03)
    m.caixa((1.9, 0.08, 1.5), pos=(0, 0, 0.4), cor="azul_palido", degrade=True)
    for x in (-0.96, 0.0, 0.96):
        m.caixa((0.1, 0.16, 1.6), pos=(x, 0, 0.4), cor="branco")
    m.caixa((2.0, 0.16, 0.08), pos=(0, 0, 1.1), cor="branco")
    m.caixa((2.0, 0.2, 0.12), pos=(0, 0, 1.9), cor="branco")
    return m.finalizar()


def parede_de_estufa_baixa():
    """Mureta da estufa para o lado da câmera: uma floreira baixa, com mato dentro."""
    m = kit.Modelo("parede_de_estufa_baixa")
    m.caixa((2.0, 0.4, 0.3), pos=(0, 0, 0), cor="cinza_medio", chanfro=0.03)
    m.caixa((1.84, 0.26, 0.04), pos=(0, 0, 0.28), cor="marrom")
    for x in (-0.6, 0.0, 0.6):
        _planta(m, "grass_large", pos=(x, 0, 0.3), escala=0.9)
    return m.finalizar()


def canteiro_hidroponico():
    """Canteiro elevado de hidroponia, com a água aparente e as mudas crescidas."""
    m = kit.Modelo("canteiro_hidroponico")
    for x in (-0.75, 0.75):
        m.caixa((0.1, 0.5, 0.4), pos=(x, 0, 0), cor="chumbo")
    m.caixa((1.8, 0.64, 0.24), pos=(0, 0, 0.36), cor="branco", chanfro=0.04)
    m.caixa((1.66, 0.5, 0.03), pos=(0, 0, 0.585), cor="azul_claro")
    m.cilindro(0.05, 1.8, pos=(-0.9, 0.36, 0.42), cor="azul", lados=6, rot=(0, 90, 0))
    for indice, x in enumerate((-0.6, -0.2, 0.2, 0.6)):
        arquivo = "crops_leafs_stage_b" if indice % 2 == 0 else "plant_bush_small"
        _planta(m, arquivo, pos=(x, 0, 0.6), escala=1.1, rot=(0, 0, indice * 70))
    return m.finalizar()


def bancada_de_mudas():
    """Bancada de laboratório com bandejas de muda e uma luz de cultivo acesa em cima."""
    m = kit.Modelo("bancada_de_mudas")
    m.caixa((1.4, 0.6, 0.06), pos=(0, 0, 0.44), cor="cinza", chanfro=0.02)
    for x in (-0.62, 0.62):
        for y in (-0.22, 0.22):
            m.caixa((0.07, 0.07, 0.44), pos=(x, y, 0), cor="chumbo")
    for x in (-0.38, 0.38):
        m.caixa((0.52, 0.4, 0.07), pos=(x, 0, 0.5), cor="grafite")
        for dx in (-0.14, 0.0, 0.14):
            m.cilindro(0.035, 0.08, pos=(x + dx, 0, 0.57), cor="verde", lados=5, raio_do_topo=0.0)
    for x in (-0.66, 0.66):
        m.caixa((0.04, 0.04, 0.5), pos=(x, 0.26, 0.5), cor="chumbo")
    m.caixa((1.36, 0.1, 0.05), pos=(0, 0.26, 0.98), cor="chumbo")
    m.caixa((1.2, 0.08, 0.03), pos=(0, 0.26, 0.95), cor="magenta", brilho=True)
    return m.finalizar()


def lampada_de_cultivo():
    """Poste com luz de cultivo magenta, a cor que marca o biodomo."""
    m = kit.Modelo("lampada_de_cultivo")
    m.cilindro(0.16, 0.08, pos=(0, 0, 0), cor="chumbo", lados=8)
    m.cilindro(0.04, 1.5, pos=(0, 0, 0.08), cor="cinza_metal", lados=6)
    m.caixa((0.06, 0.5, 0.06), pos=(0, -0.2, 1.52), cor="cinza_metal")
    m.caixa((0.5, 0.24, 0.08), pos=(0, -0.42, 1.44), cor="chumbo", chanfro=0.02)
    m.caixa((0.42, 0.18, 0.03), pos=(0, -0.42, 1.41), cor="magenta", brilho=True)
    return m.finalizar()


def arvore_em_vaso():
    """Editado de `kenney_nature_kit/tree_default.glb`: a árvore num vaso de laboratório."""
    m = kit.Modelo("arvore_em_vaso")
    m.cilindro(0.34, 0.4, pos=(0, 0, 0), cor="branco", lados=8, raio_do_topo=0.4, degrade=True)
    m.cilindro(0.42, 0.06, pos=(0, 0, 0.4), cor="chumbo", lados=8)
    m.cilindro(0.34, 0.02, pos=(0, 0, 0.45), cor="marrom", lados=8)
    m.caixa((0.2, 0.03, 0.1), pos=(0, -0.37, 0.16), cor="magenta", brilho=True)
    _planta(m, "tree_default", pos=(0, 0, 0.5), escala=1.25)
    return m.finalizar()


def arvore_que_rompeu_o_piso():
    """Editado de `kenney_nature_kit/tree_oak.glb`: a árvore que cresceu e quebrou o piso."""
    m = kit.Modelo("arvore_que_rompeu_o_piso")
    _planta(m, "tree_oak", pos=(0, 0, 0.02), escala=1.5)
    for angulo, distancia, inclinacao in ((0, 0.42, 22), (80, 0.48, -18), (150, 0.4, 25), (215, 0.5, 15), (290, 0.44, -24)):
        placa = m.caixa((0.42, 0.34, 0.06), pos=(distancia, 0, 0.02), cor="cinza_medio", rot=(0, -inclinacao, 0))
        m.mover(placa, rot=(0, 0, angulo))
    m.cilindro(0.5, 0.03, pos=(0, 0, 0), cor="marrom", lados=8)
    return m.finalizar()


def conteiner_tomado_pelo_mato():
    """Editado de `kenney_city_kit_industrial/shipping_container_b.glb`.

    O contêiner três vezes maior, com arbustos no teto e cipó descendo pela lateral.
    """
    importados = kit.importar_glb("kenney_city_kit_industrial/shipping_container_b.glb")
    origem = next(objeto for objeto in importados if objeto.type == "MESH")
    m = kit.Modelo("conteiner_tomado_pelo_mato")
    m.malha_de(origem, escala=(3, 3, 3))
    kit.apagar(importados)
    _planta(m, "plant_bush_large", pos=(0.1, 0.5, 1.02), escala=1.3)
    _planta(m, "plant_bush", pos=(-0.15, -0.6, 1.02), escala=1.2, rot=(0, 0, 40))
    for y, comprimento in ((-0.9, 0.7), (-0.2, 0.45), (0.3, 0.85), (0.85, 0.5)):
        m.caixa((0.04, 0.12, comprimento), pos=(-0.58, y, 1.05 - comprimento), cor="verde_folha")
        m.caixa((0.05, 0.2, 0.12), pos=(-0.59, y, 1.0 - comprimento), cor="verde")
    return m.finalizar()


def tanque_de_nutrientes():
    """Tanque em pé de solução nutritiva, com o visor de nível aceso."""
    m = kit.Modelo("tanque_de_nutrientes")
    m.cilindro(0.42, 0.12, pos=(0, 0, 0), cor="chumbo", lados=10)
    m.cilindro(0.38, 1.2, pos=(0, 0, 0.12), cor="branco", lados=10, degrade=True)
    m.cilindro(0.38, 0.18, pos=(0, 0, 1.32), cor="cinza", lados=10, raio_do_topo=0.2)
    m.cilindro(0.08, 0.12, pos=(0, 0, 1.5), cor="chumbo", lados=6)
    m.caixa((0.14, 0.04, 0.8), pos=(0, -0.375, 0.3), cor="verde", brilho=True)
    m.caixa((0.2, 0.05, 0.86), pos=(0, -0.36, 0.27), cor="chumbo")
    for z in (0.4, 1.0):
        m.cilindro(0.395, 0.05, pos=(0, 0, z), cor="cinza_medio", lados=10)
    m.cilindro(0.06, 0.5, pos=(0.38, 0, 0.25), cor="azul", lados=6, rot=(0, 90, 0))
    return m.finalizar()


def aspersor():
    """Aspersor de irrigação, um poste baixo com a cabeça azul."""
    m = kit.Modelo("aspersor")
    m.cilindro(0.1, 0.05, pos=(0, 0, 0), cor="chumbo", lados=6)
    m.cilindro(0.035, 0.45, pos=(0, 0, 0.05), cor="cinza_metal", lados=6)
    m.cilindro(0.07, 0.07, pos=(0, 0, 0.5), cor="azul", lados=6)
    m.caixa((0.3, 0.03, 0.03), pos=(0, 0, 0.52), cor="azul")
    return m.finalizar()


def enfeite_cipo():
    """Cipó rasteiro que avança pelo piso. Sem colisão: o jogador passa por cima."""
    m = kit.Modelo("enfeite_cipo")
    trechos = ((-0.8, 0.0, 0.5, 20), (-0.35, 0.16, 0.5, -15), (0.1, 0.02, 0.55, 25), (0.55, 0.22, 0.5, -10))
    for x, y, comprimento, giro in trechos:
        m.caixa((comprimento, 0.07, 0.035), pos=(x, y, 0.0), cor="verde_folha", rot=(0, 0, giro))
    for x, y in ((-0.6, 0.12), (-0.1, 0.02), (0.35, 0.2), (0.8, 0.14)):
        m.cilindro(0.09, 0.02, pos=(x, y, 0.03), cor="verde", lados=5)
    _planta(m, "grass", pos=(0.0, 0.3, 0.0), escala=0.8)
    return m.finalizar()


def movel_caixa_de_sementes():
    """A caixa de sementes nativas que o objetivo paralelo manda resgatar."""
    m = kit.Modelo("movel_caixa_de_sementes")
    m.caixa((0.46, 0.34, 0.24), pos=(0, 0, 0), cor="creme", chanfro=0.02)
    for x in (-0.19, 0.19):
        m.caixa((0.06, 0.36, 0.25), pos=(x, 0, 0), cor="marrom")
    m.caixa((0.48, 0.36, 0.05), pos=(0, 0, 0.23), cor="verde", chanfro=0.015)
    m.caixa((0.16, 0.02, 0.1), pos=(0, -0.175, 0.07), cor="amarelo", brilho=True)
    m.cilindro(0.015, 0.1, pos=(0, 0, 0.28), cor="verde_folha", lados=4)
    for giro in (40, -40):
        m.caixa((0.1, 0.05, 0.015), pos=(0.045 if giro > 0 else -0.045, 0, 0.37), cor="verde", rot=(0, -giro * 0.5, 0), brilho=True)
    return m.finalizar()


MODELOS = [
    chao_terra_placa, chao_grama_placa, parede_de_estufa, parede_de_estufa_baixa,
    canteiro_hidroponico, bancada_de_mudas, lampada_de_cultivo, arvore_em_vaso,
    arvore_que_rompeu_o_piso, conteiner_tomado_pelo_mato, tanque_de_nutrientes, aspersor,
    enfeite_cipo, movel_caixa_de_sementes,
]

if __name__ == "__main__":
    kit.produzir(MODELOS, "biodomo")
