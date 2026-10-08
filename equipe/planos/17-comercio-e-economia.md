# Plano 17: Comércio e economia

**Objetivo:** NPCs comerciantes com loja, uma moeda, plantação como fonte primária de
renda, sementes compradas com NPC, baú para descarregar item, e o balanceamento que
amarra tudo.

**Depende de:** 04 (inventário), 06 (o que vender), 14 (quem vende), 15 (a loja abre pelo
diálogo).

É o último plano de propósito: ele só faz sentido quando os números dos outros sistemas
já existem.

## Revisão de 2026-10-07 (vale sobre o resto do plano)

**Situação:** feito, menos a tarefa 10 (jogar 30 dias e ajustar preços), que é de jogar e
fica com o balanceamento final. Conferido por teste automático:

- O jogo começa com 500 créditos, os cestos, as três ferramentas e 5 sementes de cenoura
  e 5 de trigo.
- Preços de compra: semente de cenoura 15, de trigo 12, de tomate 18 (60 por cento da
  colheita); pão 60 e bastão de choque 240 (o dobro da venda).
- Conversar com a Marta às 7:00 rende a fala "Tô fechando", sem tela. Às 10:00, a loja
  abre depois da conversa. Na Folga a loja está fechada.
- Comprar 5 sementes de tomate leva de 500 para 410 créditos e põe as 5 no inventário.
  Sem crédito a compra é recusada e nada muda.
- O baú de venda aceita cenoura e foice e recusa a enxada; o de guardar aceita os três.
- Com 10 cenouras e uma foice no baú de venda, virar o dia rende 310 créditos e esvazia o
  baú. O que está no baú de guardar continua lá, e volta ao inventário.
- Passar de 2000 vendidos desbloqueia o `marco_1`, e o catálogo do Vitor vai de 3 para 4
  itens.
- A loja, a tela de baú, o saldo na HUD e o resumo de vendas foram conferidos por captura.

**Ajustes ao plano:**

- **Sinais em inglês:** `credits_changed` e `sale_completed`.
- **Um script de baú só** (`Bau`, com a função GUARDAR ou VENDER), e não um baú e uma
  `CaixaDeEntrega` separados. O de venda se chama "Baú de venda", como o Antonio chamou.
- **`ContainerDeItens` é uma classe nova, ao lado do `InventoryManager`.** O inventário
  não foi reescrito em cima dela, para não mexer no que os planos 04 a 16 já usam.
- **Na tela de baú não se arrasta:** um clique (ou confirmar, no controle) manda a pilha
  inteira para o outro lado.
- **A loja abre depois da conversa do dia** com o comerciante. Fechada, ele diz por quê.
- **O que cada item pode fazer** virou três funções do `Item`: `pode_ser_descartado()`,
  `pode_ser_vendido()` e `pode_ser_guardado()`, seguindo a tabela da nota abaixo.
- **`Item.preco_de_compra`** permite escrever um preço à mão; zero usa a regra.
- **O inventário inicial é um Resource** (`resources/items/inventario_inicial.tres`). As
  armas, os pães e as outras sementes saíram do começo do jogo; o menu de debug as dá.
- **O gerador de NPCs roda como cena** (`scenes/utils/gerar_npcs.tscn`), porque o catálogo
  consulta autoloads. Os catálogos saem da tabela dele, em `resources/lojas/`.
- **A Marta vende o buquê** e, depois do `marco_1`, o nutrisolo. O Vitor vende nanogel,
  estimulante e bastão de choque; a foice entra no `marco_1`, o espadão e a escopeta no
  `marco_2`.
- **Fora do que o plano pedia e não feito:** o baú comprável com o Vitor (colocar baú no
  mundo é outro sistema), a expansão da grade de solo no `marco_2`, e a melhoria de
  ferramenta, que espera a definição dos níveis.
- **Sem partículas**, porque o plano é anterior à regra. Ficam para o plano 19.

## Nota de 2026-10-07: baú de venda confirmado pelo Antonio

O Antonio pediu, de novo e com as próprias palavras, o que este plano chama de caixa de
entrega: um baú de venda na fazenda, onde o jogador coloca os itens; ao dormir, eles são
vendidos e o dinheiro vai para a conta dele. Está no escopo, nas seções "A caixa de
entrega" e na tarefa 5. O que precisa valer ao executar:

- **A venda acontece na virada do dia**, seja dormindo na cama, caindo de sono ou
  desmaiando. É o `day_ended`, que os três caminhos disparam.
- **O que cada tipo de item pode fazer** (especificação do Antonio):

  | Item | Baú de guardar | Baú de venda | Lixeira e soltar |
  |---|---|---|---|
  | Comum (colheita, recurso, semente, consumível, material) | sim | sim | sim |
  | Arma | sim | sim | não |
  | Ferramenta de fazenda | sim | nunca | não |
  | Item-chave | não | nunca | não |

