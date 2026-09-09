# Sugestões de features

Antonio pediu sugestões do que pode estar faltando, comparando com os jogos de fazenda e
ação da mesma família. Estão em três grupos, por relação entre o que entregam e o que
custam.

Nenhuma destas está nos 17 planos. Bernardo: se tiver uma ideia durante a execução,
anote aqui em vez de implementar por fora.

---

## As cinco que mais fazem falta

Estas cinco são as que, na minha leitura, mais mudariam a sensação do jogo pelo esforço
que dão.

### 1. Evento de coração

O que Stardew e Harvest Moon fazem e que nenhum outro sistema substitui: ao atingir 2, 4,
6, 8 e 10 corações, uma cena curta dispara num lugar específico e revela alguma coisa
sobre o NPC. É o que transforma barra de afinidade em personagem.

O plano 16 monta toda a infraestrutura (relacionamento, corações, diálogo com filtro por
faixa). O que falta é o gatilho por lugar e a cena. Com a `biblioteca-de-dialogos.md` já
escrita, seriam mais umas 30 falas e um sistema de gatilho simples.

**Custo:** médio. **Impacto:** o maior da lista.

### 2. Fabricação

Os planos 03 e 17 criam e precificam quatro materiais processados e nenhum plano diz como
fabricá-los. É uma lacuna que o jogador vai perceber. Uma bancada na fazenda, um
`Resource` de receita, e uma tela reusando os slots do plano 04.

Fabricação também é o que dá função à sucata de inimigo além de vender, o que amarra o
combate na economia.

**Custo:** médio. **Impacto:** alto, e fecha um buraco que já existe.

### 3. Salvar o jogo de verdade

Está registrado como pendência, mas merece estar aqui também: sem salvar, nada do que os
17 planos constroem sobrevive ao fechar o jogo. É requisito, não melhoria.

**Custo:** médio. **Impacto:** obrigatório.

### 4. Melhoria de ferramenta

Enxada que ara 3 quadrados, regador que molha em área, picareta mais rápida. É a
progressão que faz a fazenda crescer de verdade, porque o gargalo do gênero é sempre
tempo de dia, não dinheiro.

Combina perfeitamente com o Vitor, que é mecânico, e dá função aos minérios.

**Custo:** baixo. **Impacto:** alto.

### 5. Animal de criação

O `kenney_cube_pets` já está importado no projeto e não é usado por nada. Galinha que dá
ovo, vaca que dá leite, com afinidade própria e rotina de alimentar. É meia fazenda que
está faltando, e a arte já está lá.

**Custo:** médio. **Impacto:** alto, e usa asset parado.

---

## Baratas e que rendem muito

Coisas pequenas com retorno desproporcional.

**Previsão do tempo.** O `WeatherManager` do plano 13 já sorteia o clima de amanhã e
guarda em `clima_de_amanha`, sem ninguém usar. Um aparelho na casa que mostra isso custa
quase nada e muda como o jogador planeja o dia.

**Tela de resumo do dia.** Ao dormir, mostrar quanto ganhou, o que foi vendido e o que
aconteceu. Fecha o ciclo do dia com uma sensação de conclusão.

**Coleta automática ao passar por cima.** O plano 03 optou por coleta por botão. Coleta
por proximidade, com o item voando até o jogador, é o padrão do Minecraft e muito mais
gostoso depois de colher 20 quadrados.

**Estufa.** Plantar fora de estação. O apagão sem nenhum cultivo (plano 11) foi desenhado
justamente para isso ser desejável. Uma área com a regra de estação desligada.

**Guardar semente da própria colheita.** Uma fala da Marta já menciona isso. Reduz a
dependência de comprar e dá sensação de fazenda autossuficiente.

**Neve no apagão.** Mesma partícula da chuva com outra textura e outra velocidade. O
sistema do plano 13 já existe inteiro.

**Beep de fala.** Um bipe curto por caractere durante o diálogo, no estilo Animal
Crossing, com o tom variando por personagem. Custa uma linha de código e dá personalidade
a seis NPCs de uma vez.

**Lua e estrelas.** O ciclo de dia e noite do plano 10 já controla o `WorldEnvironment`.
Um céu noturno decente é barato e o jogo se chama Cyber Moon.

**Ataque carregado.** Segurar o botão de ataque para dar um golpe forte. A arma pesada do
plano 08 já tem a estrutura.

---

## Grandes, para depois

Sistemas inteiros. Cada um daria um semestre sozinho.

**Mina ou área de exploração com andares.** É o que Rune Factory e Stardew usam para dar
destino ao combate. Hoje os inimigos do plano 09 ficam num canto do mapa sem propósito.
Uma mina com andares, minério progressivamente melhor e inimigos mais fortes daria função
ao combate inteiro.

**Construção e melhoria da fazenda.** Ampliar a casa, construir celeiro, cercar pasto.
Encaixa direto nos marcos do `GameManager` e é o que o GDD promete quando fala em
"evoluir a fazenda".

**Navegação com desvio de obstáculo para inimigos.** O plano 09 deixou isso de fora e o
inimigo anda em linha reta. O plano 14 já vai configurar a `NavigationRegion3D` para os
NPCs, então metade do trabalho estará feita.

**Festival por estação.** Um evento por estação, com todos os NPCs no mesmo lugar e uma
competição. É o que faz o calendário virar expectativa em vez de contador.

**Missões e linha principal da história.** O `GameManager` tem fases e marcos, e o
`EventBus` tem `city_expansion_blocked` desde o primeiro dia, sem ninguém emitir. O plano
17 finalmente emite, mas nada escuta. Um sistema de missão é o que ligaria a fazenda à
narrativa que o GDD descreve.

**Pesca.** Barato de justificar (tem rio no mapa), caro de fazer bem.

**Interior de casa.** Cena separada por porta, com transição. Necessário para o evento de
coração ficar bom, e para a casa do jogador ser mais que um marcador de spawn.

**Multiplayer local.** O GDD não menciona, e é o tipo de coisa que dobra a complexidade
de todo sistema já feito. Fica registrado como algo a não fazer, a menos que vire
requisito.

---

## O que eu não recomendaria

Para poupar discussão depois.

**Qualidade de item com estrelas.** Multiplica o catálogo por três e o jogador quase não
percebe num jogo de duração curta.

**Fome e sede como barras separadas.** Stamina já cumpre o papel. Barras demais cansam.

**Preço variando com oferta e procura.** Charmoso na descrição, invisível na prática, e
uma fonte inesgotável de bug de balanceamento.

**Durabilidade de arma e ferramenta.** Adiciona gerenciamento sem adicionar decisão
interessante, num jogo em que o recurso escasso já é o tempo do dia.
