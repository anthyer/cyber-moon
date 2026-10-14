# Plano 23: Conteúdo da dungeon

**Objetivo:** transformar a dungeon de teste do plano 22 numa dungeon de verdade: várias
salas, subchefes, um chefe e um objetivo.

**Depende de:** 22.

**Situação:** feito em 2026-10-13. As três dungeons estão jogáveis, sozinho e em dupla.
A descrição de cada uma está em `equipe/dungeons/`.

## Revisão de 2026-10-13 (execução)

**O que foi entregue**

- Três dungeons: Galeria de Manutenção, Biodomo Abandonado e Torre de Retransmissão.
  Cada uma com cinco salas, dois inimigos próprios, subchefe, chefe com duas fases,
  objetivo paralelo, baú de recompensa e troféu.
- A base em código: `DefinicaoDeDungeon`, `SalaDeDungeon`, `PortaDeDungeon`, `Chefe` com
  `PerfilChefe` e `AtaqueDeChefe`, `AvisoDeAtaque`, os três `ObjetivoParalelo`,
  `BauDeRecompensa`, `HudDeDungeon`, `HudDoChefe` e a escolha da dungeon no lobby.
- Um pacote de 63 modelos próprios (`assets/models/cyber_moon_dungeons/`), feitos no
  Blender no estilo dos pacotes do jogo, com o guia em `game/docs/biblia_3d.md`.
- `CoberturaTranslucida`: a peça alta que esconde o jogador ou um inimigo fica
  translúcida.
- Partículas em sala limpa, porta, chefe (aparecer, atacar, mudar de fase, cair),
  objetivo e recompensa, na tabela do `EfeitosDoJogo`.

**Decisões tomadas na execução**

- **Os inimigos são máquinas de malha rígida.** O Antonio pediu inimigos no tema de cada
  dungeon e chefes de cara mais agressiva. Máquina não precisa de esqueleto: as partes
  são animadas por código pelo nome (`MaquinaAnimada`). Os três inimigos antigos (drone
  rastejador, ciborgue operário, sentinela pesada) continuam existindo, fora das dungeons.
- **As salas ficam em fila, de oeste para leste.** A câmera olha do sul para o norte;
  com parede alta só ao norte e mureta ao sul, nada cobre o jogador. Uma sala ao norte
  da outra ficaria com um pedaço escondido atrás da parede.
- **As cenas são geradas por script** (`equipe/ferramentas/gerar_dungeons.py`), a partir
  de uma descrição curta. Montar à mão quatrocentos nós por dungeon era erro na certa, e
  o número do inimigo na rede depende de a cena ser idêntica nos dois jogos.
- **O objetivo de resgate não falha.** Caixa que ficou para trás só não conta. Os outros
  dois falham (gerador de pé quando o chefe cai; antena destruída).
- **Destruir os geradores tira um quarto da vida do chefe**, além de melhorar o baú. É o
  que faz o objetivo valer a pena durante a luta, e não só depois.
- **O tiro de inimigo passou a ser transmitido.** Era uma pendência do plano 22, e duas
  das três dungeons têm inimigo de distância. O convidado vê o tiro (só o desenho); o
  dano continua vindo do jogo do anfitrião.
- **A dungeon de teste do plano 22 foi apagada** (`scenes/levels/dungeon.tscn`).

**Como foi testado**

- Sozinho, as três dungeons do começo ao fim por script: salas limpam, portas abrem, o
  chefe ataca e muda de fase, o baú paga, a seguinte é liberada.
- Em dupla, com dois jogos e o servidor local: vida do chefe 60% maior, salas, portas,
  objetivo, marcas de ataque, troca de fase, tiros e recompensa iguais nos dois lados.
- Por captura de tela: cada sala das três dungeons, a translucidez e as lutas de chefe.
- Ninguém jogou com a mão. O que os testes não dizem é se a luta está gostosa.

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
