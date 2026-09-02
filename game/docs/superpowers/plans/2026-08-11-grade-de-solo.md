# Grade de Solo Arável da Fazenda — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dar ao jogador uma enxada e um regador equipáveis que transformam quadrados do piso da fazenda em solo arado (seco/molhado), com as fileiras horizontais se unindo visualmente via autotile.

**Architecture:** Um `GridMap3D` (`GradeSolo`) sobrepõe o `PlaneMesh` de grama existente em `playground.tscn`, com uma `MeshLibrary` de 8 variantes de solo. Estado do grid vive em memória (`Dictionary`) num script anexado ao `GridMap`. Um autoload `EquipmentManager` controla qual ferramenta está equipada; `player.gd` consulta esse autoload ao apertar o botão de atacar e decide entre golpear ou usar a ferramenta no quadrado à frente.

**Tech Stack:** Godot 4.7 (GL Compatibility), GDScript. Sem framework de testes no projeto (nenhuma feature anterior — dash, combo de ataque — tem testes automatizados). Este plano adapta "test-then-implement" à realidade do projeto: para lógica pura (ciclagem de ferramenta, seleção de variante do grid) usa um autoteste temporário com `assert()`/`print()` no `_ready()`, rodado via `mcp__godot__run_project` + `mcp__godot__get_debug_output` e removido depois de confirmado; para peças visuais/de input (HUD, GridMap, indicador, binds) usa checklist manual de jogo, porque não têm lógica pura isolável para automatizar.

## Global Constraints

- Identificadores, `class_name` e nomes de arquivo de **autoloads** em inglês (`EquipmentManager`); tudo o resto (Resources, scripts de cena, métodos, variáveis, nomes de nó, ações de input) em português — ver `docs/dev/specs/2026-08-11-grade-de-solo-design.md` para o raciocínio completo por categoria.
- Sinais de autoload (inclusive `EventBus`) em inglês, verbo no passado: `tool_equipped`, `tile_plowed`, `tile_watered`.
- Texturas usadas em superfícies 3D precisam de `detect_3d/compress_to=0` no `.import`, senão o Godot recomprime pra VRAM e borra a paleta de 16x16 (mesma regra já documentada em `docs/convencoes.md` pro `colormap.png` da Kenney).
- Nenhuma mudança em `attack-melee-*`/combo de soco além de checar `EquipmentManager.ferramenta_atual()` antes de disparar (fora de escopo do design).

---

## Task 1: Resource `Ferramenta` e itens equipáveis

**Files:**
- Create: `scripts/resources/ferramenta.gd`
- Create: `resources/items/enxada.tres`
- Create: `resources/items/regador.tres`

**Interfaces:**
- Produces: `class_name Ferramenta extends Item`, campo `id_acao: StringName`. Consumido pelo `EquipmentManager` (Task 2) e por `player.gd` (Task 10).

- [ ] **Step 1: Criar o script do Resource**

`scripts/resources/ferramenta.gd`:

```gdscript
class_name Ferramenta
extends Item

@export var id_acao: StringName = &""
```

- [ ] **Step 2: Criar `enxada.tres`**

`resources/items/enxada.tres`:

```
[gd_resource type="Resource" script_class="Ferramenta" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ferramenta.gd" id="1"]

[resource]
script = ExtResource("1")
nome = "Enxada"
id_acao = &"enxada"
```

- [ ] **Step 3: Criar `regador.tres`**

`resources/items/regador.tres`:

```
[gd_resource type="Resource" script_class="Ferramenta" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ferramenta.gd" id="1"]

[resource]
script = ExtResource("1")
nome = "Regador"
id_acao = &"regador"
```

- [ ] **Step 4: Verificar**

Abra os dois `.tres` no editor do Godot (FileSystem dock → duplo clique) e confirme no Inspector que `Nome` e `Id Acao` aparecem preenchidos como acima, sem erro de script no console.

- [ ] **Step 5: Commit**

```bash
git add scripts/resources/ferramenta.gd resources/items/enxada.tres resources/items/regador.tres
git commit -m "feat(farming): adiciona resource Ferramenta e itens enxada/regador"
```

---

## Task 2: Autoload `EquipmentManager`

**Files:**
- Create: `scripts/core/equipment_manager.gd`
- Modify: `project.godot:18-25` (seção `[autoload]`)

**Interfaces:**
- Consumes: `Ferramenta` (Task 1), `resources/items/enxada.tres`, `resources/items/regador.tres`.
- Produces: autoload global `EquipmentManager` com `signal tool_equipped(ferramenta: Ferramenta)`, `var indice_atual: int` (`-1` = socos), `func equipar_indice(indice: int) -> void`, `func ciclar(direcao: int) -> void`, `func ferramenta_atual() -> Ferramenta`. Consumido por Task 4 (HUD), Task 9 (indicador) e Task 10 (`player.gd`).

- [ ] **Step 1: Criar o autoload com um autoteste temporário**

`scripts/core/equipment_manager.gd`:

```gdscript
extends Node

signal tool_equipped(ferramenta: Ferramenta)

@export var ferramentas: Array[Ferramenta] = [
	preload("res://resources/items/enxada.tres"),
	preload("res://resources/items/regador.tres"),
]
var indice_atual: int = -1

func equipar_indice(indice: int) -> void:
	if indice < -1 or indice >= ferramentas.size():
		return
	indice_atual = indice
	tool_equipped.emit(ferramenta_atual())

func ciclar(direcao: int) -> void:
	var total: int = ferramentas.size() + 1
	var posicao: int = indice_atual + 1
	posicao = (posicao + direcao + total) % total
	equipar_indice(posicao - 1)

func ferramenta_atual() -> Ferramenta:
	return ferramentas[indice_atual] if indice_atual >= 0 else null

func _ready() -> void:
	assert(indice_atual == -1, "deveria começar em socos")
	assert(ferramenta_atual() == null, "socos não tem Ferramenta")
	equipar_indice(0)
	assert(ferramenta_atual().id_acao == &"enxada", "indice 0 deveria ser a enxada")
	ciclar(1)
	assert(ferramenta_atual().id_acao == &"regador", "ciclar(1) da enxada deveria ir pro regador")
	ciclar(1)
	assert(ferramenta_atual() == null, "ciclar(1) do regador deveria voltar pra socos")
	ciclar(-1)
	assert(ferramenta_atual().id_acao == &"regador", "ciclar(-1) de socos deveria ir pro regador (wrap)")
	equipar_indice(5)
	assert(ferramenta_atual().id_acao == &"regador", "indice fora do range deveria ser ignorado")
	print("EquipmentManager: autoteste OK")
```

