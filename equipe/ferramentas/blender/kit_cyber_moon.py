"""Kit de modelagem do Cyber Moon para o Blender.

Serve para criar modelos novos no mesmo estilo dos pacotes de cidade que o jogo usa:
poucas faces, um material só e a cor de cada face tirada de uma célula da paleta
`colormap.png`. O guia completo do estilo está em `game/docs/biblia_3d.md`.

Uso, dentro do Blender (console, aba Scripting ou `blender -b --python arquivo.py`):

    import sys
    sys.path.insert(0, "<repositorio>/equipe/ferramentas/blender")
    import kit_cyber_moon as kit

    m = kit.Modelo("barril")
    m.cilindro(raio=0.18, altura=0.5, cor="azul")
    m.cilindro(raio=0.19, altura=0.04, pos=(0, 0, 0.1), cor="cinza_claro")
    objeto = m.finalizar()
    kit.exportar(objeto, "barril")

Convenções de eixo: o Blender usa Z para cima e o exportador converte para o Y para
cima do Godot. A frente do modelo é o lado -Y do Blender, que no jogo vira +Z, o lado
da câmera. A origem do modelo fica no chão, no centro da base.

Escala: o pacote `cyber_moon_dungeons` é modelado no tamanho final do jogo, para entrar
na cena com escala 1. A referência é o personagem, que tem 0,66 de altura.
"""

import json
import math
import os
import struct

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

RAIZ_DO_REPOSITORIO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
PASTA_DO_PACOTE = os.path.join(RAIZ_DO_REPOSITORIO, "game", "assets", "models", "cyber_moon_dungeons")
CAMINHO_DA_PALETA = os.path.join(PASTA_DO_PACOTE, "textures", "colormap.png")
PASTA_DAS_FOTOS = os.path.expanduser("~/.cache/cm_blender")

NOME_DO_MATERIAL = "colormap"
NOME_DO_MATERIAL_DE_BRILHO = "colormap_brilho"
FORCA_DO_BRILHO = 0.55

# A paleta tem 8 colunas por 4 linhas de células de 64 por 128 pixels. A metade esquerda
# de cada célula é a cor chapada; a metade direita é um degradê da mesma cor, mais claro
# em cima. O valor aqui é (coluna, linha), contando do canto de cima à esquerda.
PALETA = {
    # Linha 0: cores vivas, usadas em janela, neon e detalhe.
    "azul": (0, 0),
    "azul_claro": (1, 0),
    "roxo": (2, 0),
    "magenta": (3, 0),
    "rosa": (4, 0),
    # Linha 1: tons quentes.
    "salmao": (0, 1),
    "ferrugem": (1, 1),
    "pessego": (2, 1),
    "creme": (3, 1),
    "verde": (4, 1),
    "amarelo": (5, 1),
    "laranja": (6, 1),
    "coral": (7, 1),
    # Linha 2: os cinzas azulados, a base de tudo que é concreto e metal.
    "cinza": (0, 2),
    "cinza_medio": (1, 2),
    "cinza_escuro": (2, 2),
    "grafite": (3, 2),
    "cinza_metal": (4, 2),
    "chumbo": (5, 2),
    "lavanda": (6, 2),
    "branco": (7, 2),
    # Linha 3: apoio.
    "preto": (0, 3),
    "verde_folha": (1, 3),
    "marrom": (2, 3),
    "cinza_lilas": (3, 3),
    "gelo": (4, 3),
    "azul_palido": (5, 3),
    "indigo": (6, 3),
    "branco_frio": (7, 3),
}

LARGURA_DA_PALETA = 512.0
LARGURA_DA_CELULA = 64.0
ALTURA_DA_CELULA = 128.0


def uv_da_cor(nome, altura_relativa=None):
    """Devolve o ponto da paleta de uma cor.

    Sem `altura_relativa` usa a metade chapada da célula. Com um valor de 0 (base) a 1
    (topo) usa a metade em degradê, que é como os prédios do pacote ganham o tom mais
    escuro perto do chão.
    """
    coluna, linha = PALETA[nome]
    if altura_relativa is None:
        u = (coluna * LARGURA_DA_CELULA + 16.0) / LARGURA_DA_PALETA
        v = (linha * ALTURA_DA_CELULA + 64.0) / LARGURA_DA_PALETA
    else:
        altura_relativa = min(max(altura_relativa, 0.0), 1.0)
        u = (coluna * LARGURA_DA_CELULA + 48.0) / LARGURA_DA_PALETA
        v = (linha * ALTURA_DA_CELULA + 10.0 + (1.0 - altura_relativa) * 108.0) / LARGURA_DA_PALETA
    return (u, 1.0 - v)


