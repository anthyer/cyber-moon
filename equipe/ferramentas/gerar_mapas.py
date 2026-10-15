#!/usr/bin/env python3
"""Monta as cenas do mapa da fazenda e do mapa mundi (plano 26).

Os dois mapas seguem o mapa de manchas aprovado pelo Antonio (`equipe/mapas/manchas.html`).
A descrição de cada área está aqui embaixo, em coordenadas do próprio mapa: x cresce para
o leste, z para o sul, e a câmera do jogo olha do sul para o norte. O script grava:

    game/scenes/levels/fazenda.tscn
    game/scenes/levels/mundo.tscn

Uso, a partir da raiz do repositório:

    ./equipe/ferramentas/gerar_mapas.py

Depois de gerar, refaça a malha de navegação do mundo e rode este script de novo, para a
cena passar a apontar para a malha:

    godot --headless --path game res://scenes/utils/gerar_malha_de_navegacao.tscn -- res://scenes/levels/mundo.tscn

ATENÇÃO: o script reescreve as duas cenas inteiras. Ajuste feito à mão no editor se perde
na próxima geração. Para mudar um mapa, mude a descrição aqui.

Regras que o script segue, e por quê:

- Coisa alta (viaduto, mesas de pedra, prédios grandes, letreiro) fica no norte ou nas
  laterais. Ao sul, só coisa baixa (reservatório, mureta, cerca).
- Objeto que se repete muito (cacto, pedra, capim, painel solar) vai num
  EspalhadorDeObjetos, que desenha todas as cópias de uma vez.
- Entre os marcos, o chão é areia lisa. É o que deixa o mapa leve.
"""

import math
import random
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1].parent
PASTA_DAS_CENAS = RAIZ / "game" / "scenes" / "levels"
PASTA_DAS_MALHAS = RAIZ / "game" / "resources" / "navigation"

MUNDO_PACOTE = "res://assets/models/cyber_moon_mundo/"
DUNGEON_PACOTE = "res://assets/models/cyber_moon_dungeons/"
KENNEY = "res://assets/models/"
SUBURBANO = KENNEY + "kenney_city_kit_suburban/"
COMERCIAL = KENNEY + "kenney_city_kit_commercial/"
INDUSTRIAL = KENNEY + "kenney_city_kit_industrial/"
NATUREZA = KENNEY + "kenney_nature_kit/"

ESCALA_KENNEY = 4.0

CORES = {
    "areia": (0.85, 0.73, 0.55),
    "terra_batida": (0.73, 0.55, 0.38),
    "asfalto": (0.29, 0.29, 0.35),
    "praca": (0.62, 0.61, 0.68),
    "terra_da_fazenda": (0.5, 0.66, 0.36),
    "talhao": (0.45, 0.31, 0.21),
    "talhao_futuro": (0.6, 0.47, 0.34),
    "agua": (0.26, 0.5, 0.86),
}


def numero(valor):
    return str(round(valor, 4))


def vetor(x, y, z):
    return "Vector3(%s, %s, %s)" % (numero(x), numero(y), numero(z))


def cor(nome):
    r, g, b = CORES[nome]
    return "Color(%s, %s, %s, 1)" % (r, g, b)


class Cena:
    """Acumula recursos externos, sub-recursos e nós de um `.tscn`."""

    def __init__(self):
        self.recursos = {}
        self.linhas_de_recurso = []
        self.subrecursos = []
        self.contagem_de_sub = 0
        self.nos = []
        self.nomes_usados = {}

    def recurso(self, tipo, caminho):
        if caminho not in self.recursos:
            identificador = "r%d" % (len(self.recursos) + 1)
            self.recursos[caminho] = identificador
            self.linhas_de_recurso.append('[ext_resource type="%s" path="%s" id="%s"]' % (tipo, caminho, identificador))
        return 'ExtResource("%s")' % self.recursos[caminho]

    def sub(self, tipo, propriedades, chave=None):
        """Cria um sub-recurso. Com `chave`, reaproveita o que já foi criado com ela."""
        if chave is not None:
            for existente_chave, identificador in getattr(self, "_por_chave", {}).items():
                if existente_chave == chave:
                    return 'SubResource("%s")' % identificador
        self.contagem_de_sub += 1
        identificador = "s%d" % self.contagem_de_sub
        linhas = ['[sub_resource type="%s" id="%s"]' % (tipo, identificador)]
        for nome, valor in propriedades.items():
            linhas.append("%s = %s" % (nome, valor))
        self.subrecursos.append("\n".join(linhas))
        if chave is not None:
            if not hasattr(self, "_por_chave"):
                self._por_chave = {}
            self._por_chave[chave] = identificador
        return 'SubResource("%s")' % identificador

    def material(self, nome, sem_sombra=False):
        return self.sub("StandardMaterial3D", {"albedo_color": cor(nome), "roughness": "1.0"}, chave="material_" + nome)

    def no(self, nome, tipo=None, pai=".", instancia=None, propriedades=None, grupos=None):
        if pai is not None:
            chave = (pai, nome)
            self.nomes_usados[chave] = self.nomes_usados.get(chave, 0) + 1
            if self.nomes_usados[chave] > 1:
                nome = "%s%d" % (nome, self.nomes_usados[chave])
        cabecalho = '[node name="%s"' % nome
        if tipo is not None:
            cabecalho += ' type="%s"' % tipo
        if pai is not None:
            cabecalho += ' parent="%s"' % pai
        if instancia is not None:
            cabecalho += " instance=%s" % self.recurso("PackedScene", instancia)
        if grupos:
            cabecalho += " groups=[%s]" % ", ".join('"%s"' % g for g in grupos)
        cabecalho += "]"
        linhas = [cabecalho]
        for chave, valor in (propriedades or {}).items():
            linhas.append("%s = %s" % (chave, valor))
        self.nos.append("\n".join(linhas))
        if pai is None:
            return "."
        return nome if pai == "." else pai + "/" + nome

    def texto(self):
        partes = ["[gd_scene format=3]", "\n".join(self.linhas_de_recurso)]
        if self.subrecursos:
            partes.append("\n\n".join(self.subrecursos))
        partes.append("\n\n".join(self.nos))
        return "\n\n".join(partes) + "\n"