- **Arma sai do inventário por dois caminhos:** ou vai para o baú de guardar, ou é
  vendida. Ela continua sem poder ser solta nem jogada na lixeira.
- **Ferramenta de fazenda nunca é vendida.** Ela é melhorada: o jogador troca a que tem
  por uma versão melhor. Pode ser guardada no baú.
- **Isso separa três perguntas no `Item`**, que hoje têm uma resposta só
  (`pode_ser_descartado()`): pode descartar (lixeira e soltar), pode vender (baú de
  venda) e pode guardar (baú de guardar). Ao executar, criar `pode_ser_vendido()` e
  `pode_ser_guardado()` ao lado da que já existe, cada uma seguindo a tabela acima.
- **Melhoria de ferramenta é escopo novo.** O plano 17 já tem o Vitor vendendo
  equipamento; a troca da ferramenta por uma versão melhor entra ali, como compra que
  substitui a antiga em vez de somar. Falta definir quantos níveis cada ferramenta tem e
  o que cada nível melhora (área, custo de stamina, velocidade). Decidir antes de
  executar.
- **O resultado aparece ao acordar**, como o plano já prevê.

## Decisões fechadas

**A moeda é o crédito, e não ocupa slot.** Um número no `EconomyManager`, mostrado na
HUD, não um item empilhado no inventário. O item `credito` do catálogo do plano 03 vira
apenas o ícone usado na interface.

**O jogador começa com 500 créditos e algumas sementes.** Como o Antonio pediu: só o
suficiente para o primeiro plantio. A sugestão é 5 de semente de cenoura e 5 de trigo,
que são as duas mais rápidas e mais baratas.

**Dois comerciantes, com catálogos que não se sobrepõem.** Marta vende semente,
ferramenta e comida. Vitor vende equipamento, arma e o baú. Assim cada um tem uma
identidade clara e o jogador aprende para onde ir.

**Vender é pelo baú de entrega, não pelo balcão.** Uma caixa na fazenda onde o jogador
deposita a produção; de madrugada ela é recolhida e o crédito aparece no dia seguinte.
Esse é o mecanismo de Stardew, e ele existe por um motivo bom: deixa o jogador vender sem
gastar o dia andando até a loja, o que é a diferença entre a fazenda ser lucrativa e ser
uma tarefa chata.

Comprar continua sendo cara a cara com o NPC.

**A loja fecha na Folga e fora do horário comercial** (9:00 às 18:00). Tentar comprar
fora disso rende uma fala, não uma tela.

## A economia

**Preço de compra é o dobro do valor de venda**, com exceções escritas à mão. É uma regra
simples e previsível, e o jogador entende sozinho que produzir vale mais que revender.

Semente é a exceção importante: ela custa cerca de 60 por cento do valor da colheita que
produz. Isso deixa o lucro por plantio em torno de 40 por cento no começo, e cresce quando
o jogador aprende a escolher o cultivo certo para a estação.

| Cultivo | Semente custa | Colheita vale | Dias até colher | Lucro por dia |
|---|---|---|---|---|
| Cenoura | 15 | 25 | 3 | 3.3 |
| Trigo | 12 | 20 | 3 | 5.3 (rende 2 a 3) |
| Beterraba | 21 | 35 | 6 | 2.3 |
| Repolho | 30 | 50 | 6 | 3.3 |
| Milho | 24 | 40 | 6 | 2.7, e rebrota |
| Tomate | 18 | 30 | 9 | 1.3, e rebrota |

Tomate e milho parecem ruins na tabela e são os melhores no longo prazo, porque rebrotam
e você planta uma vez só. É uma armadilha de leitura proposital, do tipo que recompensa
quem presta atenção.

**A sucata de inimigo é renda secundária e irregular.** Ela existe para o combate valer a
pena, não para substituir a fazenda.

## Progressão

Três marcos, ligados ao `GameManager` que já existe com `desbloquear_marco` e
`marcos_desbloqueados`. Isso finalmente dá uso ao sinal `city_expansion_blocked` que está
declarado no `EventBus` desde o começo do projeto e nunca foi emitido.

| Marco | Condição | Desbloqueia |
|---|---|---|
| `marco_1` | 2.000 créditos acumulados em vendas | Vitor passa a vender o baú e a foice |
| `marco_2` | 10.000 acumulados | armas melhores, expansão da grade de solo |
| `marco_3` | 30.000 acumulados | o confronto com a cidade (não implementado) |

