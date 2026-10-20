# Plano 29: Ajuda para mirar no solo

**Objetivo:** facilitar acertar a célula certa da terra arada quando o jogador está com
semente, regador ou outro item de solo na mão.

**Depende de:** 26 (os talhões).

**Situação:** feito em 2026-10-19.

## Revisão de 2026-10-19 (execução)

- `GradeSolo.celula_com_ajuda(celula, posicao_do_jogador, ajuda)`: se a célula da mira
  normal já serve, fica ela; se não, a vizinha que serve mais perto da mira, dentro de 2
  do jogador. A célula embaixo do próprio jogador não conta.
- **Semente** prefere terra arada e vazia; **regador**, terra arada e seca; **enxada e
  picareta** não têm ajuda, então arar a célula do lado nunca briga com a mira.
- **Colher** também ganhou a ajuda: o botão de interagir colhe a planta madura vizinha, e
  o indicador marca a célula dela. Era o que tinha ficado de fora do plano 28.
- O `IndicadorAlvo` mostra a célula para onde a ajuda puxou.
- Testado no jogo: arada a célula ao lado da mira, a semente foi para ela; com a enxada a
  mira ficou onde estava; com a arada a duas células, a ajuda não puxou; depois de
  molhada, o regador deixou de preferir a célula.
- Sem partícula nova: a ajuda não cria ação; plantar e molhar já têm efeito.

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
