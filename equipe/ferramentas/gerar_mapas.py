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
    "areia": (0.78, 0.58, 0.42),
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


def gravar_mascara_da_fazenda(livres, umidade=1.0):
    """A máscara da graminha da fazenda: um pixel por unidade, vermelho é a densidade e
    verde a umidade. Os retângulos livres (talhões, caminhos, quintal) ficam sem grama.

    O PNG é escrito à mão com zlib, para o gerador seguir só com a biblioteca padrão."""
    import struct
    import zlib
    largura, altura = int(LARGURA_DA_FAZENDA), int(PROFUNDIDADE_DA_FAZENDA)
    linhas = bytearray()
    for z in range(altura):
        linhas.append(0)
        for x in range(largura):
            centro_x, centro_z = x + 0.5, z + 0.5
            livre = any(rx <= centro_x <= rx + rw and rz <= centro_z <= rz + rd for (rx, rz, rw, rd) in livres)
            linhas += bytes((0 if livre else 255, int(umidade * 255), 0))

    def bloco(tipo, dados):
        corpo = tipo + dados
        return struct.pack(">I", len(dados)) + corpo + struct.pack(">I", zlib.crc32(corpo) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + bloco(b"IHDR", struct.pack(">IIBBBBB", largura, altura, 8, 2, 0, 0, 0))
    png += bloco(b"IDAT", zlib.compress(bytes(linhas), 9)) + bloco(b"IEND", b"")
    caminho = RAIZ / "game" / "assets" / "textures" / "grama" / "mascara_da_fazenda.png"
    caminho.write_bytes(png)


def grama_perto_do_jogador(cena, mascara=None, umidade=0.0, densidade=5.0):
    """A graminha que só nasce em volta do jogador (GramaPertoDoJogador)."""
    material = cena.sub("ShaderMaterial", {
        "shader": cena.recurso("Shader", "res://assets/shaders/grama_perto.gdshader")})
    propriedades = {
        "script": cena.recurso("Script", "res://scripts/world/grama_perto_do_jogador.gd"),
        "material": material,
        "umidade_sem_mascara": numero(umidade),
        "tufos_por_metro_quadrado": numero(densidade),
    }
    if mascara is not None:
        propriedades["mascara"] = cena.recurso("Texture2D", mascara)
    cena.no("GramaPertoDoJogador", "Node3D", propriedades=propriedades)


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
    # O chão de colisão da fazenda. O plano de colisão da fase fica bem abaixo (o mundo tem
    # relevo e precisa do rio afundado livre), então cada mapa traz o próprio chão.
    forma_do_chao = c.sub("BoxShape3D", {"size": vetor(140, 1, 120)})
    corpo_do_chao = c.no("ChaoFirme", "StaticBody3D", pai="Chao", propriedades={
        "position": vetor(25, -0.5, 20), "collision_layer": "513", "collision_mask": "0", "metadata/superficie": '&"terra"'})
    c.no("Forma", "CollisionShape3D", pai=corpo_do_chao, propriedades={"shape": forma_do_chao})
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

    # Graminha perto do jogador: mais verde que a do mundo, a fazenda é o oásis.
    # A máscara da graminha usa só o que é chão de uso (talhão, caminho, casa, galpão,
    # laguinho). O gramado em volta da casa ganha grama, mesmo sem enfeite espalhado.
    sem_grama_na_fazenda = [(x - 0.6, z - 0.6, w + 1.2, d + 1.2) for (x, z, w, d, _l) in TALHOES] + [
        (16, 1, 16, 8.5), (31, 2, 11, 10), (6, 1, 8, 8), (3, 11, 44, 4.5), (0.5, 10.5, 4.8, 5.5),
        (43, 14, 8, 11), (31.5, 20.5, 2.2, 3)]
    gravar_mascara_da_fazenda(sem_grama_na_fazenda)
    grama_perto_do_jogador(c, mascara="res://assets/textures/grama/mascara_da_fazenda.png", densidade=5.0)

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
#
# O mundo orgânico (plano 26, segunda versão). O traçado do rio, do cânion, do aquífero,
# dos terraços e das trilhas vem de desenho_do_mundo.py, o mesmo arquivo que o Blender lê
# para modelar o terreno. As alturas do chão vêm de altura_do_mundo.json, gravado pelo
# script do terreno, para cada peça assentar no relevo.

import json
import sys as _sys

_sys.path.insert(0, str(Path(__file__).resolve().parent))
import desenho_do_mundo as dm

with open(Path(__file__).resolve().parent / "altura_do_mundo.json") as _arquivo:
    _ALTURAS = json.load(_arquivo)


def chao(x, z):
    """A altura do chão do mundo em (x, z), pela grade gravada pelo script do terreno."""
    passo = _ALTURAS["passo"]
    cx = (x - _ALTURAS["x0"]) / passo
    cz = (z - _ALTURAS["z0"]) / passo
    colunas, linhas = _ALTURAS["colunas"], _ALTURAS["linhas"]
    cx = min(max(cx, 0.0), colunas - 1.001)
    cz = min(max(cz, 0.0), linhas - 1.001)
    i, j = int(cx), int(cz)
    fx, fz = cx - i, cz - j
    a = _ALTURAS["alturas"]
    v00 = a[j * colunas + i]
    v10 = a[j * colunas + i + 1]
    v01 = a[(j + 1) * colunas + i]
    v11 = a[(j + 1) * colunas + i + 1]
    return (v00 * (1 - fx) + v10 * fx) * (1 - fz) + (v01 * (1 - fx) + v11 * fx) * fz


def circulos_das_trilhas(folga=1.2):
    """As trilhas, o rio e o cânion como círculos livres para o deserto espalhado."""
    circulos = []
    for pontos, largura in dm.TRILHAS:
        for x, z in dm.suavizar(pontos, passo=2.0):
            circulos.append((x, z, largura / 2 + folga))
    for x, z in dm.suavizar(dm.RIO, passo=2.0):
        circulos.append((x, z, dm.meia_largura_do_rio_em(z) + dm.LARGURA_DA_MARGEM_DO_RIO + 1.0))
    for x, z in dm.suavizar(dm.CANION, passo=2.0):
        circulos.append((x, z, dm.MEIA_LARGURA_DO_CANION + dm.LARGURA_DA_PAREDE_DO_CANION + 1.0))
    return circulos


def dentro_de_algum_lugar(x, z, folga=0.0):
    for cx, cz, rx, rz in dm.LUGARES.values():
        if ((x - cx) / (rx + folga)) ** 2 + ((z - cz) / (rz + folga)) ** 2 < 1.0:
            return True
    return False


# O que é pequeno demais para servir de ponto de referência.
PECAS_QUE_NAO_SAO_MARCO = (
    "barril", "arbusto", "enfeite_", "pedras", "varal", "banco_de_praca", "caixa_de_correio", "maquina_de_venda",
    "moto", "pilha_de_pneus", "mesa_de_acampamento", "alvo_de_treino", "campfire", "poste_de_luz", "cerca_",
    "vagonete", "rochedo_b", "placa_de_estrada", "bateria_de_reserva",
)
MARCOS_POSTOS = []

# A janela que a câmera do jogo mostra em volta do jogador.
JANELA_LADO, JANELA_NORTE, JANELA_SUL = 7.5, 8.0, 4.5


def andavel(x, z):
    """Verdadeiro para o chão onde o jogador pode estar: fora da água, do cânion e das reservas."""
    if x < 1 or x > 159 or z < 10 or z > 108:
        return False
    if _distancia_a_pontos(x, z, dm.suavizar(dm.RIO, passo=1.0)) < dm.meia_largura_do_rio_em(z) + dm.LARGURA_DA_MARGEM_DO_RIO:
        return False
    if _distancia_a_pontos(x, z, dm.suavizar(dm.CANION, passo=1.0)) < dm.MEIA_LARGURA_DO_CANION + dm.LARGURA_DA_PAREDE_DO_CANION:
        return False
    cx, cz = dm.AQUIFERO_CENTRO
    if math.hypot(x - cx, z - cz) < dm.raio_do_aquifero(math.atan2(z - cz, x - cx)) + 0.5:
        return False
    for pontos in dm.RESERVAS.values():
        if _dentro_do_poligono(x, z, pontos):
            return False
    return True


def _distancia_a_pontos(x, z, pontos):
    return min(math.hypot(x - px, z - pz) for px, pz in pontos)


def _dentro_do_poligono(x, z, pontos):
    dentro = False
    for (x1, z1), (x2, z2) in zip(pontos, pontos[1:] + pontos[:1]):
        if (z1 > z) != (z2 > z) and x < (x2 - x1) * (z - z1) / (z2 - z1) + x1:
            dentro = not dentro
    return dentro


def relatorio_de_marcos():
    """Mede, para cada ponto andável (de 2 em 2), se algum marco cai na janela da câmera,
    e lista os buracos. É a regra do plano 26: sempre um marco à vista."""
    total, cobertos, buracos = 0, 0, []
    for x in range(1, 160, 2):
        for z in range(11, 109, 2):
            if not andavel(x, z):
                continue
            total += 1
            if any(abs(mx - x) <= JANELA_LADO and z - JANELA_NORTE <= mz <= z + JANELA_SUL for mx, mz, n in MARCOS_POSTOS if n != "nada"):
                cobertos += 1
            else:
                buracos.append((x, z))
    print("cobertura de marcos: %d%% (%d de %d pontos andáveis), %d marcos" % (100 * cobertos // max(total, 1), cobertos, total, sum(1 for *_r, n in MARCOS_POSTOS if n != "nada")))
    return buracos


# Os marcos de preenchimento de cada região: o que faz sentido aparecer ali.
MARCOS_DE_PREENCHIMENTO = {
    "oeste": ("rochedo_a", "barraco_a", "carro_velho", "rochedo_c", "poste_de_energia"),
    "centro": ("barraco_b", "rochedo_c", "poste_de_energia", "carro_velho", "rochedo_a"),
    "leste": ("rochedo_a", "carro_velho", "rochedo_c", "barraco_a", "poste_de_energia"),
    "sul": ("rochedo_c", "palmeira", "barraco_b", "rochedo_a", "carro_velho"),
    "norte": ("outdoor_neon", "poste_de_energia", "barraco_a", "carro_velho"),
}


def regiao_de(x, z):
    if z < 22:
        return "norte"
    if z > 88:
        return "sul"
    if x < 50:
        return "oeste"
    if x > 110:
        return "leste"
    return "centro"


def lugar_livre_para_marco(x, z, circulos):
    if not andavel(x, z):
        return False
    if dentro_de_algum_lugar(x, z, folga=1.0):
        return False
    for cx_, cz_, r in circulos:
        if math.hypot(x - cx_, z - cz_) < r + 1.0:
            return False
    for mx, mz, _n in MARCOS_POSTOS:
        if math.hypot(x - mx, z - mz) < 4.0:
            return False
    return True


def preencher_buracos(p, sorteio, meta=0.95):
    """Põe marcos onde a câmera não teria nenhum à vista, até a cobertura passar da meta.

    O marco vai um pouco ao norte do buraco (a câmera vê mais para o norte do que para o
    sul), num lugar livre de trilha, água e outros marcos.
    """
    circulos = circulos_das_trilhas(folga=0.5)
    contadores = {}
    for rodada in range(400):
        buracos = []
        total = 0
        for x in range(1, 160, 2):
            for z in range(11, 109, 2):
                if not andavel(x, z):
                    continue
                total += 1
                if not any(abs(mx - x) <= JANELA_LADO and z - JANELA_NORTE <= mz <= z + JANELA_SUL for mx, mz, _n in MARCOS_POSTOS):
                    buracos.append((x, z))
        if not buracos or 1.0 - len(buracos) / total >= meta:
            return
        # Começa pelo buraco com mais vizinhos sem marco: é o meio da maior área vazia.
        def vizinhos(ponto):
            return sum(1 for b in buracos if abs(b[0] - ponto[0]) <= 7 and abs(b[1] - ponto[1]) <= 6)
        buraco = max(buracos, key=vizinhos)
        posto = False
        for dz in (-4, -2, -6, 0, 2, -8):
            for dx in (0, 3, -3, 6, -6):
                x, z = buraco[0] + dx, buraco[1] + dz
                if lugar_livre_para_marco(x, z, circulos):
                    regiao = regiao_de(x, z)
                    escolha = MARCOS_DE_PREENCHIMENTO[regiao][contadores.get(regiao, 0) % len(MARCOS_DE_PREENCHIMENTO[regiao])]
                    contadores[regiao] = contadores.get(regiao, 0) + 1
                    p("Marco", MUNDO_PACOTE + escolha + ".glb", x, z, graus=sorteio.uniform(0, 360) if escolha.startswith("rochedo") else sorteio.uniform(-35, 35),
                      pai="Preenchimento", cobre=escolha in ("rochedo_a", "rochedo_c", "palmeira") and z < 100)
                    posto = True
                    break
            if posto:
                break
        if not posto:
            # Sem lugar livre perto, este buraco fica de fora da conta nas próximas rodadas.
            MARCOS_POSTOS.append((buraco[0], buraco[1], "nada"))


def montar_mundo():
    c = Cena()
    m = Montador(c)
    raiz_do_mapa(c, "Mundo", "mundo", "Arredores da vila")
    sorteio = random.Random(26)

    def p(nome, modelo, x, z, graus=0.0, pai=".", escala=None, cobre=False, gira=False, erguer=0.0):
        """Uma peça assentada no chão do terreno. Peça grande conta como marco."""
        arquivo = modelo.rsplit("/", 1)[-1].replace(".glb", "").replace(".tscn", "")
        if not any(arquivo.startswith(pequeno) for pequeno in PECAS_QUE_NAO_SAO_MARCO):
            MARCOS_POSTOS.append((x, z, arquivo))
        return m.peca(nome, modelo, x, z, graus=graus, pai=pai, escala=escala, cobre=cobre, gira=gira, y=chao(x, z) + erguer)

    def voltada_para(x, z, alvo_x, alvo_z):
        """Os graus que viram a frente (+Z) de uma peça para o ponto dado."""
        return math.degrees(math.atan2(alvo_x - x, alvo_z - z))

    # -- o chão e a água
    c.no("Chao", "Node3D")
    m.peca("Terreno", MUNDO_PACOTE + "chao_terreno_mundo.glb", 0, 0, pai="Chao")
    agua = m.peca("Agua", MUNDO_PACOTE + "enfeite_agua_do_mundo.glb", 0, 0, pai="Chao")
    material_da_agua = c.sub("ShaderMaterial", {
        "shader": c.recurso("Shader", "res://assets/shaders/agua_toon.gdshader"),
        "shader_parameter/espuma_pela_cor_do_vertice": "true"})
    c.no("AplicarShader", "Node", pai=agua, propriedades={
        "script": c.recurso("Script", "res://scripts/world/material_nas_malhas.gd"),
        "material": material_da_agua})

    # -- viaduto e a cidade ao fundo (o norte pode ser alto)
    c.no("Viaduto", "Node3D")
    for x in range(4, 160, 8):
        m.peca("Modulo", MUNDO_PACOTE + "viaduto_modulo.glb", x, 5.0, pai="Viaduto")
        # O viaduto é alto (4,2) e aparece no alto da tela de quem está na pista.
        MARCOS_POSTOS.append((x, 5.0, "viaduto_modulo"))
    for x in range(6, 158, 13):
        m.peca("Predio", DUNGEON_PACOTE + "predio_de_fundo.glb", x + sorteio.uniform(-2, 2), -9 - sorteio.random() * 4,
               escala=1.6 + sorteio.random() * 1.2, pai="Viaduto")
    p("PontoDeOnibus", MUNDO_PACOTE + "ponto_de_onibus.glb", 74, 14.6, pai="Viaduto")
    p("Maquina", MUNDO_PACOTE + "maquina_de_venda.glb", 77.2, 14.2, pai="Viaduto")
    for x in (40, 118):
        p("Outdoor", MUNDO_PACOTE + "outdoor_neon.glb", x, 15.0, pai="Viaduto")
    for x in range(10, 156, 16):
        if abs(x - 87) > 5:
            p("Poste", MUNDO_PACOTE + "poste_de_luz.glb", x, 14.0, pai="Viaduto")
    m.luz("LuzDoPonto", 74, 2.6, 16, (0.45, 0.7, 1.0), pai="Viaduto")

    # -- pontes, no lugar exato onde as trilhas cruzam o rio e o cânion
    c.no("Pontes", "Node3D")
    modelos_de_ponte = {"sucata": "ponte_de_sucata", "madeira": "ponte_de_madeira", "cabo": "ponte_de_cabo"}
    pontes_do_rio = []
    for nome, x, z, comprimento, tipo in dm.PONTES:
        if x is None:
            x, angulo = dm.x_do_curso_em(dm.RIO, z)
            graus = math.degrees(angulo)
            pontes_do_rio.append(z)
        else:
            z, angulo = dm.z_do_curso_em(dm.CANION, x)
            graus = -math.degrees(angulo) - 90.0
            ponte_do_canion = x
        m.peca(nome, MUNDO_PACOTE + modelos_de_ponte[tipo] + ".glb", x, z, graus=graus, pai="Pontes")

    # -- paredes invisíveis no alto da margem (o rio e o cânion são afundados)
    c.no("Margens", "Node3D")

    def muro_ao_longo(pontos, nome, pular):
        for (x1, z1), (x2, z2) in zip(pontos, pontos[1:]):
            mx, mz = (x1 + x2) / 2, (z1 + z2) / 2
            if pular(mx, mz):
                continue
            comprimento = math.hypot(x2 - x1, z2 - z1) + 0.3
            forma = c.sub("BoxShape3D", {"size": vetor(comprimento, 3.0, 0.4)})
            corpo = c.no(nome, "StaticBody3D", pai="Margens", propriedades={
                "position": vetor(mx, 1.0, mz), "rotation": vetor(0, -math.atan2(z2 - z1, x2 - x1), 0),
                "collision_mask": "0"})
            c.no("Forma", "CollisionShape3D", pai=corpo, propriedades={"shape": forma})

    def lado_do_rio(sinal):
        pontos = []
        curva = dm.suavizar(dm.RIO, passo=2.0)
        for indice, (x, z) in enumerate(curva):
            a = curva[max(indice - 1, 0)]
            b = curva[min(indice + 1, len(curva) - 1)]
            dx, dz = b[0] - a[0], b[1] - a[1]
            comprimento = math.hypot(dx, dz) or 1.0
            desvio = dm.meia_largura_do_rio_em(z) + dm.LARGURA_DA_MARGEM_DO_RIO + 0.2
            pontos.append((x + dz / comprimento * desvio * sinal, z - dx / comprimento * desvio * sinal))
        return pontos

    def perto_de_ponte_do_rio(x, z):
        return any(abs(z - zp) < 1.6 for zp in pontes_do_rio) or z > dm.AQUIFERO_CENTRO[1] - dm.AQUIFERO_RAIOS[1] - 1.0
    for sinal in (-1, 1):
        muro_ao_longo(lado_do_rio(sinal), "MargemDoRio", perto_de_ponte_do_rio)
        muro_ao_longo(dm.paralela(dm.CANION, sinal * (dm.MEIA_LARGURA_DO_CANION + dm.LARGURA_DA_PAREDE_DO_CANION + 0.2)),
                      "BeiraDoCanion", lambda x, z: abs(x - ponte_do_canion) < 1.5)
    # O aquífero: a margem toda, menos o vão do píer e a boca do rio.
    contorno = dm.margem_do_aquifero(80)
    contorno_largo = []
    cx, cz = dm.AQUIFERO_CENTRO
    for x, z in contorno + contorno[:1]:
        dx, dz = x - cx, z - cz
        r = math.hypot(dx, dz)
        contorno_largo.append((x + dx / r * (dm.LARGURA_DA_MARGEM_DO_AQUIFERO + 0.2), z + dz / r * (dm.LARGURA_DA_MARGEM_DO_AQUIFERO + 0.2)))
    x_do_pier = 64.0
    muro_ao_longo(contorno_largo, "MargemDoAquifero",
                  lambda x, z: (abs(x - x_do_pier) < 1.2 and z < cz) or (abs(x - dm.RIO[-1][0]) < 4 and z < cz - 4))

    # -- aquífero: píer, barco, casa de bombas, oásis
    c.no("Aquifero", "Node3D")
    z_da_margem_norte = min(z for x, z in contorno if abs(x - x_do_pier) < 1.5)
    m.peca("Pier", MUNDO_PACOTE + "pier_de_madeira.glb", x_do_pier, z_da_margem_norte - 1.2, graus=180, pai="Aquifero",
           y=0.0)
    m.peca("Barco", MUNDO_PACOTE + "barco_velho.glb", x_do_pier + 2.6, z_da_margem_norte + 4.0, graus=8, pai="Aquifero",
           y=dm.ALTURA_DA_AGUA - 0.15)
    p("CasaDeBombas", MUNDO_PACOTE + "casa_de_bombas.glb", cx + dm.AQUIFERO_RAIOS[0] + 3.5, cz - 1.0, graus=-90, pai="Aquifero")
    for angulo in range(0, 360, 30):
        if 250 < angulo < 290:
            continue
        r = dm.raio_do_aquifero(math.radians(angulo)) + 2.6
        x, z = cx + math.cos(math.radians(angulo)) * r, cz + math.sin(math.radians(angulo)) * r
        if z > 107 or abs(x - x_do_pier) < 2.5:
            continue
        p("Palmeira", MUNDO_PACOTE + "palmeira.glb", x, z, graus=angulo * 7, pai="Aquifero", cobre=True)
    anel = []
    for angulo in range(0, 360, 8):
        r = dm.raio_do_aquifero(math.radians(angulo)) + 1.6
        anel.append((cx + math.cos(math.radians(angulo)) * r, cz + math.sin(math.radians(angulo)) * r))
    for indice, (x, z) in enumerate(anel):
        if abs(x - x_do_pier) < 2.0 or z > 107:
            continue
        modelo = ("enfeite_juncos", "enfeite_tufo_de_grama", "enfeite_juncos", "arbusto_do_oasis")[indice % 4]
        p("Beira", MUNDO_PACOTE + modelo + ".glb", x, z, graus=indice * 47, pai="Aquifero")

    # -- o mercado (praça redonda no terraço)
    c.no("Mercado", "Node3D")
    mx, mz = dm.LUGARES["mercado"][0], dm.LUGARES["mercado"][1]
    p("Letreiro", MUNDO_PACOTE + "letreiro_da_vila.glb", mx, mz - 3.0, pai="Mercado")
    p("Poco", MUNDO_PACOTE + "bomba_solar.glb", mx, mz + 2.0, pai="Mercado")
    for angulo in (-40, 40, 140, -112):
        x = mx + math.cos(math.radians(angulo)) * 6.5
        z = mz + math.sin(math.radians(angulo)) * 5.2
        p("Barraca", MUNDO_PACOTE + "barraca_de_feira.glb", x, z, graus=voltada_para(x, z, mx, mz), pai="Mercado")
    for angulo in (0, 100, -165, 180 + 35):
        x = mx + math.cos(math.radians(angulo)) * 3.6
        z = mz + math.sin(math.radians(angulo)) * 3.0
        p("Banco", MUNDO_PACOTE + "banco_de_praca.glb", x, z, graus=voltada_para(x, z, mx, mz) + 180, pai="Mercado")
    for angulo in (20, 160, -70):
        x = mx + math.cos(math.radians(angulo)) * 8.6
        z = mz + math.sin(math.radians(angulo)) * 7.0
        p("Palmeira", MUNDO_PACOTE + "palmeira.glb", x, z, graus=angulo, pai="Mercado", cobre=True)
    for x, z in ((mx - 5, mz - 6.5), (mx + 5, mz - 6.5), (mx - 7, mz + 4), (mx + 7, mz + 4)):
        p("Poste", MUNDO_PACOTE + "poste_de_luz.glb", x, z, graus=voltada_para(x, z, mx, mz), pai="Mercado")
    m.luz("LuzDoMercado", mx, 4.5, mz - 2, (0.95, 0.45, 0.95), alcance=12.0, pai="Mercado")
    # Na borda norte, fora do terraço: o mercado da Marta e o bar. A clínica a oeste.
    p("MercadoDaMarta", MUNDO_PACOTE + "mercado_da_marta.glb", mx - 4.5, mz - 12.0, pai="Mercado")
    p("Bar", MUNDO_PACOTE + "bar_de_beira_de_estrada.glb", mx + 6.0, mz - 11.5, pai="Mercado")
    m.luz("LuzDoBar", mx + 6.0, 3.0, mz - 8.5, (0.95, 0.45, 0.95), alcance=7.0, pai="Mercado")
    p("Clinica", MUNDO_PACOTE + "clinica_da_iara.glb", mx - 14.5, mz + 1.0, graus=90, pai="Mercado")
    p("CasaDaIara", MUNDO_PACOTE + "casa_da_iara.glb", mx - 14.0, mz + 9.5, graus=90, pai="Mercado")

    # -- a vila de barracos, do outro lado do rio
    c.no("Vila", "Node3D")
    vx, vz = dm.LUGARES["vila"][0], dm.LUGARES["vila"][1]
    p("CasaGeminada", MUNDO_PACOTE + "casa_geminada.glb", vx, vz - 9.0, pai="Vila")
    p("CasaDoVitor", MUNDO_PACOTE + "casa_do_vitor.glb", vx + 9.5, vz - 1.0, graus=-90, pai="Vila")
    p("OficinaDoVitor", MUNDO_PACOTE + "oficina_do_vitor.glb", vx + 9.5, vz + 7.5, graus=-90, pai="Vila")
    p("CasaDaMarta", MUNDO_PACOTE + "casa_da_marta.glb", vx - 8.5, vz + 6.0, graus=90, pai="Vila")
    for nome, modelo, x, z, graus in (("BarracoA", "barraco_a", vx - 7.0, vz - 8.5, 0), ("BarracoB", "barraco_b", vx + 3.5, vz + 10.5, 180),
                                      ("BarracoA", "barraco_a", vx + 12.5, vz - 10.0, -60), ("BarracoB", "barraco_b", vx - 2.0, vz + 13.5, 160)):
        p(nome, MUNDO_PACOTE + modelo + ".glb", x, z, graus=graus, pai="Vila")
    p("AntenaDoKenji", DUNGEON_PACOTE + "movel_antena_pirata.glb", vx + 4.5, vz - 13.0, escala=1.5, pai="Vila", gira=True)
    p("Varal", MUNDO_PACOTE + "varal.glb", vx - 3.5, vz + 3.0, graus=30, pai="Vila")
    for x, z in ((vx + 2, vz - 2), (vx - 4, vz + 1), (vx + 6, vz + 3)):
        p("Barril", DUNGEON_PACOTE + "barril.glb", x, z, pai="Vila")
    p("CarroVelho", MUNDO_PACOTE + "carro_velho.glb", vx + 13.0, vz + 2.0, graus=-20, pai="Vila")
    p("Cisterna", MUNDO_PACOTE + "cisterna_velha.glb", dm.LUGARES["cisterna"][0], dm.LUGARES["cisterna"][1], pai="Vila", cobre=True)
    p("BarracaDaSol", MUNDO_PACOTE + "barraca_da_sol.glb", 73.0, 75.0, graus=90, pai="Vila")
    m.luz("LuzDaSol", 73.5, 1.2, 74.0, (1.0, 0.8, 0.4), alcance=5.0, energia=0.8, pai="Vila")
    for x, z in ((vx - 5.5, vz - 4.0), (vx + 6.5, vz - 6.0), (vx + 1.0, vz + 6.5)):
        p("Arbusto", MUNDO_PACOTE + "arbusto_do_oasis.glb", x, z, escala=0.8, pai="Vila")

    # -- campos solares, o cânion entre eles
    c.no("Solar", "Node3D")
    for grupo_x, grupo_z, linhas_, colunas_ in ((14, 26, 2, 4), (28, 24, 2, 3), (16, 38, 2, 3), (32, 38, 1, 3), (10, 84, 2, 3), (14, 96, 1, 4), (30, 94, 2, 2)):
        for linha in range(linhas_):
            for coluna in range(colunas_):
                x = grupo_x + coluna * 4.2 + sorteio.uniform(-0.3, 0.3)
                z = grupo_z + linha * 3.2
                p("Paineis", INDUSTRIAL + "solar_panel_landscape_group.glb", x, z, graus=sorteio.uniform(-6, 6),
                  escala=ESCALA_KENNEY * 0.75, pai="Solar")
    p("CataVento", MUNDO_PACOTE + "cata_vento_enferrujado.glb", 7, 32, pai="Solar", cobre=True)
    p("CataVentoNovo", INDUSTRIAL + "windmill.glb", 40, 20, escala=4.0, pai="Solar", cobre=True)
    for x, z in ((38, 32), (22, 33), (24, 90)):
        p("Transformador", DUNGEON_PACOTE + "bateria_de_reserva.glb", x, z, graus=90, pai="Solar")
    for x, z, graus in ((20, 31, 10), (27, 92, -20), (36, 30, 70)):
        p("Cabos", DUNGEON_PACOTE + "enfeite_cabos.glb", x, z, graus=graus, pai="Solar")
    p("PocoDePetroleo", MUNDO_PACOTE + "poco_de_petroleo.glb", 35, 80, graus=-20, pai="Solar")

    # -- entradas das dungeons (a Galeria aberta desde o primeiro dia)
    c.no("Entradas", "Node3D")
    for nome, dungeon_id, modelo, x, z, rgb, frente in (
            ("Galeria", "galeria", "entrada_da_galeria", 98, 17.5, (1.0, 0.8, 0.35), 2.4),
            ("Torre", "torre", "entrada_da_torre", 132, 15.5, (0.95, 0.45, 0.95), 2.4),
            ("Biodomo", "biodomo", "entrada_do_biodomo", 18, 80, (0.5, 1.0, 0.6), 2.9)):
        grupo = c.no(nome, "Node3D", pai="Entradas", propriedades={"position": vetor(x, chao(x, z), z)})
        m.peca("Modelo", MUNDO_PACOTE + modelo + ".glb", 0, 0, pai=grupo)
        m.peca("Acesso", "res://scenes/world/entrada_de_dungeon.tscn", 0, frente, pai=grupo)
        c.nos[-1] += '\ndungeon_id = &"%s"' % dungeon_id
        m.luz("Luz", 0, 2.2, 1.8, rgb, alcance=7.0, pai=grupo)

    # -- Badlands e a pedreira
    c.no("Badlands", "Node3D")
    for x, z, graus in ((150, 19, 10), (138, 16, -15), (157, 36, 80)):
        p("MesaGrande", MUNDO_PACOTE + "mesa_de_pedra_grande.glb", x, z, graus=graus, pai="Badlands")
    p("Guindaste", MUNDO_PACOTE + "guindaste_da_pedreira.glb", 142, 37, graus=-30, pai="Badlands")
    for x in (131, 135, 139):
        p("Trilho", MUNDO_PACOTE + "enfeite_trilho.glb", x, 43, graus=90, pai="Badlands")
    p("Vagonete", MUNDO_PACOTE + "vagonete.glb", 136, 43, graus=90, pai="Badlands")
    for x, z in ((146, 40), (149, 44), (144, 46)):
        p("RochaDaPedreira", MUNDO_PACOTE + "rochedo_b.glb", x, z, graus=sorteio.uniform(0, 360), pai="Badlands")
    p("Mirante", MUNDO_PACOTE + "placa_de_estrada.glb", 127, 28.5, graus=0, pai="Badlands")
    p("BancoDoMirante", MUNDO_PACOTE + "banco_de_praca.glb", 125.5, 30.5, graus=180, pai="Badlands")
    p("Ossada", MUNDO_PACOTE + "enfeite_caveira_de_boi.glb", 146, 50, pai="Badlands")
    p("CarroVelho", MUNDO_PACOTE + "carro_velho.glb", 121, 50, graus=35, pai="Badlands")

    # -- acampamento das motoqueiras
    c.no("Acampamento", "Node3D")
    ax, az = dm.LUGARES["acampamento"][0], dm.LUGARES["acampamento"][1]
    p("Oficina", MUNDO_PACOTE + "oficina_das_motoqueiras.glb", ax + 2, az - 9, pai="Acampamento")
    p("Onibus", MUNDO_PACOTE + "onibus_abandonado.glb", ax - 10, az + 1, graus=20, pai="Acampamento")
    m.luz("LuzDoOnibus", ax - 10, 2.0, az - 1.5, (1.0, 0.6, 0.9), alcance=7.0, pai="Acampamento")
    p("Trailer", MUNDO_PACOTE + "trailer.glb", ax + 12, az + 2, graus=-30, pai="Acampamento")
    p("Trailer", MUNDO_PACOTE + "trailer.glb", ax - 4, az + 9, graus=170, pai="Acampamento")
    for x, z, graus in ((ax - 3.5, az - 4.5, 80), (ax - 1.8, az - 4.0, 100), (ax + 8, az - 5, -70)):
        p("Moto", MUNDO_PACOTE + "moto.glb", x, z, graus=graus, pai="Acampamento")
    p("Rampa", MUNDO_PACOTE + "rampa_de_salto.glb", ax + 8, az + 7, graus=90, pai="Acampamento")
    for x, z in ((ax - 13, az - 7), (ax + 14, az - 7), (ax - 6, az + 12)):
        p("Pneus", MUNDO_PACOTE + "pilha_de_pneus.glb", x, z, graus=sorteio.uniform(0, 360), pai="Acampamento")
    p("Muro", MUNDO_PACOTE + "muro_grafitado.glb", ax - 7, az - 11, pai="Acampamento")
    p("Muro", MUNDO_PACOTE + "muro_grafitado.glb", ax + 11, az - 11, pai="Acampamento")
    p("Fogueira", NATUREZA + "campfire_stones.glb", ax + 1, az + 1, escala=3.0, pai="Acampamento")
    m.luz("LuzDaFogueira", ax + 1, 1.4, az + 1, (1.0, 0.6, 0.3), alcance=8.0, energia=1.5, pai="Acampamento")
    p("Toldo", MUNDO_PACOTE + "toldo_de_lona.glb", ax - 5, az - 1, graus=-10, pai="Acampamento")
    p("Mesa", MUNDO_PACOTE + "mesa_de_acampamento.glb", ax - 5, az - 0.7, graus=-10, pai="Acampamento")
    c.no("AlvosDeTreino", "Node3D", pai="Acampamento")
    for indice, x in enumerate((ax + 8, ax + 10.5, ax + 13)):
        m.peca("AlvoDeTreino", "res://scenes/combat/alvo_de_treino.tscn", x, az - 1, pai="Acampamento/AlvosDeTreino",
               y=chao(x, az - 1))

    # -- reservas: cercadas, vistas mas não andáveis, com bichos dentro
    c.no("Reservas", "Node3D")

    def cercar(pontos, nome, modelo):
        fechado = list(pontos) + [pontos[0]]
        for (x1, z1), (x2, z2) in zip(fechado, fechado[1:]):
            comprimento = math.hypot(x2 - x1, z2 - z1)
            pedacos = max(int(round(comprimento / 4.0)), 1)
            for k in range(pedacos):
                t = (k + 0.5) / pedacos
                x, z = x1 + (x2 - x1) * t, z1 + (z2 - z1) * t
                p(nome, MUNDO_PACOTE + modelo + ".glb", x, z, graus=math.degrees(math.atan2(-(z2 - z1), x2 - x1)),
                  pai="Reservas", escala=comprimento / pedacos / 4.0 * 1.02 if abs(comprimento / pedacos - 4.0) > 0.3 else None)

    for nome, pontos in dm.RESERVAS.items():
        cercar(pontos, "Cerca", "cerca_de_sucata" if nome != "pasto_do_vizinho" else "cerca_de_arame")
    raposas = dm.RESERVAS["reserva_das_raposas"]
    p("CarcacaDeDrone", MUNDO_PACOTE + "carcaca_de_drone.glb", 43, 75, graus=25, pai="Reservas")
    p("Costela", MUNDO_PACOTE + "costela_gigante.glb", 108, 24, graus=-15, pai="Reservas")
    p("CaixaDoPasto", MUNDO_PACOTE + "caixa_dagua_da_fazenda.glb", 119, 69, pai="Reservas")

    def animal(nome, arquivo, x, z, area, escala, velocidade):
        c.no(nome, "Node3D", pai="Reservas", propriedades={
            "position": vetor(x, chao(x, z), z),
            "script": c.recurso("Script", "res://scripts/world/animal_do_cenario.gd"),
            "modelo": c.recurso("PackedScene", KENNEY + "kenney_cube_pets/" + arquivo + ".glb"),
            "area": "Rect2(%s, %s, %s, %s)" % (numero(area[0]), numero(area[1]), numero(area[2]), numero(area[3])),
            "escala_do_modelo": numero(escala), "velocidade": numero(velocidade)})

    area_das_raposas = (37, 68, 12, 18)
    for k, (x, z) in enumerate(((40, 70), (46, 80), (38, 84))):
        animal("Raposa", "animal_fox", x, z, area_das_raposas, 0.24, 1.1)
    for k, (x, z) in enumerate(((44, 70), (40, 78))):
        animal("Lebre", "animal_bunny", x, z, area_das_raposas, 0.2, 1.4)
    for k, (x, z) in enumerate(((115, 66), (120, 72), (117, 74))):
        animal("Vaca", "animal_cow", x, z, (114, 64, 9, 10), 0.36, 0.5)
    for k, (x, z) in enumerate(((104, 22), (111, 27))):
        animal("RaposaDosOssos", "animal_fox", x, z, (102, 20, 12, 8), 0.24, 1.0)
    c.no("BolasDeFeno", "Node3D", propriedades={
        "script": c.recurso("Script", "res://scripts/world/soprador_de_feno.gd"),
        "modelo": c.recurso("PackedScene", MUNDO_PACOTE + "enfeite_bola_de_feno.glb"),
        "areas": "Array[Rect2]([Rect2(34, 66, 8, 22), Rect2(100, 19, 6, 10), Rect2(2, 99, 40, 8), Rect2(105, 101, 50, 6), Rect2(112, 62, 5, 14), Rect2(118, 52, 16, 6)])",
        "maximo_ao_mesmo_tempo": "7"})

    # -- a porteira para a fazenda (noroeste)
    c.no("SaidaDaFazenda", "Node3D")
    p("Porteira", MUNDO_PACOTE + "porteira_da_fazenda.glb", 0.5, 20, graus=90, pai="SaidaDaFazenda")
    p("CaixaDeCorreio", MUNDO_PACOTE + "caixa_de_correio.glb", 4, 23.5, pai="SaidaDaFazenda")
    p("Placa", MUNDO_PACOTE + "placa_de_estrada.glb", 14, 18, graus=180, pai="SaidaDaFazenda")
    m.marcador("ChegadaDaFazenda", 5, 20, graus=90, pai="SaidaDaFazenda")
    m.passagem("PassagemParaAFazenda", -2.5, 20, 2.0, 5.0, "fazenda", "ChegadaDaPorteira", pai="SaidaDaFazenda")

    # -- marcos espalhados no caminho, para o jogador sempre ter um à vista
    c.no("Marcos", "Node3D")
    for x, z in ((52, 30), (114, 84), (30, 68), (104, 92), (48, 96)):
        p("Barraco", MUNDO_PACOTE + ("barraco_a" if x % 2 else "barraco_b") + ".glb", x, z, graus=sorteio.uniform(-30, 30), pai="Marcos")
    p("CaixaDagua", MUNDO_PACOTE + "caixa_dagua_da_fazenda.glb", 78, 30, pai="Marcos")
    for pontos, _largura in dm.TRILHAS[3:5]:
        curva = dm.suavizar(pontos, passo=12.0)
        for indice, (x, z) in enumerate(curva[1:-1]):
            p("PosteDeEnergia", MUNDO_PACOTE + "poste_de_energia.glb", x + 2.2, z + 1.5, graus=indice * 13, pai="Marcos")

    # -- preenchimento: onde ainda não há marco à vista, um marco do tipo da região
    c.no("Preenchimento", "Node3D")
    preencher_buracos(p, sorteio)

    # -- rocha: formações altas nas bordas e no norte; baixas no meio
    c.no("Rochas", "Node3D")
    altas = ((4, 48, "rochedo_a"), (9, 62, "rochedo_d"), (44, 22, "rochedo_c"), (68, 20, "rochedo_a"), (96, 32, "rochedo_c"),
             (118, 46, "rochedo_a"), (150, 60, "rochedo_d"), (156, 75, "rochedo_c"), (124, 96, "rochedo_b"), (150, 99, "rochedo_d"),
             (60, 80, "rochedo_c"), (112, 90, "rochedo_a"), (30, 103, "rochedo_d"), (5, 76, "rochedo_c"), (156, 90, "rochedo_a"),
             (1, 100, "rochedo_d"), (86, 104, "rochedo_b"), (100, 104, "rochedo_d"), (48, 104, "rochedo_b"))
    for x, z, modelo in altas:
        p("Rochedo", MUNDO_PACOTE + modelo + ".glb", x, z, graus=sorteio.uniform(0, 360), pai="Rochas",
          cobre=modelo in ("rochedo_a", "rochedo_c") and z < 95)

    # -- deserto espalhado
    c.no("Deserto", "Node3D")
    circulos = circulos_das_trilhas()
    livres_dos_lugares = [(cx_ - rx - 1, cz_ - rz - 1, (rx + 1) * 2, (rz + 1) * 2) for cx_, cz_, rx, rz in dm.LUGARES.values()]
    livres_dos_lugares += [(0, 0, 160, 16), (cx - 26, cz - 11, 52, 22)]

    def espalhar(nome, modelo, quantidade, semente, distancia, raio=0.0, altura=1.5, escala=(0.85, 1.2), sombra=True, some=0.0,
                 area=(80, 60, 156, 92), livres=None):
        no = m.espalhador(nome, MUNDO_PACOTE + modelo + ".glb", area[0], area[1], area[2], area[3], quantidade, semente,
                          distancia=distancia, raio=raio, altura=altura, livres=livres if livres is not None else livres_dos_lugares,
                          escala=escala, sombra=sombra, some=some, pai="Deserto")
        circulos_locais = ", ".join("%s, %s, %s" % (numero(x - area[0]), numero(z - area[1]), numero(r)) for x, z, r in circulos)
        c.nos[-1] += "\ncirculos_livres = PackedVector3Array(%s)\nseguir_o_chao = true" % circulos_locais
        return no

    espalhar("CactosAltos", "cacto_alto", 55, 3, 5.0, raio=0.3, altura=2.0)
    espalhar("CactosRedondos", "cacto_redondo", 80, 4, 2.5, raio=0.32, altura=0.5)
    espalhar("Palmas", "cacto_de_raquete", 55, 5, 2.5, raio=0.3, altura=0.9)
    espalhar("RochasBaixas", "rochas_baixas", 60, 6, 3.0, raio=0.7, altura=0.6, escala=(0.7, 1.4))
    espalhar("Pedras", "pedras_do_deserto", 70, 7, 2.5, sombra=False, some=40.0)
    espalhar("Capim", "enfeite_capim_seco", 380, 8, 1.3, sombra=False, some=35.0)
    espalhar("ArbustosSecos", "arbusto_seco", 90, 11, 2.5, sombra=False, some=45.0)
    espalhar("Ossos", "enfeite_ossos", 18, 12, 9.0, sombra=False)
    espalhar("Caveiras", "enfeite_caveira_de_boi", 8, 13, 12.0, sombra=False)
    espalhar("Rachaduras", "enfeite_rachadura", 120, 14, 3.0, sombra=False, some=45.0)
    espalhar("ManchasDeTerra", "enfeite_mancha_de_terra", 18, 15, 12.0, sombra=False, escala=(1.0, 2.0))

    # -- graminha perto do jogador, seca, só onde a máscara do terreno deixa
    grama_perto_do_jogador(c, mascara="res://assets/textures/grama/mascara_do_mundo.png")

    # -- pontos de rotina dos NPCs (os nomes são os que os perfis usam)
    c.no("PontosDeRotina", "Node3D", grupos=["pontos_de_rotina"])
    pontos_de_rotina = (
        ("casa_marta", vx - 5.6, vz + 6.0, 90), ("casa_iara", mx - 11.6, mz + 9.5, 90), ("casa_sol", 75.0, 75.0, 90),
        ("casa_kenji", vx - 1.8, vz - 6.3, 0), ("casa_rafa", vx + 2.2, vz - 6.3, 0), ("casa_vitor", vx + 7.0, vz - 1.0, -90),
        ("oficina", vx + 6.5, vz + 7.5, -90), ("mercado", mx - 4.5, mz - 9.0, 0), ("clinica", mx - 11.5, mz + 1.0, 90),
        ("torre_antena", vx + 4.5, vz - 10.5, 0), ("posto_entrega", 76.0, 16.0, 0), ("mirante", 127.0, 30.5, 0),
        ("praca", mx, mz + 0.5, 0), ("ponte", 0.0, dm.PONTES[2][2], 90), ("beira_rio", x_do_pier, z_da_margem_norte - 3.0, 180),
    )
    for nome, x, z, graus in pontos_de_rotina:
        if nome == "ponte":
            x, _angulo = dm.x_do_curso_em(dm.RIO, z)
        m.marcador(nome, x, z, graus=graus, pai="PontosDeRotina")
        c.nos[-1] = c.nos[-1].replace("position = Vector3(%s, 0, %s)" % (numero(x), numero(z)),
                                      "position = %s" % vetor(x, chao(x, z), z))
    c.no("ElencoDeNpcs", "Node3D", propriedades={"script": c.recurso("Script", "res://scripts/npcs/elenco_de_npcs.gd")})

    # -- bordas do mapa
    c.no("Limites", "Node3D")
    m.parede("Norte", 80, 8.6, 164, 1, pai="Limites")
    m.parede("Sul", 80, 108.6, 164, 1, pai="Limites")
    m.parede("Leste", 159.6, 60, 1, 102, pai="Limites")
    m.parede("OesteDeCima", -0.6, 13.25, 1, 9.5, pai="Limites")
    m.parede("OesteDeBaixo", -0.6, 65.25, 1, 88.5, pai="Limites")
    m.parede("AtrasDaPassagem", -5.5, 20, 1, 8, pai="Limites")
    m.parede("LadoDaPassagemNorte", -3, 17.2, 5, 1, pai="Limites")
    m.parede("LadoDaPassagemSul", -3, 22.8, 5, 1, pai="Limites")

    # -- navegação
    arquivo = "res://resources/navigation/mundo.tres"
    propriedades = {}
    if (PASTA_DAS_MALHAS / "mundo.tres").exists():
        propriedades["navigation_mesh"] = c.recurso("NavigationMesh", arquivo)
    propriedades["script"] = c.recurso("Script", "res://scripts/world/regiao_de_navegacao.gd")
    propriedades["arquivo_da_malha"] = '"%s"' % arquivo
    propriedades["limite_do_chao"] = "Rect2(0, 9, 160, 100)"
    propriedades["somar_chao_plano"] = "false"
    c.no("RegiaoDeNavegacao", "NavigationRegion3D", propriedades=propriedades)
    return c.texto()


def main():
    for nome, montar in (("fazenda", montar_fazenda), ("mundo", montar_mundo)):
        texto = montar()
        if nome == "mundo":
            buracos = relatorio_de_marcos()
            if "--buracos" in _sys.argv:
                print("buracos:", buracos)
        caminho = PASTA_DAS_CENAS / (nome + ".tscn")
        caminho.write_text(texto, encoding="utf-8")
        print("gravado", caminho.relative_to(RAIZ), "com", texto.count("[node "), "nos")


if __name__ == "__main__":
    main()
