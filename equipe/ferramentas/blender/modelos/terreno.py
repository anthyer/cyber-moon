"""O chão do mapa mundi, com relevo, e a água do rio e do aquífero.

Lê o traçado de `equipe/ferramentas/desenho_do_mundo.py` e gera dois modelos no pacote
`cyber_moon_mundo`:

- `chao_terreno_mundo.glb`: uma malha só, facetada como o Nature Kit, com o leito do rio
  afundado, o cânion, a bacia do aquífero e os terraços com rampa. A cor de cada face sai
  da paleta pela altura, pela inclinação e pelo que está ali: areia, poeira vermelha,
  estrato de rocha no barranco, trilha clara, asfalto, terra rachada na borda.
- `enfeite_agua_do_mundo.glb`: a água, com a forma do rio e do lago. A cor de cada vértice
  guarda a distância até a margem (vermelho de 0 na beira a 1 no meio), que o shader de
  água usa para desenhar a espuma.

Rodar com o Blender sem janela, a partir da raiz do repositório:

    flatpak run org.blender.Blender -b --python-expr "import runpy,sys; sys.path.insert(0,'equipe/ferramentas/blender/modelos'); runpy.run_path('equipe/ferramentas/blender/modelos/terreno.py', run_name='__main__')"
"""

import math
import os
import sys

import bpy
import numpy as np

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(AQUI))
sys.path.insert(0, os.path.dirname(os.path.dirname(AQUI)))
import kit_cyber_moon as kit
import desenho_do_mundo as dm

PACOTE = "cyber_moon_mundo"
PASSO_DA_GRADE = 1.0

# Os tons do chão, como "célula@ponto do degradê" (0 é o pé escuro, 1 o topo claro).
AREIA = "pessego@0.35"
POEIRA = "salmao@0.45"
TRILHA = "pessego@0.75"
PRACA = "pessego@0.62"


def distancia_a_curva(x, z, curva):
    """Distância de cada ponto (x, z) até a curva (lista de pontos), em lotes."""
    pontos = np.array(curva)
    menor = np.full(x.shape, np.inf)
    for inicio in range(0, len(pontos) - 1, 64):
        a = pontos[inicio:inicio + 65]
        p0 = a[:-1]
        p1 = a[1:]
        segmento = p1 - p0
        comprimento2 = np.maximum((segmento ** 2).sum(axis=1), 1e-9)
        px = x[..., None] - p0[:, 0]
        pz = z[..., None] - p0[:, 1]
        t = np.clip((px * segmento[:, 0] + pz * segmento[:, 1]) / comprimento2, 0.0, 1.0)
        dx = px - t * segmento[:, 0]
        dz = pz - t * segmento[:, 1]
        menor = np.minimum(menor, np.sqrt(dx * dx + dz * dz).min(axis=-1))
    return menor


def ponto_mais_perto_da_curva(x, z, curva):
    """Para cada ponto (x, z), o ponto da curva mais perto dele e a distância até lá."""
    pontos = np.array(curva)
    menor = np.full(x.shape, np.inf)
    perto_x = np.zeros(x.shape)
    perto_z = np.zeros(x.shape)
    for inicio in range(0, len(pontos) - 1, 64):
        a = pontos[inicio:inicio + 65]
        p0 = a[:-1]
        segmento = a[1:] - p0
        comprimento2 = np.maximum((segmento ** 2).sum(axis=1), 1e-9)
        px = x[..., None] - p0[:, 0]
        pz = z[..., None] - p0[:, 1]
        t = np.clip((px * segmento[:, 0] + pz * segmento[:, 1]) / comprimento2, 0.0, 1.0)
        qx = p0[:, 0] + t * segmento[:, 0]
        qz = p0[:, 1] + t * segmento[:, 1]
        distancia = np.hypot(x[..., None] - qx, z[..., None] - qz)
        qual = distancia.argmin(axis=-1)
        desta_vez = np.take_along_axis(distancia, qual[..., None], axis=-1)[..., 0]
        melhor = desta_vez < menor
        menor = np.where(melhor, desta_vez, menor)
        perto_x = np.where(melhor, np.take_along_axis(qx, qual[..., None], axis=-1)[..., 0], perto_x)
        perto_z = np.where(melhor, np.take_along_axis(qz, qual[..., None], axis=-1)[..., 0], perto_z)
    return menor, perto_x, perto_z


