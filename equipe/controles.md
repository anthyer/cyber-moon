# Controles alvo

Este documento define o mapa de controles completo do jogo, incluindo as ações que
ainda não existem. Cada plano de `equipe/planos/` que precisa de uma ação nova aponta
para a linha correspondente aqui, em vez de inventar um bind próprio.

Base de inspiração, escolhida pelo Antonio: **Minecraft** para movimento, inventário,
barra de acesso rápido e soltar item. **Rune Factory 4** para o combate e para a
ciclagem de equipamento no controle.

`game/docs/entrada.md` continua sendo a documentação oficial do Input Map, e precisa ser
atualizado a cada ação nova que entrar de fato. Este arquivo é o alvo, aquele é o estado.

## Teclado e mouse

| Ação | Tecla | Origem | Existe hoje |
|---|---|---|---|
| `mover_cima` / `baixo` / `esquerda` / `direita` | W A S D e setas | Minecraft | sim |
| `correr` | Shift esquerdo (segurar) | Minecraft (sprint) | sim |
| `dash` | Espaço | ver nota abaixo | muda |
| `atacar` | Botão esquerdo do mouse | Minecraft (usar item na mão) | sim |
| `interagir` | F | conversar, abrir baú, colher | muda |
| `abrir_inventario` | E | Minecraft | muda |
| `menu_pausa` | Esc | Minecraft | novo |
| `soltar_item` | Q | Minecraft (drop), usado também para presentear | novo |
| `slot_1` a `slot_9` | 1 a 9 | Minecraft (hotbar) | amplia |
| `slot_proximo` / `slot_anterior` | Roda do mouse | Minecraft | renomeia |
| `abrir_calendario` | C | Stardew Valley | novo |

## Controle

Nomenclatura de botão no padrão Xbox. Rune Factory 4 é de 3DS, onde o botão Y fica na
posição oeste e o X na posição norte, então a tradução é por posição, não por letra.

| Ação | Botão | `button_index` | Origem |
|---|---|---|---|
| `mover_*` | D-pad | 11 a 14 | igual hoje |
| `interagir` | A (sul) | 0 | Rune Factory 4 (A confirma) |
| `correr` | B (leste), segurar | 1 | Rune Factory 4 (B corre) |
| `atacar` | X (oeste) | 2 | Rune Factory 4 (ataque no botão oeste) |
| `abrir_inventario` | Y (norte) | 3 | igual hoje |
| `slot_anterior` | L1 | 9 | Rune Factory 4 (L e R ciclam equipamento) |
| `slot_proximo` | R1 | 10 | Rune Factory 4 |
| `soltar_item` | L2 (gatilho esquerdo) | eixo | posição livre |
| `dash` | R2 (gatilho direito) | eixo | ver nota abaixo |
| `menu_pausa` | Start | 6 | convenção |
| `abrir_calendario` | Back / Select | 4 | convenção |

**Cuidado com a enum.** No Godot 4, `9 = LeftShoulder (L1)` e `10 = RightShoulder (R1)`,
nessa ordem, que é o inverso do palpite intuitivo. Confira contra um bind que já existe
no `project.godot` antes de escrever um novo a mão.

## As três mudanças em bind que já existe

Não são ajustes cosméticos, são conflitos reais criados pelas features novas. Estão
concentradas aqui para não ficarem escondidas dentro de um plano.

**`dash` sai de Q e de R1.** Q vira `soltar_item`, porque é a tecla de largar item no
Minecraft e o sistema de presente para NPC depende dela (plano 16). R1 vira
`slot_proximo`, porque L1 e R1 ciclando equipamento é Rune Factory 4. O dash vai para
Espaço no teclado e R2 no controle. O bind de botão direito do mouse para dash pode
ficar como atalho extra, não conflita com nada.

**`abrir_inventario` sai de I e vai para E.** E é inventário no Minecraft e a memória
muscular é forte. Quem faz o plano 04 muda isso.

**`interagir` sai de E e vai para F.** Consequência direta da mudança acima. F é a
convenção de teclado quando o botão direito do mouse já está ocupado.

Fazer as três de uma vez, no plano 04 (inventário), evita mexer no Input Map três vezes.
Até lá o mapa atual continua valendo.

## As ações de equipar viram slots

Hoje existem `equipar_1` a `equipar_4`, mapeadas para as teclas 1 a 4 e ligadas
diretamente ao array fixo do `EquipmentManager`. Com a barra de acesso rápido (plano
05), elas viram `slot_1` a `slot_9`, mapeadas para as teclas 1 a 9 e ligadas ao índice
do slot, não à ferramenta. `ferramenta_proxima` e `ferramenta_anterior` viram
`slot_proximo` e `slot_anterior` pelo mesmo motivo.

A ferramenta continua sendo o que está no slot selecionado, exatamente como no
Minecraft: o slot selecionado é o item na mão, e é ele que o botão de atacar usa.
