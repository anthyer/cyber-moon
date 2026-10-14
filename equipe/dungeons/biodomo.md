# Biodomo Abandonado

**Id:** `biodomo`. **Ordem:** 2, abre vencendo o Compactador.
**Cena:** `game/scenes/levels/dungeon_biodomo.tscn`.

## Tema

A estufa de pesquisa onde a corporação guardava as sementes que tirou dos agricultores.
O projeto foi encerrado, as portas foram lacradas, e duas coisas continuaram lá dentro:
o mato, que rompeu o piso, e as máquinas de jardinagem, que seguem podando tudo o que
cresce e tudo o que se mexe. É a dungeon que fala com o resto do jogo: o jogador é
fazendeiro, e aqui a fazenda virou inimiga.

Cores: verde e terra, caixilho branco, vidro azul pálido e a luz magenta de cultivo.

## Salas

| Sala | Tamanho | O que tem |
|---|---|---|
| 1. Recepção da estufa | 10 por 8 | 2 podadores, 1 semeador. Bancadas de muda e tanque de nutrientes. Uma caixa de sementes. |
| 2. Canteiros de hidroponia | 12 por 10 | 3 podadores, 2 semeadores. Cinco canteiros elevados, que servem de cobertura baixa. Uma caixa. |
| 3. Laboratório de enxertos | 12 por 12 | **Subchefe: Enxertador**, com 2 semeadores. Árvores em vaso. Uma caixa. |
| 4. Bosque que escapou | 14 por 10 | 4 podadores, 2 semeadores. Árvores que romperam o piso, contêiner tomado pelo mato. Uma caixa. |
| 5. Campo de colheita | 16 por 14 | **Chefe: Colheitadeira**. Terra arada, canteiros e milho no fundo. Baú. |

## Inimigos

| Inimigo | Vida | Dano | Como age |
|---|---|---|---|
| Podador | 46 | 9 | Drone de poda, flutua e corta de perto com as duas lâminas. |
| Semeador | 40 | 8 | Torre de três pernas, fica parada e cospe semente de longe. O tiro é lento, dá para desviar. |

A mistura obriga a escolher: os podadores apertam de perto enquanto os semeadores
atiram do fundo.

## Subchefe: Enxertador, o Jardineiro de Agulhas

A máquina de enxerto do laboratório: uma aranha de seis pernas com o corpo verde
balançando no meio, um reservatório magenta nas costas e dois braços de seringa.
Vida 480, sem segunda fase.

| Ataque | Marca | Dano |
|---|---|---|
| Injeção | faixa fina e rápida na direção do jogador | 20 |
| Raízes de aço | quatro círculos em volta do jogador | 15 |

## Chefe: Colheitadeira, a Safra Final

A colheitadeira do campo de testes. Foi programada para colher tudo o que estiver de pé
no talhão, e o jogador está de pé no talhão. Corpo verde de máquina agrícola, cabine
amarela com o visor franzido, chifres de escapamento e, na frente, o molinete de lâminas
girando sobre uma fileira de dentes. Vida 1000 (1600 em dupla).

| Ataque | Marca | Dano | Fase |
|---|---|---|---|
| Corredor de colheita | faixa larga e comprida na direção do jogador | 26 | 1 e 2 |
| Giro do molinete | círculo em volta dela | 22 | 1 e 2 |
| Semeadura | oito círculos em volta do jogador | 18 | só 2 |

Na segunda fase anda 45% mais rápido e ataca com 60% do intervalo.

**Troféu:** Lâmina da Colheitadeira. Libera a Torre de Retransmissão.

## Objetivo paralelo: resgatar as sementes

Quatro caixas de sementes nativas ficaram para trás, uma em cada uma das quatro
primeiras salas, nos cantos. O jogador pega interagindo. Com as quatro em mãos, o baú
paga mais. Este objetivo não falha: caixa que ficou para trás só não conta.

## Recompensa

450 créditos e 3 materiais raros; com o objetivo, mais 200 créditos e 1 material.

## Modelos

Todos em `game/assets/models/cyber_moon_dungeons/`, salvo indicação.

- **Novos:** `chao_terra_placa`, `chao_grama_placa`, `parede_de_estufa`,
  `bancada_de_mudas`, `lampada_de_cultivo`, `tanque_de_nutrientes`, `aspersor`,
  `movel_caixa_de_sementes`, `inimigo_podador`, `inimigo_semeador`, `chefe_enxertador`,
  `chefe_colheitadeira`.
- **Editados**, com plantas do `kenney_nature_kit` repintadas na paleta e juntadas a
  peças novas: `parede_de_estufa_baixa` (floreira com `grass_large`),
  `canteiro_hidroponico` (`crops_leafs_stage_b` e `plant_bush_small`), `arvore_em_vaso`
  (`tree_default`), `arvore_que_rompeu_o_piso` (`tree_oak`), `enfeite_cipo` (`grass`) e
  `conteiner_tomado_pelo_mato` (o `shipping_container_b` do kit industrial com
  `plant_bush` em cima).
- **Do repositório, sem alteração:** do `kenney_nature_kit`, `plant_bush_large`,
  `tree_pine_round_a`, `rock_large_a`, `mushroom_red_group`, `flower_purple_a` e
  `crops_corn_stage_d`.
- **Comuns às três dungeons:** pilar, moldura e folha de porta, baú.