def encaixar_nas_margens(gx, gz):
    """Puxa os vértices da grade que caem perto do pé ou do topo de um barranco para cima
    da curva exata dele.

    A grade tem 1 de passo e o barranco tem menos que isso de largura: sem o encaixe, o
    topo e o pé do barranco caem entre os vértices e a beira do rio sai serrilhada. Com
    ele, cada barranco vira uma faixa limpa entre duas linhas que seguem a curva.
    """
    gx, gz = gx.copy(), gz.copy()
    alcance = 0.5

    def encaixar_no_curso(curva, meias_larguras, largura_da_margem):
        distancia, perto_x, perto_z = ponto_mais_perto_da_curva(gx, gz, curva)
        pe = meias_larguras(gz)
        topo = pe + largura_da_margem
        # Cada vértice vai para a linha (pé ou topo) mais perto dele, se estiver no alcance.
        alvo = np.where(np.abs(distancia - pe) <= np.abs(distancia - topo), pe, topo)
        puxar = (np.abs(distancia - alvo) < alcance) & (distancia > 1e-6)
        fator = np.where(puxar, alvo / np.maximum(distancia, 1e-6), 1.0)
        gx[:] = np.where(puxar, perto_x + (gx - perto_x) * fator, gx)
        gz[:] = np.where(puxar, perto_z + (gz - perto_z) * fator, gz)

    encaixar_no_curso(dm.suavizar(dm.RIO), meia_largura_do_rio, dm.LARGURA_DA_MARGEM_DO_RIO)
    encaixar_no_curso(dm.suavizar(dm.CANION), lambda z: np.full(z.shape, dm.MEIA_LARGURA_DO_CANION),
                      dm.LARGURA_DA_PAREDE_DO_CANION)

    # O lago: pelo raio, a partir do centro. O pé do barranco fica a uma margem para dentro
    # da beira, e o topo na beira.
    cx, cz = dm.AQUIFERO_CENTRO
    for recuo in (-dm.LARGURA_DA_MARGEM_DO_AQUIFERO, 0.0):
        d_lago = distancia_ao_aquifero(gx, gz)
        puxar = np.abs(d_lago - recuo) < alcance
        raio_atual = np.maximum(np.hypot(gx - cx, gz - cz), 1e-6)
        fator = np.where(puxar, (raio_atual - d_lago + recuo) / raio_atual, 1.0)
        gx = np.where(puxar, cx + (gx - cx) * fator, gx)
        gz = np.where(puxar, cz + (gz - cz) * fator, gz)
    return gx, gz


def distancia_ao_aquifero(x, z):
    """Distância com sinal até a margem do aquífero: negativa dentro do lago."""
    cx, cz = dm.AQUIFERO_CENTRO
    angulo = np.arctan2(z - cz, x - cx)
    rx, rz = dm.AQUIFERO_RAIOS
    base = (rx * rz) / np.sqrt((rz * np.cos(angulo)) ** 2 + (rx * np.sin(angulo)) ** 2)
    raio = base * (1.0 + 0.09 * np.sin(angulo * 3 + dm.AQUIFERO_SEMENTE) + 0.06 * np.sin(angulo * 5 + dm.AQUIFERO_SEMENTE * 2))
    return np.hypot(x - cx, z - cz) - raio


def meia_largura_do_rio(z):
    return dm.MEIA_LARGURA_DO_RIO + dm.VARIACAO_DA_LARGURA_DO_RIO * np.sin(z * 0.11 + 1.3) * np.cos(z * 0.047)


def rebaixar(altura, distancia, meia_largura, largura_da_margem, fundo):
    """Afunda o chão perto de um curso: fundo no leito, barranco íngreme até o chão."""
    fator = np.clip((distancia - meia_largura) / largura_da_margem, 0.0, 1.0)
    return fundo + (altura - fundo) * fator


