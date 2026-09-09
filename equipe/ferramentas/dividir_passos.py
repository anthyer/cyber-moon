#!/usr/bin/env python3
"""Corta um clipe .wav com varios passos em sequencia em um arquivo por passo.

Clipe de passo costuma vir gravado em fila (toc, toc, toc) num arquivo so. O jogo
precisa de um arquivo por passo, para sortear entre eles. Este script separa por
deteccao de silencio e grava numerado no destino.

Uso:

    ./dividir_passos.py clipe_bruto.wav ../../game/assets/audio/sfx/passos/grama

Opcoes uteis quando o corte sai errado:

    --limiar 0.04         mais sensivel, pega passo mais fraco
    --silencio-minimo 0.1 exige silencio mais longo para considerar que separou
    --listar              so mostra o que faria, sem gravar nada

Nao depende de ffmpeg nem de biblioteca externa, so da biblioteca padrao do Python.
Aceita .wav PCM de 8, 16 ou 32 bits, mono ou estereo.
"""

import argparse
import array
import sys
import wave
from pathlib import Path

TIPO_POR_LARGURA = {1: "b", 2: "h", 4: "i"}
JANELA_SEGUNDOS = 0.005


def ler_wav(caminho):
    with wave.open(str(caminho), "rb") as arquivo:
        canais = arquivo.getnchannels()
        largura = arquivo.getsampwidth()
        taxa = arquivo.getframerate()
        quadros = arquivo.readframes(arquivo.getnframes())

    if largura not in TIPO_POR_LARGURA:
        raise SystemExit(
            f"largura de amostra nao suportada: {largura} bytes. "
            "Converta o arquivo para PCM de 16 bits antes."
        )

    amostras = array.array(TIPO_POR_LARGURA[largura])
    amostras.frombytes(quadros)
    if sys.byteorder == "big":
        amostras.byteswap()

    return amostras, canais, largura, taxa


def escrever_wav(caminho, amostras, canais, largura, taxa):
    saida = array.array(TIPO_POR_LARGURA[largura], amostras)
    if sys.byteorder == "big":
        saida.byteswap()
    with wave.open(str(caminho), "wb") as arquivo:
        arquivo.setnchannels(canais)
        arquivo.setsampwidth(largura)
        arquivo.setframerate(taxa)
        arquivo.writeframes(saida.tobytes())


def energia_por_janela(amostras, canais, taxa):
    """Devolve a amplitude maxima de cada janela curta, em quadros."""
    quadros_por_janela = max(1, int(taxa * JANELA_SEGUNDOS))
    total_de_quadros = len(amostras) // canais
    energias = []
    for inicio in range(0, total_de_quadros, quadros_por_janela):
        fim = min(inicio + quadros_por_janela, total_de_quadros)
        pico = 0
        for quadro in range(inicio, fim):
            for canal in range(canais):
                valor = abs(amostras[quadro * canais + canal])
                if valor > pico:
                    pico = valor
        energias.append(pico)
    return energias, quadros_por_janela


def achar_segmentos(energias, quadros_por_janela, taxa, limiar_relativo,
                    silencio_minimo, duracao_minima, margem):
    """Encontra as regioes com som, em pares de quadro inicial e final."""
    pico_geral = max(energias) if energias else 0
    if pico_geral == 0:
        return []
    limiar = pico_geral * limiar_relativo

    janelas_de_silencio_para_cortar = max(1, int(silencio_minimo / JANELA_SEGUNDOS))
    segmentos = []
    inicio_atual = None
    silencio_corrido = 0

    for indice, energia in enumerate(energias):
        if energia >= limiar:
            if inicio_atual is None:
                inicio_atual = indice
            silencio_corrido = 0
        elif inicio_atual is not None:
            silencio_corrido += 1
            if silencio_corrido >= janelas_de_silencio_para_cortar:
                segmentos.append((inicio_atual, indice - silencio_corrido + 1))
                inicio_atual = None
                silencio_corrido = 0

    if inicio_atual is not None:
        segmentos.append((inicio_atual, len(energias)))

    quadros_de_margem = int(taxa * margem)
    quadros_minimos = int(taxa * duracao_minima)
    total_de_quadros = len(energias) * quadros_por_janela

    resultado = []
    for janela_inicial, janela_final in segmentos:
        inicio = max(0, janela_inicial * quadros_por_janela - quadros_de_margem)
        fim = min(total_de_quadros, janela_final * quadros_por_janela + quadros_de_margem)
        if fim - inicio >= quadros_minimos:
            resultado.append((inicio, fim))
    return resultado


