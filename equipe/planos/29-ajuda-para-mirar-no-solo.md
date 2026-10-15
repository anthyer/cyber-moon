# Plano 29: Ajuda para mirar no solo

**Objetivo:** facilitar acertar a célula certa da terra arada quando o jogador está com
semente, regador ou outro item de solo na mão.

**Depende de:** 26 (os talhões).

**Situação:** só registrado, em 2026-10-14, a pedido do Antonio.

## O pedido do Antonio (2026-10-14)

- Um sistema de snap: quando o jogador chega perto da terra arada com semente ou
  regador, a mira gruda na célula arada, para facilitar.
- Isso **não pode impedir** de arar as células do lado: a ajuda não pode prender a mira.

## Ideias para discutir

- A ajuda depende do item: com semente, a mira prefere a célula arada e vazia mais perto
  da frente do jogador; com regador, a arada e seca; com a enxada, nenhuma ajuda (ou a
  preferência por terra ainda não arada dentro do talhão).
- Só puxa se a célula preferida estiver a até uma célula de distância da mira normal.
  Fora disso, vale a mira normal, e o jogador ara a célula do lado sem briga.
- O indicador de alvo (`IndicadorAlvo`) mostra para onde a ajuda puxou.
