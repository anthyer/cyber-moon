# Plano 40: Redesenho da interface

**Objetivo:** refazer todas as telas e a HUD do jogo num visual só, pixel art com cara de
cyberpunk de fazenda, seguindo os mocks aprovados. Hoje cada tela tem o próprio
`StyleBoxFlat` e as próprias constantes de cor; no fim deste plano, todas usam o mesmo
Theme.

**Depende de:** 20 (save, para "Continuar" e "Salvar e sair"). As abas de diário e de
mapa só ganham conteúdo nos planos 32 e 33; aqui elas nascem reservadas.

**Situação:** registrado em 2026-11-03, com os mocks aprovados pelo Antonio. Em execução desde 2026-11-05.

## Os mocks

Estão em `equipe/mocks-de-interface/`. Abra o `index.html` no navegador (ele lê os
arquivos ao lado, então precisa da pasta inteira). Cada tela é desenhada em 960 por 540,
com índice na lateral. A última seção, "Folha de componentes", tem as peças soltas com
todos os estados, e é dela que sai o Theme.

Os textos dos mocks (falas, preços, nomes de missão, nomes dos dias da semana, a cidade
nas opções) são de enchimento, só para ocupar o lugar. O que vale é a estrutura e o
visual. Número e texto de verdade continuam vindo dos `.tres`.

## O pedido do Antonio (2026-11-03)

- Mockar todos os elementos da interface em HTML: refazer os que já existem e criar os
  que faltam (tela inicial, menu de pausa, inventários, conversas, dungeons e o resto).
- Pixel art, criativo no cyberpunk e na fazenda.
- Os retratos de personagem não entram. A interface mostra o **modelo 3D** do personagem,
  como a conversa já faz (2026-11-03).
- Virar uma etapa para executar, com tudo o que foi decidido documentado.

## Decisões (2026-11-03)

### Visual

- **Pixel art.** Fontes de pixel: **Silkscreen** nos títulos, etiquetas e números grandes,
  e **VT323** no texto corrido. As duas são livres (licença OFL), do Google Fonts. Ícone
  16 por 16 desenhado em 32 ou 48, sempre sem filtro (`texture_filter` em nearest).
- **Painel de chapa.** Fundo azul-noite quase opaco, borda de 3 px com uma segunda borda
  escura por dentro, cantos em degrau de pixel (não arredondados) e uma faixa de
  cabeçalho com dois rebites nas pontas. Variantes de borda: neutra, ciano (o que está
  em foco ou aceso), magenta (convite, perigo de ação destrutiva) e ouro (dinheiro, baú
  de venda, recompensa).
- **Barra de vida e de stamina como bateria.** Segmentos de 8 px com vão de 2 px. Vida em
  verde, stamina em ouro, experiência em ciano fina, chefe em ouro na fase 1 e violeta na
  fase 2.
- **Linhas de varredura** discretas por cima da tela, com chave nas opções (desligadas
  por padrão no jogo, ligadas nos mocks só para mostrar).
- **Botão** de chapa com sombra de 3 px embaixo. Focado: borda e texto ciano, fundo
  ciano escuro, brilho e uma seta na frente. Destrutivo ("Salvar e sair") em magenta.
  Desligado em cinza azulado.
- **Tecla na tela** como tecla física clara com sombra, e em ciano quando é a ação
  principal do momento.

### Cores

As cores saem das constantes que os scripts de `game/scripts/ui/` já usam, para o jogo
não mudar de cara de uma hora para outra:

| Papel | Cor |
|---|---|
| Fundo de painel | `Color(0.06, 0.07, 0.12, 0.92)` |
| Borda | `Color(0.25, 0.3, 0.45)` |
| Foco, informação, crítico | ciano `Color(0.2, 0.95, 1.0)` |
| Segurando item, dano, convite | magenta `Color(1.0, 0.25, 0.8)` |
| Dinheiro, preço, item na mão, stamina | ouro `Color(1.0, 0.85, 0.3)` |
| Vida, ganho, cura, o que se tem | verde `Color(0.4, 1.0, 0.5)` |
| Corações, aniversário | rosa `Color(1.0, 0.45, 0.75)` |
| Fase 2 do chefe, desmaio, madrugada | violeta `Color(0.6, 0.36, 1.0)` |
| Aviso, erro, o que falta | âmbar `Color(1.0, 0.7, 0.28)` |
| Texto | `Color(0.92, 0.95, 1.0)` |
| Texto apagado | `Color(0.6, 0.66, 0.8)` |

