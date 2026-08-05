# Pipeline de assets

Assets brutos são colocados em `_import/`, sem se preocupar com nome final ou organização. Periodicamente, esses arquivos são renomeados segundo a convenção de nomenclatura (veja `convencoes.md`) e movidos para a subpasta correspondente dentro de `assets/`.

Exemplo: um arquivo bruto `personagem_ana_diffuse.png` se torna `assets/textures/npcs/ana_diffuse.png`.

## Convenções por tipo de asset

- **Modelos 3D** (`assets/models/`): formato `.glb`, poligonagem enxuta, compatível com a proposta de renderização 3D simples do jogo.
- **Texturas** (`assets/textures/`): `.png` para texturas com transparência ou baixo detalhe, `.jpg` apenas quando não houver transparência e o peso do arquivo for prioridade sobre a qualidade. Prefira dimensões potência de dois (256, 512, 1024).
- **Áudio** (`assets/audio/`): `.ogg` (Ogg Vorbis) para música e efeitos mais longos. `.wav` reservado a efeitos curtos onde a latência de decodificação importa, como passos e cliques de interface.
- **Fontes** (`assets/fonts/`): `.ttf` ou `.otf`, evitando charsets muito amplos quando não forem necessários, para não inflar o tamanho do build web.

Nada dentro de `_import/` é referenciado diretamente por cenas ou scripts. Essa pasta é apenas uma zona de trânsito.
