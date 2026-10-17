# Bíblia de 3D

O guia de estilo dos modelos 3D do Cyber Moon. Serve para duas coisas: escolher e usar
bem os modelos que o projeto já tem, e modelar peça nova que não destoe deles. Toda vez
que um modelo novo ensinar alguma coisa (um erro, um atalho, uma medida), a lição entra
aqui, na seção "Dificuldades superadas".

O jogo usa pacotes da Kenney e um pacote próprio, o `cyber_moon_dungeons`, feito no
Blender para as dungeons. A regra de ouro: **antes de modelar, abra no Blender um modelo
parecido que já existe e meça**. Tamanho, número de faces, onde tem chanfro, de que
célula da paleta sai cada cor. Modelo feito de memória sai fora do estilo.

## O estilo em uma frase

Forma simples e reconhecível de longe, poucas faces, cor chapada tirada de uma paleta
pequena, sem textura desenhada, sem brilho de metal. O jogo é visto de cima e de longe:
o que importa é a silhueta e duas ou três cores, não o detalhe.

## Os pacotes e como cada um é feito

| Pacote | O que tem | Cor | Escala na cena |
|---|---|---|---|
| `kenney_city_kit_industrial` | galpões, chaminés, tanques, contêineres, painéis solares | paleta `colormap.png` | 4 |
| `kenney_city_kit_commercial` | prédios, arranha-céus, toldos | paleta própria | 4 |
| `kenney_city_kit_suburban` | casas, cercas, caminhos | paleta própria | 4 |
| `kenney_city_kit_roads` | ruas, calçadas, postes, placas | paleta própria | 4 |
| `kenney_nature_kit` | árvores, pedras, plantas, cultivos, cercas | cor chapada por material, sem textura | 4 |
| `kenney_mini_characters` | pessoas (jogador, NPCs) com esqueleto e animações | paleta própria | 1 |
| `kenney_cube_pets` | animais em cubo, com esqueleto | paleta própria | 1 |
| `cyber_moon_dungeons` | cenário, objetos, inimigos e chefes das dungeons | paleta do industrial | 1 |
| `cyber_moon_mundo` | deserto, vila, canal, viaduto, acampamento e fazenda | paleta do industrial | 1 |

Cada pacote de cidade tem **a sua** `colormap.png`. Os arquivos têm o mesmo desenho
geral, mas não são iguais: a UV de um modelo do pacote comercial aponta para outra cor
se for usada com a paleta do industrial. Por isso um modelo editado que troca de pacote
precisa ser repintado (ver "Editar um modelo que já existe").

## A paleta

O pacote próprio usa a paleta do `kenney_city_kit_industrial`, copiada sem alteração
para `assets/models/cyber_moon_dungeons/textures/colormap.png`. Ela tem 512 por 512
pixels, em 8 colunas por 4 linhas de células de 64 por 128. **A metade esquerda de cada
célula é a cor chapada; a metade direita é um degradê da mesma cor**, mais claro em cima.

Todo modelo tem **um material só** apontando para essa imagem. A cor de uma face é
escolhida pondo a UV da face inteira num ponto da célula. Não existe UV "aberta": todos
os vértices de uma face chapada têm a mesma UV. Na face com degradê, a UV anda só na
vertical, da base ao topo da peça.

Os nomes que o kit de modelagem dá às células (linha, de cima para baixo):

| Linha | Células, da esquerda para a direita |
|---|---|
| 0 | `azul`, `azul_claro`, `roxo`, `magenta`, `rosa` (as três últimas colunas são pretas, sem uso) |
| 1 | `salmao`, `ferrugem`, `pessego`, `creme`, `verde`, `amarelo`, `laranja`, `coral` |
| 2 | `cinza`, `cinza_medio`, `cinza_escuro`, `grafite`, `cinza_metal`, `chumbo`, `lavanda`, `branco` |
| 3 | `preto`, `verde_folha`, `marrom`, `cinza_lilas`, `gelo`, `azul_palido`, `indigo`, `branco_frio` |

Como usar:

- **Concreto e metal** saem da linha 2. O cinza é sempre azulado; não existe cinza neutro
  na paleta, e é isso que dá unidade ao cenário.
- **Uma cor de destaque por peça**, no máximo duas. O resto é cinza. Um barril é azul
  com aros de chumbo; um quadro elétrico é cinza com quatro luzes.
