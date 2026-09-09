# Plano 10: Ciclo de dia e noite

**Objetivo:** o tempo passa sozinho, a iluminação da cena acompanha a hora, o jogador
tem uma luz curta própria para enxergar à noite, e às 1 da manhã ele cai no sono com
penalidade.

**Depende de:** 07 (a penalidade do sono é a mesma do desmaio).

**Entrega para:** 11, 12, 13, 14.

## Contexto

O `DayCycleManager` já existe com `numero_do_dia`, `hora_atual`, os sinais `day_started`
e `day_ended`, e `avancar_para_o_proximo_dia()`. Mas nada faz `hora_atual` andar. Este
plano dá corda no relógio.

## Decisões fechadas

**O dia vai das 6:00 às 2:00 do dia seguinte.** Vinte horas de jogo. Das 6:00 às 18:00 é
dia, das 18:00 às 2:00 é noite.

**Cinco minutos reais de dia e cinco de noite**, como o Antonio calibrou. Como o dia tem
12 horas de jogo e a noite tem 8, o relógio anda em duas velocidades:

```gdscript
const SEGUNDOS_REAIS_POR_HORA_DE_DIA: float = 300.0 / 12.0    # 25 s
const SEGUNDOS_REAIS_POR_HORA_DE_NOITE: float = 300.0 / 8.0   # 37.5 s
```

Velocidade diferente entre dia e noite não é problema, é controle de ritmo. A noite passa
mais devagar por hora justamente porque é o período em que o jogador se apressa.

**Às 1:00 o personagem cai no sono onde estiver.** Não dá para virar a noite. A
penalidade é a mesma do desmaio por stamina, que o plano 07 já implementou: stamina
máxima reduzida no dia seguinte e perda de créditos. Isso é de propósito: uma penalidade
só, aplicada por dois caminhos, é mais fácil de entender e de balancear.

**Dormir na cama antes disso é o caminho bom.** Sem penalidade, e é o que restaura a
stamina cheia.

**A luz do jogador é curta e sempre ligada**, mas só faz diferença no escuro. Uma
`OmniLight3D` de raio pequeno presa ao jogador. Ela é o gancho para item de lanterna
depois, e por isso o alcance e a energia são exportados.

## Modelo

`DayCycleManager` ampliado:

```gdscript
extends Node

signal day_started(numero_do_dia: int)
signal day_ended(numero_do_dia: int)
signal hora_mudou(hora: float)
signal periodo_mudou(periodo: Periodo)
signal jogador_dormiu(forcado: bool)

enum Periodo { MADRUGADA, MANHA, TARDE, ANOITECER, NOITE }

const HORA_INICIO_DIA: float = 6.0
const HORA_ANOITECER: float = 18.0
const HORA_LIMITE: float = 25.0        # 1:00 do dia seguinte
const SEGUNDOS_REAIS_POR_HORA_DE_DIA: float = 25.0
const SEGUNDOS_REAIS_POR_HORA_DE_NOITE: float = 37.5

var numero_do_dia: int = 1
var hora_atual: float = HORA_INICIO_DIA
var tempo_congelado: bool = false

func avancar_para_o_proximo_dia() -> void
func dormir(forcado: bool = false) -> void
func periodo_atual() -> Periodo
func hora_formatada() -> String        # "07:30"
func fracao_do_dia() -> float          # 0.0 no inicio, 1.0 no limite
```

As horas passam de 24 e continuam contando (24.5 é 0:30, 25.0 é 1:00). Isso evita a
matemática de virada de meia-noite espalhada pelo código. Só `hora_formatada()` precisa
saber disso, com um `fmod(hora_atual, 24.0)`.

`tempo_congelado` existe porque o tempo não pode andar durante o menu de pausa nem
durante um diálogo (plano 15).

## Iluminação

Um nó novo `IluminacaoDoCiclo`, script
`game/scripts/core/iluminacao_do_ciclo.gd`, colocado no `playground.tscn` junto da luz
que já existe. Ele controla o `DirectionalLight3D` e o `WorldEnvironment` que já estão na
cena.

Por hora, interpolando entre pontos:

