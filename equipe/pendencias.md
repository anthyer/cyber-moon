# Pendências

O que ficou de fora, o que precisa de decisão, e o que foi decidido sem consultar
ninguém. É o primeiro arquivo que o Antonio lê quando voltar.

Bernardo: acrescente aqui conforme for executando. Data, o que aconteceu, e por quê.

O que falta de arte e de som (clipe, música, ícone, modelo, animação) fica numa lista só,
em `assets-pendentes.md`.

---

## Deixado pelo Antonio antes de viajar (2026-09-08)

### Precisam de resposta do Bernardo

**Epidemic Sound.** O plano 02 pergunta se você usa a plataforma. Se usar, dá para
configurar o MCP dela e construir os sons restantes pelo agente. Responda antes de
começar o plano 02.

**Clipes de áudio.** O sistema de som roda vazio de propósito, mas o vídeo de entrega
fica muito melhor com passo tocando. O plano 02 diz quantos arquivos, em que formato e
com que nome. Providencie antes de gravar.

### Decisões que o Antonio ainda vai querer revisar

**Três binds mudam de tecla no plano 04.** Inventário sai de I e vai para E (Minecraft),
interagir sai de E e vai para F, e dash sai de Q e vai para Espaço, porque Q vira soltar
item. Está tudo explicado em `controles.md`. É a mudança mais intrusiva de toda a
entrega e é a que ele pode querer discutir.

**Semana de 6 dias.** O calendário do plano 12 usa semana de 6 dias em vez de 7, para a
grade de 30 dias fechar certinho e o sexto dia virar a Folga em que as lojas fecham.
Funciona bem, mas é uma decisão de design que ninguém pediu.

**Nomes das estações.** Brotação, Estiagem, Colheita e Apagão, em vez de primavera,
verão, outono e inverno. Combina com o tema, mas é escolha autoral.

**O elenco de NPCs.** Os seis personagens do plano 14, com nome, idade, papel,
aniversário e gostos, foram inventados do zero, assim como toda a
`biblioteca-de-dialogos.md`. Nada disso estava definido no GDD. É a parte da entrega com
mais liberdade tomada.

**Apagão não tem nenhum cultivo plantável.** É proposital (vira a estação de minerar,
lutar e conversar), mas pode frustrar. É o gancho para estufa.

### Lacunas conhecidas nos planos

**O `SaveManager` está defasado e nenhum plano o conserta.** Ele salva número do dia,
fase da história e marcos, e mais nada. Depois dos 17 planos, vai faltar salvar
inventário, status, relacionamentos, economia, estado da grade de solo e das plantas,
clima e estação. Isso foi deixado de fora de cada plano individual de propósito, porque
salvar tudo de uma vez é mais fácil do que salvar aos pedaços. **Virou o plano 20**
(`equipe/planos/20-salvar-o-jogo.md`, escrito em 2026-10-02), e ele precisa existir antes de qualquer entrega jogável de verdade.

**Não há fabricação.** O plano 03 cria itens processados (composto orgânico,
biocombustível, nutrisolo, chapa reciclada) e o plano 17 os precifica, mas nenhum plano
diz como fabricá-los. É a lacuna mais visível do conjunto. Hoje eles só existiriam como
drop ou compra.

**Não há tela de opções.** O plano 02 cria os buses de áudio que permitiriam controle de
volume, e nada usa. Menu de opções com volume, resolução e binds é trabalho pequeno e
está faltando.

**Nada gera inimigo sozinho.** O plano 09 coloca inimigos à mão numa área de teste. Não
há geração por horário nem por região.

**Não há interior de casa.** Os NPCs param na frente das casas. Cena de interior é um
sistema próprio.

**O jogador não tem modelo próprio.** Continua usando um personagem do pacote Kenney.

### Coisas que aconteceram durante a preparação

**Os hooks anti-IA foram desligados.** Estão em `.git/hooks/` com sufixo `.disabled`,
não foram apagados. Foi decisão do Antonio, para permitir versionar a pasta `equipe/`, o
`CLAUDE.md`, o `.mcp.json` e as skills. Para religar, é só tirar o sufixo.

