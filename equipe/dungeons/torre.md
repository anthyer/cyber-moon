# Torre de Retransmissão

**Id:** `torre`. **Ordem:** 3, abre vencendo a Colheitadeira.
**Cena:** `game/scenes/levels/dungeon_torre.tscn`.

## Tema

A central de dados da corporação, no alto da cidade: é de lá que sai o sinal que
controla preço, crédito e notícia. Piso de sala de servidor com trilha de circuito
acesa, parede escura com filete de neon, armários de servidor piscando e os prédios da
cidade aparecendo atrás do terraço. É a dungeon mais difícil e a mais cyberpunk: a
segurança atira de longe, e o chefe é a própria corporação em forma de máquina.

Cores: grafite e preto, com neon magenta, azul claro e amarelo. Luz ciano e roxa.

## Salas

| Sala | Tamanho | O que tem |
|---|---|---|
| 1. Saguão de acesso | 10 por 8 | 1 guarda blindado, 2 olhos de vigia. Letreiros de neon e um terminal. |
| 2. Sala dos servidores | 12 por 10 | 2 guardas, 3 olhos. Fileira de armários no fundo e dois blocos no meio, que ficam translúcidos quando cobrem alguém. |
| 3. Câmara do firewall | 12 por 12 | **Subchefe: Firewall**, com 2 olhos. Piso todo de circuito. |
| 4. Terraço da antena | 14 por 10 | 3 guardas, 3 olhos. A antena pirata no centro e os prédios ao fundo. |
| 5. Sala do conselho | 16 por 14 | **Chefe: O Auditor**. Arena de circuito, servidores nos cantos. Baú. |

## Inimigos

| Inimigo | Vida | Dano | Como age |
|---|---|---|---|
| Olho de vigia | 52 | 10 | Câmera que flutua, com um anel girando. Atira dois projéteis em leque, de longe. |
| Guarda blindado | 95 | 14 | Robô de choque sobre uma roda, com escudo e bastão. Lento, aguenta muito. |

Os guardas seguram o jogador enquanto os olhos atiram por cima.

## Subchefe: Firewall, Acesso Negado

O programa de defesa da rede, com corpo: um núcleo preto que flutua, com um olho
magenta, cercado por três placas de escudo que giram e uma coroa de pontas amarelas.
Vida 650, sem segunda fase.

| Ataque | Marca | Dano |
|---|---|---|
| Pulso de bloqueio | círculo em volta dele | 22 |
| Quarentena | cinco círculos em volta do jogador | 18 |

## Chefe: O Auditor, Fechamento de Contas

O executivo de metal que fecha as contas da corporação. Não tem pernas: flutua sobre um
propulsor, com um anel de dados girando na cintura. Tronco em V de terno preto com
gravata de neon, ombreiras de ponta, cabeça de tela com olhar franzido e dentes de luz,
e dois braços que terminam em lâmina. Fala a língua do corte. Vida 1400 (2240 em dupla).

| Ataque | Marca | Dano | Fase |
|---|---|---|---|
| Corte de custos | faixa comprida na direção do jogador | 30 | 1 e 2 |
| Auditoria | círculo rápido onde o jogador está | 26 | 1 e 2 |
| Demissão em massa | nove círculos em volta do jogador | 22 | só 2 |
| Fechamento | círculo enorme em volta dele | 28 | só 2 |

Na segunda fase anda 50% mais rápido e ataca com 55% do intervalo. É a luta em que
parar de andar custa caro.

**Troféu:** Crachá do Auditor. É o último; não libera dungeon nova.

## Objetivo paralelo: proteger a antena

O Kenji montou uma antena pirata no terraço (sala 4) para transmitir por cima do sinal
da corporação. Enquanto houver inimigo acordado perto dela, a antena perde vida. Limpar
a sala com a antena de pé cumpre o objetivo; se a vida dela zerar, ele falha. A pressa
aqui é o desafio: os guardas são lentos de derrubar.

## Recompensa

650 créditos e 4 materiais raros; com o objetivo, mais 300 créditos e 2 materiais.

## Modelos

Todos em `game/assets/models/cyber_moon_dungeons/`.

- **Novos:** `chao_tecnologico_placa`, `chao_tecnologico_circuito`,
  `parede_tecnologica`, `parede_tecnologica_baixa`, `rack_de_servidor`,
  `rack_de_servidor_baixo`, `terminal`, `painel_neon`, `torre_de_resfriamento`,
  `bateria_de_reserva`, `enfeite_cabos`, `movel_antena_pirata`,
  `inimigo_olho_de_vigia`, `inimigo_guarda_blindado`, `chefe_firewall`, `chefe_auditor`.
- **Editado:** `predio_de_fundo` (do `building_skyscraper_a` do kit comercial, três vezes
  maior, repintado de escuro, com fileiras de janela acesa). Fica fora da arena, atrás da
  parede do norte, como vista da cidade.
- **Comuns às três dungeons:** pilar, moldura e folha de porta, baú.