- **Faixa de aviso** é `amarelo` alternado com `grafite`. É a marca de "perigo" e de
  "aqui não passa" do jogo, e aparece em mureta, porta, soleira de arena e máquina.
- **Neon** é `magenta`, `azul_claro` e `amarelo`, sempre em face que emite luz.
- **Vermelho**: a célula mais próxima é a `coral`, e ela só entra em objeto (um
  contêiner). Nada que represente dano, golpe ou morte usa vermelho, porque o jogo não
  tem sangue.
- A paleta não tem ciano nem verde-limão. Quando a cena pede essas cores, elas vêm da
  luz (`OmniLight3D`), não do modelo.

## Escala

A medida de referência é o personagem: **0,66 de altura**, cápsula de raio 0,25.

- Os pacotes da Kenney de cidade e natureza são miniaturas (um prédio tem perto de 1,3 de
  altura, um contêiner 0,35) e entram na cena com **escala 4**.
- O pacote próprio é modelado **no tamanho final** e entra com **escala 1**. É mais fácil
  pensar a porta, o piso e o inimigo já na medida do jogador.

Medidas que deram certo no pacote próprio:

| Peça | Medida |
|---|---|
| Placa de piso | 2 por 2, topo em y = 0 |
| Módulo de parede alta | 2 de largura, 2 de altura, 0,3 de espessura |
| Mureta (lado da câmera) | 2 de largura, 0,35 de altura |
| Vão de porta | 2 de largura, 2,2 de altura |
| Objeto de chão (barril, caixote) | 0,4 a 0,5, um pouco abaixo do personagem |
| Objeto alto (coluna, armário de servidor) | 1,7 a 2,3 |
| Inimigo comum | cabe em 0,5 de largura por 0,7 de altura |
| Chefe | modelado em 0,8 a 1,0 e ampliado pelo `escala` do perfil (1,7 a 2,6) |

## Quantas faces

Contagem em triângulos, medida nos modelos:

| Tipo | Kenney | Pacote próprio |
|---|---|---|
| Peça de chão | 44 (rua reta) | 60 a 150 |
| Objeto pequeno | 88 (cerca), 160 (chaminé) | 70 a 250 |
| Objeto médio | 310 (tanque), 400 (contêiner) | 250 a 550 |
| Prédio | 1250 a 1900 | não tem |
| Pessoa | perto de 770 | não tem |
| Inimigo comum | não tem | 190 a 330 |
| Chefe | não tem | 700 a 1300 |

Cilindro tem 6 a 12 lados; 8 e 10 são o normal. Menos que 6 lê como prisma, mais que 12
é face jogada fora.

## Sombreamento

Os modelos misturam face chapada com chanfro suave. No pacote próprio a regra é
automática: toda face é marcada como suave e toda aresta com mais de 40 graus fica viva.
O resultado é caixa de face dura, cilindro de lateral lisa e chanfro de 45 graus duro.

O Nature Kit é quase todo facetado, de propósito: é o que faz a árvore parecer de papel
dobrado. Não suavize modelo desse pacote.

Rugosidade é 1 e metálico é 0 em tudo. Nada brilha, nada reflete. O que "acende" (luz de
painel, visor de inimigo, neon) usa um segundo material, `colormap_brilho`, que é a mesma
paleta ligada também na emissão.

## Estilo por tipo de asset

### Prédios e estruturas (kits de cidade)

Caixa com chanfro pequeno nas quinas, rodapé mais escuro, capa no topo. Janela é um
retângulo de `azul_claro` ou `azul` um pouco afundado, sem vidro de verdade. Detalhe é
sempre volume (uma caixa colada), nunca desenho. A parede usa o degradê da célula, mais
escuro perto do chão; é o único "sombreado pintado" do estilo.

Parede e piso das dungeons seguem isso: pano em degradê, rodapé `chumbo`, capa escura,
duas juntas verticais finas.

### Tubulação, máquinas e objetos industriais

Cilindro de 8 a 10 lados com flange (um anel um pouco mais largo, `chumbo`) nas pontas e
no meio. Curva de tubo é feita em gomos: dois trechos retos e uma esfera facetada em cada
dobra, sem curva suave. Suporte e pé são caixas `grafite`. Toda máquina tem uma faixa de
aviso ou uma luz, senão vira um bloco cinza sem leitura.

