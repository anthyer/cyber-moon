# Plano 39: Escolha do personagem

**Objetivo:** antes de começar um jogo novo, o jogador escolhe com que personagem vai
jogar, entre seis protagonistas feitos para isso: três no corpo tipo 1 e três no corpo
tipo 2. Os seis são modelados no Blender com cuidado de protagonista: precisam se
destacar dos moradores e parecer o herói da história, não mais um da vila.

**Depende de:** 30 (o caminho de editar pessoa no Blender, `kit.Personagem`, e o pacote
`cyber_moon_personagens`; o plano 30 está pronto na worktree
`plano-30-mais-personagens` e precisa estar em main antes deste), 40 (a tela inicial, o
Theme e o palco de modelo), 20 (o save guarda a escolha), 21 e 22 (o outro jogador vê o
personagem escolhido).

**Vem antes de:** 34 (a cena de abertura já mostra o personagem escolhido).

**Situação:** registrado em 2026-11-03, a pedido do Antonio. Falta fazer.

## O pedido do Antonio (2026-11-03)

- O jogador seleciona o personagem antes do jogo.
- Seis opções: três com corpo masculino e três com corpo feminino.
- **No jogo, isso é "tipo 1" e "tipo 2", sem citar gênero** em lugar nenhum da tela.
- Os modelos são criados no Blender, com cuidado extra para parecerem protagonistas de
  verdade.

## Regras

- **Nenhuma palavra de gênero no jogo.** A tela diz "Corpo: Tipo 1 / Tipo 2". Os
  identificadores também não usam gênero: `body_type` com os valores `1` e `2`, e o
  visual por id (`protagonista_1a`, `protagonista_2b`). O nome do arquivo base da
  Kenney (`character_male_*`, `character_female_*`) só aparece no script do Blender.
  Tipo 1 sai das bases `male`; tipo 2, das bases `female`.
- **As falas continuam neutras.** O jogador não é chamado no masculino nem no feminino
  (nada de "bem-vindo", "cansado", "o novo fazendeiro"). A biblioteca de diálogos hoje já
  é neutra quase toda; este plano passa por ela inteira e corrige o que escapou, e a
  regra entra no `leiame.md` das personas. Mensagem de sistema também ("Você apagou",
  não "Você desmaiou cansado").
- **O tipo não muda nada na mecânica.** Vida, stamina, golpe, animação e preço são os
  mesmos. Só o visual muda.

## Como fazer um protagonista (o cuidado extra)

Os doze modelos da Kenney já estão todos em uso pelos moradores (planos 14 e 30), então o
protagonista não pode ser só uma base com outra cor: ficaria parecendo morador. O que faz
ele parecer protagonista:

1. **Uma marca que só o jogador tem.** Os seis carregam nas costas a **mochila de campo**:
   um tanque pequeno de água com mangueira, uma placa de bateria e uma luz de status.
   O jogo é visto de cima e por trás, então as costas são o que mais aparece. Nenhum
   morador usa mochila. É a silhueta do herói: em qualquer canto da tela, de longe, dá
   para achar o jogador.
2. **Uma cor de destaque reservada.** O neon do jogador é o **verde-broto** (a cor da
   planta que nasce, que liga a fazenda ao neon), na luz da mochila e em um detalhe do
   visual. Nenhum morador usa esse verde aceso. Antes de fixar, conferir as cores de
   `personagens.py` do plano 30; a cruz verde da Iara precisa ficar num tom bem
   diferente, ou a cruz muda.
3. **Silhueta própria por opção.** Cada um tem uma peça grande na cabeça ou nos ombros
   que muda o contorno (chapéu, capuz, gola alta, ombreira, rabo de cabelo preso). Peça
   pequena some quando a câmera está longe.
4. **Mais contraste.** O protagonista usa o contraste mais forte da paleta (roupa média e
   detalhe claro), enquanto os moradores ficam nos tons gastos. Na tela, o jogador é a
   figura mais legível.
5. **Mesma escala dos moradores.** Nada de deixar maior: o jogo inteiro (portas, móveis,
   colisão) está na escala da Kenney.
6. **Peça só no osso da cabeça e do tronco.** É a regra do plano 30: peça abaixo da
   cintura atravessa a perna andando. A mochila vai no `torso`.

### As seis propostas (para o Antonio aprovar)

Os nomes de visual são os da tela. A base é a sugestão de partida; pode trocar se, na
foto, ficar parecido demais com algum morador.

| id | Tipo | Visual | Base sugerida | Peça de silhueta | Detalhe verde-broto |
|---|---|---|---|---|---|
| `protagonista_1a` | 1 | **Palha** | `male_e` | chapéu de palha de aba larga com faixa de LED | a faixa do chapéu |
| `protagonista_1b` | 1 | **Solda** | `male_c` | óculos de solda na testa e gola alta de jaqueta de trabalho | as lentes |
| `protagonista_1c` | 1 | **Capuz** | `male_d` | capuz largo sobre um fone de antena | o fone |
| `protagonista_2a` | 2 | **Lenço** | `female_d` | lenço longo no pescoço caindo nas costas e boné virado | a costura do boné |
| `protagonista_2b` | 2 | **Visor** | `female_e` | visor de uma peça e rabo de cabelo alto preso | o visor |
| `protagonista_2c` | 2 | **Ombreira** | `female_f` | ombreira de sucata num ombro só e bandana | a ombreira |

