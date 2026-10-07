# Plano 23: Conteúdo da dungeon

**Objetivo:** transformar a dungeon de teste do plano 22 numa dungeon de verdade: várias
salas, subchefes, um chefe e um objetivo.

**Depende de:** 22.

**Situação:** só documentado. Decisão do Antonio em 2026-10-06: primeiro o esqueleto do
coop funcionando (plano 22), depois o conteúdo.

## A ideia do Antonio

Dungeons onde ficam os monstros, com um objetivo, chefes e subchefes. Os amigos entram
juntos pelo lobby, enfrentam os monstros e seguem em coop até superar os inimigos. Na
dungeon não há horário nem clima: a progressão é enfrentar os bichos e coletar itens.

## O que precisa ser decidido antes de executar

- **Estrutura:** salas fixas em sequência, ou sorteadas a cada entrada?
- **Objetivo:** matar o chefe, ou algo além disso (coletar, proteger, cronômetro)?
- **Chefes e subchefes:** quantos, e o que cada um faz de diferente de um inimigo comum.
  Precisam de padrões de ataque próprios, e o plano 09 só tem três inimigos.
- **Recompensa:** o que a dungeon dá que a fazenda não dá, e como isso entra na economia
  do plano 17.
- **Custo de entrada e frequência:** entra quando quiser, ou uma vez por dia?
- **Quantas dungeons,** e como elas se ligam aos marcos da história (`GameManager`).

## O que o plano 22 já deixa pronto

- Entrar e sair sem perder a fazenda, com relógio parado e luz fixa.
- Inimigos criados a partir de marcadores na cena, comandados pelo anfitrião.
- O aviso de "todos os inimigos caíram", que é o gancho para abrir a porta da sala
  seguinte.
- O canal de mensagens da sala, para o que precisar ser sincronizado (porta, chefe).

## Partículas

Plano escrito depois da regra de partículas: porta abrindo, chefe aparecendo e morrendo,
e recompensa final já nascem com efeito.
