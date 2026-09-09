# Plano 01: Colisão de cenário

**Prioridade.** Junto com o plano 02, é o que precisa estar pronto antes do vídeo de
entrega.

**Objetivo:** o jogador para de atravessar árvore, prédio, cerca e pedra, passa a ter
chão de verdade sob os pés, e o cenário passa a saber de que material cada superfície é.

**Abordagem:** em vez de colocar colisão à mão nos mais de 300 nós do `playground.tscn`,
a colisão é gerada na importação, estendendo o `post_import_kenney.gd` que já roda em
todo `.glb` dos pacotes. Um modelo ganha colisão uma vez e todas as instâncias dele no
mapa ganham junto.

**Depende de:** nada. É o primeiro plano.

**Entrega para:** todos os outros planos, através do esquema de camadas de física, e o
plano 02, através da metadata de superfície.

## Contexto do que existe hoje

- `game/scripts/utils/post_import_kenney.gd` é um `EditorScenePostImport` que já roda em
  todo `.glb` dos pacotes Kenney, zerando o metálico e uniformizando rugosidade e filtro
  de textura. Todo `.glb.import` já aponta para ele em `import_script/path`.
- `game/scenes/levels/playground.tscn` tem o mapa montado com centenas de instâncias de
  `.glb`, mais dois `MeshInstance3D` chamados `Grama2` e `Grama3` que são malha solta,
  não instância de pacote.
- `game/scripts/player/player.gd` é um `CharacterBody3D` que **não aplica gravidade
  nenhuma**. `velocity.y` nunca é escrito. O jogador flutua em y igual a zero porque
  nada nunca o move para baixo. Não existe chão com colisão em lugar nenhum da cena.

Esse último ponto é importante: hoje o jogo parece ter chão, mas não tem. Este plano
resolve isso, e é por isso que o plano 02 depende dele (o raycast que descobre a
superfície sob o pé precisa acertar alguma coisa).

## Camadas de física

Este é o esquema para o jogo inteiro. Os planos seguintes referenciam estes nomes, então
ele precisa nascer certo aqui.

| Camada | Nome | Quem fica nela |
|---|---|---|
| 1 | `mundo` | cenário estático, chão, paredes, obstáculo |
| 2 | `jogador` | o corpo do jogador |
| 3 | `npc` | corpo dos NPCs |
| 4 | `inimigo` | corpo dos inimigos |
| 5 | `item_no_chao` | item dropado esperando ser pego (plano 03) |
| 6 | `area_interacao` | área que detecta o que dá para interagir (planos 06, 15, 17) |
| 7 | `hitbox_ataque` | área de dano de um golpe (planos 08, 09) |
| 8 | `solo_agricola` | a grade de solo arável (plano 06) |

Máscaras de quem colide com quem:

| Corpo | Camada | Máscara (com quem colide) |
|---|---|---|
| Cenário | `mundo` | nada (é estático) |
| Jogador | `jogador` | `mundo`, `npc`, `inimigo` |
| NPC | `npc` | `mundo`, `jogador` |
| Inimigo | `inimigo` | `mundo`, `jogador` |
| Item no chão | `item_no_chao` | `mundo` |
| Área de interação do jogador | vazia | `item_no_chao`, `npc`, `area_interacao` |
| Hitbox de ataque do jogador | `hitbox_ataque` | `inimigo` |
| Hitbox de ataque do inimigo | `hitbox_ataque` | `jogador` |

## Superfícies

Cada corpo estático do cenário carrega uma metadata `superficie`, com um `StringName`.
O plano 02 lê essa metadata para escolher o banco de sons de passo.

Valores possíveis, e mais nenhum: `&"grama"`, `&"terra"`, `&"pedra"`, `&"madeira"`,
`&"metal"`, `&"asfalto"`.

O mapeamento a partir do nome do arquivo do modelo é aproximado de propósito. É
placeholder honesto: acerta a maioria e é fácil de corrigir caso a caso depois.

## Arquivos

- Modificar: `game/project.godot` (nomes das camadas de física 3D)
- Modificar: `game/scripts/utils/post_import_kenney.gd`
- Modificar: `game/scenes/levels/playground.tscn`
- Modificar: `game/scenes/player/player.tscn`
- Modificar: `game/scripts/player/player.gd`
- Modificar: `game/docs/arquitetura.md` (seção nova de camadas de física)

