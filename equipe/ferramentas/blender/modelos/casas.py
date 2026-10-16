"""As casas da vila, uma para cada morador, e os lugares onde eles trabalham.

Pedido do Antonio (2026-10-15): casas feitas do zero, com mais detalhe e agradáveis de
olhar, cada uma com a cara de quem mora nela. As personas estão em `equipe/personas/`.

| Modelo | Quem | O que diz do morador |
|---|---|---|
| casa_da_marta | Marta, dona do mercado | horta de caixote, vasos, cadeira na varanda, forno de barro |
| mercado_da_marta | Marta | fachada com toldo, caixotes de fruta e verdura, letreiro |
| casa_da_iara | Iara, a médica | casa clara e arrumada, plantas, a maleta na janela |
| clinica_da_iara | Iara | cruz azul de neon (nunca vermelha), maca na varanda, banco de espera |
| casa_geminada | Kenji e Rafa | metade do Kenji com parabólica e cabos; metade do Rafa com a bicicleta de entrega e caixas |
| casa_do_vitor | Vitor, o mecânico | chapa remendada, tambor de óleo, peças penduradas |
| oficina_do_vitor | Vitor | garagem aberta, bancada, engrenagem no letreiro, pilha de sucata |
| barraca_da_sol | Sol, a ex-analista | barraca na beira do rio, quadro de mapas, luneta, lampião |
| barraco_a, barraco_b | vizinhos | barracos de sucata para encher a vila |

Escala: o personagem tem 0,66. Parede de casa com 2,2 de altura, porta de 1,2. A frente
é o lado -Y (vai para a câmera no jogo).

Pacote `cyber_moon_mundo`.
"""

import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit
from pecas_de_inimigo import faixa_de_aviso

PACOTE = "cyber_moon_mundo"


# -- peças que se repetem ------------------------------------------------------------------

def janela(m, x, y, z, largura=0.7, altura=0.6, acesa=True, cortina="rosa", moldura="marrom"):
    """Janela na parede da frente (y é o plano da parede): moldura, vidro, cortina e
    peitoril. Acesa, ela brilha de noite."""
    m.caixa((largura + 0.12, 0.08, altura + 0.12), pos=(x, y - 0.02, z - 0.06), cor=moldura)
    m.caixa((largura, 0.06, altura), pos=(x, y - 0.05, z), cor="amarelo" if acesa else "azul_palido", brilho=acesa)
    m.caixa((largura * 0.28, 0.07, altura), pos=(x - largura * 0.36, y - 0.06, z), cor=cortina)
    m.caixa((largura * 0.28, 0.07, altura), pos=(x + largura * 0.36, y - 0.06, z), cor=cortina)
    m.caixa((0.04, 0.075, altura), pos=(x, y - 0.065, z), cor=moldura)
    m.caixa((largura + 0.2, 0.18, 0.06), pos=(x, y - 0.1, z - 0.1), cor=moldura)


def porta(m, x, y, largura=0.75, altura=1.25, cor="marrom", macaneta="amarelo"):
    m.caixa((largura + 0.14, 0.08, altura + 0.08), pos=(x, y - 0.02, 0.15), cor="chumbo")
    m.caixa((largura, 0.07, altura), pos=(x, y - 0.05, 0.15), cor=cor)
    m.caixa((largura * 0.7, 0.075, 0.05), pos=(x, y - 0.06, 0.15 + altura * 0.55), cor="grafite")
    m.esfera(0.035, pos=(x + largura * 0.33, y - 0.11, 0.15 + altura * 0.45), cor=macaneta)


def degrau(m, x, y, largura=1.1):
    m.caixa((largura, 0.45, 0.15), pos=(x, y - 0.2, 0.0), cor="cinza_medio", chanfro=0.02)


def vaso(m, x, y, z=0.0, cor_do_vaso="ferrugem", cor_da_planta="verde", altura=0.25):
    m.cilindro(0.13, altura, pos=(x, y, z), cor=cor_do_vaso, lados=7, raio_do_topo=0.16)
    m.esfera(0.17, pos=(x, y, z + altura + 0.1), cor=cor_da_planta, escala=(1, 1, 0.85))
    m.esfera(0.1, pos=(x + 0.08, y - 0.05, z + altura + 0.22), cor="verde_folha")


