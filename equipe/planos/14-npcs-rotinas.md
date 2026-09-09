# Plano 14: NPCs, walk cycle e rotinas

**Objetivo:** seis NPCs habitando o mapa, cada um com uma rotina que depende da hora do
dia, do dia da semana e da estação. Eles andam, param nos lugares certos e interagem
entre si.

**Depende de:** 01 (colisão), 10 (hora), 11 (estação), 12 (dia da semana).

**Entrega para:** 15, 16, 17.

## O elenco

Três homens e três mulheres, como o Antonio pediu. Modelos placeholder do
`kenney_mini_characters`. Os aniversários já ficam definidos aqui porque o plano 12 os
mostra no calendário.

| id | nome | idade | papel | modelo | aniversário | romanceável |
|---|---|---|---|---|---|---|
| `vitor` | Vitor Alencar | 45 | mecânico da oficina, conserta e compra sucata | `character_male_b.glb` | estiagem, 12 | não |
| `kenji` | Kenji Moura | 24 | técnico que mexe com rede pirata | `character_male_c.glb` | brotação, 9 | sim |
| `rafa` | Rafael Duarte | 27 | entregador, corre a fronteira o dia todo | `character_male_d.glb` | colheita, 3 | sim |
| `marta` | Marta Bueno | 58 | dona do mercado, vende semente e ferramenta | `character_female_a.glb` | colheita, 20 | não |
| `iara` | Iara Nakamura | 29 | médica da clínica | `character_female_b.glb` | apagao, 15 | sim |
| `sol` | Sol Vasques | 26 | ex-funcionária da corporação, desertou | `character_female_c.glb` | estiagem, 27 | sim |

Vitor e Marta não são romanceáveis de propósito: eles são os dois comerciantes do plano
17, e é bom ter personagem cuja relação com o jogador é puramente de negócio e amizade.

Sol é o elo com a linha principal da história, já que ela veio da cidade que está
avançando sobre os campos.

## Decisões fechadas

**A rotina é dado, não código.** Um `Resource` com uma lista de compromissos. Um NPC
novo, ou um horário novo, não exige tocar em script.

**O NPC anda até o ponto, não teleporta.** Andar de verdade é o que faz o mundo parecer
vivo. Usa `NavigationAgent3D`, porque o mapa tem prédio e cerca no caminho e andar em
linha reta encalharia.

Isto é uma diferença consciente em relação ao plano 09, onde o inimigo anda em linha
reta: o inimigo persegue por poucos segundos numa área aberta, o NPC atravessa o mapa
todo dia. Aqui a navegação paga o custo dela.

**O compromisso mais específico vence.** Ao escolher o que fazer, o NPC pega o
compromisso que casa com a hora atual e tem mais condições preenchidas. Assim uma regra
geral ("de manhã, na praça") convive com uma exceção ("no aniversário, em casa").

**Na Folga e na chuva forte, todo mundo fica em casa.** Uma regra global, fácil de
entender e de perceber jogando.

## Modelo

`game/scripts/resources/compromisso.gd`:

```gdscript
class_name Compromisso
extends Resource

@export var hora_inicial: float = 8.0
@export var hora_final: float = 12.0
## Vazio significa "vale para todas".
@export var estacoes: Array[StringName] = []
@export var dias_da_semana: Array[int] = []
@export var climas: Array[StringName] = []
@export var apenas_no_aniversario: bool = false

## Nome do Marker3D no mapa para onde o NPC vai.
@export var destino: StringName = &""
## Animação tocada ao chegar. Use idle, sit, crouch ou interact-left.
@export var animacao_parado: StringName = &"idle"
```

`game/scripts/resources/perfil_npc.gd` ganha:

```gdscript
@export var modelo: PackedScene
@export var rotina: Array[Compromisso] = []
@export var velocidade: float = 2.2
@export var eh_romanceavel: bool = false
```

Já tem `id`, `nome_exibido`, `retrato`, `relacionamento_inicial`, `relacionamento_maximo`,
e o plano 12 acrescentou os dois campos de aniversário.

`game/scripts/npcs/npc.gd`, com `class_name Npc`, estendendo `CharacterBody3D`. Cena
genérica `game/scenes/npcs/npc.tscn`, configurada por `@export var perfil: PerfilNpc`.

