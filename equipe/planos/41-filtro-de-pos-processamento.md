# Plano 41: Filtro de pós-processamento

**Objetivo:** dar ao mundo 3D uma camada de acabamento por cima da imagem, com três
efeitos: brilho no neon, gradação de cor por período do dia e contorno nos objetos. Hoje
o jogo não tem nenhum pós-processamento: o `Environment` da fase só define o céu, sem
brilho, sem tonemap e sem ajuste de cor.

**Depende de:** 10 (o relógio e a `IluminacaoDoCiclo`), 13 (clima), 37 (a luz da Lua) e
40 (a tela de opções, onde ficam as chaves). Os passos 1 a 4 não precisam do 40; só o
passo 5 precisa.

**Situação:** registrado em 2026-11-05, a pedido do Antonio. Falta fazer.

## O pedido do Antonio (2026-11-05)

- Um filtro de pós-processamento para o jogo.
- Os três efeitos escolhidos: **brilho no neon**, **paleta e gradação de cor** e
  **contorno nos objetos**. O visual pixelado (baixa resolução) ficou de fora.
- **Bonito primeiro.** Aceita perder quadros na Web em troca do visual. Mesmo assim, cada
  efeito tem chave nas opções, e o plano mede o custo de cada um.

## Os três efeitos

### Brilho no neon (glow)

O que é de neon passa a irradiar: as placas e o letreiro do mapa, a luz da mochila
verde-broto do jogador (plano 39), o visor do Kenji, as janelas acesas, a fogueira do
acampamento, os olhos dos inimigos e a Lua.

- Usa o glow do próprio `Environment`. O renderizador Compatibility tem glow desde o
  Godot 4.3, mas desenha em LDR: o que brilha é o que passa de um limiar de claridade, e
  não o que tem energia acima de 1. **Verificar no passo 1** se o limiar separa o neon do
  resto sem fazer a areia do deserto brilhar ao meio-dia.
- Se o limiar não separar, o neon ganha um material com emissão forte e o glow fica mais
  fraco de dia e mais forte à noite (ver "Por período do dia").
- O que brilha é decidido no material, não numa lista no código: emissão no material da
  peça, ou a cor reservada da paleta (`verde_broto`, os `neon_*`) já acesa.

### Gradação de cor por período do dia

Uma tabela de cor (LUT) por período, que muda a cara da imagem inteira:

| Período | Cara |
|---|---|
| Manhã | luz limpa, poeira dourada leve |
| Tarde | deserto alaranjado e quente, sombra puxada para o azul |
| Anoitecer | laranja para o magenta, céu da cidade acendendo |
| Noite | azul profundo com realce magenta e ciano nas luzes |
| Madrugada | violeta escuro, pouco contraste |

- Usa o ajuste de cor do `Environment` (`adjustment_enabled` e
  `adjustment_color_correction`, que aceita uma textura de LUT). Entre dois períodos, a
  LUT não pode trocar de uma vez: o filtro mistura as duas (duas texturas e um peso num
  shader de tela, ou uma `GradientTexture` refeita aos poucos). **Verificar no passo 1**
  qual dos dois o Compatibility aceita.
- O clima e a estação já tingem a luz (planos 11 e 13). A gradação vem por cima e precisa
  combinar com eles, não brigar: na chuva, menos saturação; no Apagão, mais frio.
- **Pontilhado (dither) suave** opcional nas passagens de cor, para o degradê do céu não
  virar faixa. Só se o passo 1 mostrar faixa.
- **Nada vermelho.** A gradação não pode empurrar dano, inimigo ou interface para o
  vermelho. A noite vai para o magenta e o violeta, não para o vermelho.
- As LUTs são arquivos PNG em `assets/textures/pos/`, geradas por script para poderem ser
  refeitas, e os períodos apontam para elas num `.tres`.

### Contorno nos objetos

Uma linha escura em volta de personagens, objetos e prédios, no estilo de desenho, que
ajuda a ler a cena vista de cima e de longe.

Há dois jeitos, e o passo 1 decide:

- **Na tela, pela profundidade.** Um shader de tela lê a textura de profundidade e
  desenha linha onde a profundidade salta. Um efeito só para a cena inteira, sem mexer em
  modelo. Riscos: a água e a grama translúcidas (`agua_toon`, `grama_perto`) não escrevem
  profundidade do mesmo jeito, e o terreno longe pode ganhar linha onde não devia.
- **Casca invertida no material.** Cada material ganha uma segunda passada (`next_pass`)
  com a face de trás aumentada e escura. Funciona em qualquer renderizador e dá linha
  limpa nos personagens, mas exige mexer nos materiais na importação
  (`post_import_kenney.gd`) e dobra os triângulos desenhados.