**Nada vermelho.** Além do dano, que já não podia ser vermelho, saem do vermelho: a hora
de aviso do relógio (`COR_DA_HORA_DE_AVISO`), o gasto de créditos (`COR_AO_GASTAR`), a
recusa da loja (`COR_DA_RECUSA`), o material que falta na bancada (`COR_DE_QUEM_FALTA`) e
a lixeira do inventário. Aviso e falta viram âmbar; a lixeira vira roxo escuro.

**Número de dano:** normal em magenta, crítico em ciano, cura em verde.

### Modelos 3D no lugar de retrato

- Nenhuma tela desenha rosto. Onde aparece personagem, aparece o **modelo 3D** dele num
  palco: `SubViewport` com mundo próprio (`own_world_3d`), câmera, luz e uma luz ciano no
  chão, do mesmo jeito que a `caixa_dialogo.tscn` faz hoje.
- Esse palco vira **uma cena reutilizável** (sugestão: `scenes/ui/palco_de_modelo.tscn`,
  classe `ModelStage`), que recebe o id do personagem e a animação. A caixa de conversa
  passa a usar a mesma cena.
- Onde aparece: na conversa (jogador à esquerda, morador à direita, quem fala aceso e um
  pouco à frente, quem escuta mais escuro), na aba de equipamento (o jogador grande,
  girando com o mouse ou o direcional direito), na aba de relacionamentos (um modelo
  pequeno por cartão), no menu de serviços (o lojista em pé), no desmaio (quem te achou)
  e no diário (quem pediu a missão).
- Onde o espaço é pequeno demais para um modelo (HUD, lobby, aliados na dungeon), fica só
  o nome e um ponto da cor do jogador. Sem retrato.
- Desempenho: a aba de relacionamentos tem até catorze modelos. Se pesar no
  Compatibility, o palco tira uma foto do modelo uma vez (`get_texture().get_image()`) e
  mostra a imagem parada, animando só o cartão focado.

### Telas

| Tela | Cena hoje | O que muda |
|---|---|---|
| Tela inicial | não existe | **Nova.** Logo, cena noturna da fazenda com a cidade atrás, menu (Continuar com o resumo do save, Novo jogo, Jogar em equipe, Opções, Créditos, Sair), a conta conectada no canto, e a Lua e o clima reais do plano 37. |
| Conta online | `tela_de_conta` | Painel ciano de terminal de acesso; o código de confirmação em seis caixas. |
| Opções | não existe | **Nova.** Som (música, efeitos, ambiente), tela (tela cheia, linhas de varredura, tremor ao bater), mundo real (as chaves do plano 37 e a cidade), controles, e "Salvar e sair". Abre da tela inicial e do menu de pausa. O menu de debug (F3) continua, só para a equipe. |
| HUD da fazenda | `barras_de_status`, `hud_relogio`, `hud_creditos`, `barra_rapida`, `destaque_de_interacao`, `hud_chat`, `hud_aviso` | Status no canto de cima à esquerda; relógio à direita com a faixa colorida do dia, ícone do clima e da Lua; créditos embaixo do relógio com o ganho em verde; barra rápida no meio de baixo com o nome do item na mão acima; chat à esquerda, acima da barra; aviso no alto, no meio; minimapa (plano 33) no canto de baixo à direita. |
| Conversa | `caixa_dialogo` | Palco com os dois modelos, caixa embaixo com o nome numa etiqueta ciano, a função do morador, os corações e "F continuar". As escolhas aparecem num painel no alto, no meio, só no fim da fala, para não cobrir os modelos. |
| Serviços e loja | `menu_de_servicos`, `tela_de_loja` | O lojista em pé à esquerda com os serviços; a loja à direita com abas Comprar e Vender, estoque do dia, preço em ouro, cartão do item focado e o saldo depois da compra. Item que não dá para pagar fica apagado. |
| Bancada | `tela_de_aprimoramento` | Armas à esquerda; nível atual e próximo lado a lado, com a diferença em ciano; materiais com "tem / precisa" em verde ou âmbar, e de onde sai o que falta. |
| Baú | `tela_de_bau` | Baú e mochila lado a lado com a mesma grade; o baú de venda tem borda ouro e mostra o valor e a hora em que o Rafa recolhe. |
| Resumo de vendas | `resumo_de_vendas` | Um cupom fiscal de papel do caminhão do Rafa ("Entregas Duarte"), item por item, com o bônus de Lua cheia do plano 37. |
| Desmaio | `tela_de_desmaio` | "SINAL PERDIDO" em violeta com deslocamento de cor, quem te achou (modelo) e quanto custou. Sem vermelho. |
| Menu de pausa | `menu_pausa`, `aba_de_relacionamentos`, `calendario` | **Abas numa fileira só:** Inventário, Equipamento, Relacionamentos, Diário, Mapa, Calendário, Opções. |
| Inventário | aba do `menu_pausa` | Grade da mochila com os slots trancados riscados; barra rápida embaixo; lixeira; cartão do item focado à direita (ícone grande, tipo, descrição, efeito, preço de venda, ação). Estados do slot: normal, focado (ciano), segurando (magenta), na mão (ouro), trancado. |
| Equipamento | aba do `menu_pausa` | Arma na mão, ferramentas, acessório e troféus à esquerda; o modelo do jogador no meio com nível e experiência; os números à direita, com a comparação de troca de arma. |
| Relacionamentos | `aba_de_relacionamentos` | Cartão por morador em duas colunas: modelo, nome, função, corações e as marcas do dia (conversou, presente). Aniversário perto em rosa. Entra o elenco do plano 30. |
| Diário | não existe | Aba reservada; o conteúdo é do plano 32 (o mock mostra como fica). |
| Mapa | não existe | Aba reservada; o conteúdo é do plano 33 (o mock mostra como fica). |
| Calendário | `calendario` | Seis colunas (a semana de seis dias, com a Folga em roxo), a fase da Lua de cada dia (plano 37), aniversário em rosa, eventos em ouro. |
| Lobby e convite | `tela_de_lobby`, `hud_convite` | Cada dungeon é um cartão com a cor do tema, o chefe e o estado (aberta, ou o troféu que falta); a equipe embaixo, com quem está pronto; o convite num painel magenta com barra de tempo. |
| HUD da dungeon | `hud_de_dungeon`, `hud_do_chefe` | Objetivo e sala no canto; aliados empilhados embaixo com vida e stamina; barra do chefe no alto, no meio, com o nome, a fase e os golpes; contador de combo; aviso de golpe forte como losango ouro com "!". |
| Dungeon concluída | não existe | **Nova.** Título de conclusão, o troféu com o que ele abre, o que você levou, a experiência e o que o outro jogador levou; "Voltar para a vila" e "Jogar de novo". Estouro de partícula em ciano e ouro. |