class Montador:
    """Os tijolos dos dois mapas: peça, chão, faixa de estrada, espalhador, parede."""

    def __init__(self, cena):
        self.c = cena

    def peca(self, nome, modelo, x, z, graus=0.0, escala=None, pai=".", y=0.0, cobre=False, gira=False):
        propriedades = {"position": vetor(x, y, z)}
        if graus:
            propriedades["rotation"] = vetor(0, math.radians(graus), 0)
        if escala is not None:
            propriedades["scale"] = vetor(escala, escala, escala)
        caminho = self.c.no(nome, pai=pai, instancia=modelo, propriedades=propriedades)
        if cobre:
            self.c.no("Cobertura", "Node", pai=caminho, propriedades={
                "script": self.c.recurso("Script", "res://scripts/world/cobertura_translucida.gd")})
        if gira:
            self.c.no("MaquinaAnimada", "Node", pai=caminho, propriedades={
                "script": self.c.recurso("Script", "res://scripts/combat/maquina_animada.gd"),
                "voltas_por_segundo": "0.25"})
        return caminho

    def chao(self, nome, cx, cz, largura, profundidade, nome_da_cor, pai=".", y=0.0):
        """Um plano de cor chapada, sem colisão (o chão de colisão é o plano da fase)."""
        malha = self.c.sub("PlaneMesh", {"material": self.c.material(nome_da_cor),
                                         "size": "Vector2(%s, %s)" % (numero(largura), numero(profundidade))})
        return self.c.no(nome, "MeshInstance3D", pai=pai, propriedades={
            "position": vetor(cx, y, cz), "mesh": malha, "cast_shadow": "0"})

    def faixa(self, nome, pontos, largura, nome_da_cor, pai=".", y=0.012):
        """Uma estrada como sequência de trechos retos entre os pontos dados."""
        for (x1, z1), (x2, z2) in zip(pontos, pontos[1:]):
            dx, dz = x2 - x1, z2 - z1
            comprimento = math.hypot(dx, dz) + largura * 0.5
            malha = self.c.sub("PlaneMesh", {"material": self.c.material(nome_da_cor),
                                             "size": "Vector2(%s, %s)" % (numero(comprimento), numero(largura))})
            self.c.no(nome, "MeshInstance3D", pai=pai, propriedades={
                "position": vetor((x1 + x2) / 2, y, (z1 + z2) / 2),
                "rotation": vetor(0, -math.atan2(dz, dx), 0),
                "mesh": malha, "cast_shadow": "0"})

    def espalhador(self, nome, modelo, cx, cz, largura, profundidade, quantidade, semente, distancia=1.5,
                   raio=0.0, altura=1.5, livres=(), escala=(0.85, 1.2), sombra=True, some=0.0, pai="."):
        """Cópias de um modelo numa área. `livres` são retângulos (x, z, largura, profundidade)
        em coordenadas do mapa onde nada é posto."""
        retangulos = []
        for (x, z, w, d) in livres:
            # Só entra o que encosta na área deste espalhador.
            if x + w < cx - largura / 2 or x > cx + largura / 2 or z + d < cz - profundidade / 2 or z > cz + profundidade / 2:
                continue
            retangulos.append("Rect2(%s, %s, %s, %s)" % (numero(x - cx), numero(z - cz), numero(w), numero(d)))
        propriedades = {
            "position": vetor(cx, 0, cz),
            "script": self.c.recurso("Script", "res://scripts/world/espalhador_de_objetos.gd"),
            "modelo": self.c.recurso("PackedScene", modelo),
            "quantidade": str(quantidade),
            "tamanho_da_area": "Vector2(%s, %s)" % (numero(largura), numero(profundidade)),
            "semente": str(semente),
            "escala_minima": numero(escala[0]),
            "escala_maxima": numero(escala[1]),
            "distancia_minima": numero(distancia),
            "areas_livres": "Array[Rect2]([%s])" % ", ".join(retangulos),
            "raio_da_colisao": numero(raio),
            "altura_da_colisao": numero(altura),
            "projeta_sombra": "true" if sombra else "false",
            "some_a_partir_de": numero(some),
        }
        return self.c.no(nome, "Node3D", pai=pai, propriedades=propriedades)

    def parede(self, nome, cx, cz, largura, profundidade, pai="."):
        """Parede invisível na borda do mapa, para o jogador não sair andando para o nada."""
        forma = self.c.sub("BoxShape3D", {"size": vetor(largura, 3.0, profundidade)})
        corpo = self.c.no(nome, "StaticBody3D", pai=pai, propriedades={
            "position": vetor(cx, 1.5, cz), "collision_mask": "0"})
        self.c.no("Forma", "CollisionShape3D", pai=corpo, propriedades={"shape": forma})

    def agua(self, nome, x1, z1, x2, z2, pai=".", y=0.025):
        """Um plano de água com o shader toon, de (x1, z1) a (x2, z2).

        O plano tem 1 por 1 e é esticado pela escala do nó, que é como o shader sabe o
        tamanho em metros para desenhar a espuma da beira.
        """
        if not hasattr(self, "_malha_da_agua"):
            material = self.c.sub("ShaderMaterial", {
                "shader": self.c.recurso("Shader", "res://assets/shaders/agua_toon.gdshader")})
            self._malha_da_agua = self.c.sub("PlaneMesh", {"material": material, "size": "Vector2(1, 1)"})
        return self.c.no(nome, "MeshInstance3D", pai=pai, propriedades={
            "position": vetor((x1 + x2) / 2, y, (z1 + z2) / 2),
            "scale": vetor(x2 - x1, 1, z2 - z1),
            "mesh": self._malha_da_agua, "cast_shadow": "0"})

    def bloqueio(self, nome, x1, z1, x2, z2, pai="."):
        """Parede invisível em cima da água, de (x1, z1) a (x2, z2). A borda baixa de
        concreto sozinha não segura: a cápsula do personagem sobe nela."""
        self.parede(nome, (x1 + x2) / 2, (z1 + z2) / 2, x2 - x1, z2 - z1, pai=pai)

    def marcador(self, nome, x, z, graus=0.0, pai="."):
        propriedades = {"position": vetor(x, 0, z)}
        if graus:
            propriedades["rotation"] = vetor(0, math.radians(graus), 0)
        return self.c.no(nome, "Marker3D", pai=pai, propriedades=propriedades)

    def luz(self, nome, x, y, z, rgb, alcance=9.0, energia=1.2, pai="."):
        return self.c.no(nome, "OmniLight3D", pai=pai, propriedades={
            "position": vetor(x, y, z), "light_color": "Color(%s, %s, %s, 1)" % rgb,
            "light_energy": numero(energia), "omni_range": numero(alcance), "shadow_enabled": "false"})

    def passagem(self, nome, x, z, largura, profundidade, mapa, chegada, pai="."):
        forma = self.c.sub("BoxShape3D", {"size": vetor(largura, 3.0, profundidade)})
        area = self.c.no(nome, "Area3D", pai=pai, propriedades={
            "position": vetor(x, 1.5, z),
            "script": self.c.recurso("Script", "res://scripts/world/passagem_de_mapa.gd"),
            "mapa_de_destino": '&"%s"' % mapa, "chegada": '&"%s"' % chegada})
        self.c.no("Forma", "CollisionShape3D", pai=area, propriedades={"shape": forma})


def raiz_do_mapa(cena, nome, mapa_id, nome_exibido):
    cena.no(nome, "Node3D", pai=None, propriedades={
        "script": cena.recurso("Script", "res://scripts/world/mapa.gd"),
        "id": '&"%s"' % mapa_id, "nome_exibido": '"%s"' % nome_exibido})


