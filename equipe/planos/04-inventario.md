# Plano 04: Inventário

**Objetivo:** inventário em matriz estilo Rune Factory, acessado por um menu de pausa,
onde dá para organizar os itens arrastando, e equipar arma, armadura e equipamento de
solo.

**Depende de:** plano 03.

**Entrega para:** 05 (a barra rápida é uma fatia deste inventário), 06, 08, 17.

## Contexto

O `InventoryManager` de hoje é um dicionário de item para quantidade. Não tem posição,
não tem limite, não tem slot. Serve para contar, não para organizar. Este plano
substitui o miolo dele, mantendo os nomes de método que já existem para não quebrar quem
chama.

## Decisões fechadas

**Matriz de 8 colunas por 4 linhas, mais 9 slots rápidos.** Os 9 rápidos são slots à
parte, que **contam na capacidade total**, exatamente como o Antonio pediu. Total de 41
slots. O número de colunas casa com a leitura em tela larga e as 4 linhas dão folga sem
virar inventário infinito.

**Slot é uma pilha, não um item.** Um slot guarda um `Item` e uma quantidade. Slot vazio
é `null`, não um objeto vazio, porque comparar com `null` é mais direto de ler.

**Equipar é um ponteiro para um slot, não uma cópia.** O item equipado continua ocupando
o slot dele. Isso é o que faz a regra do Antonio funcionar: o slot selecionado da barra
rápida é o equipamento em uso, igual ao Minecraft.

**Três espaços de equipamento fixos**, além da mão: armadura, equipamento de solo, e
acessório. A mão é o slot rápido selecionado.

**O menu de pausa pausa o jogo de verdade** (`get_tree().paused = true`), com o nó da UI
em `PROCESS_MODE_WHEN_PAUSED`.

## Modelo de dados

`game/scripts/resources/pilha_de_itens.gd`:

```gdscript
class_name PilhaDeItens
extends Resource

@export var item: Item
@export var quantidade: int = 0

func esta_vazia() -> bool
func espaco_livre() -> int
## Junta o que couber e devolve o que sobrou.
func juntar(outra: PilhaDeItens) -> int
```

`game/scripts/core/inventory_manager.gd` reescrito:

```gdscript
extends Node

const COLUNAS: int = 8
const LINHAS: int = 4
const TOTAL_DE_SLOTS: int = COLUNAS * LINHAS      # 32
const SLOTS_RAPIDOS: int = 9

signal inventario_alterado
signal equipamento_alterado(espaco: Espaco, item: Item)

enum Espaco { MAO, ARMADURA, SOLO, ACESSORIO }

## Índices de 0 a 8 são os slots rápidos. De 9 a 40 é a matriz principal.
var slots: Array[PilhaDeItens] = []

func adicionar_item(item: Item, quantidade: int) -> int   # devolve o que nao coube
func remover_item(item: Item, quantidade: int) -> bool
func obter_quantidade(item: Item) -> int
func mover(indice_origem: int, indice_destino: int) -> void
func slot_em(indice: int) -> PilhaDeItens
func equipar(espaco: Espaco, indice_do_slot: int) -> bool
func item_equipado(espaco: Espaco) -> Item
func esta_cheio() -> bool
```

Atenção à mudança de contrato: `adicionar_item` hoje retorna `void` e passa a retornar a
sobra. Quem chama precisa tratar o caso de inventário cheio, que é o que impede o item
de sumir. Os chamadores atuais estão no plano 03.

A ordem de preenchimento de `adicionar_item` importa para a sensação de jogo: primeiro
completa pilha existente do mesmo item, depois usa o primeiro slot vazio, varrendo os
slots rápidos antes da matriz. É o que faz item novo aparecer na mão, como no Minecraft.

## Interface

Cena `game/scenes/ui/menu_pausa.tscn`, script em `game/scripts/ui/menu_pausa.gd`.

Estrutura visual, da esquerda para a direita:

```
+-------------------+---------------------------+
| Personagem        |  Matriz 8 x 4             |
| Armadura   [   ]  |  [ ][ ][ ][ ][ ][ ][ ][ ] |
| Solo       [   ]  |  [ ][ ][ ][ ][ ][ ][ ][ ] |
| Acessorio  [   ]  |  [ ][ ][ ][ ][ ][ ][ ][ ] |
|                   |  [ ][ ][ ][ ][ ][ ][ ][ ] |
| Vida    ####      |                           |
| Stamina ####      |  Barra rapida             |
|                   |  [1][2][3][4][5][6][7][8][9]|
+-------------------+---------------------------+
| Nome do item selecionado                      |
| Descricao                                     |
+-----------------------------------------------+
```

Vida e stamina só aparecem depois do plano 07. Deixe o espaço reservado.

Cena `game/scenes/ui/slot_inventario.tscn` para um slot, reusada nos 41 lugares: um
`Panel` com `TextureRect` do ícone e `Label` da quantidade. Ela cuida do arrastar e
soltar com `_get_drag_data`, `_can_drop_data` e `_drop_data`, que é o mecanismo nativo
do Godot para isso e evita reinventar arraste na mão.

Navegação por controle usa o sistema de foco dos nós `Control`, conforme a regra que já
está em `game/docs/entrada.md`.

## Entrada

Este é o plano que faz as três mudanças de bind descritas em `equipe/controles.md`,
seção "As três mudanças em bind que já existe". Fazer todas aqui evita mexer no Input Map
três vezes.

- `abrir_inventario` passa de I para E, e no controle continua no Y.
- `interagir` passa de E para F, e no controle continua no A.
- `menu_pausa` é ação nova: Esc no teclado, Start no controle.

Métodos novos no `InputManager`, seguindo o padrão dos existentes:

```gdscript
func menu_pausa_pressionado() -> bool
```

## Tarefas

- [ ] **1.** Criar `pilha_de_itens.gd`. Testar por script headless: criar duas pilhas,
  juntar, conferir a sobra.
- [ ] **2.** Reescrever o `InventoryManager`. Manter as assinaturas antigas funcionando.
  Verificar por script headless: adicionar 200 de um item que empilha até 99 e conferir
  que ocupou 3 slots.
- [ ] **3.** Fazer as três mudanças de bind e a ação `menu_pausa`. Atualizar
  `game/docs/entrada.md`. Rodar e conferir que E abre alguma coisa e F interage.
- [ ] **4.** Criar `slot_inventario.tscn` com arrastar e soltar.
- [ ] **5.** Criar `menu_pausa.tscn` montando a matriz e a barra rápida com o slot
  reusado. Ligar ao sinal `inventario_alterado`.
- [ ] **6.** Ligar pausa de verdade do jogo e o fechar com Esc.
- [ ] **7.** Implementar equipar, arrastando item para os espaços de equipamento.
- [ ] **8.** Documentar e commitar.

## Critério de pronto

- E abre o menu, o jogo congela, Esc fecha e o jogo volta.
- Item coletado aparece no primeiro slot rápido livre.
- Arrastar item de um slot para outro funciona, inclusive trocando dois itens de lugar.
- Coletar item com o inventário cheio deixa o item no chão em vez de sumir com ele.
- Dá para navegar entre os slots com o controle, sem mouse.

## Fora de escopo

- **Ordenar automaticamente.** Botão de organizar é conveniência, não requisito.
- **Dividir pilha ao meio.** Padrão em Minecraft, mas é polimento.
- **Peso ou limite por tipo.** O limite é o número de slots, e só.
- **Baú.** É o plano 17, porque o baú é comprado com NPC. O `InventoryManager` deste
  plano precisa ser genérico o suficiente para o baú reusar a mesma lógica de slots, mas
  não construa o baú agora.
- **Efeito de armadura e acessório.** Aqui eles só equipam. O que eles fazem depende do
  plano 07 (status) e 09 (dano).