- [ ] **Step 2: Registrar o autoload**

Em `project.godot`, dentro da seção `[autoload]` (depois da linha `SaveManager="*res://scripts/core/save_manager.gd"`):

```
EquipmentManager="*res://scripts/core/equipment_manager.gd"
```

- [ ] **Step 3: Rodar e verificar o autoteste**

Use `mcp__godot__run_project` pra rodar a cena principal, depois `mcp__godot__get_debug_output` pra ler o console. Espera-se a linha `EquipmentManager: autoteste OK` e nenhum erro de `assert` (que apareceria como `Assertion failed` no output). Pare com `mcp__godot__stop_project`.

- [ ] **Step 4: Remover o autoteste**

Apague o método `_ready()` inteiro de `equipment_manager.gd` (o autoteste já cumpriu seu papel — não faz parte do comportamento em produção). Rode `mcp__godot__run_project` de novo e confirme no `get_debug_output` que não há nenhum erro relacionado a `EquipmentManager`.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/equipment_manager.gd project.godot
git commit -m "feat(farming): adiciona autoload EquipmentManager"
```

---

## Task 3: Ações de input e `InputManager`

**Files:**
- Modify: `project.godot:87-92` (depois da ação `atacar`, antes de `[physics]`)
- Modify: `scripts/core/input_manager.gd`

**Interfaces:**
- Produces: ações `equipar_1`, `equipar_2`, `equipar_3`, `ferramenta_proxima`, `ferramenta_anterior`; métodos `InputManager.equipar_1_pressionado()`, `equipar_2_pressionado()`, `equipar_3_pressionado()`, `proxima_ferramenta_pressionada()`, `ferramenta_anterior_pressionada()`, todos `-> bool`. Consumido por Task 10 (`player.gd`).

- [ ] **Step 1: Adicionar as 5 ações em `project.godot`**

Logo depois do fechamento da ação `atacar` (linha 92, `}`) e antes de `[physics]`:

```
equipar_1={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":16,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":49,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
equipar_2={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":16,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":50,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
equipar_3={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":16,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":51,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
ferramenta_proxima={
"deadzone": 0.5,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":5,"canceled":false,"pressed":false,"double_click":false,"script":null)
, Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":5,"axis_value":1.0,"script":null)
]
}
ferramenta_anterior={
"deadzone": 0.5,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":4,"canceled":false,"pressed":false,"double_click":false,"script":null)
, Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":4,"axis_value":1.0,"script":null)
]
}
```

Notas: `physical_keycode` 49/50/51 são as teclas `1`/`2`/`3` (ASCII). `button_index` 5/4 do `InputEventMouseButton` são `MOUSE_BUTTON_WHEEL_DOWN`/`MOUSE_BUTTON_WHEEL_UP`. `axis` 5/4 do `InputEventJoypadMotion` são `JOY_AXIS_TRIGGER_RIGHT`/`JOY_AXIS_TRIGGER_LEFT` (R2/L2).

- [ ] **Step 2: Adicionar os métodos em `input_manager.gd`**

No fim do arquivo, depois de `atacar_pressionado()`:

```gdscript
func equipar_1_pressionado() -> bool:
	return Input.is_action_just_pressed("equipar_1")

func equipar_2_pressionado() -> bool:
	return Input.is_action_just_pressed("equipar_2")

func equipar_3_pressionado() -> bool:
	return Input.is_action_just_pressed("equipar_3")

func proxima_ferramenta_pressionada() -> bool:
	return Input.is_action_just_pressed("ferramenta_proxima")

func ferramenta_anterior_pressionada() -> bool:
	return Input.is_action_just_pressed("ferramenta_anterior")
```

- [ ] **Step 3: Verificar no editor**

Abra **Projeto → Configurações do Projeto → Mapa de Entrada** e confirme que as 5 ações novas aparecem com os binds certos (tecla 1/2/3, roda do mouse pra cima/baixo, e — se tiver um gamepad conectado pra testar — L2/R2). Sem gamepad físico, essa parte fica só validada visualmente na configuração; o teste funcional das teclas e do scroll acontece no checklist manual da Task 10.

- [ ] **Step 4: Commit**

```bash
git add project.godot scripts/core/input_manager.gd
git commit -m "feat(farming): adiciona acoes de input pra equipar e ciclar ferramenta"
```

---

## Task 4: HUD da ferramenta equipada

**Files:**
- Create: `scenes/ui/hud_ferramenta.tscn`
- Create: `scripts/ui/hud_ferramenta.gd`
- Modify: `scenes/levels/playground.tscn`

**Interfaces:**
- Consumes: `EquipmentManager.tool_equipped` (Task 2), `EquipmentManager.ferramenta_atual()`.

- [ ] **Step 1: Criar o script do HUD**

`scripts/ui/hud_ferramenta.gd`:

```gdscript
extends Control

@onready var rotulo: Label = $RotuloFerramenta

func _ready() -> void:
	EquipmentManager.tool_equipped.connect(_ao_trocar_ferramenta)
	_ao_trocar_ferramenta(EquipmentManager.ferramenta_atual())

func _ao_trocar_ferramenta(ferramenta: Ferramenta) -> void:
	rotulo.text = ferramenta.nome if ferramenta else "Socos"
```

- [ ] **Step 2: Criar a cena do HUD**

`scenes/ui/hud_ferramenta.tscn`:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ui/hud_ferramenta.gd" id="1_script"]

[node name="HudFerramenta" type="Control"]
layout_mode = 3
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -220.0
offset_top = 16.0
offset_right = -16.0
offset_bottom = 56.0
grow_horizontal = 0
script = ExtResource("1_script")

[node name="RotuloFerramenta" type="Label" parent="."]
layout_mode = 2
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
horizontal_alignment = 2
text = "Socos"
```

- [ ] **Step 3: Instanciar no playground**

Em `scenes/levels/playground.tscn`, adicione o `ext_resource` do HUD e dois nós novos: um `CanvasLayer` na raiz, com a instância do HUD dentro. No topo do arquivo, junto aos outros `ext_resource`:

```
[ext_resource type="PackedScene" path="res://scenes/ui/hud_ferramenta.tscn" id="5_hud"]
```

E no fim do arquivo, depois do nó `Luz`:

```
[node name="InterfaceHUD" type="CanvasLayer" parent="."]

[node name="HudFerramenta" parent="InterfaceHUD" instance=ExtResource("5_hud")]
```

- [ ] **Step 4: Verificar**

Rode a cena (`mcp__godot__run_project`). O texto `"Socos"` deve aparecer no canto superior direito assim que o jogo inicia. Pare com `mcp__godot__stop_project`.

- [ ] **Step 5: Commit**

```bash
git add scenes/ui/hud_ferramenta.tscn scripts/ui/hud_ferramenta.gd scenes/levels/playground.tscn
git commit -m "feat(farming): adiciona HUD mostrando a ferramenta equipada"
```

---

## Task 5: Ajustar import das texturas de solo pra uso em 3D

**Files:**
- Modify (gerados pelo Godot, depois editados): `assets/textures/kenney_tiny_farm/soil_plow_dry_left.png.import` e os outros 7 arquivos irmãos.

**Interfaces:**
- Produces: os 8 `.png` de `assets/textures/kenney_tiny_farm/` importados com `compress/mode=0` (Lossless) e `detect_3d/compress_to=0`, prontos pra Task 6.

- [ ] **Step 1: Forçar o Godot a gerar os `.import` padrão**

Os 8 PNGs foram só copiados pro projeto (nunca abertos no editor), então ainda não têm `.import`. Rode `mcp__godot__run_project` uma vez — isso faz o Godot escanear e importar tudo que está em `assets/` com as configurações padrão — e depois `mcp__godot__stop_project`.

- [ ] **Step 2: Confirmar que os 8 `.import` existem**

```bash
ls assets/textures/kenney_tiny_farm/*.png.import | wc -l
```

Esperado: `8`.

- [ ] **Step 3: Corrigir `detect_3d/compress_to` nos 8 arquivos**

```bash
grep -l "detect_3d/compress_to=1" assets/textures/kenney_tiny_farm/*.png.import | \
  xargs sed -i 's/detect_3d\/compress_to=1/detect_3d\/compress_to=0/'
```

- [ ] **Step 4: Confirmar `compress/mode=0` (Lossless) em todos**

```bash
grep -L "compress/mode=0" assets/textures/kenney_tiny_farm/*.png.import
```

Esperado: nenhuma saída (se algum arquivo aparecer, ele não está em Lossless — abra o `.import` e mude `compress/mode` pro valor que faltar pra `0`).

- [ ] **Step 5: Forçar reimportação com as novas configurações**

Rode `mcp__godot__run_project` de novo — o Godot detecta que os `.import` mudaram e reimporta os 8 arquivos com as configurações corrigidas antes de rodar a cena. Pare com `mcp__godot__stop_project`.

- [ ] **Step 6: Commit**

```bash
git add assets/textures/kenney_tiny_farm/*.png.import
git commit -m "fix(farming): configura import lossless sem compressao VRAM pras texturas de solo"
```

---

## Task 6: `MeshLibrary` do solo

**Files:**
- Create: `scenes/farming/fonte_mesh_library_solo.tscn`
- Create: `resources/farming/mesh_library_solo.tres`

**Interfaces:**
- Produces: `resources/farming/mesh_library_solo.tres`, uma `MeshLibrary` com 8 itens nomeados `soil_plow_dry_single`, `soil_plow_dry_left`, `soil_plow_dry_middle`, `soil_plow_dry_right`, `soil_plow_watered_single`, `soil_plow_watered_left`, `soil_plow_watered_middle`, `soil_plow_watered_right`. Consumido por Task 7.

- [ ] **Step 1: Criar a cena-fonte com os 8 planos**

`scenes/farming/fonte_mesh_library_solo.tscn` — um `Node3D` raiz com 8 filhos `MeshInstance3D`, cada um com seu **próprio** `PlaneMesh` de `size = Vector2(1, 1)`. O material (`texture_filter = 0` é `Nearest` no enum `BaseMaterial3D.TextureFilter`, `albedo_texture` apontando pra textura correspondente) é atribuído **direto no `PlaneMesh`** (`material = SubResource(...)`), não como `surface_material_override` no `MeshInstance3D` — a ferramenta `mcp__godot__export_mesh_library` (usada no Step 2) lê só `MeshInstance3D.mesh` ao gerar cada item da `MeshLibrary` e ignora qualquer `surface_material_override`, então o material precisa estar embutido no mesh em si, não numa sobreposição por instância. Isso também significa que cada um dos 8 planos precisa de um `PlaneMesh` só seu (não dá pra compartilhar um `PlaneMesh` entre vários nós com materiais diferentes, já que o material agora mora no mesh). O nome de cada nó vira o nome do item na `MeshLibrary`:

```
[gd_scene load_steps=25 format=3]

[ext_resource type="Texture2D" path="res://assets/textures/kenney_tiny_farm/soil_plow_dry_single.png" id="1_dry_single"]
[ext_resource type="Texture2D" path="res://assets/textures/kenney_tiny_farm/soil_plow_dry_left.png" id="2_dry_left"]
[ext_resource type="Texture2D" path="res://assets/textures/kenney_tiny_farm/soil_plow_dry_middle.png" id="3_dry_middle"]
[ext_resource type="Texture2D" path="res://assets/textures/kenney_tiny_farm/soil_plow_dry_right.png" id="4_dry_right"]
[ext_resource type="Texture2D" path="res://assets/textures/kenney_tiny_farm/soil_plow_watered_single.png" id="5_watered_single"]
[ext_resource type="Texture2D" path="res://assets/textures/kenney_tiny_farm/soil_plow_watered_left.png" id="6_watered_left"]
[ext_resource type="Texture2D" path="res://assets/textures/kenney_tiny_farm/soil_plow_watered_middle.png" id="7_watered_middle"]
[ext_resource type="Texture2D" path="res://assets/textures/kenney_tiny_farm/soil_plow_watered_right.png" id="8_watered_right"]

[sub_resource type="StandardMaterial3D" id="Mat_dry_single"]
texture_filter = 0
albedo_texture = ExtResource("1_dry_single")

[sub_resource type="StandardMaterial3D" id="Mat_dry_left"]
texture_filter = 0
albedo_texture = ExtResource("2_dry_left")

[sub_resource type="StandardMaterial3D" id="Mat_dry_middle"]
texture_filter = 0
albedo_texture = ExtResource("3_dry_middle")

[sub_resource type="StandardMaterial3D" id="Mat_dry_right"]
texture_filter = 0
albedo_texture = ExtResource("4_dry_right")

[sub_resource type="StandardMaterial3D" id="Mat_watered_single"]
texture_filter = 0
albedo_texture = ExtResource("5_watered_single")

[sub_resource type="StandardMaterial3D" id="Mat_watered_left"]
texture_filter = 0
albedo_texture = ExtResource("6_watered_left")

[sub_resource type="StandardMaterial3D" id="Mat_watered_middle"]
texture_filter = 0
albedo_texture = ExtResource("7_watered_middle")

[sub_resource type="StandardMaterial3D" id="Mat_watered_right"]
texture_filter = 0
albedo_texture = ExtResource("8_watered_right")

[sub_resource type="PlaneMesh" id="PlaneMesh_dry_single"]
material = SubResource("Mat_dry_single")
size = Vector2(1, 1)

[sub_resource type="PlaneMesh" id="PlaneMesh_dry_left"]
material = SubResource("Mat_dry_left")
size = Vector2(1, 1)

[sub_resource type="PlaneMesh" id="PlaneMesh_dry_middle"]
material = SubResource("Mat_dry_middle")
size = Vector2(1, 1)

[sub_resource type="PlaneMesh" id="PlaneMesh_dry_right"]
material = SubResource("Mat_dry_right")
size = Vector2(1, 1)

[sub_resource type="PlaneMesh" id="PlaneMesh_watered_single"]
material = SubResource("Mat_watered_single")
size = Vector2(1, 1)

[sub_resource type="PlaneMesh" id="PlaneMesh_watered_left"]
material = SubResource("Mat_watered_left")
size = Vector2(1, 1)

[sub_resource type="PlaneMesh" id="PlaneMesh_watered_middle"]
material = SubResource("Mat_watered_middle")
size = Vector2(1, 1)

[sub_resource type="PlaneMesh" id="PlaneMesh_watered_right"]
material = SubResource("Mat_watered_right")
size = Vector2(1, 1)

[node name="FonteMeshLibrarySolo" type="Node3D"]

[node name="soil_plow_dry_single" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 0)
mesh = SubResource("PlaneMesh_dry_single")

[node name="soil_plow_dry_left" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0.02, 0)
mesh = SubResource("PlaneMesh_dry_left")

[node name="soil_plow_dry_middle" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2, 0.02, 0)
mesh = SubResource("PlaneMesh_dry_middle")

[node name="soil_plow_dry_right" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3, 0.02, 0)
mesh = SubResource("PlaneMesh_dry_right")

[node name="soil_plow_watered_single" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 1)
mesh = SubResource("PlaneMesh_watered_single")

[node name="soil_plow_watered_left" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0.02, 1)
mesh = SubResource("PlaneMesh_watered_left")

[node name="soil_plow_watered_middle" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 2, 0.02, 1)
mesh = SubResource("PlaneMesh_watered_middle")

[node name="soil_plow_watered_right" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3, 0.02, 1)
mesh = SubResource("PlaneMesh_watered_right")
```

(Os 8 planos ficam espalhados numa grade 4x2 só pra não se sobrepor visualmente na cena-fonte — a posição deles aqui não importa pro resultado final, só a existência de cada nó com seu mesh e material. O deslocamento `y = 0.02` em cada um é o que vai fazer o item, já dentro da `MeshLibrary`, renderizar ligeiramente acima do plano de grama quando usado no `GridMap`, evitando z-fighting.)

- [ ] **Step 2: Exportar a `MeshLibrary`**

Carregue o schema da ferramenta com `ToolSearch("select:mcp__godot__export_mesh_library")`, depois chame `mcp__godot__export_mesh_library` apontando a cena-fonte como origem e `resources/farming/mesh_library_solo.tres` como destino. Os parâmetros `scenePath`/`outputPath` dessa ferramenta esperam caminho relativo ao projeto **sem** o prefixo `res://` (passar `res://...` retorna erro "Scene file does not exist") — use `scenes/farming/fonte_mesh_library_solo.tscn` e `resources/farming/mesh_library_solo.tres` diretamente.

- [ ] **Step 3: Verificar**

Abra `resources/farming/mesh_library_solo.tres` no editor (aba Inspector) e confirme que os 8 itens aparecem listados com os nomes esperados (`soil_plow_dry_single`, etc.) e que cada preview mostra a textura certa.

- [ ] **Step 4: Commit**

```bash
git add scenes/farming/fonte_mesh_library_solo.tscn resources/farming/mesh_library_solo.tres
git commit -m "feat(farming): gera mesh library com as 8 variantes de solo arado"
```

---

## Task 7: Nó `GridMap` e recolorir a grama

**Files:**
- Modify: `scenes/levels/playground.tscn`

**Interfaces:**
- Consumes: `resources/farming/mesh_library_solo.tres` (Task 6).
- Produces: nó `GradeSolo` (tipo `GridMap`) em `playground.tscn`, pronto pra Task 8 anexar o script.

- [ ] **Step 1: Recolorir a grama**

Em `scenes/levels/playground.tscn`, no `sub_resource type="StandardMaterial3D" id="StandardMaterial3D_grama"`, troque:

```
albedo_color = Color(0.32549, 0.580392, 0.235294, 1)
```

por:

```
albedo_color = Color(0.517647, 0.776471, 0.411765, 1)
```

- [ ] **Step 2: Adicionar o `ext_resource` da MeshLibrary**

No topo do arquivo, junto aos outros `ext_resource`:

```
[ext_resource type="MeshLibrary" path="res://resources/farming/mesh_library_solo.tres" id="6_grade_solo"]
```

- [ ] **Step 3: Adicionar o nó `GridMap`**

Depois do nó `Piso`, antes do nó `Player`:

```
[node name="GradeSolo" type="GridMap" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 0)
mesh_library = ExtResource("6_grade_solo")
cell_size = Vector3(1, 1, 1)
```

**Nota (ajuste sobre a Task 6):** o offset `y = 0.02` pra evitar z-fighting com a grama, que a Task 6 previa embutir no `mesh_transform` de cada item da `MeshLibrary`, não sobreviveu à exportação via `mcp__godot__export_mesh_library` (a ferramenta zera o transform de todos os itens, verificado na Task 6). Por isso o offset entra aqui, direto no `transform` do próprio nó `GridMap` — desloca o grid inteiro pra cima uma vez só, em vez de por item, com o mesmo efeito visual.

- [ ] **Step 4: Verificar**

Rode a cena (`mcp__godot__run_project`). O chão deve estar visivelmente mais verde-claro (a nova cor da grama), e nenhum erro sobre `GridMap`/`mesh_library` deve aparecer no `mcp__godot__get_debug_output`. Pare com `mcp__godot__stop_project`.

- [ ] **Step 5: Commit**

```bash
git add scenes/levels/playground.tscn
git commit -m "feat(farming): adiciona GridMap de solo e recolore a grama pra combinar"
```

---

## Task 8: Script `GradeSolo` — estado, arar/molhar, variante horizontal

**Files:**
- Create: `scripts/farming/grade_solo.gd`
- Modify: `scenes/levels/playground.tscn` (anexar o script ao nó `GradeSolo`)
- Modify: `scripts/core/event_bus.gd`

**Interfaces:**
- Consumes: `mesh_library` do nó `GradeSolo` (Task 7), `EventBus` (pra emitir os sinais novos).
- Produces: `class_name GradeSolo extends GridMap`, `enum EstadoTile { VAZIO, ARADO_SECO, ARADO_MOLHADO }`, `func arar(celula: Vector2i) -> bool`, `func molhar(celula: Vector2i) -> bool`, `func obter_celula_alvo(posicao_jogador: Vector3, rotacao_y: float) -> Vector2i`. Consumido por Task 9 (indicador) e Task 10 (`player.gd`).

- [ ] **Step 1: Adicionar os sinais no `EventBus`**

Em `scripts/core/event_bus.gd`, depois de `signal npc_relationship_changed(...)`:

```gdscript
signal tile_plowed(celula: Vector2i)
signal tile_watered(celula: Vector2i)
```

- [ ] **Step 2: Criar `grade_solo.gd` com um autoteste temporário**

`scripts/farming/grade_solo.gd`:

```gdscript
class_name GradeSolo
extends GridMap

enum EstadoTile { VAZIO, ARADO_SECO, ARADO_MOLHADO }

var _estado: Dictionary = {}

func arar(celula: Vector2i) -> bool:
	if _estado.get(celula, EstadoTile.VAZIO) != EstadoTile.VAZIO:
		return false
	_definir_estado(celula, EstadoTile.ARADO_SECO)
	EventBus.tile_plowed.emit(celula)
	return true

func molhar(celula: Vector2i) -> bool:
	if _estado.get(celula, EstadoTile.VAZIO) != EstadoTile.ARADO_SECO:
		return false
	_definir_estado(celula, EstadoTile.ARADO_MOLHADO)
	EventBus.tile_watered.emit(celula)
	return true

func obter_celula_alvo(posicao_jogador: Vector3, rotacao_y: float) -> Vector2i:
	var direcao := Vector3(sin(rotacao_y), 0.0, cos(rotacao_y))
	var alvo_local := local_to_map(to_local(posicao_jogador + direcao))
	return Vector2i(alvo_local.x, alvo_local.z)

func _definir_estado(celula: Vector2i, novo_estado: EstadoTile) -> void:
	_estado[celula] = novo_estado
	_atualizar_variante(celula)
	_atualizar_variante(celula + Vector2i.LEFT)
	_atualizar_variante(celula + Vector2i.RIGHT)

func _atualizar_variante(celula: Vector2i) -> void:
	var estado: EstadoTile = _estado.get(celula, EstadoTile.VAZIO)
	if estado == EstadoTile.VAZIO:
		set_cell_item(Vector3i(celula.x, 0, celula.y), -1)
		return

	var tem_esquerda: bool = _estado.get(celula + Vector2i.LEFT, EstadoTile.VAZIO) != EstadoTile.VAZIO
	var tem_direita: bool = _estado.get(celula + Vector2i.RIGHT, EstadoTile.VAZIO) != EstadoTile.VAZIO
	var sufixo: String = "single"
	if tem_esquerda and tem_direita:
		sufixo = "middle"
	elif tem_direita:
		sufixo = "left"
	elif tem_esquerda:
		sufixo = "right"

	var prefixo: String = "dry" if estado == EstadoTile.ARADO_SECO else "watered"
	var nome_item: String = "soil_plow_%s_%s" % [prefixo, sufixo]
	set_cell_item(Vector3i(celula.x, 0, celula.y), mesh_library.find_item_by_name(nome_item))

func _ready() -> void:
	assert(arar(Vector2i(0, 0)) == true, "primeira arada devia funcionar")
	assert(arar(Vector2i(0, 0)) == false, "arar de novo na mesma celula nao devia fazer nada")
	assert(get_cell_item(Vector3i(0, 0, 0)) == mesh_library.find_item_by_name("soil_plow_dry_single"), "celula isolada devia ser single")
	arar(Vector2i(1, 0))
	assert(get_cell_item(Vector3i(0, 0, 0)) == mesh_library.find_item_by_name("soil_plow_dry_left"), "0,0 devia virar left com vizinho a direita arado")
	assert(get_cell_item(Vector3i(1, 0, 0)) == mesh_library.find_item_by_name("soil_plow_dry_right"), "1,0 devia ser right")
	arar(Vector2i(-1, 0))
	assert(get_cell_item(Vector3i(0, 0, 0)) == mesh_library.find_item_by_name("soil_plow_dry_middle"), "0,0 com vizinhos dos dois lados devia virar middle")
	assert(molhar(Vector2i(0, 0)) == true, "molhar celula arada seca devia funcionar")
	assert(molhar(Vector2i(0, 0)) == false, "molhar de novo nao devia fazer nada")
	assert(get_cell_item(Vector3i(0, 0, 0)) == mesh_library.find_item_by_name("soil_plow_watered_middle"), "celula molhada com vizinhos secos ainda devia ser middle, so que watered")
	assert(molhar(Vector2i(5, 5)) == false, "molhar celula vazia nao devia fazer nada")
	print("GradeSolo: autoteste OK")
```

- [ ] **Step 3: Anexar o script ao nó**

Em `scenes/levels/playground.tscn`, no nó `GradeSolo` criado na Task 7, adicione a linha `script = ExtResource("...")` — primeiro adicione o `ext_resource` do script no topo do arquivo:

```
[ext_resource type="Script" path="res://scripts/farming/grade_solo.gd" id="7_grade_solo_script"]
```

E no nó:

```
[node name="GradeSolo" type="GridMap" parent="."]
script = ExtResource("7_grade_solo_script")
mesh_library = ExtResource("6_grade_solo")
cell_size = Vector3(1, 1, 1)
```

- [ ] **Step 4: Rodar e verificar o autoteste**

`mcp__godot__run_project`, depois `mcp__godot__get_debug_output`. Espera-se `GradeSolo: autoteste OK` sem nenhum `Assertion failed`. Pare com `mcp__godot__stop_project`.

- [ ] **Step 5: Remover o autoteste**

Apague o método `_ready()` de `grade_solo.gd`. Rode de novo pra confirmar que não sobrou nenhum erro.

- [ ] **Step 6: Commit**

```bash
git add scripts/farming/grade_solo.gd scenes/levels/playground.tscn scripts/core/event_bus.gd
git commit -m "feat(farming): adiciona logica de arar/molhar e autotile horizontal do grid"
```

---

## Task 9: Indicador de alvo

**Files:**
- Modify: `scenes/levels/playground.tscn`
- Modify: `scripts/player/player.gd`

**Interfaces:**
- Consumes: `EquipmentManager.indice_atual` (Task 2), `GradeSolo.obter_celula_alvo()` (Task 8), `GradeSolo.map_to_local()` (nativo do `GridMap`).

- [ ] **Step 1: Adicionar o nó indicador**

Em `scenes/levels/playground.tscn`, um `sub_resource` de material translúcido e o `PlaneMesh` (reaproveitando o mesmo `size=Vector2(1,1)` já usado na `MeshLibrary`):

```
[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_indicador"]
albedo_color = Color(1, 1, 0, 0.5)
transparency = 1

[sub_resource type="PlaneMesh" id="PlaneMesh_indicador"]
material = SubResource("StandardMaterial3D_indicador")
size = Vector2(1, 1)
```

E o nó, como filho direto da raiz, depois de `GradeSolo`:

```
[node name="IndicadorAlvo" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.03, 0)
visible = false
mesh = SubResource("PlaneMesh_indicador")
```

- [ ] **Step 2: Referenciar os nós em `player.gd`**

Junto aos `@onready` já existentes (`personagem`, `animation_player`):

```gdscript
@onready var grade_solo: GradeSolo = $"../GradeSolo"
@onready var indicador_alvo: MeshInstance3D = $"../IndicadorAlvo"
```

- [ ] **Step 3: Atualizar o indicador a cada frame**

No início de `_physics_process`, depois dos decrementos de timer já existentes e antes da lógica de dash:

```gdscript
var ferramenta_equipada: Ferramenta = EquipmentManager.ferramenta_atual()
indicador_alvo.visible = ferramenta_equipada != null
if ferramenta_equipada != null:
	var celula_alvo: Vector2i = grade_solo.obter_celula_alvo(global_position, personagem.rotation.y)
	var posicao_local: Vector3 = grade_solo.map_to_local(Vector3i(celula_alvo.x, 0, celula_alvo.y))
	indicador_alvo.global_position = grade_solo.global_transform * posicao_local
	indicador_alvo.global_position.y = 0.03
```

- [ ] **Step 4: Verificar manualmente**

Rode o jogo (`mcp__godot__run_project`). Aperte `2` (equipar enxada) — o quadrado amarelo translúcido deve aparecer um tile à frente do personagem e seguir a direção que ele encara ao girar. Aperte `1` (socos) — o indicador some. Pare com `mcp__godot__stop_project`.

- [ ] **Step 5: Commit**

```bash
git add scenes/levels/playground.tscn scripts/player/player.gd
git commit -m "feat(farming): adiciona indicador visual do quadrado alvo da ferramenta"
```

---

## Task 10: Usar a ferramenta equipada ao atacar

**Files:**
- Modify: `scripts/player/player.gd`

**Interfaces:**
- Consumes: `EquipmentManager.ferramenta_atual()` (Task 2), `Ferramenta.id_acao` (Task 1), `GradeSolo.arar()`/`molhar()`/`obter_celula_alvo()` (Task 8), `indicador_alvo`/`grade_solo` (Task 9).

- [ ] **Step 1: Adicionar a lista de clipes de interação**

Junto à constante `CLIPES_COMBO_ATAQUE`:

```gdscript
const CLIPES_INTERACAO: Array[String] = ["interact-left", "interact-right"]
```

E uma variável de estado nova, junto às outras `var _...`:

```gdscript
var _indice_interacao: int = 0
```

- [ ] **Step 2: Desviar o disparo do ataque quando há ferramenta equipada**

O bloco atual do disparo de ataque é:

```gdscript
	if _tempo_dash_restante <= 0.0 and _tempo_ataque_restante <= 0.0 and _tempo_cooldown_ataque_restante <= 0.0 and InputManager.atacar_pressionado():
		var nome_clipe: String = CLIPES_COMBO_ATAQUE[_indice_combo]
		animation_player.play(nome_clipe, -1.0, velocidade_ataque)

		var duracao_golpe: float = animation_player.get_animation(nome_clipe).length / velocidade_ataque
		_tempo_ataque_restante = duracao_golpe
		_tempo_movimento_travado_ataque_restante = duracao_golpe + folga_pos_golpe
		_tempo_janela_combo_restante = janela_combo_ataque

		_indice_combo += 1
		if _indice_combo >= CLIPES_COMBO_ATAQUE.size():
			_indice_combo = 0
			_tempo_cooldown_ataque_restante = cooldown_ataque
			_tempo_janela_combo_restante = 0.0
```

Substitua por:

```gdscript
	if _tempo_dash_restante <= 0.0 and _tempo_ataque_restante <= 0.0 and _tempo_cooldown_ataque_restante <= 0.0 and InputManager.atacar_pressionado():
		var ferramenta_equipada: Ferramenta = EquipmentManager.ferramenta_atual()
		if ferramenta_equipada == null:
			var nome_clipe: String = CLIPES_COMBO_ATAQUE[_indice_combo]
			animation_player.play(nome_clipe, -1.0, velocidade_ataque)

			var duracao_golpe: float = animation_player.get_animation(nome_clipe).length / velocidade_ataque
			_tempo_ataque_restante = duracao_golpe
			_tempo_movimento_travado_ataque_restante = duracao_golpe + folga_pos_golpe
			_tempo_janela_combo_restante = janela_combo_ataque

			_indice_combo += 1
			if _indice_combo >= CLIPES_COMBO_ATAQUE.size():
				_indice_combo = 0
				_tempo_cooldown_ataque_restante = cooldown_ataque
				_tempo_janela_combo_restante = 0.0
		else:
			var celula_alvo: Vector2i = grade_solo.obter_celula_alvo(global_position, personagem.rotation.y)
			var acao_teve_efeito: bool = false
			if ferramenta_equipada.id_acao == &"enxada":
				acao_teve_efeito = grade_solo.arar(celula_alvo)
			elif ferramenta_equipada.id_acao == &"regador":
				acao_teve_efeito = grade_solo.molhar(celula_alvo)

			if acao_teve_efeito:
				var nome_clipe_interacao: String = CLIPES_INTERACAO[_indice_interacao]
				animation_player.play(nome_clipe_interacao, -1.0, velocidade_ataque)

				var duracao_interacao: float = animation_player.get_animation(nome_clipe_interacao).length / velocidade_ataque
				_tempo_ataque_restante = duracao_interacao
				_tempo_movimento_travado_ataque_restante = duracao_interacao + folga_pos_golpe

				_indice_interacao = (_indice_interacao + 1) % CLIPES_INTERACAO.size()
```

Isso mantém o combo de soco intocado quando `ferramenta_equipada == null`, e adiciona o caminho de enxada/regador reaproveitando exatamente as mesmas variáveis de trava de movimento (`_tempo_ataque_restante`, `_tempo_movimento_travado_ataque_restante`) que o soco já usa — sem nenhuma variável de estado nova além de `_indice_interacao`.

- [ ] **Step 3: Verificar manualmente — arar**

Rode o jogo. Aperte `2` (equipa enxada, HUD deve mostrar "Enxada", indicador amarelo aparece à frente). Aperte o botão de atacar olhando pro quadrado indicado: a animação `interact-left`/`interact-right` deve tocar (alternando a cada aperto), o movimento trava por um instante, e o quadrado indicado vira solo arado marrom. Apertar de novo no mesmo quadrado não deve tocar animação nenhuma (célula já arada).

- [ ] **Step 4: Verificar manualmente — fileira horizontal**

Ande um passo pro lado e are o quadrado vizinho. Os dois quadrados arados devem se unir visualmente (bordas internas desaparecem, só a borda externa da fileira fica visível) — não `single` duplicado lado a lado.

- [ ] **Step 5: Verificar manualmente — regador**

Aperte `3` (equipa regador). Use no quadrado já arado: deve virar solo arado molhado (tom mais escuro/avermelhado), mantendo a fileira unida com os vizinhos secos. Usar o regador num quadrado ainda não arado não deve fazer nada.

- [ ] **Step 6: Verificar manualmente — troca de ferramenta**

Confirme que a tecla `1` volta pra socos (indicador some, HUD mostra "Socos", botão de atacar volta a dar soco normal) e que a roda do mouse cicla entre socos → enxada → regador → socos (e o sentido inverso).

- [ ] **Step 7: Commit**

```bash
git add scripts/player/player.gd
git commit -m "feat(farming): enxada e regador substituem o combo de ataque quando equipados"
```

---

## Task 11: Conectar os inputs de equipar/ciclar ao `EquipmentManager`

**Contexto:** lacuna descoberta na revisão da Task 10 — a Task 3 criou as ações de input e os métodos `InputManager.equipar_1_pressionado()` etc., e a prosa da Task 3 descrevia a intenção (`equipar_2` → `EquipmentManager.equipar_indice(0)`), mas nenhuma task tinha um Step que efetivamente chamasse esses métodos do `EquipmentManager`. Sem isso, o jogador não consegue equipar enxada/regador de jeito nenhum jogando normalmente — só chamando código direto, como os agentes fizeram pra verificar as Tasks 9 e 10.

**Files:**
- Modify: `scripts/player/player.gd`

**Interfaces:**
- Consumes: `InputManager.equipar_1_pressionado()`, `equipar_2_pressionado()`, `equipar_3_pressionado()`, `proxima_ferramenta_pressionada()`, `ferramenta_anterior_pressionada()` (Task 3); `EquipmentManager.equipar_indice(indice: int)`, `EquipmentManager.ciclar(direcao: int)` (Task 2).

- [ ] **Step 1: Adicionar a checagem de troca de ferramenta em `_physics_process`**

No início de `_physics_process`, junto aos decrementos de timer já existentes (antes da lógica de dash/ataque):

```gdscript
	if InputManager.equipar_1_pressionado():
		EquipmentManager.equipar_indice(-1)
	elif InputManager.equipar_2_pressionado():
		EquipmentManager.equipar_indice(0)
	elif InputManager.equipar_3_pressionado():
		EquipmentManager.equipar_indice(1)
	elif InputManager.proxima_ferramenta_pressionada():
		EquipmentManager.ciclar(1)
	elif InputManager.ferramenta_anterior_pressionada():
		EquipmentManager.ciclar(-1)
```

`elif` entre as 5 checagens porque só uma pode fazer sentido por frame (não dá pra apertar duas teclas de equipar diferentes no mesmo frame de forma útil); `equipar_indice(0)`/`equipar_indice(1)` são os índices fixos de enxada/regador em `EquipmentManager.ferramentas`, os mesmos já usados no Step 2 da Task 3.

- [ ] **Step 2: Verificar manualmente**

Rode o jogo. Aperte `1`, `2`, `3` e confirme que o HUD alterna entre "Socos"/"Enxada"/"Regador" e o indicador de alvo aparece/some de acordo. Gire a roda do mouse pra cima e pra baixo e confirme que cicla na mesma sequência (socos → enxada → regador → socos, e o sentido inverso). Isso fecha o ciclo: agora dá pra jogar a feature inteira (Tasks 1-11) só com teclado/mouse, sem precisar chamar nada por código.

- [ ] **Step 3: Commit**

```bash
git add scripts/player/player.gd
git commit -m "feat(farming): conecta os inputs de equipar/ciclar ferramenta ao EquipmentManager"
```

---

## Self-Review

**Cobertura da spec:** Ferramenta equipada (Task 1-2), HUD (Task 4), input incluindo scroll do mouse (Task 3), GridMap + MeshLibrary + recolorir grama (Task 5-7), estado do grid + autotile horizontal + sinais do EventBus (Task 8), indicador de alvo (Task 9), integração final em `player.gd` com enxada e regador (Task 10), conexão dos inputs de equipar ao `EquipmentManager` (Task 11 — adicionada depois da revisão da Task 10 ter pego essa lacuna: a Task 3 só criava os métodos de input, nenhuma task os chamava de fato). Todos os itens do "Objetivo" da spec têm uma task correspondente. Os itens de "Fora de escopo" (plantio, secagem automática, posse por inventário, VFX/SFX, cena de fazenda separada) não têm task — corretamente, não deveriam ter.

**Placeholders:** nenhum "TBD"/"implementar depois" — todo passo tem código completo ou comando exato.

**Consistência de tipos:** `Ferramenta.id_acao` (`StringName`) comparado com `&"enxada"`/`&"regador"` em todo lugar que usa; `GradeSolo.arar`/`molhar` retornam `bool` em toda referência (Task 8 e Task 10); `obter_celula_alvo` retorna `Vector2i` em todo lugar (Task 8, Task 9, Task 10); nomes de item da `MeshLibrary` (`soil_plow_{prefixo}_{sufixo}`) idênticos entre Task 6 (onde são criados) e Task 8 (onde são buscados via `find_item_by_name`).

---

Plano completo e salvo em `docs/superpowers/plans/2026-08-11-grade-de-solo.md`. Duas opções de execução:

**1. Subagent-Driven (recomendado)** — eu despacho um subagente novo por task, com revisão entre elas, iteração rápida.

**2. Execução Inline** — executo as tasks nesta sessão com o skill `executing-plans`, em lote com checkpoints pra revisão.

Qual prefere?
