# Plano 02: Som

**Prioridade.** Junto com o plano 01, é o que precisa estar pronto antes do vídeo de
entrega.

**Objetivo:** o sistema de áudio inteiro montado e funcionando, com passo que varia por
superfície e música de fundo. O sistema tem que rodar sem erro com zero arquivos de
áudio carregados, para não ficar bloqueado esperando os clipes.

**Abordagem:** um autoload `AudioManager` com buses separados, um `Resource` que mapeia
superfície para lista de clipes de passo, superfície descoberta por raycast para baixo, e
o disparo do passo amarrado à fase do ciclo de animação, para o som sair quando o pé
encosta e não num intervalo fixo.

**Depende de:** plano 01. O raycast que descobre a superfície precisa acertar um corpo
com colisão, e a metadata `superficie` nasce lá.

---

## Antes de começar: duas perguntas para o Bernardo

**1. Você usa Epidemic Sound?**

Se usa, vale conectar a plataforma ao agente por MCP antes de seguir. Com isso dá para
buscar, ouvir e baixar trilha e efeito direto pela conversa, o que economiza muito tempo
nos sons que ainda vão vir (ambiente, estação, combate, interface). O
`equipe/instalacao.md`, passo 5, explica o caminho e o cuidado com credencial.

Se não usa, ignore e providencie os arquivos de onde preferir. O plano funciona igual.

**2. Você já tem os clipes?**

O sistema roda vazio de propósito, então dá para implementar tudo hoje. Mas o vídeo de
entrega fica muito melhor com passo tocando. O que é preciso está na seção "O que
providenciar" logo abaixo.

---

## O que providenciar

**Passos.** De 6 a 9 arquivos por superfície, cada arquivo com **um passo só**. São 6
superfícies (`grama`, `terra`, `pedra`, `madeira`, `metal`, `asfalto`), mas dá para
começar com duas ou três e o resto cai no padrão.

Formato `.wav`, conforme `game/docs/pipeline_de_assets.md`: passo é efeito curto onde a
latência de decodificação importa, então não vira `.ogg`.

Caminho e nome:

```
game/assets/audio/sfx/passos/grama/passo_01.wav
game/assets/audio/sfx/passos/grama/passo_02.wav
...
game/assets/audio/sfx/passos/asfalto/passo_09.wav
```

Se o clipe que você conseguir tiver vários passos em sequência no mesmo arquivo (toc,
toc, toc), use o `equipe/ferramentas/dividir_passos.py`, que corta por detecção de
silêncio e já numera na saída:

```bash
./equipe/ferramentas/dividir_passos.py clipe_bruto.wav game/assets/audio/sfx/passos/grama
```

Ele roda com o Python que já vem na máquina, sem instalar nada. Use `--listar` para ver
onde ele pretende cortar antes de gravar, e `--limiar 0.03` se ele perder passo fraco.

**Música.** Um arquivo `.ogg` em `game/assets/audio/music/`. Para o vídeo, uma faixa só
já basta. Nome sugerido: `tema_fazenda.ogg`.

---

## Por que a variação importa

Seis a nove arquivos por superfície parece exagero para um som de 200 milissegundos, mas
é o que separa passo que soa natural de passo que soa metralhadora. Três coisas fazem
esse trabalho juntas, e o sistema aplica as três:

1. Sorteio sem repetir o último clipe usado.
2. Variação aleatória de tom, de mais ou menos 8 por cento.
3. Variação aleatória de volume, de mais ou menos 2 decibéis.

Com nove clipes e essas variações, o ouvido para de reconhecer repetição.

## Arquivos

- Criar: `game/scripts/core/audio_manager.gd` (autoload)
- Criar: `game/scripts/resources/banco_de_passos.gd`
- Criar: `game/resources/audio/passos_padrao.tres`
- Criar: `game/scripts/player/passos_do_jogador.gd`
- Criar: `game/default_bus_layout.tres` (pelo editor)
- Modificar: `game/project.godot` (autoload novo, bus layout)
- Modificar: `game/scenes/player/player.tscn`
- Modificar: `game/scripts/core/event_bus.gd`
- Modificar: `game/docs/arquitetura.md`

---

## Tarefa 1: buses de áudio

Bus separado é o que permite ter controle de volume de música e de efeito separados
depois, sem refazer nada. Fazer agora custa dois minutos.

- [ ] **Passo 1.** Abra o editor do Godot, painel Audio, na parte de baixo da tela.
  Crie três buses novos, todos com saída para o Master:

- `Musica`
- `SFX`
- `Ambiente`

