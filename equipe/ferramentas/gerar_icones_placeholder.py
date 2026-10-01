#!/usr/bin/env python3
"""Gera os ícones placeholder 16x16 dos itens que ainda não têm arte.

Só as seis colheitas têm ícone de verdade, em assets/textures/tiny_farm_crops/. O resto
do catálogo do plano 03 precisa de alguma imagem, porque o ícone é o que aparece girando
no chão. Este script desenha um ícone simples por item: uma forma por tipo de coisa
(saco de semente, engrenagem, pedra, frasco) e uma paleta de cores por item, com
contorno escuro de 1 pixel para o ícone ler em cima do chão turquesa.

A tabela ITENS é a fonte da verdade dos ids. Para trocar um placeholder por arte de
verdade, basta apontar outro PNG no .tres do item; não é preciso mexer aqui.

Uso, a partir da raiz do repositório:

    ./equipe/ferramentas/gerar_icones_placeholder.py

Opções:

    --destino PASTA   grava em outra pasta (padrão: game/assets/textures/icones_itens)
    --previa ARQUIVO  grava também uma folha com todos os ícones ampliados 8 vezes
                      sobre o turquesa do chão, para conferir de olho

Não depende de biblioteca externa, só da biblioteca padrão do Python.
"""

import argparse
import struct
import zlib
from pathlib import Path

TAMANHO = 16
COR_CONTORNO = (25, 22, 35)
COR_FUNDO_PREVIA = (64, 200, 190)
RAIZ_DO_REPOSITORIO = Path(__file__).resolve().parents[2]
DESTINO_PADRAO = RAIZ_DO_REPOSITORIO / "game" / "assets" / "textures" / "icones_itens"