def material_da_paleta(com_brilho=False):
    """O material único do pacote. O de brilho usa a mesma paleta também como emissão."""
    nome = NOME_DO_MATERIAL_DE_BRILHO if com_brilho else NOME_DO_MATERIAL
    material = bpy.data.materials.get(nome)
    if material is not None:
        return material
    material = bpy.data.materials.new(nome)
    material.use_nodes = True
    nos = material.node_tree.nodes
    principal = next(no for no in nos if no.type == "BSDF_PRINCIPLED")
    textura = nos.new("ShaderNodeTexImage")
    textura.image = bpy.data.images.load(CAMINHO_DA_PALETA, check_existing=True)
    textura.interpolation = "Closest"
    material.node_tree.links.new(textura.outputs["Color"], principal.inputs["Base Color"])
    principal.inputs["Roughness"].default_value = 1.0
    principal.inputs["Metallic"].default_value = 0.0
    if com_brilho:
        material.node_tree.links.new(textura.outputs["Color"], principal.inputs["Emission Color"])
        principal.inputs["Emission Strength"].default_value = 1.5
    return material


def _matriz(pos, rot, escala=(1.0, 1.0, 1.0)):
    giro = Euler([math.radians(angulo) for angulo in rot], "XYZ").to_matrix().to_4x4()
    tamanho = Matrix.Diagonal((escala[0], escala[1], escala[2], 1.0))
    return Matrix.Translation(Vector(pos)) @ giro @ tamanho


