# Plano 06: Plantio e colheita

**Objetivo:** fechar o ciclo da fazenda. Plantar semente em solo arado e molhado, a
planta cresce por estágio a cada dia, e quando está madura o jogador colhe, o item cai no
chão e vai para o inventário.

**Depende de:** 03 (item e item no chão), 04 (inventário), 05 (semente vem da mão).

**Entrega para:** 17 (a fazenda é a fonte primária de renda).

## Contexto

`GradeSolo` já sabe arar, molhar e remover, e já guarda estado por célula num dicionário.
Falta o que fica plantado em cima. As texturas dos 6 cultivos já estão importadas em
`game/assets/textures/tiny_farm_crops/`, com 3 estágios, um ícone e uma versão murcha
cada.

## Decisões fechadas

**O cultivo é 2D e fica em pé, a 90 graus do solo**, como o Antonio pediu. Em Godot isso
é um `Sprite3D` com `billboard = BILLBOARD_FIXED_Y`. Esse modo gira o sprite só em torno
do eixo vertical, então a planta sempre encara a câmera mas nunca deita nem inclina.
Billboard completo faria a planta tombar junto com a câmera; billboard desligado faria
ela sumir de perfil.

Configure também `texture_filter` em nearest, `alpha_cut` em `ALPHA_CUT_DISCARD` e
`pixel_size` por volta de `0.03` para um sprite de 16 pixels dar uma planta de cerca de
meio metro. Ajuste olhando na tela.

**O crescimento é por dia, não por tempo real.** Um estágio por dia, ouvindo
`DayCycleManager.day_started`. Isso é o padrão do gênero e é o que faz o ciclo de dia ter
peso.

**Molhar acelera, não é obrigatório.** Solo molhado avança um estágio por dia. Solo seco
avança um estágio a cada dois dias. Assim regar tem valor sem virar tarefa punitiva. Ao
virar o dia, o solo molhado seca.

**Planta só morre por estação, não por descuido.** Trocar de estação murcha o que não
pertence à estação nova (plano 11). Antes do plano 11 existir, nada murcha, e a textura
`withered` fica sem uso. Isso é proposital: o asset já está lá esperando.

**A colheita só acontece no estágio maduro.** Interagir com planta imatura não faz nada e
não gasta stamina.

**O item colhido cai no chão.** Não vai direto para o inventário. Ele nasce como
`ItemNoMundo` (plano 03) com um empurrão para cima e para o lado, e o jogador pega. É o
que o Antonio pediu, e é o mesmo caminho de todo item dropado do jogo.

## Modelo de dados

`game/scripts/resources/cultivo.gd` ampliado:

```gdscript
class_name Cultivo
extends Resource

@export var id: StringName = &""
@export var nome: String = ""
@export var estagios_de_crescimento: Array[Texture2D] = []
@export var textura_murcha: Texture2D
@export var dias_por_estagio: int = 2
@export var item_colhido: Item
@export var quantidade_colhida_minima: int = 1
@export var quantidade_colhida_maxima: int = 2
@export var estacoes_permitidas: Array[StringName] = []
## Quando maior que zero, a planta volta para este estágio ao ser colhida em vez
## de sumir. É o que faz tomate render várias colheitas de um plantio só.
@export var estagio_de_rebrota: int = 0
```

`dias_por_estagio` igual a 2 com solo molhado contando dobrado é o que gera a regra de
"molhado avança 1 por dia, seco avança 1 a cada 2 dias" sem precisar de dois campos.

Um `.tres` por cultivo em `game/resources/farming/`, um para cada uma das 6 texturas.
Sugestão de ritmo, para o plantio não ficar todo igual:

| cultivo | dias por estágio | rebrota | quantidade |
|---|---|---|---|
| cenoura | 1 | não | 1 a 2 |
| trigo | 1 | não | 2 a 3 |
| beterraba | 2 | não | 1 a 2 |
| repolho | 2 | não | 1 a 1 |
| milho | 2 | estágio 2 | 1 a 2 |
| tomate | 3 | estágio 2 | 1 a 3 |

## Onde mora o estado da planta

`GradeSolo` ganha um segundo dicionário, paralelo ao `_estado` que já existe:

```gdscript
## Célula para PlantaNaGrade. Célula sem entrada é célula sem planta.
var _plantas: Dictionary = {}
```

`PlantaNaGrade` é uma classe interna simples, não um Resource, porque ela é estado de
partida e não conteúdo de jogo:

```gdscript
class PlantaNaGrade:
	var cultivo: Cultivo
	var estagio: int = 0
	var dias_no_estagio: int = 0
	var murcha: bool = false
	var visual: Sprite3D
```

Métodos novos em `GradeSolo`:

```gdscript
func plantar(celula: Vector2i, cultivo: Cultivo) -> bool
func colher(celula: Vector2i) -> bool
func esta_madura(celula: Vector2i) -> bool
func planta_em(celula: Vector2i) -> PlantaNaGrade
func avancar_um_dia() -> void
```

`plantar` recusa quando a célula não está arada, quando já tem planta, ou quando o
cultivo não serve para a estação atual (a checagem de estação fica desligada até o plano
11).

`avancar_um_dia` é conectado a `DayCycleManager.day_started`, e é o único lugar que mexe
em `dias_no_estagio`.

Sinais novos no `EventBus`, seguindo o padrão dos que já existem:

```gdscript
signal crop_planted(celula: Vector2i, cultivo: Cultivo)
signal crop_grown(celula: Vector2i, novo_estagio: int)
```

`crop_harvested` já existe e continua servindo.

## Como plantar e como colher

**Plantar:** o jogador está com uma `Semente` na mão (plano 05) e aperta `atacar`, o
mesmo botão de usar o item da mão. O `player.gd` já tem o caminho de "item na mão faz
alguma coisa na célula alvo": hoje ele chama `GradeSolo.aplicar(id_acao, celula)` para
ferramenta. Acrescente o ramo de semente antes dele, porque semente não é ferramenta.

**Colher:** o jogador aperta `interagir` (não `atacar`) perto da planta madura. Usa a
`AreaInteracao` do plano 03, ou o mesmo cálculo de célula alvo que a ferramenta usa. O
segundo é mais simples e mais consistente com o resto da fazenda, e é o recomendado.

Colher com a mão vazia funciona. Não exige ferramenta.

## Tarefas

- [ ] **1.** Ampliar `cultivo.gd`. Criar os 6 `.tres` apontando para as texturas já
  importadas.
- [ ] **2.** Criar os 6 `.tres` de item colhido e os 6 de semente (plano 03 definiu os
  ids), e ligar `Cultivo.item_colhido` e `Semente.cultivo`.
- [ ] **3.** Adicionar `_plantas`, a classe `PlantaNaGrade` e o método `plantar` em
  `GradeSolo`, criando o `Sprite3D` na posição da célula. Verificar plantando à mão por
  script e vendo a planta aparecer em pé no lugar certo.
- [ ] **4.** Ligar o plantio ao jogador com semente na mão.
- [ ] **5.** Implementar `avancar_um_dia` e conectar ao `day_started`. Como o ciclo de
  dia automático é o plano 10, teste chamando
  `DayCycleManager.avancar_para_o_proximo_dia()` por uma tecla temporária.
- [ ] **6.** Implementar `esta_madura` e `colher`, soltando o item no chão com
  `ItemNoMundo.soltar()`.
- [ ] **7.** Implementar rebrota para milho e tomate.
- [ ] **8.** Ajustar `pixel_size` e altura do sprite olhando o jogo rodando. Este passo é
  de olho, não de conta.
- [ ] **9.** Documentar e commitar.

## Critério de pronto

- Arar, molhar, plantar e a planta aparece em pé no quadrado, encarando a câmera de
  qualquer ângulo, sem deitar.
- Avançar o dia troca a textura para o estágio seguinte, e solo molhado avança no dobro
  da velocidade do seco.
- Interagir com planta imatura não faz nada.
- Interagir com planta madura faz o item cair no chão, girando, e some a planta (ou volta
  para o estágio de rebrota, no caso de milho e tomate).
- Pegar o item do chão soma no inventário e ele aparece na barra rápida.

## Fora de escopo

- **Regar em área.** Um quadrado por vez. Regador melhorado é progressão de ferramenta,
  que não está planejado ainda.
- **Qualidade da colheita.** Sem estrela, sem nível de qualidade.
- **Fertilizante.** O item `composto_organico` e o `nutrisolo` existem no catálogo mas
  não fazem nada ainda. É o gancho para depois.
- **Murchar por estação.** Depende do plano 11. A textura já está pronta e o campo
  `textura_murcha` já existe.
- **Plantar fora da grade.** Só planta em solo arado da `GradeSolo`.
- **Árvore frutífera.** Cultivo de vários anos é outro sistema.