def altura_do_chao(x, z):
    curva_do_rio = dm.suavizar(dm.RIO)
    curva_do_canion = dm.suavizar(dm.CANION)
    d_rio = distancia_a_curva(x, z, curva_do_rio)
    d_canion = distancia_a_curva(x, z, curva_do_canion)
    d_lago = distancia_ao_aquifero(x, z)

    # Dunas baixinhas, só para o chão não ser uma tábua. Somem perto das trilhas.
    perto_da_trilha = np.full(x.shape, np.inf)
    for pontos, _largura in dm.TRILHAS:
        perto_da_trilha = np.minimum(perto_da_trilha, distancia_a_curva(x, z, dm.suavizar(pontos)))
    dunas = 0.09 * np.sin(x * 0.31) + 0.07 * np.sin(z * 0.27 + x * 0.13) + 0.05 * np.sin((x - z) * 0.53)
    altura = dunas * np.clip((perto_da_trilha - 1.5) / 3.0, 0.0, 1.0)

    # Terraços com rampa.
    for tx, tz, rx, rz, subida, rampa in dm.TERRACOS:
        normal = np.sqrt(((x - tx) / rx) ** 2 + ((z - tz) / rz) ** 2)
        fora = (normal - 1.0) * min(rx, rz)
        fator = np.clip(1.0 - fora / rampa, 0.0, 1.0)
        altura = np.maximum(altura, subida * fator)

    altura = rebaixar(altura, d_rio, meia_largura_do_rio(z), dm.LARGURA_DA_MARGEM_DO_RIO, dm.FUNDO_DO_RIO)
    altura = rebaixar(altura, d_canion, dm.MEIA_LARGURA_DO_CANION, dm.LARGURA_DA_PAREDE_DO_CANION, dm.FUNDO_DO_CANION)
    margem = dm.LARGURA_DA_MARGEM_DO_AQUIFERO
    fator = np.clip((d_lago + margem) / margem, 0.0, 1.0)
    altura = dm.FUNDO_DO_AQUIFERO + (altura - dm.FUNDO_DO_AQUIFERO) * fator
    return altura, d_rio, d_canion, d_lago, perto_da_trilha


def ruido(x, z, semente):
    return (np.sin(x * 0.17 + semente) + np.sin(z * 0.21 - semente * 2) + np.sin((x + z) * 0.11 + semente * 3)) / 3.0


def cor_das_faces(cx, cz, altura_media, inclinacao, d_rio, d_canion, d_lago, d_trilha):
    """O nome da cor da paleta para cada face, pela ordem de prioridade."""
    # A areia usa o tom médio do degradê da célula, e não o chapado: o chapado do pêssego
    # e do creme é claro demais e estoura para o branco com o sol do meio-dia.
    cores = np.full(cx.shape, AREIA, dtype=object)
    # Manchas grandes de poeira vermelha, de borda irregular. Frequência baixa: são
    # regiões, não bolinhas.
    poeira = (np.sin(cx * 0.06 + 1.1) + np.sin(cz * 0.08 - 0.7) + 0.6 * np.sin((cx + cz) * 0.13 + 2.0)
              + 0.12 * np.sin(cx * 0.45 + cz * 0.35)) > 0.9
    cores[poeira] = POEIRA
    # Terra rachada na borda do mapa: a faixa tem largura irregular e o rachado é um
    # mosaico de ferrugem e marrom.
    largura_da_borda = 3.5 + 2.5 * np.sin(cx * 0.21 + cz * 0.17) + 1.5 * np.sin(cz * 0.43)
    distancia_da_borda = np.minimum.reduce([cx, dm.LARGURA - cx, dm.PROFUNDIDADE - cz + 2.0])
    borda = distancia_da_borda < largura_da_borda
    rachado = (np.abs(np.sin(cx * 1.9 + np.sin(cz * 1.3) * 2.0)) < 0.18) | (np.abs(np.sin(cz * 2.1 + np.sin(cx * 1.1) * 2.0)) < 0.18)
    cores[borda] = "ferrugem"
    cores[borda & rachado] = "marrom"
    # Trilhas (a primeira é a pista de asfalto sob o viaduto).
    for indice, (pontos, largura) in enumerate(dm.TRILHAS):
        dentro = distancia_a_curva(cx, cz, dm.suavizar(pontos)) < largura / 2.0
        cores[dentro] = "grafite" if indice == 0 else TRILHA
    # Praça do mercado.
    tx, tz, rx, rz, _subida, _rampa = dm.TERRACOS[0]
    praca = np.sqrt(((cx - tx) / rx) ** 2 + ((cz - tz) / rz) ** 2) < 0.92
    cores[praca] = PRACA
    # Barranco: estrato de rocha pela altura.
    barranco = inclinacao > 0.45
    estrato = np.where(np.floor((altura_media + 4.0) * 2.2) % 2 == 0, "ferrugem", "salmao")
    cores[barranco] = estrato[barranco]
    # Fundo do rio, do lago e do cânion.
    fundo = (d_rio < meia_largura_do_rio(cz)) | (d_lago < 0) | (d_canion < dm.MEIA_LARGURA_DO_CANION)
    cores[fundo & (inclinacao <= 0.45)] = "marrom"
    return cores