class Modelo:
    """Junta primitivas numa malha só, cada face pintada com uma cor da paleta.

    Toda primitiva recebe `pos` (o centro da base dela), `rot` (graus, em X, Y, Z),
    `cor` (um nome da PALETA), `degrade` (usa o degradê da célula, de baixo para cima) e
    `brilho` (a face vai para o material que emite luz, para neon e LED).
    """

    def __init__(self, nome):
        self.nome = nome
        self.bm = bmesh.new()
        self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.usa_brilho = False

    # -- primitivas ---------------------------------------------------------------

    def caixa(self, tam, pos=(0, 0, 0), cor="cinza", chanfro=0.0, rot=(0, 0, 0),
              degrade=False, brilho=False, cor_do_topo=None):
        """Caixa de tamanho (x, y, z), com a base centrada em `pos`."""
        criado = bmesh.ops.create_cube(self.bm, size=1.0)
        vertices = criado["verts"]
        bmesh.ops.scale(self.bm, vec=Vector(tam), verts=vertices)
        bmesh.ops.translate(self.bm, vec=Vector((0, 0, tam[2] / 2.0)), verts=vertices)
        faces = self._faces_dos_vertices(vertices)
        if chanfro > 0.0:
            arestas = list({aresta for face in faces for aresta in face.edges})
            resultado = bmesh.ops.bevel(self.bm, geom=arestas, offset=chanfro, segments=1,
                                        profile=0.5, affect="EDGES")
            vertices = list({v for face in faces if face.is_valid for v in face.verts}
                            | set(resultado["verts"]))
            faces = self._faces_dos_vertices(vertices)
        self._pintar(faces, cor, degrade, brilho)
        if cor_do_topo is not None:
            topo = [face for face in faces if face.normal.z > 0.9]
            self._pintar(topo, cor_do_topo, False, brilho)
        bmesh.ops.transform(self.bm, matrix=_matriz(pos, rot), verts=vertices)
        return vertices

    def cilindro(self, raio, altura, pos=(0, 0, 0), cor="cinza", lados=10, raio_do_topo=None,
                 rot=(0, 0, 0), degrade=False, brilho=False, cor_das_tampas=None):
        """Cilindro ou tronco de cone em pé, com a base centrada em `pos`.

        Para deitar, use `rot=(90, 0, 0)` (o topo aponta para -Y, a frente do modelo),
        `rot=(-90, 0, 0)` (aponta para +Y) ou `rot=(0, 90, 0)` (aponta para +X).
        """
        if raio_do_topo is None:
            raio_do_topo = raio
        criado = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=lados,
                                       radius1=raio, radius2=max(raio_do_topo, 0.0001), depth=altura)
        vertices = criado["verts"]
        bmesh.ops.translate(self.bm, vec=Vector((0, 0, altura / 2.0)), verts=vertices)
        faces = self._faces_dos_vertices(vertices)
        self._pintar(faces, cor, degrade, brilho)
        if cor_das_tampas is not None:
            tampas = [face for face in faces if abs(face.normal.z) > 0.9]
            self._pintar(tampas, cor_das_tampas, False, brilho)
        bmesh.ops.transform(self.bm, matrix=_matriz(pos, rot), verts=vertices)
        return vertices

    def esfera(self, raio, pos=(0, 0, 0), cor="cinza", subdivisoes=1, escala=(1, 1, 1),
               rot=(0, 0, 0), degrade=False, brilho=False):
        """Icosfera facetada, com o centro (e não a base) em `pos`."""
        criado = bmesh.ops.create_icosphere(self.bm, subdivisions=subdivisoes, radius=raio)
        vertices = criado["verts"]
        faces = self._faces_dos_vertices(vertices)
        self._pintar(faces, cor, degrade, brilho)
        bmesh.ops.transform(self.bm, matrix=_matriz(pos, rot, escala), verts=vertices)
        return vertices

    def prisma(self, pontos, profundidade, pos=(0, 0, 0), cor="cinza", rot=(0, 0, 0),
               degrade=False, brilho=False):
        """Extrusão de um contorno 2D.

        `pontos` é a lista de (x, z) do contorno, em sentido anti-horário visto de
        frente (do lado -Y). A peça fica centrada em Y, com `profundidade` de espessura.
        Serve para rampa, telhado, cunha, seta e qualquer perfil.
        """
        metade = profundidade / 2.0
        frente = [self.bm.verts.new((x, -metade, z)) for (x, z) in pontos]
        fundo = [self.bm.verts.new((x, metade, z)) for (x, z) in pontos]
        faces = [self.bm.faces.new(frente), self.bm.faces.new(list(reversed(fundo)))]
        quantidade = len(pontos)
        for indice in range(quantidade):
            proximo = (indice + 1) % quantidade
            faces.append(self.bm.faces.new((frente[proximo], frente[indice], fundo[indice], fundo[proximo])))
        vertices = frente + fundo
        bmesh.ops.recalc_face_normals(self.bm, faces=faces)
        self._pintar(faces, cor, degrade, brilho)
        bmesh.ops.transform(self.bm, matrix=_matriz(pos, rot), verts=vertices)
        return vertices

    def malha_de(self, objeto, pos=(0, 0, 0), rot=(0, 0, 0), escala=(1, 1, 1), cor=None,
                 brilho=False):
        """Copia a malha de um objeto do Blender para dentro deste modelo.

        É o caminho para editar um modelo de pacote: importa-se o `.glb`, copia-se a
        malha para cá e acrescentam-se peças. Sem `cor`, as UVs originais são mantidas,
        o que só dá certo quando a paleta de origem é a mesma do pacote. Com `cor`, a
        malha inteira é repintada. Com um dicionário em `cor`, cada face é pintada pelo
        nome do material de origem: `{"leafs": "verde", "wood": "marrom", "": "cinza"}`
        (a chave vazia é a cor de quem não casar). É o jeito de trazer um modelo do
        Nature Kit, que não tem textura, para dentro da paleta.
        """
        temporario = bmesh.new()
        temporario.from_mesh(objeto.data)
        uv_de_origem = temporario.loops.layers.uv.active
        mapa = {}
        matriz = _matriz(pos, rot, escala) @ objeto.matrix_world
        for vertice in temporario.verts:
            mapa[vertice.index] = self.bm.verts.new(matriz @ vertice.co)
        faces = []
        materiais_de_origem = []
        for face in temporario.faces:
            try:
                nova = self.bm.faces.new([mapa[v.index] for v in face.verts])
            except ValueError:
                continue
            nova.smooth = face.smooth
            if uv_de_origem is not None:
                for laco_novo, laco_velho in zip(nova.loops, face.loops):
                    laco_novo[self.uv].uv = laco_velho[uv_de_origem].uv
            faces.append(nova)
            materiais_de_origem.append(face.material_index)
        if isinstance(cor, dict):
            for nova, indice_do_material in zip(faces, materiais_de_origem):
                nome = objeto.data.materials[indice_do_material].name.lower()
                escolhida = cor.get("", "cinza")
                for trecho, nome_da_cor in cor.items():
                    if trecho != "" and trecho.lower() in nome:
                        escolhida = nome_da_cor
                self._pintar([nova], escolhida, False, brilho)
        elif cor is not None:
            self._pintar(faces, cor, False, brilho)
        temporario.free()
        return list(mapa.values())

    # -- ajuste -------------------------------------------------------------------

    def mover(self, vertices, pos=(0, 0, 0), rot=(0, 0, 0), escala=(1, 1, 1)):
        """Transforma um grupo de vértices devolvido por uma primitiva."""
        bmesh.ops.transform(self.bm, matrix=_matriz(pos, rot, escala), verts=vertices)

    def repintar(self, vertices, cor, degrade=False, brilho=False):
        self._pintar(self._faces_dos_vertices(vertices), cor, degrade, brilho)

    # -- saída --------------------------------------------------------------------

    def finalizar(self, pai=None, pos=(0, 0, 0), angulo_de_quina=40.0):
        """Cria o objeto na cena. Aresta com ângulo maior que `angulo_de_quina` fica viva.

        Com `pai`, o objeto vira filho dele; é assim que se monta um chefe em partes
        nomeadas, cada uma animada por código no jogo. O `pos` é a posição do pivô.
        """
        self.bm.normal_update()
        malha = bpy.data.meshes.new(self.nome)
        self.bm.to_mesh(malha)
        self.bm.free()
        malha.materials.append(material_da_paleta(False))
        malha.materials.append(material_da_paleta(True))
        for poligono in malha.polygons:
            poligono.use_smooth = True
        malha.set_sharp_from_angle(angle=math.radians(angulo_de_quina))
        objeto = bpy.data.objects.new(self.nome, malha)
        bpy.context.scene.collection.objects.link(objeto)
        objeto.location = Vector(pos)
        if pai is not None:
            objeto.parent = pai
        return objeto

    # -- interno ------------------------------------------------------------------

    def _faces_dos_vertices(self, vertices):
        conjunto = set(vertices)
        faces = set()
        for vertice in vertices:
            if not vertice.is_valid:
                continue
            for face in vertice.link_faces:
                if all(v in conjunto for v in face.verts):
                    faces.add(face)
        return list(faces)

    def _pintar(self, faces, cor, degrade, brilho):
        faces = [face for face in faces if face.is_valid]
        if not faces:
            return
        if brilho:
            self.usa_brilho = True
        minimo = min(v.co.z for face in faces for v in face.verts)
        maximo = max(v.co.z for face in faces for v in face.verts)
        faixa = max(maximo - minimo, 0.0001)
        for face in faces:
            face.material_index = 1 if brilho else 0
            for laco in face.loops:
                if degrade:
                    laco[self.uv].uv = uv_da_cor(cor, (laco.vert.co.z - minimo) / faixa)
                else:
                    laco[self.uv].uv = uv_da_cor(cor)


