# Plano 16: Amizade e romance

**Objetivo:** conversar e presentear NPCs muda o relacionamento com cada um. Cada NPC
gosta, ama, não gosta e odeia coisas diferentes. Ao chegar em 10 corações com um
personagem romanceável, o buquê pede em namoro.

**Depende de:** 15 (conversar é o que dá ponto), 05 (o presente é o item na mão), 12 (o
aniversário multiplica o presente).

## Decisões fechadas

**Dez corações, 250 pontos cada, 2500 no máximo.** Coração é a unidade que o jogador vê,
ponto é a unidade interna. Os NPCs não romanceáveis também vão até 10; o que muda é que o
buquê não funciona neles.

**Presentear é soltar o item perto do NPC.** Segurar o item na mão e apertar
`soltar_item` (Q no teclado, L2 no controle), como o Antonio pediu, no mesmo esquema de
Stardew e Rune Factory. Se não houver NPC por perto, o item simplesmente cai no chão, e é
por isso que a mesma ação serve para as duas coisas.

**Um presente por semana, uma conversa por dia.** A semana do jogo tem 6 dias (plano 12).
O contador de presente zera na virada da semana, não 7 dias depois do último presente.
Isso é mais fácil de entender e de comunicar.

**O relacionamento decai quando você some.** Menos 10 pontos por dia depois de 7 dias sem
conversar, e o decaimento para no limiar do coração já conquistado, para o jogador nunca
perder um coração inteiro por descuido. Sem decaimento, todo NPC vira 10 corações e o
sistema perde sentido; com decaimento punitivo, vira tarefa.

## Balanceamento

| Ação | Pontos |
|---|---|
| Conversar (uma vez por dia) | +20 |
| Presente amado | +80 |
| Presente que gosta | +45 |
| Presente neutro | +20 |
| Presente que não gosta | -20 |
| Presente odiado | -40 |
| Presente no aniversário | multiplica por 3 |
| Dia sem conversar, a partir do sétimo | -10 |

Com conversa diária e um presente amado por semana, são 200 pontos por semana, ou seja,
cerca de 12 semanas de jogo (72 dias, pouco mais de duas estações) para chegar aos 10
corações com um NPC. Isso é ritmo de jogo de fazenda: rápido o bastante para ver
progresso, lento o bastante para valer a pena.

## Modelo

`game/scripts/core/relationship_manager.gd`, autoload novo:

```gdscript
extends Node

signal relacionamento_alterado(npc_id: String, pontos: int, coracoes: int)
signal coracao_ganho(npc_id: String, coracoes: int)
signal namoro_iniciado(npc_id: String)

const PONTOS_POR_CORACAO: int = 250
const CORACOES_MAXIMOS: int = 10
const PONTOS_POR_CONVERSA: int = 20
const DIAS_ATE_DECAIR: int = 7
const PONTOS_DE_DECAIMENTO: int = 10

var pontos: Dictionary = {}                 # npc_id para int
var dia_da_ultima_conversa: Dictionary = {} # npc_id para int
var semana_do_ultimo_presente: Dictionary = {}
var namorando: String = ""

func coracoes(npc_id: String) -> int
func registrar_conversa(npc_id: String) -> bool     # false se ja conversou hoje
func presentear(npc_id: String, item: Item) -> ResultadoPresente
func pode_presentear(npc_id: String) -> bool
func pedir_em_namoro(npc_id: String) -> bool
```

`ResultadoPresente` é um enum simples: `AMOU`, `GOSTOU`, `NEUTRO`, `NAO_GOSTOU`,
`ODIOU`, `JA_PRESENTEOU_ESTA_SEMANA`.

`perfil_npc.gd` ganha as quatro listas de gosto:

```gdscript
@export var itens_amados: Array[Item] = []
@export var itens_queridos: Array[Item] = []
@export var itens_indesejados: Array[Item] = []
@export var itens_odiados: Array[Item] = []
```

Item que não está em nenhuma lista é neutro. O campo `Item.pode_ser_presente` (plano 03)
bloqueia ferramenta e arma de virarem presente.

## O que os NPCs gostam

Cada gosto conta uma coisa sobre o personagem, e é assim que o jogador aprende quem eles
são sem precisar de exposição.

| NPC | Ama | Gosta | Não gosta | Odeia |
|---|---|---|---|---|
| Vitor | `servo_motor`, `chapa_reciclada` | `sucata_metal`, `minerio_ferro`, `placa_queimada` | `buque` | `nanogel` |
| Kenji | `nucleo_sintetico`, `fio_optico` | `celula_energia`, `placa_queimada`, `estimulante` | `pedra`, `fibra` | `composto_organico` |
| Rafa | `biocombustivel`, `estimulante` | `pao_de_trigo`, `milho`, `celula_energia` | `pedra` | `sucata_metal` |
| Marta | `sopa_de_legumes`, `repolho` | `cenoura`, `beterraba`, `tomate`, `trigo` | `sucata_metal` | `placa_queimada` |
| Iara | `nanogel`, `sopa_de_legumes` | `beterraba`, `fibra`, `composto_organico` | `sucata_metal` | `estimulante` |
| Sol | `nucleo_sintetico`, `tomate` | `celula_energia`, `pao_de_trigo`, `milho` | `minerio_cobre` | `chapa_reciclada` |

