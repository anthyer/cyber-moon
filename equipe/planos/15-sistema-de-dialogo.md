# Plano 15: Sistema de diálogo

**Objetivo:** conversar com um NPC abre uma caixa na parte de baixo da tela, com os
modelos 3D dos dois personagens ao fundo, o nome de quem fala antes da fala, e os dois em
animação de repouso.

**Depende de:** 14 (precisa haver com quem conversar).

**Entrega para:** 16, 17.

## O que o Antonio pediu, literalmente

Caixa com os diálogos na parte inferior da tela. Os modelos 3D dos personagens que estão
na conversa atrás da caixa: o jogador atrás da parte esquerda, o interlocutor atrás da
direita. O nome do personagem aparece antes da frase. Os dois ficam fazendo a animação de
idle.

Este plano é a execução literal disso.

## Decisões fechadas

**Os modelos são reais, não retrato 2D.** Uma `SubViewport` com uma câmera própria e duas
cópias dos modelos, renderizada como textura atrás da caixa. Isso reaproveita os modelos
que já existem, e ainda deixa a animação rodando, que é exatamente o pedido. Não existe
arte de retrato no projeto, então essa é também a única saída sem arte nova.

**Diálogo é dado, não código.** `NoDialogo` já existe como `Resource`, com `id`, `texto`,
`falante_id` e `proximos_nos`. Este plano usa e amplia.

**Uma conversa por dia por NPC, e ela se repete se você falar de novo no mesmo dia.**
É o que o Antonio pediu, e é o padrão do gênero. A troca acontece na virada do dia.

**O tempo congela durante o diálogo.** O `DayCycleManager` já ganhou
`tempo_congelado` no plano 10 justamente para isto. O jogo não pausa inteiro, só o
relógio, para a animação de idle continuar rodando.

## Modelo

`game/scripts/resources/no_dialogo.gd` ampliado:

```gdscript
class_name NoDialogo
extends Resource

@export var id: String = ""
@export var falante_id: String = ""
@export_multiline var texto: String = ""
@export var proximos_nos: Array[String] = []
## Quando preenchido, o texto so aparece se o relacionamento estiver neste
## intervalo. Deixa o NPC falar diferente conforme a amizade (plano 16).
@export var relacionamento_minimo: int = 0
@export var relacionamento_maximo: int = 999
## Vazio significa "qualquer estacao".
@export var estacoes: Array[StringName] = []
@export var animacao: StringName = &"idle"
```

`game/scripts/resources/conversa.gd`, o agrupador que faltava:

```gdscript
class_name Conversa
extends Resource

@export var id: StringName = &""
@export var npc_id: String = ""
@export var nos: Array[NoDialogo] = []
```

`game/scripts/core/dialogue_manager.gd`, autoload novo:

```gdscript
extends Node

signal dialogo_iniciado(npc_id: String)
signal dialogo_terminado(npc_id: String)
signal fala_mostrada(falante: String, texto: String)

var em_dialogo: bool = false

func iniciar(npc: Npc) -> void
func avancar() -> void
func encerrar() -> void
## Escolhe a fala do dia para este NPC, filtrando por relacionamento e estação.
func fala_do_dia(npc_id: String) -> NoDialogo
```

A escolha da fala do dia usa `DayCycleManager.numero_do_dia` como semente, e não sorteio
puro. Assim a fala é a mesma o dia inteiro, mesmo falando várias vezes, e muda no dia
seguinte, que é exatamente o comportamento pedido:

```gdscript
var indice: int = (DayCycleManager.numero_do_dia + npc_id.hash()) % candidatos.size()
```

Somar o hash do id evita que todos os seis NPCs troquem de fala em sincronia.

## Interface

Cena `game/scenes/dialogue/caixa_dialogo.tscn`.