- [ ] **Passo 2.** Salve o layout em `res://default_bus_layout.tres`, que é o caminho
  que o Godot procura sozinho.

- [ ] **Passo 3.** Confirme que o `project.godot` ganhou a referência ao layout. Se não
  ganhou, adicione:

```ini
[audio]

buses/default_bus_layout="res://default_bus_layout.tres"
```

- [ ] **Passo 4.** Commit.

```bash
git add game/default_bus_layout.tres game/project.godot
git commit -m "feat(audio): cria os buses de musica, sfx e ambiente"
```

---

## Tarefa 2: o autoload AudioManager

- [ ] **Passo 1.** Crie `game/scripts/core/audio_manager.gd`:

```gdscript
extends Node

## Ponto único de reprodução de som do jogo.
##
## Efeito espacial sai de uma piscina de tocadores reaproveitados, em vez de um nó
## novo por som. Criar e destruir nó a cada passo geraria lixo constante numa ação
## que acontece duas vezes por segundo enquanto o jogador anda.

const TAMANHO_DA_PISCINA: int = 16
const DISTANCIA_MAXIMA_SFX: float = 30.0

var _piscina: Array[AudioStreamPlayer3D] = []
var _tocador_de_musica: AudioStreamPlayer
var _musica_atual: AudioStream = null

func _ready() -> void:
	for indice in TAMANHO_DA_PISCINA:
		var tocador := AudioStreamPlayer3D.new()
		tocador.bus = &"SFX"
		tocador.max_distance = DISTANCIA_MAXIMA_SFX
		add_child(tocador)
		_piscina.append(tocador)

	_tocador_de_musica = AudioStreamPlayer.new()
	_tocador_de_musica.bus = &"Musica"
	add_child(_tocador_de_musica)

## Toca um efeito posicionado no mundo. Ignora a chamada quando o fluxo é nulo, que
## é o caso normal enquanto os clipes de áudio ainda não chegaram.
func tocar_sfx(fluxo: AudioStream, posicao: Vector3, volume_db: float = 0.0, tom: float = 1.0) -> void:
	if fluxo == null:
		return
	var tocador: AudioStreamPlayer3D = _tocador_livre()
	if tocador == null:
		return
	tocador.stream = fluxo
	tocador.global_position = posicao
	tocador.volume_db = volume_db
	tocador.pitch_scale = tom
	tocador.play()

func tocar_musica(fluxo: AudioStream, duracao_do_fade: float = 1.5) -> void:
	if fluxo == null or fluxo == _musica_atual:
		return
	_musica_atual = fluxo
	if not _tocador_de_musica.playing:
		_tocador_de_musica.stream = fluxo
		_tocador_de_musica.volume_db = 0.0
		_tocador_de_musica.play()
		return
	var transicao := create_tween()
	transicao.tween_property(_tocador_de_musica, "volume_db", -40.0, duracao_do_fade)
	transicao.tween_callback(func() -> void:
		_tocador_de_musica.stream = fluxo
		_tocador_de_musica.play()
	)
	transicao.tween_property(_tocador_de_musica, "volume_db", 0.0, duracao_do_fade)

func parar_musica(duracao_do_fade: float = 1.5) -> void:
	_musica_atual = null
	if not _tocador_de_musica.playing:
		return
	var transicao := create_tween()
	transicao.tween_property(_tocador_de_musica, "volume_db", -40.0, duracao_do_fade)
	transicao.tween_callback(_tocador_de_musica.stop)

func _tocador_livre() -> AudioStreamPlayer3D:
	for tocador in _piscina:
		if not tocador.playing:
			return tocador
	return null
```

A guarda `if fluxo == null: return` é o coração do requisito de "pronto para receber".
Todo o resto do jogo pode chamar `AudioManager.tocar_sfx()` sem nunca checar se o clipe
existe, e enquanto não existir simplesmente não sai som, sem erro no console.

- [ ] **Passo 2.** Registre o autoload em `game/project.godot`, na seção `[autoload]`,
  depois do `EquipmentManager`:

```ini
AudioManager="*res://scripts/core/audio_manager.gd"
```

- [ ] **Passo 3.** Rode o jogo. O console tem que ficar limpo. Nada toca ainda, e isso
  é o esperado.

- [ ] **Passo 4.** Commit.

```bash
git add game/scripts/core/audio_manager.gd game/project.godot
git commit -m "feat(audio): adiciona o autoload AudioManager com piscina de tocadores"
```

---

## Tarefa 3: o banco de passos