**As texturas dos cultivos foram recuperadas do cache do Godot.** Durante a organização
dos assets, os PNGs originais em `game/_import/tiny-farm-crops/` foram apagados por
engano antes da cópia. Foram recuperados a partir dos `.ctex` em `game/.godot/imported/`,
que guardavam os dados sem perda (o import era `compress/mode=0`). Os 30 arquivos foram
conferidos um a um visualmente e estão íntegros. Efeito colateral: o `process/fix_alpha_border`
do import original foi aplicado, o que altera o RGB de pixels totalmente transparentes.
É invisível na tela, mas os arquivos não são byte a byte idênticos ao pacote original. Se
isso incomodar, basta baixar o pacote de novo e substituir.

**As texturas estão com `detect_3d/compress_to=0`.** Sem isso o Godot as reimportaria
como VRAM Compressed assim que aparecessem numa cena 3D, borrando pixel art de 16x16. Não
mexa nesse valor.

---

## Registrado pelo Bernardo

<!-- Acrescente aqui. Formato sugerido:

### 2026-09-15, plano 01

**Bugs encontrados na implementação e corrigidos:**

O script `post_import_kenney.gd` aplicava colisão em TODOS os `.glb` do projeto, incluindo
`character_female_f.glb` do pacote kenney_mini_characters. O personagem ficava com
`StaticBody3D` dentro dele. Como esse corpo é filho do `Personagem`, que é filho do `Player`
(CharacterBody3D), o `move_and_slide()` interpretava o contato com o próprio corpo como
"plataforma em movimento" e lançava o player para cima indefinidamente. Correção: adicionar
`"character"` e `"animal"` a `TRECHOS_SEM_COLISAO`.

A lista `TRECHOS_SEM_COLISAO` continha `"grass"`, que casava com `platform_grass.glb` e
`ground_grass.glb` (peças de chão que precisam de colisão). Correção: todo modelo que tem
superfície reconhecida pela tabela de `scripts/utils/superficies.gd` recebe colisão,
independente da lista de exclusão.

**Divergências do plano:**

O plano dizia para colocar o `ChaoBase` em `y = -0.6`. Com os tiles de chão em `y = 0` e o
plano visual `Grama2`/`Grama3` em `y ≈ 0`, o valor -0.6 colocava o player bem abaixo do
visual onde não tem tile. Ajustado para `y = 0` (sem transform no ChaoBase), que alinha com
o piso visual. O spawn do player foi ajustado de `y = 0.136` para `y = 0.5` para garantir
que o player aparece acima de qualquer tile e cai suavemente.

**Tarefa 5 (ajuste andando pelo mapa):** feita em parte. Os bugs acima foram os ajustes
encontrados rodando o jogo, mas o mapa ainda não foi percorrido inteiro encostando em
tudo para achar obstáculo incorreto. O Antonio revisa isso ao voltar.

### 2026-09-15, plano 02

**Decisão:** o `platform_grass.glb` (o `Piso` do playground) toca som de água, por escolha
feita no commit 5f72630. A regra fica em `scripts/utils/superficies.gd`.

### 2026-09-29, plano 03

**Feito.** As decisões e ajustes estão no topo do plano, na seção "Revisão de
2026-09-29". Resumo do que mudou em relação ao texto original:

- Sinal em inglês, `item_picked_up`, e não `item_coletado`.
- O gerador do catálogo é script de linha de comando (`extends SceneTree`), não de editor.
- O item no chão não usa billboard, porque ele anula o giro. Para não virar uma linha
  de lado, o sprite ganhou duas cópias logo atrás (lateral escura e face de trás).
- Ids `moeda` e `servo_motor` viraram `credito` e `servomotor`, e os planos 09, 16 e
  17 foram atualizados junto.