### Plantas e natureza (Nature Kit)

Sem textura. Cada material é uma cor chapada (`leafsGreen`, `woodBark`, `grass`, `corn`).
A copa da árvore é um sólido facetado, nunca folhas soltas. O verde do pacote é puxado
para o turquesa; em superfície grande fica estranho (ver `pipeline_de_assets.md`).

Planta que entra no pacote próprio é **repintada na paleta**: folha vira `verde`, tronco
e terra viram `marrom`, espiga vira `amarelo`. Isso muda o tom (o verde da paleta é mais
claro que o turquesa do Nature Kit), mas deixa a planta com a mesma cara dos outros
objetos da dungeon.

### Pessoas (mini characters)

Cabeça grande e quadrada, quase do tamanho do tronco; corpo curto; sem dedos, sem rosto
modelado. Têm esqueleto e um conjunto de animações (`idle`, `walk`, `sprint`,
`attack-melee-right`, `die` e outras). O jogo diferencia os personagens trocando o
modelo e tingindo o material. **Não modelamos pessoa nova**: fazer o esqueleto e as
animações à mão não compensa. Personagem novo é um dos 26 modelos do pacote.

### Animais (cube pets)

Um cubo com patas, orelhas e focinho colados. Têm esqueleto. Vale a mesma decisão das
pessoas: usar os que existem.

### Veículos e ruas

O projeto não tem pacote de veículo. As ruas são placas de 1 por 1 (4 por 4 na cena) com
a faixa pintada como volume fino. Se um dia entrar carro, a referência é a mesma dos
prédios: caixa chanfrada, janela de `azul_claro`, roda de cilindro de 8 lados `grafite`.

### Deserto (cactos, rochas, mesas de pedra)

O deserto do mapa mundi segue o Nature Kit na forma (sólido facetado, sem detalhe fino)
e a paleta do pacote na cor:

- **Cacto** é `verde`, com espinho `creme` e uma flor `magenta` ou `rosa` no alto. O alto
  tem cerca de 2 de altura, três personagens; o redondo e a palma ficam abaixo de 1.
- **Mesa de pedra** é feita de camadas de contorno irregular (11 pontos, extrudados na
  vertical), alternando `ferrugem` e `salmao` e com o topo `pessego`. Camadas de caixa
  chanfrada pareciam almofadas empilhadas: o contorno irregular é o que dá cara de rocha.
- **Rochas** são as do Nature Kit repintadas de `ferrugem` e `pessego`.
- **Capim** é um leque de folhas largas (prismas de três pontos) em amarelo, creme e
  pêssego. Com folha fina, de cone de três lados, parecia graveto solto.
- **Mancha de chão** (terra batida, areia clara) é um contorno irregular de espessura
  quase zero, rente ao chão, para quebrar o plano de areia sem custo.

### Terreno do mundo

O chão do mapa mundi é uma malha só (`chao_terreno_mundo`), feita por
`equipe/ferramentas/blender/modelos/terreno.py` a partir do traçado de
`equipe/ferramentas/desenho_do_mundo.py`. É uma grade de 1 em 1 com um tremor pequeno,
facetada como o Nature Kit, com dunas baixas, dois terraços com rampa, e o rio, o cânion
e o lago afundados.

- **Cor por face**, tirada da paleta pelo tom do degradê (`"pessego@0.35"`): areia e
  poeira em tons médios, nunca o chapado claro, que estoura para o branco ao meio-dia.
- **Barranco** é qualquer face com inclinação acima de 0,45: estrato de `ferrugem` e
  `salmao` pela altura, e sombreamento liso (o resto do chão é facetado).
- **O barranco é mais largo que a grade.** Rio com 1,3 de barranco, cânion com 1,6, lago
  com 1,4. E os vértices perto do pé e do topo são puxados para cima da curva exata
  (`encaixar_nas_margens`).

### Terreno da fazenda

O chão da fazenda segue a mesma receita, com `terreno_da_fazenda.py` lendo
`desenho_da_fazenda.py`. Dentro da cerca é plano; o desnível fica no laguinho e no vale de
fora. São dois modelos: `chao_terreno_fazenda` (paleta por face: terra batida
`pessego@0.2`, talhão `marrom`, terra rachada e areia) e `chao_terreno_fazenda_gramado`,
sem material, com um cinza por face na cor dos vértices, que o jogo multiplica pelo verde
da estação. Os vértices perto da beira de cada caminho são puxados para a beira exata;
os talhões caem na grade e não se mexem.