def montar_terreno():
    margem = dm.MARGEM_DO_TERRENO
    xs = np.arange(-margem, dm.LARGURA + margem + 0.01, PASSO_DA_GRADE)
    zs = np.arange(-margem, dm.PROFUNDIDADE + margem + 0.01, PASSO_DA_GRADE)
    gx, gz = np.meshgrid(xs, zs)
    # Um tremor pequeno na grade dá a cara facetada, sem linhas retas no chão.
    tremor = 0.22
    gx = gx + tremor * np.sin(gz * 1.7 + gx * 0.9)
    gz = gz + tremor * np.sin(gx * 1.3 - gz * 0.7)
    gx, gz = encaixar_nas_margens(gx, gz)
    altura, *_ = altura_do_chao(gx, gz)

    linhas, colunas = gx.shape
    vertices = np.stack([gx.ravel(), -gz.ravel(), altura.ravel()], axis=1)
    faces = []
    for linha in range(linhas - 1):
        for coluna in range(colunas - 1):
            a = linha * colunas + coluna
            b = a + 1
            c = a + colunas
            d = c + 1
            if (linha + coluna) % 2 == 0:
                faces.append((a, c, b))
                faces.append((b, c, d))
            else:
                faces.append((a, c, d))
                faces.append((a, d, b))
    faces = np.array(faces)

    # Atributos de cada face, para escolher a cor.
    tri = vertices[faces]
    centro = tri.mean(axis=1)
    cx, cz, hm = centro[:, 0], -centro[:, 1], centro[:, 2]
    normal = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    normal /= np.linalg.norm(normal, axis=1)[:, None]
    inclinacao = 1.0 - np.abs(normal[:, 2])
    _h, d_rio, d_canion, d_lago, d_trilha = altura_do_chao(cx, cz)
    cores = cor_das_faces(cx, cz, hm, inclinacao, d_rio, d_canion, d_lago, d_trilha)

    malha = bpy.data.meshes.new("chao_terreno_mundo")
    malha.from_pydata(vertices.tolist(), [], faces.tolist())
    malha.update()
    camada = malha.uv_layers.new(name="UVMap")
    uv = np.zeros((len(faces) * 3, 2))
    tabela = {}
    for nome in set(cores.tolist()):
        if "@" in nome:
            celula, ponto = nome.split("@")
            tabela[nome] = kit.uv_da_cor(celula, float(ponto))
        else:
            tabela[nome] = kit.uv_da_cor(nome)
    for indice, nome in enumerate(cores):
        uv[indice * 3:indice * 3 + 3] = tabela[nome]
    camada.data.foreach_set("uv", uv.ravel())
    malha.materials.append(kit.material_da_paleta(False))
    # O chão é facetado, mas o barranco é liso: facetado, cada triângulo do barranco pega
    # a luz de um jeito e a beira do rio vira um serrote de faces claras e escuras.
    lisas = (inclinacao > 0.45).tolist()
    malha.polygons.foreach_set("use_smooth", lisas)
    objeto = bpy.data.objects.new("chao_terreno_mundo", malha)
    bpy.context.scene.collection.objects.link(objeto)
    return objeto