- Sucata ficou na categoria RECURSO. Consumíveis e buquê ganharam valor de venda.
- A coleta virou automática, com ímã, a pedido do Antonio. O plano deixava isso fora de
  escopo. Quando o plano 04 der limite ao inventário, o item que não couber para de
  perseguir o jogador; vale conferir se o comportamento agrada.

**Fica para depois:**

- Os três itens de demonstração perto do spawn (`ItensDeDemonstracao`) existem só para
  teste. Podem sair quando o plano 06 começar a soltar colheita de verdade.
- Os 30 ícones são placeholder. Arte de verdade entra trocando o PNG no `.tres`.
- `Semente.cultivo` está vazio em todas as sementes até o plano 06.

### 2026-09-29, plano 04

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-09-29".

**Fica para depois:**

- Os itens do catálogo não têm descrição. O rodapé do menu mostra o nome e deixa a
  descrição em branco. Vale escrever uma linha por item no gerador do catálogo.
- Armadura e acessório não têm nenhum item. Os espaços existem e aceitam a categoria
  certa, mas só dá para testar quando o plano 08 (ou outro) criar esses itens.
- (Resolvido no plano 05: a lista fixa de ferramentas saiu, e o item na mão é o slot
  rápido selecionado.)
- O slot guarda o espaço de equipamento como `int`, porque o enum está num autoload sem
  `class_name` e não dá para fazer cast dele fora do autoload. Funciona, mas se um dia o
  `InventoryManager` ganhar `class_name`, vale tipar como `Espaco`.

### 2026-09-30, plano 05

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-09-30".

**Fica para depois:**

- Os itens iniciais (cestos e as três ferramentas) estão numa lista de caminhos no
  `EquipmentManager`. O plano 17 dá ao jogador o inventário inicial com sementes; aí essa
  lista vira um Resource de inventário inicial, junto das sementes.
- A barra some durante a pausa, mas o plano também pede que ela suma durante o diálogo.
  Isso fica para o plano 15, que cria o diálogo.

### 2026-09-30, plano 06

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-09-30".

**Temporário, precisa sair depois:**

- A tecla N (`teste_avancar_dia`) e o nó `AtalhosDeTeste` do playground avançam o dia.
  Ficaram depois do plano 10 como atalho de teste (ver a entrada do plano 10).
- As 5 sementes de cada cultura no inventário inicial são estoque de teste. O plano 17
  define o inventário inicial.

**Fica para depois:**

- A planta já murcha por solo seco. Murchar por estação e a checagem de estação no
  plantio são do plano 11.
- A planta madura também murcha se passar um dia sem regar. Foi a leitura literal do
  pedido ("semente ou planta em solo seco"); se for punitivo demais, basta poupar a
  planta madura no `avancar_um_dia`.
- O plantio não tem som próprio. O plano 02 só previu som de ferramenta.
- As plantas não são salvas. Entra no plano de save completo que ainda não existe.
- Os três itens de demonstração do playground saíram, como previsto na pendência do
  plano 03.

### 2026-09-30, plano 07

**Feito**, menos o ajuste dos números jogando (tarefa 8). Decisões e ajustes no topo do
plano, seção "Revisão de 2026-09-30".

**Precisa do Antonio:**

- Jogar e ajustar os custos em `resources/status/custos_padrao.tres` e nos `.tres` das
  ferramentas. A tabela atual é o chute do plano.

**Fica para depois:**

- Desmaiar não tira crédito ainda. Quando o plano 17 criar o `EconomyManager`, ele
  escuta `StatusManager.player_fainted` e desconta.
- Não existe cama: dormir é a tecla temporária N. O plano 10 traz o fim do dia.
- Nada causa dano ao jogador ainda (é o plano 09), então a derrota só foi testada
  chamando `receber_dano` por script.
- Os 3 pães de trigo do inventário inicial são estoque de teste, como as sementes.
- O status não é salvo. Entra no plano de save completo.

### 2026-09-30, plano 08

**Feito.** Decisões e ajustes no topo do plano.

**Temporário, precisa sair depois:**