# -- fazenda ------------------------------------------------------------------------------

LARGURA_DA_FAZENDA = 50.0
PROFUNDIDADE_DA_FAZENDA = 40.0

# (x, z, largura, profundidade, liberado), em células de 1 por 1, canto noroeste.
TALHOES = [
    (6, 18, 11, 8, True),
    (20, 18, 11, 8, True),
    (34, 18, 10, 8, True),
    (6, 29, 11, 7, False),
    (20, 29, 11, 7, False),
    (34, 29, 10, 7, False),
]


def montar_fazenda():
    c = Cena()
    m = Montador(c)
    raiz_do_mapa(c, "Fazenda", "fazenda", "Fazenda")
    material_da_terra = c.material("terra_da_fazenda")

    c.no("Chao", "Node3D")
    m.chao("Areia", 25, 20, 130, 110, "areia", pai="Chao", y=-0.01)
    malha = c.sub("PlaneMesh", {"material": material_da_terra, "size": "Vector2(50, 40)"})
    c.no("Terra", "MeshInstance3D", pai="Chao", propriedades={"position": vetor(25, 0, 20), "mesh": malha, "cast_shadow": "0"})
    m.chao("Patio", 25, 13, 42, 4, "terra_batida", pai="Chao", y=0.008)
    m.faixa("Caminho", [(44, 15), (48, 22), (56, 22)], 3.0, "terra_batida", pai="Chao")
    c.no("GramaDaEstacao", "Node", propriedades={
        "script": c.recurso("Script", "res://scripts/world/grama_da_estacao.gd"),
        "material_da_grama": material_da_terra})

    c.no("Construcoes", "Node3D")
    m.peca("Casa", MUNDO_PACOTE + "casa_da_fazenda.glb", 24, 6, pai="Construcoes")
    m.peca("Galpao", MUNDO_PACOTE + "galpao_da_fazenda.glb", 37, 6.5, pai="Construcoes")
    m.peca("CaixaDagua", MUNDO_PACOTE + "caixa_dagua_da_fazenda.glb", 10, 5, pai="Construcoes")
    m.peca("Espantalho", MUNDO_PACOTE + "espantalho_robo.glb", 32.5, 22, graus=-15, pai="Construcoes")
    m.peca("Porteira", MUNDO_PACOTE + "porteira_da_fazenda.glb", 50, 22, graus=90, pai="Construcoes")
    m.peca("CaixaDeCorreio", MUNDO_PACOTE + "caixa_de_correio.glb", 47.5, 25.5, pai="Construcoes")

    # A cerca em volta, com o vão da porteira no leste (z de 20 a 24).
    for x in range(2, 50, 4):
        m.peca("Cerca", MUNDO_PACOTE + "cerca_de_arame.glb", x, 0, pai="Construcoes")
        m.peca("Cerca", MUNDO_PACOTE + "cerca_de_arame.glb", x, 40, pai="Construcoes")
    for z in range(2, 40, 4):
        m.peca("Cerca", MUNDO_PACOTE + "cerca_de_arame.glb", 0, z, graus=90, pai="Construcoes")
        if not 18 <= z <= 26:
            m.peca("Cerca", MUNDO_PACOTE + "cerca_de_arame.glb", 50, z, graus=90, pai="Construcoes")

    # Os talhões: o nó de regra, o chão de terra e a borda de tábua.
    c.no("Talhoes", "Node3D")
    for indice, (x, z, largura, profundidade, liberado) in enumerate(TALHOES):
        talhao = c.no("Talhao%d" % (indice + 1), "Node3D", pai="Talhoes", propriedades={
            "position": vetor(x, 0, z),
            "script": c.recurso("Script", "res://scripts/farming/talhao_de_cultivo.gd"),
            "tamanho_em_celulas": "Vector2i(%d, %d)" % (largura, profundidade),
            "liberado": "true" if liberado else "false"})
        m.chao("Terra", largura / 2, profundidade / 2, largura, profundidade,
               "talhao" if liberado else "talhao_futuro", pai=talhao, y=0.01)
        for passo in range(0, largura, 2):
            for borda_z in (-0.1, profundidade + 0.1):
                m.peca("Borda", MUNDO_PACOTE + "enfeite_borda_de_talhao.glb", passo + 1, borda_z, pai=talhao)
        for passo in range(0, profundidade, 2):
            for borda_x in (-0.1, largura + 0.1):
                m.peca("Borda", MUNDO_PACOTE + "enfeite_borda_de_talhao.glb", borda_x, passo + 1, graus=90, pai=talhao)

    # O que o jogador usa na fazenda. Os nomes são os de antes do plano 26, porque o save
    # de alguns deles (os baús) usa o nome do nó.
    c.no("GradeSolo", "GridMap", propriedades={
        "position": vetor(0, 0.07, 0),
        "mesh_library": c.recurso("MeshLibrary", "res://resources/farming/mesh_library_solo.tres"),
        "cell_size": "Vector3(1, 0.1, 1)",
        "script": c.recurso("Script", "res://scripts/farming/grade_solo.gd")})
    malha_do_indicador = c.sub("PlaneMesh", {
        "material": c.sub("StandardMaterial3D", {"transparency": "1", "albedo_color": "Color(1, 1, 0, 0.5)"}),
        "size": "Vector2(1, 1)"})
    c.no("IndicadorAlvo", "MeshInstance3D", propriedades={
        "position": vetor(0, 0.13, 0), "visible": "false", "mesh": malha_do_indicador})
    m.marcador("PontoDeSpawn", 24, 10.5)
    m.peca("Cama", "res://scenes/world/cama.tscn", 19.5, 9.2)
    m.peca("QuadroCalendario", "res://scenes/world/quadro_calendario.tscn", 28.8, 9.4)
    m.peca("BauDeGuardar", "res://scenes/items/bau.tscn", 35.4, 9.2)
    m.peca("BauDeVenda", "res://scenes/items/bau.tscn", 38.6, 9.2)
    c.nos[-1] += "\nfuncao = 1"
    m.luz("LuzDaVaranda", 24, 2.6, 9.0, (1.0, 0.8, 0.5), alcance=7.0, energia=0.8)

    # A passagem para o mundo, do lado de fora da porteira.
    m.marcador("ChegadaDaPorteira", 46, 22, graus=-90)
    m.passagem("PassagemParaOMundo", 53, 22, 2.0, 5.0, "mundo", "ChegadaDaFazenda")

    # Bordas: o mapa da fazenda acaba na cerca. A parede do leste tem o vão da porteira, e
    # atrás da passagem fica outra parede, se a troca de mapa falhar.
    c.no("Limites", "Node3D")
    m.parede("Norte", 25, -0.6, 52, 1, pai="Limites")
    m.parede("Sul", 25, 40.6, 52, 1, pai="Limites")
    m.parede("Oeste", -0.6, 20, 1, 42, pai="Limites")
    m.parede("LesteDeCima", 50.6, 9.75, 1, 20.5, pai="Limites")
    m.parede("LesteDeBaixo", 50.6, 32.25, 1, 16.5, pai="Limites")
    m.parede("AtrasDaPassagem", 55.5, 22, 1, 8, pai="Limites")
    m.parede("LadoDaPassagemNorte", 53, 19.2, 5, 1, pai="Limites")
    m.parede("LadoDaPassagemSul", 53, 24.8, 5, 1, pai="Limites")

    # O verde: a fazenda é um oásis no meio do deserto. Palmeiras atrás da casa (o norte
    # pode ser alto), o pomar na cerca do sul com cobertura translúcida, o laguinho no
    # canto oeste, grama, flores e arbustos onde não se planta nem se anda muito.
    c.no("Verde", "Node3D")
    for x in (3, 15, 30.5, 45):
        m.peca("Palmeira", MUNDO_PACOTE + "palmeira.glb", x, 2.4, graus=x * 37, pai="Verde")
    for x in (47.5,):
        for z in (17.5, 27):
            m.peca("Palmeira", MUNDO_PACOTE + "palmeira.glb", x, z, graus=z * 53, pai="Verde", cobre=True)
    for x in (4, 11, 18, 25, 32, 39, 46):
        m.peca("ArvoreFrutifera", MUNDO_PACOTE + "arvore_frutifera.glb", x, 38.3, graus=x * 29, pai="Verde", cobre=True)
    for x, z in ((1.6, 17), (1.6, 27), (1.6, 33), (48.6, 33), (48.6, 37)):
        m.peca("CercaViva", MUNDO_PACOTE + "cerca_viva.glb", x, z, graus=90, pai="Verde")
    m.agua("Laguinho", 1.0, 11.0, 4.6, 15.4, pai="Verde")
    m.bloqueio("BloqueioDoLaguinho", 1.0, 11.0, 4.6, 15.4, pai="Verde")
    for x, z in ((0.8, 10.6), (4.9, 11.2), (5.0, 15.0), (2.4, 15.8), (0.7, 15.6)):
        m.peca("Juncos", MUNDO_PACOTE + "enfeite_juncos.glb", x, z, graus=x * 80, pai="Verde")
    for x, z in ((5.3, 13.0), (3.8, 16.4)):
        m.peca("Pedras", MUNDO_PACOTE + "pedras_do_deserto.glb", x, z, escala=0.7, pai="Verde")
    livres_da_fazenda = [(x - 0.6, z - 0.6, w + 1.2, d + 1.2) for (x, z, w, d, _l) in TALHOES] + [
        (15, 1, 18, 10.5), (31, 2, 11, 10), (6, 1, 8, 8), (3, 11, 44, 4.5), (0.5, 10.5, 4.8, 5.5),
        (43, 14, 8, 11), (31.5, 20.5, 2.2, 3)]
    m.espalhador("Grama", MUNDO_PACOTE + "enfeite_tufo_de_grama.glb", 25, 20, 49, 39, 170, 31, distancia=1.0,
                 sombra=False, livres=livres_da_fazenda, escala=(0.9, 1.5), pai="Verde")
    m.espalhador("Flores", MUNDO_PACOTE + "enfeite_flores.glb", 25, 20, 49, 39, 40, 32, distancia=1.6,
                 sombra=False, livres=livres_da_fazenda, pai="Verde")
    m.espalhador("Arbustos", MUNDO_PACOTE + "arbusto_do_oasis.glb", 25, 20, 49, 39, 16, 33, distancia=4.0,
                 raio=0.45, altura=0.8, livres=livres_da_fazenda, escala=(0.8, 1.2), pai="Verde")
    for x, z in ((8, 9.5), (11, 9.2), (39.5, 11.4), (12.6, 16.4), (29.8, 16.4)):
        m.peca("FloresDoCanteiro", MUNDO_PACOTE + "enfeite_flores.glb", x, z, graus=x * 41, pai="Verde")

    # As coisas de uso, perto da casa e do galpão.
    c.no("Utensilios", "Node3D")
    m.peca("Varal", MUNDO_PACOTE + "varal.glb", 13.5, 9.6, pai="Utensilios")
    m.peca("Bancada", MUNDO_PACOTE + "bancada_de_ferramentas.glb", 42.2, 6.5, graus=-90, pai="Utensilios")
    m.peca("Feno", MUNDO_PACOTE + "fardo_de_feno.glb", 41.8, 10.4, graus=10, pai="Utensilios")
    m.peca("Feno", MUNDO_PACOTE + "fardo_de_feno.glb", 42.4, 11.2, graus=-15, pai="Utensilios")
    m.peca("Feno", MUNDO_PACOTE + "fardo_de_feno.glb", 42.0, 10.75, graus=80, y=0.5, pai="Utensilios")
    m.peca("CarrinhoDeMao", MUNDO_PACOTE + "carrinho_de_mao.glb", 18.4, 16.6, graus=70, pai="Utensilios")
    m.peca("Barril", DUNGEON_PACOTE + "barril.glb", 11.6, 6.5, pai="Utensilios")

    # O deserto do lado de fora da cerca, só para a borda não ser um corte seco.
    c.no("Deserto", "Node3D")
    m.espalhador("CactosDoNorte", MUNDO_PACOTE + "cacto_redondo.glb", 25, -8, 60, 12, 14, 21, distancia=3.0, pai="Deserto")
    m.espalhador("CactosDoOeste", MUNDO_PACOTE + "cacto_alto.glb", -9, 20, 12, 44, 6, 22, distancia=5.0, pai="Deserto")
    m.espalhador("CapimDeFora", MUNDO_PACOTE + "enfeite_capim_seco.glb", 25, 47, 60, 10, 30, 23, distancia=1.2,
                 sombra=False, pai="Deserto")
    m.espalhador("CapimDeDentro", MUNDO_PACOTE + "enfeite_capim_seco.glb", 25, 38, 46, 3, 12, 24, distancia=1.5,
                 sombra=False, pai="Deserto")
    return c.texto()