def vazio(nome, pai=None, pos=(0, 0, 0)):
    """Um nó sem malha, para agrupar as partes de um modelo ou marcar um ponto."""
    objeto = bpy.data.objects.new(nome, None)
    bpy.context.scene.collection.objects.link(objeto)
    objeto.location = Vector(pos)
    objeto.empty_display_size = 0.2
    if pai is not None:
        objeto.parent = pai
    return objeto


def importar_glb(caminho_relativo):
    """Importa um `.glb` de `game/assets/models/` e devolve os objetos de malha."""
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(RAIZ_DO_REPOSITORIO, "game", "assets", "models", caminho_relativo))
    novos = [objeto for objeto in bpy.data.objects if objeto not in antes]
    return novos


def apagar(objetos):
    for objeto in objetos:
        bpy.data.objects.remove(objeto, do_unlink=True)


def limpar_cena():
    """Tira tudo da cena. Use no começo de um script rodado com `blender -b`."""
    for objeto in list(bpy.data.objects):
        bpy.data.objects.remove(objeto, do_unlink=True)
    for malha in list(bpy.data.meshes):
        if malha.users == 0:
            bpy.data.meshes.remove(malha)


def _familia(objeto):
    todos = [objeto]
    for filho in objeto.children:
        todos.extend(_familia(filho))
    return todos


def contar_triangulos(objeto):
    total = 0
    for parte in _familia(objeto):
        if parte.type == "MESH":
            total += sum(len(poligono.vertices) - 2 for poligono in parte.data.polygons)
    return total