Sugestão: contorno na tela para o cenário, e casca invertida só nos personagens (moradores,
protagonistas e inimigos), que é onde a leitura mais importa. A cor da linha não é preta
pura: é o azul-noite do fundo de painel da interface do plano 40, um pouco mais escuro de
dia e mais claro de noite.

## Por período do dia

O filtro não é fixo. Os números de cada efeito mudam com a hora, junto da luz:

| | Manhã e tarde | Anoitecer | Noite e madrugada |
|---|---|---|---|
| Glow | fraco, só o neon forte | médio | forte |
| Gradação | quente | transição | fria, magenta e ciano |
| Contorno | escuro | médio | mais claro, para não sumir no escuro |

Na dungeon a luz já é fixa (`IluminacaoDoCiclo`); o filtro também fica fixo, com um perfil
próprio de dungeon por tema (Galeria, Biodomo, Torre).

## Arquitetura

- Um nó novo na fase, `FiltroDaTela` (classe `ScreenFilter`, script
  `scripts/world/filtro_da_tela.gd`), irmão da `IluminacaoDoCiclo`. Ele lê a hora do
  `DayCycleManager`, o clima do `WeatherManager`, a estação do `SeasonManager` e a Lua do
  `RealWorldManager`, e mexe no `Environment` e no shader de tela. Os sistemas não sabem
  que o filtro existe: tirar o nó da fase tira os efeitos sem quebrar nada, como o
  `EfeitosDoJogo`.
- Os números ficam num `Resource` novo, `ConfiguracaoDoFiltro`
  (`scripts/resources/configuracao_do_filtro.gd`), com um `.tres` em
  `resources/pos/configuracao.tres`: força do glow e limiar por período, a LUT de cada
  período, a cor e a espessura do contorno, o perfil de cada dungeon. Nada de número no
  código.
- O efeito de tela (contorno e mistura de LUT, se for por shader) é um quad na frente da
  câmera com `hint_screen_texture` e `hint_depth_texture`, em
  `assets/shaders/filtro_da_tela.gdshader`. A interface (`CanvasLayer`) fica fora do
  filtro: o texto e os ícones pixel art do plano 40 não ganham contorno nem gradação.
- As chaves (glow, gradação, contorno, e uma chave geral) ficam nas opções do plano 40, e
  são salvas com as outras preferências, fora do save do jogo.
- Registrar o nó, o `Resource` e o shader em `game/docs/arquitetura.md`, e o termo em
  `game/docs/glossario.md` ("Filtro da tela" para `ScreenFilter`).

## Partículas

O filtro não cria ação do jogador, então não tem partícula própria. Mas ele muda como as
partículas que existem aparecem: as faíscas claras do combate e os brilhos (Lua, saque
raro, chefe) passam a brilhar com o glow. Conferir no passo 6 que o glow não transforma o
efeito de dano em mancha, e que continua sem vermelho.

## Passos

- [ ] **1.** Prova no Compatibility, numa cena de teste: glow com limiar (o neon brilha e
  a areia ao meio-dia não), LUT pelo `Environment` e mistura de duas, contorno pela
  profundidade e casca invertida num personagem. Rodar também no export Web e medir os
  quadros por segundo de cada um. Ajustar este plano com o que funcionar.
- [ ] **2.** `ConfiguracaoDoFiltro`, o `.tres` e o `FiltroDaTela` com o glow por período.
  Marcar como emissivo o que é neon nos materiais.
- [ ] **3.** Gradação: script que gera as LUTs, uma por período e uma por dungeon, e a
  mistura entre elas acompanhando a hora, o clima e a estação.
- [ ] **4.** Contorno, do jeito decidido no passo 1, com a cor por período.
- [ ] **5.** As chaves nas opções do plano 40 e no menu de debug (F3), com a medição de
  quadros na tela.
- [ ] **6.** Rodar o jogo da manhã à madrugada, na chuva, na tempestade, nas quatro
  estações, com Lua cheia e nova, e nas três dungeons. Comparar com e sem cada efeito,
  em 1152 por 648, em tela cheia e na Web. Nada vermelho.

## Como saber que ficou pronto

- À noite, as placas, a mochila do jogador e a Lua irradiam; ao meio-dia, a areia não.
- A tarde é alaranjada e a noite azul com magenta, e a troca acontece aos poucos, sem
  salto.
- Personagens e objetos têm contorno, e o contorno não aparece na água, na grama nem
  na interface.
- Cada efeito liga e desliga nas opções, e a imagem sem filtro é a de hoje.
- A medição de quadros de cada efeito, no PC e na Web, está registrada em `pendencias.md`.

## Fora de escopo

- O visual pixelado (renderizar em baixa resolução), que o Antonio deixou de fora.
- As linhas de varredura da tela, que são do plano 40 (camada da interface, não do
  mundo).
- Filtro diferente por mapa além da fazenda, do mundo e das três dungeons.
