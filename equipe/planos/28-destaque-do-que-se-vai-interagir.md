# Plano 28: Destaque do que se vai interagir

**Objetivo:** mostrar na tela, sem precisar adivinhar, qual objeto responde se o jogador
apertar o botão de interagir agora: baú, quadro do calendário, cama, NPC, porteira,
entrada de dungeon, peça de resgate.

**Situação:** só registrado, em 2026-10-14, a pedido do Antonio.

## O pedido do Antonio (2026-10-14)

- Indicações visuais do que está sendo selecionado para interação no momento, como baús,
  calendário etc.

## Ideias para discutir

- Um contorno ou brilho no objeto escolhido (o mais perto dentro da área de interação do
  jogador), mais um balão pequeno com o botão e o verbo ("E · Abrir baú").
- Uma regra só para todo interagível, para não tratar caso a caso: quem está no contrato
  de interação (`AreaDeInteracao`) ganha o destaque sem código novo.
- Cuidado com o renderizador Compatibility: contorno por shader de segunda passada
  funciona, mas pesa em objeto grande. Testar o custo.
- Partícula discreta ao trocar de alvo, conforme a regra de partículas.