def exportar(objeto, nome_do_arquivo):
    """Exporta o objeto (e os filhos) para `cyber_moon_dungeons/<nome>.glb`.

    O `.glb` sai sem imagem embutida e é corrigido em seguida para apontar para
    `textures/colormap.png`, do mesmo jeito que os pacotes da Kenney. Assim todos os
    modelos dividem um arquivo de paleta só.
    """
    os.makedirs(PASTA_DO_PACOTE, exist_ok=True)
    caminho = os.path.join(PASTA_DO_PACOTE, nome_do_arquivo + ".glb")
    posicao_original = objeto.location.copy()
    objeto.location = Vector((0, 0, 0))
    for outro in bpy.context.view_layer.objects:
        outro.select_set(False)
    for parte in _familia(objeto):
        parte.select_set(True)
    bpy.context.view_layer.objects.active = objeto
    bpy.ops.export_scene.gltf(
        filepath=caminho,
        export_format="GLB",
        use_selection=True,
        export_image_format="NONE",
        export_apply=True,
        export_yup=True,
        export_animations=False,
        export_materials="EXPORT",
    )
    objeto.location = posicao_original
    _apontar_para_a_paleta(caminho)
    print("exportado", nome_do_arquivo, contar_triangulos(objeto), "triangulos")
    return caminho


def _apontar_para_a_paleta(caminho):
    """Reescreve o JSON do `.glb` para os materiais usarem a paleta externa."""
    with open(caminho, "rb") as arquivo:
        dados = arquivo.read()
    tamanho_do_json = struct.unpack("<I", dados[12:16])[0]
    documento = json.loads(dados[20:20 + tamanho_do_json])
    resto = dados[20 + tamanho_do_json:]

    documento["images"] = [{"uri": "textures/colormap.png", "name": "colormap"}]
    documento["samplers"] = [{"magFilter": 9728, "minFilter": 9728}]
    documento["textures"] = [{"sampler": 0, "source": 0, "name": "colormap"}]
    for material in documento.get("materials", []):
        pbr = material.setdefault("pbrMetallicRoughness", {})
        pbr.pop("baseColorFactor", None)
        pbr["baseColorTexture"] = {"index": 0}
        pbr["metallicFactor"] = 0.0
        pbr["roughnessFactor"] = 1.0
        if material.get("name", "").startswith(NOME_DO_MATERIAL_DE_BRILHO):
            # Emissão abaixo de 1: a face acesa soma a própria cor com a luz da cena, e
            # com o fator cheio o magenta e o azul estouram para o branco.
            material["emissiveTexture"] = {"index": 0}
            material["emissiveFactor"] = [FORCA_DO_BRILHO, FORCA_DO_BRILHO, FORCA_DO_BRILHO]
            material.pop("extensions", None)
        else:
            material.pop("emissiveFactor", None)
            material.pop("emissiveTexture", None)
            material.pop("extensions", None)

    texto = json.dumps(documento, separators=(",", ":")).encode("utf-8")
    texto += b" " * ((4 - len(texto) % 4) % 4)
    corpo = struct.pack("<I", len(texto)) + b"JSON" + texto + resto
    cabecalho = b"glTF" + struct.pack("<II", 2, 12 + len(corpo))
    with open(caminho, "wb") as arquivo:
        arquivo.write(cabecalho + corpo)


