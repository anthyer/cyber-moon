"""Os personagens da vila: os seis moradores antigos no tema e o elenco do plano 30.

Pacote `cyber_moon_personagens`. Cada um parte de um modelo do pacote de personagens da
Kenney (esqueleto e animações prontos), troca a cor de partes da roupa e ganha peças do
tema presas a um osso. O guia está em `game/docs/biblia_3d.md`, seção "Pessoas".

As cores são as da paleta dos personagens (`kit.PALETA_DE_PERSONAGENS`): as da Kenney
(creme, azul, grafite, pele_clara...) e as novas do tema (neon_ciano, couro, jeans...).

Rodar no Blender, ou sem janela:
    flatpak run org.blender.Blender -b --python equipe/ferramentas/blender/modelos/personagens.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit

# Medidas da cabeça em repouso, iguais nos doze modelos (ver kit.Personagem).
FRENTE_DO_ROSTO = -0.16
ALTURA_DOS_OLHOS = 0.485
ALTURA_DA_TESTA = 0.57


# -- peças --------------------------------------------------------------------------------

def faixa_na_cabeca(m, altura, cor="grafite", espessura=0.035):
    """A tira que segura óculos, lanterna e visor, dando a volta na cabeça."""
    m.caixa((0.4, 0.36, espessura), pos=(0, -0.01, altura), cor=cor)


def visor(cor="neon_ciano"):
    """Visor de uma peça só na frente dos olhos, aceso."""
    m = kit.Modelo("visor")
    faixa_na_cabeca(m, ALTURA_DOS_OLHOS - 0.025, cor="grafite", espessura=0.05)
    m.caixa((0.34, 0.035, 0.075), pos=(0, FRENTE_DO_ROSTO - 0.02, ALTURA_DOS_OLHOS - 0.035), cor=cor, brilho=True)
    m.caixa((0.04, 0.05, 0.05), pos=(0.2, FRENTE_DO_ROSTO + 0.02, ALTURA_DOS_OLHOS - 0.02), cor="cromo")
    return m


def oculos_na_testa(cor_das_lentes="grafite", cor_do_aro="cromo", brilho=False):
    """Óculos de solda ou de moto, puxados para a testa."""
    m = kit.Modelo("oculos_na_testa")
    faixa_na_cabeca(m, ALTURA_DA_TESTA, cor="couro")
    for x in (-0.075, 0.075):
        m.cilindro(0.055, 0.04, pos=(x, FRENTE_DO_ROSTO - 0.01, ALTURA_DA_TESTA + 0.018), rot=(90, 0, 0),
                   cor=cor_do_aro, lados=8)
        m.cilindro(0.04, 0.012, pos=(x, FRENTE_DO_ROSTO - 0.05, ALTURA_DA_TESTA + 0.018), rot=(90, 0, 0),
                   cor=cor_das_lentes, lados=8, brilho=brilho)
    return m


def oculos_escuros():
    """Óculos escuros na frente dos olhos."""
    m = kit.Modelo("oculos_escuros")
    for x in (-0.072, 0.072):
        m.caixa((0.11, 0.025, 0.06), pos=(x, FRENTE_DO_ROSTO - 0.015, ALTURA_DOS_OLHOS - 0.03), cor="preto")
    m.caixa((0.06, 0.02, 0.015), pos=(0, FRENTE_DO_ROSTO - 0.015, ALTURA_DOS_OLHOS + 0.005), cor="preto")
    return m


def lanterna_de_cabeca():
    """A lanterna de quem trabalhou a vida inteira em túnel."""
    m = kit.Modelo("lanterna_de_cabeca")
    faixa_na_cabeca(m, ALTURA_DA_TESTA - 0.01, cor="verde_militar")
    m.caixa((0.1, 0.05, 0.07), pos=(0, FRENTE_DO_ROSTO - 0.035, ALTURA_DA_TESTA - 0.025), cor="grafite", chanfro=0.01)
    m.cilindro(0.028, 0.012, pos=(0, FRENTE_DO_ROSTO - 0.06, ALTURA_DA_TESTA + 0.01), rot=(90, 0, 0),
               cor="neon_amarelo", lados=8, brilho=True)
    return m


def capacete(cor, cor_do_visor="preto", altura_da_base=0.53):
    """Capacete de moto fechado em cima, com a viseira levantada."""
    m = kit.Modelo("capacete")
    m.caixa((0.5, 0.46, 0.24), pos=(0, -0.025, altura_da_base), cor=cor, chanfro=0.06)
    m.caixa((0.4, 0.04, 0.07), pos=(0, -0.27, altura_da_base + 0.02), cor=cor_do_visor, rot=(-25, 0, 0))
    for x in (-0.252, 0.252):
        m.caixa((0.01, 0.3, 0.04), pos=(x, -0.025, altura_da_base + 0.1), cor="branco")
    return m


def bone(cor, cor_da_frente=None, virado=False):
    """Boné de aba reta. Virado, a aba vai para trás (o Téo)."""
    m = kit.Modelo("bone")
    m.caixa((0.47, 0.43, 0.12), pos=(0, -0.025, 0.6), cor=cor, chanfro=0.03)
    if cor_da_frente:
        m.caixa((0.3, 0.02, 0.09), pos=(0, -0.248, 0.615), cor=cor_da_frente)
    aba_y = 0.27 if virado else -0.32
    m.caixa((0.36, 0.17, 0.025), pos=(0, aba_y, 0.6), cor=cor)
    return m


def lenco_no_pescoco(cor):
    """Lenço amarrado no pescoço, com a ponta caindo na frente."""
    m = kit.Modelo("lenco")
    m.caixa((0.27, 0.23, 0.06), pos=(0, 0.02, 0.32), cor=cor, chanfro=0.02)
    m.prisma([(-0.08, 0.0), (0.08, 0.0), (0.0, -0.09)], 0.025, pos=(0, -0.105, 0.34), cor=cor)
    return m


def avental(cor, cor_do_bolso):
    """Avental de feira, só no tronco (abaixo dele a perna anda e atravessaria o pano)."""
    m = kit.Modelo("avental")
    m.caixa((0.21, 0.025, 0.17), pos=(0, -0.118, 0.19), cor=cor)
    m.caixa((0.11, 0.03, 0.05), pos=(0, -0.124, 0.22), cor=cor_do_bolso)
    for x in (-0.07, 0.07):
        m.caixa((0.02, 0.2, 0.02), pos=(x, -0.02, 0.355), cor=cor)
    return m


def cruz_no_peito(cor):
    """A cruz de quem cuida da clínica, acesa."""
    m = kit.Modelo("cruz")
    m.caixa((0.06, 0.02, 0.02), pos=(-0.05, -0.118, 0.31), cor=cor, brilho=True)
    m.caixa((0.02, 0.02, 0.06), pos=(-0.05, -0.118, 0.29), cor=cor, brilho=True)
    return m


def cracha(cor):
    """Crachá da corporação no peito, com a faixa acesa."""
    m = kit.Modelo("cracha")
    m.caixa((0.05, 0.015, 0.065), pos=(0.055, -0.118, 0.27), cor="branco")
    m.caixa((0.05, 0.02, 0.015), pos=(0.055, -0.12, 0.315), cor=cor, brilho=True)
    return m


def fone_de_ouvido(cor):
    """Fone de comunicação de um lado só, com a luz acesa."""
    m = kit.Modelo("fone")
    m.caixa((0.03, 0.06, 0.08), pos=(-0.235, -0.03, 0.44), cor="grafite")
    m.caixa((0.012, 0.02, 0.02), pos=(-0.252, -0.03, 0.49), cor=cor, brilho=True)
    return m


def bolsa_a_tiracolo(cor):
    """Bolsa de lona com a alça cruzando o peito (o caderno de sementes do Hélio)."""
    m = kit.Modelo("bolsa")
    m.caixa((0.06, 0.15, 0.12), pos=(0.13, 0.0, 0.18), cor=cor, chanfro=0.015)
    m.caixa((0.025, 0.02, 0.24), pos=(0.0, -0.118, 0.2), cor=cor, rot=(0, 40, 0))
    return m


def ombreiras(cor, cor_do_detalhe):
    """Ombreiras de couro de motoqueira, com o rebite aceso."""
    m = kit.Modelo("ombreiras")
    for x in (-0.13, 0.13):
        m.caixa((0.11, 0.2, 0.05), pos=(x, 0.02, 0.35), cor=cor, chanfro=0.015)
        m.caixa((0.03, 0.02, 0.02), pos=(x, -0.085, 0.365), cor=cor_do_detalhe, brilho=True)
    return m


# -- os seis moradores antigos ---------------------------------------------------------------

def personagem_vitor():
    """Mecânico: macacão de oficina e óculos de solda na testa. A barba ruiva fica."""
    p = kit.Personagem("personagem_vitor", "male_b")
    p.trocar_cor("vermelho", "jeans", parte="corpo")
    p.trocar_cor("azul", "jeans", parte="corpo")
    p.peca("head", oculos_na_testa(cor_das_lentes="verde_militar"))
    return p


def personagem_kenji():
    """O da antena: o quepe vira gorro preto, a farda vira jaqueta, e o visor acende."""
    p = kit.Personagem("personagem_kenji", "male_c")
    p.trocar_cor("azul", "preto", parte="cabeca")
    p.trocar_cor("amarelo", "neon_ciano", parte="cabeca")
    p.trocar_cor("azul", "ardosia", parte="corpo")
    p.trocar_cor("amarelo", "neon_ciano", parte="corpo")
    p.peca("head", visor("neon_ciano"))
    return p


def personagem_rafa():
    """Entregador: jaqueta de couro, gravata virando faixa refletiva, e o capacete."""
    p = kit.Personagem("personagem_rafa", "male_d")
    p.trocar_cor("grafite", "couro", parte="corpo")
    p.trocar_cor("vermelho", "laranja_seguranca", parte="corpo")
    p.peca("head", capacete("laranja_seguranca"))
    return p


def personagem_marta():
    """Dona do mercado: blusa de terracota, calça oliva e o avental de feira."""
    p = kit.Personagem("personagem_marta", "female_a")
    p.tirar_da_mao(["azul", "cinza_lilas"])
    p.trocar_cor("roxo", "terracota", parte="corpo")
    p.trocar_cor("azul", "oliva", parte="corpo")
    p.peca("torso", avental("creme", "verde_militar"))
    return p


def personagem_iara():
    """Médica: jaleco branco, calça de clínica e a cruz verde acesa no peito."""
    p = kit.Personagem("personagem_iara", "female_b")
    p.trocar_cor("amarelo", "branco", parte="corpo")
    p.trocar_cor("roxo", "azul_claro", parte="corpo")
    p.trocar_cor("amarelo", "neon_verde", parte="cabeca")
    p.peca("torso", cruz_no_peito("neon_verde"))
    return p


def personagem_sol():
    """A que fugiu da cidade: roupa cor de areia, lenço no pescoço e óculos escuros."""
    p = kit.Personagem("personagem_sol", "female_c")
    p.trocar_cor("azul", "areia", parte="corpo")
    p.trocar_cor("cinza", "vinho", parte="cabeca")
    p.peca("torso", lenco_no_pescoco("neon_magenta"))
    p.peca("head", oculos_escuros())
    return p


# -- o elenco novo ---------------------------------------------------------------------------

def personagem_bento():
    """Ex-zelador da Galeria, 68 anos: barba branca, uniforme verde e a lanterna de túnel."""
    p = kit.Personagem("personagem_bento", "male_b")
    p.trocar_cor("pele_media", "branco", parte="cabeca")
    p.trocar_cor("cinza_lilas", "branco", parte="cabeca")
    p.trocar_cor("vermelho", "verde_militar", parte="corpo")
    p.trocar_cor("azul", "oliva", parte="corpo")
    p.peca("head", lanterna_de_cabeca())
    return p


def personagem_helio():
    """Ex-pesquisador do Biodomo: cabelo grisalho, suspensório de couro e a bolsa do caderno."""
    p = kit.Personagem("personagem_helio", "male_e")
    p.trocar_cor("grafite", "cinza", parte="cabeca")
    p.trocar_cor("amarelo", "couro", parte="corpo")
    p.peca("torso", bolsa_a_tiracolo("oliva"))
    return p


def personagem_dandara():
    """Líder das motoqueiras: cabelo vinho, couro preto, ombreiras e os óculos de moto."""
    p = kit.Personagem("personagem_dandara", "female_f")
    p.trocar_cor("pele_escura", "vinho", parte="cabeca")
    p.trocar_cor("amarelo", "neon_magenta", parte="corpo")
    p.trocar_cor("azul", "preto", parte="corpo")
    p.trocar_cor("roxo", "couro", parte="corpo")
    p.peca("torso", ombreiras("preto", "neon_magenta"))
    p.peca("head", oculos_na_testa(cor_das_lentes="neon_magenta", cor_do_aro="preto", brilho=True))
    return p


def personagem_lucia():
    """Fiscal da expansão: terninho escuro, crachá e fone da corporação, acesos em roxo."""
    p = kit.Personagem("personagem_lucia", "female_d")
    p.trocar_cor("cinza", "ardosia", parte="corpo")
    p.peca("torso", cracha("neon_magenta"))
    p.peca("head", fone_de_ouvido("neon_magenta"))
    return p


def personagem_teo():
    """Criança da vila, 10 anos: camiseta laranja, mochila de explorador e boné virado."""
    p = kit.Personagem("personagem_teo", "male_f")
    p.trocar_cor("verde", "laranja", parte="corpo")
    p.trocar_cor("cinza", "couro", parte="corpo")
    p.peca("head", bone("azul", virado=True))
    p.escalar(0.8)
    return p


def personagem_zeca():
    """Caminhoneiro: camisa vinho, jeans, óculos escuros e boné de caminhoneiro."""
    p = kit.Personagem("personagem_zeca", "male_a")
    p.trocar_cor("verde", "vinho", parte="corpo")
    p.trocar_cor("azul", "jeans", parte="corpo")
    p.trocar_cor("branco", "grafite", parte="cabeca")
    p.peca("head", bone("areia", cor_da_frente="branco"))
    return p


def personagem_motoqueira_a():
    """Figurante do acampamento: jaqueta preta com detalhe magenta e óculos de moto."""
    p = kit.Personagem("personagem_motoqueira_a", "female_e")
    p.trocar_cor("branco", "preto", parte="corpo")
    p.trocar_cor("cinza_lilas", "neon_magenta", parte="corpo")
    p.peca("head", oculos_na_testa(cor_das_lentes="neon_ciano", cor_do_aro="preto", brilho=True))
    return p


def personagem_motoqueira_b():
    """Figurante do acampamento: cabelo rosa, couro e calça preta."""
    p = kit.Personagem("personagem_motoqueira_b", "female_a")
    p.tirar_da_mao(["azul", "cinza_lilas"])
    p.trocar_cor("grafite", "neon_magenta", parte="cabeca")
    p.trocar_cor("roxo", "couro", parte="corpo")
    p.trocar_cor("azul", "preto", parte="corpo")
    p.peca("torso", ombreiras("couro", "neon_ciano"))
    return p


PERSONAGENS = [
    personagem_vitor, personagem_kenji, personagem_rafa, personagem_marta, personagem_iara, personagem_sol,
    personagem_bento, personagem_helio, personagem_dandara, personagem_lucia, personagem_teo, personagem_zeca,
    personagem_motoqueira_a, personagem_motoqueira_b,
]

if __name__ == "__main__":
    kit.usar_paleta_de_personagens()
    kit.produzir_personagens(PERSONAGENS, "personagens")