| Hora | Cor da luz | Energia | Ambiente |
|---|---|---|---|
| 6:00 | laranja quente | 0.4 | escuro azulado |
| 9:00 | branco levemente quente | 1.0 | claro |
| 15:00 | branco | 1.0 | claro |
| 18:00 | laranja forte | 0.7 | quente |
| 20:00 | azul escuro | 0.15 | escuro |
| 25:00 | azul bem escuro | 0.10 | bem escuro |

O ângulo da luz direcional também gira ao longo do dia, do leste para o oeste.

**Cuidado ao escrever a rotação da luz à mão no `.tscn`.** Os 9 números do `Transform3D`
são as linhas da matriz, não os vetores de eixo. Já aconteceu neste projeto de a luz
acabar apontando para o céu por causa disso, e passar despercebido. Prefira mexer pelo
editor, ou pelo script em runtime com `look_at`, em vez de escrever a matriz na mão.

A energia nunca chega a zero. Noite totalmente preta é frustrante, e o padrão do gênero é
uma noite azulada em que ainda dá para se orientar.

## Luz do jogador

No `player.tscn`, uma `OmniLight3D` chamada `LuzDoJogador`:

- `omni_range` igual a 6.0
- `light_energy` igual a 1.2
- `light_color` levemente ciano, para combinar com a estética cyberpunk
- posição em `(0, 1.2, 0)`, na altura do peito

Exporte alcance e energia num script pequeno para item futuro poder aumentar.

## Dormir

Um `Area3D` chamada `Cama` no `playground.tscn`, dentro da casa, na camada
`area_interacao`. Interagir com ela chama `DayCycleManager.dormir(false)`.

O sono forçado às 1:00 chama `dormir(true)`, e aí:

1. Escurece a tela.
2. Toca `die` (a mesma animação do desmaio).
3. Teleporta para o `PontoDeSpawn`.
4. Avança o dia com a penalidade do plano 07.

## Interface

Um relógio no canto superior direito: hora formatada, número do dia, e um indicador
simples de período. Cena `game/scenes/ui/hud_relogio.tscn`. Ele fica vermelho depois da
meia-noite, como aviso.

## Tarefas

- [ ] **1.** Ampliar o `DayCycleManager` com o avanço da hora, os períodos e os sinais.
  Verificar por script headless: simular o `_process` e conferir que 5 minutos de dia dão
  12 horas de jogo.
- [ ] **2.** Criar `hud_relogio.tscn` e colocar no playground.
- [ ] **3.** Criar `iluminacao_do_ciclo.gd` e ligar ao `DirectionalLight3D` e ao
  `WorldEnvironment` existentes. Rodar e ver o dia inteiro passar uma vez.
- [ ] **4.** Ajustar as cores e as energias olhando na tela. A tabela é ponto de partida.
- [ ] **5.** Adicionar a `LuzDoJogador`.
- [ ] **6.** Adicionar a `Cama` e o dormir voluntário.
- [ ] **7.** Implementar o sono forçado às 1:00 com a penalidade.
- [ ] **8.** Congelar o tempo durante o menu de pausa.
- [ ] **9.** Ligar `avancar_um_dia` da `GradeSolo` (plano 06) ao `day_started`, se ainda
  não estiver.
- [ ] **10.** Documentar e commitar.

## Critério de pronto

- O relógio anda e o dia vira sozinho.
- A cena escurece ao anoitecer e clareia ao amanhecer, de forma contínua e não em salto.
- À noite dá para enxergar em volta do personagem, e longe dele fica escuro.
- Dormir na cama passa o dia sem penalidade.
- Chegar à 1:00 derruba o personagem e o dia seguinte começa com a stamina reduzida.
- As plantas avançam de estágio ao virar o dia.

## Fora de escopo

- **Sombra dinâmica de qualidade.** O renderizador é GL Compatibility, e sombra boa custa
  caro. Se ficar pesado, desligue a sombra da luz direcional.
- **Estrela e lua no céu.** Fica bonito, e está em `sugestoes-de-features.md`.
- **Loja fechar por horário.** É o plano 17.
- **Rotina de NPC por hora.** É o plano 14, e vai ler `hora_atual` daqui.
- **Salvar o horário.** Junto do resto do save, que já está defasado.
