#!/usr/bin/env python3
"""Monta as cenas das três dungeons a partir de uma descrição curta de cada uma.

Cada dungeon é uma fila de salas, da esquerda (oeste) para a direita (leste). A descrição
diz o tamanho de cada sala, os inimigos, a decoração e o objetivo paralelo; este script
calcula piso, paredes, portas, luzes e a ligação entre as salas, e grava o `.tscn`.

Uso, a partir da raiz do repositório:

    ./equipe/ferramentas/gerar_dungeons.py

Depois de gerar, refaça a malha de navegação de cada cena e rode este script de novo,
para a cena passar a apontar para a malha:

    godot --headless --path game res://scenes/utils/gerar_malha_de_navegacao.tscn -- res://scenes/levels/dungeon_galeria.tscn

ATENÇÃO: o script reescreve a cena inteira. Ajuste feito à mão no editor do Godot se
perde na próxima geração. Para mudar uma dungeon, mude a descrição dela aqui embaixo.

Regras de montagem que o script garante, e por quê:

- A câmera do jogo olha do sul para o norte, de cima. Por isso a parede do norte é alta,
  a do sul é uma mureta, e as salas se sucedem de oeste para leste: nenhuma parede alta
  fica entre a câmera e o jogador.
- Peça alta no meio da sala (marcada com "cobre") ganha o nó CoberturaTranslucida, que a
  deixa translúcida quando esconde o jogador ou um inimigo.
- A ordem dos pontos de inimigo na cena é o número do inimigo na rede. Como a cena é
  gerada, ela é igual nos dois jogos.

Medidas: uma placa de piso tem 2 por 2. A posição dentro da sala é (u, v), em unidades
do jogo, com u contando do canto oeste e v do canto norte.
"""

import math
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
PASTA_DAS_CENAS = RAIZ / "game" / "scenes" / "levels"
PASTA_DAS_MALHAS = RAIZ / "game" / "resources" / "navigation"
MODELOS = "res://assets/models/"
PACOTE = MODELOS + "cyber_moon_dungeons/"
INIMIGOS = "res://resources/combat/inimigos/"
CHEFES = "res://resources/combat/chefes/"

PLACA = 2.0
# As placas ficam um fio acima do plano de colisão da fase, para o som de passo ler a
# superfície da placa, e não a grama do plano.
ALTURA_DO_PISO = 0.02
METADE_DA_PAREDE = 0.15
ALTURA_DO_PONTO_DE_INIMIGO = 0.1


class Cena:
    """Acumula os recursos externos e os nós de um `.tscn`."""

    def __init__(self):
        self.recursos = {}
        self.linhas_de_recurso = []
        self.nos = []
        self.nomes_usados = {}

    def recurso(self, tipo, caminho):
        if caminho not in self.recursos:
            identificador = "r%d" % (len(self.recursos) + 1)
            self.recursos[caminho] = identificador
            self.linhas_de_recurso.append('[ext_resource type="%s" path="%s" id="%s"]' % (tipo, caminho, identificador))
        return 'ExtResource("%s")' % self.recursos[caminho]

    def nome_unico(self, pai, nome):
        chave = (pai, nome)
        self.nomes_usados[chave] = self.nomes_usados.get(chave, 0) + 1
        if self.nomes_usados[chave] == 1:
            return nome
        return "%s%d" % (nome, self.nomes_usados[chave])

    def no(self, nome, tipo=None, pai=".", instancia=None, propriedades=None):
        """Acrescenta um nó e devolve o caminho dele, para servir de pai a outros."""
        if pai is not None:
            nome = self.nome_unico(pai, nome)
        cabecalho = '[node name="%s"' % nome
        if tipo is not None:
            cabecalho += ' type="%s"' % tipo
        if pai is not None:
            cabecalho += ' parent="%s"' % pai
        if instancia is not None:
            cabecalho += " instance=%s" % self.recurso("PackedScene", instancia)
        cabecalho += "]"
        linhas = [cabecalho]
        for chave, valor in (propriedades or {}).items():
            linhas.append("%s = %s" % (chave, valor))
        self.nos.append("\n".join(linhas))
        if pai is None:
            return "."
        return nome if pai == "." else pai + "/" + nome

    def texto(self):
        return "[gd_scene format=3]\n\n" + "\n".join(self.linhas_de_recurso) + "\n\n" + "\n\n".join(self.nos) + "\n"


def vetor(x, y, z):
    return "Vector3(%s, %s, %s)" % (round(x, 3), round(y, 3), round(z, 3))


def giro(graus):
    return "Vector3(0, %s, 0)" % round(math.radians(graus), 5)


def cor(r, g, b):
    return "Color(%s, %s, %s, 1)" % (r, g, b)