---

## Tarefa 1: nomear as camadas de física

Nome de camada é só rótulo do editor, mas sem ele o Inspector mostra "Layer 1, Layer 2"
e fica impossível conferir se a máscara está certa. Fazer isso antes de tudo economiza
erro nas tarefas seguintes.

- [ ] **Passo 1.** Em `game/project.godot`, adicione uma seção `[layer_names]` (ou
  complete a existente):

```ini
[layer_names]

3d_physics/layer_1="mundo"
3d_physics/layer_2="jogador"
3d_physics/layer_3="npc"
3d_physics/layer_4="inimigo"
3d_physics/layer_5="item_no_chao"
3d_physics/layer_6="area_interacao"
3d_physics/layer_7="hitbox_ataque"
3d_physics/layer_8="solo_agricola"
```

- [ ] **Passo 2.** Abra o editor do Godot, selecione qualquer nó com colisão e confira
  no Inspector que os nomes aparecem no lugar de "Layer 1". Feche o editor.

- [ ] **Passo 3.** Commit.

```bash
git add game/project.godot
git commit -m "chore(fisica): nomeia as camadas de colisao do jogo"
```

---

## Tarefa 2: gerar colisão na importação

- [ ] **Passo 1.** Substitua o conteúdo de `game/scripts/utils/post_import_kenney.gd`
  pelo abaixo. O que já existia (normalização de material) continua igual, o que entra é
  a geração de colisão e a marcação de superfície.

```gdscript
@tool
extends EditorScenePostImport

## Normaliza os materiais dos pacotes de modelos da Kenney na importação e gera a
## colisão estática do cenário.
##
## Os modelos são exportados com metallicFactor 1.0 no glTF. Com esse valor o
## Godot trata a cor do albedo como cor de reflexo e zera a componente difusa,
## deixando tudo escuro. Como esses materiais tiram a cor inteira do albedo, o
## componente metálico não acrescenta nada e é zerado aqui.
##
## A colisão é gerada aqui, e não à mão na cena, porque o playground instancia
## centenas de cópias dos mesmos modelos. Gerando na importação, um modelo
## corrigido conserta todas as instâncias dele de uma vez.

const RUGOSIDADE_PADRAO: float = 0.9

const CAMADA_MUNDO: int = 1

## Modelos cujo nome contém um destes trechos não recebem colisão. São decoração
## que o jogador precisa poder atravessar, senão andar pelo mapa vira um labirinto
## de tufos de grama invisíveis.
const TRECHOS_SEM_COLISAO: Array[String] = [
	"grass", "flower", "mushroom", "plant", "crops_",
	"mulch", "mound", "mark_", "mark-",
]

## Mapeamento de trecho do nome do arquivo para superfície. A primeira entrada que
## casar vence, então a ordem importa: "path_stone" precisa vir antes de "path".
const SUPERFICIE_POR_TRECHO: Array = [
	["road", &"asfalto"],
	["driveway", &"asfalto"],
	["sidewalk", &"pedra"],
	["path_stone", &"pedra"],
	["stone", &"pedra"],
	["cliff", &"pedra"],
	["rock", &"pedra"],
	["bridge", &"madeira"],
	["log_", &"madeira"],
	["plank", &"madeira"],
	["fence", &"madeira"],
	["crate", &"madeira"],
	["tree", &"madeira"],
	["building", &"metal"],
	["detail_", &"metal"],
	["tank", &"metal"],
	["silo", &"metal"],
	["ground_path", &"terra"],
	["dirt", &"terra"],
	["platform_grass", &"grama"],
	["ground_grass", &"grama"],
]

const SUPERFICIE_PADRAO: StringName = &"grama"

func _post_import(cena: Node) -> Object:
	var nome_do_arquivo: String = get_source_file().get_file().to_lower()
	_normalizar_materiais(cena)
	if not _deve_ter_colisao(nome_do_arquivo):
		return cena
	var superficie: StringName = _superficie_do_nome(nome_do_arquivo)
	_gerar_colisao(cena, cena, superficie)
	return cena

func _deve_ter_colisao(nome_do_arquivo: String) -> bool:
	for trecho in TRECHOS_SEM_COLISAO:
		if nome_do_arquivo.contains(trecho):
			return false
	return true

func _superficie_do_nome(nome_do_arquivo: String) -> StringName:
	for par in SUPERFICIE_POR_TRECHO:
		if nome_do_arquivo.contains(par[0] as String):
			return par[1] as StringName
	return SUPERFICIE_PADRAO

func _gerar_colisao(no: Node, raiz: Node, superficie: StringName) -> void:
	if no is MeshInstance3D:
		var instancia := no as MeshInstance3D
		var malha: Mesh = instancia.mesh
		if malha != null and malha.get_surface_count() > 0:
			var corpo := StaticBody3D.new()
			corpo.name = "Colisao"
			corpo.collision_layer = CAMADA_MUNDO
			corpo.collision_mask = 0
			corpo.set_meta(&"superficie", superficie)

			var forma := CollisionShape3D.new()
			forma.name = "FormaColisao"
			forma.shape = malha.create_trimesh_shape()

			corpo.add_child(forma)
			instancia.add_child(corpo)
			corpo.owner = raiz
			forma.owner = raiz

	for filho in no.get_children():
		_gerar_colisao(filho, raiz, superficie)

func _normalizar_materiais(no: Node) -> void:
	if no is MeshInstance3D:
		var malha: Mesh = (no as MeshInstance3D).mesh
		if malha != null:
			for indice in malha.get_surface_count():
				var material: Material = malha.surface_get_material(indice)
				if material is BaseMaterial3D:
					var base := material as BaseMaterial3D
					base.metallic = 0.0
					base.roughness = RUGOSIDADE_PADRAO
					base.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	for filho in no.get_children():
		_normalizar_materiais(filho)
```