```gdscript
class_name Npc
extends CharacterBody3D

@export var perfil: PerfilNpc

func compromisso_atual() -> Compromisso
func ir_para(destino: Vector3) -> void
func esta_disponivel_para_conversa() -> bool
```

Camadas conforme o plano 01: camada `npc`, máscara `mundo` e `jogador`.

## Os destinos

`Marker3D` nomeados no `playground.tscn`, agrupados num `Node3D` chamado `PontosDeRotina`.
Nomes sugeridos, que as rotinas referenciam:

`casa_vitor`, `oficina`, `casa_kenji`, `torre_antena`, `casa_rafa`, `posto_entrega`,
`casa_marta`, `mercado`, `casa_iara`, `clinica`, `casa_sol`, `mirante`, `praca`,
`ponte`, `beira_rio`.

Vários já têm construção correspondente no mapa. Onde não houver, escolha um prédio
existente e use.

## Rotinas de exemplo

Vitor, para servir de modelo aos outros cinco:

| Hora | Estação | Dia | Destino | Animação |
|---|---|---|---|---|
| 6 a 8 | todas | todos | `casa_vitor` | `idle` |
| 8 a 12 | todas | 0 a 4 | `oficina` | `interact-left` |
| 12 a 13 | todas | 0 a 4 | `praca` | `sit` |
| 13 a 18 | todas | 0 a 4 | `oficina` | `interact-left` |
| 18 a 22 | todas | todos | `praca` | `idle` |
| 22 a 25 | todas | todos | `casa_vitor` | `idle` |
| 8 a 22 | todas | 5 (Folga) | `casa_vitor` | `sit` |

Monte as outras cinco no mesmo espírito, deixando os horários se cruzarem em alguns
pontos. É o cruzamento que faz o mundo parecer vivo, e é o que habilita a interação
entre NPCs abaixo.

## Interação entre NPCs

Quando dois NPCs param a menos de 3 metros um do outro e ambos estão em compromisso de
`idle`, eles se viram um para o outro e alternam `emote-yes` e `emote-no` com pausas.
Não é conversa de verdade, é encenação, e resolve muito bem em câmera de cima.

Um balão simples com reticências acima da cabeça vende a ideia. Um `Sprite3D` com
`billboard` ligado.

## Tarefas

- [ ] **1.** Criar `compromisso.gd` e ampliar `perfil_npc.gd`.
- [ ] **2.** Criar `npc.tscn` e `npc.gd` só com o modelo aparecendo e a animação `idle`.
  Colocar um no playground e ver funcionando.
- [ ] **3.** Montar os `Marker3D` de destino no mapa.
- [ ] **4.** Configurar a `NavigationRegion3D` do playground e gerar a malha de
  navegação. Sem isso o `NavigationAgent3D` não anda.
- [ ] **5.** Implementar `compromisso_atual()` com a regra do mais específico. Verificar
  por script headless com horas e dias variados.
- [ ] **6.** Implementar o andar até o destino com `NavigationAgent3D`, tocando `walk` em
  movimento e a animação do compromisso ao chegar.
- [ ] **7.** Criar os seis `.tres` de perfil com as rotinas.
- [ ] **8.** Implementar a regra da Folga e da chuva.
- [ ] **9.** Implementar a encenação entre NPCs.
- [ ] **10.** Documentar e commitar.

## Critério de pronto

- Os seis NPCs aparecem no mapa e cada um está num lugar diferente conforme a hora.
- Avançar as horas faz eles andarem até o destino novo, desviando de prédio e cerca.
- Na Folga eles ficam em casa.
- Dois NPCs próximos encenam uma conversa.
- Andar contra um NPC não atravessa ele.

## Fora de escopo

- **Conversa de verdade.** É o plano 15.
- **Rotina mudando com a amizade.** É o plano 16.
- **NPC reagindo a inimigo.** Os dois sistemas não se conhecem.
- **Porta abrindo e NPC entrando na casa.** Ele para na frente. Interior de casa é outro
  sistema de cena.
- **Retrato de personagem.** O campo `retrato` existe no `PerfilNpc` mas não há arte.
  O plano 15 usa o modelo 3D atrás da caixa de diálogo justamente por isso.
