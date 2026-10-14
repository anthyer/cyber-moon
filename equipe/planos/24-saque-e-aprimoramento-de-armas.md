# Plano 24: Saque por força do inimigo e aprimoramento de armas

**Objetivo:** os inimigos soltam materiais, os mais fortes soltam materiais melhores, e
esses materiais servem para aprimorar as armas com um NPC ferreiro, numa tela própria.

**Depende de:** 09 (inimigos e saque), 08 (armas), 15 (o ferreiro é um NPC com quem se
conversa), 17 (créditos, se o aprimoramento também custar dinheiro).

**Situação:** feito em 2026-10-13. Pedido do Antonio em 2026-10-07; decisões
fechadas em 2026-10-13.

## Revisão de 2026-10-13 (vale sobre o resto do plano)

**Situação:** feito. Os números (receitas, chances de saque, tempo de carga) são proposta
para ajustar jogando. Conferido por teste automático:

- 200 sentinelas soltaram material nas três faixas, perto das chances do perfil, com o
  brilho de aviso nos incomuns e raros.
- O bastão de choque vai de dano 20 a 25 e a 30. Sem material o aprimoramento é recusado;
  com material ele consome a sucata e os créditos. No nível 3 não há mais receita.
- Com o bastão no inventário, o Vitor não o vende e comprar de novo é recusado ("Você já
  tem uma."). Vendido pelo baú de venda, o nível volta a 1 e o Vitor volta a vender.
- A enxada no nível 1 ara um quadrado no toque. No nível 3: um quadrado no toque, 3 em
  linha segurando 0,6 s e 3 por 3 segurando 1,2 s, com a marcação no chão acompanhando. Os
  9 quadrados custaram 10 de stamina, contra 18 feitos um por um.
- O menu de serviços e a bancada do Vitor abrem e pausam o jogo. A bancada e a marcação
  de 3 por 3 foram conferidas por captura.

**Números propostos:**

| | Materiais | Créditos |
|---|---|---|
| Arma, nível 2 | 4 sucata de metal, 2 placa queimada, 2 célula de energia | 50 mais o valor de venda da arma |
| Arma, nível 3 | 3 fio óptico, 2 servomotor, 1 núcleo sintético | 150 mais 2,5 vezes o valor de venda |
| Ferramenta, nível 2 | 6 sucata de metal, 3 placa queimada | 150 |
| Ferramenta, nível 3 | 4 célula de energia, 2 fio óptico, 2 servomotor | 500 |

| Inimigo | Comum | Incomum | Raro | Nada |
|---|---|---|---|---|
| Drone | 60% | | | 40% |
| Ciborgue | 45% | 25% | | 30% |
| Sentinela | 20% | 50% | 20% | 10% |

Dano por nível: 1, 1,25 e 1,5 vezes. Stamina por etapa de área: 1, 2 e 5 vezes o custo de
um quadrado. Tempo por etapa ao segurar: 0,45 s. Tudo em
`game/resources/combat/aprimoramento.tres`, e as chances em cada perfil de inimigo.

**Ajustes ao plano:**

- **O nível fica no `UpgradeManager`, por id do item,** e não em cada pilha do inventário.
  Só é possível porque arma e ferramenta são únicas.
- **`Item.e_unico()`** diz o que é único (arma e ferramenta). A loja esconde o que o
  jogador já tem, no inventário ou em baú, e a compra é recusada.
- **A ferramenta no nível 1 age ao apertar, como antes.** A aprimorada age ao soltar, para
  dar tempo de segurar.
- **Carregando a ferramenta, o personagem fica parado.**
- **A área nunca custa mais stamina** do que os quadrados em que ela teve efeito custariam
  sozinhos.
- **O Vitor oferece a escolha** num menu pequeno depois da conversa: Loja, Aprimorar ou
  Sair.
- **Os cestos também são aprimoráveis,** porque são uma arma.
- **As faíscas do aprimoramento saem quando a bancada fecha,** porque a tela pausa o jogo.
- **Menu de debug:** seção Aprimoramento, com sucata, subir e zerar níveis e abrir a
  bancada.
- **Não feito:** a arma aprimorada não vale mais na venda. O saque dos chefes e subchefes
  depende do plano 23.

## Decisões fechadas com o Antonio (2026-10-13)

As perguntas da seção "O que precisa ser decidido antes de executar" foram respondidas. O
que vale:

**O ferreiro é o Vitor.** Depois da conversa do dia, ele oferece a loja ou a bancada de
aprimorar. Vale o mesmo horário da loja.

**Armas e ferramentas são únicas.** O jogador tem no máximo uma de cada. A loja não vende
uma arma que ele já tem. Por isso o nível é do item do jogador: não existem duas foices
com níveis diferentes. Vender a arma aprimorada perde o nível, e comprar de novo começa
do 1. O nível acompanha o item no baú de guardar.

**Três níveis por arma, e só o dano muda.** Sugestão de partida: nível 2 dá 25 por cento
a mais de dano, e nível 3 dá 50 por cento.

**O aprimoramento custa materiais e créditos.**

**Os materiais são as seis sucatas que já existem**, em três faixas:

| Faixa | Itens |
|---|---|
| Comum | `sucata_metal`, `placa_queimada` |
| Incomum | `celula_energia`, `fio_optico` |
| Rara | `servomotor`, `nucleo_sintetico` |

**O inimigo solta da faixa dele, com chance de subir.** O drone solta comum; o ciborgue,
comum ou incomum; a sentinela, incomum e às vezes raro. Os chefes e subchefes da dungeon
(plano 23) soltam raro. Cada `PerfilInimigo` tem a própria tabela de chances.

**Na dungeon em equipe o saque continua individual.**

**As ferramentas de fazenda são aprimoradas na mesma tela**, com materiais e créditos.
Elas nunca são vendidas nem trocadas: só aprimoradas. Cada nível aumenta a área:

| Nível | Área máxima |
|---|---|
| 1 | 1 quadrado |
| 2 | 3 em linha, à frente |
| 3 | 3 por 3 |

**A área maior sai segurando o botão.** Um toque faz um quadrado só, porque às vezes se
quer arar um quadrado mesmo. Segurando, a marcação no chão cresce em etapas até o máximo
do nível, e a ação acontece ao soltar. Dá para soltar no meio e fazer a área
intermediária. É o esquema do Rune Factory.

**A área maior custa menos stamina por quadrado** do que fazer um por vez (por exemplo, 9
quadrados pelo preço de 5). Aprimorar poupa tempo e stamina.

**O que isso muda no desenho técnico:** como cada arma e cada ferramenta é única, o nível
pode ficar num lugar só, por id do item (um dicionário num autoload, salvo no plano 20),
e não em cada pilha do inventário. A seção "O nível mora no item do jogador" abaixo
descrevia o caso mais difícil, que não é mais necessário.

**Ainda em aberto, para definir ao executar:** a receita exata de cada nível (quanto de
cada material e quantos créditos), os números das tabelas de saque, e o tempo de cada
etapa ao segurar o botão. São valores de balanceamento, e saem como proposta para ajustar
jogando.

## O que o Antonio pediu

Materiais dropados pelos inimigos, com inimigos mais fortes dropando itens melhores. Esses
itens podem ser usados para aprimorar armas num NPC ferreiro, numa interface específica.

## O que já existe

- **Saque:** cada `PerfilInimigo` tem `itens_dropados` e `chance_de_drop`. Ao morrer, o
  inimigo sorteia um item da lista. Hoje o drone solta um tipo de sucata, e o ciborgue e a
  sentinela soltam os mesmos dois. Não há diferença de qualidade por força.
- **Materiais:** seis sucatas no catálogo (`sucata_metal`, `placa_queimada`,
  `celula_energia`, `fio_optico`, `servomotor`, `nucleo_sintetico`), com valores de venda
  crescentes. Servem como ponto de partida para a escala de qualidade.
- **Armas:** `Arma` é um `Resource` com dano, alcance, custo de stamina, velocidade e
  cooldown. Não existe nível de arma.
- **Dungeon em equipe (plano 22):** o saque é individual. Cada jogo sorteia o próprio.
- **Regra dos itens (plano 17):** arma pode ser guardada e vendida, e não descartada.

## Ideias de desenho, para decidir

**Saque por faixa.** Em vez de uma lista só, o perfil do inimigo ganha uma tabela de saque:
cada linha com o item, a chance e a quantidade. A "força" do inimigo decide de qual faixa
de material ele sorteia. Três faixas bastam para começar (comum, incomum, raro), ligadas
às sucatas que já existem.

**Aprimorar é subir o nível da arma.** Cada arma tem níveis; cada nível pede uma receita
(tantos de tal material, e talvez créditos) e melhora um ou mais números da arma. A
receita e o ganho de cada nível são dado (`Resource`), e não código.

**O nível mora no item do jogador, não no arquivo da arma.** Hoje todas as foices são o
mesmo `Resource`. Para uma foice ter nível 3 e outra nível 1, o nível precisa ficar na
pilha do inventário (ou a arma aprimorada vira outro item). Esta é a decisão técnica mais
importante do plano, e mexe com o inventário e com o save (plano 20).

**A tela do ferreiro.** Abre pela conversa, como a loja. Mostra as armas do jogador, a
arma escolhida com os números de agora e os do próximo nível lado a lado, a receita com o
que o jogador tem e o que falta, e o botão de aprimorar.

## O que precisa ser decidido antes de executar

- **Quem é o ferreiro.** O Vitor, que já é o mecânico e vende as armas, ou um NPC novo?
- **Quantos níveis** cada arma tem, e o que cada nível melhora (dano, alcance, custo de
  stamina, velocidade, cooldown).
- **A receita de cada nível:** só materiais, ou materiais e créditos?
- **O que é "inimigo mais forte".** Hoje são três inimigos. A dungeon (plano 23) vai
  trazer subchefes e chefes, que são o lugar natural do material raro.
- **Materiais novos ou os seis que já existem?**
- **Ferramenta de fazenda entra aqui?** O Antonio já disse que ferramenta é melhorada,
  trocada por versão melhor (nota do plano 17). Pode ser a mesma tela e o mesmo ferreiro,
  ou continuar como compra. Vale decidir junto.
- **Em equipe na dungeon:** o saque continua individual?

## Partículas

Plano escrito depois da regra de partículas, então as ações dele nascem com efeito: o
material raro caindo do inimigo (um brilho na cor da raridade) e a arma sendo aprimorada
no ferreiro (faíscas).

## Tarefas (rascunho, a fechar depois das decisões)

- [x] **1.** Tabela de saque no `PerfilInimigo`, com faixas de raridade.
- [x] **2.** Onde mora o nível da arma, e o inventário e o combate lendo dele.
- [x] **3.** As receitas de aprimoramento como `Resource`.
- [x] **4.** O ferreiro e a tela de aprimorar.
- [x] **5.** Partículas do saque raro e do aprimoramento.
- [x] **6.** Documentar e commitar.

## Fora de escopo

- **Encantamento, gema e atributo aleatório.** Aprimorar é subir de nível, e só.
- **Desmontar arma para recuperar material.**
- **Armadura e acessório aprimoráveis.** Os espaços existem no inventário, mas não há
  itens para eles ainda.
