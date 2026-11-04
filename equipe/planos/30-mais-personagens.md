# Plano 30: Mais personagens

**Objetivo:** aumentar o elenco de personagens e deixar os que já existem com a cara do
tema cyberpunk de deserto.

**Situação:** feito em 2026-10-27 (ver "Revisão de 2026-10-27", no fim). Elenco aprovado
pelo Antonio em 2026-10-20. Decidido com ele: o elenco novo vem antes do plano 27, porque
a história das dungeons depende de quem a conta.

## Proposta de elenco (2026-10-19, para aprovar)

A ideia: cada dungeon ganha um morador ligado a ela, que pede a missão e conta o pedaço da
história; um deles abre o jogo (plano 34). O fio que atravessa as três é o do plano 27:
a corporação controla a água, as sementes e o sinal, e a vila toma cada um de volta.

| Quem | Idade | Papel | Onde mora | Ligação |
|---|---|---|---|---|
| **Bento Arruda** | 68 | Ex-zelador da Galeria. Conhece os túneis de olho fechado. **Morador chave da abertura.** | Barraco perto da entrada da Galeria | Galeria e a **água**: as máquinas lá embaixo fecharam o registro que levava água às fazendas. É por isso que a fazenda do jogador está seca. |
| **Hélio Tavares** | 55 | Ex-pesquisador do Biodomo. Guardou escondido um caderno com as sementes que a corporação tirou dos agricultores. Troca sementes nativas. | Na cisterna velha | Biodomo e as **sementes** |
| **Dandara "Dada" Reis** | 34 | Líder das motoqueiras. Conhece as rotas até a cidade e o que acontece lá em cima. | Acampamento | Torre e o **sinal**, junto com o Kenji |
| **Lúcia Prado** | 41 | Fiscal da expansão. Vem à vila uma vez por semana, de ônibus. Ex-chefe da Sol. Não é vilã de desenho: acredita no que faz. | Na cidade; aparece no ponto de ônibus | A cara da **corporação** |
| **Téo** | 10 | Criança da vila, sobrinho do Kenji. Corre o mapa inteiro, coleciona osso e lenda. Dá missões pequenas de achar coisas. | Casa geminada, com o Kenji | Missões de morador e o minimapa |

Mais duas motoqueiras sem fala (figurantes no acampamento) para o lugar não ficar vazio.

**Opcional:** **Zeca**, o caminhoneiro, que para na pista sob o viaduto uma vez por
semana e vende coisa rara. Dá vida à pista e uma loja diferente.

**Visual:** todos saem dos personagens da Kenney editados no Blender, mantendo o
esqueleto. Os seis atuais também ganham peças do tema (visor do Kenji, macacão de oficina
do Vitor, jaleco da Iara, capacete do Rafa, lenço e óculos da Sol, avental da Marta).

## Decisões do Antonio (2026-10-20)

- **Entram todos:** Bento, Hélio, Dandara, Lúcia, Téo e o Zeca (o caminhoneiro deixa de
  ser opcional). Mais as duas motoqueiras figurantes.
- **Romanceável novo:** só a Dandara.
- **Abertura:** "tem que ser um residente carismático que dá as boas-vindas". Fica o
  **Bento, mais carismático**: um senhor brincalhão, contador de causo, que recebe o
  jogador na fazenda e conta ele mesmo da água cortada e da Galeria. A ficha dele parte
  daí: o humor é a forma de ele carregar a culpa de ter trabalhado para a corporação
  lá embaixo.

## O pedido do Antonio (2026-10-14)

- Expandir a gama de personagens.
- Personalizar os existentes para a temática.
- Usar o Blender (pelo MCP) para isso.

## O que já se sabe (ver `game/docs/biblia_3d.md`)

- Os personagens são do `kenney_mini_characters`, com esqueleto e animações. A bíblia
  registra a decisão de não modelar pessoa do zero, porque esqueleto e animação à mão não
  compensam. Este plano muda essa conta: o caminho mais barato é **editar** os modelos do
  pacote no Blender mantendo o esqueleto e os pesos (trocar cor, somar peças rígidas
  presas a um osso: óculos de visor, jaqueta, implante, capacete de moto) e salvar como
  modelo novo.
- Peça presa a um osso não precisa de pintura de peso: herda o osso inteiro. É o que
  permite acessório sem refazer animação.
- As motoqueiras do mapa novo (plano 26) e os NPCs da vila são os primeiros candidatos.

## Revisão de 2026-10-27

**Feito.** O que entrou, em quatro partes:

- **Modelos.** Os doze moradores e as duas motoqueiras figurantes saem de
  `equipe/ferramentas/blender/modelos/personagens.py`, no pacote novo
  `assets/models/cyber_moon_personagens/`. Cada um é um personagem da Kenney com a cor de
  partes trocada e peças do tema presas a um osso, com o esqueleto e as 32 animações
  intactos. O kit ganhou a classe `Personagem` e a paleta dos personagens (a da Kenney com
  as cores do tema nas linhas vazias). O passo a passo está na `biblia_3d.md`.
- **Dados.** `gerar_npcs.gd` tem o elenco novo, com rotina, gostos, aniversário, a loja do
  Zeca e as figurantes. O `PerfilNpc` ganhou `mora_fora_do_mapa` (Lúcia e Zeca, que somem
  ao chegar em casa) e `eh_figurante` (só acena). As figurantes ficam em
  `resources/npcs/figurantes/`, fora do calendário e da amizade.
- **Mapa.** O barraco do Bento de frente para a trilha da Galeria, e os pontos de rotina
  novos (`casa_bento`, `porta_da_galeria`, `casa_helio`, `cisterna`, `casa_dandara`,
  `oficina_das_motoqueiras`, `fogueira`, `ponto_de_onibus`, `fim_da_estrada`,
  `parada_do_caminhao`). O Téo mora com o Kenji, na `casa_kenji`.
- **Fala.** Fichas em `equipe/personas/` (bento, helio, dandara, lucia, teo, zeca) e as
  falas na biblioteca. A ficha do Kenji ganhou a irmã (Yumi, mãe do Téo).

Partículas: o aceno da figurante e a chegada e saída do visitante (sinais `npc_waved`,
`visitor_arrived` e `visitor_left` no `EfeitosDoJogo`).

**Divergências do plano:**

- O Blender não respondia pelo MCP (o addon não estava rodando). Tudo foi feito com o
  Blender sem janela, pelo kit, como os outros modelos do projeto.
- O Kenji usava o modelo de policial da Kenney. Ficou com ele, mas o quepe virou gorro
  preto e a farda virou jaqueta.
- O acampamento das motoqueiras estava sem caminho desde o plano 26: o pasto do vizinho
  ficava em cima da trilha, e a oficina do Vitor tampava a boca dela. O pasto desceu para
  o sul da trilha e a oficina recuou 2 para oeste.
