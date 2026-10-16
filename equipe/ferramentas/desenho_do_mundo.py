"""O desenho do mapa mundi: rio, cânion, aquífero, terraços, trilhas, pontes e reservas.

É a fonte única do traçado do mundo. Dois scripts leem daqui:

- `equipe/ferramentas/blender/modelos/terreno.py`, que modela o chão com relevo no
  Blender (o leito do rio afundado, o cânion, a bacia do aquífero, os terraços com rampa,
  as trilhas pintadas) e a água;
- `equipe/ferramentas/gerar_mapas.py`, que monta a cena do mundo em cima desse chão
  (pontes no lugar certo, paredes invisíveis na margem, cercas das reservas).

Assim o rio do terreno e as pontes do gerador nunca saem do lugar um do outro. As
coordenadas são as do jogo: x cresce para o leste, z para o sul, em unidades do jogo (o
personagem tem 0,66 de altura). O plano aprovado está em `equipe/mapas/mundo_organico.template.html`.

Só biblioteca padrão do Python: roda dentro do Blender e fora dele.
"""

import math

LARGURA = 160.0
PROFUNDIDADE = 110.0

# Até onde o chão vai além da área andável, para a borda não acabar num corte.
MARGEM_DO_TERRENO = 14.0

# -- água e buracos -------------------------------------------------------------------

# O rio (wadi) desce do viaduto até o aquífero, serpenteando.
RIO = [(86, 0), (87, 11), (89, 19), (86, 27), (82, 34), (84, 42), (88, 49), (85, 57), (79, 63), (77, 71), (81, 79), (78, 86), (76, 92)]
# Meia largura da água e do leito. A margem é íngreme de propósito: o personagem não
# desce nela, e a parede invisível da margem fica no topo.
MEIA_LARGURA_DO_RIO = 2.3
# A largura varia ao longo do rio (mais largo nas curvas abertas), em até tanto para mais
# ou para menos.
VARIACAO_DA_LARGURA_DO_RIO = 0.6
LARGURA_DA_MARGEM_DO_RIO = 0.7
FUNDO_DO_RIO = -1.2

# O aquífero: um lago de margem irregular na borda sul.
AQUIFERO_CENTRO = (76.0, 98.0)
AQUIFERO_RAIOS = (23.0, 8.5)
AQUIFERO_SEMENTE = 5
FUNDO_DO_AQUIFERO = -1.2
LARGURA_DA_MARGEM_DO_AQUIFERO = 0.8

# O cânion corta o oeste e separa os dois campos solares.
CANION = [(-14, 63), (0, 62), (12, 58), (24, 60), (36, 54), (46, 58), (52, 56)]
MEIA_LARGURA_DO_CANION = 2.6
LARGURA_DA_PAREDE_DO_CANION = 1.0
FUNDO_DO_CANION = -2.6

# A água fica um pouco abaixo do chão: do alto do barranco se vê o rio lá embaixo.
ALTURA_DA_AGUA = -0.85

# -- terraços (sobem, com rampa) ---------------------------------------------------------

# (x, z, raio em x, raio em z, altura, largura da rampa)
TERRACOS = [
    (62.0, 54.0, 10.0, 8.0, 0.5, 2.5),     # praça do mercado
    (127.0, 30.0, 6.0, 4.5, 1.2, 4.0),     # mirante das Badlands
]

# -- trilhas -----------------------------------------------------------------------------

# (pontos, largura). Pintadas no terreno; as pontes ficam onde uma trilha cruza a água.
TRILHAS = [
    ([(0, 11), (40, 11), (80, 11), (120, 11), (160, 11)], 4.5),          # pista sob o viaduto (asfalto)
    ([(4, 20), (18, 22), (34, 28), (46, 40), (54, 49)], 2.6),             # porteira até o mercado
    ([(74, 12), (72, 24), (68, 38), (64, 46)], 2.6),                       # ponto de ônibus até o mercado
    ([(70, 55), (80, 53), (90, 51), (100, 50), (112, 46), (122, 37), (127, 31)], 2.6),  # mercado, vila, mirante
    ([(104, 54), (114, 62), (126, 72), (134, 79)], 2.6),                  # vila até o acampamento
    ([(62, 62), (64, 74), (68, 86), (70, 89)], 2.4),                       # mercado até o aquífero
    ([(30, 30), (27, 44), (24, 56), (23, 66), (22, 80)], 2.4),             # solar norte, ponte de cabo, solar sul
    ([(52, 52), (40, 56), (30, 58)], 2.2),                                 # mercado até a ponte de cabo
    ([(101, 60), (102, 71)], 2.2),                                         # vila até a cisterna
    ([(96, 22), (88, 24), (80, 22)], 2.2),                                 # Galeria até a avenida
]