def foto(nome, objetos=None, direcao=(1.0, -1.3, 0.9), resolucao=(1000, 600), margem=1.15):
    """Renderiza uma foto de conferência em `~/.cache/cm_blender/<nome>.png`.

    A câmera é ortográfica e enquadra os objetos dados (ou a cena toda). A direção
    padrão olha de frente, de cima e um pouco de lado, parecido com a câmera do jogo.
    Modelar sem olhar a foto é o erro mais caro: proporção errada só aparece na imagem.
    """
    os.makedirs(PASTA_DAS_FOTOS, exist_ok=True)
    cena = bpy.context.scene
    if objetos is None:
        objetos = [objeto for objeto in cena.objects if objeto.type == "MESH"]
    else:
        completos = []
        for objeto in objetos:
            completos.extend(parte for parte in _familia(objeto) if parte.type == "MESH")
        objetos = completos
    cantos = [objeto.matrix_world @ Vector(canto) for objeto in objetos for canto in objeto.bound_box]
    minimo = Vector([min(canto[eixo] for canto in cantos) for eixo in range(3)])
    maximo = Vector([max(canto[eixo] for canto in cantos) for eixo in range(3)])
    centro = (minimo + maximo) / 2.0
    raio = (maximo - minimo).length / 2.0

    camera = bpy.data.objects.get("CamFoto")
    if camera is None:
        camera = bpy.data.objects.new("CamFoto", bpy.data.cameras.new("CamFoto"))
        cena.collection.objects.link(camera)
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = raio * 2.0 * margem
    camera.data.clip_end = 1000.0
    sentido = Vector(direcao).normalized()
    camera.location = centro + sentido * (raio * 4.0 + 10.0)
    camera.rotation_euler = (-sentido).to_track_quat("-Z", "Y").to_euler()
    cena.camera = camera

    sol = bpy.data.objects.get("SolFoto")
    if sol is None:
        sol = bpy.data.objects.new("SolFoto", bpy.data.lights.new("SolFoto", "SUN"))
        cena.collection.objects.link(sol)
        sol.data.energy = 3.0
    sol.rotation_euler = (math.radians(50), math.radians(10), math.radians(30))

    if cena.world is None:
        cena.world = bpy.data.worlds.new("MundoFoto")
    cena.world.use_nodes = True
    fundo = next((no for no in cena.world.node_tree.nodes if no.type == "BACKGROUND"), None)
    if fundo is not None:
        fundo.inputs[0].default_value = (0.55, 0.57, 0.62, 1.0)
        fundo.inputs[1].default_value = 1.0

    visiveis = set(objetos)
    escondidos = []
    for objeto in cena.objects:
        if objeto.type == "MESH" and objeto not in visiveis and not objeto.hide_render:
            objeto.hide_render = True
            escondidos.append(objeto)

    cena.render.resolution_x, cena.render.resolution_y = resolucao
    cena.render.resolution_percentage = 100
    cena.render.image_settings.file_format = "PNG"
    cena.view_settings.view_transform = "Standard"
    caminho = os.path.join(PASTA_DAS_FOTOS, nome + ".png")
    cena.render.filepath = caminho
    try:
        bpy.ops.render.render(write_still=True)
    finally:
        for objeto in escondidos:
            objeto.hide_render = False
    print("foto", caminho)
    return caminho


def boneco_de_referencia(pos=(0, 0, 0)):
    """Um boneco do tamanho do personagem do jogo (0,66 de altura), só para a foto.

    Nunca é exportado. Colocar um do lado do modelo mostra na hora se a peça ficou
    grande ou pequena demais para o jogador.
    """
    m = Modelo("_referencia")
    m.caixa((0.26, 0.2, 0.3), pos=(0, 0, 0), cor="laranja")
    m.caixa((0.4, 0.36, 0.36), pos=(0, 0, 0.3), cor="pessego")
    return m.finalizar(pos=pos)


def produzir(construtores, nome_do_grupo, espaco=0.6, exportar_modelos=True, fotografar=True):
    """Constrói, enfileira lado a lado, exporta e fotografa um grupo de modelos.

    Cada construtor é uma função sem parâmetros que devolve o objeto raiz do modelo. O
    nome da função é o nome do arquivo `.glb`.
    """
    limpar_cena()
    cursor = 0.0
    feitos = []
    for construtor in construtores:
        objeto = construtor()
        objeto.name = construtor.__name__
        bpy.context.view_layer.update()
        partes = [parte for parte in _familia(objeto) if parte.type == "MESH"]
        cantos = [parte.matrix_world @ Vector(canto) for parte in partes for canto in parte.bound_box]
        minimo = min(canto.x for canto in cantos)
        maximo = max(canto.x for canto in cantos)
        if exportar_modelos:
            exportar(objeto, construtor.__name__)
        # O Blender não aceita dois objetos com o mesmo nome e renomeia o segundo para
        # "Corpo.001", que chega ao Godot como "Corpo_001". Depois de exportar, as
        # partes ganham o nome do modelo na frente e liberam o nome para o próximo.
        for parte in _familia(objeto)[1:]:
            parte.name = construtor.__name__ + "." + parte.name
        objeto.location.x = cursor - minimo
        cursor += (maximo - minimo) + espaco
        feitos.append(objeto)
    boneco_de_referencia(pos=(cursor + 0.2, 0, 0))
    bpy.context.view_layer.update()
    if fotografar:
        foto(nome_do_grupo)
    return feitos
