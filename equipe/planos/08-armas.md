# Plano 08: Armas

**Objetivo:** além do punho que já existe, o jogador ganha arma leve, arma pesada e arma
de longo alcance, com modelo visível na mão e animação diferente por tipo.

**Depende de:** 04 (arma é item equipado), 05 (a arma é o item na mão), 07 (golpe custa
stamina).

**Entrega para:** 09 (o inimigo precisa levar dano de alguma coisa).

## O que o pacote de personagens já oferece

Isto foi verificado carregando o `.glb` no Godot, não é suposição. O
`character_male_a.glb` tem 32 animações e um esqueleto de 7 ossos.

Animações relevantes que **ainda não são usadas** pelo jogo:

| Clipe | Duração | Serve para |
|---|---|---|
| `attack-kick-left` / `attack-kick-right` | 0.53s | chute, e ataque de inimigo (plano 09) |
| `holding-both` | 0.17s | pose parada segurando arma com as duas mãos |
| `holding-both-shoot` | 0.20s | disparo com as duas mãos |
| `holding-left` / `holding-right` | 0.17s | pose segurando com uma mão |
| `holding-left-shoot` / `holding-right-shoot` | 0.20s | disparo com uma mão |
| `pick-up` | 0.33s | pegar item do chão |
| `die` | 0.33s | morte e desmaio |
| `emote-yes` / `emote-no` | 0.67s | reação em diálogo (plano 15) |

Já usadas hoje: `attack-melee-left`, `attack-melee-right` (combo de soco),
`interact-left`, `interact-right` (uso de ferramenta), `idle`, `walk`, `sprint`, `jump`
(dash).

Ossos do esqueleto: `root`, `leg-left`, `leg-right`, `torso`, `arm-left`, `arm-right`,
`head`. O osso `arm-right` é onde a arma prende, com um `BoneAttachment3D`.

Modelo para o espadão placeholder: `aid_crutch.glb`, do mesmo pacote. A parte comprida
dele mede cerca de 0.31 de altura, então escalado por volta de 2.5 vezes vira um espadão
plausível para um personagem desse tamanho. Foi a ideia do Antonio e funciona.

## Decisões fechadas

**Três tipos, um enum, um caminho de código.** Não são três sistemas, é um sistema com
três configurações. A diferença entre leve e pesada é número e velocidade de animação, não
lógica.

**Pesada reusa o clipe de melee, mais lento.** O `player.gd` já toca a animação com um
multiplicador de velocidade (`velocidade_ataque`). Tocar `attack-melee-right` a 0.55 da
velocidade dá peso, sem precisar de animação nova. Chute fica reservado para o inimigo.

**O dano sai de uma `Area3D`, não de raycast.** A hitbox liga por alguns quadros no meio
da animação e desliga depois. Isso permite acertar mais de um inimigo com o mesmo golpe,
que é o que faz arma pesada valer a pena.

**Arma de longo alcance dispara projétil de verdade**, não hitscan. Projétil dá para ver,
dá para errar, e é mais fácil de depurar.

## Modelo de dados

`game/scripts/resources/arma.gd`:

```gdscript
class_name Arma
extends Item

enum Tipo { LEVE, PESADA, DISTANCIA }

@export var tipo: Tipo = Tipo.LEVE
@export var dano: int = 10
@export var alcance: float = 1.2          # raio da hitbox, em metros
@export var custo_de_stamina: float = 1.5
@export var velocidade_da_animacao: float = 1.6
@export var cooldown: float = 0.3
@export var modelo: PackedScene
@export var escala_do_modelo: Vector3 = Vector3.ONE
@export var deslocamento_do_modelo: Transform3D = Transform3D.IDENTITY
@export var projetil: PackedScene         # so para Tipo.DISTANCIA
@export var velocidade_do_projetil: float = 18.0
@export var som_do_golpe: AudioStream
```

## As armas iniciais

Quatro `.tres` em `game/resources/items/armas/`, mais o punho, que continua sendo o slot
vazio e não é item.

| id | nome | tipo | dano | alcance | stamina | vel. anim. | modelo |
|---|---|---|---|---|---|---|---|
| (nenhum) | Punho | leve | 5 | 1.0 | 1.0 | 1.6 | nenhum |
| `foice_curva` | Foice curva | leve | 12 | 1.2 | 1.5 | 1.8 | `aid_cane.glb` |
| `espadao_sucata` | Espadão de sucata | pesada | 34 | 1.9 | 4.0 | 0.55 | `aid_crutch.glb`, escala 2.5 |
| `rifle_de_ferro` | Rifle de ferro velho | distância | 18 | 14.0 | 2.0 | 1.0 | `aid_cane_blind.glb` |
| `bastao_choque` | Bastão de choque | leve | 20 | 1.3 | 2.0 | 1.5 | `aid_cane_low_vision.glb` |

