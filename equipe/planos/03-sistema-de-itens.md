# Plano 03: Sistema de itens

**Objetivo:** ampliar a classe `Item` para cobrir tudo que o jogo vai precisar, criar o
catálogo inicial de itens com a temática do jogo, e fazer item existir no mundo como
objeto que gira no chão e vai para o inventário quando o jogador interage.

**Depende de:** plano 01, pela camada `item_no_chao`.

**Entrega para:** 04 (inventário), 06 (colheita produz item), 08 (arma é item), 16
(presente é item), 17 (comércio vende item).

## Revisão de 2026-09-29 (vale sobre o resto do plano)

O plano foi revisado contra o código antes de começar. Onde esta seção contradiz o texto
abaixo, vale esta seção.

**Situação (2026-09-29):** feito. Os critérios de pronto foram conferidos por um teste
automático no playground, que coletou os três itens de demonstração pelo `interagir` e
usou a enxada. O teste à mão fica com o Antonio, pelos itens do nó
`ItensDeDemonstracao`.

**Catálogo aprovado pelo Antonio:** sucata na categoria RECURSO; valores de venda de
pão de trigo 30, sopa de legumes 70, estimulante 55, nanogel 80 e buquê 60; ids
`moeda` e `servo_motor` renomeados para `credito` e `servomotor`.

**Billboard:** o `ItemNoMundo` não usa billboard, porque ele anula o giro. O quadrado
gira de verdade, e cópias do sprite logo atrás dele dão espessura ao item. Se não agradar, basta
ligar o billboard no `Visual` e aceitar que só a flutuação aparece.

**Decisões do Antonio:**

- **Ícones placeholder.** Só as 6 colheitas têm arte (16x16 em
  `assets/textures/tiny_farm_crops/`). Os outros 31 itens ganham um ícone 16x16 simples,
  com forma e cor por categoria, gerado por um script versionado em
  `equipe/ferramentas/`. Arte de verdade entra depois, trocando só o PNG apontado no
  `.tres`. Os ícones ficam em `assets/textures/icones_itens/`.
- **Catálogo revisado antes de gerar.** Nomes, ids e valores das tabelas abaixo são um
  primeiro chute. Depois do modelo de dados, a tabela é mostrada ao Antonio para ajuste,
  e só então os `.tres` são gerados.

**Ajustes ao plano encontrados na revisão:**

- **Sinal em inglês.** A convenção pede sinal em inglês no passado. O sinal fica
  `item_picked_up(item: Item, quantidade: int)`, e não `item_coletado`.
- **Gerador roda pela linha de comando.** Em vez de script de editor, o gerador do
  catálogo é um script `extends SceneTree` em `game/scripts/utils/`, rodado com
  `--headless --script`. Assim dá para gerar de novo sem abrir o editor.
- **Mover as ferramentas quebra o `EquipmentManager`.** Os três `.tres` de ferramenta
  vão para `resources/items/ferramentas/`, e os `preload()` do `EquipmentManager`
  precisam apontar para o caminho novo no mesmo commit.
- **`item_de_teste.tres` sai.** Nenhum sistema usa, e o catálogo real o substitui.
- **Contrato de interação.** Qualquer coisa interagível tem um método `interagir()`. A
  `AreaInteracao` devolve o nó dono do corpo detectado, e o `player.gd` só chama
  `alvo.interagir()`, sem saber se é item, NPC ou baú. É o mesmo padrão de despacho do
  `GradeSolo.aplicar()`. No `ItemNoMundo`, `interagir()` chama `coletar()`.
- **Moeda nunca vai para o chão.** O plano 17 decidiu que crédito é um número no
  `EconomyManager`. O item `credito` existe só como ícone de interface, com
  `pode_ser_presente = false`.
- **`coletar()` sempre dá certo por enquanto.** O `InventoryManager` atual não tem limite.
  O caso de inventário cheio passa a existir no plano 04.
- **`Semente.cultivo` fica vazio.** Os `.tres` de `Cultivo` nascem no plano 06, que
  preenche esse campo.
- **`interagir` continua no E.** A troca para F é do plano 04.

## Contexto

Hoje `game/scripts/resources/item.gd` tem cinco campos: nome, descrição, ícone,
empilhável e quantidade máxima por pilha. `Ferramenta` já herda de `Item` e acrescenta
`id_acao`. Existem três `.tres` de ferramenta e um item de teste.

Falta identidade estável (o `nome` é texto de exibição, não serve de chave), categoria,
valor para o comércio, e a representação do item quando ele está no chão.

## Decisões fechadas

**Item ganha `id` do tipo `StringName`.** É a chave usada em save, em receita de gosto de
NPC e em lista de loja. O `nome` continua sendo só o texto que aparece na tela, e pode
mudar sem quebrar nada.

