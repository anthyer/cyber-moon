# Plano 07: Status, vida e stamina

**Objetivo:** o jogador passa a ter vida e stamina. Ação custa stamina, stamina zerada
derruba o personagem e encerra o dia com penalidade, e os dois máximos crescem com o
nível.

**Depende de:** 04 (a barra aparece no menu e na HUD), 06 (as ações de fazenda são o que
gasta stamina).

**Entrega para:** 08, 09, 10, 17.

## Decisões fechadas

**Um autoload `StatusManager`.** Vida e stamina são consultados por combate, por fazenda,
pelo ciclo de dia e pela interface. É responsabilidade própria, e cabe num autoload
pequeno.

**Stamina não regenera andando.** Ela volta dormindo e comendo. Isso é o que dá peso à
decisão de quantas tarefas fazer no dia, que é o núcleo do gênero. Vida regenera devagar
fora de combate.

**Desmaio custa dinheiro e stamina do dia seguinte**, como o Antonio pediu. Ao zerar a
stamina o personagem desmaia onde está, o dia termina, e no dia seguinte ele acorda em
casa com stamina máxima reduzida e menos crédito.

**Nível sobe por ação, não por experiência de combate só.** Colher, arar e derrotar
inimigo dão experiência. Assim quem joga só de fazendeiro também evolui.

## Modelo de dados

`game/scripts/core/status_manager.gd`:

```gdscript
extends Node

signal vida_alterada(atual: int, maxima: int)
signal stamina_alterada(atual: float, maxima: float)
signal nivel_alterado(novo_nivel: int)
signal jogador_desmaiou
signal jogador_morreu

const VIDA_BASE: int = 100
const STAMINA_BASE: float = 100.0
const VIDA_POR_NIVEL: int = 10
const STAMINA_POR_NIVEL: float = 8.0

## Penalidade aplicada no dia seguinte a um desmaio.
const FATOR_STAMINA_APOS_DESMAIO: float = 0.6
const CREDITOS_PERDIDOS_AO_DESMAIAR: int = 100

var nivel: int = 1
var experiencia: int = 0
var vida_atual: int
var stamina_atual: float
var desmaiou_ontem: bool = false

func vida_maxima() -> int
func stamina_maxima() -> float
func gastar_stamina(quantidade: float) -> bool   # false quando nao havia o bastante
func tem_stamina(quantidade: float) -> bool
func receber_dano(quantidade: int, origem: Node3D = null) -> void
func curar(quantidade: int) -> void
func recuperar_stamina(quantidade: float) -> void
func ganhar_experiencia(quantidade: int) -> void
func dormir() -> void      # restaura para o novo dia, aplicando penalidade se houve desmaio
```

## Tabela de custos

Números iniciais, para ajustar jogando. A referência é: um dia de 100 de stamina deve dar
para arar, molhar e plantar uns 15 quadrados e ainda sobrar para explorar.

| Ação | Stamina | Experiência |
|---|---|---|
| Arar um quadrado | 2.0 | 1 |
| Molhar um quadrado | 1.0 | 1 |
| Remover com a picareta | 2.0 | 0 |
| Plantar | 0.5 | 1 |
| Colher | 1.0 | 3 |
| Golpe de punho | 1.0 | 0 |
| Golpe de arma leve | 1.5 | 0 |
| Golpe de arma pesada | 4.0 | 0 |
| Tiro de arma ranged | 2.0 | 0 |
| Dash | 3.0 | 0 |
| Derrotar inimigo | 0 | 20 a 60 conforme o tipo |

Experiência para o nível seguinte: `100 * nivel`. Nível máximo 20.

## Onde ligar

O ponto natural é `GradeSolo.aplicar()`, que já é a tabela de despacho de toda ação de
ferramenta e já devolve se a ação teve efeito. O custo de stamina entra ali, antes de
executar, e a ação é recusada quando não há stamina.

Cuidado com a ordem: cobrar a stamina só quando a ação teve efeito. Arar um quadrado que
já estava arado devolve `false` e não pode custar nada.

Para o dash e o ataque, o ponto é o `player.gd`, nas mesmas condições que já verificam
cooldown.

## Interface

HUD sempre visível, canto superior esquerdo: uma barra de vida vermelha e uma de stamina
verde, empilhadas, mais o número do nível. Cena
`game/scenes/ui/hud_status.tscn`, script correspondente, ouvindo os três sinais do
`StatusManager`.

A stamina pisca quando está abaixo de 20 por cento. É aviso barato e eficaz.

As mesmas barras aparecem no menu de pausa, no espaço já reservado pelo plano 04.

## Desmaio

Quando `stamina_atual` chega a zero:

1. Emite `jogador_desmaiou`.
2. O jogador perde o controle e toca a animação de queda (use `die` do pacote Kenney, ou
   a mais próxima disponível).
3. Escurece a tela.
4. Chama `DayCycleManager.avancar_para_o_proximo_dia()`.
5. Teleporta o jogador para a posição de casa.
6. `StatusManager.dormir()` restaura, mas com `desmaiou_ontem` ligado, o que reduz a
   stamina máxima daquele dia pelo fator, e desconta os créditos.
7. Mostra um texto curto contando o que aconteceu.

A posição de casa é uma marcação `Marker3D` chamada `PontoDeSpawn` no `playground.tscn`.

Vida chegando a zero segue o mesmo caminho, emitindo `jogador_morreu`, com penalidade
maior. Sem tela de game over: no gênero, perder é perder um dia.

## Tarefas

- [ ] **1.** Criar o `StatusManager` e registrar o autoload. Verificar por script
  headless: gastar stamina até zerar e conferir que o sinal saiu.
- [ ] **2.** Criar `hud_status.tscn` e ligar aos sinais. Colocar no `playground.tscn`.
- [ ] **3.** Cobrar stamina em `GradeSolo.aplicar()`, só quando a ação teve efeito.
- [ ] **4.** Cobrar stamina no dash e no ataque, em `player.gd`.
- [ ] **5.** Implementar experiência e nível, com os máximos crescendo.
- [ ] **6.** Implementar o desmaio inteiro, com o `Marker3D` de casa.
- [ ] **7.** Ligar `Consumivel` (plano 03) a `curar` e `recuperar_stamina`, com o botão
  de usar item da mão.
- [ ] **8.** Ajustar os números jogando. Este passo não é opcional: a tabela acima é
  chute.
- [ ] **9.** Documentar e commitar.

## Critério de pronto

- Arar consome stamina e a barra desce.
- Arar sem stamina não faz nada e não consome.
- Zerar a stamina derruba o personagem, avança o dia, e ele acorda em casa com a barra
  mais curta que o normal e menos crédito.
- Colher dá experiência e subir de nível aumenta os dois máximos.
- Comer um consumível recupera o que ele promete.

## Fora de escopo

- **Atributos separados** de ataque, defesa e sorte. Vida e stamina bastam por enquanto.
- **Árvore de habilidades.** Nível só aumenta os máximos.
- **Fome e sono como barras próprias.** O gênero costuma ter só stamina, e somar barras
  cansa o jogador.
- **Salvar o status.** O `SaveManager` precisa ganhar esses campos, mas ele já está
  defasado em relação a vários sistemas. Registre em `pendencias.md` e trate o save
  inteiro de uma vez depois.