# Cada forma é uma grade 16x16. Ponto é transparente, e cada letra é um papel de cor
# que a paleta do item preenche: "a" cor base, "b" luz, "c" sombra, "d" e "e" detalhes.
# A borda de 1 pixel fica livre para caber o contorno, que é calculado depois.
FORMAS = {
    "saco_de_semente": [
        "................",
        "................",
        ".....cc..cc.....",
        "......cbbc......",
        ".......aa.......",
        "......aaaa......",
        ".....aaaaaa.....",
        "....abaaaaaa....",
        "....abddddaa....",
        "...abaddddaac...",
        "...abaddddaac...",
        "...abaaaaaaac...",
        "....aaaaaaacc...",
        ".....cccccc.....",
        "................",
        "................",
    ],
    "engrenagem": [
        "................",
        "................",
        ".......aa.......",
        "...aa.aaaa.aa...",
        "...aaaaaaaaaa...",
        "....aabbbbaa....",
        "..aaabc..cbaaa..",
        "..aaab....baaa..",
        "..aaab....baaa..",
        "..aaabc..cbaaa..",
        "....aabbbbaa....",
        "...aaaaaaaaaa...",
        "...aa.aaaa.aa...",
        ".......aa.......",
        "................",
        "................",
    ],
    "placa": [
        "................",
        "................",
        "................",
        "..aaaaaaaaaaaa..",
        "..abbbabaaadda..",
        "..aaabaaabadda..",
        "..abbbaeeaaaaa..",
        "..abaaaeeabbba..",
        "..abaccaaaabaa..",
        "..aaacccaaabaa..",
        "..abbbccbbbbaa..",
        "..aaaaaaaaaaaa..",
        "...d.d.d.d.d....",
        "................",
        "................",
        "................",
    ],
    "bateria": [
        "................",
        "......cccc......",
        ".....aaaaaa.....",
        "....abbbbbbc....",
        "....abddddac....",
        "....abddddac....",
        "....abddddac....",
        "....abeeeeac....",
        "....abeeeeac....",
        "....abeeeeac....",
        "....abeeeeac....",
        "....abeeeeac....",
        "....abbbbbac....",
        ".....cccccc.....",
        "................",
        "................",
    ],
    "bobina": [
        "................",
        "................",
        ".....aaaaaa.....",
        "...aabbbbbbaa...",
        "..abb......bba..",
        "..ab..aaaa..ba..",
        ".ab..ab..ba..ba.",
        ".ab.ab....ba.ba.",
        ".ab.ab....ba.ba.",
        ".ab..ab..ba..ba.",
        "..ab..aaaa..ba..",
        "..abb......bbd..",
        "...aabbbbbbaad..",
        ".....aaaaaa..d..",
        "............ee..",
        "................",
    ],
    "motor": [
        "................",
        "................",
        ".......cc.......",
        ".......cc.......",
        "...aaaaaaaaaa...",
        "...abbbbbbbbac..",
        "...abdddddddac..",
        "...abdeeeeedac..",
        "...abdeeeeedac..",
        "...abdddddddac..",
        "...abbbbbbbbac..",
        "...aaaaaaaaaac..",
        "....c......c....",
        "....c......c....",
        "................",
        "................",
    ],
    "cristal": [
        "................",
        ".......b........",
        "......bba.......",
        ".....bbaaa......",
        "....bbaaaac.....",
        "...bbaadaaac....",
        "..bbaaddeaaac...",
        "..baaadeeaaacc..",
        "..caaaddeaaacc..",
        "...caaadaaacc...",
        "....caaaaacc....",
        ".....caaacc.....",
        "......cacc......",
        ".......cc.......",
        "................",
        "................",
    ],
    "tora": [
        "................",
        "................",
        "................",
        "................",
        "..aaaaaaaaaddd..",
        ".abbbbbbbbdeed..",
        ".aaaaaaaaadeed..",
        ".acccaaaccdeed..",
        ".aaaaaaaaadeed..",
        ".acaacccaadeed..",
        ".aaaaaaaaadeed..",
        "..cccccccccddd..",
        "................",
        "................",
        "................",
        "................",
    ],
    "pedra": [
        "................",
        "................",
        "................",
        "................",
        "......aaaa......",
        "....aabbbaaa....",
        "...abbaaaaaac...",
        "..abaaadaaaaac..",
        "..abaaaaaadaac..",
        ".abaadaaaaaaacc.",
        ".aaaaaaadaaaacc.",
        ".caaaaaaaaaaccc.",
        "..cccccccccccc..",
        "................",
        "................",
        "................",
    ],
    "feixe": [
        "................",
        ".....a.aa.a.....",
        "....abaabbab....",
        "....abaabbab....",
        ".....abaabba....",
        ".....abaabba....",
        "......abbba.....",
        ".....dddddd.....",
        "......abbba.....",
        ".....abaabba....",
        ".....abaabba....",
        "....abaabbaba...",
        "....abaabbaba...",
        "...aabaabbaab...",
        "................",
        "................",
    ],
    "saco": [
        "................",
        "................",
        ".....c....c.....",
        "......cccc......",
        "......aaaa......",
        ".....aaaaaa.....",
        "....abaaaaaac...",
        "...abaaaaaaaac..",
        "...abadddddaac..",
        "...abadddddaac..",
        "...abadddddaac..",
        "...abaaaaaaaac..",
        "...aaaaaaaaaac..",
        "....cccccccc....",
        "................",
        "................",
    ],
    "galao": [
        "................",
        "................",
        ".........ccc....",
        ".....aaaaaca....",
        "....abbbbaaa....",
        "....abaaaaaac...",
        "....abaddddac...",
        "....abadeedac...",
        "....abadeedac...",
        "....abaddddac...",
        "....abaaaaaac...",
        "....abaaaaaac...",
        "....aaaaaaaac...",
        ".....cccccccc...",
        "................",
        "................",
    ],
    "chapas": [
        "................",
        "................",
        "................",
        "................",
        "...bbbbbbbbbb...",
        "..baaaaaaaaaac..",
        "..cccccccccccc..",
        "...bbbbbbbbbb...",
        "..baaaaaaaaaac..",
        "..cccccccccccc..",
        "...bbbbbbbbbb...",
        "..baaadaaaaaac..",
        "..cccccccccccc..",
        "................",
        "................",
        "................",
    ],
    "pao": [
        "................",
        "................",
        "................",
        "................",
        ".....bbbbbb.....",
        "...bbaaaaaabb...",
        "..baadaadaadaa..",
        "..baaadaadaada..",
        ".baaaaaaaaaaaac.",
        ".aaaaaaaaaaaaac.",
        ".caaaaaaaaaaacc.",
        "..cccccccccccc..",
        "................",
        "................",
        "................",
        "................",
    ],
    "tigela": [
        "................",
        "................",
        "................",
        "................",
        "................",
        "..dddddddddddd..",
        ".adeddedddedda..",
        ".abddddddddddac.",
        ".abaaaaaaaaaaac.",
        "..abaaaaaaaaac..",
        "..abaaaaaaaaac..",
        "...abaaaaaaac...",
        "....aaaaaaac....",
        ".....cccccc.....",
        "................",
        "................",
    ],
    "frasco": [
        "................",
        ".....cccccc.....",
        "......cccc......",
        "......abba......",
        "......abda......",
        ".....abddda.....",
        "....abddddda....",
        "...abdddddddc...",
        "...abdeddddec...",
        "...abdddedddc...",
        "...abddddeddc...",
        "...abdddddddc...",
        "....aaaaaaac....",
        ".....cccccc.....",
        "................",
        "................",
    ],
    "buque": [
        "................",
        ".....dd.ee......",
        "....dddeeee.....",
        "...ddddeeedd....",
        "...eeeddddddd...",
        "....eeeddeee....",
        ".....ddeeee.....",
        "......abba......",
        "......abba......",
        ".....cccccc.....",
        "......abba......",
        "......abba......",
        ".......bb.......",
        "................",
        "................",
        "................",
    ],
    "moeda": [
        "................",
        "................",
        ".....aaaaaa.....",
        "....abbbbbba....",
        "...abbaaaacba...",
        "..abbaaddaacba..",
        "..abaaddddaaca..",
        "..abaaaddaaaca..",
        "..abaaaddaaaca..",
        "..abaaddddaaca..",
        "..abcaaddaacca..",
        "...acccaaccca...",
        "....accccca.....",
        ".....aaaaaa.....",
        "................",
        "................",
    ],
    "enxada": [
        "................",
        ".aaaaa..........",
        ".abbbac.........",
        "..cccdd.........",
        ".....dd.........",
        "......dd........",
        ".......dd.......",
        "........dd......",
        ".........dd.....",
        "..........dd....",
        "...........dd...",
        "............dd..",
        ".............d..",
        "................",
        "................",
        "................",
    ],
    "regador": [
        "................",
        "................",
        "................",
        ".....cccc.......",
        "....c....c......",
        "...aaaaaaaa..b..",
        "...abbbbbba.ba..",
        "...abaaaaaaaa...",
        "...abaaaaaaa....",
        "...abaaaaaac....",
        "...abaaaaaac....",
        "...aaaaaaaac....",
        "....cccccccc....",
        "................",
        "................",
        "................",
    ],
    "picareta": [
        "................",
        "....aaaaaaa.....",
        "..aabbbbbbbaa...",
        ".ab....dd...ba..",
        ".a.....dd....a..",
        ".......dd.......",
        ".......dd.......",
        ".......dd.......",
        ".......dd.......",
        ".......dd.......",
        ".......dd.......",
        ".......dd.......",
        ".......dd.......",
        "................",
        "................",
        "................",
    ],
    "cestos": [
        "................",
        "................",
        "....aaaaaaa.....",
        "...abbbbbbba....",
        "..aaeaaeaaeaa...",
        "..aaaaaaaaaaaa..",
        "..aacaaaaaaaaaa.",
        "..aaaaaaaaaabaa.",
        "..aaaaaaaaaaaa..",
        "...caaaaaaaac...",
        "...dcdcdcdcdc...",
        "...cdcdcdcdcd...",
        "...dcdcdcdcdc...",
        "....cccccccc....",
        "................",
        "................",
    ],
    "foice": [
        "................",
        "...aaaaaaa......",
        "..abbbbbbbaa....",
        ".abcc....ccba...",
        ".ac.......cba...",
        ".a.........ba...",
        "...........dd...",
        "...........dd...",
        "...........dd...",
        "...........dd...",
        "...........dd...",
        "...........dd...",
        "...........dd...",
        "...........dd...",
        "................",
        "................",
    ],
    "espadao": [
        ".............aa.",
        "............aba.",
        "...........abba.",
        "..........abea..",
        ".........abba...",
        "........aeba....",
        ".......abba.....",
        "......abba......",
        ".....abea.......",
        "..c.abba........",
        "..ccaba.........",
        "...ccc..........",
        "..ddcc..........",
        ".dd..c..........",
        ".d..............",
        "................",
    ],
    "escopeta": [
        "................",
        "................",
        "................",
        "................",
        ".bbbbbbbbbb.....",
        ".aaaaaaaaaadd...",
        ".ccccccccccdddd.",
        ".bbbbbbbbbbbddd.",
        ".aaaaaaaaaa.ddd.",
        ".cccccccccc.ddd.",
        "......e.e...ddd.",
        "......eee...ddd.",
        "............dd..",
        "................",
        "................",
        "................",
    ],
    "bastao_de_choque": [
        "..........e..e..",
        "...........ee...",
        "..........eaae.e",
        ".........abba...",
        "........abba....",
        ".......abba.....",
        "......abba......",
        ".....acca.......",
        "....adda........",
        "...adda.........",
        "..adda..........",
        ".adda...........",
        ".aaa............",
        "................",
        "................",
        "................",
    ],
}