- Os alvos de treino chegaram a sair no plano 09 e voltaram no mesmo dia, a pedido do
  Antonio, para testar o combate ao lado dos inimigos. Ficam enquanto o combate estiver
  sendo ajustado.
- As quatro armas no inventário inicial são estoque de teste, como as sementes e os pães.

**Fica para depois:**

- Os modelos das armas são bengalas e muleta do pacote de acessibilidade. Trocar por
  modelo de arma é só mudar o campo `modelo` no `.tres` e refazer o encaixe na tabela do
  gerador.
- Só existe um som de golpe (`punch.wav`), usado por todas as armas, inclusive a escopeta.
- Andando com a escopeta, ela aponta para baixo junto com o braço, porque não existe clipe
  de andar segurando arma. Parado, a pose é a de segurar com as duas mãos.
- O gerador do catálogo imprime um erro de compilação ao carregar a cena do projétil,
  porque roda sem os autoloads. As armas saem certas mesmo assim.

### 2026-10-02, decisões do Antonio sobre o que fica para o fim

- **Salvar o jogo:** documentado como plano 20, feito depois dos planos de sistema e
  obrigatório antes de qualquer entrega jogável.
- **Balanceamento:** custos de stamina (plano 07), números dos inimigos (plano 09) e
  cores do dia e da noite (plano 10) são ajustados depois de tudo pronto, numa etapa
  final que está no fim de `ordem-de-execucao.md`.
- **Revisão do combate** (stagger, combos e animações) vai junto do balanceamento final.

### 2026-10-02, sombra e menu de debug

**Sombra otimizada** a pedido do Antonio: distância de 35 m, duas divisões, mapa de 2048
e sem sombra nas peças planas de chão. A cena passou de 145 para 191 quadros por segundo.
O travamento que motivou o pedido era outro: a máquina estava sem memória (swap cheio),
e o jogo caiu para 4 quadros por segundo mesmo sem sombra.

**Atenção para quem já tem o projeto:** a sombra das peças planas é desligada na
importação. Máquina com cache de importação antigo precisa reimportar esses modelos
(ver a skill `rodar-o-jogo`). Sem reimportar, nada quebra, só fica sem esse ganho.

**Fica para pensar depois:** sombra falsa (um círculo escuro) embaixo dos personagens,
como reserva se a versão web pesar, e sombra pré-calculada só se o mapa final ficar
pesado demais, aceitando que as sombras do cenário não acompanham o sol.

**Menu de debug (F3)** criado para testar os recursos. Ação de teste nova entra nele.

### 2026-10-07, plano 16

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-10-07".

**Precisa do Antonio:**

- Confirmar o R3 como botão de soltar e presentear no controle. O plano previa o L2, que
  está ocupado. No painel arcade pode não existir esse botão.
- Jogar e sentir o ritmo: são cerca de 72 dias de jogo até 10 corações com um NPC.

**Fica para depois:**

- O indicador amarelo em cima do NPC considera só a conversa do dia. Ele ainda não avisa
  que dá para presentear, nem que é aniversário.
- A amizade não é salva. Entra no plano 20.
- Nenhum item diz na descrição quem gosta dele, e a aba não mostra os gostos: descobrir é
  de propósito.
- Eventos de coração (cena especial ao atingir certos corações) estão em
  `sugestoes-de-features.md`.
- O buquê ainda não tem onde ser comprado. É do plano 17.

### 2026-10-07, indicador de conversa

**Feito**, a pedido do Antonio. Um balão aparece em cima do NPC quando o jogador está
perto o bastante para conversar: amarelo se ainda há fala nova hoje, branco se a conversa
do dia já aconteceu. Hoje "fala nova" é a única conversa do dia. Quando o plano 16 trouxer
mais de uma fala por dia (presente, aniversário, evento de amizade), a regra do amarelo
mora em `DialogueManager.ja_conversou_hoje` e é lá que ela cresce.

### 2026-10-07, plano 15

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-10-07".

**Precisa do Antonio:**

