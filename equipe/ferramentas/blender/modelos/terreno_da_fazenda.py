"""O chão do mapa da fazenda e a água do laguinho.

Lê o traçado de `equipe/ferramentas/desenho_da_fazenda.py` e gera, no pacote
`cyber_moon_mundo`:

- `chao_terreno_fazenda.glb`: tudo que não é gramado. Os caminhos de terra batida, o chão
  dos talhões, o laguinho afundado com barranco, a terra rachada do lado de fora da cerca
  e as dunas que sobem em volta (a fazenda fica num vale raso). Cor da paleta por face,
  como o terreno do mundo.
- `chao_terreno_fazenda_gramado.glb`: o gramado de dentro da cerca, sem material. A cor de
  cada face é um cinza (manchas mais claras e mais escuras) na cor dos vértices; o jogo
  multiplica pela cor da grama da estação (`GramaDaEstacao`), que muda o verde ao longo
  do ano.
- `enfeite_agua_da_fazenda.glb`: a água do laguinho, com a distância até a beira na cor
  dos vértices, para a espuma do shader de água.

Os dois chãos começam com `chao_terreno`: o post-import põe os dois na camada "chao".

Rodar com o Blender sem janela, a partir da raiz do repositório (caminhos absolutos):

    flatpak run org.blender.Blender -b --python-expr "import runpy,sys; sys.path.insert(0,'<raiz>/equipe/ferramentas/blender/modelos'); runpy.run_path('<raiz>/equipe/ferramentas/blender/modelos/terreno_da_fazenda.py', run_name='__main__')"
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
import desenho_da_fazenda as df
from terreno import distancia_a_curva, ponto_mais_perto_da_curva

PACOTE = "cyber_moon_mundo"

AREIA = "pessego@0.35"
POEIRA = "salmao@0.45"
TERRA_BATIDA = "pessego@0.2"


def distancia_ao_laguinho(x, z):
    """Distância com sinal até a beira do laguinho: negativa dentro dele."""
    cx, cz = df.LAGUINHO_CENTRO
    angulo = np.arctan2(z - cz, x - cx)
    rx, rz = df.LAGUINHO_RAIOS
    base = (rx * rz) / np.sqrt((rz * np.cos(angulo)) ** 2 + (rx * np.sin(angulo)) ** 2)
    raio = base * (1.0 + 0.08 * np.sin(angulo * 3 + 1.0) + 0.05 * np.sin(angulo * 5 + 2.0))
    return np.hypot(x - cx, z - cz) - raio


def distancia_fora_da_cerca(x, z):
    dx = np.maximum.reduce([-x, np.zeros(x.shape), x - df.LARGURA])
    dz = np.maximum.reduce([-z, np.zeros(z.shape), z - df.PROFUNDIDADE])
    return np.hypot(dx, dz)


def distancia_aos_caminhos(x, z):
    """Distância até a beira do caminho mais perto (negativa em cima dele)."""
    menor = np.full(x.shape, np.inf)
    for pontos, largura in df.CAMINHOS:
        menor = np.minimum(menor, distancia_a_curva(x, z, df.suavizar(pontos)) - largura / 2.0)
    return menor


def altura_do_chao(x, z):
    fora = distancia_fora_da_cerca(x, z)
    caminho = distancia_aos_caminhos(x, z)
    # O vale: plano até a terra rachada acabar, depois dunas subindo, com ondulação.
    subida = np.clip((fora - df.LARGURA_DA_TERRA_RACHADA) / 12.0, 0.0, 1.0)
    subida = subida * subida * (3.0 - 2.0 * subida)
    ondas = 0.5 + 0.25 * np.sin(x * 0.23 + 1.0) + 0.15 * np.sin(z * 0.31 - x * 0.12) + 0.1 * np.sin((x + z) * 0.57)
    altura = df.ALTURA_DAS_DUNAS * subida * ondas
    altura += 0.08 * np.sin(x * 0.7) * np.sin(z * 0.6) * np.clip(fora - 1.0, 0.0, 1.0)
    # O caminho que sai pela porteira fica plano até o fim.
    altura *= np.clip((caminho - 1.0) / 3.0, 0.0, 1.0)
    # O laguinho, afundado com barranco.
    d_lago = distancia_ao_laguinho(x, z)
    margem = df.LARGURA_DA_MARGEM_DO_LAGUINHO
    fator = np.clip((d_lago + margem) / margem, 0.0, 1.0)
    altura = df.FUNDO_DO_LAGUINHO + (altura - df.FUNDO_DO_LAGUINHO) * fator
    return altura


def encaixar_no_laguinho(gx, gz):
    """Puxa os vértices perto do pé e do topo do barranco do laguinho para a curva exata,
    como no rio do mundo: sem isso a beira sai serrilhada."""
    cx, cz = df.LAGUINHO_CENTRO
    for recuo in (-df.LARGURA_DA_MARGEM_DO_LAGUINHO, 0.0):
        d_lago = distancia_ao_laguinho(gx, gz)
        puxar = np.abs(d_lago - recuo) < 0.35
        raio_atual = np.maximum(np.hypot(gx - cx, gz - cz), 1e-6)
        fator = np.where(puxar, (raio_atual - d_lago + recuo) / raio_atual, 1.0)
        gx = np.where(puxar, cx + (gx - cx) * fator, gx)
        gz = np.where(puxar, cz + (gz - cz) * fator, gz)
    return gx, gz


def encaixar_nos_caminhos(gx, gz):
    """Puxa cada vértice perto da beira de um caminho para cima da beira exata. A grade
    tem 1 de passo, então toda linha dela tem um vértice a menos de meio da beira: com o
    encaixe, a beira do caminho segue a curva em vez de sair em escadinha."""
    gx, gz = gx.copy(), gz.copy()
    melhor = np.full(gx.shape, np.inf)
    alvo_x, alvo_z = gx.copy(), gz.copy()
    for pontos, largura in df.CAMINHOS:
        distancia, perto_x, perto_z = ponto_mais_perto_da_curva(gx, gz, df.suavizar(pontos))
        folga = np.abs(distancia - largura / 2.0)
        puxar = (folga < 0.5) & (folga < melhor) & (distancia > 1e-6)
        fator = np.where(puxar, (largura / 2.0) / np.maximum(distancia, 1e-6), 1.0)
        alvo_x = np.where(puxar, perto_x + (gx - perto_x) * fator, alvo_x)
        alvo_z = np.where(puxar, perto_z + (gz - perto_z) * fator, alvo_z)
        melhor = np.where(puxar, folga, melhor)
    # Vértice em cima de um talhão (ou na borda dele) não sai do lugar: a borda do talhão
    # é reta e cai na grade.
    fixo = dentro_de_talhao(gx, gz, folga=0.01)
    return np.where(fixo, gx, alvo_x), np.where(fixo, gz, alvo_z)


def dentro_de_talhao(x, z, folga=0.0):
    dentro = np.zeros(x.shape, dtype=bool)
    for tx, tz, largura, profundidade, _liberado in df.TALHOES:
        dentro |= (x > tx - folga) & (x < tx + largura + folga) & (z > tz - folga) & (z < tz + profundidade + folga)
    return dentro


def montar_chao():
    m = df.MARGEM_DO_TERRENO
    xs = np.arange(-m, df.LARGURA + m + 0.01, 1.0)
    zs = np.arange(-m, df.PROFUNDIDADE + m + 0.01, 1.0)
    gx, gz = np.meshgrid(xs, zs)
    # Tremor só fora da cerca: dentro, a grade reta casa com os talhões e a cerca.
    fora = distancia_fora_da_cerca(gx, gz) > 0.5
    gx = gx + np.where(fora, 0.22 * np.sin(gz * 1.7 + gx * 0.9), 0.0)
    gz = gz + np.where(fora, 0.22 * np.sin(gx * 1.3 - gz * 0.7), 0.0)
    gx, gz = encaixar_nos_caminhos(gx, gz)
    gx, gz = encaixar_no_laguinho(gx, gz)
    altura = altura_do_chao(gx, gz)

    linhas, colunas = gx.shape
    vertices = np.stack([gx.ravel(), -gz.ravel(), altura.ravel()], axis=1)
    faces = []
    for linha in range(linhas - 1):
        for coluna in range(colunas - 1):
            a = linha * colunas + coluna
            b, c, d = a + 1, a + colunas, a + colunas + 1
            if (linha + coluna) % 2 == 0:
                faces += [(a, c, b), (b, c, d)]
            else:
                faces += [(a, c, d), (a, d, b)]
    faces = np.array(faces)
    tri = vertices[faces]
    centro = tri.mean(axis=1)
    cx, cz, hm = centro[:, 0], -centro[:, 1], centro[:, 2]
    normal = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    normal /= np.linalg.norm(normal, axis=1)[:, None]
    inclinacao = 1.0 - np.abs(normal[:, 2])

    fora_da_cerca = distancia_fora_da_cerca(cx, cz)
    caminho = distancia_aos_caminhos(cx, cz) < 0.0
    d_lago = distancia_ao_laguinho(cx, cz)
    perto_do_lago = d_lago < 0.25
    talhao = dentro_de_talhao(cx, cz)
    gramado = (fora_da_cerca <= 0.0) & ~caminho & ~perto_do_lago & ~talhao

    # Cores do que não é gramado.
    cores = np.full(cx.shape, AREIA, dtype=object)
    poeira = (np.sin(cx * 0.09 + 1.1) + np.sin(cz * 0.11 - 0.7) + 0.4 * np.sin((cx + cz) * 0.2)) > 0.8
    cores[poeira] = POEIRA
    largura_rachada = df.LARGURA_DA_TERRA_RACHADA + 1.2 * np.sin(cx * 0.37 + cz * 0.21) + 0.8 * np.sin(cz * 0.53 - cx * 0.2)
    rachada = (fora_da_cerca > 0.0) & (fora_da_cerca < largura_rachada)
    rachado = (np.abs(np.sin(cx * 1.9 + np.sin(cz * 1.3) * 2.0)) < 0.18) | (np.abs(np.sin(cz * 2.1 + np.sin(cx * 1.1) * 2.0)) < 0.18)
    cores[rachada] = "ferrugem"
    cores[rachada & rachado] = "marrom"
    cores[caminho] = TERRA_BATIDA
    cores[talhao] = "marrom"
    barranco = inclinacao > 0.45
    estrato = np.where(np.floor((hm + 4.0) * 3.0) % 2 == 0, "ferrugem", "salmao")
    cores[barranco] = estrato[barranco]
    cores[(d_lago < -df.LARGURA_DA_MARGEM_DO_LAGUINHO + 0.2) & ~barranco] = "marrom"

    terra = _malha_de_faces("chao_terreno_fazenda", vertices, faces[~gramado], inclinacao[~gramado])
    _pintar_pela_paleta(terra, cores[~gramado])

    # O gramado: cinza em manchas, que o jogo multiplica pelo verde da estação.
    manchas = 0.9 + 0.06 * np.sin(cx * 0.21 + 0.4) * np.sin(cz * 0.26 - 1.0) + 0.04 * np.sin((cx - cz) * 0.45)
    sorteio = np.random.default_rng(31)
    manchas = np.clip(manchas + sorteio.uniform(-0.025, 0.025, manchas.shape), 0.0, 1.0)
    grama = _malha_de_faces("chao_terreno_fazenda_gramado", vertices, faces[gramado], inclinacao[gramado])
    _pintar_por_face(grama, manchas[gramado])
    return terra, grama


def _malha_de_faces(nome, vertices, faces, inclinacao):
    """Uma malha só com as faces dadas, e os vértices que elas usam."""
    usados, novos = np.unique(faces, return_inverse=True)
    malha = bpy.data.meshes.new(nome)
    malha.from_pydata(vertices[usados].tolist(), [], novos.reshape(faces.shape).tolist())
    malha.update()
    malha.polygons.foreach_set("use_smooth", (inclinacao > 0.45).tolist())
    objeto = bpy.data.objects.new(nome, malha)
    bpy.context.scene.collection.objects.link(objeto)
    return objeto


def _pintar_pela_paleta(objeto, cores):
    malha = objeto.data
    camada = malha.uv_layers.new(name="UVMap")
    uv = np.zeros((len(cores) * 3, 2))
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


def _pintar_por_face(objeto, cinzas):
    """Cor chapada por face, na cor dos cantos (cada face com o seu cinza)."""
    atributo = objeto.data.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="CORNER")
    cores = np.repeat(np.stack([cinzas, cinzas, cinzas, np.ones(cinzas.shape)], axis=1), 3, axis=0)
    atributo.data.foreach_set("color", cores.astype(np.float32).ravel())


def montar_agua():
    """O laguinho: leque do centro até um anel por baixo do barranco."""
    cx, cz = df.LAGUINHO_CENTRO
    vertices = [(cx, -cz, df.ALTURA_DA_AGUA_DO_LAGUINHO)]
    cores = [(1.0, 0.0, 0.0, 1.0)]
    faces = []
    pontos = 48
    for indice in range(pontos):
        angulo = math.tau * indice / pontos
        raio = df.raio_do_laguinho(angulo) - 0.2
        for desvio, beira in ((0.0, 0.0), (-0.9, 1.0)):
            vertices.append((cx + math.cos(angulo) * (raio + desvio), -(cz + math.sin(angulo) * (raio + desvio)), df.ALTURA_DA_AGUA_DO_LAGUINHO))
            cores.append((beira, 0.0, 0.0, 1.0))
    for indice in range(pontos):
        fora_a, dentro_a = 1 + indice * 2, 2 + indice * 2
        seguinte = (indice + 1) % pontos
        fora_b, dentro_b = 1 + seguinte * 2, 2 + seguinte * 2
        faces.append((fora_a, fora_b, dentro_b, dentro_a))
        faces.append((dentro_a, dentro_b, 0))
    malha = bpy.data.meshes.new("enfeite_agua_da_fazenda")
    malha.from_pydata(vertices, [], faces)
    malha.update()
    for poligono in malha.polygons:
        if poligono.normal.z < 0:
            poligono.flip()
    malha.update()
    atributo = malha.color_attributes.new(name="Col", type="FLOAT_COLOR", domain="POINT")
    atributo.data.foreach_set("color", np.array(cores, dtype=np.float32).ravel())
    objeto = bpy.data.objects.new("enfeite_agua_da_fazenda", malha)
    bpy.context.scene.collection.objects.link(objeto)
    return objeto


def exportar_com_cor_de_vertice(objeto, nome):
    """Exporta sem material, levando a cor dos vértices (o jogo põe o material)."""
    caminho = os.path.join(kit.PASTA_DO_PACOTE, nome + ".glb")
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
    print("exportado", nome, len(objeto.data.polygons), "triangulos")


if __name__ == "__main__":
    kit.usar_pacote(PACOTE)
    kit.limpar_cena()
    terra, grama = montar_chao()
    kit.exportar(terra, "chao_terreno_fazenda")
    exportar_com_cor_de_vertice(grama, "chao_terreno_fazenda_gramado")
    agua = montar_agua()
    exportar_com_cor_de_vertice(agua, "enfeite_agua_da_fazenda")
    kit.foto("terreno_da_fazenda", [terra, grama, agua], direcao=(0.0, -0.8, 1.0), resolucao=(1400, 1100), margem=1.0)
