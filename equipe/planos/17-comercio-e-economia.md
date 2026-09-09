# Plano 17: Comércio e economia

**Objetivo:** NPCs comerciantes com loja, uma moeda, plantação como fonte primária de
renda, sementes compradas com NPC, baú para descarregar item, e o balanceamento que
amarra tudo.

**Depende de:** 04 (inventário), 06 (o que vender), 14 (quem vende), 15 (a loja abre pelo
diálogo).

É o último plano de propósito: ele só faz sentido quando os números dos outros sistemas
já existem.

## Decisões fechadas

**A moeda é o crédito, e não ocupa slot.** Um número no `EconomyManager`, mostrado na
HUD, não um item empilhado no inventário. O item `moeda` do catálogo do plano 03 vira
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

- [ ] **1.** Criar o `EconomyManager` e a HUD de créditos.
- [ ] **2.** Dar ao jogador o inventário inicial (as sementes) e os 500 créditos.
- [ ] **3.** Extrair `ContainerDeItens` se o plano 04 não extraiu, e criar o baú.
- [ ] **4.** Criar a tela de baú reusando o slot do plano 04. Colocar um baú em casa.
- [ ] **5.** Criar a caixa de entrega e o processamento no `day_ended`.
- [ ] **6.** Criar `catalogo_de_loja.gd` e os dois catálogos.
- [ ] **7.** Criar a tela de loja, aberta pelo diálogo com Marta e Vitor.
- [ ] **8.** Implementar horário e Folga.
- [ ] **9.** Ligar os três marcos ao `GameManager`, emitindo `city_expansion_blocked`.
- [ ] **10.** Jogar 30 dias seguidos e conferir o ritmo econômico. Ajustar preços.
- [ ] **11.** Documentar e commitar.

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