### Água (shader toon)

A água tem o shader `assets/shaders/agua_toon.gdshader`: duas cores chapadas que andam
devagar, riscos finos de reflexo, espuma ondulando na beira e luz em degraus
(`diffuse_toon`). Não usa textura nem leitura de profundidade, que o renderizador
Compatibility não garante.

- **Rio e lago** são um modelo (`enfeite_agua_do_mundo`): uma fita que segue o rio, com
  cinco vértices atravessando o curso, e um leque que preenche o lago. A cor do vértice
  guarda a distância até a beira (0 na beira, 1 a dois de distância), e a espuma segue a
  margem por ela (`espuma_pela_cor_do_vertice`). A beira da água entra 0,6 por baixo do
  barranco. Onde o rio desemboca no lago, o anel do lago não tem espuma.
- **O laguinho da fazenda** é um plano de 1 por 1 esticado pela escala do nó: é pela
  escala que o shader sabe a largura da espuma em metros.

### Borda dos corredores

Onde o deserto fecha, a parede invisível tem sempre cenário em cima (`bordas.py`). As
peças compridas têm 2 de comprimento ao longo de X e seguem a linha emendadas: muro de
pedra seca, cerca de estaca, barreira de concreto. As soltas enchem a
linha e uma segunda fileira atrás: moita de cacto, pilha de sucata, pedra, mato. O tema
muda a cada trecho de 10 a 22, pelo lugar: concreto na pista, cerca e sucata perto de
casa, junco e arbusto perto da água (a cerca viva foi testada ali e destoou: verde
forte demais para a beira do rio no deserto), e pedra, mato ou cerca no deserto aberto. Peça alta (árvore
seca, cacto alto, rochedo) só na borda do norte do corredor, que não esconde o jogador.

### Graminha perto do jogador

Não é modelo do Blender: o `GramaPertoDoJogador` monta um tufo de sete folhas finas e
opacas em código, e repete por MultiMesh em pedaços de 4 por 4 só em volta do jogador.
Opaca de propósito: cartão com transparência custa caro aos milhares. A normal da folha é
sempre para cima, como a do chão; com a normal de verdade, o verso de cada folha ficava
quase preto contra a areia. Onde nasce vem de uma máscara (vermelho densidade, verde
umidade) gravada pelo script do terreno, e na fazenda pelo gerador do mapa.

### Verde e objetos de uso

- **Palmeira**: tronco em gomos alternando `marrom` e `ferrugem`, levemente curvo, com sete
  folhas caídas de três gomos cada. É o verde que combina com deserto.
- **Grama, flores e juncos** seguem o capim: folhas largas de prisma, nunca cone fino.
- **Objetos de uso** (feira, banco, máquina de venda, carro velho, vagonete, feno, varal)
  têm uma cor forte e o resto neutro, como as máquinas das dungeons.

### Construções do mundo

- **Viaduto, comporta, letreiro e outdoor** são as peças altas do mapa e ficam no norte.
- **Neon** de rua segue as cores das dungeons: `magenta` e `azul_claro` nas faixas,
  `amarelo` na luz de poste e nas sinalizações.
- **Água** é uma face `azul` com um ou dois riscos `azul_claro`, rente ao chão. O canal e o
  reservatório "afundam" só na aparência: as bordas sobem 0,3 e seguram o jogador.
- **Casa da fazenda e galpão** usam barro claro (`creme`, `pessego`) e chapa
  (`cinza_metal`, `ferrugem`), com painel solar `indigo` e caixa d'água `azul`.

### Inimigos e chefes das dungeons (máquinas)

São **malha rígida, sem esqueleto**, de propósito: máquina não dobra, e isso dispensa
rig e animação. O modelo é um nó vazio com as partes como filhas, e o nome da parte diz
como o jogo a mexe (`scripts/combat/maquina_animada.gd`):

| Prefixo do nome | O que o jogo faz |
|---|---|
| `Gira...` | roda sem parar em torno do eixo vertical da própria parte (hélice, serra, anel) |
| `Flutua...` | sobe e desce devagar (corpo de drone, núcleo) |
| `Braco...` | recua e desce num golpe quando o inimigo ataca |
| `Corpo`, `Cabeca`, outros | ficam parados em relação ao modelo |

