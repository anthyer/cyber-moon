# Plano 11: Estações

**Objetivo:** quatro estações de 30 dias cada, influenciando iluminação, música,
sementes que podem ser plantadas e a rotina dos NPCs.

**Depende de:** 10 (conta dias), 06 (planta murcha ao trocar de estação), 02 (a música
troca pelo `EventBus.musica_solicitada`).

**Entrega para:** 12, 13, 14, 17.

## Decisões fechadas

**Quatro estações, 30 dias cada, 120 dias por ano**, conforme o Antonio pediu. Os nomes
seguem o tema do jogo em vez do calendário comum, mas o mapeamento é direto:

| id | nome exibido | equivale a |
|---|---|---|
| `brotacao` | Brotação | primavera |
| `estiagem` | Estiagem | verão |
| `colheita` | Colheita | outono |
| `apagao` | Apagão | inverno |

Apagão é o inverno cyberpunk: dias curtos, a cidade racionando energia, nada cresce fora
de estufa. Serve bem como a estação difícil que fecha o ano.

**A estação é derivada do dia, não guardada separada.** Um número só (`numero_do_dia`) é
a fonte da verdade, e estação, dia do mês e ano são calculados dele. Guardar os dois
convida a ficarem dessincronizados.

**Trocar de estação murcha o que não pertence à estação nova.** A textura `withered` já
existe nos seis cultivos e o campo `Cultivo.estacoes_permitidas` já foi criado no plano
06 esperando por isto.

**Cada estação tem uma faixa de música e um ajuste de iluminação**, não uma paleta
inteira nova. Multiplicadores sobre o que o plano 10 já faz.

## Modelo

`game/scripts/core/season_manager.gd`, autoload novo:

```gdscript
extends Node

signal estacao_mudou(nova: StringName)
signal ano_mudou(novo_ano: int)

const DIAS_POR_ESTACAO: int = 30
const ESTACOES: Array[StringName] = [&"brotacao", &"estiagem", &"colheita", &"apagao"]

func estacao_atual() -> StringName
func dia_da_estacao() -> int      # 1 a 30
func ano_atual() -> int           # comeca em 1
func indice_da_estacao() -> int   # 0 a 3
func nome_exibido(estacao: StringName) -> String
func perfil_da_estacao(estacao: StringName) -> PerfilEstacao
```

As contas, a partir de `DayCycleManager.numero_do_dia`, que começa em 1:

```gdscript
var dias_passados: int = DayCycleManager.numero_do_dia - 1
indice = (dias_passados / DIAS_POR_ESTACAO) % 4
dia_da_estacao = (dias_passados % DIAS_POR_ESTACAO) + 1
ano = dias_passados / (DIAS_POR_ESTACAO * 4) + 1
```

Divisão inteira em GDScript já trunca, mas escreva com `int()` explícito para quem lê não
precisar lembrar disso.

`game/scripts/resources/perfil_estacao.gd`:

```gdscript
class_name PerfilEstacao
extends Resource

@export var id: StringName = &""
@export var nome_exibido: String = ""
@export var musica: AudioStream
@export var cor_da_luz: Color = Color.WHITE
@export var multiplicador_de_energia: float = 1.0
@export var hora_do_anoitecer: float = 18.0
@export var cor_da_grama: Color = Color.WHITE
@export var chance_de_chuva: float = 0.2      # usado pelo plano 13
```

## Os quatro perfis

Um `.tres` por estação em `game/resources/estacoes/`.

| | Brotação | Estiagem | Colheita | Apagão |
|---|---|---|---|---|
| Anoitecer | 18:00 | 20:00 | 17:30 | 16:30 |
| Cor da luz | verde suave | branco quente | laranja | azul frio |
| Energia | 1.0 | 1.15 | 0.9 | 0.7 |
| Cor da grama | verde vivo | verde amarelado | ocre | cinza azulado |
| Chance de chuva | 0.35 | 0.15 | 0.25 | 0.10 |

Apagão com anoitecer às 16:30 e energia 0.7 é o que dá a sensação de inverno sem precisar
de arte nova.

## O que muda por estação

**Iluminação.** O `IluminacaoDoCiclo` do plano 10 passa a multiplicar a energia pelo
`multiplicador_de_energia` e a misturar a cor da luz com a `cor_da_luz` da estação. O
`hora_do_anoitecer` substitui a constante `HORA_ANOITECER`.

**Música.** Ao trocar de estação, emite `EventBus.musica_solicitada` com a faixa do
perfil. O gancho já foi deixado pronto no plano 02.

**Grama.** O `albedo_color` do material do chão é multiplicado pela `cor_da_grama`. É
barato e muda muito a leitura da cena.

**Sementes.** `GradeSolo.plantar()` passa a recusar cultivo cuja
`estacoes_permitidas` não contém a estação atual, e a interface avisa. Sugestão de
distribuição, para cada estação ter o que plantar:

| Cultivo | Brotação | Estiagem | Colheita | Apagão |
|---|---|---|---|---|
| Cenoura | sim | não | sim | não |
| Repolho | sim | não | sim | não |
| Beterraba | sim | não | sim | não |
| Milho | não | sim | sim | não |
| Tomate | não | sim | não | não |
| Trigo | sim | sim | sim | não |

Apagão sem nenhum cultivo é proposital: é a estação de minerar, lutar e conversar com os
NPCs, e é o gancho natural para estufa depois.

**Murchar.** No `estacao_mudou`, a `GradeSolo` varre `_plantas` e marca como murcha toda
planta cujo cultivo não serve para a estação nova, trocando para `textura_murcha`. Planta
murcha só pode ser removida com a picareta.

## Tarefas

- [ ] **1.** Criar `perfil_estacao.gd` e os quatro `.tres`.
- [ ] **2.** Criar o `SeasonManager` e registrar o autoload. Verificar por script
  headless: dia 1 é brotação dia 1; dia 30 é brotação dia 30; dia 31 é estiagem dia 1;
  dia 121 é brotação dia 1 do ano 2.
- [ ] **3.** Emitir `estacao_mudou` no `day_started` quando o índice da estação muda.
- [ ] **4.** Ligar a iluminação da estação ao `IluminacaoDoCiclo`.
- [ ] **5.** Ligar a música da estação.
- [ ] **6.** Ligar a cor da grama.
- [ ] **7.** Preencher `estacoes_permitidas` nos seis cultivos e fazer `plantar` respeitar.
- [ ] **8.** Implementar o murchar na virada de estação.
- [ ] **9.** Mostrar a estação e o dia da estação no relógio da HUD.
- [ ] **10.** Documentar e commitar.

## Critério de pronto

- Avançar 30 dias troca a estação e o mundo muda de cor visivelmente.
- Tentar plantar tomate no apagão é recusado, com aviso na tela.
- Uma planta viva na virada para uma estação em que ela não cresce fica murcha.
- A música troca ao virar a estação (ou não toca nada, se não houver arquivo, sem erro).
- Avançar 120 dias volta para brotação e o ano vira 2.

## Fora de escopo

- **Estufa.** Plantar fora de estação. É a evolução óbvia do apagão e está em
  `sugestoes-de-features.md`.
- **Neve e folha caindo.** Partícula por estação é polimento visual.
- **Cultivo que atravessa a estação.** Todo cultivo morre na virada se não servir.
- **Festival por estação.** Está em `sugestoes-de-features.md`, e é bem forte no gênero.
