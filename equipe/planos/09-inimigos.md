# Plano 09: Inimigos

**Objetivo:** três tipos de inimigo, cada um com velocidade, dano e padrão de ataque
diferentes, perseguindo o jogador dentro de um raio e voltando ao comportamento ocioso
quando ele se afasta. Eles tiram vida, levam dano, reagem ao dano e morrem.

**Depende de:** 07 (vida), 08 (o que causa dano neles).

## Contexto e placeholder

Os inimigos são ciborgues e robôs, tema cyberpunk. Não existe modelo de inimigo no
projeto. Use os personagens do `kenney_mini_characters` como placeholder, um modelo
diferente por tipo, tingido de outra cor para não confundir com NPC:

| Tipo | Modelo placeholder | Cor |
|---|---|---|
| Drone rastejador | `character_male_e.glb` | vermelho |
| Ciborgue operário | `character_male_f.glb` | laranja |
| Sentinela pesada | `character_female_f.glb` | roxo |

Tingir é sobrescrever `albedo_color` no material do modelo instanciado, em runtime, no
`_ready` do inimigo. Não mexa no `.glb`.

Todos os clipes de animação listados no plano 08 valem aqui, porque é o mesmo esqueleto.
`attack-kick-left` e `attack-kick-right` ficaram reservados justamente para o inimigo.

## Os três tipos

O que muda entre eles é dado, não código. Um `Resource` configura tudo.

| | Drone rastejador | Ciborgue operário | Sentinela pesada |
|---|---|---|---|
| Vida | 30 | 70 | 160 |
| Velocidade | 4.5 | 2.8 | 1.8 |
| Dano | 6 | 14 | 30 |
| Alcance de ataque | 1.0 | 1.4 | 2.2 |
| Intervalo entre ataques | 0.8s | 1.6s | 2.8s |
| Raio de percepção | 9 | 12 | 7 |
| Raio de desistência | 14 | 18 | 10 |
| Comportamento ocioso | corre em círculo | patrulha entre dois pontos | fica parado, gira devagar |
| Animação de ataque | `attack-kick-left` | `attack-melee-right` | `attack-kick-right` |
| Experiência | 20 | 35 | 60 |
| Sucata que dropa | `sucata_metal` | `placa_queimada`, `fio_optico` | `servo_motor`, `celula_energia` |

O drone é rápido e fraco, para ensinar o jogador a desviar. O ciborgue é o inimigo
padrão. A sentinela é lenta e perigosa, e é a que recompensa a arma pesada e o dash.

## Modelo de dados

`game/scripts/resources/perfil_inimigo.gd`:

```gdscript
class_name PerfilInimigo
extends Resource

enum ComportamentoOcioso { CIRCULO, PATRULHA, PARADO }

@export var id: StringName = &""
@export var nome: String = ""
@export var modelo: PackedScene
@export var cor: Color = Color.WHITE

@export var vida_maxima: int = 50
@export var velocidade: float = 3.0
@export var dano: int = 10
@export var alcance_de_ataque: float = 1.4
@export var intervalo_entre_ataques: float = 1.5
@export var animacao_de_ataque: StringName = &"attack-melee-right"

@export var raio_de_percepcao: float = 10.0
@export var raio_de_desistencia: float = 15.0
@export var comportamento_ocioso: ComportamentoOcioso = ComportamentoOcioso.PATRULHA

@export var experiencia_concedida: int = 30
@export var itens_dropados: Array[Item] = []
@export var chance_de_drop: float = 0.6
```

`raio_de_desistencia` maior que `raio_de_percepcao` de propósito. Se fossem iguais, o
inimigo ficaria ligando e desligando a perseguição na borda exata, tremendo no lugar.
Essa folga é o que resolve, e é o erro clássico dessa mecânica.

## Máquina de estados

Quatro estados, num enum, num `match` dentro do `_physics_process`. Não use nó por
estado: para quatro estados isso é mais cerimônia que ajuda.

```
OCIOSO      -> jogador entrou no raio de percepcao      -> PERSEGUINDO
PERSEGUINDO -> jogador saiu do raio de desistencia      -> OCIOSO
PERSEGUINDO -> distancia menor que alcance de ataque    -> ATACANDO
ATACANDO    -> terminou o golpe e o intervalo           -> PERSEGUINDO
qualquer    -> vida chegou a zero                       -> MORRENDO
```

`MORRENDO` toca `die`, desliga a colisão, espera a animação, solta o drop e some.