Duas coisas que não são óbvias e quebram silenciosamente se você mudar:

O `owner` precisa ser a raiz da cena importada. Nó sem `owner` correto não é salvo no
`.scn` gerado, então a colisão sumiria sem nenhum erro aparecer.

`collision_mask = 0` no cenário é de propósito. O cenário é estático e não precisa
detectar ninguém, quem detecta é o jogador. Deixar máscara cheia num corpo estático só
gasta processamento.

- [ ] **Passo 2.** Force a reimportação de todos os pacotes. O Godot só reimporta quando
  o arquivo de origem muda, e o `.glb` não mudou, só o script. Apagar o cache resolve:

```bash
rm -rf game/.godot/imported
GODOT=/var/lib/flatpak/exports/bin/org.godotengine.Godot
"$GODOT" --headless --path game --import
```

Isso reimporta o projeto inteiro e demora alguns minutos. É esperado.

- [ ] **Passo 3.** Verifique que a colisão foi gerada mesmo, sem abrir o editor:

```bash
cat > /tmp/verifica_colisao.gd <<'EOF'
extends SceneTree

func _init() -> void:
	for caminho in [
		"res://assets/models/kenney_nature_kit/tree_oak.glb",
		"res://assets/models/kenney_city_kit_suburban/building_type_a.glb",
		"res://assets/models/kenney_nature_kit/grass_large.glb",
	]:
		var cena: PackedScene = load(caminho)
		var raiz: Node = cena.instantiate()
		var corpos: Array[Node] = raiz.find_children("*", "StaticBody3D", true, false)
		var superficie: String = "nenhuma"
		if corpos.size() > 0:
			superficie = str(corpos[0].get_meta(&"superficie", "sem meta"))
		print(caminho.get_file(), " -> corpos: ", corpos.size(), ", superficie: ", superficie)
		raiz.free()
	quit()
EOF
"$GODOT" --headless --path game --script /tmp/verifica_colisao.gd
```

Esperado:

```
tree_oak.glb -> corpos: 1, superficie: madeira
building_type_a.glb -> corpos: 1, superficie: metal
grass_large.glb -> corpos: 0, superficie: nenhuma
```

Se `tree_oak` vier com 0 corpos, o `owner` não foi setado ou o cache não foi apagado. Se
`grass_large` vier com 1 corpo, a lista de exclusão não pegou o nome.

- [ ] **Passo 4.** Commit.

