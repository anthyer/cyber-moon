# Galeria de Manutenção

**Id:** `galeria`. **Ordem:** 1, aberta desde o começo.
**Cena:** `game/scenes/levels/dungeon_galeria.tscn`.

## Tema

Os túneis de serviço debaixo da cidade: concreto, tubo, vapor e faixa de aviso. A
corporação automatizou a manutenção e foi embora; as máquinas continuam trabalhando, e
qualquer coisa que entra ali é tratada como entulho. É a dungeon de entrada: inimigos
simples, corpo a corpo, e um chefe lento que ensina a ler a marca no chão.

Cores: cinza azulado, laranja de máquina pesada, amarelo e grafite de aviso. Luz âmbar e
azul, com um toque de magenta perto dos geradores.

## Salas

| Sala | Tamanho | O que tem |
|---|---|---|
| 1. Casa de bombas | 10 por 8 | 2 ratos de sucata, 1 drone de solda. Tubos e quadro elétrico na parede. |
| 2. Corredor dos tanques | 12 por 10 | 2 drones, 3 ratos. Dois tanques de pressão e uma coluna de tubo no meio. Um gerador. |
| 3. Depósito de limpeza | 12 por 12 | **Subchefe: Zelador**, com 2 ratos. Dois exaustores girando na parede. |
| 4. Pátio de contêineres | 14 por 10 | 3 drones, 3 ratos. Contêineres no fundo. Dois geradores. |
| 5. Câmara da prensa | 16 por 14 | **Chefe: Compactador**. Arena limpa, com exaustores e chaminés no fundo. Baú. |

## Inimigos

| Inimigo | Vida | Dano | Como age |
|---|---|---|---|
| Rato de sucata | 26 | 5 | Rasteiro, rápido, morde de perto. Vem em bando. |
| Drone de solda | 36 | 7 | Flutua, chega perto e acerta com o maçarico. |

## Subchefe: Zelador, a Faxina que Não Acaba

O robô de limpeza do setor, que ninguém desligou. Alguém trocou as escovas por serras.
Baixo, largo, um visor magenta franzido, um limpa-trilho de dentes na frente e a sirene
girando no alto. Vida 320, sem segunda fase.

| Ataque | Marca | Dano |
|---|---|---|
| Varredura | círculo em volta dele | 16 |
| Investida das serras | faixa reta na direção do jogador | 18 |

## Chefe: Compactador, Tudo é Sucata

A prensa de sucata do fim da linha. Para ela não existe diferença entre lata, drone e
gente. Esteiras, tronco laranja de máquina pesada, ombreiras de espinho, grelha de
dentes, o reator magenta girando no peito e dois braços de pistão que terminam em placa
cravejada. Vida 700 (1120 em dupla).

| Ataque | Marca | Dano | Fase |
|---|---|---|---|
| Prensa | círculo onde o jogador está | 22 | 1 e 2 |
| Onda de choque | círculo grande em volta dele | 20 | 1 e 2 |
| Chuva de sucata | seis círculos em volta do jogador | 16 | só 2 |

Na segunda fase anda 40% mais rápido e ataca com 65% do intervalo.

**Troféu:** Placa do Compactador. Libera o Biodomo Abandonado.

## Objetivo paralelo: destruir os geradores

Três geradores da corporação alimentam a prensa: um na sala 2 e dois na sala 4. Cada um
aguenta alguns golpes. Com os três no chão antes de o chefe cair, o Compactador perde um
quarto da vida e o baú paga mais. Se o chefe cair com gerador de pé, o objetivo falha.

## Recompensa

300 créditos e 2 materiais raros; com o objetivo, mais 150 créditos e 1 material.

## Modelos

Todos em `game/assets/models/cyber_moon_dungeons/`, salvo indicação.

- **Novos:** `chao_concreto_placa`, `chao_metal_placa`, `chao_grade`,
  `chao_faixa_de_aviso`, `parede_concreto`, `parede_concreto_baixa`, `parede_pilar`,
  `moldura_de_porta`, `movel_porta_de_dungeon`, `movel_bau_de_recompensa`, `tubo_reto`,
  `tubo_duplo`, `tubo_descida`, `tubo_coluna`, `valvula`, `painel_eletrico`,
  `luminaria_de_tunel`, `barril`, `barril_de_aviso`, `caixote_de_metal`,
  `ventilador_de_parede`, `movel_gerador_da_corporacao`, `inimigo_drone_de_solda`,
  `inimigo_rato_de_sucata`, `chefe_zelador`, `chefe_compactador`.
- **Editados:** `conteiner_de_manutencao` (do `shipping_container_a` do kit industrial,
  três vezes maior, com ferrugem e tubo) e `tanque_de_pressao` (do `detail_tank`, com
  manômetro e base de aviso).
- **Do repositório, sem alteração:** `kenney_city_kit_industrial/shipping_container_c`
  e `chimney_medium`.
