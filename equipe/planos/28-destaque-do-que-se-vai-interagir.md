# Plano 28: Destaque do que se vai interagir

**Objetivo:** mostrar na tela, sem precisar adivinhar, qual objeto responde se o jogador
apertar o botão de interagir agora: baú, quadro do calendário, cama, NPC, porteira,
entrada de dungeon, peça de resgate.

**Situação:** feito em 2026-10-19.

## Revisão de 2026-10-19 (execução)

O plano só tinha ideias; ficou a mais simples de cada uma.

- **Brilho, e não contorno.** Um shader de camada (`material_overlay`) que soma um amarelo
  claro pulsante, mais forte na borda das faces. Contorno por casco inflado racha nas
  quinas dos modelos facetados, e o brilho não pesa: é uma passada a mais só no alvo.
- **Balão com tecla e verbo** acima do alvo ("F  Abrir baú"). A tecla vem do Input Map e
  troca para "A" quando o jogador usa o controle.
- **Uma regra só:** a `AreaDeInteracao` avisa pelo `EventBus` quando o alvo muda, e todo
  interagível ganha o destaque. Verbos escritos: baú, baú de venda, cama, calendário,
  NPC (com o nome), entrada e saída da dungeon, baú de recompensa, peça de resgate.
- **Partícula** pequena (`alvo_de_interacao`) no alvo novo.
- Testado no jogo: baú, cama, calendário, entrada da Galeria e a Iara mostram o balão
  certo e brilham; longe de tudo, nada aparece.

**Fora:** a porteira não entra, porque ela não usa o botão (basta andar por ela). A
planta madura também não, porque colher usa a célula à frente e não a área de interação;
fica para o plano 29, que cuida da mira no solo.

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