## Decisões fechadas (2026-11-05)

- **Trocar de aba no menu de pausa: Q e E, como no mock.** Só enquanto o menu de pausa
  está aberto; fora dele, Q continua soltando item e E abrindo o inventário. No controle,
  L1 e R1. Ações novas `aba_anterior` e `aba_seguinte` no Input Map (Q e L1, E e R1),
  lidas pelo `InputManager` e documentadas em `entrada.md`. O menu de pausa consome a
  tecla, para ela não soltar item nem fechar o inventário no mesmo quadro.
- **Linhas de varredura desligadas por padrão.** A chave fica nas opções.

## Passos

- [x] **1.** Fontes: baixar Silkscreen e VT323 para `game/assets/fonts/`, com a licença
  OFL junto.
- [x] **2.** O Theme: `resources/ui/tema_cyber_moon.tres` com fontes, painéis
  (`StyleBoxTexture` com o canto em degrau, uma textura de 9 fatias por variante de
  borda), botões, abas, barras e slots. Aplicado no nó raiz das telas. As constantes de
  cor de cada script de `scripts/ui/` saem do script e passam a ser lidas do Theme
  (`get_theme_color`), num lugar só. Registrar em `game/docs/arquitetura.md`.
- [x] **3.** A cena `palco_de_modelo.tscn` e a `caixa_dialogo` passando a usá-la.
- [x] **4.** HUD da fazenda e da dungeon (status, relógio, créditos, barra rápida,
  destaque, chat, aviso, objetivo, chefe, aliados, combo).
- [x] **5.** Conversa, serviços, loja, bancada, baú, resumo de vendas, desmaio.
- [x] **6.** Menu de pausa com a fileira de abas, inventário, equipamento,
  relacionamentos e calendário; as abas de diário e mapa reservadas.
- [x] **7.** Lobby, convite, conta.
- [ ] **8.** Telas novas: tela inicial (vira a cena principal do projeto; "Continuar" só
  aparece com save), opções e dungeon concluída.
- [ ] **9.** Partículas (regra do plano 19): abrir a tela inicial (poeira de estrela),
  confirmar no menu (faísca ciano no botão), concluir dungeon (estouro ciano e ouro),
  comprar e aprimorar (faísca ouro). Sinais no `EventBus`, ações na tabela do
  `EfeitosDoJogo`.
- [ ] **10.** Rodar o jogo e passar por todas as telas no teclado e mouse e no controle,
  em 1152 por 648 e em tela cheia, comparando com o mock. Nada vermelho em lugar nenhum.

## Fora de escopo

- O conteúdo do diário e do mapa (planos 32 e 33).
- A escolha do personagem (plano 39), que usa o Theme e o palco deste plano.
- Interface no celular.