Script `game/scripts/combat/inimigo.gd`, com `class_name Inimigo`, estendendo
`CharacterBody3D`. Cena `game/scenes/combat/inimigo.tscn`, genérica, configurada por um
`@export var perfil: PerfilInimigo`.

```gdscript
class_name Inimigo
extends CharacterBody3D

enum Estado { OCIOSO, PERSEGUINDO, ATACANDO, MORRENDO }

@export var perfil: PerfilInimigo

func receber_dano(quantidade: int, origem_da_posicao: Vector3) -> void
func esta_vivo() -> bool
```

Camadas conforme o plano 01: camada `inimigo`, máscara `mundo` e `jogador`.

## Feedback de dano

Isto é o que o Antonio pediu e é o que separa combate que responde de combate mudo. Ao
receber dano, tanto no inimigo quanto no jogador:

1. **Empurrão para trás.** O alvo é deslocado na direção oposta a quem bateu, por volta de
   3 metros por segundo, decaindo em 0.15 segundo. Durante esse tempo ele não controla o
   próprio movimento.
2. **Piscada branca.** O material do modelo vai para branco por 0.08 segundo e volta. Um
   `Tween` no `albedo_color` resolve.
3. **Invencibilidade curta**, 0.4 segundo, para não tomar cinco golpes num quadro.
4. **Som** pelo `AudioManager`.

Para o jogador, some uma sacudida leve de câmera. A câmera é
`game/scenes/player/camera_jogador.tscn`.

Vale extrair isso para um nó reusável, `game/scenes/combat/reacao_a_dano.tscn`, com
script, instanciado tanto no jogador quanto no inimigo. É exatamente o tipo de
comportamento repetido que as convenções mandam virar cena própria.

Sinais novos no `EventBus`:

```gdscript
signal dano_causado(alvo: Node3D, quantidade: int)
signal inimigo_derrotado(perfil: PerfilInimigo, posicao: Vector3)
```

## Área de teste

Um canto do `playground.tscn`, longe da fazenda, com um `Node3D` chamado `AreaDeTeste`
contendo umas seis instâncias de `inimigo.tscn`: três drones, dois ciborgues e uma
sentinela. Marcadores de patrulha (`Marker3D`) para os que patrulham.

## Tarefas

- [ ] **1.** Criar `perfil_inimigo.gd` e os três `.tres`.
- [ ] **2.** Criar `inimigo.tscn` e o script com a máquina de estados, só com `OCIOSO` e
  `PERSEGUINDO`. Verificar: o inimigo persegue ao chegar perto e desiste ao se afastar,
  sem tremer na borda.
- [ ] **3.** Implementar os três comportamentos ociosos.
- [ ] **4.** Implementar `ATACANDO`, com a hitbox do inimigo tirando vida do jogador.
- [ ] **5.** Fazer o inimigo levar dano da hitbox e do projétil do jogador (plano 08).
- [ ] **6.** Criar `reacao_a_dano.tscn` e usar nos dois lados.
- [ ] **7.** Implementar `MORRENDO`, com drop de item usando `ItemNoMundo.soltar()` e
  experiência pelo `StatusManager`.
- [ ] **8.** Montar a área de teste no playground.
- [ ] **9.** Ajustar os números jogando. A tabela acima é chute.
- [ ] **10.** Documentar e commitar.

## Critério de pronto

- Chegar perto de um inimigo faz ele vir atrás; se afastar o bastante faz ele voltar ao
  comportamento ocioso, sem oscilar.
- Os três se comportam visivelmente diferente, tanto parados quanto perseguindo.
- Apanhar tira vida, empurra o jogador para trás e pisca.
- Bater tira vida do inimigo, empurra e pisca.
- Inimigo morto toca a animação, solta item no chão e dá experiência.
- Vários inimigos ao mesmo tempo não travam o jogo.

## Fora de escopo

- **Navegação com desvio de obstáculo.** O inimigo anda em linha reta na direção do
  jogador. Vai encostar em parede às vezes. `NavigationAgent3D` é a solução certa e está
  em `sugestoes-de-features.md`, mas é um sistema inteiro.
- **Inimigo que aparece sozinho** por horário ou por região. Aqui eles são colocados à
  mão no playground, para teste. Geração automática combina com o plano 10.
- **Chefe.** Um por vez.
- **Inimigo com ataque de longe.** Os três são corpo a corpo. O projétil do plano 08 já
  serviria, e é a evolução natural.
- **Modelo de inimigo de verdade.** Placeholder tingido é suficiente, e o Antonio pediu
  explicitamente para usar villager como placeholder.