def tons(base):
    """Devolve a cor base, uma versão mais clara (luz) e uma mais escura (sombra)."""
    r, g, b = base
    luz = tuple(min(255, int(c + (255 - c) * 0.45)) for c in base)
    sombra = (int(r * 0.6), int(g * 0.6), int(b * 0.6))
    return {"a": base, "b": luz, "c": sombra}


def paleta(base, d=None, e=None):
    cores = tons(base)
    cores["d"] = d if d is not None else cores["c"]
    cores["e"] = e if e is not None else cores["b"]
    return cores


BEGE_DO_SACO = (200, 170, 120)
MADEIRA_DO_CABO = (150, 100, 55)

# id do item, forma, paleta. A ordem segue as tabelas do plano 03.
ITENS = [
    # Sementes: mesmo saco, e a etiqueta tem a cor da colheita.
    ("semente_beterraba", "saco_de_semente", paleta(BEGE_DO_SACO, d=(150, 30, 70))),
    ("semente_repolho", "saco_de_semente", paleta(BEGE_DO_SACO, d=(110, 185, 75))),
    ("semente_cenoura", "saco_de_semente", paleta(BEGE_DO_SACO, d=(240, 130, 30))),
    ("semente_milho", "saco_de_semente", paleta(BEGE_DO_SACO, d=(245, 210, 60))),
    ("semente_tomate", "saco_de_semente", paleta(BEGE_DO_SACO, d=(215, 45, 40))),
    ("semente_trigo", "saco_de_semente", paleta(BEGE_DO_SACO, d=(185, 135, 30))),
    # Sucata da cidade.
    ("sucata_metal", "engrenagem", paleta((140, 145, 155))),
    ("placa_queimada", "placa", paleta((40, 120, 70), d=(210, 180, 60), e=(30, 30, 35))),
    ("celula_energia", "bateria", paleta((90, 95, 110), d=(35, 35, 45), e=(80, 240, 120))),
    ("fio_optico", "bobina", paleta((60, 170, 230), d=(60, 60, 70), e=(250, 250, 200))),
    ("servomotor", "motor", paleta((200, 120, 40), d=(70, 70, 80), e=(170, 175, 185))),
    ("nucleo_sintetico", "cristal", paleta((180, 70, 220), d=(240, 170, 255), e=(255, 255, 255))),
    # Recursos do campo.
    ("madeira", "tora", paleta((140, 90, 50), d=(95, 60, 30), e=(215, 170, 110))),
    ("pedra", "pedra", paleta((135, 135, 140), d=(105, 105, 110))),
    ("fibra", "feixe", paleta((200, 180, 90), d=(120, 80, 40))),
    ("minerio_cobre", "pedra", paleta((120, 110, 105), d=(230, 120, 60))),
    ("minerio_ferro", "pedra", paleta((110, 110, 120), d=(200, 190, 185))),
    # Materiais processados.
    ("composto_organico", "saco", paleta((110, 80, 50), d=(90, 160, 60))),
    ("biocombustivel", "galao", paleta((60, 150, 70), d=(30, 60, 35), e=(240, 220, 60))),
    ("nutrisolo", "saco", paleta((80, 60, 45), d=(80, 220, 200))),
    ("chapa_reciclada", "chapas", paleta((150, 170, 185), d=(90, 200, 90))),
    # Consumíveis.
    ("pao_de_trigo", "pao", paleta((205, 140, 60), d=(240, 200, 130))),
    ("sopa_de_legumes", "tigela", paleta((170, 110, 70), d=(220, 120, 50), e=(90, 170, 60))),
    ("estimulante", "frasco", paleta((190, 220, 230), d=(250, 200, 40), e=(255, 255, 220))),
    ("nanogel", "frasco", paleta((190, 220, 230), d=(60, 200, 240), e=(220, 255, 255))),
    # Especiais.
    # O buquê escreve a paleta à mão porque a fita ("c") não é sombra do caule.
    ("buque", "buque", {
        "a": (50, 130, 50), "b": (100, 190, 80), "c": (220, 60, 120),
        "d": (240, 90, 140), "e": (250, 230, 90),
    }),
    ("credito", "moeda", paleta((230, 180, 40), d=(150, 100, 20))),
    # Ferramentas: o ferro fica na cor base, o cabo de madeira no detalhe "d".
    ("enxada", "enxada", paleta((170, 175, 185), d=MADEIRA_DO_CABO)),
    ("regador", "regador", paleta((70, 140, 200))),
    ("picareta", "picareta", paleta((160, 165, 175), d=MADEIRA_DO_CABO)),
    # Arma: os cestos são a luva de couro com tiras dos pugilistas antigos, e é o que o
    # jogador usa quando não está com ferramenta na mão. O couro fica na cor base, as
    # tiras do pulso no detalhe "d" e os rebites de metal no "e".
    ("cestos", "cestos", paleta((150, 95, 55), d=(205, 170, 120), e=(205, 210, 220))),
    # Armas do plano 08. O metal fica na cor base e o cabo de madeira no detalhe "d".
    ("foice_curva", "foice", paleta((175, 180, 190), d=MADEIRA_DO_CABO)),
    # O "e" do espadão é o remendo enferrujado na chapa.
    ("espadao_sucata", "espadao", paleta((140, 145, 155), d=MADEIRA_DO_CABO, e=(175, 95, 50))),
    # Escopeta de cano serrado: dois canos curtos empilhados e a coronha curta de madeira.
    ("escopeta_serrada", "escopeta", paleta((105, 110, 122), d=MADEIRA_DO_CABO, e=(60, 62, 70))),
    # No bastão, o "d" é a empunhadura amarela e o "e" é a faísca da ponta.
    ("bastao_choque", "bastao_de_choque", paleta((70, 75, 95), d=(230, 200, 60), e=(110, 240, 250))),
]


