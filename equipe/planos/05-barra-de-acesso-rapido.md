# Plano 05: Barra de acesso rápido

**Objetivo:** a barra de 9 slots aparece na tela durante o jogo, o slot selecionado é o
item na mão, e dá para trocar de slot por tecla numérica, roda do mouse e botão do
controle, sem abrir menu nenhum.

**Depende de:** plano 04. Os slots rápidos já existem lá, aqui eles ganham tela e
controle.

**Entrega para:** 06, 08, 16.

## Contexto

Hoje existe `game/scenes/ui/hud_ferramenta.tscn` com `hud_ferramenta.gd`, que mostra a
ferramenta equipada lendo o `EquipmentManager`. Este plano substitui essa HUD pela barra,
e o `EquipmentManager` deixa de ter array próprio de ferramenta: a ferramenta passa a ser
o que está no slot selecionado do inventário.

Essa é a mudança conceitual do plano, e é a que o Antonio pediu explicitamente: o slot
rápido selecionado continua sendo o equipamento equipado.

## Decisões fechadas

**O `EquipmentManager` vira uma casca fina.** Ele guarda só o índice do slot selecionado
e responde qual item está nele. Toda a posse de item passa para o `InventoryManager`.

```gdscript
extends Node

signal slot_selecionado_alterado(indice: int)

var indice_selecionado: int = 0

func selecionar(indice: int) -> void
func ciclar(direcao: int) -> void
func item_na_mao() -> Item
func ferramenta_na_mao() -> Ferramenta   # null quando o item na mao nao e ferramenta
```

O `player.gd` hoje chama `EquipmentManager.ferramenta_atual()`. Renomeie para
`ferramenta_na_mao()` e a lógica de uso de ferramenta continua igual, porque ela já é
genérica pelo `id_acao`.

**A ciclagem dá a volta e passa por slot vazio.** Slot vazio é o punho, que é como o
jogador ataca hoje. Não pule slot vazio na ciclagem: no Minecraft o slot vazio é uma
posição válida, e aqui ele tem função (socar).

**A barra some durante o menu de pausa** e durante o diálogo (plano 15), porque nesses
momentos ela não faz nada e atrapalha a leitura.

## Interface

Cena `game/scenes/ui/barra_rapida.tscn`, script `game/scripts/ui/barra_rapida.gd`.

Um `HBoxContainer` ancorado no rodapé, centralizado, com 9 instâncias de
`slot_inventario.tscn` (a mesma cena do plano 04, reusada). O slot selecionado ganha uma
borda destacada. Acima do slot selecionado aparece o nome do item por dois segundos
quando a seleção muda, que é exatamente o comportamento do Minecraft e ajuda muito quando
os ícones são pequenos.

Ela escuta dois sinais e não conhece mais nada:

- `InventoryManager.inventario_alterado` para redesenhar os ícones e as quantidades.
- `EquipmentManager.slot_selecionado_alterado` para mover o destaque.

## Entrada

Conforme `equipe/controles.md`. As ações `equipar_1` a `equipar_4` são renomeadas e
ampliadas para `slot_1` a `slot_9`, e `ferramenta_proxima` e `ferramenta_anterior` viram
`slot_proximo` e `slot_anterior`.

| Ação | Teclado | Controle |
|---|---|---|
| `slot_1` a `slot_9` | teclas 1 a 9 | nenhum |
| `slot_proximo` | roda do mouse para baixo | R1 (`button_index` 10) |
| `slot_anterior` | roda do mouse para cima | L1 (`button_index` 9) |

Lembre que L1 é 9 e R1 é 10 no Godot 4, e que é fácil trocar. Confira contra um bind que
já existe no `project.godot`.

No `InputManager`, os nove métodos `slot_N_pressionado()` viram um só, que é mais limpo
que nove métodos quase iguais:

```gdscript
## Devolve o índice do slot pedido por tecla numérica, ou -1 quando nenhuma foi
## pressionada neste quadro.
func slot_numerico_pressionado() -> int:
	for indice in 9:
		if Input.is_action_just_pressed("slot_%d" % (indice + 1)):
			return indice
	return -1

func slot_proximo_pressionado() -> bool
func slot_anterior_pressionado() -> bool
```

O `player.gd` perde o bloco de seis `elif` de equipar e fica com três linhas.

## Tarefas

- [ ] **1.** Renomear as ações no `project.godot`, ampliando para 9, e ajustar o
  `InputManager`. Atualizar `game/docs/entrada.md`.
- [ ] **2.** Reescrever o `EquipmentManager` como casca fina sobre o `InventoryManager`.
  Ajustar a chamada em `player.gd`.
- [ ] **3.** Criar `barra_rapida.tscn` reusando `slot_inventario.tscn`.
- [ ] **4.** Trocar `hud_ferramenta.tscn` pela barra no `playground.tscn`. Apagar a HUD
  antiga e o script dela.
- [ ] **5.** Adicionar o texto do nome do item que aparece e some ao trocar de slot.
- [ ] **6.** Esconder a barra quando o jogo estiver pausado.
- [ ] **7.** Documentar e commitar.

## Critério de pronto

- As teclas 1 a 9 mudam o slot e o destaque acompanha.
- A roda do mouse cicla, dá a volta nas duas pontas, e passa pelo slot vazio.
- L1 e R1 ciclam no controle, no sentido certo (R1 avança).
- Com uma enxada no slot 2, selecionar o slot 2 e apertar atacar ara o solo, igual hoje.
- Com o slot vazio selecionado, atacar faz o combo de soco, igual hoje.
- Item coletado no chão aparece na barra sem precisar abrir o menu.

## Fora de escopo

- **Arrastar item entre a barra e o mundo.** Soltar item é o plano 16, junto com
  presentear.
- **Barra configurável** (mudar quantos slots). Nove é o número, igual ao Minecraft.
- **Atalho de consumir item.** O item na mão ser usado com um botão dedicado depende do
  plano 07 existir para ter o que recuperar.
