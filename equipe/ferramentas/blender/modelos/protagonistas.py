"""Os protagonistas que o jogador escolhe antes do jogo novo (plano 39).

Pacote `cyber_moon_personagens`, o mesmo dos moradores. Cada protagonista parte de um
modelo do pacote de personagens da Kenney, como os moradores (`personagens.py`), mas com o
cuidado de herói: a mochila de campo nas costas (`kit.mochila_de_campo`), o verde-broto
aceso (`kit.COR_DO_JOGADOR`, a cor que nenhum morador usa), uma peça grande na cabeça que
muda o contorno e a roupa de trabalho com o contraste mais forte da paleta. A escala é a
mesma dos moradores e as peças ficam só nos ossos `head` e `torso`.

No jogo não há palavra de gênero: os protagonistas são do corpo "tipo 1" ou "tipo 2". O
nome da base da Kenney só aparece aqui, no script: tipo 1 sai das bases `male_*`, tipo 2
das bases `female_*`.

Rodar no Blender, ou sem janela:
    flatpak run org.blender.Blender -b --python <repositorio>/equipe/ferramentas/blender/modelos/protagonistas.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit_cyber_moon as kit

# A base da Kenney de cada tipo de corpo. Fica só aqui: o resto do projeto fala em tipo.
BASE_DO_TIPO_1 = "male"
BASE_DO_TIPO_2 = "female"


# -- peças --------------------------------------------------------------------------------

def chapeu_de_palha(cor_da_faixa=kit.COR_DO_JOGADOR):
    """Chapéu de palha de aba larga, com a faixa de LED em volta da copa.

    A aba passa da largura dos ombros: de cima, que é como a câmera vê, o contorno vira um
    disco claro que nenhum morador tem. A aba fica acima da mochila para não esconder a
    luz de status.
    """
    m = kit.Modelo("chapeu_de_palha")
    # Inclinado para trás, para a câmera do jogo, que fica alta, ainda ver o rosto.
    inclinacao = (-18, 0, 0)
    m.cilindro(0.36, 0.03, pos=(0, -0.02, 0.6), cor="areia", lados=12, raio_do_topo=0.33, rot=inclinacao)
    m.cilindro(0.29, 0.15, pos=(0, -0.02, 0.61), cor="areia", lados=10, raio_do_topo=0.24,
               cor_das_tampas="areia", rot=inclinacao)
    m.cilindro(0.285, 0.04, pos=(0, -0.02, 0.625), cor=cor_da_faixa, lados=10, raio_do_topo=0.275,
               brilho=True, rot=inclinacao)
    return m


# -- os protagonistas ----------------------------------------------------------------------

def protagonista_1a():
    """Palha: chapéu de palha de aba larga com a faixa acesa, camisa jeans, calça de lona
    clara, luva e bota escuras. A roupa de quem trabalha na terra, no contraste mais forte.

    A base é a mesma do Hélio, então sai o que é dele: os óculos (apagados) e o cabelo
    castanho (agora preto)."""
    p = kit.Personagem("protagonista_1a", BASE_DO_TIPO_1 + "_e")
    p.apagar_cor(["cinza_lilas", "branco"], parte="cabeca")
    p.trocar_cor("pele_escura", "preto", parte="cabeca")
    p.trocar_cor("amarelo", "areia", parte="corpo")
    p.trocar_cor("branco", "jeans", parte="corpo")
    p.trocar_cor("grafite", "preto", parte="corpo")
    p.trocar_cor("cinza", "couro", parte="corpo")
    p.peca("head", chapeu_de_palha())
    p.peca("torso", kit.mochila_de_campo())
    return p


PROTAGONISTAS = [protagonista_1a]

if __name__ == "__main__":
    kit.usar_paleta_de_personagens()
    kit.produzir_personagens(PROTAGONISTAS, "protagonistas")