def toldo(m, x, y, z, largura, profundidade=0.8, cores=("laranja", "creme"), faixas=6, inclinacao=-14):
    """Toldo listrado saindo da parede, levemente inclinado."""
    passo = largura / faixas
    for indice in range(faixas):
        faixa = m.caixa((passo, profundidade, 0.05), pos=(0, 0, 0), cor=cores[indice % len(cores)])
        m.mover(faixa, pos=(0, -profundidade / 2, 0), rot=(inclinacao, 0, 0))
        m.mover(faixa, pos=(x - largura / 2 + passo * (indice + 0.5), y, z))
    for indice in range(faixas * 2):
        ponta = m.prisma([(-passo / 4, 0.0), (passo / 4, 0.0), (0.0, -0.1)], 0.03,
                         cor=cores[(indice // 2) % len(cores)])
        m.mover(ponta, pos=(x - largura / 2 + passo / 4 + indice * passo / 2,
                             y - profundidade * math.cos(math.radians(inclinacao)) - 0.01,
                             z + profundidade * math.sin(math.radians(inclinacao))))


def telhado_de_duas_aguas(m, largura, profundidade, z, altura=0.8, cor="ferrugem", beiral=0.25, centro=(0, 0)):
    """Telhado de duas águas com a cumeeira ao longo de X."""
    meia = profundidade / 2 + beiral
    pontos = [(-meia, 0.0), (meia, 0.0), (0.0, altura)]
    telhado = m.prisma(pontos, largura + beiral * 2, cor=cor)
    m.mover(telhado, rot=(0, 0, 90))
    m.mover(telhado, pos=(centro[0], centro[1], z))
    m.caixa((largura + beiral * 2 + 0.06, 0.14, 0.1), pos=(centro[0], centro[1], z + altura - 0.04), cor="chumbo")


def telhado_de_chapa(m, largura, profundidade, z, cor="cinza_metal", inclinacao=8, centro=(0, 0)):
    """Telhado de chapa ondulada, uma água só, caindo para a frente."""
    chapa = m.caixa((largura + 0.4, profundidade + 0.5, 0.08), pos=(0, 0, 0), cor=cor)
    m.mover(chapa, rot=(-inclinacao, 0, 0))
    m.mover(chapa, pos=(centro[0], centro[1], z))
    for indice in range(int((largura + 0.4) / 0.3)):
        onda = m.caixa((0.06, profundidade + 0.5, 0.03), pos=(0, 0, 0.06), cor="cinza_medio")
        m.mover(onda, rot=(-inclinacao, 0, 0))
        m.mover(onda, pos=(centro[0] - (largura + 0.4) / 2 + 0.15 + indice * 0.3, centro[1], z))


def caixa_dagua_de_telhado(m, x, y, z):
    m.cilindro(0.45, 0.65, pos=(x, y, z), cor="azul", lados=9, cor_das_tampas="cinza_medio", degrade=True)
    m.cilindro(0.47, 0.06, pos=(x, y, z + 0.3), cor="cinza_escuro", lados=9)


def plantinha_de_parede(m, x, y, z):
    m.caixa((0.5, 0.18, 0.16), pos=(x, y - 0.09, z), cor="marrom")
    for dx in (-0.15, 0.0, 0.15):
        m.esfera(0.1, pos=(x + dx, y - 0.1, z + 0.2), cor="verde" if dx else "magenta", escala=(1, 1, 0.8))


def corpo_da_casa(m, largura, profundidade, altura, cor="creme", base="cinza_medio", rodape="ferrugem"):
    m.caixa((largura + 0.3, profundidade + 0.3, 0.15), cor=base, chanfro=0.03)
    m.caixa((largura, profundidade, altura), pos=(0, 0, 0.15), cor=cor, chanfro=0.06, degrade=True)
    m.caixa((largura + 0.04, profundidade + 0.04, 0.22), pos=(0, 0, 0.15), cor=rodape)
    for x in (-largura / 2, largura / 2):
        for y in (-profundidade / 2, profundidade / 2):
            m.caixa((0.14, 0.14, altura), pos=(x, y, 0.15), cor=rodape)


# -- casas -----------------------------------------------------------------------------------

def casa_da_marta():
    """Casa da Marta: barro claro, telhado de telha, varanda com cadeira, horta de caixote,
    forno de barro do lado e vasos por todo canto."""
    m = kit.Modelo("casa_da_marta")
    largura, profundidade, altura = 4.6, 3.6, 2.2
    corpo_da_casa(m, largura, profundidade, altura, cor="creme", rodape="ferrugem")
    frente = -profundidade / 2
    porta(m, -0.6, frente, cor="verde")
    janela(m, 1.2, frente, 1.05, cortina="laranja")
    janela(m, -1.75, frente, 1.05, largura=0.55, cortina="laranja")
    degrau(m, -0.6, frente)
    telhado_de_duas_aguas(m, largura, profundidade, 2.35, altura=1.0, cor="coral")
    # Varanda: piso, dois esteios e o toldo listrado.
    m.caixa((largura, 1.2, 0.12), pos=(0, frente - 0.6, 0.0), cor="marrom")
    for x in (-largura / 2 + 0.15, largura / 2 - 0.15):
        m.cilindro(0.07, 1.9, pos=(x, frente - 1.1, 0.1), cor="marrom", lados=6)
    toldo(m, 0, frente - 0.05, 2.05, largura, profundidade=1.15, cores=("laranja", "creme"), faixas=8)
    # Cadeira de balanço e a mesinha.
    m.caixa((0.45, 0.45, 0.06), pos=(1.0, frente - 0.75, 0.42), cor="ferrugem")
    m.caixa((0.45, 0.06, 0.55), pos=(1.0, frente - 0.52, 0.45), cor="ferrugem")
    for x in (0.8, 1.2):
        m.caixa((0.05, 0.4, 0.42), pos=(x, frente - 0.75, 0.1), cor="marrom")
    m.cilindro(0.2, 0.5, pos=(1.65, frente - 0.75, 0.1), cor="marrom", lados=6)
    m.cilindro(0.06, 0.12, pos=(1.65, frente - 0.75, 0.6), cor="branco", lados=6)
    # Vasos na beira da varanda e plantas na janela.
    for x in (-2.05, -1.2, 1.95):
        vaso(m, x, frente - 1.05, z=0.12, cor_do_vaso="coral" if x < 0 else "ferrugem")
    plantinha_de_parede(m, 1.2, frente - 0.12, 0.62)
    # Horta de caixote do lado direito.
    for indice, (y, cor) in enumerate(((-0.8, "verde"), (0.4, "verde_folha"))):
        m.caixa((1.0, 1.0, 0.35), pos=(largura / 2 + 0.9, y, 0.0), cor="marrom", chanfro=0.03)
        for dx in (-0.25, 0.0, 0.25):
            for dy in (-0.25, 0.25):
                m.esfera(0.12, pos=(largura / 2 + 0.9 + dx, y + dy, 0.45), cor=cor if (dx + dy) else "laranja",
                         escala=(1, 1, 0.8))
    # Forno de barro atrás, à esquerda, com a chaminé.
    m.esfera(0.65, pos=(-largura / 2 - 0.7, 0.9, 0.3), cor="salmao", escala=(1, 1, 0.75))
    m.caixa((0.4, 0.12, 0.35), pos=(-largura / 2 - 0.7, 0.3, 0.15), cor="grafite")
    m.cilindro(0.12, 0.6, pos=(-largura / 2 - 0.7, 1.1, 0.75), cor="ferrugem", lados=6)
    m.caixa((0.5, 0.5, 1.2), pos=(-1.3, 0.8, 2.6), cor="ferrugem", chanfro=0.03)
    return m.finalizar()


def mercado_da_marta():
    """O mercado: fachada larga com o toldo, caixotes de fruta e verdura na frente, o
    letreiro e a lousa de preços."""
    m = kit.Modelo("mercado_da_marta")
    largura, profundidade, altura = 6.0, 4.0, 2.6
    corpo_da_casa(m, largura, profundidade, altura, cor="pessego", rodape="verde")
    frente = -profundidade / 2
    m.caixa((2.2, 0.08, 1.6), pos=(0, frente - 0.02, 0.15), cor="chumbo")
    m.caixa((2.0, 0.07, 1.5), pos=(0, frente - 0.05, 0.15), cor="amarelo", brilho=True)
    for x in (-0.55, 0.55):
        m.caixa((0.05, 0.075, 1.5), pos=(x, frente - 0.06, 0.15), cor="chumbo")
    janela(m, -2.1, frente, 1.15, largura=1.0, altura=0.8, cortina="verde")
    janela(m, 2.1, frente, 1.15, largura=1.0, altura=0.8, cortina="verde")
    telhado_de_chapa(m, largura, profundidade, 2.85, cor="verde", centro=(0, 0.1))
    toldo(m, 0, frente - 0.05, 2.35, largura - 0.2, profundidade=1.3, cores=("verde", "creme"), faixas=10)
    # Letreiro em cima do toldo.
    m.caixa((3.4, 0.2, 0.6), pos=(0, frente - 0.1, 2.75), cor="preto")
    m.caixa((3.0, 0.22, 0.3), pos=(0, frente - 0.12, 2.9), cor="verde", brilho=True)
    m.caixa((0.6, 0.23, 0.12), pos=(-1.3, frente - 0.13, 2.82), cor="amarelo", brilho=True)
    # Caixotes de fruta na frente, em degraus.
    produtos = ("laranja", "amarelo", "verde", "magenta", "coral", "verde_folha")
    for indice, x in enumerate((-2.4, -1.6, 1.6, 2.4)):
        m.caixa((0.7, 0.5, 0.45), pos=(x, frente - 0.6, 0.0), cor="marrom", chanfro=0.02)
        m.caixa((0.7, 0.45, 0.35), pos=(x, frente - 0.35, 0.45), cor="ferrugem", chanfro=0.02)
        for dx in (-0.18, 0.0, 0.18):
            m.esfera(0.09, pos=(x + dx, frente - 0.6, 0.5), cor=produtos[indice])
            m.esfera(0.08, pos=(x + dx, frente - 0.35, 0.85), cor=produtos[indice + 2])
    # Lousa de preços e sacos de semente.
    m.caixa((0.6, 0.06, 0.8), pos=(-1.0, frente - 1.2, 0.0), cor="marrom", rot=(-10, 0, 0))
    m.caixa((0.5, 0.07, 0.55), pos=(-1.0, frente - 1.24, 0.2), cor="grafite", rot=(-10, 0, 0))
    for indice, x in enumerate((0.9, 1.2)):
        m.cilindro(0.18, 0.4, pos=(x, frente - 1.1, 0.0), cor="creme", lados=7, raio_do_topo=0.12)
    return m.finalizar()


def casa_da_iara():
    """Casa da Iara: clara e arrumada, telhado azul, jardim de vaso, a maleta na janela."""
    m = kit.Modelo("casa_da_iara")
    largura, profundidade, altura = 4.0, 3.4, 2.2
    corpo_da_casa(m, largura, profundidade, altura, cor="branco", rodape="azul")
    frente = -profundidade / 2
    porta(m, 0.8, frente, cor="azul_claro")
    janela(m, -0.9, frente, 1.05, largura=0.9, cortina="azul_palido", moldura="azul")
    degrau(m, 0.8, frente)
    telhado_de_duas_aguas(m, largura, profundidade, 2.35, altura=0.9, cor="azul")
    m.caixa((0.35, 0.2, 0.25), pos=(-0.9, frente - 0.15, 0.6), cor="grafite")
    m.caixa((0.1, 0.21, 0.04), pos=(-0.9, frente - 0.16, 0.73), cor="azul_claro")
    # Cerquinha baixa e o jardim de vasos.
    for x in (-1.8, -1.2, -0.6, 1.6):
        vaso(m, x, frente - 0.75, cor_do_vaso="branco", cor_da_planta="verde" if x < 0 else "verde_folha", altura=0.2)
    for x in (-1.9, -0.3, 1.9):
        m.caixa((0.06, 0.06, 0.45), pos=(x, frente - 1.15, 0.0), cor="branco")
    m.caixa((3.9, 0.05, 0.05), pos=(0, frente - 1.15, 0.38), cor="branco")
    m.caixa((0.9, 0.06, 0.32), pos=(1.15, frente - 1.15, 0.0), cor="branco", rot=(0, 0, 35))
    caixa_dagua_de_telhado(m, 1.2, 0.6, 2.9)
    painel = m.caixa((1.2, 0.8, 0.05), cor="indigo")
    m.mover(painel, pos=(-0.9, 0.5, 3.1), rot=(-22, 0, 0))
    return m.finalizar()


def clinica_da_iara():
    """A clínica: fachada clara com a cruz azul de neon (o jogo não usa vermelho em nada
    de ferimento), banco de espera, maca dobrada e o toldo azul."""
    m = kit.Modelo("clinica_da_iara")
    largura, profundidade, altura = 5.0, 4.0, 2.5
    corpo_da_casa(m, largura, profundidade, altura, cor="branco", rodape="azul")
    frente = -profundidade / 2
    m.caixa((1.6, 0.08, 1.6), pos=(0, frente - 0.02, 0.15), cor="chumbo")
    m.caixa((1.4, 0.07, 1.5), pos=(0, frente - 0.05, 0.15), cor="azul_palido")
    m.caixa((0.05, 0.075, 1.5), pos=(0, frente - 0.06, 0.15), cor="azul")
    janela(m, -1.75, frente, 1.15, largura=0.9, cortina="branco", moldura="azul")
    janela(m, 1.75, frente, 1.15, largura=0.9, cortina="branco", moldura="azul")
    degrau(m, 0, frente, largura=1.8)
    telhado_de_chapa(m, largura, profundidade, 2.7, cor="azul_palido")
    toldo(m, 0, frente - 0.05, 2.2, 2.0, profundidade=0.9, cores=("azul", "branco"), faixas=6)
    # Cruz de neon azul, no alto da fachada.
    m.caixa((1.0, 0.16, 1.0), pos=(1.75, frente - 0.1, 2.5), cor="preto", chanfro=0.04)
    m.caixa((0.7, 0.18, 0.22), pos=(1.75, frente - 0.12, 2.89), cor="azul_claro", brilho=True)
    m.caixa((0.22, 0.18, 0.7), pos=(1.75, frente - 0.12, 2.65), cor="azul_claro", brilho=True)
    # Banco de espera e a maca dobrada.
    m.caixa((1.3, 0.4, 0.06), pos=(-1.6, frente - 0.6, 0.42), cor="azul")
    for x in (-2.15, -1.05):
        m.caixa((0.06, 0.35, 0.42), pos=(x, frente - 0.6, 0.0), cor="cinza_metal")
    # A maca dobrada, encostada na parede do lado.
    m.caixa((0.08, 1.4, 0.55), pos=(largura / 2 + 0.1, frente + 1.0, 0.15), cor="branco")
    for y in (frente + 0.4, frente + 1.6):
        m.caixa((0.1, 0.06, 0.7), pos=(largura / 2 + 0.12, y, 0.0), cor="cinza_metal")
    vaso(m, -0.95, frente - 0.4, cor_do_vaso="branco")
    vaso(m, 0.95, frente - 0.4, cor_do_vaso="branco")
    caixa_dagua_de_telhado(m, -1.6, 0.8, 3.0)
    return m.finalizar()


def casa_geminada():
    """A casa do Kenji (metade esquerda) e do Rafa (metade direita), parede com parede.
    O Kenji tem parabólica, cabos e luz azul; o Rafa, a bicicleta de entrega e caixas."""
    m = kit.Modelo("casa_geminada")
    largura, profundidade, altura = 6.4, 3.6, 2.3
    corpo_da_casa(m, largura, profundidade, altura, cor="lavanda", rodape="chumbo")
    m.caixa((3.2, profundidade + 0.02, altura), pos=(1.6, 0, 0.15), cor="pessego", chanfro=0.04, degrade=True)
    m.caixa((0.18, profundidade + 0.1, altura + 0.2), pos=(0, 0, 0.15), cor="chumbo")
    frente = -profundidade / 2
    telhado_de_chapa(m, largura, profundidade, 2.6, cor="cinza_metal")
    # Metade do Kenji.
    porta(m, -2.2, frente, cor="indigo", macaneta="azul_claro")
    janela(m, -0.9, frente, 1.1, cortina="indigo", moldura="grafite")
    degrau(m, -2.2, frente)
    m.caixa((0.06, 0.06, 2.0), pos=(-0.25, frente - 0.06, 0.2), cor="azul_claro", brilho=True)
    m.caixa((0.6, 0.4, 0.5), pos=(-1.6, frente - 0.4, 0.0), cor="grafite")
    for dx in (-0.2, 0.0, 0.2):
        m.caixa((0.06, 0.02, 0.06), pos=(-1.6 + dx, frente - 0.61, 0.35), cor="verde", brilho=True)
    # Os cabos do Kenji descem pela quina, da parabólica até a caixa de rede.
    for indice in range(3):
        m.caixa((0.04, 0.04, 2.2), pos=(-3.12 + indice * 0.07, frente - 0.08, 0.3), cor="preto")
    m.caixa((1.5, 0.04, 0.04), pos=(-2.4, frente - 0.08, 0.32), cor="preto")
    parabola = m.cilindro(0.55, 0.16, cor="branco", lados=10, raio_do_topo=0.15, cor_das_tampas="cinza_medio")
    m.mover(parabola, rot=(55, 0, 25))
    m.mover(parabola, pos=(-2.0, 0.6, 3.0))
    m.cilindro(0.05, 0.5, pos=(-2.0, 0.6, 2.65), cor="grafite", lados=5)
    # Metade do Rafa.
    porta(m, 2.2, frente, cor="laranja")
    janela(m, 0.9, frente, 1.1, cortina="amarelo")
    degrau(m, 2.2, frente)
    for indice, (x, z, cor) in enumerate(((3.0, 0.0, "marrom"), (3.0, 0.42, "creme"), (2.65, 0.0, "creme"))):
        m.caixa((0.42, 0.42, 0.42), pos=(x, frente - 0.5, z), cor=cor, chanfro=0.02)
        m.caixa((0.43, 0.43, 0.06), pos=(x, frente - 0.5, z + 0.2), cor="laranja")
    # A bicicleta de entrega, encostada.
    for x in (0.95, 1.85):
        m.cilindro(0.3, 0.05, pos=(x, frente - 0.45, 0.32), cor="grafite", lados=10, rot=(90, 0, 0))
        m.cilindro(0.12, 0.06, pos=(x, frente - 0.45, 0.32), cor="laranja", lados=6, rot=(90, 0, 0))
    m.caixa((0.95, 0.05, 0.05), pos=(1.4, frente - 0.48, 0.55), cor="laranja", rot=(0, -20, 0))
    m.caixa((0.5, 0.45, 0.4), pos=(0.9, frente - 0.45, 0.65), cor="laranja", chanfro=0.03)
    m.caixa((0.3, 0.46, 0.08), pos=(0.9, frente - 0.45, 0.9), cor="creme")
    # Varal entre as duas metades.
    for x in (-0.6, 0.6):
        m.cilindro(0.03, 1.5, pos=(x, frente - 1.3, 0.0), cor="marrom", lados=5)
    m.caixa((1.2, 0.02, 0.02), pos=(0, frente - 1.3, 1.45), cor="branco")
    for x, cor in ((-0.35, "indigo"), (0.05, "amarelo"), (0.4, "laranja")):
        m.caixa((0.3, 0.02, 0.4), pos=(x, frente - 1.3, 1.05), cor=cor)
    return m.finalizar()


def casa_do_vitor():
    """Casa do Vitor: chapa remendada de várias cores, tambor de óleo, peças penduradas,
    gerador velho do lado e a antena torta."""
    m = kit.Modelo("casa_do_vitor")
    largura, profundidade, altura = 4.4, 3.6, 2.2
    corpo_da_casa(m, largura, profundidade, altura, cor="cinza_metal", rodape="ferrugem")
    frente = -profundidade / 2
    for x, z, w, h, cor in ((-1.5, 0.4, 1.1, 0.9, "ferrugem"), (1.4, 1.3, 1.0, 0.8, "azul"), (0.6, 0.3, 0.7, 0.6, "verde")):
        m.caixa((w, 0.05, h), pos=(x, frente - 0.03, z), cor=cor)
    for x in (-1.5, 1.4):
        for z in (0.5, 1.2):
            m.esfera(0.025, pos=(x - 0.4, frente - 0.06, z), cor="grafite")
    porta(m, -0.2, frente, cor="ferrugem", macaneta="cinza_metal")
    janela(m, 1.4, frente, 1.15, cortina="grafite", moldura="chumbo")
    degrau(m, -0.2, frente)
    telhado_de_chapa(m, largura, profundidade, 2.5, cor="ferrugem")
    # Peças penduradas na parede: chave inglesa, engrenagem, mangueira.
    m.cilindro(0.18, 0.04, pos=(-1.5, frente - 0.08, 1.75), cor="cinza_metal", lados=8, rot=(90, 0, 0))
    m.caixa((0.06, 0.04, 0.5), pos=(-1.1, frente - 0.06, 1.55), cor="cinza_metal", rot=(0, 20, 0))
    # Tambor de óleo e o gerador.
    for x, cor in ((largura / 2 + 0.4, "azul"), (largura / 2 + 0.45, "amarelo")):
        m.cilindro(0.25, 0.65, pos=(x, frente + (0.0 if cor == "azul" else 0.6), 0.0), cor=cor, lados=9, cor_das_tampas="chumbo")
    m.caixa((0.9, 0.6, 0.6), pos=(-largura / 2 - 0.6, 0.4, 0.0), cor="amarelo", chanfro=0.04)
    m.caixa((0.92, 0.62, 0.12), pos=(-largura / 2 - 0.6, 0.4, 0.4), cor="grafite")
    m.cilindro(0.05, 0.5, pos=(-largura / 2 - 0.35, 0.55, 0.6), cor="grafite", lados=5)
    antena = m.cilindro(0.03, 1.4, pos=(0, 0, 0), cor="grafite", lados=4)
    m.mover(antena, rot=(0, 12, 0))
    m.mover(antena, pos=(1.4, 0.9, 2.6))
    m.caixa((0.6, 0.04, 0.04), pos=(1.55, 0.9, 3.8), cor="grafite")
    vaso(m, 0.7, frente - 0.4, cor_do_vaso="cinza_metal", cor_da_planta="verde_folha")
    return m.finalizar()


def oficina_do_vitor():
    """A oficina: garagem aberta com a bancada lá dentro, engrenagem no letreiro, pilha de
    sucata e um carro sem rodas esperando conserto."""
    m = kit.Modelo("oficina_do_vitor")
    largura, profundidade, altura = 5.6, 4.4, 2.8
    m.caixa((largura + 0.3, profundidade + 0.3, 0.15), cor="cinza_medio")
    for x in (-largura / 2, largura / 2):
        m.caixa((0.25, profundidade, altura), pos=(x, 0, 0.15), cor="ferrugem", degrade=True)
    m.caixa((largura, 0.25, altura), pos=(0, profundidade / 2, 0.15), cor="ferrugem", degrade=True)
    m.caixa((largura, 0.3, 0.5), pos=(0, -profundidade / 2, altura - 0.35), cor="chumbo")
    for indice in range(int(largura / 0.4)):
        m.caixa((0.05, 0.3, 0.5), pos=(-largura / 2 + 0.2 + indice * 0.4, -profundidade / 2 - 0.01, altura - 0.35), cor="cinza_metal")
    faixa_de_aviso(m, largura, (0, -profundidade / 2 - 0.16, altura - 0.5), altura=0.14, partes=12)
    telhado_de_chapa(m, largura, profundidade, altura + 0.2, cor="cinza_metal")
    # Letreiro com a engrenagem.
    m.cilindro(0.55, 0.12, pos=(0, -profundidade / 2 - 0.2, altura + 0.55), cor="amarelo", lados=12, rot=(90, 0, 0), brilho=True)
    for angulo in range(0, 360, 45):
        dente = m.caixa((0.18, 0.13, 0.2), pos=(0.6, 0, 0), cor="amarelo", brilho=True)
        m.mover(dente, rot=(0, angulo, 0))
        m.mover(dente, pos=(0, -profundidade / 2 - 0.2, altura + 0.55))
    m.cilindro(0.2, 0.14, pos=(0, -profundidade / 2 - 0.21, altura + 0.55), cor="grafite", lados=8, rot=(90, 0, 0))
    # Dentro: bancada, ferramentas, a luz.
    m.caixa((2.4, 0.7, 0.85), pos=(0, profundidade / 2 - 0.55, 0.15), cor="marrom")
    for x, cor in ((-0.8, "cinza_metal"), (-0.3, "ferrugem"), (0.4, "cinza_metal"), (0.9, "amarelo")):
        m.caixa((0.08, 0.06, 0.6), pos=(x, profundidade / 2 - 0.15, 1.3), cor=cor)
    m.caixa((1.6, 0.3, 0.08), pos=(0, profundidade / 2 - 0.4, altura - 0.2), cor="amarelo", brilho=True)
    # Pilha de sucata e o carro esperando.
    for x, y, z, tamanho, cor in ((-largura / 2 - 0.8, -0.8, 0.0, 0.5, "ferrugem"), (-largura / 2 - 0.6, -0.3, 0.0, 0.4, "cinza_metal"),
                                  (-largura / 2 - 0.9, -0.5, 0.4, 0.35, "azul"), (-largura / 2 - 0.5, 0.4, 0.0, 0.45, "chumbo")):
        m.caixa((tamanho, tamanho, tamanho), pos=(x, y, z), cor=cor, rot=(0, 0, x * 40))
    m.cilindro(0.3, 0.22, pos=(largura / 2 + 0.7, -1.2, 0.0), cor="grafite", lados=10)
    m.cilindro(0.3, 0.22, pos=(largura / 2 + 0.75, -1.2, 0.22), cor="grafite", lados=10)
    return m.finalizar()


def barraca_da_sol():
    """A barraca da Sol na beira do rio: lona, o quadro de mapas riscados, a luneta virada
    para a cidade, o lampião e a cadeira dobrável."""
    m = kit.Modelo("barraca_da_sol")
    m.caixa((3.2, 2.6, 0.08), cor="marrom")
    lona = m.prisma([(-1.3, 0.0), (1.3, 0.0), (0.0, 1.6)], 2.4, cor="azul_palido", rot=(0, 0, 90))
    m.mover(lona, pos=(0, 0.2, 0.08))
    m.prisma([(-0.45, 0.0), (0.45, 0.0), (0.0, 1.0)], 0.04, pos=(0, -1.0, 0.08), cor="indigo")
    m.caixa((0.06, 2.5, 0.06), pos=(0, 0.2, 1.62), cor="marrom")
    # Quadro de mapas.
    m.caixa((1.0, 0.08, 0.75), pos=(-1.8, -0.3, 0.6), cor="marrom", rot=(-8, 0, 15))
    m.caixa((0.9, 0.09, 0.65), pos=(-1.8, -0.31, 0.65), cor="creme", rot=(-8, 0, 15))
    for indice, (dx, dz, cor) in enumerate(((-0.2, 0.15, "magenta"), (0.15, -0.1, "azul"), (0.1, 0.2, "grafite"))):
        m.caixa((0.35, 0.095, 0.03), pos=(-1.8 + dx, -0.33, 0.95 + dz), cor=cor, rot=(-8, 30 * indice, 15))
    for x in (-2.15, -1.45):
        m.caixa((0.04, 0.04, 0.65), pos=(x, -0.2, 0.0), cor="marrom")
    # Luneta no tripé, virada para o norte.
    for angulo in (0, 120, 240):
        perna = m.caixa((0.03, 0.03, 0.8), pos=(0.15, 0, 0), cor="grafite", rot=(0, -12, 0))
        m.mover(perna, rot=(0, 0, angulo))
        m.mover(perna, pos=(1.6, -0.5, 0.08))
    luneta = m.cilindro(0.07, 0.75, cor="cinza_metal", lados=8, raio_do_topo=0.05)
    m.mover(luneta, rot=(-65, 0, 0))
    m.mover(luneta, pos=(1.6, -0.6, 0.85))
    # Lampião, cadeira, caixote.
    m.cilindro(0.1, 0.25, pos=(0.9, -1.2, 0.08), cor="amarelo", lados=6, brilho=True)
    m.cilindro(0.12, 0.05, pos=(0.9, -1.2, 0.33), cor="grafite", lados=6)
    m.caixa((0.45, 0.4, 0.05), pos=(-0.8, -1.3, 0.42), cor="laranja", rot=(0, 0, 20))
    m.caixa((0.45, 0.05, 0.45), pos=(-0.85, -1.12, 0.45), cor="laranja", rot=(-15, 0, 20))
    m.caixa((0.5, 0.4, 0.4), pos=(0.0, -1.35, 0.08), cor="marrom", chanfro=0.02)
    m.cilindro(0.05, 0.12, pos=(0.05, -1.35, 0.48), cor="branco", lados=6)
    return m.finalizar()


def _barraco(nome, cor_da_parede, cor_do_telhado, remendos, semente):
    m = kit.Modelo(nome)
    largura, profundidade, altura = 3.4, 2.8, 2.0
    corpo_da_casa(m, largura, profundidade, altura, cor=cor_da_parede, rodape="chumbo")
    frente = -profundidade / 2
    for x, z, w, h, cor in remendos:
        m.caixa((w, 0.05, h), pos=(x, frente - 0.03, z), cor=cor)
    porta(m, -0.7 if semente % 2 else 0.7, frente, cor="marrom")
    janela(m, 0.8 if semente % 2 else -0.8, frente, 1.05, largura=0.6, cortina=("rosa", "verde", "amarelo")[semente % 3])
    degrau(m, -0.7 if semente % 2 else 0.7, frente)
    telhado_de_chapa(m, largura, profundidade, 2.25, cor=cor_do_telhado)
    m.caixa((0.8, 0.8, 0.05), pos=(0.6, 0.4, 2.45), cor="ferrugem", rot=(-8, 0, 15))
    m.cilindro(0.06, 0.6, pos=(-1.2, 0.8, 2.3), cor="grafite", lados=5)
    vaso(m, 1.4 if semente % 2 else -1.4, frente - 0.4, cor_do_vaso="ferrugem")
    m.cilindro(0.22, 0.55, pos=(-largura / 2 - 0.35, 0.3, 0.0), cor="azul", lados=8, cor_das_tampas="chumbo")
    return m


def barraco_a():
    """Barraco de sucata, de chapa azulada com remendo de ferrugem e de verde."""
    m = _barraco("barraco_a", "azul_palido", "cinza_metal",
                 ((-1.0, 0.3, 0.8, 0.7, "ferrugem"), (1.1, 1.2, 0.6, 0.5, "verde")), 1)
    return m.finalizar()


def barraco_b():
    """Barraco de sucata, de chapa cor de areia, telhado vermelho-tijolo e o toldo."""
    m = _barraco("barraco_b", "pessego", "coral",
                 ((1.0, 0.4, 0.7, 0.6, "cinza_metal"), (-1.2, 1.3, 0.5, 0.4, "azul")), 2)
    toldo(m, 0, -1.45, 1.85, 2.0, profundidade=0.7, cores=("magenta", "creme"), faixas=6)
    return m.finalizar()


MODELOS = [
    casa_da_marta, mercado_da_marta, casa_da_iara, clinica_da_iara, casa_geminada,
    casa_do_vitor, oficina_do_vitor, barraca_da_sol, barraco_a, barraco_b,
]

if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.produzir(MODELOS, "casas", espaco=1.2)