Todos: mochila de campo nas costas, roupa de trabalho de fazenda (jeans, lona, couro,
oliva) com o contraste forte, e as animações da Kenney intactas.

### Como modelar

- Os seis saem de `equipe/ferramentas/blender/modelos/protagonistas.py`, com
  `kit.Personagem` (ver `game/docs/biblia_3d.md`, "Editar uma pessoa", que entra em main
  com o plano 30). A mochila é uma função do kit (`mochila_de_campo(cor)`) usada pelos
  seis.
- Exportam para `assets/models/cyber_moon_personagens/protagonista_<id>.glb`.
- **Fotos de aprovação:** cada um de frente, de costas e de cima (a câmera do jogo), e
  uma foto dos seis em fila **ao lado dos moradores**. A pergunta da foto é: dá para
  achar o protagonista na fila em um segundo? Se não, a silhueta ou o contraste não
  está bom. Mandar as fotos ao Antonio antes de seguir.
- Abrir no jogo e olhar de longe, de dia e de noite (a noite do plano 37, com Lua cheia
  e nova), e conferir que a luz da mochila aparece.
- Registrar na bíblia de 3D a seção "Protagonistas", com a mochila e a cor reservada.

## A tela de escolha

Entra pelo "Novo jogo" da tela inicial (plano 40), antes da abertura (plano 34).

- O modelo grande no meio, no palco de modelo do plano 40, tocando `idle`, girando com o
  mouse ou o direcional direito.
- Em cima, **Corpo: Tipo 1 / Tipo 2**, duas abas.
- Embaixo, os três visuais do tipo escolhido como três cartões com o nome (Palha, Solda,
  Capuz). Trocar de cartão troca o modelo na hora.
- Um campo de nome para o jogo offline. Com conta online, o nome é o da conta (plano 36)
  e o campo vem preenchido e travado.
- "Começar" e "Voltar". Ao confirmar, o personagem acena (`interact` ou o clipe mais
  parecido do pacote) e solta partícula verde-broto antes de a tela fechar.
- Teclado e mouse e controle, pelo `InputManager`.
- Fazer o mock desta tela em `equipe/mocks-de-interface/` antes de montar no Godot, no
  mesmo estilo das outras.

## Dados

- `Resource` nova `PerfilProtagonista` (`scripts/` na pasta dos dados do jogador), um
  `.tres` por visual em `resources/protagonistas/`: `id`, `body_type` (1 ou 2), `nome_do_visual`
  ("Palha"), `modelo` (o `.glb`). Nada de tabela no código.
- O save (plano 20) guarda o `id` do protagonista e o nome. O `player.tscn` deixa de ter o
  modelo fixo: o jogador monta o modelo do perfil ao entrar. Save antigo, sem o campo,
  usa `protagonista_2c`, que é a base `female_f` de hoje, e ninguém percebe a troca.
- Na rede (planos 21 e 22), a escolha vai junto da entrada do jogador; o
  `jogador_remoto.tscn` monta o mesmo modelo. Isso fecha a linha "Modelo do outro jogador
  na dungeon" de `assets-pendentes.md`.
- A conversa, a aba de equipamento e o desmaio usam o modelo escolhido (todos passam
  pelo palco de modelo do plano 40).

## Passos

- [x] **1.** Plano 30 em main (o `kit.Personagem` e o pacote `cyber_moon_personagens`).
- [x] **2.** Mochila de campo e a cor verde-broto no kit; um protagonista de prova
  (`protagonista_1a`) com foto ao lado dos moradores. Ajustar até passar no teste da
  fila. **Mostrar ao Antonio.**
- [x] **3.** Os outros cinco, com as fotos de aprovação dos seis.
- [x] **4.** `PerfilProtagonista` e os seis `.tres`; o jogador montando o modelo do perfil;
  o campo no save com o padrão para save antigo.
- [ ] **5.** Mock da tela de escolha e, aprovado, a tela no Godot.
- [x] **6.** Rede: a escolha chega no outro jogador.
- [x] **7.** Passar pela biblioteca de diálogos e pelas mensagens de sistema tirando
  qualquer flexão de gênero para o jogador; a regra no `leiame.md` das personas.
- [ ] **8.** Partícula ao confirmar (sinal no `EventBus`, ação no `EfeitosDoJogo`).
- [ ] **9.** Rodar: jogo novo com cada um dos seis, olhar de perto e de longe, de dia e de
  noite, na conversa e na aba de equipamento; carregar um save antigo; entrar em dois
  jogadores com visuais diferentes.

## Fora de escopo

- Escolher cor de pele, cabelo e roupa à parte (o visual é um pacote fechado). Fica
  anotado como ideia para depois.
- Trocar de personagem no meio do jogo.
- Roupa ou peça que se compra.