# Onde as trilhas cruzam a água ou o cânion: (nome, x, z, comprimento, tipo).
# O x e o z são o centro; a ponte fica atravessada no curso naquele ponto.
PONTES = [
    ("PonteDeSucata", None, 11.0, 7.0, "sucata"),      # x calculado no rio
    ("PonteDaGaleria", None, 23.0, 6.5, "madeira"),
    ("PonteDoMercado", None, 52.0, 6.5, "madeira"),
    ("PonteDeCabo", 24.0, None, 9.0, "cabo"),         # z calculado no cânion
]

# -- reservas (cercadas, vistas mas não andáveis) -------------------------------------------

RESERVAS = {
    "reserva_das_raposas": [(34, 66), (50, 64), (52, 82), (44, 90), (34, 86)],
    "pasto_do_vizinho": [(112, 64), (124, 62), (125, 75), (114, 77)],
    "campo_de_ossos": [(100, 20), (114, 18), (117, 29), (104, 31)],
}

# Áreas de cada lugar, para os scripts saberem o que pintar e o que deixar livre.
LUGARES = {
    "mercado": (62.0, 54.0, 12.0, 10.0),
    "vila": (102.0, 52.0, 13.0, 14.0),
    "cisterna": (103.0, 76.0, 8.0, 6.0),
    "solar_norte": (24.0, 32.0, 18.0, 13.0),
    "solar_sul": (22.0, 84.0, 18.0, 13.0),
    "badlands": (134.0, 36.0, 22.0, 20.0),
    "acampamento": (138.0, 86.0, 16.0, 12.0),
    "porteira": (8.0, 20.0, 7.0, 5.0),
}


# -- contas ----------------------------------------------------------------------------------

def suavizar(pontos, passo=0.5):
    """Curva Catmull-Rom passando pelos pontos, amostrada a cada `passo` unidades."""
    resultado = []
    estendidos = [pontos[0]] + list(pontos) + [pontos[-1]]
    for indice in range(1, len(estendidos) - 2):
        p0, p1, p2, p3 = estendidos[indice - 1], estendidos[indice], estendidos[indice + 1], estendidos[indice + 2]
        comprimento = math.dist(p1, p2)
        amostras = max(int(comprimento / passo), 1)
        for amostra in range(amostras):
            t = amostra / amostras
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            z = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            resultado.append((x, z))
    resultado.append(tuple(pontos[-1]))
    return resultado


def meia_largura_do_rio_em(z):
    """A meia largura do rio na altura z: varia devagar, para o rio não ser uma faixa."""
    return MEIA_LARGURA_DO_RIO + VARIACAO_DA_LARGURA_DO_RIO * math.sin(z * 0.11 + 1.3) * math.cos(z * 0.047)


def x_do_curso_em(curso, z):
    """O x do centro de um curso (rio) na altura z dada, pela curva suavizada."""
    pontos = suavizar(curso)
    for a, b in zip(pontos, pontos[1:]):
        if (a[1] - z) * (b[1] - z) <= 0 and a[1] != b[1]:
            t = (z - a[1]) / (b[1] - a[1])
            return a[0] + (b[0] - a[0]) * t, math.atan2(b[0] - a[0], b[1] - a[1])
    return pontos[-1][0], 0.0


def z_do_curso_em(curso, x):
    """O z do centro de um curso (cânion) no x dado."""
    pontos = suavizar(curso)
    for a, b in zip(pontos, pontos[1:]):
        if (a[0] - x) * (b[0] - x) <= 0 and a[0] != b[0]:
            t = (x - a[0]) / (b[0] - a[0])
            return a[1] + (b[1] - a[1]) * t, math.atan2(b[1] - a[1], b[0] - a[0])
    return pontos[-1][1], 0.0


def raio_do_aquifero(angulo):
    """O raio da margem do aquífero na direção dada, com a margem ondulada."""
    rx, rz = AQUIFERO_RAIOS
    base = (rx * rz) / math.sqrt((rz * math.cos(angulo)) ** 2 + (rx * math.sin(angulo)) ** 2)
    ondulacao = 1.0 + 0.09 * math.sin(angulo * 3 + AQUIFERO_SEMENTE) + 0.06 * math.sin(angulo * 5 + AQUIFERO_SEMENTE * 2)
    return base * ondulacao


def margem_do_aquifero(pontos=72):
    """O contorno do aquífero, para a parede invisível e a cerca da margem."""
    cx, cz = AQUIFERO_CENTRO
    contorno = []
    for indice in range(pontos):
        angulo = math.tau * indice / pontos
        raio = raio_do_aquifero(angulo)
        contorno.append((cx + math.cos(angulo) * raio, cz + math.sin(angulo) * raio))
    return contorno


def paralela(curso, desvio):
    """A curva paralela a um curso, deslocada para a direita (desvio positivo) ou esquerda."""
    pontos = suavizar(curso, passo=1.0)
    resultado = []
    for indice, (x, z) in enumerate(pontos):
        a = pontos[max(indice - 1, 0)]
        b = pontos[min(indice + 1, len(pontos) - 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        comprimento = math.hypot(dx, dz) or 1.0
        nx, nz = dz / comprimento, -dx / comprimento
        resultado.append((x + nx * desvio, z + nz * desvio))
    return resultado