Parte com "Coroa" no nome gira ao contrário e mais devagar. Parte que precisa girar em
torno de outro eixo (o molinete da colheitadeira, as rodas) é modelada ao longo do Z
local e **o objeto** é girado no Blender; o jogo continua rodando no eixo vertical local.

O que deixa a máquina com cara de ameaça sem sair do estilo
(`equipe/ferramentas/blender/modelos/pecas_de_inimigo.py`):

- **Olhar bravo**: um visor aceso partido em duas metades inclinadas para o centro, sobre
  uma placa `grafite`. É a sobrancelha franzida. Sozinho já muda o personagem.
- **Ponta**: cone de 4 ou 5 lados em ombro, costas e cabeça.
- **Dentes**: fileira de pirâmides brancas numa grelha ou num limpa-trilho.
- **Ferramenta de trabalho virada arma**: serra, prensa, tesoura, seringa, lâmina.
- **Uma cor de corpo forte** (laranja, azul, verde, preto) e o resto `chumbo` e `grafite`.

A frente do inimigo é o lado -Y do Blender, que vira +Z no Godot.

## Como modelar uma peça nova

O caminho é por script, com o kit em `equipe/ferramentas/blender/kit_cyber_moon.py`. Os
modelos existentes estão em `equipe/ferramentas/blender/modelos/`, um arquivo por tema.
Para mudar um modelo, mude a função dele e rode o arquivo de novo; não edite o `.glb`.

```python
def barril():
    m = kit.Modelo("barril")
    m.cilindro(0.2, 0.52, cor="azul", lados=10, degrade=True, cor_das_tampas="chumbo")
    for z in (0.12, 0.36):
        m.cilindro(0.215, 0.04, pos=(0, 0, z), cor="chumbo", lados=10)
    return m.finalizar()
```

O kit tem `caixa`, `cilindro` (que também faz cone e tronco de cone), `esfera`, `prisma`
(extrusão de um contorno, para rampa, cunha e seta) e `malha_de` (copia a malha de um
objeto importado). Toda primitiva recebe `cor`, `degrade` e `brilho`.

Passo a passo:

1. Abra no Blender o modelo existente mais parecido e meça.
2. Escreva a função num arquivo de `modelos/`, acrescente em `MODELOS` e rode o arquivo.
   O `kit.produzir` constrói, exporta para `assets/models/cyber_moon_dungeons/` e
   fotografa o grupo ao lado de um boneco do tamanho do personagem.
3. **Olhe a foto** (`~/.cache/cm_blender/<grupo>.png`). Proporção errada só aparece ali.
4. Rode `godot --headless --path game --import`. No primeiro import de um modelo novo,
   aponte o script de importação no `.glb.import` (o comando está em
   `pipeline_de_assets.md`) e importe de novo.

O nome do arquivo decide o que a importação faz com ele
(`scripts/utils/post_import_kenney.gd` e `scripts/utils/superficies.gd`):

| Começo do nome | Efeito |
|---|---|
| `chao_metal`, `chao_grade`, `chao_tecnologico` | colisão, som de passo de metal |
| `chao_concreto` | colisão, som de pedra |
| `chao_terra`, `chao_grama` | colisão, som de terra ou grama |
| `inimigo_`, `chefe_` | sem colisão (viram filhos de um corpo que se move) |
| `movel_` | sem colisão (a cena que usa a peça tem a própria: porta, baú, gerador) |
| `enfeite_` | sem colisão (o jogador passa por cima: cabo, cipó) |
| qualquer outro | colisão pela malha |

### Editar um modelo que já existe

Modelo editado é salvo **como modelo separado**, com outro nome, no pacote próprio; o
original da Kenney nunca é alterado. A função importa o `.glb`, copia a malha com
`malha_de`, e acrescenta peças:

- Vindo do **industrial**: a UV original serve, porque a paleta é a mesma. Só mudar a
  escala e somar peças (`conteiner_de_manutencao`, `tanque_de_pressao`).
- Vindo de **outro pacote de cidade**: a paleta é outra; repinte tudo com uma cor só e
  acrescente o detalhe por cima (`predio_de_fundo`).
