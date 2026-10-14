#!/usr/bin/env python3
"""Gera os ícones 16x16 dos troféus dos chefes das dungeons.

Mesmo estilo dos ícones de item: pixel art com contorno escuro de 1 pixel. Cada ícone é
uma grade de letras; ponto é transparente e cada letra é uma cor da tabela CORES.

Uso, a partir da raiz do repositório:

    ./equipe/ferramentas/gerar_icones_de_trofeu.py

Não depende de biblioteca externa, só da biblioteca padrão do Python.
"""

import struct
import zlib
from pathlib import Path

DESTINO = Path(__file__).resolve().parents[2] / "game" / "assets" / "textures" / "icones_itens"

CORES = {
    "#": (25, 22, 35),      # contorno
    "a": (255, 190, 70),    # amarelo
    "A": (255, 225, 140),   # amarelo claro
    "l": (255, 125, 70),    # laranja
    "c": (80, 82, 97),      # chumbo
    "C": (135, 140, 160),   # cinza de metal
    "w": (235, 240, 255),   # branco
    "v": (97, 204, 140),    # verde
    "V": (160, 235, 180),   # verde claro
    "m": (242, 120, 240),   # magenta
    "M": (250, 190, 250),   # magenta claro
    "i": (72, 74, 170),     # índigo
    "b": (210, 232, 255),   # azul claro
}

ICONES = {
    # A placa de prensa: uma chapa amarela com cravos e a faixa de aviso.
    "trofeu_do_compactador": [
        "................",
        "....########....",
        "...#cCCCCCCc#...",
        "...#cCwCCwCc#...",
        "....#cCCCCc#....",
        ".....#cCCc#.....",
        "..############..",
        ".#AAAAAAAAAAAA#.",
        ".#aaaaaaaaaaaa#.",
        ".#a#aa#aa#aa#a#.",
        ".#aaaaaaaaaaaa#.",
        ".#llllllllllll#.",
        "..############..",
        "...#C#.#C#.#C#..",
        "....#...#...#...",
        "................",
    ],
    # A lâmina do molinete: uma lâmina curva branca com o cabo verde.
    "trofeu_da_colheitadeira": [
        "................",
        "..........###...",
        "........##wwC#..",
        "......##wwwC#...",
        ".....#wwwwC#....",
        "....#wwwwC#.....",
        "...#wwwwC#......",
        "...#wwwC#.......",
        "..#wwwC#........",
        "..#wwC##........",
        "..#wC#vV#.......",
        "...##vVv#.......",
        "....#vvv##......",
        ".....##vVv#.....",
        ".......####.....",
        "................",
    ],
    # O crachá: cartão índigo com a marca magenta da corporação e o cordão.
    "trofeu_do_auditor": [
        "................",
        "......#..#......",
        ".....#m##m#.....",
        ".....#m..m#.....",
        "...##########...",
        "..#iiiiiiiiii#..",
        "..#ii##mm##ii#..",
        "..#iiiMmmMiii#..",
        "..#iiimmmmiii#..",
        "..#iimmMMmmii#..",
        "..#iiiiiiiiii#..",
        "..#ibbbbbbbbi#..",
        "..#iiiiiiiiii#..",
        "..#ibbbbbiiii#..",
        "...##########...",
        "................",
    ],
}


def gravar_png(caminho, grade):
    linhas = b""
    for linha in grade:
        linhas += b"\x00"
        for letra in linha:
            if letra == ".":
                linhas += bytes((0, 0, 0, 0))
            else:
                linhas += bytes(CORES[letra]) + b"\xff"

    def bloco(tipo, dados):
        return struct.pack(">I", len(dados)) + tipo + dados + struct.pack(">I", zlib.crc32(tipo + dados) & 0xFFFFFFFF)

    conteudo = b"\x89PNG\r\n\x1a\n"
    conteudo += bloco(b"IHDR", struct.pack(">IIBBBBB", 16, 16, 8, 6, 0, 0, 0))
    conteudo += bloco(b"IDAT", zlib.compress(linhas, 9))
    conteudo += bloco(b"IEND", b"")
    caminho.write_bytes(conteudo)


def main():
    for nome, grade in ICONES.items():
        assert len(grade) == 16 and all(len(linha) == 16 for linha in grade), nome
        gravar_png(DESTINO / (nome + ".png"), grade)
        print("gravado", nome)


if __name__ == "__main__":
    main()