def montar_agua():
    """A água: uma fita que segue o rio e um leque que preenche o lago, com a distância até
    a margem na cor dos vértices (0 na beira, 1 a dois de distância).

    A beira da água entra por baixo do barranco. Ela é uma curva lisa, e não recortada de
    uma grade: recortada, a linha d'água sai em escadinha onde o barranco a deixa à vista.
    """
    vertices = []
    cores = []
    faces = []
    entra_no_barranco = 0.6
    alcance_da_espuma = 2.0

    # O rio: cinco vértices atravessando o curso, das duas beiras para o meio.
    curva = dm.suavizar(dm.RIO, passo=0.5)
    anterior = None
    for indice, (x, z) in enumerate(curva):
        if distancia_ao_aquifero(np.array(x), np.array(z)) < -0.8:
            break
        a = curva[max(indice - 1, 0)]
        b = curva[min(indice + 1, len(curva) - 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        comprimento = math.hypot(dx, dz) or 1.0
        nx, nz = dz / comprimento, -dx / comprimento
        meia = float(meia_largura_do_rio(np.array(z))) + entra_no_barranco
        dentro = max(meia - alcance_da_espuma, 0.1)
        linha = []
        for desvio in (-meia, -dentro, 0.0, dentro, meia):
            linha.append(len(vertices))
            vertices.append((x + nx * desvio, -(z + nz * desvio), dm.ALTURA_DA_AGUA))
            cores.append((min((meia - abs(desvio)) / alcance_da_espuma, 1.0), 0.0, 0.0, 1.0))
        if anterior is not None:
            for coluna in range(4):
                faces.append((anterior[coluna], linha[coluna], linha[coluna + 1], anterior[coluna + 1]))
        anterior = linha

    # O lago: um leque do centro até um anel por baixo do barranco. Onde o rio desemboca,
    # o anel não tem espuma, para não riscar uma linha branca atravessando a boca do rio.
    cx, cz = dm.AQUIFERO_CENTRO
    centro = len(vertices)
    vertices.append((cx, -cz, dm.ALTURA_DA_AGUA))
    cores.append((1.0, 0.0, 0.0, 1.0))
    curva_do_rio = dm.suavizar(dm.RIO)
    pontos_do_anel = 120
    anel_de_fora = []
    anel_de_dentro = []
    for indice in range(pontos_do_anel):
        angulo = math.tau * indice / pontos_do_anel
        raio = dm.raio_do_aquifero(angulo) - dm.LARGURA_DA_MARGEM_DO_AQUIFERO + entra_no_barranco + 0.4
        fx, fz = cx + math.cos(angulo) * raio, cz + math.sin(angulo) * raio
        na_boca = distancia_a_curva(np.array([fx]), np.array([fz]), curva_do_rio)[0] < float(meia_largura_do_rio(np.array(fz))) + 1.0
        anel_de_fora.append(len(vertices))
        vertices.append((fx, -fz, dm.ALTURA_DA_AGUA))
        cores.append((1.0 if na_boca else 0.0, 0.0, 0.0, 1.0))
        raio_de_dentro = raio - alcance_da_espuma
        anel_de_dentro.append(len(vertices))
        vertices.append((cx + math.cos(angulo) * raio_de_dentro, -(cz + math.sin(angulo) * raio_de_dentro), dm.ALTURA_DA_AGUA))
        cores.append((1.0, 0.0, 0.0, 1.0))
    for indice in range(pontos_do_anel):
        seguinte = (indice + 1) % pontos_do_anel
        faces.append((anel_de_fora[indice], anel_de_fora[seguinte], anel_de_dentro[seguinte], anel_de_dentro[indice]))
        faces.append((anel_de_dentro[indice], anel_de_dentro[seguinte], centro))

    malha = bpy.data.meshes.new("enfeite_agua_do_mundo")
    malha.from_pydata(vertices, [], faces)
    malha.update()
    # A face tem que olhar para cima; a ordem dos vértices acima varia entre o rio e o lago.
    for poligono in malha.polygons:
        if poligono.normal.z < 0:
            poligono.flip()
    malha.update()
    atributo = malha.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="POINT")
    atributo.data.foreach_set("color", np.array(cores).ravel())
    objeto = bpy.data.objects.new("enfeite_agua_do_mundo", malha)
    bpy.context.scene.collection.objects.link(objeto)
    return objeto


def exportar_agua(objeto):
    """A água não usa a paleta (o jogo põe o shader de água por cima), mas precisa levar a
    cor dos vértices, que é onde está a distância até a margem."""
    caminho = os.path.join(kit.PASTA_DO_PACOTE, "enfeite_agua_do_mundo.glb")
    bpy.context.view_layer.update()
    for outro in bpy.context.view_layer.objects:
        if outro is not None:
            outro.select_set(False)
    objeto.select_set(True)
    bpy.context.view_layer.objects.active = objeto
    opcoes = dict(filepath=caminho, export_format="GLB", use_selection=True, export_image_format="NONE",
                  export_yup=True, export_animations=False, export_materials="NONE")
    try:
        bpy.ops.export_scene.gltf(export_vertex_color="ACTIVE", **opcoes)
    except TypeError:
        bpy.ops.export_scene.gltf(export_colors=True, **opcoes)
    print("exportado enfeite_agua_do_mundo", len(objeto.data.polygons) * 2, "triangulos")


def gravar_alturas():
    """Grava a altura do chão em cada ponto inteiro do mapa, para o gerador do mapa
    assentar as peças no relevo sem precisar do Blender."""
    import json
    xs = np.arange(-2.0, dm.LARGURA + 2.01, 1.0)
    zs = np.arange(-2.0, dm.PROFUNDIDADE + 2.01, 1.0)
    gx, gz = np.meshgrid(xs, zs)
    altura, *_ = altura_do_chao(gx, gz)
    caminho = os.path.join(os.path.dirname(os.path.dirname(AQUI)), "altura_do_mundo.json")
    with open(caminho, "w") as arquivo:
        json.dump({"x0": -2.0, "z0": -2.0, "passo": 1.0, "colunas": len(xs), "linhas": len(zs),
                   "alturas": [round(float(v), 3) for v in altura.ravel()]}, arquivo)
    print("gravado", caminho)


def gravar_mascara_da_grama():
    """Grava onde nasce a graminha perto do jogador, uma célula por unidade do mapa.

    Vermelho é a densidade (0 sem grama: água, barranco, trilha, praça, asfalto; 1 na
    areia; pouco na terra rachada da borda). Verde é a umidade (1 perto da água, onde a
    grama sai mais verde). O jogo lê com `GramaPertoDoJogador`.
    """
    xs = np.arange(0.0, dm.LARGURA + 1.0, 1.0)
    zs = np.arange(0.0, dm.PROFUNDIDADE + 1.0, 1.0)
    gx, gz = np.meshgrid(xs, zs)
    _altura, d_rio, d_canion, d_lago, _t = altura_do_chao(gx, gz)
    densidade = np.ones(gx.shape)
    # Nada de grama em cima da trilha; ela volta aos poucos na beira.
    for pontos, largura in dm.TRILHAS:
        perto = distancia_a_curva(gx, gz, dm.suavizar(pontos))
        densidade = np.minimum(densidade, np.clip((perto - largura / 2.0 - 0.2) / 1.5, 0.0, 1.0))
    meia = meia_largura_do_rio(gz)
    densidade[d_rio < meia + dm.LARGURA_DA_MARGEM_DO_RIO + 0.3] = 0.0
    densidade[d_canion < dm.MEIA_LARGURA_DO_CANION + dm.LARGURA_DA_PAREDE_DO_CANION + 0.3] = 0.0
    densidade[d_lago < dm.LARGURA_DA_MARGEM_DO_AQUIFERO + 0.3] = 0.0
    tx, tz, rx, rz, _s, _r = dm.TERRACOS[0]
    densidade[np.sqrt(((gx - tx) / rx) ** 2 + ((gz - tz) / rz) ** 2) < 1.0] = 0.0
    largura_da_borda = 3.5 + 2.5 * np.sin(gx * 0.21 + gz * 0.17) + 1.5 * np.sin(gz * 0.43)
    distancia_da_borda = np.minimum.reduce([gx, dm.LARGURA - gx, dm.PROFUNDIDADE - gz + 2.0])
    densidade[distancia_da_borda < largura_da_borda] *= 0.3
    umidade = np.clip(1.0 - (np.minimum(d_rio - meia, d_lago) - 1.5) / 5.0, 0.0, 1.0)
    imagem = bpy.data.images.new("mascara_da_grama", width=len(xs), height=len(zs), alpha=False, float_buffer=False)
    pixels = np.zeros((len(zs), len(xs), 4))
    # A imagem do Blender começa embaixo; a linha 0 do arquivo tem que ser z = 0.
    pixels[:, :, 0] = densidade[::-1]
    pixels[:, :, 1] = umidade[::-1]
    pixels[:, :, 3] = 1.0
    imagem.pixels.foreach_set(pixels.astype(np.float32).ravel())
    caminho = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(AQUI)))), "game", "assets", "textures", "grama", "mascara_do_mundo.png")
    os.makedirs(os.path.dirname(caminho), exist_ok=True)
    imagem.filepath_raw = caminho
    imagem.file_format = "PNG"
    imagem.save()
    print("gravado", caminho)


if __name__ == "__main__":
    gravar_alturas()
    gravar_mascara_da_grama()
    kit.usar_pacote(PACOTE)
    kit.limpar_cena()
    terreno = montar_terreno()
    kit.exportar(terreno, "chao_terreno_mundo")
    agua = montar_agua()
    exportar_agua(agua)
    kit.foto("terreno", [terreno, agua], direcao=(0.0, -0.6, 1.0), resolucao=(1600, 1150), margem=1.0)
