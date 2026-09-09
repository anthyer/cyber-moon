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
salvar tudo de uma vez é mais fácil do que salvar aos pedaços. **Vale um plano 18 só para
isso**, e ele precisa existir antes de qualquer entrega jogável de verdade.

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

O que ficou de fora e por quê.
Decisão que tomei sozinho e qual era a alternativa.
Onde o plano divergia do código real.

-->
