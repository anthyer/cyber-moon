---
name: rodar-o-jogo
description: Use ao rodar, testar, depurar ou verificar qualquer coisa no Cyber Moon, ao abrir o editor do Godot, ao investigar erro, crash, tela preta, modelo branco sem textura, colisão que não funciona, animação que não toca ou som que não sai. Também ao importar assets novos e ao escrever Transform3D ou button_index a mão em .tscn e project.godot.
---

# Rodar e depurar o Cyber Moon

O projeto Godot fica em `game/`, não na raiz do repositório. Todo comando e todo
caminho de projeto aponta para `game/`.

## Rodar pelo MCP

O servidor MCP `godot` está configurado no `.mcp.json` versionado. As ferramentas úteis:

- `run_project` com o caminho de `game/` roda o jogo.
- `get_debug_output` traz stdout e stderr do processo rodando. É aqui que aparecem os
  `push_error`, `push_warning` e qualquer `print`.
- `stop_project` encerra.
- `launch_editor` abre o editor, necessário para tarefa que exige a interface
  (montar cena grande, editar MeshLibrary, ajustar import dock).

Rodar sem parar o anterior deixa processo pendurado. Sempre `stop_project` antes de
rodar de novo.

## Rodar pela linha de comando

Útil para importar assets e para checagem que não precisa de janela:

```bash
GODOT=/var/lib/flatpak/exports/bin/org.godotengine.Godot
"$GODOT" --headless --path game --import          # reimporta assets novos
"$GODOT" --path game                              # roda a cena principal
"$GODOT" --headless --path game --script res://caminho/script.gd
```

Se o Godot não for flatpak nesta máquina, o caminho muda. Ajuste `GODOT_PATH` no
`.mcp.json` junto.

## Verificar de verdade

Uma feature não está pronta porque o código parece certo. Rode o jogo e observe o
comportamento específico que a tarefa prometia. Quando o efeito não é visível na tela
(um estado interno, um valor calculado), coloque um `print` temporário, rode, leia com
`get_debug_output`, confirme o número, e só então apague o `print`.

Para lógica pura que não depende de cena, um script headless com `--script` verifica
mais rápido que abrir o jogo. Carregue o recurso real com `load()` em vez de confiar na
leitura do arquivo de texto.

## Três armadilhas que já morderam este projeto

**Transform3D em `.tscn` é row-major.** Os 9 números da base são as linhas da matriz,
não os vetores de eixo x, y, z que o construtor `Transform3D(Vector3, Vector3, Vector3,
Vector3)` do GDScript recebe. Derive a base como colunas, transponha antes de escrever:
`row0 = (x.x, y.x, z.x)`, `row1 = (x.y, y.y, z.y)`, `row2 = (x.z, y.z, z.z)`. Rotação
identidade fica igual dos dois jeitos, então o erro passa despercebido. Já aconteceu de
a câmera e a luz direcional apontarem para o céu em vez do chão por causa disso, e
ninguém notar porque sem sky configurado os dois casos mostram cinza chapado. Depois de
escrever, confirme carregando a cena de verdade e lendo `global_transform.basis`.

**`button_index` do JoyButton não é a ordem intuitiva.** A enum do Godot 4 é
`0=A, 1=B, 2=X, 3=Y, 4=Back, 5=Guide, 6=Start, 7=LeftStick, 8=RightStick,
9=LeftShoulder (L1), 10=RightShoulder (R1), 11=DPadUp, 12=DPadDown, 13=DPadLeft,
14=DPadRight`. L1 é 9 e R1 é 10, o que é fácil de trocar. Antes de escrever um bind
novo a mão, confira contra um bind que já existe no `project.godot` e usa valor
vizinho, em vez de confiar na enum de memória.

**`.glb` de pacote Kenney precisa do script de pós importação.** Os modelos chegam do
glTF com `metallicFactor = 1.0`, o que faz o Godot tratar a cor de albedo como cor de
reflexo: o modelo fica escuro sem ambiente, ou espelha a cor do céu quando há um. Todo
`.glb.import` de pacote Kenney aponta `import_script/path` para
`res://scripts/utils/post_import_kenney.gd`. Pacote novo extraído para `assets/models/`
precisa do mesmo tratamento:

```bash
find game/assets/models/<nome_do_pacote> -name "*.glb.import" -exec sed -i \
  's|^import_script/path=""$|import_script/path="res://scripts/utils/post_import_kenney.gd"|' {} +
```

## Duas armadilhas de textura

**Modelo branco sem textura** quase sempre é caminho relativo quebrado dentro do `.glb`.
Alguns pacotes não embutem a textura, referenciam `textures/colormap.png` por caminho
relativo gravado no arquivo binário. Mover ou renomear a pasta da textura quebra isso
sem gerar erro visível.

**Pixel art que fica borrada ou com cor suja** é o `detect_3d/compress_to` do `.import`.
O padrão é `1`, e assim que a textura aparece numa cena 3D o Godot a reimporta sozinho
como VRAM Compressed, misturando as cores vizinhas. Para paleta e para pixel art, o
`.import` precisa de `compress/mode=0` e `detect_3d/compress_to=0`. As texturas em
`game/assets/textures/tiny_farm_crops/` já estão assim.

## Antes de dizer que funciona

Nunca afirme que algo passou sem ter rodado e lido a saída. Se rodou e falhou, diga que
falhou e mostre a saída. Se pulou uma verificação, diga que pulou.
