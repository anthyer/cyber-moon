# Assets pendentes

O que o jogo ainda precisa receber de arte e de som. Em todos os casos o sistema já está
pronto e roda sem o arquivo: ou fica mudo, ou usa um provisório. Entregar o asset é
colocar o arquivo na pasta e apontar o campo indicado, sem mexer em código.

Quem implementar um plano e deixar um asset faltando acrescenta uma linha aqui. Quem
entregar um asset risca a linha (ou apaga) e diz no commit.

Formatos: som em `.ogg` (música e loop) ou `.wav` (efeito curto); ícone em PNG 16 por 16,
pixel art, fundo transparente; modelo em `.glb`. O caminho de importação está em
`game/docs/pipeline_de_assets.md`.

## Som

| O que falta | Hoje | Onde apontar | Plano |
|---|---|---|---|
| Chuva em loop | mudo | `som_ambiente` em `resources/climas/chuva.tres` e `tempestade.tres` | 13 |
| Trovão | mudo | `som_do_trovao` em `resources/climas/tempestade.tres` | 13 |
| Música da Brotação | toca a música padrão | `musica` em `resources/estacoes/brotacao.tres` | 11 |
| Música da Estiagem | toca a música padrão | `musica` em `resources/estacoes/estiagem.tres` | 11 |
| Música da Colheita | toca a música padrão | `musica` em `resources/estacoes/colheita.tres` | 11 |
| Música do Apagão | toca a música padrão | `musica` em `resources/estacoes/apagao.tres` | 11 |
| Golpe de cada arma (cestos, foice, espadão, bastão de choque) | todas usam `punch.wav` | `som_do_golpe` nos `.tres` de `resources/items/armas/` | 08 |
| Tiro da escopeta | usa `punch.wav` | `som_do_golpe` em `resources/items/armas/escopeta_serrada.tres` | 08 |
| Dano no jogador e no inimigo | usa `punch.wav` | a definir junto da revisão do combate | 09 |
| Passo em madeira | usa o de concreto | `clipes_por_superficie` em `resources/audio/passos_padrao.tres` | 02 |
| Passo em metal | usa o de concreto | idem | 02 |
| Passo em pedra | usa o de concreto | idem | 02 |
| Passo em terra | usa o de grama | idem | 02 |
| Música das dungeons (uma por tema) | toca a música da estação | a definir: hoje a dungeon não troca de música | 23 |
| Porta de dungeon abrindo | mudo | a definir junto dos sons de dungeon; o sinal é `EventBus.dungeon_door_opened` | 23 |
| Aviso e impacto de ataque de chefe | mudo | idem; os sinais são `EventBus.boss_engaged` e `boss_attack_landed` | 23 |
| Chefe mudando de fase e caindo | usa `punch.wav` do dano | idem; `EventBus.boss_phase_changed` e `boss_defeated` | 23 |
| Baú de recompensa abrindo | mudo | idem; `EventBus.dungeon_reward_claimed` | 23 |
| Porteira entre a fazenda e o mundo | mudo | a definir; o sinal é `EventBus.map_changed` | 26 |
| Ambiente do deserto (vento, inseto) e do canal (água correndo) | mudo | a definir | 26 |

## Arte 2D

| O que falta | Hoje | Onde apontar | Plano |
|---|---|---|---|
| Ícone da lixeira do inventário | provisório, desenhado no estilo dos itens | `assets/textures/icones_itens/lixeira.png` | avulso |
| Ícones dos 30 itens | provisórios | campo `icone` de cada `.tres` em `resources/items/` (trocar o PNG em `assets/textures/icones_itens/` basta) | 03 |
| Ícones dos três troféus de chefe | provisórios, desenhados no estilo dos itens por `equipe/ferramentas/gerar_icones_de_trofeu.py` | `icone` em `resources/items/especiais/trofeu_*.tres` | 23 |
| Ícones de clima (sol, chuva, tempestade) | provisórios, desenhados no estilo dos itens | `assets/textures/icones_clima/` | 13 |
| Ícone de loja aberta em cima do comerciante | provisório, uma banquinha desenhada no estilo dos itens | `assets/textures/efeitos/indicador_de_loja.png` | 17 |
| Indicador de conversa em cima do NPC | provisório, um balão branco tingido por código | `assets/textures/efeitos/indicador_de_conversa.png` | 15 |
| Balão de conversa dos NPCs | provisório, desenhado no estilo dos itens | `assets/textures/efeitos/balao_de_conversa.png` | 14 |
| Retrato dos doze NPCs | sem retrato | `retrato` em `resources/npcs/*.tres` | 14, 15 e 30 |

## Modelos e animação

| O que falta | Hoje | Onde apontar | Plano |
|---|---|---|---|
| Modelos das armas | bengalas e muleta do pacote de acessibilidade | `modelo` nos `.tres` de `resources/items/armas/`, e refazer o encaixe na mão no gerador do catálogo | 08 |
| Quadro de calendário | feito de caixas | `scenes/world/quadro_calendario.tscn` | 12 |
| Caminhão do Zeca | o Zeca chega e vai embora a pé pela pista, sem caminhão | um modelo novo em `equipe/ferramentas/blender/modelos/` e, para aparecer só no dia dele, um nó que siga a visibilidade do Zeca (`EventBus.visitor_arrived` e `visitor_left`) | 30 |
| Ônibus que traz a Lúcia | ela aparece e some no ponto de ônibus | idem, com o ônibus parando no `ponto_de_onibus` | 30 |
| Acessórios melhores nas pessoas | caixas e cilindros do kit (visor, capacete, boné, avental) | as funções de peça em `equipe/ferramentas/blender/modelos/personagens.py` | 30 |
| Baú (de guardar e de venda) | caixa feita de formas simples, com etiqueta de texto | `scenes/items/bau.tscn` | 17 |
| Portal de saída da dungeon | um anel com luz, feito de formas simples | `scenes/world/portal.tscn` | 22 |
| Prédios da vila no tema do deserto | casas, mercado, clínica e oficina do Vitor são da Kenney, sem mudança | as instâncias em `equipe/ferramentas/gerar_mapas.py` (seção da vila) | 26 e 30 |
| Animação de andar dos inimigos das dungeons | são máquinas de malha rígida: deslizam, flutuam ou giram, sem passo | um esqueleto e clipes nos `.glb` de `assets/models/cyber_moon_dungeons/inimigo_*` e `chefe_*`; o `Inimigo` já toca clipe quando o modelo tem `AnimationPlayer` | 23 |
| Vidro de verdade na estufa | face azul opaca, como as janelas dos prédios | `parede_de_estufa` em `equipe/ferramentas/blender/modelos/biodomo.py` | 23 |
| Modelo do outro jogador na dungeon | um personagem do pacote Kenney, diferente do local | `scenes/coop/jogador_remoto.tscn` | 22 |
| Modelo próprio do jogador | personagem do pacote Kenney | `scenes/player/player.tscn` | sem plano |
| Animação de golpe por tipo de arma | todas usam o soco do pacote Kenney | revisão do combate | 08 |
| Animação de andar segurando a arma de distância | o braço abaixa a escopeta ao andar | revisão do combate | 08 |
