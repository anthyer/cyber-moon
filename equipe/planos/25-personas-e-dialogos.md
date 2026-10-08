# Plano 25: Revisão das personas e dos diálogos

**Objetivo:** cada um dos seis NPCs vira um personagem escrito de verdade, com uma ficha
de persona feita por boas práticas, e os diálogos passam a variar conforme a
personalidade, o clima, o dia da semana, a estação, as datas especiais e as situações
especiais.

**Depende de:** 15 (diálogo), 16 (amizade), 13 (clima), 12 (dia da semana e aniversário).

**Situação:** só documentado. Pedido do Antonio em 2026-10-07, para ser o próximo depois
do plano 20.

## O que o Antonio pediu

Um plano de revisão das personalidades dos personagens e dos seus diálogos, que devem
estar de acordo com a personalidade, o clima, o dia da semana, a estação, datas especiais,
situações especiais e o que mais couber. Os personagens devem ser criados seguindo boas
práticas de criação de personas.

## O que existe hoje

- **Personagens:** seis, com um parágrafo cada em `equipe/biblioteca-de-dialogos.md`
  (idade, papel, um traço de temperamento e uma motivação). Não há ficha.
- **Falas:** 19 falas do dia por NPC: de 3 a 4 por faixa de amizade (distante, conhecido,
  amigo, íntimo) e uma por estação. Mais as de evento: cinco reações a presente, uma de
  aniversário e as de buquê.
- **O que o sistema sabe filtrar:** só a faixa de amizade e a estação (`NoDialogo`). A fala
  do dia é uma por dia, escolhida pelo número do dia.
- **O que o sistema ainda não sabe:** clima, dia da semana, hora do dia, data especial e
  situação especial. Os dados existem no jogo (`WeatherManager`, `SeasonManager`,
  `DayCycleManager`, `StatusManager`, `RelationshipManager`), mas a fala não olha para eles.

## Parte 1: fichas de persona

Uma ficha por personagem, em `equipe/personas/<id>.md`, antes de escrever qualquer fala.
A ficha é a fonte da verdade: toda fala nova é conferida contra ela.

O que a ficha precisa ter, pelas práticas usuais de criação de personagem:

- **Quem é, em uma frase.** Se não cabe numa frase, o personagem ainda não está claro.
- **História:** de onde veio, o que perdeu, por que está aqui. Só o que explica o
  comportamento de hoje.
- **O que quer e o que precisa.** O desejo é o que ele diz que quer; a necessidade é o
  que resolveria a vida dele e que ele não enxerga. A distância entre os dois é o arco.
- **Medo e ferida.** O que ele evita, e o que aconteceu para ele evitar.
- **Contradição.** Um traço que briga com outro (o ranzinza que guarda peça para os
  outros). É o que tira o personagem do estereótipo.
- **Valores e limites:** o que ele nunca faria, e o que faria por alguém.
- **Voz:** tamanho de frase, vocabulário, bordões, o que ele nunca diz, como muda quando
  está à vontade. Com exemplos de certo e errado.
- **Relações:** o que pensa de cada um dos outros cinco e do jogador. As falas de um NPC
  sobre outro precisam bater dos dois lados.
- **Rotina e gostos**, já definidos nos planos 14 e 16, com o porquê de cada um.
- **Arco com o jogador:** o que muda nele em cada faixa de amizade, e o que ele só conta
  quando é íntimo.
- **Como reage** ao clima, às estações, ao próprio aniversário e ao dos outros.

Dois testes para cada ficha: tirando o nome, dá para saber de quem é a fala? E os seis
soam diferentes entre si, lado a lado?

## Parte 2: a matriz de falas

O que deve fazer a fala mudar, do mais geral para o mais específico:

| Eixo | Exemplos |
|---|---|
| Faixa de amizade | distante, conhecido, amigo, íntimo, namorando |
| Estação | brotação, estiagem, colheita, apagão |
| Clima | sol, chuva, tempestade |
| Dia da semana | dia de trabalho, Folga, véspera de Folga |
| Hora do dia | manhã, almoço, fim de tarde, noite |
| Onde ele está | no trabalho, na praça, em casa, na beira do rio |
| Datas especiais | aniversário dele, aniversário de outro NPC, primeiro e último dia da estação, virada do ano |
| Situações do jogador | primeiro encontro, voltou depois de dias sem aparecer, desmaiou ontem, vida baixa, acabou de sair da dungeon, está namorando outra pessoa, vendeu muito, alcançou um marco |
| Situações do mundo | primeira chuva depois da estiagem, tempestade ontem, o Apagão começando |

A regra de escolha é a mesma da rotina do plano 14: entre as falas que servem para o
momento, vence a mais específica. Assim uma fala geral de "conhecido" convive com a fala
de "primeiro dia do Apagão, chovendo".

Não é para preencher a matriz inteira, que teria milhares de casas. É para cada
personagem ter falas nos cruzamentos que dizem algo sobre ele: a Iara na tempestade, o
Rafa na Folga, o Kenji no primeiro dia do Apagão.

## Parte 3: o que muda no sistema

- **`NoDialogo` ganha condições:** climas, dias da semana, faixa de hora, lugar, e uma
  lista de situações (marcas como `primeiro_encontro` ou `desmaiou_ontem`).
- **A escolha passa a ser pela mais específica**, com o número do dia desempatando.
- **Um lugar só decide quais situações valem agora**, perguntando aos outros sistemas.
- **Primeiro encontro e falas que só acontecem uma vez** precisam de memória, que entra no
  save (plano 20).
- **O gerador** (`gerar_dialogos.gd`) passa a ler as condições novas da biblioteca.
- **Mais de uma fala nova por dia?** Hoje é uma. Com situações especiais, pode fazer
  sentido a fala especial vir além da do dia. O indicador amarelo em cima do NPC já foi
  pensado para isso.

## O que precisa ser decidido antes de executar

- **Tom do jogo:** quanto de humor, quanto de melancolia, quanto da crítica à cidade.
- **Quantas falas por personagem** é o alvo. Hoje são 19 do dia.
- **Quem escreve e quem revisa.** As fichas pedem decisão de autor.
- **Os seis continuam como estão** (nome, idade, papel), ou a revisão pode mudar isso?
- **Namoro:** o que muda na fala de quem namora o jogador, e na dos outros.
- **Falas que citam outro NPC:** vale ter, sabendo que dão mais trabalho de manter.

## Partículas

Plano escrito depois da regra de partículas. Ele não cria ação nova no mundo: muda o que
os personagens dizem. Se uma situação especial ganhar um gesto ou efeito próprio (o NPC
comemorando o aniversário), o efeito nasce junto.

## Tarefas (rascunho, a fechar depois das decisões)

- [ ] **1.** Escrever as seis fichas de persona e passar pelos dois testes.
- [ ] **2.** Revisar as falas que já existem contra as fichas.
- [ ] **3.** Ampliar o `NoDialogo` e a escolha da fala para os eixos novos.
- [ ] **4.** O lugar que decide as situações que valem agora, e a memória do que já foi
  dito uma vez.
- [ ] **5.** Escrever as falas novas na biblioteca, por personagem.
- [ ] **6.** Atualizar o gerador e gerar.
- [ ] **7.** Ler todas as falas de cada personagem em sequência, em voz alta.
- [ ] **8.** Documentar e commitar.

## Fora de escopo

- **Diálogo com escolha de resposta.** O sistema permite, mas é outro trabalho.
- **Eventos de coração** (cena especial ao atingir certos corações). Estão em
  `sugestoes-de-features.md`, e combinam com este plano, mas são cenas, não falas.
- **Dublagem.**
