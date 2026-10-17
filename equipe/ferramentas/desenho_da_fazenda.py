"""O desenho do mapa da fazenda: talhões, caminhos, laguinho e o vale em volta.

É a fonte única do traçado da fazenda, como `desenho_do_mundo.py` é a do mundo. Dois
scripts leem daqui:

- `equipe/ferramentas/blender/modelos/terreno_da_fazenda.py`, que modela o chão (o
  gramado, os caminhos de terra batida, o laguinho afundado, a terra rachada do lado de
  fora da cerca e as dunas do vale) e a água do laguinho;
- `equipe/ferramentas/gerar_mapas.py`, que monta a cena da fazenda em cima desse chão.

Coordenadas do mapa da fazenda: x de 0 a 50 para o leste, z de 0 a 40 para o sul, com a
cerca na borda. Dentro da cerca o chão é plano (talhão, casa e baú pedem chão reto); o
desnível fica no laguinho e do lado de fora.

Só biblioteca padrão do Python: roda dentro do Blender e fora dele.
"""

import math

LARGURA = 50.0
PROFUNDIDADE = 40.0

# Até onde o chão vai além da cerca, para o vale aparecer em volta.
MARGEM_DO_TERRENO = 20.0

# (x, z, largura, profundidade, liberado), em células de 1 por 1, canto noroeste.
TALHOES = [
    (6, 18, 11, 8, True),
    (20, 18, 11, 8, True),
    (34, 18, 10, 8, True),
    (6, 29, 11, 7, False),
    (20, 29, 11, 7, False),
    (34, 29, 10, 7, False),
]

# Caminhos de terra batida: (pontos, largura). O primeiro vai da varanda até a porteira e
# segue para fora, até a passagem para o mundo.
CAMINHOS = [
    ([(24, 10.5), (30, 12.6), (39, 13.6), (45, 16.0), (48, 21.2), (51, 22), (56, 22)], 2.8),
    ([(15, 11.4), (20, 11.0), (24, 10.5)], 2.4),                 # varanda, varal e cama
    ([(31, 12.4), (36, 11.4), (41, 11.8)], 2.6),                 # baús e galpão
    # Os corredores entre os talhões são retos e enchem o vão inteiro: a beira deles é a
    # beira do talhão, que cai na grade do terreno.
    ([(4.5, 27.5), (45.5, 27.5)], 3.0),                          # entre as fileiras de talhão
    ([(18.5, 13.8), (18.5, 36.0)], 3.0),                         # entre os talhões do oeste
    ([(32.5, 13.4), (32.5, 36.0)], 3.0),                         # entre os talhões do leste
    ([(14, 11.6), (11, 11.3), (8.6, 12.4)], 1.6),                # até o laguinho
]

# O laguinho no canto oeste: centro, raios, fundo e a largura do barranco.
LAGUINHO_CENTRO = (3.8, 14.0)
LAGUINHO_RAIOS = (2.2, 1.8)
FUNDO_DO_LAGUINHO = -0.9
LARGURA_DA_MARGEM_DO_LAGUINHO = 1.0
ALTURA_DA_AGUA_DO_LAGUINHO = -0.55

# A faixa de terra rachada do lado de fora da cerca, e onde as dunas começam a subir.
LARGURA_DA_TERRA_RACHADA = 4.0
ALTURA_DAS_DUNAS = 1.6

# Onde o chão é de construção (sem grama): casa, galpão e caixa d'água. (x, z, largura,
# profundidade), canto noroeste.
CONSTRUCOES = [(16, 1, 16, 8.5), (31, 2, 11, 9.5), (7, 2, 6, 6)]


def suavizar(pontos, passo=0.5):
    """Curva Catmull-Rom passando pelos pontos (a mesma do desenho do mundo)."""
    resultado = []
    estendidos = [pontos[0]] + list(pontos) + [pontos[-1]]
    for indice in range(1, len(estendidos) - 2):
        p0, p1, p2, p3 = estendidos[indice - 1], estendidos[indice], estendidos[indice + 1], estendidos[indice + 2]
        amostras = max(int(math.dist(p1, p2) / passo), 1)
        for amostra in range(amostras):
            t = amostra / amostras
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2 + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            z = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2 + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            resultado.append((x, z))
    resultado.append(tuple(pontos[-1]))
    return resultado


def raio_do_laguinho(angulo):
    """O raio da beira do laguinho na direção dada, com a margem ondulada."""
    rx, rz = LAGUINHO_RAIOS
    base = (rx * rz) / math.sqrt((rz * math.cos(angulo)) ** 2 + (rx * math.sin(angulo)) ** 2)
    return base * (1.0 + 0.08 * math.sin(angulo * 3 + 1.0) + 0.05 * math.sin(angulo * 5 + 2.0))


def distancia_fora_da_cerca(x, z):
    """Quanto o ponto está do lado de fora da cerca (zero dentro)."""
    dx = max(-x, 0.0, x - LARGURA)
    dz = max(-z, 0.0, z - PROFUNDIDADE)
    return math.hypot(dx, dz)
