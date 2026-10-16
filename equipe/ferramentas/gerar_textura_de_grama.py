#!/usr/bin/env python3
"""Desenha a textura da graminha perto do jogador: quatro tufos em pixel art, lado a lado.

Cada tufo é um quadro de 32 por 32, com fundo transparente: folhas finas saindo da base,
cada uma de uma cor da paleta seca (palha, ocre, verde seco), com a ponta mais clara.
O shader `grama_perto.gdshader` escolhe um dos quatro quadros por cópia.

Uso, a partir da raiz do repositório:

    ./equipe/ferramentas/gerar_textura_de_grama.py

Só biblioteca padrão do Python.
"""

import random
import struct
import zlib
from pathlib import Path

DESTINO = Path(__file__).resolve().parents[2] / "game" / "assets" / "textures" / "grama" / "tufos_de_grama.png"
LADO = 32
QUADROS = 4

# Tons de capim seco (base escura, meio, ponta clara). Nenhum chega perto do branco.
PALETAS = [
    [(150, 110, 52), (196, 150, 70), (224, 186, 104)],   # palha
    [(132, 92, 46), (176, 124, 60), (206, 160, 88)],     # ocre
    [(104, 112, 52), (142, 150, 70), (178, 180, 96)],    # verde seco
    [(162, 118, 58), (204, 166, 84), (230, 196, 120)],   # palha clara
]


def desenhar_tufo(pixels, inicio_x, sorteio, paleta):
    folhas = sorteio.randint(11, 15)
    for _ in range(folhas):
        base_x = inicio_x + sorteio.randint(8, 23)
        altura = sorteio.randint(12, 28)
        inclinacao = sorteio.uniform(-0.45, 0.45)
        tom = sorteio.choice(paleta[:2])
        for passo in range(altura):
            y = LADO - 1 - passo
            x = int(round(base_x + inclinacao * passo + (passo * passo) * inclinacao * 0.015))
            if not inicio_x <= x < inicio_x + LADO:
                break
            fracao = passo / altura
            cor = paleta[2] if fracao > 0.78 else (tom if fracao > 0.25 else paleta[0])
            pixels[y][x] = cor
            # A base é mais grossa: dois pixels nos primeiros passos.
            if fracao < 0.35 and inicio_x <= x + 1 < inicio_x + LADO:
                pixels[y][x + 1] = paleta[0] if fracao < 0.15 else tom


def gravar_png(caminho, pixels):
    largura, altura = len(pixels[0]), len(pixels)
    linhas = b""
    for linha in pixels:
        linhas += b"\x00"
        for pixel in linha:
            linhas += bytes((0, 0, 0, 0)) if pixel is None else bytes(pixel) + b"\xff"

    def bloco(tipo, dados):
        return struct.pack(">I", len(dados)) + tipo + dados + struct.pack(">I", zlib.crc32(tipo + dados) & 0xFFFFFFFF)

    conteudo = b"\x89PNG\r\n\x1a\n"
    conteudo += bloco(b"IHDR", struct.pack(">IIBBBBB", largura, altura, 8, 6, 0, 0, 0))
    conteudo += bloco(b"IDAT", zlib.compress(linhas, 9))
    conteudo += bloco(b"IEND", b"")
    caminho.parent.mkdir(parents=True, exist_ok=True)
    caminho.write_bytes(conteudo)


def main():
    sorteio = random.Random(42)
    pixels = [[None] * (LADO * QUADROS) for _ in range(LADO)]
    for quadro in range(QUADROS):
        desenhar_tufo(pixels, quadro * LADO, sorteio, PALETAS[quadro])
    gravar_png(DESTINO, pixels)
    print("gravado", DESTINO)


if __name__ == "__main__":
    main()