O acumulado é o total já vendido, não o saldo atual. Assim gastar não atrasa a história.

## Modelo

`game/scripts/core/economy_manager.gd`, autoload novo:

```gdscript
extends Node

signal creditos_alterados(saldo: int)
signal venda_realizada(total: int, itens: int)

const CREDITOS_INICIAIS: int = 500

var creditos: int = CREDITOS_INICIAIS
var total_vendido: int = 0

func pode_pagar(valor: int) -> bool
func gastar(valor: int) -> bool
func receber(valor: int) -> void
func preco_de_compra(item: Item) -> int
func processar_caixa_de_entrega(pilhas: Array[PilhaDeItens]) -> int
```

`game/scripts/resources/catalogo_de_loja.gd`:

```gdscript
class_name CatalogoDeLoja
extends Resource

@export var npc_id: String = ""
@export var itens: Array[Item] = []
## Item que so aparece depois de um marco. Mesmo indice do array acima.
@export var marco_necessario: Array[String] = []
@export var hora_de_abrir: float = 9.0
@export var hora_de_fechar: float = 18.0
```

`perfil_npc.gd` ganha `@export var catalogo: CatalogoDeLoja`, nulo para quem não vende.

## O baú

Um `Resource` de armazenamento reusando a lógica de slots do plano 04. O jeito limpo é o
plano 04 já ter separado a lógica de container do autoload; se não separou, este é o
momento de extrair uma classe `ContainerDeItens` que tanto o `InventoryManager` quanto o
baú usam.

```gdscript
class_name Bau
extends Node3D

@export var total_de_slots: int = 24
@export var conteudo: Array[PilhaDeItens] = []
```

Cena `game/scenes/items/bau.tscn`, modelo placeholder `crate.glb` ou similar do
`kenney_nature_kit`. Interagir abre uma tela com o inventário do jogador embaixo e o baú
em cima, arrastando entre os dois. É a mesma cena de slot do plano 04, reusada de novo.

**O jogador começa com um baú em casa**, colocado à mão no `playground.tscn`. Baús
adicionais são comprados com o Vitor depois do `marco_1`.

## A caixa de entrega

Igual ao baú por fora, mas com comportamento próprio: no `day_ended`, ela soma o
`valor_de_venda` de tudo que está dentro, chama `EconomyManager.receber()`, esvazia, e o
jogador vê o resultado numa telinha ao acordar.

Uma instância na fazenda, colocada à mão, chamada `CaixaDeEntrega`.

## Tarefas

- [x] **1.** Criar o `EconomyManager` e a HUD de créditos.
- [x] **2.** Dar ao jogador o inventário inicial (as sementes) e os 500 créditos.
- [x] **3.** Extrair `ContainerDeItens` se o plano 04 não extraiu, e criar o baú.
- [x] **4.** Criar a tela de baú reusando o slot do plano 04. Colocar um baú em casa.
- [x] **5.** Criar a caixa de entrega e o processamento no `day_ended`.
- [x] **6.** Criar `catalogo_de_loja.gd` e os dois catálogos.
- [x] **7.** Criar a tela de loja, aberta pelo diálogo com Marta e Vitor.
- [x] **8.** Implementar horário e Folga.
- [x] **9.** Ligar os três marcos ao `GameManager`, emitindo `city_expansion_blocked`.
- [ ] **10.** Jogar 30 dias seguidos e conferir o ritmo econômico. Ajustar preços.
- [x] **11.** Documentar e commitar.

## Critério de pronto

- O jogador começa com 500 créditos e sementes suficientes para o primeiro plantio.
- Comprar semente com a Marta desconta o crédito e o item entra no inventário.
- Colocar colheita na caixa de entrega e dormir rende crédito no dia seguinte.
- O baú guarda item e devolve, e o conteúdo continua lá no dia seguinte.
- A loja recusa atendimento na Folga e fora do horário.
- Chegar a 2.000 vendidos desbloqueia o `marco_1` e o catálogo do Vitor cresce.
- Uma temporada inteira de cenoura dá lucro, e dá para perceber isso jogando.

## Fora de escopo

- **Preço flutuando com oferta e procura.** Charmoso, e uma armadilha de escopo.
- **Fabricação e receita.** Os materiais processados do catálogo do plano 03 ainda não
  têm como ser feitos. É a lacuna mais visível que este plano deixa, e está registrada em
  `pendencias.md`.
- **Melhoria de ferramenta.** Combinaria com o Vitor, e é a evolução natural.
- **Banco, empréstimo, dívida inicial.** Harvest Moon faz, e muda o jogo inteiro.
- **Munição comprável.** Ligado ao fora de escopo do plano 08.
- **Salvar a economia.** Junto do save geral, que continua defasado.
