#!/usr/bin/env python3
"""Gera os quatro ícones 16x16 de fase da Lua que aparecem no relógio da tela.

Os ícones ficam ao lado do ícone de clima (assets/textures/icones_clima/) e seguem o
mesmo estilo: 16x16 pixels, cores chapadas, fundo transparente. O disco da Lua tem um
contorno de 1 pixel cinza azulado, que é o mesmo tom da base das nuvens dos ícones de
clima, para o disco escuro da lua nova continuar visível em cima do fundo do relógio.

Cada fase é uma grade de caracteres desenhada à mão, pixel a pixel. A minguante não é
desenhada: é o espelho horizontal da crescente.

Uso, a partir da raiz do repositório:

    ./equipe/ferramentas/gerar_icones_da_lua.py

Opções:

    --destino PASTA   grava em outra pasta (padrão: game/assets/textures/icones_lua)
    --previa ARQUIVO  grava também uma folha com os quatro ícones ampliados 8 vezes,
                      para conferir de olho

Não depende de biblioteca externa, só da biblioteca padrão do Python.
"""

import argparse
import struct
import zlib
from pathlib import Path

TAMANHO = 16
COR_FUNDO_PREVIA = (24, 26, 40)
RAIZ_DO_REPOSITORIO = Path(__file__).resolve().parents[2]
DESTINO_PADRAO = RAIZ_DO_REPOSITORIO / "game" / "assets" / "textures" / "icones_lua"

# Ponto é transparente, e cada letra é um papel de cor. Nada de vermelho: a Lua é
# prateada, puxando para o azul, como as nuvens dos ícones de clima.
CORES = {
    "o": (150, 162, 186),  # contorno, o mesmo cinza azulado da base da nuvem
    "l": (232, 238, 248),  # parte iluminada, o mesmo branco azulado da nuvem
    "c": (190, 200, 222),  # cratera, um tom só um pouco abaixo da parte iluminada
    "s": (52, 62, 92),  # parte escura, azul bem fechado
}

# Lua nova: o disco inteiro no escuro, só o contorno marca onde ela está.
NOVA = [
    "................",
    "................",
    "......oooo......",
    "....oossssoo....",
    "...osssssssso...",
    "...osssssssso...",
    "..osssssssssso..",
    "..osssssssssso..",
    "..osssssssssso..",
    "..osssssssssso..",
    "...osssssssso...",
    "...osssssssso...",
    "....oossssoo....",
    "......oooo......",
    "................",
    "................",
]

# Crescente iluminada à esquerda. O jogo se passa em Florianópolis, no hemisfério sul.
# Lá a Lua é vista "de cabeça para baixo" em relação ao hemisfério norte: o Sol ilumina
# o lado oeste da Lua crescente, e quem olha do sul vê esse lado à esquerda. Por isso a
# crescente brilha à esquerda (forma de C) e a minguante à direita. Os ícones de
# hemisfério norte, comuns em jogo e em aplicativo de clima, fazem o contrário.
CRESCENTE = [
    "................",
    "................",
    "......oooo......",
    "....oolsssoo....",
    "...ollsssssso...",
    "...ollsssssso...",
    "..olllssssssso..",
    "..ollllsssssso..",
    "..ollllsssssso..",
    "..olllssssssso..",
    "...ollsssssso...",
    "...ollsssssso...",
    "....oolsssoo....",
    "......oooo......",
    "................",
    "................",
]

# Minguante: o espelho da crescente, iluminada à direita.
MINGUANTE = [linha[::-1] for linha in CRESCENTE]

# Lua cheia: o disco inteiro claro, com duas crateras sutis para não virar um sol branco.
CHEIA = [
    "................",
    "................",
    "......oooo......",
    "....oolllloo....",
    "...ollllllllo...",
    "...ollllccllo...",
    "..olllllcclllo..",
    "..ollllllllllo..",
    "..olllllllcllo..",
    "..ollccllllllo..",
    "...olcllllllo...",
    "...ollllllllo...",
    "....oolllloo....",
    "......oooo......",
    "................",
    "................",
]

# Nome do arquivo e grade. A ordem é a do ciclo, e é a ordem da folha de prévia.
FASES = [
    ("nova", NOVA),
    ("crescente", CRESCENTE),
    ("cheia", CHEIA),
    ("minguante", MINGUANTE),
]


def desenhar(nome, grade):
    """Troca cada caractere da grade pela cor do papel. Retorna linhas de pixels RGBA."""
    if len(grade) != TAMANHO or any(len(linha) != TAMANHO for linha in grade):
        raise SystemExit(f"a fase '{nome}' não tem {TAMANHO}x{TAMANHO} caracteres")

    transparente = (0, 0, 0, 0)
    linhas = []
    for linha in grade:
        pixels = []
        for papel in linha:
            if papel == ".":
                pixels.append(transparente)
            else:
                pixels.append(CORES[papel] + (255,))
        linhas.append(pixels)
    return linhas


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


def montar_previa(icones, escala=8, margem=8):
    """Junta os ícones ampliados lado a lado sobre um fundo escuro de relógio."""
    lado = TAMANHO * escala
    largura = len(icones) * (lado + margem) + margem
    altura = lado + 2 * margem
    fundo = COR_FUNDO_PREVIA + (255,)
    folha = [[fundo] * largura for _ in range(altura)]

    for indice, linhas in enumerate(icones):
        origem_x = margem + indice * (lado + margem)
        for y in range(lado):
            for x in range(lado):
                pixel = linhas[y // escala][x // escala]
                if pixel[3] > 0:
                    folha[margem + y][origem_x + x] = pixel
    return folha


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--destino", type=Path, default=DESTINO_PADRAO)
    parser.add_argument("--previa", type=Path)
    args = parser.parse_args()

    args.destino.mkdir(parents=True, exist_ok=True)
    icones = []
    for nome, grade in FASES:
        linhas = desenhar(nome, grade)
        escrever_png(args.destino / f"{nome}.png", linhas)
        icones.append(linhas)

    print(f"{len(icones)} ícones gravados em {args.destino}")

    if args.previa is not None:
        escrever_png(args.previa, montar_previa(icones))
        print(f"prévia gravada em {args.previa}")


if __name__ == "__main__":
    main()