def desenhar(forma, cores):
    """Pinta a forma com as cores do item e acrescenta o contorno escuro.

    O contorno ocupa todo pixel transparente que encosta, na horizontal ou na
    vertical, num pixel pintado. Retorna uma lista de linhas de pixels RGBA.
    """
    grade = FORMAS[forma]
    if len(grade) != TAMANHO or any(len(linha) != TAMANHO for linha in grade):
        raise SystemExit(f"a forma '{forma}' não tem {TAMANHO}x{TAMANHO} caracteres")

    pixels = [[None] * TAMANHO for _ in range(TAMANHO)]
    for y, linha in enumerate(grade):
        for x, papel in enumerate(linha):
            if papel != ".":
                pixels[y][x] = cores[papel] + (255,)

    contorno = COR_CONTORNO + (255,)
    for y in range(TAMANHO):
        for x in range(TAMANHO):
            if grade[y][x] != ".":
                continue
            vizinhos = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
            for vx, vy in vizinhos:
                if 0 <= vx < TAMANHO and 0 <= vy < TAMANHO and grade[vy][vx] != ".":
                    pixels[y][x] = contorno
                    break

    transparente = (0, 0, 0, 0)
    return [[p if p is not None else transparente for p in linha] for linha in pixels]


def escrever_png(caminho, linhas):
    """Grava uma imagem RGBA de 8 bits por canal, sem compressão com perda."""
    altura = len(linhas)
    largura = len(linhas[0])
    dados_brutos = bytearray()
    for linha in linhas:
        dados_brutos.append(0)
        for pixel in linha:
            dados_brutos.extend(pixel)

    def bloco(tipo, conteudo):
        corpo = tipo + conteudo
        return struct.pack(">I", len(conteudo)) + corpo + struct.pack(">I", zlib.crc32(corpo))

    cabecalho = struct.pack(">IIBBBBB", largura, altura, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n"
    png += bloco(b"IHDR", cabecalho)
    png += bloco(b"IDAT", zlib.compress(bytes(dados_brutos), 9))
    png += bloco(b"IEND", b"")
    Path(caminho).write_bytes(png)


def montar_previa(icones, escala=8, colunas=6, margem=8):
    """Junta todos os ícones ampliados numa folha sobre o turquesa do chão."""
    lado = TAMANHO * escala
    linhas_da_folha = (len(icones) + colunas - 1) // colunas
    largura = colunas * (lado + margem) + margem
    altura = linhas_da_folha * (lado + margem) + margem
    fundo = COR_FUNDO_PREVIA + (255,)
    folha = [[fundo] * largura for _ in range(altura)]

    for indice, linhas in enumerate(icones):
        origem_x = margem + (indice % colunas) * (lado + margem)
        origem_y = margem + (indice // colunas) * (lado + margem)
        for y in range(lado):
            for x in range(lado):
                pixel = linhas[y // escala][x // escala]
                if pixel[3] > 0:
                    folha[origem_y + y][origem_x + x] = pixel
    return folha


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--destino", type=Path, default=DESTINO_PADRAO)
    parser.add_argument("--previa", type=Path)
    args = parser.parse_args()

    ids = [item_id for item_id, _, _ in ITENS]
    if len(ids) != len(set(ids)):
        raise SystemExit("a tabela ITENS tem id repetido")

    args.destino.mkdir(parents=True, exist_ok=True)
    icones = []
    for item_id, forma, cores in ITENS:
        linhas = desenhar(forma, cores)
        escrever_png(args.destino / f"{item_id}.png", linhas)
        icones.append(linhas)

    print(f"{len(icones)} ícones gravados em {args.destino}")

    if args.previa is not None:
        escrever_png(args.previa, montar_previa(icones))
        print(f"prévia gravada em {args.previa}")


if __name__ == "__main__":
    main()