```bash
git add game/scripts/utils/post_import_kenney.gd
git commit -m "feat(fisica): gera colisao e marca superficie na importacao dos modelos"
```

---

## Tarefa 3: chão do playground

Os modelos de chão instanciados já ganharam colisão na tarefa 2, mas o playground também
tem malha solta (`Grama2`, `Grama3`) que não passa pelo importador, e buraco entre as
peças. Sem uma rede de segurança, o jogador cai para sempre no primeiro buraco.

- [ ] **Passo 1.** Abra `game/scenes/levels/playground.tscn` no editor do Godot.

- [ ] **Passo 2.** Adicione, como filho direto da raiz `Playground`, um `StaticBody3D`
  chamado `ChaoBase`, com um `CollisionShape3D` filho chamado `FormaChao` usando um
  `WorldBoundaryShape3D`.

Configure o `ChaoBase`:

- `transform.origin.y` igual a `-0.6`
- `collision_layer` só a camada 1 (`mundo`)
- `collision_mask` igual a 0
- em Node, aba Metadata, adicione `superficie` do tipo StringName com valor `grama`

O `WorldBoundaryShape3D` é um plano infinito. Ele fica logo abaixo do chão real para
funcionar como rede de segurança: onde existe peça de chão com colisão, o jogador pisa na
peça e a superfície lida é a da peça; onde não existe peça, ele pisa no plano e a
superfície é grama. Colocar o plano em y igual a zero, coincidindo com as peças, deixaria
o raycast do plano 02 instável, sem saber qual dos dois acertou primeiro.

- [ ] **Passo 3.** Salve a cena, rode o jogo, ande até uma borda do mapa. O jogador não
  pode cair. Se cair, o `ChaoBase` está na camada errada ou o jogador ainda não tem
  máscara (isso é a tarefa 4, então por enquanto ele nem cai).

- [ ] **Passo 4.** Commit.

```bash
git add game/scenes/levels/playground.tscn
git commit -m "feat(playground): adiciona chao base com plano de colisao"
```

---

## Tarefa 4: gravidade e colisão do jogador

- [ ] **Passo 1.** Abra `game/scenes/player/player.tscn`. O nó raiz `Player` é um
  `CharacterBody3D`. Confira se já existe um `CollisionShape3D` filho. Se não existir,
  adicione um chamado `FormaColisao` com uma `CapsuleShape3D`, raio `0.3`, altura `1.6`,
  e desloque a forma em y igual a `0.8` para a base da cápsula ficar no pé, não no meio
  do corpo.

- [ ] **Passo 2.** No mesmo nó `Player`, configure `collision_layer` só na camada 2
  (`jogador`) e `collision_mask` nas camadas 1, 3 e 4 (`mundo`, `npc`, `inimigo`).

- [ ] **Passo 3.** Em `game/scripts/player/player.gd`, adicione a constante de gravidade
  junto das outras exportações do topo:

```gdscript
@export var gravidade: float = 24.0
```

- [ ] **Passo 4.** Ainda em `player.gd`, dentro de `_physics_process`, aplique a
  gravidade logo antes da chamada de `move_and_slide()`, que hoje é a última linha da
  função:

```gdscript
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravidade * delta

	move_and_slide()
```

O valor 24.0 é bem acima dos 9.8 do mundo real, de propósito. Câmera de cima em jogo de
fazenda fica com sensação pesada e travada com gravidade realista; o padrão do gênero é
exagerar. Ajuste depois se o dash ficar estranho.

- [ ] **Passo 5.** Rode o jogo. Três coisas para conferir, nesta ordem:

1. O jogador fica parado no chão, não afunda e não flutua.
2. Andando contra uma árvore ou um prédio, ele para. Não atravessa.
3. Andando contra um tufo de grama, ele passa por cima. Não trava.

- [ ] **Passo 6.** Commit.

```bash
git add game/scenes/player/player.tscn game/scripts/player/player.gd
git commit -m "feat(player): aplica gravidade e liga o jogador as camadas de colisao"
```

---

## Tarefa 5: ajustar a lista de exclusão andando pelo mapa

O mapeamento de nome para superfície e a lista de exclusão são chutes informados. Esta
tarefa é a passada de correção, e ela precisa ser feita andando pelo jogo, não lendo
código.