- [ ] **Passo 1.** Crie `game/scripts/resources/banco_de_passos.gd`:

```gdscript
class_name BancoDePassos
extends Resource

## Mapeia superfície para os clipes de passo daquela superfície.
##
## As chaves do dicionário são os mesmos StringName que o post_import_kenney.gd
## grava como metadata nos corpos do cenário: grama, terra, pedra, madeira, metal
## e asfalto.

@export var clipes_por_superficie: Dictionary = {}

@export var superficie_padrao: StringName = &"grama"

@export_range(0.0, 0.5) var variacao_de_tom: float = 0.08
@export_range(0.0, 6.0) var variacao_de_volume_db: float = 2.0

var _ultimo_indice_por_superficie: Dictionary = {}

## Sorteia um clipe da superfície pedida, evitando repetir o último sorteado.
## Retorna null quando a superfície não tem clipe nenhum cadastrado, que é o caso
## normal enquanto os arquivos de áudio não chegaram.
func sortear(superficie: StringName) -> AudioStream:
	var clipes: Array = clipes_por_superficie.get(superficie, [])
	if clipes.is_empty():
		clipes = clipes_por_superficie.get(superficie_padrao, [])
	if clipes.is_empty():
		return null
	if clipes.size() == 1:
		return clipes[0]

	var ultimo: int = _ultimo_indice_por_superficie.get(superficie, -1)
	var indice: int = randi() % clipes.size()
	while indice == ultimo:
		indice = randi() % clipes.size()
	_ultimo_indice_por_superficie[superficie] = indice
	return clipes[indice]

func sortear_tom() -> float:
	return 1.0 + randf_range(-variacao_de_tom, variacao_de_tom)

func sortear_volume_db() -> float:
	return randf_range(-variacao_de_volume_db, variacao_de_volume_db)
```

- [ ] **Passo 2.** Crie a pasta `game/resources/audio/` e, pelo editor do Godot, crie um
  novo Resource do tipo `BancoDePassos` salvo como
  `game/resources/audio/passos_padrao.tres`. Deixe `clipes_por_superficie` vazio por
  enquanto. Quando os clipes chegarem, cada chave recebe um `Array[AudioStream]`.

- [ ] **Passo 3.** Commit.

```bash
git add game/scripts/resources/banco_de_passos.gd game/resources/audio/
git commit -m "feat(audio): adiciona o Resource de banco de passos por superficie"
```

---

## Tarefa 4: detectar a superfície sob o pé

- [ ] **Passo 1.** Abra `game/scenes/player/player.tscn` e adicione, como filho do nó
  raiz `Player`, um `RayCast3D` chamado `RaioSuperficie`.

Configure:

- `position` igual a `(0, 0.3, 0)`
- `target_position` igual a `(0, -0.8, 0)`
- `collision_mask` só na camada 1 (`mundo`)
- `enabled` ligado

O raio sai um pouco acima do pé e desce um pouco abaixo, para continuar acertando o chão
mesmo com o personagem em cima de uma peça levemente elevada.

- [ ] **Passo 2.** Crie `game/scripts/player/passos_do_jogador.gd`. Este é o script que
  vai no nó do jogador e cuida só de passo, sem entrar no `player.gd`, que já está
  grande:

```gdscript
extends Node

## Toca o som de passo do jogador no momento em que o pé encosta no chão.
##
## O disparo é amarrado à fase do clipe de animação, e não a um intervalo de tempo
## fixo nem à distância percorrida, porque só assim o som acompanha a animação
## quando ela muda de velocidade. As animações vêm dentro do .glb do pacote Kenney
## e não aceitam method track sem reimportar o modelo, então em vez de marcar o
## frame do contato dentro da animação, o script observa a posição do clipe e
## dispara quando ela cruza as fases configuradas abaixo.

@export var caminho_animation_player: NodePath = ^"../Personagem/AnimationPlayer"
@export var caminho_raio_superficie: NodePath = ^"../RaioSuperficie"
@export var banco: BancoDePassos

## Fração do clipe (de 0.0 a 1.0) em que cada pé encosta no chão. Dois valores por
## clipe porque o ciclo de caminhada tem dois passos. Ajuste olhando a animação
## rodando em câmera lenta no editor.
@export var fases_andando: Array[float] = [0.15, 0.65]
@export var fases_correndo: Array[float] = [0.10, 0.60]

@export var volume_andando_db: float = -6.0
@export var volume_correndo_db: float = -2.0

@onready var _animation_player: AnimationPlayer = get_node(caminho_animation_player)
@onready var _raio: RayCast3D = get_node(caminho_raio_superficie)

var _fase_anterior: float = 0.0
var _clipe_anterior: StringName = &""

func _physics_process(_delta: float) -> void:
	var clipe: StringName = _animation_player.current_animation
	var fases: Array[float] = _fases_do_clipe(clipe)
	if fases.is_empty():
		_fase_anterior = 0.0
		_clipe_anterior = clipe
		return

	var duracao: float = _animation_player.current_animation_length
	if duracao <= 0.0:
		return
	var fase_atual: float = _animation_player.current_animation_position / duracao

	if clipe != _clipe_anterior:
		_clipe_anterior = clipe
		_fase_anterior = fase_atual
		return

	for fase in fases:
		if _cruzou(_fase_anterior, fase_atual, fase):
			_tocar_passo(clipe)
			break

	_fase_anterior = fase_atual

func _fases_do_clipe(clipe: StringName) -> Array[float]:
	match clipe:
		&"walk":
			return fases_andando
		&"sprint":
			return fases_correndo
		_:
			return []

## Detecta se a fase alvo ficou para trás entre o quadro anterior e o atual,
## tratando o caso em que o clipe deu a volta e a posição voltou para perto de zero.
func _cruzou(anterior: float, atual: float, alvo: float) -> bool:
	if atual >= anterior:
		return anterior < alvo and atual >= alvo
	return anterior < alvo or atual >= alvo

func _tocar_passo(clipe: StringName) -> void:
	if banco == null:
		return
	var superficie: StringName = _superficie_sob_o_pe()
	var fluxo: AudioStream = banco.sortear(superficie)
	if fluxo == null:
		return
	var volume: float = volume_correndo_db if clipe == &"sprint" else volume_andando_db
	AudioManager.tocar_sfx(
		fluxo,
		get_parent().global_position,
		volume + banco.sortear_volume_db(),
		banco.sortear_tom()
	)

func _superficie_sob_o_pe() -> StringName:
	if not _raio.is_colliding():
		return banco.superficie_padrao
	var corpo: Object = _raio.get_collider()
	if corpo == null:
		return banco.superficie_padrao
	return corpo.get_meta(&"superficie", banco.superficie_padrao)
```

- [ ] **Passo 3.** Adicione ao `player.tscn` um nó `Node` filho da raiz chamado
  `PassosDoJogador`, com esse script anexado, e arraste
  `game/resources/audio/passos_padrao.tres` para a propriedade `banco` no Inspector.

- [ ] **Passo 4.** Verifique a detecção antes de existir som. Coloque um `print`
  temporário no fim de `_tocar_passo`, logo depois de calcular a superfície:

```gdscript
	print("passo em ", superficie)
```

Rode o jogo, ande pela grama, depois pela rua, depois pela ponte de madeira. O console
tem que imprimir `passo em grama`, `passo em asfalto`, `passo em madeira`, no ritmo da
caminhada, dois por ciclo. Apague o `print` depois de confirmar.

Se imprimir sempre `grama`, a metadata do plano 01 não chegou nos modelos ou a máscara
do raycast está errada. Se imprimir rápido demais ou em rajada, ajuste as fases.

- [ ] **Passo 5.** Ajuste `fases_andando` e `fases_correndo`. Abra a animação `walk` no
  editor, rode em câmera lenta e veja em que fração do clipe cada pé toca o chão. Os
  valores padrão são um chute razoável, não uma medição.

- [ ] **Passo 6.** Commit.

```bash
git add game/scripts/player/passos_do_jogador.gd game/scenes/player/player.tscn
git commit -m "feat(audio): toca passo por superficie no contato do pe com o chao"
```

---

## Tarefa 5: música de fundo

- [ ] **Passo 1.** Adicione um sinal novo em `game/scripts/core/event_bus.gd`, junto dos
  outros:

```gdscript
signal musica_solicitada(faixa: AudioStream)
```

Isso é o gancho para os planos 11 (estações) e 13 (clima) trocarem a trilha sem precisar
conhecer o `AudioManager`.

- [ ] **Passo 2.** No `AudioManager._ready()`, conecte o sinal:

```gdscript
	EventBus.musica_solicitada.connect(tocar_musica.bind(1.5))
```

- [ ] **Passo 3.** Adicione ao `AudioManager` uma faixa padrão que toca ao iniciar,
  carregada por caminho e tolerante a arquivo ausente:

