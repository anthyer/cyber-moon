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
PASSO_DA_AGUA = 0.5


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
    for poligono in malha.polygons:
        poligono.use_smooth = False
    objeto = bpy.data.objects.new("chao_terreno_mundo", malha)
    bpy.context.scene.collection.objects.link(objeto)
    return objeto


def montar_agua():
    """A água como grade fina recortada no formato do rio e do lago, com a distância até
    a margem na cor dos vértices."""
    curva_do_rio = dm.suavizar(dm.RIO)
    minimo_x = min(min(p[0] for p in curva_do_rio), dm.AQUIFERO_CENTRO[0] - dm.AQUIFERO_RAIOS[0] * 1.2) - 3
    maximo_x = max(max(p[0] for p in curva_do_rio), dm.AQUIFERO_CENTRO[0] + dm.AQUIFERO_RAIOS[0] * 1.2) + 3
    minimo_z = min(p[1] for p in curva_do_rio) - 1
    maximo_z = dm.AQUIFERO_CENTRO[1] + dm.AQUIFERO_RAIOS[1] * 1.3
    xs = np.arange(minimo_x, maximo_x + 0.01, PASSO_DA_AGUA)
    zs = np.arange(minimo_z, maximo_z + 0.01, PASSO_DA_AGUA)
    gx, gz = np.meshgrid(xs, zs)
    d_rio = distancia_a_curva(gx, gz, curva_do_rio)
    d_lago = distancia_ao_aquifero(gx, gz)
    # A água entra um pouco por baixo do barranco, para não sobrar fresta na beira.
    alcance = meia_largura_do_rio(gz) + 0.3
    margem_do_rio = (alcance - d_rio)
    margem_do_lago = -d_lago + 0.4
    distancia_da_beira = np.maximum(margem_do_rio, margem_do_lago)
    dentro = distancia_da_beira > 0

    linhas, colunas = gx.shape
    indice_do_vertice = -np.ones(gx.shape, dtype=int)
    vertices = []
    cores = []
    for linha in range(linhas):
        for coluna in range(colunas):
            if dentro[linha, coluna]:
                indice_do_vertice[linha, coluna] = len(vertices)
                vertices.append((gx[linha, coluna], -gz[linha, coluna], dm.ALTURA_DA_AGUA))
                beira = min(max(distancia_da_beira[linha, coluna] / 2.0, 0.0), 1.0)
                cores.append((beira, 0.0, 0.0, 1.0))
    faces = []
    for linha in range(linhas - 1):
        for coluna in range(colunas - 1):
            canto = (indice_do_vertice[linha, coluna], indice_do_vertice[linha, coluna + 1],
                     indice_do_vertice[linha + 1, coluna + 1], indice_do_vertice[linha + 1, coluna])
            if min(canto) >= 0:
                faces.append((canto[0], canto[3], canto[2], canto[1]))
    malha = bpy.data.meshes.new("enfeite_agua_do_mundo")
    malha.from_pydata(vertices, [], faces)
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