**Categoria é enum, não texto.** Filtro de loja, aba de inventário e regra de presente
todos precisam agrupar item, e texto solto vira erro de digitação silencioso.

**Item no chão é uma cena só, genérica.** Um `ItemNoMundo` que recebe qual `Item` ele
representa e monta a aparência a partir do ícone. Não é uma cena por item. Segue a ideia
do Minecraft: o objeto no chão gira devagar, flutua de leve, e o jogador aperta o botão
de interagir perto dele para pegar.

**O ícone vira a aparência 3D.** Os ícones são pixel art 2D. No chão, o item aparece como
um quadrado com a textura do ícone, em pé, virado para a câmera. Isso reaproveita a arte
que já existe e combina com os crops, que também são 2D em pé (plano 06).

## Modelo de dados

`game/scripts/resources/item.gd` passa a ser:

```gdscript
class_name Item
extends Resource

enum Categoria { RECURSO, SEMENTE, COLHEITA, FERRAMENTA, ARMA, ARMADURA, CONSUMIVEL, MATERIAL, ESPECIAL }

@export var id: StringName = &""
@export var nome: String = ""
@export var descricao: String = ""
@export var icone: Texture2D
@export var categoria: Categoria = Categoria.RECURSO
@export var empilhavel: bool = true
@export var quantidade_maxima_por_pilha: int = 99
@export var valor_de_venda: int = 1
@export var pode_ser_presente: bool = true
```

Classes filhas novas, cada uma no seu arquivo em `game/scripts/resources/`:

```gdscript
class_name Semente
extends Item

@export var cultivo: Cultivo
```

A semente não guarda em que estação ela serve. Quem guarda isso é o `Cultivo` que ela
aponta (plano 06, campo `estacoes_permitidas`). Duplicar o dado nos dois lugares só cria
a chance de eles discordarem.

```gdscript
class_name Consumivel
extends Item

@export var recupera_vida: int = 0
@export var recupera_stamina: int = 0
```

`Arma` e `Armadura` nascem nos planos 08 e 04. Aqui só a base.

`Ferramenta` continua herdando de `Item` sem mudança, além de passar a preencher `id` e
`categoria`.

## Catálogo inicial

A ideia temática é a fricção entre a fazenda e a cidade: metade do catálogo é rural,
metade é sucata tecnológica, e o que dá dinheiro de verdade é combinar as duas.

Crie um `.tres` por item em `game/resources/items/`, agrupado em subpastas por categoria.

**Colheitas (as 6 que já têm arte, em `assets/textures/tiny_farm_crops/`)**

| id | nome | venda |
|---|---|---|
| `beterraba` | Beterraba | 35 |
| `repolho` | Repolho | 50 |
| `cenoura` | Cenoura | 25 |
| `milho` | Milho | 40 |
| `tomate` | Tomate | 30 |
| `trigo` | Trigo | 20 |

**Sementes.** Uma por colheita, id `semente_<cultura>`, valor de venda igual a um terço
do valor da colheita, arredondado para baixo. O preço de compra fica no plano 17.

**Sucata da cidade.** Cai de inimigo (plano 09) e aparece no chão perto da divisa.

| id | nome | venda |
|---|---|---|
| `sucata_metal` | Sucata de metal | 8 |
| `placa_queimada` | Placa queimada | 15 |
| `celula_energia` | Célula de energia | 45 |
| `fio_optico` | Fio óptico | 22 |
| `servomotor` | Servomotor | 60 |
| `nucleo_sintetico` | Núcleo sintético | 140 |

**Recursos do campo.** Vêm de coletar no cenário.

| id | nome | venda |
|---|---|---|
| `madeira` | Madeira | 5 |
| `pedra` | Pedra | 4 |
| `fibra` | Fibra | 3 |
| `minerio_cobre` | Minério de cobre | 18 |
| `minerio_ferro` | Minério de ferro | 26 |

**Materiais processados.** O elo entre os dois mundos, e a fonte de renda que cresce.

| id | nome | venda | ideia |
|---|---|---|---|
| `composto_organico` | Composto orgânico | 30 | acelera crescimento de cultivo |
| `biocombustivel` | Biocombustível | 90 | trigo mais célula de energia |
| `nutrisolo` | Nutrisolo | 75 | melhora qualidade da colheita |
| `chapa_reciclada` | Chapa reciclada | 40 | sucata refinada, usada em construção |

**Consumíveis.**

| id | nome | vida | stamina |
|---|---|---|---|
| `pao_de_trigo` | Pão de trigo | 20 | 15 |
| `sopa_de_legumes` | Sopa de legumes | 40 | 35 |
| `estimulante` | Estimulante | 0 | 70 |
| `nanogel` | Nanogel | 60 | 0 |

**Especiais.**