Os modelos são placeholder honesto: são bengalas e muleta do pacote de acessibilidade,
que por acaso têm o formato de bastão comprido. Trocar por modelo de arma de verdade
depois é só mudar o campo `modelo` no `.tres`, sem tocar em código.

## Estrutura na cena do jogador

```
Player (CharacterBody3D)
  Personagem (Node3D)
    ...Skeleton3D
      MaoDireita (BoneAttachment3D, osso "arm-right")
        <modelo da arma instanciado aqui em runtime>
  HitboxAtaque (Area3D, camada hitbox_ataque, mascara inimigo)
    FormaHitbox (CollisionShape3D, SphereShape3D)
```

A `HitboxAtaque` fica desabilitada por padrão. Um script novo,
`game/scripts/combat/ataque_do_jogador.gd`, cuida de:

```gdscript
## Liga a hitbox pelo tempo do golpe e devolve quem foi atingido.
func executar_golpe(arma: Arma) -> void
## Troca o modelo preso na mão quando a arma equipada muda.
func trocar_modelo(arma: Arma) -> void
func disparar(arma: Arma, direcao: Vector3) -> void
```

A hitbox liga no meio da animação. Como as animações vêm dentro do `.glb` e não aceitam
method track sem reimportar, use a mesma técnica do plano 02: ligue a hitbox numa fração
da duração do clipe. Para os clipes de melee, entre 0.35 e 0.65 da duração funciona bem.

## Projétil

Cena `game/scenes/combat/projetil.tscn`, script correspondente. Um `Area3D` com
`CollisionShape3D` pequena, máscara em `inimigo` e `mundo`, que anda para frente numa
velocidade fixa, some ao acertar qualquer coisa e some sozinho depois de 3 segundos.

```gdscript
class_name Projetil
extends Area3D

var dano: int = 0
var velocidade: float = 18.0
var direcao: Vector3 = Vector3.FORWARD
var dono: Node3D
```

O `dono` existe para o projétil do jogador não acertar o jogador, e mais tarde o do
inimigo não acertar o inimigo.

## Animação por tipo

O `_atualizar_animacao` do `player.gd` ganha um caso novo: quando a arma equipada é do
tipo `DISTANCIA` e o jogador está parado, a animação de repouso é `holding-both` em vez de
`idle`. Andando continua `walk`, porque não existe clipe de andar segurando arma, e essa
diferença não incomoda em câmera de cima.

Disparar toca `holding-both-shoot`.

## Tarefas

- [ ] **1.** Criar `arma.gd` e os 4 `.tres`.
- [ ] **2.** Adicionar o `BoneAttachment3D` no `arm-right` e fazer o modelo da arma
  aparecer e sumir ao trocar de slot. Verificar visualmente: a arma tem que acompanhar a
  mão durante a animação de andar.
- [ ] **3.** Ajustar `deslocamento_do_modelo` e `escala_do_modelo` de cada arma olhando
  no jogo. Este passo é de olho e vai levar mais tempo que parece.
- [ ] **4.** Criar `ataque_do_jogador.gd` e a `HitboxAtaque`. Sem inimigo ainda, teste
  colocando um `Area3D` de mentira no playground e imprimindo quando for atingido.
- [ ] **5.** Ligar o ataque ao `player.gd`, respeitando o tipo da arma, o cooldown e o
  custo de stamina do plano 07.
- [ ] **6.** Implementar o golpe pesado com a animação desacelerada.
- [ ] **7.** Criar o projétil e a arma de distância, com a pose `holding-both`.
- [ ] **8.** Ligar o som do golpe (`AudioManager.tocar_sfx`, plano 02).
- [ ] **9.** Documentar e commitar.

## Critério de pronto

- Trocar de slot troca o modelo na mão, e ele fica preso corretamente durante o
  movimento.
- Punho continua fazendo o combo de três golpes, igual hoje.
- Foice bate mais rápido que o espadão, e o espadão tem alcance visivelmente maior.
- O rifle dispara um projétil que viaja, some ao bater na parede e some sozinho no ar.
- Todo golpe consome stamina e não sai quando não há stamina.
- Com o slot da arma selecionado, a ferramenta não é usada, e vice-versa.

## Fora de escopo

- **Durabilidade de arma.** Não foi pedido e obriga a interface a mostrar mais uma coisa.
- **Combo de arma.** Só o punho tem combo. Arma dá um golpe por vez.
- **Ataque carregado.** Segurar o botão para dar golpe forte é boa ideia, e está anotado
  em `sugestoes-de-features.md`.
- **Munição.** O rifle atira sem gastar item. Munição é um sistema de economia e cabe
  melhor junto do plano 17.
- **Arma de dois slots** ou troca rápida entre arma e ferramenta. A barra rápida resolve.
