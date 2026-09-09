---
name: padrao-cyber-moon
description: Use ao escrever, editar ou revisar qualquer código do Cyber Moon, incluindo scripts GDScript (.gd), cenas (.tscn), recursos (.tres), o project.godot e a documentação em game/docs/. Carrega as convenções de nomenclatura, idioma, arquitetura de autoloads, uso do EventBus, dados como Resource e estilo de escrita do projeto. Use também antes de criar um sistema novo, um autoload novo ou uma classe Resource nova.
---

# Padrão de código do Cyber Moon

## Nomenclatura

| O quê | Padrão | Exemplo |
|---|---|---|
| Arquivo e pasta | `snake_case` | `crop_manager.gd`, `hud_ferramenta.tscn` |
| `class_name` | `PascalCase` | `GradeSolo`, `PerfilNpc` |
| Nó dentro de cena | `PascalCase` descritivo | `Player`, `IndicadorAlvo` |
| Constante | `SCREAMING_SNAKE_CASE` | `HORA_INICIO_DIA` |
| Sinal | verbo no passado, `snake_case` | `crop_harvested`, `tile_plowed` |
| Arquivo `.tres` | conteúdo em `snake_case` | `picareta.tres`, `tomate.tres` |

## Idioma

Identificadores em inglês. Comentários e documentação em português, com acentuação
normal. Quando um termo de design em português precisar de um nome técnico em inglês,
consulte e atualize `game/docs/glossario.md`.

Atenção: o código existente mistura os dois de propósito. Nomes de classe e de sinal
seguem o inglês (`Item`, `crop_harvested`), mas métodos e variáveis de domínio seguem o
português (`adicionar_item`, `numero_do_dia`, `celula_alvo`). Siga o que o arquivo
vizinho já faz em vez de uniformizar por conta própria.

## Escrita

Nada de travessão (o caractere de traço longo) e nada de emoji, em nenhum arquivo do
repositório: documentação, comentário, docstring, mensagem de commit. Use vírgula,
ponto e parênteses. Acentuação em português fica normal.

Comentário explica o porquê, nunca o quê. Se o comentário descreve o que a linha
seguinte faz, apague o comentário e melhore o nome.

## Arquitetura

**Um autoload por responsabilidade.** Os que existem estão descritos em
`game/docs/arquitetura.md`. Quando um autoload começa a acumular lógica de um domínio
que não é o dele, isso é sinal de que falta um autoload novo, não de que esse deve
crescer.

**EventBus para desacoplar.** Sistemas que não precisam se conhecer conversam por sinal
declarado em `game/scripts/core/event_bus.gd`. Sistemas que têm relação direta e
hierárquica (um nó e seu filho) chamam método direto, sem passar pelo EventBus.
Emita o sinal apenas quando a ação teve efeito de verdade, seguindo o padrão de
`GradeSolo.arar()`, que retorna `false` e não emite nada quando a ação não se aplica.

**Dado de jogo é Resource.** Cultivo, item, NPC e diálogo são classes `Resource`
definidas em `game/scripts/resources/` e instanciadas como `.tres` em `game/resources/`.
Uma cultura nova ou item novo tem que ser um arquivo `.tres`, sem exigir código novo.
Se adicionar conteúdo exige editar um `match` ou um array em código, o modelo de dados
está errado.

**Entrada só pelo InputManager.** Nunca `Input.is_action_just_pressed()` em código de
gameplay. Adicione a ação no `project.godot`, exponha um método em
`game/scripts/core/input_manager.gd`, documente em `game/docs/entrada.md`.

**Tabela de despacho em vez de condicional espalhada.** `GradeSolo.aplicar()` é o
modelo: o `player.gd` não conhece o nome de nenhuma ferramenta, só passa o `id_acao` e
lê o booleano de retorno. Ao adicionar comportamento por tipo, procure o ponto de
despacho existente antes de criar um `if` novo no chamador.

## Tipagem

GDScript com tipo estático em tudo que for declaração: parâmetro, retorno, variável de
membro, variável local não trivial. O código existente faz isso sem exceção
(`func adicionar_item(item: Item, quantidade: int) -> void:`). Use `StringName`
(`&"enxada"`) para identificador comparado com frequência, não `String`.

## Antes de dar a tarefa por pronta

- Rodou o jogo e viu o comportamento novo acontecer? Veja a skill `rodar-o-jogo`.
- A documentação em `game/docs/` que descrevia o sistema alterado continua verdadeira?
- Entrou ação de entrada nova? Então `game/docs/entrada.md` precisa da linha nova.
- Entrou sinal novo no EventBus? Então `game/docs/arquitetura.md` precisa da linha nova.