- Conversar com os seis NPCs e ver se o enquadramento dos modelos atrás da caixa agrada.
  A câmera e os suportes ficam em `scenes/dialogue/caixa_dialogo.tscn`.

**Fica para depois:**

- Só as falas de "Distante" e as de estação aparecem, até o plano 16 trazer a amizade.
- Falas de presente, aniversário e buquê entram no plano 16.
- O modelo do jogador na caixa não mostra o item na mão.
- No controle, a dica da caixa ainda diz "[F] continuar".
- Conversar não está disponível dentro da dungeon (não há NPC lá).

### 2026-10-07, solo arado na chuva fica molhado

**Feito**, a pedido do Antonio. A terra arada com a chuva (ou a tempestade) já caindo
fica molhada sozinha depois de 3 segundos. O tempo é o export
`segundos_para_a_chuva_molhar` da `GradeSolo`. Se a chuva para ou a terra é desfeita
antes do tempo, ela não molha.

### 2026-10-06, planos 21 e 22 (rede, chat e dungeon em coop)

**Feito.** Decisões e ajustes no topo de cada plano, seção "Revisão de 2026-10-06". Como
rodar o servidor e abrir dois jogos está em `backend/servidor_local/leiame.md`.

**Precisa do Antonio:**

- Jogar a dungeon com duas pessoas de verdade. Os testes foram automáticos, com dois
  jogos abertos, mas ninguém apertou o botão de atacar neles.
- Decidir o conteúdo da dungeon (plano 23): salas, chefes, objetivo e recompensa.

**Fica para depois:**

- A AWS: as Lambdas do plano 18 precisam implementar as rotas do plano 21, inclusive as
  de sala, que o plano 18 não previa.
- Login com Google e lista de amigos. Hoje é um nome local e a lista de quem está online.
- O fantoche do outro jogador não mostra a arma na mão nem os tiros.
- Inimigo de distância (a sentinela) não está na dungeon: o projétil não é transmitido.
- A experiência de cada inimigo vai para os dois jogadores, não importa quem bateu.
- Se a conexão do anfitrião cai, a dungeon acaba para os dois.
- Só dois jogadores foram testados.
- O portal é um anel provisório no chão, e a dungeon é uma sala de caixas.

### 2026-10-05, plano 14

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-10-05".

**Precisa do Antonio:**

- Jogar um dia olhando os NPCs e dizer se os horários e os lugares agradam. Os horários
  estão na tabela de `scripts/utils/gerar_npcs.gd`, e os lugares são os marcadores de
  `PontosDeRotina` no playground.
- No mapa final: pôr os marcadores com os mesmos nomes, um nó `RegiaoDeNavegacao` e o
  `ElencoDeNpcs`, e rodar o gerador da malha.

**Fica para depois:**

- A malha não enxerga o que muda com o jogo rodando (um baú posto no chão, no plano 17).
  O NPC preso pula para o próximo ponto do caminho, que é um remendo.
- Os inimigos de teste continuam espalhados pelo mapa, alguns perto do caminho dos NPCs.
  Os dois sistemas não se conhecem.
- NPC não entra em casa: para na frente da porta.
- Os modelos são do pacote Kenney, e um deles vem com bengala.

### 2026-10-05, plano 13

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-10-05".

**Precisa do Antonio:**

- Arranjar um clipe de chuva em loop e um de trovão, e apontar em
  `resources/climas/chuva.tres` e `tempestade.tres` (`som_ambiente` e `som_do_trovao`).
  Sem eles a chuva é muda.
- Olhar a chuva e a tempestade jogando (botões no F3) e ajustar a energia, a névoa e a
  quantidade de gotas nos mesmos arquivos.

**Fica para depois:**

- A sombra do sol fica difusa na chuva e na tempestade (opacidade e desfoque no perfil do
  clima). Pedido do Antonio em 2026-10-05.
- O `clima_de_amanha` já é sorteado, mas nada mostra a previsão.
- O clima não é salvo. Entra no plano 20.
- NPC ficar em casa na chuva é do plano 14.