- Vindo do **Nature Kit**: não há UV; passe um dicionário de material para cor
  (`{"leafs": "verde", "wood": "marrom"}`) (`arvore_em_vaso`, `canteiro_hidroponico`).

## Montar um ambiente sem esconder o jogador

A câmera fica atrás e acima do jogador (`deslocamento = Vector3(0, 5, 5)`), olhando do
sul para o norte, e não gira. Um objeto de altura `h` esconde o que está até `h` de
distância atrás dele. Daí as regras das dungeons:

- **Parede alta só ao norte.** A do sul é uma mureta de 0,35.
- **As salas se sucedem de oeste para leste.** Uma sala ao norte da outra ficaria com a
  faixa de baixo escondida atrás da parede que as divide.
- **Peça alta fica encostada na parede do norte.** No meio da sala ela ganha o nó
  `CoberturaTranslucida` (`scripts/world/cobertura_translucida.gd`), que a deixa quase
  transparente enquanto esconde o jogador ou um inimigo.
- **Decoração fica nas bordas.** O miolo da sala é da luta, e os ataques dos chefes
  marcam o chão: piso muito desenhado atrapalha a leitura da marca.

No mundo aberto vale o mesmo, com duas regras a mais:

- **Peça alta ganha a cobertura sozinha.** O gerador põe a `CoberturaTranslucida` em
  toda peça da lista `MODELOS_QUE_COBREM` (casas, prédios, rochedos, palmeiras, caixa
  d'água, ônibus). Peça alta nova entra na lista.
- **O jogador anda por corredores.** Trilha com folga e lugares, como no Stardew Valley.
  A borda do corredor é baixa (pedra, mato, cacto) para não esconder ninguém, e o que é
  alto (rochedo, barraco, poste) fica do lado de fora, como marco à vista do caminho.

## Dificuldades superadas

Em ordem de quanto tempo custaram.

1. **O Blender não mostrava a cena pelo `look`.** O Blender instalado por flatpak tem um
   `/tmp` próprio, e o arquivo da captura nunca chegava ao outro lado. Solução: renderizar
   com `kit.foto()`, que grava em `~/.cache/cm_blender/`, uma pasta que os dois enxergam.
2. **A paleta embutida virava um PNG por modelo.** O exportador glTF do Blender embute a
   imagem, e o Godot extrai uma cópia para cada `.glb`. Solução: exportar sem imagem
   (`export_image_format="NONE"`) e reescrever o JSON do `.glb` para apontar para
   `textures/colormap.png`, como a Kenney faz. Está em `kit._apontar_para_a_paleta`.
3. **Nome de parte repetido virava `Corpo_001`.** O Blender não aceita dois objetos com o
   mesmo nome na cena, e vários modelos têm uma parte `Corpo`. Solução: depois de
   exportar cada modelo, o kit renomeia as partes dele, liberando o nome para o próximo.
   Em jogo, a busca de parte é sempre por começo de nome (`begins_with`), por garantia.
4. **O `.glb` importa com um nó a mais.** O Godot cria um nó raiz da cena e põe o nó vazio
   do modelo embaixo dele. `$Modelo/Tampa` não acha a tampa; o certo é
   `find_child("Tampa", true, false)`.
5. **Face acesa estourava para o branco.** Com emissão cheia, a cor da face soma com a luz
   da cena e o magenta vira branco. Solução: emissão em 0,55 (`FORCA_DO_BRILHO`).
6. **`transparency` não funciona no renderizador Compatibility.** A propriedade do
   `GeometryInstance3D` é ignorada e o objeto continua opaco. A translucidez é feita
   trocando o material por uma cópia em modo alfa só enquanto a peça cobre alguém.
7. **Rotação em `.tscn` escrita à mão.** A matriz do `Transform3D` é fácil de errar. O
   gerador das dungeons grava `position` e `rotation` em vez da matriz, e o Godot aceita.
8. **Verde do Nature Kit em superfície grande.** O turquesa do pacote fica artificial como
   chão. O piso de grama da estufa é uma placa própria, com o `verde` da paleta.
9. **Luz de sala estourando o piso claro.** Com `OmniLight3D` em energia 1,6 o concreto
   ficava branco. Energia 0,8 e alcance 8 deixam a cor da luz aparecer sem lavar a cena.
10. **Cada pacote tem a sua paleta.** A UV de um modelo de outro pacote cai em outra cor.
    Não reaproveite UV entre pacotes; repinte.

11. **Água abaixo do chão some.** O chão do mapa é um plano de areia; a água do canal,
    modelada 0,2 abaixo, ficava escondida debaixo dele. A água agora fica um fio acima do
    chão, e a borda alta é que faz o canal parecer fundo.
12. **Escala de prédio da Kenney no mapa grande.** Em escala 3 as casas da vila sumiam no
    mapa de 160 por 110. Em escala 4 (a mesma do playground antigo) elas leem como
    prédio. Medida pela foto de cima e pela câmera do jogo.
13. **Moto do tamanho certo.** Modelada no tamanho "real", ela ficou menor que o
    personagem, que tem cabeça grande; ampliada em 1,6 virou carro. 1,3 é a medida.
14. **Prédio da Kenney editado pode não ter a frente onde se espera.** A porta e o
    letreiro somados a um galpão do kit industrial ficaram escondidos atrás dele. Quando a
    peça editada é mais de metade acessório, modelar do zero sai mais rápido e mais certo
    (foi o caso da oficina das motoqueiras).

15. **Borda baixa não segura o personagem.** A cápsula tem a ponta arredondada e sobe
    numa borda de 0,3. A água agora tem uma parede invisível por cima, e a borda de
    concreto é só desenho.
16. **Rede de linhas inteira vira piso de pedra.** O primeiro shader de água mostrava todas
    as emendas do ruído celular, e a água parecia um mosaico. Linha fina, mostrada só em
    parte da água por uma máscara, é que lê como reflexo.
17. **Luz própria escrita à mão escurece.** O `light()` customizado deixava a água
    azul-marinho de manhã. O `diffuse_toon` do Godot dá o degrau sem esse problema.
18. **Beira do rio serrilhada.** O barranco tinha 0,7 de largura e a grade do terreno, 1:
    em muitas linhas da grade nenhum vértice caía no barranco, e a beira virava um serrote.
    Três coisas juntas resolveram: barranco mais largo que a grade (o leito ficou mais
    estreito na mesma medida, para as pontes continuarem cobrindo o rio), vértices perto da
    beira puxados para cima da curva, e sombreamento liso só no barranco.
19. **Linha d'água em escadinha.** A água era recortada de uma grade de meio em meio, e a
    beira dela aparecia em degraus onde o barranco a deixava à vista. Virou uma fita que
    segue o rio e um leque no lago, com a beira lisa.
20. **Grama no telhado.** O raio que procura o chão acertava o telhado das casas. Criada a
    camada de física `chao` (a 10), só com o terreno e o chão da fazenda; todo raio de
    assentar procura só nela.
21. **Costela em gomos soltos.** Cilindros curtos em arco deixavam fresta entre os gomos.
    A costela gigante virou um arco de contas facetadas que se sobrepõem.
22. **Folha de grama preta.** Com `cull_disabled`, o verso da folha tem a normal virada e
    fica escuro. A normal da folha é forçada para cima no shader.
23. **Cenário sumindo de uma vez.** O espalhador desenhava a área toda num MultiMesh só,
    com `visibility_range_end`. O Godot mede essa distância até o meio da peça, e o meio
    era o meio do mapa: longe dele, todas as pedras, cactos e a borda sumiam, e a parede
    ficava invisível de verdade. Agora cada espalhador é dividido em blocos de 24 por 24.
24. **Modelo novo sem colisão.** O `.glb.import` de um arquivo novo nasce com
    `import_script/path=""`, e sem o script de pós-importação o modelo vem sem colisão e
    sem a camada `chao`: o jogador atravessou o chão da fazenda e caiu. Todo modelo novo
    do pacote precisa do script, como manda o `pipeline_de_assets.md`. Na dúvida:
    `grep -L post_import_kenney assets/models/*/*.glb.import`.

## O que ainda não foi feito

- O pacote próprio não tem pessoa nem animal. O plano 30 vai editar os personagens da
  Kenney no Blender, mantendo o esqueleto.
- Não há modelo com transparência de verdade (vidro). O vidro da estufa é uma face
  `azul_palido` opaca, como as janelas dos prédios.
- Os inimigos não têm animação de andar: deslizam, flutuam ou rodam. Para máquina com
  roda, hélice ou propulsor isso passa; perna que anda pediria esqueleto.