- [ ] **Passo 1.** Rode o jogo e ande por todo o mapa, encostando em tudo: as árvores,
  os prédios, as cercas, a ponte, as pedras, a fogueira, a tenda, a canoa, o
  estacionamento.

- [ ] **Passo 2.** Anote os dois tipos de erro:

- Coisa que deveria bloquear e não bloqueia. Provavelmente o nome caiu na
  `TRECHOS_SEM_COLISAO` sem querer.
- Coisa que bloqueia e não deveria, ou bloqueia numa área maior que o desenho. Decoração
  pequena que precisa entrar na lista de exclusão.

- [ ] **Passo 3.** Corrija a `TRECHOS_SEM_COLISAO` no `post_import_kenney.gd`, apague
  `game/.godot/imported`, reimporte, e ande de novo. Repita até o mapa ficar bom.

- [ ] **Passo 4.** Commit.

```bash
git add game/scripts/utils/post_import_kenney.gd
git commit -m "fix(fisica): ajusta a lista de modelos sem colisao"
```

---

## Tarefa 6: documentar

- [ ] **Passo 1.** Em `game/docs/arquitetura.md`, adicione uma seção nova no fim:

```markdown
## Camadas de física

O jogo usa 8 camadas de colisão 3D, nomeadas no `project.godot`:

| Camada | Nome | Quem fica nela |
|---|---|---|
| 1 | `mundo` | cenário estático, chão, paredes, obstáculo |
| 2 | `jogador` | o corpo do jogador |
| 3 | `npc` | corpo dos NPCs |
| 4 | `inimigo` | corpo dos inimigos |
| 5 | `item_no_chao` | item dropado esperando ser pego |
| 6 | `area_interacao` | área que detecta o que dá para interagir |
| 7 | `hitbox_ataque` | área de dano de um golpe |
| 8 | `solo_agricola` | a grade de solo arável |

A colisão do cenário não é montada à mão nas cenas. Ela é gerada na importação pelo
`scripts/utils/post_import_kenney.gd`, que cria um `StaticBody3D` com forma trimesh
para cada malha do modelo e marca nele uma metadata `superficie`, usada pelo sistema de
áudio para escolher o som de passo. Modelos de decoração atravessável ficam de fora por
uma lista de trechos de nome no próprio script.
```

- [ ] **Passo 2.** Em `game/docs/pipeline_de_assets.md`, na parte que fala do
  `import_script/path`, acrescente que o script agora também gera colisão, para quem
  extrair pacote novo saber o que esperar.

- [ ] **Passo 3.** Commit.

```bash
git add game/docs/arquitetura.md game/docs/pipeline_de_assets.md
git commit -m "docs(fisica): documenta as camadas de colisao e a geracao na importacao"
```

---

## Critério de pronto

- O jogador não atravessa árvore, prédio, cerca nem pedra.
- O jogador atravessa grama e flor sem travar.
- O jogador não cai do mapa em nenhuma borda nem buraco.
- O script de verificação da tarefa 2 imprime superfície certa para árvore, prédio e
  grama.
- O console do Godot não mostra erro nem aviso novo ao rodar.

## Fora de escopo

- **Colisão precisa por modelo.** Trimesh gerado a partir da malha visual é grosseiro
  para objeto complexo, e caro se algum dia esses objetos passarem a se mover. Para
  cenário estático é a escolha certa. Se algum objeto específico ficar ruim, o conserto
  é uma forma feita à mão naquele modelo, não trocar a estratégia inteira.
- **Colisão de personagem contra personagem.** As camadas `npc` e `inimigo` já estão
  reservadas e na máscara do jogador, mas nenhum NPC nem inimigo existe ainda. Quem
  implementa os planos 09 e 14 usa o que está definido aqui.
- **Rampa, escada e altura.** O mapa é plano. Subir e descer nível fica para quando
  existir terreno com altura.
- **Pulo.** O jogador ganhou gravidade, mas não ganhou pulo. O botão de espaço fica com
  o dash, conforme `equipe/controles.md`.
- **Colisão da grade de solo.** A camada 8 (`solo_agricola`) está reservada mas não é
  usada aqui. Quem implementa o plano 06 decide se a grade precisa de corpo próprio.