```
+------------------------------------------------------+
|                                                      |
|   [modelo do jogador]        [modelo do NPC]         |
|                                                      |
| +--------------------------------------------------+ |
| | Kenji                                            | |
| | A antena da torre caiu de novo. Se voce achar    | |
| | fio optico por ai, me avisa.                     | |
| |                                            [F]   | |
| +--------------------------------------------------+ |
+------------------------------------------------------+
```

Estrutura:

```
CaixaDialogo (CanvasLayer)
  CenarioDosPersonagens (SubViewportContainer)
    SubViewport
      CameraDialogo (Camera3D)
      SuporteEsquerda (Node3D)   modelo do jogador, virado um pouco para a direita
      SuporteDireita (Node3D)    modelo do NPC, virado um pouco para a esquerda
      LuzDialogo (DirectionalLight3D)
  Painel (PanelContainer)
    NomeDoFalante (Label)
    TextoDaFala (RichTextLabel)
    IndicadorDeAvancar (Label)
```

O `SubViewport` precisa de `transparent_bg` ligado para os modelos aparecerem sobre o
jogo. Os dois modelos são instanciados em runtime a partir de `PerfilNpc.modelo` e do
modelo do jogador, e ambos tocam `idle` em loop.

O nome do falante fica destacado por cor, e a caixa muda de lado o destaque conforme quem
fala. Escrever o texto letra por letra, uns 40 caracteres por segundo, com opção de pular
para o texto completo apertando o botão de novo, é o padrão do gênero e vale o esforço
pequeno que dá.

## Entrada

Sem ação nova. `interagir` (F, ou A no controle) inicia e avança. A `AreaInteracao` do
plano 03 já detecta NPC, porque a máscara dela inclui a camada `npc`.

Durante o diálogo, o `player.gd` não deve processar movimento nem ataque. Um `if
DialogueManager.em_dialogo: return` no começo do `_physics_process` resolve.

A barra rápida some durante o diálogo, conforme decidido no plano 05.

## Tarefas

- [ ] **1.** Ampliar `no_dialogo.gd` e criar `conversa.gd`.
- [ ] **2.** Criar o `DialogueManager` e registrar o autoload.
- [ ] **3.** Criar `caixa_dialogo.tscn` com o painel de texto, sem os modelos ainda.
  Testar com texto fixo.
- [ ] **4.** Montar o `SubViewport` com os dois modelos e a câmera. Este é o passo que
  vai dar mais trabalho de posicionar, e é de olho.
- [ ] **5.** Ligar `interagir` ao início do diálogo pela `AreaInteracao`.
- [ ] **6.** Implementar a escolha da fala do dia com a semente do número do dia.
- [ ] **7.** Travar o jogador e congelar o relógio durante a conversa.
- [ ] **8.** Implementar o texto aparecendo letra por letra e o pular.
- [ ] **9.** Criar uma `Conversa` de teste para um NPC e conversar com ele em dois dias
  seguidos, confirmando que a fala muda.
- [ ] **10.** Documentar e commitar.

## Critério de pronto

- Chegar perto de um NPC e apertar F abre a caixa.
- Os dois modelos aparecem atrás da caixa, o jogador à esquerda e o NPC à direita, ambos
  em idle.
- O nome do falante aparece antes da fala.
- O jogador não anda nem ataca durante a conversa, e o relógio não corre.
- Falar duas vezes no mesmo dia repete a mesma fala; no dia seguinte ela muda.
- Encerrar devolve o controle.

## Fora de escopo

- **Escolha de resposta.** O campo `proximos_nos` permite árvore, mas as conversas do
  plano 16 são lineares. Ramificação fica para diálogo de missão.
- **Retrato 2D.** Decisão consciente, explicada acima.
- **Dublagem.** Nem em beep estilo Animal Crossing, que seria divertido e está em
  `sugestoes-de-features.md`.
- **Diálogo de dois NPCs entre si.** O plano 14 já encena isso sem texto.
- **Histórico de conversa.** Não faz falta.
