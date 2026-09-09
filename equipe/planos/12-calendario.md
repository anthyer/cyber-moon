# Plano 12: Calendário

**Objetivo:** uma tela de calendário mostrando o mês da estação atual, o dia de hoje, e
os aniversários dos NPCs.

**Depende de:** 11.

**Entrega para:** 16 (presente de aniversário vale mais).

## Decisões fechadas

**Começa como tela de menu, vira item na casa depois.** O Antonio pediu nessa ordem. O
plano constrói a tela e a abre por atalho de teclado; a versão de quadro na parede é uma
`Area3D` de interação que chama a mesma tela, e está no fim das tarefas como passo
opcional.

**Um mês por estação.** Trinta dias numa grade de 6 colunas por 5 linhas. Seis colunas
em vez de sete porque não existe semana de sete dias aqui; a semana do jogo é de 6 dias,
o que faz a grade fechar certinho e dá um ritmo próprio ao mundo.

Os dias da semana, para os NPCs terem rotina semanal (plano 14):

| Coluna | Nome |
|---|---|
| 1 | Primeiro |
| 2 | Segundo |
| 3 | Terceiro |
| 4 | Quarto |
| 5 | Quinto |
| 6 | Folga |

"Folga" é o dia em que as lojas fecham e os NPCs ficam em casa. Isso dá ao jogador um
ritmo de planejamento sem precisar de calendário complicado.

**O aniversário mora no `PerfilNpc`.** Dois campos, estação e dia.

## Modelo

`game/scripts/resources/perfil_npc.gd` ganha:

```gdscript
@export var estacao_do_aniversario: StringName = &"brotacao"
@export var dia_do_aniversario: int = 1
```

`SeasonManager` ganha um método de conveniência:

```gdscript
func dia_da_semana() -> int    # 0 a 5, onde 5 e a Folga
func nome_do_dia_da_semana() -> String
```

Calculado com `(dia_da_estacao() - 1) % 6`.

Um autoload não é necessário aqui. Um script de tela que consulta o `SeasonManager` e
varre os `.tres` de NPC basta.

## Interface

Cena `game/scenes/ui/calendario.tscn`, script `game/scripts/ui/calendario.gd`.

```
+--------------------------------------------------+
|  <   Brotacao, ano 1                          >  |
+--------------------------------------------------+
| Primeiro Segundo Terceiro Quarto Quinto  Folga   |
|   1        2        3       4      5       6     |
|   7        8        9      10     11      12     |
|  13       14       15      16     17      18     |
|  19       20      [21]     22     23      24     |
|  25       26       27      28     29      30     |
+--------------------------------------------------+
|  Aniversarios desta estacao                      |
|  dia 9   Kenji                                   |
+--------------------------------------------------+
```

Brotação tem só um aniversário (Kenji, dia 9). Estiagem tem dois (Vitor dia 12, Sol dia
27), colheita tem dois (Rafa dia 3, Marta dia 20) e apagão tem um (Iara dia 15). O elenco
e as datas estão no plano 14.

O dia de hoje fica destacado. Dia com aniversário ganha um ponto colorido. As setas
navegam entre as quatro estações, sem mudar nada no jogo, só na visualização.

Carregar os NPCs: varra `game/resources/npcs/` com `DirAccess` e carregue os `.tres`.
Isso evita uma lista fixa no código que alguém esqueceria de atualizar ao criar NPC novo.

## Entrada

Ação nova `abrir_calendario`, conforme `equipe/controles.md`: tecla C, botão Back no
controle. Método novo no `InputManager`.

O calendário pausa o jogo, igual ao menu de pausa.

## Tarefas

- [ ] **1.** Adicionar os dois campos de aniversário ao `PerfilNpc` e os métodos de dia
  da semana ao `SeasonManager`.
- [ ] **2.** Adicionar a ação `abrir_calendario` e documentar em `game/docs/entrada.md`.
- [ ] **3.** Criar `calendario.tscn` com a grade de 6 por 5 e o destaque do dia de hoje.
- [ ] **4.** Carregar os `.tres` de NPC e listar os aniversários da estação.
- [ ] **5.** Ligar a navegação entre estações.
- [ ] **6.** Mostrar o nome do dia da semana no relógio da HUD.
- [ ] **7.** Opcional: uma `Area3D` chamada `QuadroCalendario` dentro da casa, no
  playground, que abre a mesma tela ao interagir.
- [ ] **8.** Documentar e commitar.

## Critério de pronto

- C abre o calendário, o jogo pausa, e o dia de hoje está destacado.
- Avançar dias move o destaque, e virar a estação troca o mês mostrado.
- Os aniversários dos NPCs aparecem marcados na grade e listados embaixo.
- As setas navegam entre as quatro estações sem afetar o jogo.

## Fora de escopo

- **Anotar tarefa no calendário.** Agenda do jogador é outra feature.
- **Marcar evento e festival.** Não existem eventos ainda.
- **Previsão do tempo do dia seguinte.** Combina muito com o plano 13, e está anotado em
  `sugestoes-de-features.md` como aparelho de TV na casa.