| id | nome | uso |
|---|---|---|
| `buque` | Buquê | pedido de namoro (plano 16) |
| `credito` | Crédito | moeda do jogo (plano 17) |

Os valores de venda são um primeiro chute com uma lógica por trás: colheita rende mais
por dia investido que recurso coletado, e material processado rende mais que a soma dos
ingredientes. O balanceamento de verdade é o plano 17.

## Item no mundo

Cena nova `game/scenes/items/item_no_mundo.tscn`, com script
`game/scripts/items/item_no_mundo.gd`.

Estrutura:

```
ItemNoMundo (Node3D, script)
  Visual (Sprite3D)
  Corpo (StaticBody3D, camada item_no_chao, mascara vazia)
    FormaColisao (CollisionShape3D, BoxShape3D pequena)
```

O `Sprite3D` usa `billboard = BILLBOARD_ENABLED` para sempre encarar a câmera,
`texture_filter` em nearest para não borrar a pixel art, e `alpha_cut` em
`ALPHA_CUT_DISCARD` para a transparência não brigar com a ordem de desenho.

API do script:

```gdscript
class_name ItemNoMundo
extends Node3D

@export var item: Item
@export var quantidade: int = 1

@export var velocidade_de_giro: float = 1.5
@export var altura_da_flutuacao: float = 0.08
@export var velocidade_da_flutuacao: float = 2.0

## Cria uma instância já configurada e adiciona na cena, com um empurrão para
## o item não nascer exatamente em cima de outro.
static func soltar(item: Item, quantidade: int, posicao: Vector3, pai: Node) -> ItemNoMundo

## Chamado quando o jogador interage. Tenta colocar no inventário e se some.
## Retorna false quando o inventário estava cheio, e aí o item continua no chão.
func coletar() -> bool
```

O giro e a flutuação são cosméticos e ficam no `_process`, não no `_physics_process`.

Sinal novo em `game/scripts/core/event_bus.gd`:

```gdscript
signal item_coletado(item: Item, quantidade: int)
```

## Coleta pelo jogador

Um `Area3D` chamado `AreaInteracao` no `player.tscn`, com máscara nas camadas
`item_no_chao`, `npc` e `area_interacao`, raio de cerca de 1.5. Ela mantém a lista do que
está por perto e o jogador pega o mais próximo ao apertar `interagir`.

Isso nasce aqui e é reaproveitado pelos planos 06 (colher), 15 (conversar) e 17 (abrir
loja e baú). Vale fazer bem feito agora: um script `area_de_interacao.gd` que expõe

```gdscript
func alvo_mais_proximo() -> Node3D
```

e deixa cada sistema decidir o que fazer com o alvo.

## Tarefas

- [x] **1.** Ampliar `item.gd` com os campos novos. Atualizar os três `.tres` de
  ferramenta existentes para preencher `id` e `categoria`. Rodar o jogo e confirmar que
  as ferramentas continuam funcionando.
- [x] **2.** Criar `semente.gd` e `consumivel.gd`.
- [x] **2b.** Gerar os ícones placeholder e mostrar ao Antonio a tabela do catálogo
  para revisão. Não seguir para a 3 sem a tabela aprovada.
- [x] **3.** Criar os `.tres` do catálogo. É trabalho repetitivo, e vale fazer um script
  de editor `@tool` que gera os `.tres` a partir de uma tabela, em vez de 40 arquivos na
  mão. O script fica em `game/scripts/utils/`, roda uma vez e continua versionado como
  documentação de onde os números vieram.
- [x] **4.** Criar `item_no_mundo.tscn` e o script. Testar colocando uma instância à mão
  no playground e vendo ela girar.
- [x] **5.** Criar `area_de_interacao.gd` e o `AreaInteracao` no player.
- [x] **6.** Ligar `interagir` à coleta. Como o inventário de verdade é o plano 04, por
  enquanto chame `InventoryManager.adicionar_item()` que já existe.
- [x] **7.** Documentar em `arquitetura.md` e `glossario.md`. Commit.

## Critério de pronto

- Uma instância de `ItemNoMundo` no playground gira, flutua, e some ao ser coletada.
- O item coletado aparece na contagem do `InventoryManager`.
- O catálogo tem os `.tres` criados e eles abrem no Inspector sem erro.

## Fora de escopo

- **Ímã de coleta automática.** No Minecraft o item voa para o jogador. Aqui a coleta é
  por botão, conforme o Antonio pediu. Coleta automática pode virar melhoria depois.
- **Empilhar item no chão.** Dois itens iguais no chão são dois objetos. Juntar em um só
  é otimização que ainda não faz falta.
- **Qualidade de item** (estrela de Stardew). Não foi pedido e multiplicaria o catálogo.
- **Receita de fabricação.** Os materiais processados existem como item, mas não há como
  fabricá-los ainda. Está listado em `sugestoes-de-features.md`.
