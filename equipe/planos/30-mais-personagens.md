# Plano 30: Mais personagens

**Objetivo:** aumentar o elenco de personagens e deixar os que já existem com a cara do
tema cyberpunk de deserto.

**Situação:** elenco aprovado pelo Antonio em 2026-10-20 (ver "Decisões"); falta fazer. Decidido com ele:
o elenco novo vem antes do plano 27, porque a história das dungeons depende de quem a
conta.

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