```gdscript
const CAMINHO_MUSICA_PADRAO: String = "res://assets/audio/music/tema_fazenda.ogg"

func _tocar_musica_padrao() -> void:
	if not ResourceLoader.exists(CAMINHO_MUSICA_PADRAO):
		return
	tocar_musica(load(CAMINHO_MUSICA_PADRAO) as AudioStream, 0.0)
```

Chame `_tocar_musica_padrao()` no fim de `_ready()`. O `ResourceLoader.exists()` é o que
deixa o jogo rodar normalmente antes do arquivo existir.

- [ ] **Passo 4.** Rode o jogo sem o arquivo. Console limpo, nenhum som. Depois coloque
  qualquer `.ogg` como `game/assets/audio/music/tema_fazenda.ogg`, rode de novo, e a
  música tem que tocar.

- [ ] **Passo 5.** No Inspector do `.ogg` importado, marque `loop` como ligado. Sem isso
  a música toca uma vez e o jogo fica em silêncio.

- [ ] **Passo 6.** Commit.

```bash
git add game/scripts/core/audio_manager.gd game/scripts/core/event_bus.gd
git commit -m "feat(audio): toca musica de fundo e expoe sinal de troca de faixa"
```

---

## Tarefa 6: som das ferramentas

Barato de fazer agora que o encanamento existe, e melhora muito o vídeo.

- [ ] **Passo 1.** Em `game/scripts/resources/ferramenta.gd`, adicione o campo:

```gdscript
@export var som_de_uso: AudioStream
```

- [ ] **Passo 2.** Em `game/scripts/player/player.gd`, dentro do bloco que já trata o
  uso de ferramenta, logo depois de `if acao_teve_efeito:`, toque o som:

```gdscript
			AudioManager.tocar_sfx(ferramenta_equipada.som_de_uso, global_position)
```

Não precisa de guarda, o `AudioManager` já ignora fluxo nulo.

- [ ] **Passo 3.** Rode o jogo, are um quadrado. Sem clipe atribuído, nada acontece e o
  console fica limpo. Esse é o comportamento correto.

- [ ] **Passo 4.** Commit.

```bash
git add game/scripts/resources/ferramenta.gd game/scripts/player/player.gd
git commit -m "feat(audio): prepara som de uso nas ferramentas"
```

---

## Tarefa 7: documentar

- [ ] **Passo 1.** Em `game/docs/arquitetura.md`, adicione o `AudioManager` na lista de
  autoloads e o `BancoDePassos` na lista de Resources.

- [ ] **Passo 2.** Adicione ao mesmo arquivo uma seção curta de áudio explicando os três
  buses, a convenção de pasta dos passos e a regra de que fluxo nulo é ignorado de
  propósito.

- [ ] **Passo 3.** Em `game/docs/glossario.md`, adicione as linhas de banco de passos e
  superfície.

- [ ] **Passo 4.** Commit.

```bash
git add game/docs/
git commit -m "docs(audio): documenta o AudioManager e a convencao de sons de passo"
```

---

## Critério de pronto

- O jogo roda com zero arquivos de áudio no projeto, sem erro nem aviso no console.
- Com os clipes colocados, o passo toca no ritmo da caminhada, dois por ciclo, e muda de
  som ao trocar de superfície.
- Correr toca passo mais rápido e mais alto que andar, sem precisar de configuração
  extra, porque o disparo segue a animação.
- Passos seguidos não soam idênticos.
- A música toca em loop e o volume dela é controlável separado do efeito, pelos buses.

## Fora de escopo

- **Method track na animação.** Seria o jeito mais preciso de marcar o contato do pé,
  mas exige salvar as animações do `.glb` em arquivo separado no dock de importação e
  reimportar o pacote de personagens inteiro. A leitura de fase entrega precisão
  suficiente sem tocar na importação. Se um dia as animações forem substituídas por
  animações próprias, aí sim vale trocar.
- **Som de ambiente.** O bus `Ambiente` já existe, mas nada toca nele. Vento, pássaro e
  ruído de cidade ficam para depois, e vão bem com o MCP da Epidemic Sound se ele for
  configurado.
- **Menu de volume.** Os buses permitem, mas a tela de opções não existe ainda. Fica
  para quando houver menu de pausa (plano 04).
- **Som de passo de NPC e de inimigo.** O `passos_do_jogador.gd` é específico do jogador
  de propósito. Quando os planos 09 e 14 existirem, o script pode ser generalizado, mas
  generalizar antes de ter o segundo caso é adivinhação.
- **Música por estação e por clima.** O sinal `musica_solicitada` já está no lugar
  esperando. Quem faz os planos 11 e 13 emite ele.
