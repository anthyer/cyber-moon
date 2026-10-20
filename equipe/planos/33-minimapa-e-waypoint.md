# Plano 33: Minimapa com waypoint

**Objetivo:** um minimapa no canto da tela mostra onde o jogador está, os caminhos, os
lugares e os moradores, e marca para onde ir.

**Depende de:** 26 (os mapas e o traçado em `desenho_do_mundo.py`), 32 (a missão
acompanhada vira o waypoint).

**Situação:** só registrado, em 2026-10-19, a pedido do Antonio.

## O pedido do Antonio (2026-10-19)

- Já prever um minimapa com waypoint.

## Ideias para discutir

- **Imagem do mapa gerada** pelo mesmo traçado que gera o terreno (trilhas, rio, lago,
  corredores, lugares), no estilo da paleta, uma para o mundo e uma para a fazenda. Não
  precisa de segunda câmera, que pesa no Compatibility.
- **Marcadores**: o jogador (seta virada para onde olha), moradores (pontinho com a cor
  de cada um), portas de dungeon, baús e a porteira.
- **Waypoint**: o objetivo da missão acompanhada. Dentro do minimapa, um marcador; fora
  da área visível, uma seta na borda apontando a direção. No mundo, uma coluna de luz
  discreta ou um losango flutuando sobre o lugar.
- **Mapa grande** numa tecla (o mapa inteiro, com os nomes dos lugares), que pausa.
- Ação nova de entrada para o mapa grande, passando pelo `InputManager`, e documentada em
  `entrada.md`.
