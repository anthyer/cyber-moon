# Pendências

O que ficou de fora, o que precisa de decisão, e o que foi decidido sem consultar
ninguém. É o primeiro arquivo que o Antonio lê quando voltar.

Bernardo: acrescente aqui conforme for executando. Data, o que aconteceu, e por quê.

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
salvar tudo de uma vez é mais fácil do que salvar aos pedaços. **Vale um plano próprio só
para isso** (o número 18 ficou com o chat), e ele precisa existir antes de qualquer entrega jogável de verdade.

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
  Saem no plano 10.
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

- Os três alvos de treino do playground (`AlvosDeTreino`) saem quando o plano 09 trouxer
  inimigos.
- As quatro armas no inventário inicial são estoque de teste, como as sementes e os pães.

**Fica para depois:**

- Os modelos das armas são bengalas e muleta do pacote de acessibilidade. Trocar por
  modelo de arma é só mudar o campo `modelo` no `.tres` e refazer o encaixe na tabela do
  gerador.
- Só existe um som de golpe (`punch.wav`), usado por todas as armas, inclusive o rifle.
- Andando com o rifle, ele aponta para baixo junto com o braço, porque não existe clipe
  de andar segurando arma. Parado, a pose é a de segurar com as duas mãos.
- O gerador do catálogo imprime um erro de compilação ao carregar a cena do projétil,
  porque roda sem os autoloads. As armas saem certas mesmo assim.

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