def aplicar_fade(amostras, canais, taxa, duracao):
    """Suaviza inicio e fim para o corte nao gerar estalo."""
    quadros = int(taxa * duracao)
    total = len(amostras) // canais
    quadros = min(quadros, total // 2)
    if quadros <= 0:
        return amostras
    for posicao in range(quadros):
        ganho = posicao / quadros
        for canal in range(canais):
            amostras[posicao * canais + canal] = int(amostras[posicao * canais + canal] * ganho)
            fim = (total - 1 - posicao) * canais + canal
            amostras[fim] = int(amostras[fim] * ganho)
    return amostras


def main():
    analisador = argparse.ArgumentParser(
        description="Corta um clipe .wav com varios passos em um arquivo por passo."
    )
    analisador.add_argument("entrada", type=Path, help="arquivo .wav de origem")
    analisador.add_argument("destino", type=Path, help="pasta onde gravar os cortes")
    analisador.add_argument("--prefixo", default="passo", help="prefixo do nome (padrao: passo)")
    analisador.add_argument("--limiar", type=float, default=0.06,
                            help="fracao do pico que conta como som (padrao: 0.06)")
    analisador.add_argument("--silencio-minimo", type=float, default=0.06,
                            help="silencio em segundos que separa dois passos (padrao: 0.06)")
    analisador.add_argument("--duracao-minima", type=float, default=0.03,
                            help="descarta corte mais curto que isso (padrao: 0.03)")
    analisador.add_argument("--margem", type=float, default=0.02,
                            help="folga em segundos antes e depois (padrao: 0.02)")
    analisador.add_argument("--fade", type=float, default=0.005,
                            help="fade de entrada e saida em segundos (padrao: 0.005)")
    analisador.add_argument("--listar", action="store_true",
                            help="mostra o que faria, sem gravar")
    argumentos = analisador.parse_args()

    if not argumentos.entrada.is_file():
        raise SystemExit(f"arquivo nao encontrado: {argumentos.entrada}")

    amostras, canais, largura, taxa = ler_wav(argumentos.entrada)
    energias, quadros_por_janela = energia_por_janela(amostras, canais, taxa)
    segmentos = achar_segmentos(
        energias, quadros_por_janela, taxa,
        argumentos.limiar, argumentos.silencio_minimo,
        argumentos.duracao_minima, argumentos.margem,
    )

    if not segmentos:
        raise SystemExit(
            "nenhum passo encontrado. Tente --limiar menor (ex: 0.02) "
            "ou confira se o arquivo tem som."
        )

    print(f"{argumentos.entrada.name}: {len(segmentos)} passos encontrados "
          f"({taxa} Hz, {canais} canal(is), {largura * 8} bits)")

    for numero, (inicio, fim) in enumerate(segmentos, start=1):
        duracao = (fim - inicio) / taxa
        nome = f"{argumentos.prefixo}_{numero:02d}.wav"
        print(f"  {nome}  {inicio / taxa:6.3f}s ate {fim / taxa:6.3f}s  ({duracao:.3f}s)")
        if argumentos.listar:
            continue
        argumentos.destino.mkdir(parents=True, exist_ok=True)
        recorte = amostras[inicio * canais:fim * canais]
        recorte = aplicar_fade(recorte, canais, taxa, argumentos.fade)
        escrever_wav(argumentos.destino / nome, recorte, canais, largura, taxa)

    if argumentos.listar:
        print("\nmodo --listar, nada foi gravado.")
    else:
        print(f"\ngravado em {argumentos.destino}")
        if len(segmentos) < 6:
            print("aviso: menos de 6 passos. O jogo fica melhor com 6 a 9 por superficie.")


if __name__ == "__main__":
    main()
