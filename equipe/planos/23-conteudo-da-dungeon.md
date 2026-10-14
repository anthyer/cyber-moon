# Plano 23: Conteúdo da dungeon

**Objetivo:** transformar a dungeon de teste do plano 22 numa dungeon de verdade: várias
salas, subchefes, um chefe e um objetivo.

**Depende de:** 22.

**Situação:** decidido em 2026-10-13, ainda não executado. O esqueleto do coop (plano 22)
está pronto.

## Decisões fechadas com o Antonio (2026-10-13)

As perguntas da seção "O que precisa ser decidido antes de executar" foram respondidas.

**Três dungeons diferentes, cada uma com tema, inimigos e chefe próprios.** As três ficam
jogáveis agora em mock (cenário e chefes de caixas). A arte de verdade espera o Antonio
ligar o MCP do Blender; até lá, cada dungeon tem um documento de descrição, para o tema
ser feito certo depois.

**Salas fixas em sequência.** Cada dungeon é desenhada à mão: salas de inimigos, uma sala
de subchefe no meio e a do chefe no fim. Limpar a sala abre a porta da próxima.

**A dungeon seguinte abre vencendo o chefe da anterior.** A primeira está aberta desde o
começo. Não depende dos marcos de venda.

**O objetivo é derrotar o chefe, mais um objetivo paralelo, diferente em cada dungeon:**
destruir geradores da corporação numa, resgatar peças em outra, proteger um ponto na
terceira. Cumprir o paralelo melhora a recompensa.

**Chefes são inimigos únicos, maiores e com personalidade.** Bem mais vida, uns três
ataques próprios com aviso antes (uma área marcada no chão) e duas fases: com metade da
vida, ficam mais rápidos e ganham um ataque. O subchefe é a versão menor, com um ataque
especial só. O visual fica em mock por enquanto.

**Entrada livre, recompensa grande uma vez por dia.** Entra-se quantas vezes quiser para
lutar e pegar sucata. O baú do chefe só dá a recompensa grande na primeira vitória do dia.

**Recompensa do chefe:** em toda primeira vitória do dia, materiais raros garantidos e
créditos. Na primeira vitória de todas, um item-chave próprio de cada chefe, que libera a
dungeon seguinte e fica como troféu.

**Em equipe, subchefe e chefe têm mais vida** (ponto de partida: 60 por cento a mais com
dois jogadores). Os inimigos comuns ficam iguais.

**O que falta definir ao executar** (sai como proposta para o Antonio revisar): o tema, o
nome, os inimigos e a personalidade do chefe de cada dungeon; qual objetivo paralelo vai
em qual; o número de salas; e os valores de vida, dano e recompensa.

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
