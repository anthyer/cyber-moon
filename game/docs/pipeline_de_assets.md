# Pipeline de assets

Assets brutos são colocados em `_import/`, sem se preocupar com nome final ou organização. Periodicamente, esses arquivos são renomeados segundo a convenção de nomenclatura (veja `convencoes.md`) e movidos para a subpasta correspondente dentro de `assets/`.

Exemplo: um arquivo bruto `personagem_ana_diffuse.png` se torna `assets/textures/npcs/ana_diffuse.png`.

## Convenções por tipo de asset

- **Modelos 3D** (`assets/models/`): formato `.glb`, poligonagem enxuta, compatível com a proposta de renderização 3D simples do jogo.
- **Texturas** (`assets/textures/`): `.png` para texturas com transparência ou baixo detalhe, `.jpg` apenas quando não houver transparência e o peso do arquivo for prioridade sobre a qualidade. Prefira dimensões potência de dois (256, 512, 1024).
- **Áudio** (`assets/audio/`): `.ogg` (Ogg Vorbis) para música e efeitos mais longos. `.wav` reservado a efeitos curtos onde a latência de decodificação importa, como passos e cliques de interface.
- **Fontes** (`assets/fonts/`): `.ttf` ou `.otf`, evitando charsets muito amplos quando não forem necessários, para não inflar o tamanho do build web.

Nada dentro de `_import/` é referenciado diretamente por cenas ou scripts. Essa pasta é apenas uma zona de trânsito.

## Pacotes de terceiros

A maior parte da arte do jogo vem de pacotes prontos da Kenney, que chegam como um `.zip` com o mesmo modelo exportado em vários formatos. As regras abaixo valem para qualquer pacote desse tipo.

- **Escolha do formato:** só o `.glb` entra no projeto. Os formatos `.fbx`, `.obj`, `.dae` e `.stl` que acompanham o pacote são descartados, porque o `.glb` é o que o Godot importa nativamente, num arquivo só e sem passo de conversão.
- **Uma pasta por pacote:** cada pacote vira `assets/models/<nome_do_pacote>/`, com o `license.txt` do pacote junto. Manter o pacote inteiro numa pasta própria evita colisão de nomes entre pacotes diferentes e deixa claro de onde cada modelo veio.
- **Renomeação:** os arquivos do pacote são renomeados para `snake_case` como qualquer outro arquivo do projeto (`animal-cat.glb` vira `animal_cat.glb`, `cliff_blockSlopeHalfWalls_rock.glb` vira `cliff_block_slope_half_walls_rock.glb`).
- **Textura ao lado do modelo:** alguns pacotes não embutem a textura no `.glb`, referenciam um arquivo externo por caminho relativo (nos pacotes da Kenney, uma paleta única chamada `colormap.png`). Essa textura fica em `assets/models/<nome_do_pacote>/textures/`, junto dos modelos, e não em `assets/textures/`. Se ela for movida para outro lugar, o caminho gravado dentro do `.glb` deixa de resolver e os modelos importam sem textura, todos brancos.
- **Ao renomear a pasta da textura**, lembre que o caminho está gravado dentro de cada `.glb` e precisa ser corrigido junto. Nos pacotes da Kenney o caminho original é `Textures/colormap.png`, com maiúscula, e foi reescrito para `textures/colormap.png` para acompanhar a convenção do projeto.
- **Renders 2D** (vistas isométricas, laterais e miniaturas de pré-visualização que alguns pacotes trazem) vão para `assets/textures/<nome_do_pacote>/`. Não são usados pelo jogo 3D, mas são candidatos naturais a ícone de inventário e arte de interface, o que evita ter que renderizar os modelos só para isso.
- **Compressão da paleta:** a paleta de cores é importada como `Lossless`, com `detect_3d/compress_to=0` no `.import`. Sem isso o Godot reimporta a textura sozinho como `VRAM Compressed` assim que ela aparece numa cena 3D, e a compressão em blocos mistura as cores vizinhas da paleta, sujando o tom de cada face.
- **Nature Kit não tem textura:** os 329 modelos do `kenney_nature_kit` usam cor chapada por material (`albedo_color`, sem `albedo_texture`), confirmado lendo os materiais no `.glb`. Isso não é textura faltando nem import quebrado — é como o pacote foi feito. Não existe textura de grama/terra tileável em lugar nenhum do projeto; para superfícies grandes (chão que o jogador anda por cima, por exemplo), a solução é uma cor sólida própria num `StandardMaterial3D`, não a cor do material do Nature Kit. As cores desse pacote são de uma paleta estilizada (o `grass` do `platform_grass.glb`, por exemplo, é um ciano/turquesa, não um verde natural) e ficam estranhas espalhadas numa superfície grande, mesmo corretas.
- **Normalização de material:** os modelos chegam do glTF com `metallicFactor = 1.0`, o que faz o Godot tratar a cor do albedo como cor de reflexo em vez de cor difusa (fica escuro sem ambiente, ou espelha a cor do céu quando há um). Todo `.glb.import` de pacote Kenney aponta `import_script/path` para `res://scripts/utils/post_import_kenney.gd`, que zera o metálico e uniformiza rugosidade e filtro de textura na importação. Um pacote novo extraído para `assets/models/` precisa do mesmo `import_script/path` nos seus `.glb.import`:
  ```
  find assets/models/<nome_do_pacote> -name "*.glb.import" -exec sed -i \
    's|^import_script/path=""$|import_script/path="res://scripts/utils/post_import_kenney.gd"|' {} +
  ```