Iara odeia estimulante porque é médica e vê o estrago que ele faz. Sol odeia chapa
reciclada porque é feita de sucata da corporação de onde ela fugiu. Vitor odeia nanogel
porque não confia em remédio da cidade. Detalhe pequeno, e é o que faz o sistema parecer
escrito e não sorteado.

## Presentear

Ao apertar `soltar_item` com item na mão:

1. Procura NPC na `AreaInteracao`. Se não houver, solta o item no chão com
   `ItemNoMundo.soltar()` e acabou.
2. Se houver, e o item tem `pode_ser_presente`, chama `presentear()`.
3. Toca a reação: `emote-yes` para amou e gostou, `emote-no` para não gostou e odiou.
4. Mostra uma fala curta de reação, pela caixa de diálogo do plano 15.
5. Remove o item do inventário.

Presentear na semana em que já presenteou não consome o item e mostra uma fala dizendo
que ele já ganhou algo essa semana.

## Namoro

O `buque` (plano 03) só funciona quando:

- o NPC é romanceável (`eh_romanceavel`),
- está com 10 corações,
- o jogador não está namorando ninguém.

Dar buquê fora dessas condições devolve uma fala de recusa e não consome o item. Isso é
importante: consumir o buquê numa recusa seria punição sem aviso.

Ao aceitar, emite `namoro_iniciado`, e as falas do NPC passam a usar os nós de diálogo com
`relacionamento_minimo` alto (plano 15 já previu o filtro).

## Interface

No menu de pausa (plano 04), uma aba nova de relacionamentos: a lista dos seis NPCs, com
o nome, os corações preenchidos, o aniversário, e um aviso de se ainda dá para presentear
esta semana. Os gostos não aparecem: descobrir é parte da graça.

## A biblioteca de diálogos

Está em `equipe/biblioteca-de-dialogos.md`, com as falas dos seis NPCs por faixa de
relacionamento, por estação, mais as falas de reação a presente e as de aniversário.
Transcrever aquele arquivo para `.tres` de `Conversa` e `NoDialogo` é a tarefa 7 abaixo.

## Tarefas

- [ ] **1.** Criar o `RelationshipManager` e registrar o autoload. Verificar por script
  headless: 250 pontos dá 1 coração, 2500 dá 10, e nunca passa disso.
- [ ] **2.** Adicionar as quatro listas de gosto ao `PerfilNpc` e preencher nos seis
  `.tres`.
- [ ] **3.** Ligar `registrar_conversa` ao fim do diálogo do plano 15.
- [ ] **4.** Implementar `soltar_item`: sem NPC perto, cai no chão.
- [ ] **5.** Implementar presentear, com a reação e o limite semanal.
- [ ] **6.** Implementar o decaimento no `day_started`.
- [ ] **7.** Transcrever `equipe/biblioteca-de-dialogos.md` para os `.tres`.
- [ ] **8.** Implementar o buquê e o namoro.
- [ ] **9.** Criar a aba de relacionamentos no menu de pausa.
- [ ] **10.** Documentar e commitar.

## Critério de pronto

- Conversar uma vez por dia aumenta o relacionamento; conversar de novo no mesmo dia não.
- Soltar item perto de NPC presenteia; longe de NPC, cai no chão.
- Item amado sobe muito mais que item neutro, e item odiado desce.
- Presentear no aniversário do NPC rende o triplo.
- Tentar presentear duas vezes na mesma semana é recusado sem consumir o item.
- A fala do NPC muda de tom conforme os corações sobem.
- Aos 10 corações, o buquê num romanceável inicia o namoro.
- Sumir por mais de uma semana faz o relacionamento decair, mas nunca abaixo do coração
  já conquistado.

## Fora de escopo

- **Casamento e filhos.** Namoro é o fim da linha aqui.
- **Ciúme e rivalidade entre NPCs.** Namorar mais de um ao mesmo tempo é simplesmente
  bloqueado.
- **Evento de coração** (cena especial ao atingir certos corações). É o que mais falta
  para o sistema ter alma, e está em `sugestoes-de-features.md` como a sugestão de maior
  valor.
- **Presente embrulhado, correio, carta.** Fora do escopo pedido.
- **NPC dando presente de volta.** Bonito, e barato de fazer depois.