class Montador:
    def __init__(self, descricao):
        self.d = descricao
        self.cena = Cena()
        self.tema = descricao["tema"]
        self.salas = []
        self._medir_salas()

    # -- medidas ------------------------------------------------------------------

    def _medir_salas(self):
        oeste = 0.0
        for indice, sala in enumerate(self.d["salas"]):
            largura = sala["colunas"] * PLACA
            profundidade = sala["linhas"] * PLACA
            # O deslocamento é em placas, para as portas caírem sempre no meio de uma.
            norte = sala.get("desvio", 0) * PLACA - profundidade / 2.0
            norte = round(norte / PLACA) * PLACA
            self.salas.append({
                "indice": indice, "oeste": oeste, "leste": oeste + largura,
                "norte": norte, "sul": norte + profundidade, "dados": sala,
                "caminho": None,
            })
            oeste += largura

    def ponto(self, sala, u, v, y=0.0):
        return (sala["oeste"] + u, y, sala["norte"] + v)

    # -- montagem -----------------------------------------------------------------

    def montar(self):
        c = self.cena
        c.no("Dungeon", "Node3D", pai=None, propriedades={
            "script": c.recurso("Script", "res://scripts/coop/dungeon.gd"),
        })
        c.no("Cenario", "Node3D")
        c.no("Portas", "Node3D")
        for sala in self.salas:
            self._montar_sala(sala)
        for indice in range(len(self.salas) - 1):
            self._montar_divisa(self.salas[indice], self.salas[indice + 1])
        self._montar_pontas()
        self._ligar_salas()
        self._montar_objetivo()
        self._montar_entrada_e_saida()
        self._montar_navegacao()
        return c.texto()

    def _modelo(self, nome):
        return nome if nome.startswith("res://") else PACOTE + nome + ".glb"

    def _peca(self, nome_do_no, modelo, posicao, graus=0.0, pai="Cenario", escala=None, cobre=False, maquina=False):
        c = self.cena
        propriedades = {"position": vetor(*posicao)}
        if graus:
            propriedades["rotation"] = giro(graus)
        if escala is not None:
            propriedades["scale"] = vetor(escala, escala, escala)
        caminho = c.no(nome_do_no, pai=pai, instancia=self._modelo(modelo), propriedades=propriedades)
        if cobre:
            c.no("Cobertura", "Node", pai=caminho, propriedades={
                "script": c.recurso("Script", "res://scripts/world/cobertura_translucida.gd"),
            })
        if maquina:
            c.no("MaquinaAnimada", "Node", pai=caminho, propriedades={
                "script": c.recurso("Script", "res://scripts/combat/maquina_animada.gd"),
                "voltas_por_segundo": "0.6",
            })
        return caminho

    def _montar_sala(self, sala):
        c = self.cena
        dados = sala["dados"]
        numero = sala["indice"] + 1
        grupo = c.no("Sala%d" % numero, "Node3D", pai="Cenario")

        # Piso.
        pisos = dados.get("pisos", self.tema["pisos"])
        for coluna in range(dados["colunas"]):
            for linha in range(dados["linhas"]):
                modelo = pisos["padrao"]
                if "faixa_sul" in pisos and linha == dados["linhas"] - 1:
                    modelo = pisos["faixa_sul"]
                elif "xadrez" in pisos and (coluna + linha) % pisos.get("passo_do_xadrez", 3) == 0:
                    modelo = pisos["xadrez"]
                posicao = self.ponto(sala, coluna * PLACA + 1.0, linha * PLACA + 1.0, ALTURA_DO_PISO)
                self._peca("Piso", modelo, posicao, pai=grupo)

        # Parede alta ao norte, mureta ao sul.
        for coluna in range(dados["colunas"]):
            u = coluna * PLACA + 1.0
            self._peca("ParedeNorte", self.tema["parede"], self.ponto(sala, u, -METADE_DA_PAREDE), pai=grupo)
            self._peca("MuretaSul", self.tema["mureta"], (sala["oeste"] + u, 0.0, sala["sul"] + METADE_DA_PAREDE),
                       graus=180.0, pai=grupo)

        # Decoração.
        for item in dados.get("decoracao", []):
            modelo, u, v = item[0], item[1], item[2]
            graus = item[3] if len(item) > 3 else 0.0
            marcas = item[4] if len(item) > 4 else ""
            escala = item[5] if len(item) > 5 else None
            nome = modelo.split("/")[-1].replace(".glb", "")
            self._peca(nome, modelo, self.ponto(sala, u, v), graus=graus, pai=grupo, escala=escala,
                       cobre="cobre" in marcas, maquina="gira" in marcas)

        # Luzes.
        for indice, (u, v, nome_da_cor) in enumerate(dados.get("luzes", [])):
            c.no("Luz", "OmniLight3D", pai=grupo, propriedades={
                "position": vetor(*self.ponto(sala, u, v, 2.4)),
                "light_color": cor(*self.tema["luzes"][nome_da_cor]),
                "light_energy": "0.8",
                "omni_range": "8.0",
                "shadow_enabled": "false",
            })

        # A sala em si, com os pontos de inimigo dentro dela.
        propriedades = {
            "script": c.recurso("Script", "res://scripts/coop/sala_de_dungeon.gd"),
            "nome_exibido": '"%s"' % dados["nome"],
        }
        if sala["indice"] == 0:
            propriedades["comeca_ativa"] = "true"
        sala["caminho"] = c.no("Sala%d" % numero, "Node3D", propriedades=propriedades)
        for perfil, u, v in dados.get("inimigos", []):
            pasta = CHEFES if perfil.startswith("chefe:") else INIMIGOS
            arquivo = perfil.replace("chefe:", "")
            c.no("Ponto", "Marker3D", pai=sala["caminho"], propriedades={
                "position": vetor(*self.ponto(sala, u, v, ALTURA_DO_PONTO_DE_INIMIGO)),
                "script": c.recurso("Script", "res://scripts/coop/ponto_de_inimigo.gd"),
                "perfil": c.recurso("Resource", pasta + arquivo + ".tres"),
            })
        if "bau" in dados:
            u, v = dados["bau"]
            c.no("BauDeRecompensa", pai=".", instancia="res://scenes/coop/bau_de_recompensa.tscn", propriedades={
                "position": vetor(*self.ponto(sala, u, v)),
            })

    def _montar_divisa(self, sala_a, sala_b):
        """A parede entre duas salas, com a porta no meio do trecho que as duas dividem."""
        x = sala_a["leste"]
        norte = min(sala_a["norte"], sala_b["norte"])
        sul = max(sala_a["sul"], sala_b["sul"])
        norte_comum = max(sala_a["norte"], sala_b["norte"])
        sul_comum = min(sala_a["sul"], sala_b["sul"])
        placas_em_comum = int(round((sul_comum - norte_comum) / PLACA))
        z_da_porta = norte_comum + (placas_em_comum // 2) * PLACA + 1.0
        sala_a["porta_leste"] = z_da_porta

        z = norte + 1.0
        while z < sul:
            if abs(z - z_da_porta) < 0.01:
                self._peca("MolduraDePorta", "moldura_de_porta", (x, 0.0, z), graus=90.0)
                nome = "Porta%d" % (sala_a["indice"] + 1)
                self.cena.no(nome, pai="Portas", instancia="res://scenes/coop/porta_de_dungeon.tscn", propriedades={
                    "position": vetor(x, 0.0, z),
                    "rotation": giro(90.0),
                })
                sala_a["porta"] = "Portas/" + nome
            else:
                self._peca("ParedeDivisa", self.tema["parede"], (x, 0.0, z), graus=90.0)
            z += PLACA
        self._peca("Pilar", self.tema["pilar"], (x, 0.0, norte - METADE_DA_PAREDE))

    def _montar_pontas(self):
        """A parede do oeste da primeira sala e a do leste da última."""
        primeira = self.salas[0]
        ultima = self.salas[-1]
        for sala, x in ((primeira, primeira["oeste"] - METADE_DA_PAREDE), (ultima, ultima["leste"] + METADE_DA_PAREDE)):
            z = sala["norte"] + 1.0
            while z < sala["sul"]:
                self._peca("ParedeDaPonta", self.tema["parede"], (x, 0.0, z), graus=90.0)
                z += PLACA
            self._peca("Pilar", self.tema["pilar"], (x, 0.0, sala["norte"] - METADE_DA_PAREDE))

    def _ligar_salas(self):
        """Cada sala abre a porta do leste e acorda a sala seguinte quando fica limpa."""
        for indice, sala in enumerate(self.salas[:-1]):
            proxima = self.salas[indice + 1]
            linhas = self.cena.nos
            for posicao, texto in enumerate(linhas):
                if texto.startswith('[node name="Sala%d" type="Node3D" parent="."]' % (indice + 1)):
                    linhas[posicao] = texto + (
                        '\nportas = Array[NodePath]([NodePath("../%s")])' % sala["porta"]
                        + '\nproximas_salas = Array[NodePath]([NodePath("../%s")])' % proxima["caminho"]
                    )

    def _montar_objetivo(self):
        c = self.cena
        objetivo = self.d["objetivo"]
        propriedades = {"script": c.recurso("Script", "res://scripts/coop/objetivos/%s.gd" % objetivo["script"])}
        for chave, valor in objetivo.get("propriedades", {}).items():
            propriedades[chave] = valor
        if "sala_defendida" in objetivo:
            propriedades["caminho_da_sala"] = 'NodePath("../Sala%d")' % objetivo["sala_defendida"]
        caminho = c.no("Objetivo", "Node3D", propriedades=propriedades)
        for numero_da_sala, u, v in objetivo["alvos"]:
            sala = self.salas[numero_da_sala - 1]
            c.no("Alvo", pai=caminho, instancia="res://scenes/coop/objetivos/%s.tscn" % objetivo["cena_do_alvo"],
                 propriedades={"position": vetor(*self.ponto(sala, u, v))})

    def _montar_entrada_e_saida(self):
        c = self.cena
        primeira = self.salas[0]
        meio = (primeira["sul"] - primeira["norte"]) / 2.0
        c.no("Entrada", "Marker3D", propriedades={"position": vetor(*self.ponto(primeira, 3.0, meio))})
        c.no("Saida", instancia="res://scenes/world/portal.tscn", propriedades={
            "position": vetor(*self.ponto(primeira, 1.2, meio)),
            "funcao": "1",
        })

    def _montar_navegacao(self):
        c = self.cena
        nome = self.d["arquivo"]
        arquivo = "res://resources/navigation/%s.tres" % nome
        oeste = self.salas[0]["oeste"]
        leste = self.salas[-1]["leste"]
        norte = min(sala["norte"] for sala in self.salas)
        sul = max(sala["sul"] for sala in self.salas)
        propriedades = {}
        if (PASTA_DAS_MALHAS / (nome + ".tres")).exists():
            propriedades["navigation_mesh"] = c.recurso("NavigationMesh", arquivo)
        propriedades["script"] = c.recurso("Script", "res://scripts/world/regiao_de_navegacao.gd")
        propriedades["arquivo_da_malha"] = '"%s"' % arquivo
        propriedades["limite_do_chao"] = "Rect2(%s, %s, %s, %s)" % (oeste, norte, leste - oeste, sul - norte)
        c.no("RegiaoDeNavegacao", "NavigationRegion3D", propriedades=propriedades)


# -- as três dungeons ---------------------------------------------------------------

NATUREZA = MODELOS + "kenney_nature_kit/"
INDUSTRIAL = MODELOS + "kenney_city_kit_industrial/"

GALERIA = {
    "arquivo": "dungeon_galeria",
    "tema": {
        "pisos": {"padrao": "chao_concreto_placa", "xadrez": "chao_grade", "passo_do_xadrez": 4,
                  "faixa_sul": "chao_faixa_de_aviso"},
        "parede": "parede_concreto", "mureta": "parede_concreto_baixa", "pilar": "parede_pilar",
        "luzes": {"ambar": (1.0, 0.75, 0.4), "azul": (0.45, 0.7, 1.0), "magenta": (0.95, 0.45, 0.95)},
    },
    "salas": [
        {
            "nome": "Casa de bombas", "colunas": 5, "linhas": 4, "desvio": 0,
            "inimigos": [("rato_de_sucata", 6.5, 2.5), ("rato_de_sucata", 8.0, 5.5), ("drone_de_solda", 7.5, 4.0)],
            "decoracao": [
                ("tubo_reto", 1.0, 0.05), ("tubo_descida", 3.0, 0.05), ("painel_eletrico", 5.0, 0.05),
                ("luminaria_de_tunel", 7.0, 0.05), ("tubo_duplo", 9.0, 0.05),
                ("barril", 0.6, 1.0), ("barril_de_aviso", 1.1, 1.3), ("caixote_de_metal", 9.2, 1.0, 20),
                ("valvula", 4.0, 1.2),
            ],
            "luzes": [(3.0, 3.0, "ambar"), (8.0, 4.0, "azul")],
        },
        {
            "nome": "Corredor dos tanques", "colunas": 6, "linhas": 5, "desvio": 1,
            "inimigos": [("drone_de_solda", 4.0, 3.0), ("drone_de_solda", 8.0, 2.5), ("rato_de_sucata", 6.0, 6.5),
                         ("rato_de_sucata", 9.5, 7.0), ("rato_de_sucata", 3.0, 7.5)],
            "decoracao": [
                ("tanque_de_pressao", 3.0, 1.3), ("tanque_de_pressao", 8.5, 1.3),
                ("luminaria_de_tunel", 5.8, 0.05), ("tubo_reto", 11.0, 0.05),
                ("tubo_coluna", 6.0, 5.0, 0, "cobre"),
                ("barril", 11.2, 1.2), ("barril", 11.3, 1.8), ("valvula", 0.8, 3.0),
                ("caixote_de_metal", 0.8, 8.6, 10),
            ],
            "luzes": [(3.0, 4.0, "azul"), (9.0, 5.0, "ambar")],
        },
        {
            "nome": "Depósito de limpeza", "colunas": 6, "linhas": 6, "desvio": 0,
            "pisos": {"padrao": "chao_metal_placa", "faixa_sul": "chao_faixa_de_aviso"},
            "inimigos": [("chefe:zelador", 7.0, 5.0), ("rato_de_sucata", 9.5, 3.0), ("rato_de_sucata", 9.5, 8.5)],
            "decoracao": [
                ("ventilador_de_parede", 3.0, 0.05, 0, "gira"), ("ventilador_de_parede", 9.0, 0.05, 0, "gira"),
                ("painel_eletrico", 6.0, 0.05), ("barril_de_aviso", 0.7, 1.0), ("barril_de_aviso", 0.7, 1.6),
                ("caixote_de_metal", 11.2, 1.0), ("caixote_de_metal", 11.2, 1.6, 15),
                ("tubo_coluna", 2.0, 6.0, 0, "cobre"), ("tubo_coluna", 10.0, 6.0, 0, "cobre"),
            ],
            "luzes": [(6.0, 5.0, "ambar"), (6.0, 9.0, "magenta")],
        },
        {
            "nome": "Pátio de contêineres", "colunas": 7, "linhas": 5, "desvio": -1,
            "inimigos": [("drone_de_solda", 4.0, 3.5), ("drone_de_solda", 10.0, 3.0), ("drone_de_solda", 7.0, 6.5),
                         ("rato_de_sucata", 3.0, 7.0), ("rato_de_sucata", 11.0, 7.5), ("rato_de_sucata", 7.0, 2.5)],
            "decoracao": [
                ("conteiner_de_manutencao", 2.5, 1.2, 90), ("conteiner_de_manutencao", 7.0, 1.2, 90),
                (INDUSTRIAL + "shipping_container_c.glb", 11.5, 1.3, 90, "", 3.0),
                ("luminaria_de_tunel", 5.0, 0.05), ("luminaria_de_tunel", 9.5, 0.05),
                ("barril", 13.2, 2.6), ("caixote_de_metal", 0.8, 3.0), ("valvula", 13.0, 8.5),
                ("tubo_coluna", 7.0, 5.0, 0, "cobre"),
            ],
            "luzes": [(4.0, 5.0, "azul"), (10.0, 5.0, "ambar")],
        },
        {
            "nome": "Câmara da prensa", "colunas": 8, "linhas": 7, "desvio": 0,
            "pisos": {"padrao": "chao_metal_placa", "xadrez": "chao_grade", "passo_do_xadrez": 5,
                      "faixa_sul": "chao_faixa_de_aviso"},
            "inimigos": [("chefe:compactador", 10.0, 6.0)],
            "decoracao": [
                ("ventilador_de_parede", 4.0, 0.05, 0, "gira"), ("ventilador_de_parede", 12.0, 0.05, 0, "gira"),
                ("tubo_duplo", 8.0, 0.05), ("painel_eletrico", 1.2, 0.05), ("painel_eletrico", 14.8, 0.05),
                (INDUSTRIAL + "chimney_medium.glb", 0.9, 1.0, 0, "", 1.3),
                (INDUSTRIAL + "chimney_medium.glb", 15.1, 1.0, 0, "", 1.3),
                ("barril_de_aviso", 2.2, 1.0), ("barril_de_aviso", 13.8, 1.0),
                ("tanque_de_pressao", 8.0, 1.3),
            ],
            "luzes": [(4.0, 5.0, "ambar"), (12.0, 5.0, "magenta"), (8.0, 10.0, "ambar")],
            "bau": (14.5, 7.0),
        },
    ],
    "objetivo": {
        "script": "objetivo_de_geradores", "cena_do_alvo": "gerador_da_corporacao",
        "alvos": [(2, 10.5, 8.5), (4, 1.2, 8.5), (4, 12.8, 5.5)],
    },
}

BIODOMO = {
    "arquivo": "dungeon_biodomo",
    "tema": {
        "pisos": {"padrao": "chao_grama_placa", "xadrez": "chao_concreto_placa", "passo_do_xadrez": 3},
        "parede": "parede_de_estufa", "mureta": "parede_de_estufa_baixa", "pilar": "parede_pilar",
        "luzes": {"magenta": (0.95, 0.45, 0.95), "verde": (0.55, 1.0, 0.65), "branca": (0.9, 0.95, 1.0)},
    },
    "salas": [
        {
            "nome": "Recepção da estufa", "colunas": 5, "linhas": 4, "desvio": 0,
            "pisos": {"padrao": "chao_concreto_placa", "xadrez": "chao_grama_placa", "passo_do_xadrez": 3},
            "inimigos": [("podador", 6.5, 2.5), ("podador", 8.0, 5.5), ("semeador", 8.8, 1.6)],
            "decoracao": [
                ("bancada_de_mudas", 2.0, 0.6), ("tanque_de_nutrientes", 4.5, 0.8), ("bancada_de_mudas", 7.0, 0.6),
                ("arvore_em_vaso", 0.7, 0.9, 0, "cobre"), ("lampada_de_cultivo", 9.3, 1.0, 0, "cobre"),
                ("enfeite_cipo", 5.0, 5.0, 20), ("aspersor", 3.0, 6.5),
            ],
            "luzes": [(3.0, 3.0, "branca"), (8.0, 4.0, "magenta")],
        },
        {
            "nome": "Canteiros de hidroponia", "colunas": 6, "linhas": 5, "desvio": -1,
            "pisos": {"padrao": "chao_terra_placa", "xadrez": "chao_grama_placa", "passo_do_xadrez": 2},
            "inimigos": [("podador", 4.0, 3.0), ("podador", 9.0, 6.5), ("semeador", 10.5, 2.0),
                         ("semeador", 2.0, 8.0), ("podador", 6.5, 8.0)],
            "decoracao": [
                ("canteiro_hidroponico", 2.5, 1.0), ("canteiro_hidroponico", 6.0, 1.0), ("canteiro_hidroponico", 9.5, 1.0),
                ("canteiro_hidroponico", 4.0, 5.0), ("canteiro_hidroponico", 8.0, 5.0),
                ("lampada_de_cultivo", 0.7, 1.0, 0, "cobre"), ("lampada_de_cultivo", 11.3, 1.0, 0, "cobre"),
                ("aspersor", 6.0, 3.0), ("enfeite_cipo", 9.0, 8.5, -30),
                (NATUREZA + "plant_bush_large.glb", 0.8, 8.8, 0, "", 1.6),
            ],
            "luzes": [(3.0, 4.0, "magenta"), (9.0, 5.0, "verde")],
        },
        {
            "nome": "Laboratório de enxertos", "colunas": 6, "linhas": 6, "desvio": 0,
            "pisos": {"padrao": "chao_concreto_placa", "xadrez": "chao_terra_placa", "passo_do_xadrez": 4},
            "inimigos": [("chefe:enxertador", 7.0, 5.5), ("semeador", 10.5, 2.0), ("semeador", 10.5, 9.5)],
            "decoracao": [
                ("bancada_de_mudas", 2.5, 0.6), ("tanque_de_nutrientes", 5.0, 0.8), ("tanque_de_nutrientes", 6.6, 0.8),
                ("bancada_de_mudas", 9.5, 0.6),
                ("arvore_em_vaso", 1.5, 5.5, 0, "cobre"), ("arvore_em_vaso", 10.5, 6.0, 40, "cobre"),
                ("enfeite_cipo", 6.0, 9.5), ("enfeite_cipo", 3.0, 3.0, 70),
            ],
            "luzes": [(6.0, 4.0, "magenta"), (6.0, 9.0, "branca")],
        },
        {
            "nome": "Bosque que escapou", "colunas": 7, "linhas": 5, "desvio": 1,
            "inimigos": [("podador", 4.0, 3.5), ("podador", 10.0, 3.0), ("podador", 7.0, 7.0),
                         ("semeador", 12.5, 1.8), ("semeador", 1.5, 8.0), ("podador", 11.0, 7.5)],
            "decoracao": [
                ("arvore_que_rompeu_o_piso", 3.0, 1.6, 0, "cobre"), ("arvore_que_rompeu_o_piso", 8.5, 1.4, 60, "cobre"),
                ("arvore_que_rompeu_o_piso", 6.0, 5.0, 120, "cobre"),
                ("conteiner_tomado_pelo_mato", 12.0, 1.2, 90),
                (NATUREZA + "plant_bush_large.glb", 0.8, 1.0, 0, "", 1.6),
                (NATUREZA + "tree_pine_round_a.glb", 5.6, 0.9, 0, "cobre", 1.3),
                (NATUREZA + "rock_large_a.glb", 10.5, 5.5, 30, "", 1.4),
                (NATUREZA + "mushroom_red_group.glb", 2.0, 6.0, 0, "", 1.5),
                (NATUREZA + "flower_purple_a.glb", 9.0, 8.0, 0, "", 1.5),
                ("enfeite_cipo", 4.0, 8.5, 10), ("enfeite_cipo", 11.0, 3.5, -50),
            ],
            "luzes": [(4.0, 5.0, "verde"), (10.0, 5.0, "magenta")],
        },
        {
            "nome": "Campo de colheita", "colunas": 8, "linhas": 7, "desvio": 0,
            "pisos": {"padrao": "chao_terra_placa", "xadrez": "chao_grama_placa", "passo_do_xadrez": 5},
            "inimigos": [("chefe:colheitadeira", 10.0, 6.0)],
            "decoracao": [
                ("tanque_de_nutrientes", 1.0, 0.8), ("tanque_de_nutrientes", 15.0, 0.8),
                ("canteiro_hidroponico", 4.0, 1.0), ("canteiro_hidroponico", 8.0, 1.0), ("canteiro_hidroponico", 12.0, 1.0),
                ("lampada_de_cultivo", 6.0, 1.0, 0, "cobre"), ("lampada_de_cultivo", 10.0, 1.0, 0, "cobre"),
                (NATUREZA + "crops_corn_stage_d.glb", 0.8, 3.0, 0, "", 1.6),
                (NATUREZA + "crops_corn_stage_d.glb", 0.8, 4.2, 0, "", 1.6),
                (NATUREZA + "crops_corn_stage_d.glb", 15.2, 3.0, 0, "", 1.6),
                (NATUREZA + "crops_corn_stage_d.glb", 15.2, 4.2, 0, "", 1.6),
                ("enfeite_cipo", 3.0, 12.5), ("enfeite_cipo", 12.0, 12.8, 180),
            ],
            "luzes": [(4.0, 5.0, "magenta"), (12.0, 5.0, "verde"), (8.0, 10.0, "branca")],
            "bau": (14.5, 7.0),
        },
    ],
    "objetivo": {
        "script": "objetivo_de_resgate", "cena_do_alvo": "peca_de_resgate",
        "propriedades": {"nome_das_pecas": '"Sementes resgatadas"'},
        "alvos": [(1, 0.8, 7.2), (2, 11.2, 9.0), (3, 0.8, 11.0), (4, 13.2, 8.8)],
    },
}

TORRE = {
    "arquivo": "dungeon_torre",
    "tema": {
        "pisos": {"padrao": "chao_tecnologico_placa", "xadrez": "chao_tecnologico_circuito", "passo_do_xadrez": 3},
        "parede": "parede_tecnologica", "mureta": "parede_tecnologica_baixa", "pilar": "parede_pilar",
        "luzes": {"magenta": (0.95, 0.45, 0.95), "ciano": (0.4, 0.9, 1.0), "roxo": (0.66, 0.47, 0.95)},
    },
    "salas": [
        {
            "nome": "Saguão de acesso", "colunas": 5, "linhas": 4, "desvio": 0,
            "inimigos": [("guarda_blindado", 7.0, 4.0), ("olho_de_vigia", 8.5, 2.0), ("olho_de_vigia", 8.5, 6.0)],
            "decoracao": [
                ("painel_neon", 2.5, 0.05), ("terminal", 5.0, 0.7), ("painel_neon", 7.5, 0.05),
                ("rack_de_servidor_baixo", 0.8, 1.0), ("bateria_de_reserva", 9.0, 0.9),
                ("enfeite_cabos", 4.0, 5.0, 15),
            ],
            "luzes": [(3.0, 3.0, "ciano"), (8.0, 4.0, "magenta")],
        },
        {
            "nome": "Sala dos servidores", "colunas": 6, "linhas": 5, "desvio": 1,
            "inimigos": [("guarda_blindado", 4.0, 5.0), ("guarda_blindado", 9.0, 5.0), ("olho_de_vigia", 6.0, 2.5),
                         ("olho_de_vigia", 10.5, 8.0), ("olho_de_vigia", 2.0, 8.0)],
            "decoracao": [
                ("rack_de_servidor", 1.0, 0.7), ("rack_de_servidor", 1.9, 0.7), ("rack_de_servidor", 2.8, 0.7),
                ("rack_de_servidor", 5.0, 0.7), ("rack_de_servidor", 5.9, 0.7), ("rack_de_servidor", 6.8, 0.7),
                ("rack_de_servidor", 9.2, 0.7), ("rack_de_servidor", 10.1, 0.7), ("rack_de_servidor", 11.0, 0.7),
                ("rack_de_servidor", 3.0, 5.0, 0, "cobre"), ("rack_de_servidor", 3.9, 5.0, 0, "cobre"),
                ("rack_de_servidor", 8.0, 5.0, 0, "cobre"), ("rack_de_servidor", 8.9, 5.0, 0, "cobre"),
                ("enfeite_cabos", 6.0, 3.5), ("enfeite_cabos", 6.0, 8.0, 180),
                ("torre_de_resfriamento", 0.9, 8.8, 0, "gira"),
            ],
            "luzes": [(3.0, 3.0, "ciano"), (9.0, 7.0, "roxo")],
        },
        {
            "nome": "Câmara do firewall", "colunas": 6, "linhas": 6, "desvio": 0,
            "pisos": {"padrao": "chao_tecnologico_circuito", "xadrez": "chao_tecnologico_placa", "passo_do_xadrez": 2},
            "inimigos": [("chefe:firewall", 7.0, 5.5), ("olho_de_vigia", 10.0, 2.5), ("olho_de_vigia", 10.0, 9.5)],
            "decoracao": [
                ("painel_neon", 3.0, 0.05), ("painel_neon", 9.0, 0.05), ("terminal", 6.0, 0.7),
                ("rack_de_servidor_baixo", 0.8, 1.0), ("rack_de_servidor_baixo", 11.2, 1.0),
                ("torre_de_resfriamento", 0.9, 10.8, 0, "gira"), ("torre_de_resfriamento", 11.1, 10.8, 0, "gira"),
                ("bateria_de_reserva", 1.0, 5.5, 90), ("bateria_de_reserva", 11.0, 5.5, 90),
            ],
            "luzes": [(6.0, 4.0, "ciano"), (6.0, 9.0, "magenta")],
        },
        {
            "nome": "Terraço da antena", "colunas": 7, "linhas": 5, "desvio": -1,
            "inimigos": [("guarda_blindado", 3.0, 3.0), ("guarda_blindado", 11.0, 3.0), ("guarda_blindado", 7.0, 8.0),
                         ("olho_de_vigia", 2.0, 8.0), ("olho_de_vigia", 12.0, 8.0), ("olho_de_vigia", 7.0, 2.0)],
            "decoracao": [
                ("predio_de_fundo", 3.0, -4.5), ("predio_de_fundo", 11.0, -5.5, 0, "", 1.2),
                ("painel_neon", 7.0, 0.05), ("terminal", 1.5, 0.7), ("terminal", 12.5, 0.7),
                ("bateria_de_reserva", 4.0, 0.9), ("bateria_de_reserva", 10.0, 0.9),
                ("enfeite_cabos", 5.5, 4.5, 30), ("enfeite_cabos", 8.5, 5.5, 200),
                ("rack_de_servidor_baixo", 0.8, 8.8), ("torre_de_resfriamento", 13.1, 8.8, 0, "gira"),
            ],
            "luzes": [(4.0, 5.0, "magenta"), (10.0, 5.0, "ciano")],
        },
        {
            "nome": "Sala do conselho", "colunas": 8, "linhas": 7, "desvio": 0,
            "pisos": {"padrao": "chao_tecnologico_placa", "xadrez": "chao_tecnologico_circuito", "passo_do_xadrez": 2},
            "inimigos": [("chefe:auditor", 10.0, 6.0)],
            "decoracao": [
                ("painel_neon", 3.0, 0.05), ("painel_neon", 8.0, 0.05), ("painel_neon", 13.0, 0.05),
                ("rack_de_servidor", 0.8, 0.7), ("rack_de_servidor", 1.7, 0.7),
                ("rack_de_servidor", 14.3, 0.7), ("rack_de_servidor", 15.2, 0.7),
                ("terminal", 5.5, 0.7), ("terminal", 10.5, 0.7),
                ("predio_de_fundo", 8.0, -5.0, 0, "", 1.3),
                ("torre_de_resfriamento", 0.9, 12.8, 0, "gira"), ("torre_de_resfriamento", 15.1, 12.8, 0, "gira"),
                ("enfeite_cabos", 4.0, 3.0), ("enfeite_cabos", 12.0, 3.0, 180),
            ],
            "luzes": [(4.0, 5.0, "magenta"), (12.0, 5.0, "ciano"), (8.0, 10.0, "roxo")],
            "bau": (14.5, 7.0),
        },
    ],
    "objetivo": {
        "script": "objetivo_de_defesa", "cena_do_alvo": "ponto_de_defesa",
        "propriedades": {"nome_do_ponto": '"Antena"'},
        "sala_defendida": 4,
        "alvos": [(4, 7.0, 5.0)],
    },
}

DUNGEONS = [GALERIA, BIODOMO, TORRE]


def main():
    for descricao in DUNGEONS:
        texto = Montador(descricao).montar()
        caminho = PASTA_DAS_CENAS / (descricao["arquivo"] + ".tscn")
        caminho.write_text(texto, encoding="utf-8")
        print("gravado", caminho.relative_to(RAIZ), "com", texto.count("[node "), "nos")


if __name__ == "__main__":
    main()
