# Dungeons

A descrição de cada dungeon do jogo: tema, salas, inimigos, chefes, objetivo paralelo e
os modelos usados. As três são feitas do mesmo jeito (plano 23): cinco salas em fila, de
oeste para leste, com o subchefe na terceira e o chefe na quinta.

| Ordem | Dungeon | Abre quando | Chefe | Objetivo paralelo |
|---|---|---|---|---|
| 1 | [Galeria de Manutenção](galeria.md) | desde o começo | Compactador | destruir três geradores |
| 2 | [Biodomo Abandonado](biodomo.md) | vencendo o Compactador | Colheitadeira | resgatar quatro caixas de sementes |
| 3 | [Torre de Retransmissão](torre.md) | vencendo a Colheitadeira | O Auditor | proteger a antena pirata |

## O que vale para as três

- **Salas.** Limpar a sala (derrubar o último inimigo dela) abre a porta do leste e
  acorda os inimigos da sala seguinte. Antes disso eles dormem, para não sentirem o
  jogador através da parede.
- **Chefes.** Todo ataque próprio de chefe é anunciado por uma marca no chão, que enche
  até o dano cair. O chefe final muda de fase com metade da vida: fica mais rápido,
  ataca com menos intervalo e ganha ataques novos. O subchefe não tem segunda fase.
- **Em equipe.** Subchefe e chefe ganham 60% de vida por jogador além do primeiro. Os
  inimigos comuns não mudam.
- **Recompensa.** O baú da sala do chefe aparece quando ele cai. Paga créditos e
  materiais raros uma vez por dia, mais um tanto se o objetivo paralelo foi cumprido. Na
  primeira vitória de todas vem também o troféu do chefe, um item-chave.
- **Câmera.** Parede alta só ao norte, mureta ao sul. Peça alta no meio da sala fica
  translúcida quando esconde o jogador ou um inimigo.
- **Sem sangue.** Marca de ataque e faísca nunca são vermelhas.

## Onde mexer

| Para mudar | Arquivo |
|---|---|
| Tamanho das salas, inimigos, decoração, objetivo | a descrição da dungeon em `equipe/ferramentas/gerar_dungeons.py` (e gerar de novo) |
| Vida, dano e velocidade de um inimigo | `game/resources/combat/inimigos/<id>.tres` |
| Ataques e fases de um chefe | `game/resources/combat/chefes/<id>.tres` |
| Recompensa, ordem e o que libera a dungeon | `game/resources/dungeons/<id>.tres` |
| Um modelo | a função dele em `equipe/ferramentas/blender/modelos/` (e exportar de novo) |

Os números de vida, dano e recompensa são um ponto de partida. O acerto fino fica para
o balanceamento final.