# -- mundo -----------------------------------------------------------------------------------

LARGURA_DO_MUNDO = 160.0
PROFUNDIDADE_DO_MUNDO = 110.0
X_DO_CANAL = 90.0
Z_DO_VIADUTO = 7.0

# Áreas onde o deserto espalhado não entra: estradas, vila, canal, reservatório, campos.
LIVRES = [
    (0, 9, 160, 6),        # estrada debaixo do viaduto
    (77, 13, 6, 30),       # avenida que desce do viaduto para a vila
    (54, 34, 52, 48),      # vila
    (86, 13, 8, 82),       # canal
    (48, 88, 52, 22),      # reservatório
    (8, 30, 42, 44),       # fazendas solares
    (0, 17, 34, 12),       # porteira da fazenda e o caminho
    (118, 62, 42, 36),     # acampamento das motoqueiras
    (94, 20, 50, 8),       # estrada das Badlands
]


def montar_mundo():
    c = Cena()
    m = Montador(c)
    raiz_do_mapa(c, "Mundo", "mundo", "Arredores da vila")
    sorteio = random.Random(26)

    # -- chão e estradas
    c.no("Chao", "Node3D")
    m.chao("Areia", 80, 50, 230, 150, "areia", pai="Chao", y=-0.01)
    m.espalhador("ManchasDeTerra", MUNDO_PACOTE + "enfeite_mancha_de_terra.glb", 80, 60, 150, 90, 26, 1,
                 distancia=10.0, sombra=False, escala=(1.0, 2.2), livres=LIVRES, pai="Chao")
    m.espalhador("ManchasDeAreia", MUNDO_PACOTE + "enfeite_mancha_de_areia.glb", 80, 60, 150, 90, 20, 2,
                 distancia=10.0, sombra=False, escala=(1.0, 2.0), livres=LIVRES, pai="Chao")
    c.no("Estradas", "Node3D")
    m.faixa("Pista", [(2, 12), (158, 12)], 5.0, "asfalto", pai="Estradas")
    m.faixa("Avenida", [(80, 12), (80, 46)], 4.0, "asfalto", pai="Estradas")
    m.faixa("CaminhoDaFazenda", [(3, 22), (30, 28), (55, 52), (62, 55)], 3.0, "terra_batida", pai="Estradas")
    m.faixa("CaminhoDoSolar", [(30, 28), (30, 70)], 2.5, "terra_batida", pai="Estradas")
    m.faixa("CaminhoDoLeste", [(84, 56), (104, 56), (128, 76), (136, 80)], 3.0, "terra_batida", pai="Estradas")
    m.faixa("CaminhoDasBadlands", [(80, 24), (100, 24), (122, 30), (138, 32)], 3.0, "terra_batida", pai="Estradas")
    m.faixa("CaminhoDoReservatorio", [(70, 64), (70, 90)], 2.5, "terra_batida", pai="Estradas")
    m.faixa("CaminhoDasCasas", [(96, 46), (96, 78)], 2.0, "terra_batida", pai="Estradas")
    m.faixa("CaminhoDoSul", [(60, 72), (82, 72)], 2.0, "terra_batida", pai="Estradas")

    for x, z, graus in ((32, 31.5, 30), (101, 26.2, 0), (105, 58.5, -40), (71.6, 66, 90)):
        m.peca("Placa", MUNDO_PACOTE + "placa_de_estrada.glb", x, z, graus=graus, pai="Estradas")

    # -- viaduto e cidade ao fundo (o norte pode ser alto)
    c.no("Viaduto", "Node3D")
    for x in range(4, 160, 8):
        m.peca("Modulo", MUNDO_PACOTE + "viaduto_modulo.glb", x, Z_DO_VIADUTO, pai="Viaduto")
    for indice, x in enumerate(range(6, 158, 13)):
        escala = 1.6 + sorteio.random() * 1.2
        m.peca("Predio", DUNGEON_PACOTE + "predio_de_fundo.glb", x + sorteio.uniform(-2, 2), -7 - sorteio.random() * 4,
               escala=escala, pai="Viaduto")
    m.peca("PontoDeOnibus", MUNDO_PACOTE + "ponto_de_onibus.glb", 74, 15.2, pai="Viaduto")
    for x in (40, 118):
        m.peca("Outdoor", MUNDO_PACOTE + "outdoor_neon.glb", x, 15.5, pai="Viaduto")
    for x in range(10, 156, 18):
        m.peca("Poste", MUNDO_PACOTE + "poste_de_luz.glb", x, 15.0, pai="Viaduto")
    m.luz("LuzDoPonto", 74, 2.6, 16.5, (0.45, 0.7, 1.0), pai="Viaduto")

    # -- entradas das dungeons (a Galeria aberta desde o primeiro dia)
    c.no("Entradas", "Node3D")
    entradas = (
        ("Galeria", "galeria", "entrada_da_galeria", 100, 17.5, (1.0, 0.8, 0.35)),
        ("Torre", "torre", "entrada_da_torre", 130, 16.5, (0.95, 0.45, 0.95)),
        ("Biodomo", "biodomo", "entrada_do_biodomo", 25, 50, (0.5, 1.0, 0.6)),
    )
    for nome, dungeon_id, modelo, x, z, rgb in entradas:
        grupo = c.no(nome, "Node3D", pai="Entradas", propriedades={"position": vetor(x, 0, z)})
        m.peca("Modelo", MUNDO_PACOTE + modelo + ".glb", 0, 0, pai=grupo)
        entrada = m.peca("Acesso", "res://scenes/world/entrada_de_dungeon.tscn", 0, 2.4 if nome != "Biodomo" else 2.9, pai=grupo)
        c.nos[-1] += '\ndungeon_id = &"%s"' % dungeon_id
        m.luz("Luz", 0, 2.2, 1.8, rgb, alcance=7.0, pai=grupo)

    # -- canal da corporação, de norte a sul
    c.no("Canal", "Node3D")
    pontes = {24: "ponte", 56: "ponte"}
    comportas = {36: "comporta", 72: "comporta"}
    for z in range(16, 92, 4):
        if z in pontes:
            m.peca("Ponte", MUNDO_PACOTE + "canal_ponte.glb", X_DO_CANAL, z, pai="Canal")
        elif z in comportas:
            m.peca("Comporta", MUNDO_PACOTE + "canal_comporta.glb", X_DO_CANAL, z, pai="Canal")
        else:
            m.peca("Trecho", MUNDO_PACOTE + "canal_reto.glb", X_DO_CANAL, z, pai="Canal")
    m.peca("CabecaDoCanal", MUNDO_PACOTE + "casa_de_bombas.glb", X_DO_CANAL, 13.6, graus=180, pai="Canal")
    # A água do canal é um plano só, de ponta a ponta, e passa debaixo das pontes. O
    # bloqueio fica só entre as pontes: em cima delas o jogador atravessa.
    m.agua("Agua", X_DO_CANAL - 1.3, 14.0, X_DO_CANAL + 1.3, 92.0, pai="Canal")
    for z1, z2 in ((14.0, 22.0), (26.0, 54.0), (58.0, 92.0)):
        m.bloqueio("Bloqueio", X_DO_CANAL - 1.3, z1, X_DO_CANAL + 1.3, z2, pai="Canal")

    # -- reservatório, na borda sul (plano, não cobre nada)
    c.no("Reservatorio", "Node3D")
    m.agua("Agua", 52.0, 92.0, 96.0, 106.0, pai="Reservatorio")
    # O píer (x de 61 a 63, até z = 99,6) fica fora do bloqueio.
    m.bloqueio("Bloqueio", 52.0, 92.0, 61.0, 106.0, pai="Reservatorio")
    m.bloqueio("Bloqueio", 63.0, 92.0, 96.0, 106.0, pai="Reservatorio")
    m.bloqueio("Bloqueio", 61.0, 99.8, 63.0, 106.0, pai="Reservatorio")
    m.peca("Barco", MUNDO_PACOTE + "barco_velho.glb", 64.6, 95.5, graus=8, pai="Reservatorio")
    # O oásis em volta da água: palmeiras, juncos e grama.
    for x, z in ((53.5, 89), (57.5, 88.5), (79, 89), (83.5, 88.6), (99, 96), (99.5, 102.5), (49, 96.5), (48.5, 103)):
        m.peca("Palmeira", MUNDO_PACOTE + "palmeira.glb", x, z, graus=x * 31, pai="Reservatorio", cobre=True)
    m.espalhador("Juncos", MUNDO_PACOTE + "enfeite_juncos.glb", 74, 90, 42, 2.4, 22, 41, distancia=1.2, sombra=False,
                 livres=[(60, 88, 4, 4), (68.5, 86, 3, 6), (88, 86, 4, 6)], pai="Reservatorio")
    m.espalhador("Grama", MUNDO_PACOTE + "enfeite_tufo_de_grama.glb", 74, 87.5, 50, 4, 40, 42, distancia=1.0,
                 sombra=False, livres=[(68.5, 84, 3, 8), (88, 84, 4, 8)], pai="Reservatorio")
    m.espalhador("Arbustos", MUNDO_PACOTE + "arbusto_do_oasis.glb", 74, 87, 52, 3, 8, 43, distancia=4.0,
                 raio=0.45, altura=0.8, livres=[(60, 84, 4, 8), (68.5, 84, 3, 8), (88, 84, 4, 8)], pai="Reservatorio")
    for x in range(54, 96, 4):
        if x in (62, 90):
            continue
        m.peca("BordaNorte", MUNDO_PACOTE + "reservatorio_borda.glb", x, 91.75, graus=180, pai="Reservatorio")
        m.peca("BordaSul", MUNDO_PACOTE + "reservatorio_borda.glb", x, 106.25, pai="Reservatorio")
    for x in (62, 90):
        m.peca("BordaSul", MUNDO_PACOTE + "reservatorio_borda.glb", x, 106.25, pai="Reservatorio")
    for z in range(94, 106, 4):
        m.peca("BordaOeste", MUNDO_PACOTE + "reservatorio_borda.glb", 51.75, z, graus=-90, pai="Reservatorio")
        m.peca("BordaLeste", MUNDO_PACOTE + "reservatorio_borda.glb", 96.25, z, graus=90, pai="Reservatorio")
    for x, z in ((51.75, 91.75), (96.25, 91.75), (51.75, 106.25), (96.25, 106.25)):
        m.peca("Quina", MUNDO_PACOTE + "reservatorio_quina.glb", x, z, pai="Reservatorio")
    m.peca("Pier", MUNDO_PACOTE + "pier_de_madeira.glb", 62, 91.5, graus=180, pai="Reservatorio")
    m.peca("CasaDeBombas", MUNDO_PACOTE + "casa_de_bombas.glb", 100, 89, graus=-90, pai="Reservatorio")

    # -- vila
    c.no("Vila", "Node3D")
    m.chao("Praca", 73, 56, 18, 13, "praca", pai="Vila", y=0.006)
    m.peca("Letreiro", MUNDO_PACOTE + "letreiro_da_vila.glb", 73, 47.5, pai="Vila")
    m.peca("Poco", MUNDO_PACOTE + "bomba_solar.glb", 73, 57, pai="Vila")
    for x, z in ((64.5, 50), (81.5, 50), (64.5, 62), (81.5, 62)):
        m.peca("Poste", MUNDO_PACOTE + "poste_de_luz.glb", x, z, pai="Vila")
    m.luz("LuzDaPraca", 73, 5.0, 49, (0.95, 0.45, 0.95), alcance=12.0, pai="Vila")
    # Lado norte da praça, de frente para o sul: o bar e o mercado. A avenida do viaduto
    # chega entre o mercado e o canal.
    m.peca("Bar", MUNDO_PACOTE + "bar_de_beira_de_estrada.glb", 59, 43, pai="Vila")
    m.luz("LuzDoBar", 59, 3.0, 46, (0.95, 0.45, 0.95), alcance=7.0, pai="Vila")
    m.peca("Mercado", COMERCIAL + "building_c.glb", 68, 41.5, escala=ESCALA_KENNEY, pai="Vila")
    m.peca("OficinaDoVitor", INDUSTRIAL + "building_b.glb", 102, 74, graus=-90, escala=ESCALA_KENNEY, pai="Vila")
    m.peca("Clinica", COMERCIAL + "building_e.glb", 58, 55, graus=90, escala=ESCALA_KENNEY, pai="Vila")
    # Casas: duas a oeste, duas ao sul (baixas, viradas para o norte), a geminada do Kenji e do
    # Rafa e a do Vitor do outro lado do canal.
    casas = (
        ("CasaDaMarta", "building_type_c", 58, 64, 90),
        ("CasaDaIara", "building_type_f", 64, 75, 180),
        ("CasaDaSol", "building_type_h", 76, 75, 180),
        ("CasaDoKenji", "building_type_k", 100, 46, -90),
        ("CasaDoRafa", "building_type_l", 100, 51, -90),
        ("CasaDoVitor", "building_type_b", 100, 63, -90),
    )
    for nome, modelo, x, z, graus in casas:
        m.peca(nome, SUBURBANO + modelo + ".glb", x, z, graus=graus, escala=ESCALA_KENNEY, pai="Vila")
    # A feira e os bancos da praça, a máquina de venda, o carro abandonado.
    for x in (65.5, 69.0, 77.0, 80.5):
        m.peca("Barraca", MUNDO_PACOTE + "barraca_de_feira.glb", x, 51.3, pai="Vila")
    for x, z, graus in ((70.0, 59.5, 0), (76.0, 59.5, 0), (70.0, 54.5, 180), (76.0, 54.5, 180)):
        m.peca("Banco", MUNDO_PACOTE + "banco_de_praca.glb", x, z, graus=graus + 180, pai="Vila")
    for x in (66.5, 79.5):
        m.peca("Palmeira", MUNDO_PACOTE + "palmeira.glb", x, 61.8, graus=x * 13, pai="Vila", cobre=True)
    m.peca("Maquina", MUNDO_PACOTE + "maquina_de_venda.glb", 62.0, 46.5, pai="Vila")
    m.peca("Maquina", MUNDO_PACOTE + "maquina_de_venda.glb", 77.6, 14.4, pai="Vila")
    m.peca("CarroVelho", MUNDO_PACOTE + "carro_velho.glb", 55.5, 60.5, graus=80, pai="Vila")
    m.peca("CarroVelho", MUNDO_PACOTE + "carro_velho.glb", 105.5, 57.0, graus=-20, pai="Vila")
    for x, z in ((61, 67), (61, 61), (67, 71.5), (73, 71.5), (79, 71.5), (97.5, 43.5), (97.5, 66)):
        m.peca("Arbusto", MUNDO_PACOTE + "arbusto_do_oasis.glb", x, z, graus=x * 11, escala=0.8, pai="Vila")
    for z in (20, 28, 36):
        m.peca("PosteDaAvenida", MUNDO_PACOTE + "poste_de_luz.glb", 77.3, z, graus=-90, pai="Vila")
    m.espalhador("FloresDaVila", MUNDO_PACOTE + "enfeite_flores.glb", 80, 58, 50, 44, 26, 44, distancia=2.0,
                 sombra=False, livres=[(62, 48, 22, 16), (78, 12, 4, 36), (86, 13, 8, 82), (52, 38, 14, 10),
                                       (63, 36, 12, 10), (95, 44, 10, 34), (54, 58, 10, 10), (59, 70, 22, 10)],
                 pai="Vila")
    m.peca("AntenaDoKenji", DUNGEON_PACOTE + "movel_antena_pirata.glb", 108, 22, escala=1.4, pai="Vila", gira=True)
    for x, z in ((96, 70), (104, 40)):
        m.peca("Barril", DUNGEON_PACOTE + "barril.glb", x, z, pai="Vila")

    # -- fazendas solares (oeste)
    c.no("Solar", "Node3D")
    for z in (34, 40, 62, 68):
        for x in range(12, 46, 5):
            m.peca("Paineis", INDUSTRIAL + "solar_panel_landscape_group.glb", x, z, escala=ESCALA_KENNEY, pai="Solar")
    for x, z in ((12, 50), (42, 52)):
        m.peca("CataVento", MUNDO_PACOTE + "cata_vento_enferrujado.glb", x, z, pai="Solar", cobre=True)
    for x, z in ((46.5, 46), (10, 57)):
        m.peca("Transformador", DUNGEON_PACOTE + "bateria_de_reserva.glb", x, z, graus=90, pai="Solar")
    for x, z in ((40, 30), (16, 74)):
        m.peca("CataVentoNovo", INDUSTRIAL + "windmill.glb", x, z, escala=4.0, pai="Solar", cobre=True)

    # -- Badlands (nordeste): mesas de pedra no fundo, a pedreira e cactos
    c.no("Badlands", "Node3D")
    for nome, x, z, graus in (("MesaGrande", 148, 22, 10), ("MesaGrande", 132, 19, -15), ("MesaGrande", 156, 40, 80)):
        m.peca(nome, MUNDO_PACOTE + "mesa_de_pedra_grande.glb", x, z, graus=graus, pai="Badlands")
    for nome, x, z, graus in (("MesaMedia", 120, 44, 30), ("MesaMedia", 152, 54, -20), ("MesaMedia", 114, 18, 0)):
        m.peca(nome, MUNDO_PACOTE + "mesa_de_pedra_media.glb", x, z, graus=graus, pai="Badlands", cobre=True)
    for x, z in ((138, 32), (142, 35), (135, 36), (140, 39)):
        m.peca("RochaDaPedreira", MUNDO_PACOTE + "rocha_do_deserto.glb", x, z, graus=sorteio.uniform(0, 360),
               escala=1.4, pai="Badlands")
    for x in (126, 130, 134):
        m.peca("Trilho", MUNDO_PACOTE + "enfeite_trilho.glb", x, 33.5, graus=90, pai="Badlands")
    m.peca("Vagonete", MUNDO_PACOTE + "vagonete.glb", 131, 33.5, graus=90, pai="Badlands")
    m.peca("Caixote", DUNGEON_PACOTE + "caixote_de_metal.glb", 125, 31.6, graus=20, pai="Badlands")
    m.peca("Caixote", DUNGEON_PACOTE + "caixote_de_metal.glb", 125.6, 31.0, graus=-10, y=0.46, pai="Badlands")
    m.peca("CarroVelho", MUNDO_PACOTE + "carro_velho.glb", 112, 52, graus=35, pai="Badlands")

    # -- acampamento das motoqueiras (leste)
    c.no("Acampamento", "Node3D")
    m.peca("Oficina", MUNDO_PACOTE + "oficina_das_motoqueiras.glb", 140, 70, pai="Acampamento")
    m.peca("Trailer", MUNDO_PACOTE + "trailer.glb", 127, 82, graus=20, pai="Acampamento")
    m.peca("Trailer", MUNDO_PACOTE + "trailer.glb", 153, 84, graus=-30, pai="Acampamento")
    for x, z, graus in ((134.5, 78.5, 80), (136.2, 79, 100), (146, 77, -70)):
        m.peca("Moto", MUNDO_PACOTE + "moto.glb", x, z, graus=graus, pai="Acampamento")
    m.peca("Rampa", MUNDO_PACOTE + "rampa_de_salto.glb", 146, 90, graus=90, pai="Acampamento")
    for x, z in ((124, 72), (157, 73), (132, 90)):
        m.peca("Pneus", MUNDO_PACOTE + "pilha_de_pneus.glb", x, z, graus=sorteio.uniform(0, 360), pai="Acampamento")
    m.peca("Muro", MUNDO_PACOTE + "muro_grafitado.glb", 129, 68.5, pai="Acampamento")
    m.peca("Muro", MUNDO_PACOTE + "muro_grafitado.glb", 151, 68.5, pai="Acampamento")
    m.peca("Fogueira", NATUREZA + "campfire_stones.glb", 140, 82, escala=3.0, pai="Acampamento")
    m.peca("Toldo", MUNDO_PACOTE + "toldo_de_lona.glb", 133, 76.5, graus=-10, pai="Acampamento")
    m.peca("Mesa", MUNDO_PACOTE + "mesa_de_acampamento.glb", 133, 76.8, graus=-10, pai="Acampamento")
    for x, z in ((156, 78), (156.7, 78.8), (122.5, 80)):
        m.peca("Tambor", DUNGEON_PACOTE + "barril_de_aviso.glb", x, z, pai="Acampamento")
    m.peca("CarroVelho", MUNDO_PACOTE + "carro_velho.glb", 124, 89, graus=60, pai="Acampamento")
    m.peca("Maquina", MUNDO_PACOTE + "maquina_de_venda.glb", 146.5, 72.4, pai="Acampamento")
    m.luz("LuzDaFogueira", 140, 1.4, 82, (1.0, 0.6, 0.3), alcance=8.0, energia=1.5, pai="Acampamento")
    c.no("AlvosDeTreino", "Node3D", pai="Acampamento")
    for x in (148, 150.5, 153):
        m.peca("AlvoDeTreino", "res://scenes/combat/alvo_de_treino.tscn", x, 79, pai="Acampamento/AlvosDeTreino")

    # -- a porteira para a fazenda (noroeste)
    c.no("SaidaDaFazenda", "Node3D")
    m.peca("Porteira", MUNDO_PACOTE + "porteira_da_fazenda.glb", 0.5, 22, graus=90, pai="SaidaDaFazenda")
    m.peca("CaixaDeCorreio", MUNDO_PACOTE + "caixa_de_correio.glb", 4, 25.5, pai="SaidaDaFazenda")
    m.marcador("ChegadaDaFazenda", 5, 22, graus=90, pai="SaidaDaFazenda")
    m.passagem("PassagemParaAFazenda", -2.5, 22, 2.0, 5.0, "fazenda", "ChegadaDaPorteira", pai="SaidaDaFazenda")

    # -- deserto espalhado (o que dá vida ao chão aberto)
    c.no("Deserto", "Node3D")
    m.espalhador("CactosAltos", MUNDO_PACOTE + "cacto_alto.glb", 80, 62, 156, 92, 70, 3, distancia=5.0,
                 raio=0.3, altura=2.0, livres=LIVRES, pai="Deserto")
    m.espalhador("CactosRedondos", MUNDO_PACOTE + "cacto_redondo.glb", 80, 62, 156, 92, 90, 4, distancia=2.5,
                 raio=0.32, altura=0.5, livres=LIVRES, pai="Deserto")
    m.espalhador("Palmas", MUNDO_PACOTE + "cacto_de_raquete.glb", 80, 62, 156, 92, 60, 5, distancia=2.5,
                 raio=0.3, altura=0.9, livres=LIVRES, pai="Deserto")
    m.espalhador("Rochas", MUNDO_PACOTE + "rocha_do_deserto.glb", 80, 62, 156, 92, 45, 6, distancia=4.0,
                 raio=0.9, altura=0.6, livres=LIVRES, escala=(0.7, 1.5), pai="Deserto")
    m.espalhador("Pedras", MUNDO_PACOTE + "pedras_do_deserto.glb", 80, 62, 156, 92, 50, 7, distancia=3.0,
                 livres=LIVRES, sombra=False, some=40.0, pai="Deserto")
    m.espalhador("Capim", MUNDO_PACOTE + "enfeite_capim_seco.glb", 80, 62, 156, 92, 320, 8, distancia=1.4,
                 livres=LIVRES[:1] + LIVRES[3:5], sombra=False, some=35.0, pai="Deserto")
    m.espalhador("ArbustosSecos", MUNDO_PACOTE + "arbusto_seco.glb", 80, 62, 156, 92, 70, 11, distancia=3.0,
                 livres=LIVRES, sombra=False, some=45.0, pai="Deserto")
    m.espalhador("BolasDeFeno", MUNDO_PACOTE + "enfeite_bola_de_feno.glb", 80, 62, 156, 92, 14, 12, distancia=10.0,
                 livres=LIVRES, pai="Deserto")
    m.espalhador("Caveiras", MUNDO_PACOTE + "enfeite_caveira_de_boi.glb", 120, 50, 70, 60, 5, 9, distancia=12.0,
                 livres=LIVRES, sombra=False, pai="Deserto")
    m.espalhador("CactosDasBadlands", MUNDO_PACOTE + "cacto_alto.glb", 138, 40, 40, 36, 16, 10, distancia=4.0,
                 raio=0.3, altura=2.0, livres=LIVRES + [(130, 28, 16, 14)], pai="Deserto")

    # -- pontos de rotina dos NPCs (os nomes são os que os perfis usam)
    c.no("PontosDeRotina", "Node3D", grupos=["pontos_de_rotina"])
    pontos = (
        ("casa_marta", 61.5, 64, 90), ("casa_iara", 64, 71.5, 0), ("casa_sol", 76, 71.5, 0),
        ("casa_kenji", 96.5, 46, -90), ("casa_rafa", 96.5, 51, -90), ("casa_vitor", 96.5, 63, -90),
        ("oficina", 97.5, 74, -90), ("mercado", 68, 45.5, 0), ("clinica", 61.5, 55, 90),
        ("torre_antena", 108, 25, 0), ("posto_entrega", 77, 16.5, 0), ("mirante", 118, 34, 0),
        ("praca", 73, 60, 0), ("ponte", X_DO_CANAL, 56, 90), ("beira_rio", 70, 89.5, 180),
    )
    for nome, x, z, graus in pontos:
        m.marcador(nome, x, z, graus=graus, pai="PontosDeRotina")
    c.no("ElencoDeNpcs", "Node3D", propriedades={"script": c.recurso("Script", "res://scripts/npcs/elenco_de_npcs.gd")})

    # -- bordas do mapa
    c.no("Limites", "Node3D")
    m.parede("Norte", 80, 9.6, 164, 1, pai="Limites")
    m.parede("Sul", 80, 110.6, 164, 1, pai="Limites")
    m.parede("Leste", 160.6, 60, 1, 102, pai="Limites")
    m.parede("OesteDeCima", -0.6, 15.25, 1, 11.5, pai="Limites")
    m.parede("OesteDeBaixo", -0.6, 67.25, 1, 88.5, pai="Limites")
    m.parede("AtrasDaPassagem", -5.5, 22, 1, 8, pai="Limites")
    m.parede("LadoDaPassagemNorte", -3, 19.2, 5, 1, pai="Limites")
    m.parede("LadoDaPassagemSul", -3, 24.8, 5, 1, pai="Limites")
    for z in range(30, 110, 4):
        m.peca("Cerca", MUNDO_PACOTE + "cerca_de_arame.glb", -0.2, z, graus=90, pai="Limites")
    for x in range(2, 160, 4):
        if 50 <= x <= 98:
            continue
        m.peca("Cerca", MUNDO_PACOTE + "cerca_de_arame.glb", x, 110, pai="Limites")

    # -- navegação
    arquivo = "res://resources/navigation/mundo.tres"
    propriedades = {}
    if (PASTA_DAS_MALHAS / "mundo.tres").exists():
        propriedades["navigation_mesh"] = c.recurso("NavigationMesh", arquivo)
    propriedades["script"] = c.recurso("Script", "res://scripts/world/regiao_de_navegacao.gd")
    propriedades["arquivo_da_malha"] = '"%s"' % arquivo
    propriedades["limite_do_chao"] = "Rect2(0, 10, 160, 100)"
    c.no("RegiaoDeNavegacao", "NavigationRegion3D", propriedades=propriedades)
    return c.texto()


def main():
    for nome, montar in (("fazenda", montar_fazenda), ("mundo", montar_mundo)):
        texto = montar()
        caminho = PASTA_DAS_CENAS / (nome + ".tscn")
        caminho.write_text(texto, encoding="utf-8")
        print("gravado", caminho.relative_to(RAIZ), "com", texto.count("[node "), "nos")


if __name__ == "__main__":
    main()
