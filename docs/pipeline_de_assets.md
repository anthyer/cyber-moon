# Pipeline de assets

Assets brutos sao colocados em `_import/`, sem se preocupar com nome final ou organizacao. Periodicamente, esses arquivos sao renomeados segundo a convencao de nomenclatura (veja `convencoes.md`) e movidos para a subpasta correspondente dentro de `assets/`.

Exemplo: um arquivo bruto `personagem_ana_diffuse.png` se torna `assets/textures/npcs/ana_diffuse.png`.

## Convencoes por tipo de asset

- **Modelos 3D** (`assets/models/`): formato `.glb`, poligonagem enxuta, compativel com a proposta de renderizacao 3D simples do jogo.
- **Texturas** (`assets/textures/`): `.png` para texturas com transparencia ou baixo detalhe, `.jpg` apenas quando nao houver transparencia e o peso do arquivo for prioridade sobre a qualidade. Prefira dimensoes potencia de dois (256, 512, 1024).
- **Audio** (`assets/audio/`): `.ogg` (Ogg Vorbis) para musica e efeitos mais longos. `.wav` reservado a efeitos curtos onde a latencia de decodificacao importa, como passos e cliques de interface.
- **Fontes** (`assets/fonts/`): `.ttf` ou `.otf`, evitando charsets muito amplos quando nao forem necessarios, para nao inflar o tamanho do build web.

Nada dentro de `_import/` e referenciado diretamente por cenas ou scripts. Essa pasta e apenas uma zona de transito.