### 2026-10-05, plano 12

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-10-05".

**Decidido com o Antonio (2026-10-05):** o calendário só abre pelo quadro no mundo, sem
tecla de atalho. O quadro foi testado andando até ele e interagindo.

**Fica para depois:**

- O quadro é feito de caixas, sem modelo. Vai para dentro da casa quando ela existir.
- Os perfis de NPC só têm id, nome e aniversário. O plano 14 completa.
- A leitura da pasta de NPCs está na tela do calendário. Quando o plano 14 ou o 16
  precisarem da mesma lista, ela sobe para um lugar comum.

### 2026-10-02, plano 11

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-10-02".

**Precisa do Antonio:**

- Olhar as quatro estações jogando (botão "Pular para a próxima estação" no F3) e
  ajustar as cores e energias em `resources/estacoes/*.tres`.
- Escolher uma música por estação, se quiser. O campo `musica` dos perfis está vazio, e a
  música padrão continua tocando o ano todo.

**Fica para depois:**

- Os blocos de grama dos modelos da Kenney não mudam de cor com a estação, só os planos de
  grama. No mapa final, vale usar o mesmo material compartilhado no chão todo.
- O período "Anoitecer" do relógio e a velocidade do relógio continuam com as 18:00 fixas.
- A estação não precisa de save próprio: sai do número do dia, que o plano 20 salva.
- Rotina de NPC por estação é do plano 14.

### 2026-10-02, plano 10

**Feito.** Decisões e ajustes no topo do plano, seção "Revisão de 2026-10-02".

**Precisa do Antonio:**

- Jogar um dia inteiro e ajustar as cores e energias da tabela em
  `scripts/core/iluminacao_do_ciclo.gd`. Foram conferidas por captura em cinco
  horários, mas o ajuste fino é de olho, jogando.
- Decidir se a tecla N de avançar o dia sai ou fica como atalho de teste.

**Fica para depois:**

- O horário não é salvo, como o resto do status.
- Desmaiar e cair de sono não tiram crédito. É o plano 17.
- Lua e estrelas no céu estão em `sugestoes-de-features.md`.

### 2026-10-01, malha de navegação (NavMesh)

**Decidido com o Antonio:** o mapa final terá malha de navegação, o mapeamento de onde
os personagens podem andar. Ela entra no plano 14 (rotinas de NPC), que já a previa, e os
inimigos passam a usar a mesma malha para contornar obstáculo em vez de andar em linha
reta (tarefa 6b do plano 14). As decisões e os cuidados estão na nota do topo do plano
14: gerar com o mapa final montado, usar o tamanho da cápsula atual (raio 0,25, altura
0,7) no bake, e tratar à parte os obstáculos que mudam durante o jogo.

### 2026-10-01, revisar armas e combate

**Pendência do Antonio:** revisar no futuro as armas e o combate, com atenção a três
pontos:

- **Stagger.** Hoje quem apanha é empurrado e pisca, mas continua agindo: o inimigo não
  é interrompido no meio do golpe, nem o jogador. Falta um atordoamento curto que corte
  a ação de quem levou o golpe, com peso diferente por arma (o espadão atordoa mais que
  a foice).
- **Combos.** Só o punho tem combo de três golpes. As armas dão um golpe por vez. Falta
  desenhar a sequência de golpes de cada arma.
- **Animações.** As armas usam o clipe de soco do pacote Kenney (`attack-melee-right`),
  a pesada só com ele mais lento. Faltam animações próprias por tipo de arma, e a de
  andar segurando a arma de distância.

Para testar isso, o playground mantém os três bonecos de treino perto do spawn
(`AlvosDeTreino`, que não revidam e mostram o dano) e dez inimigos: seis na
`AreaDeTeste` (z = -15) e quatro espalhados (`InimigosEspalhados`).

### 2026-10-01, auditoria da colisão do plano 01

Conferida com o jogo carregado, a pedido do Antonio:

- **Certo:** 57 tipos de modelo com colisão (prédios, árvores, cercas, pedras, pisos),
  todos na camada `mundo` e com a superfície certa; grama, folhagem, mudas e o planter
  sem colisão, como o Bernardo definiu. A ponte é atravessada nos dois sentidos com a
  subida de degraus. Cercas e prédios barram onde devem.
- **Corrigido:** a cápsula do jogador tinha 1,6 m de altura para um boneco de 0,67 m, e
  batia em copas de árvore e beirais acima da cabeça dele. Eram uns 150 m² de paredes
  invisíveis no mapa. A cápsula do jogador e a dos inimigos passaram a raio 0,25 e
  altura 0,7, e a varredura caiu de 600 pontos para 5 (resíduo de 3 cm). Combate, ímã de
  itens e a ponte foram testados de novo depois da mudança.
- **Para saber:** com a cápsula menor, o jogador passa por baixo de copas e toldos e
  fica escondido por eles na câmera de cima.

### 2026-10-01, plano 09

**Feito**, menos o ajuste dos números jogando (tarefa 9). Decisões no topo do plano.

**Precisa do Antonio:**

- Jogar contra os seis inimigos da `AreaDeTeste` e ajustar os números dos três `.tres`
  em `resources/combat/inimigos/`. A tabela é o chute do plano.

**Descoberto no caminho:**

- Nesta máquina, os modelos estavam sem colisão nenhuma, porque o cache de importação
  (`game/.godot/imported/`) era de antes do plano 01. Foi preciso apagar o cache dos
  `.glb` e reimportar. Quem clonar o projeto de novo, ou tiver cache antigo, precisa
  fazer o mesmo. Está na skill `rodar-o-jogo`.

**Fica para depois:**

- Inimigo andava em linha reta e encostava em parede. Resolvido no plano 14: ele usa a
  malha de navegação.
- Os inimigos não aparecem sozinhos: estão colocados à mão no playground.
- Todo dano usa o `punch.wav`.

### 2026-09-30, partículas

O jogo ganhou um sistema de partículas e o primeiro efeito, a poeira do passo. Por
decisão do Antonio, os efeitos do que já foi feito não entram agora: viraram o plano 19,
que roda depois de todos os planos existentes. Feature nova, escrita depois dele, já
nasce com partículas (a regra está no `CLAUDE.md` e na skill `padrao-cyber-moon`).

### 2026-09-29, remapear controles

**Pendência:** uma tela de remapear controles dentro das configurações do jogo, para
cada jogador ligar qualquer botão a qualquer ação. Fica para quando os menus forem
compostos, junto da tela de opções que ainda não existe (ver "Não há tela de opções"
acima). O remapeamento salvo precisa ser reaplicado ao abrir o jogo.

**Por que ela sozinha não resolve o painel arcade.** O painel de teste (placa DragonRise,
detalhes em `game/docs/entrada.md`, seção "Painel arcade") só funciona inteiro com a
variável `SDL_GAMECONTROLLERCONFIG`, que hoje está gravada apenas no flatpak do Godot
da máquina do Antonio. Sem ela, o SDL descarta parte dos botões antes de o jogo ver, e
um botão que nunca chega não pode ser remapeado. O jogo exportado não herda essa
variável. Para o painel funcionar fora do editor, a tela de remapear precisa vir junto
de uma destas saídas:

- um script de abertura (`.sh` no Linux, `.bat` no Windows) que define a variável e abre
  o jogo;
- o próprio jogo se reabrir com a variável definida, quando detectar a placa na
  primeira abertura (o SDL lê a variável antes de qualquer script rodar, por isso
  defini-la de dentro do jogo não vale para a execução atual). Ainda não testado.

**Duas coisas a conferir quando chegar a hora.** No Windows o GUID do controle é outro,
então a linha de mapeamento precisa ser lida de novo numa máquina Windows. Na versão
web a variável não existe, o controle passa pela API de gamepad do navegador, e um
painel genérico costuma chegar com os números brutos; lá a tela de remapear é a única
saída, e precisa ser testada no navegador.
