# Plano 26: Mapa mundi e mapa da fazenda

**Objetivo:** trocar o playground por um mundo de verdade, dividido em dois mapas: o
**mapa mundi** (a vila e os arredores, num deserto rural de periferia cyberpunk) e o
**mapa da fazenda** (a terra do jogador, com talhões próprios para arar).

**Depende de:** acertar o multiplayer primeiro (decisão do Antonio, 2026-10-14). Também
usa o pacote e o kit de modelagem do plano 23 (`game/docs/biblia_3d.md`).

**Situação:** só documentado, em 2026-10-14. Nada foi feito ainda. O primeiro passo,
quando o plano começar, é o mapa de manchas (tarefa 1), para o Antonio aprovar a
divisão das áreas antes de qualquer modelagem.

## O pedido do Antonio (2026-10-14)

- Refazer o mapa mundi com base nos mapas de referência que ele passar. Analisar as
  referências **criticamente**: onde faz sentido ficar cada coisa, o tamanho e as
  dimensões de cada área.
- O jogo tem que rodar bem: o mapa **não pode ser gigante nem denso**, mas tem que ser
  bonito.
- Os assets seguem o estilo das dungeons. O que faltar é modelado no Blender, como no
  plano 23.
- Estilo novo: **área rural de deserto, com cactos**, no espírito dos arredores de Night
  City (as Badlands de Cyberpunk 2077) e da área das motoqueiras de Zenless Zone Zero
  (os Filhos de Calydon, na periferia).
- Antes de modelar, um **mapa de manchas** de cada área, bem simples, pode ser HTML,
  com criatividade.
- Um **mapa específico para a fazenda**, com **áreas específicas onde dá para arar**. O
  arar global sai: só se ara dentro dessas áreas.

## Referência recebida

`~/Área de trabalho/mapa-01.png` (1121 por 672 pixels), no computador do Antonio. É o mapa
de uma vila de jogo de fazenda em pixel art, visto de cima. O arquivo não entra no
repositório (não é nosso); esta seção guarda o que ele ensina.

O que tem nele, de cima para baixo:

- **Norte:** montanhas no canto nordeste, com uma pedreira e um lago de montanha. Uma
  estrada asfaltada desce pelo noroeste e liga o mapa ao resto do mundo (ponto de ônibus
  e acesso à fazenda, que fica fora da imagem, no canto superior esquerdo, com campos
  amarelos).
- **Centro:** a vila. Uma praça de piso cinza com as casas e as lojas em volta, ligada
  por caminhos de terra. Um rio desce da montanha, atravessa a vila de norte a sul e é
  cruzado por pontes.
- **Oeste:** uma faixa de floresta fechada, com um lago e uma clareira de terra (o
  rancho), e um bosque escondido no extremo oeste.
- **Leste:** floresta mais rala e um penhasco que fecha o mapa.
- **Sul:** o mar. Praia, píer e cais na foz do rio; a costa fecha a borda de baixo.

### O que funciona nela

- **Um centro claro.** A praça é o ponto para onde todo caminho converge. O jogador nunca
  se perde, porque sempre sabe onde fica a vila.
- **As bordas são natureza, não muro.** Montanha ao norte, mar ao sul, floresta e
  penhasco nos lados. O limite do mapa parece paisagem.
- **Água organiza o espaço.** O rio divide a vila em bairros e cria pontes, que são
  passagens naturais, e leva da montanha ao mar, ligando as duas pontas.
- **Terraços.** Os desníveis em degrau separam áreas sem precisar de cerca.
- **Cada área tem um marco:** a praça, o píer, a pedreira, o lago, o rancho.
- **A fazenda é um mapa à parte**, com uma porta para o mundo. O mundo não pesa no mapa
  da fazenda, e vice-versa.

### O que não serve para o Cyber Moon

- **Floresta fechada em toda volta.** Em pixel art uma árvore custa um tile; aqui cada
  árvore é um modelo 3D, com sombra. Centenas de árvores derrubam o jogo, ainda mais na
  versão web. O deserto resolve isso por natureza: chão aberto, cactos e pedras
  espalhados em grupos.
- **Mar ao sul e montanha ao norte, sim; o contrário, nunca.** A nossa câmera olha do sul
  para o norte, de cima. Coisa alta na borda de baixo cobriria o jogador. Nisso a
  referência acerta por acaso (o mar é plano e fica embaixo), e o nosso mapa precisa
  manter a mesma regra: tudo que é alto (montanha, mesa de pedra, prédio, viaduto) fica
  ao norte ou nas laterais; ao sul, só coisa baixa.
- **A densidade da vila.** A referência tem casa colada em casa e detalhe em cada tile. Em
  3D, com a câmera mais perto, menos prédios e maiores leem melhor e pesam menos.
- **O rio de água corrente.** No deserto, faz mais sentido um **canal de concreto** (um
  aqueduto de irrigação da corporação) que vem da montanha e acaba num **reservatório**
  ao sul, no lugar do mar. Mantém o papel do rio (divide, cria ponte, liga as pontas) e
  conta a história do lugar: a água é controlada pela corporação.

## Proposta de áreas (para o mapa de manchas)

Primeira versão, para ser discutida no mapa de manchas. Nomes provisórios.

| Área | Onde | O que é | Marco |
|---|---|---|---|
| Vila (centro) | meio do mapa | praça com mercado, ferreiro, clínica, bar de beira de estrada e as casas dos NPCs | um letreiro de neon gigante e um poço de água com bomba solar |
| Canal da corporação | do norte ao sul, cortando a vila | aqueduto de concreto com água, pontes e comportas | a comporta principal, vigiada por um drone parado |
| Rodovia elevada | borda norte | o viaduto que leva a Night City, com a cidade ao fundo como pano de fundo | o ponto de ônibus debaixo do viaduto; a entrada da Galeria de Manutenção (um alçapão de serviço) |
| Badlands | nordeste | mesas de pedra, cactos, a pedreira e a mina | a pedreira, onde se pega minério |
| Acampamento das motoqueiras | leste | ferro-velho, trailers, fogueira, motos, rampa | a oficina das motoqueiras (uma possível loja ou NPC) |
| Fazendas solares e eólicas | oeste | campo de painéis e cata-ventos da corporação, abandonados em parte | o cata-vento quebrado; perto dele, as ruínas do Biodomo Abandonado |
| Reservatório | sul | o lago artificial onde o canal termina, com píer e pesca | o píer e a casa de bombas |
| Saída para a fazenda | noroeste | estrada de terra com porteira | a porteira com a placa da fazenda |

A Torre de Retransmissão fica à vista no horizonte, na cidade atrás do viaduto. As três
dungeons ganham assim um lugar no mundo, em vez de um portal solto.

### Tamanho

- O personagem anda a 3 por segundo e corre a 6. Um mapa de cerca de **160 por 110**
  se atravessa correndo em menos de 30 segundos, a mesma sensação da referência.
- A vila ocupa perto de um terço da largura. O resto é paisagem aberta com grupos de
  objetos nos marcos e chão liso no meio.
- O playground atual tem perto de 40 por 37, para comparar.

### Para rodar bem

- **Dois mapas, duas cenas.** Fazenda e mundo são cenas separadas, com transição pela
  porteira. Só uma fica carregada.
- **Repetição em MultiMesh.** Cacto, pedra, tufo de capim, poste e cerca, que aparecem
  dezenas de vezes, vão num `MultiMeshInstance3D` por modelo: uma chamada de desenho
  para todos.
- **Distância de visibilidade.** Detalhe pequeno some de longe (`visibility_range_end`),
  o que o renderizador Compatibility suporta (o desvanecer, não; some de uma vez).
- **Sombra só no que importa.** Pedrinha, capim e placa de chão sem sombra.
- **Colisão simples.** Caixa ou cápsula nos objetos grandes; nada de colisão por malha em
  centenas de cactos.
- **Orçamento a medir no começo:** quadros por segundo no notebook do Antonio e na versão
  web, com o mapa inteiro em tela cheia.

## Estilo novo: deserto rural cyberpunk

Referências: as Badlands de Cyberpunk 2077 (deserto, mesas de pedra, cata-ventos, postos
de beira de estrada, outdoors, motel de neon, ferro-velho, Night City no horizonte) e a
periferia de Zenless Zone Zero onde vivem as motoqueiras (oficina, trailers, motos,
grafite, faixa de aviso, sol de fim de tarde).

O que já existe e serve: o kit industrial (galpões, tanques, contêineres, painéis solares,
cata-ventos, caixa d'água), o kit de estradas, o kit comercial (prédios para a vila e o
horizonte), o Nature Kit (pedras, cactos não, mas rochas e terra) e o pacote das
dungeons.

O que provavelmente vai precisar ser modelado (lista inicial, no estilo da bíblia):

- Cacto em três ou quatro formas, mesa de pedra (rochedo de topo chato), capim seco,
  chão de areia e de terra batida em placas.
- Canal de concreto em peças (reta, curva, ponte, comporta) e o reservatório (borda e
  píer).
- Viaduto em módulos e o ponto de ônibus.
- Posto de beira de estrada, outdoor de neon, trailer, moto, rampa, pilha de pneus.
- Porteira e placa da fazenda.

## Mapa da fazenda

- Um mapa próprio, menor que o mundo (ordem de 50 por 40, a medir no mapa de manchas),
  com a casa, o baú, a caixa d'água, a cerca e a porteira para o mundo.
- **Talhões:** áreas definidas na cena onde o solo pode ser arado. Fora delas a enxada não
  faz nada. Começa com poucos talhões e pode crescer (comprando terreno, ou por
  aprimoramento), decisão a fechar.
- O chão dos talhões é visivelmente diferente (terra), para o jogador saber onde pode
  plantar sem testar.

### O que muda no código

Hoje a `GradeSolo` aceita arar em qualquer célula dentro de `limite`, um retângulo de 30
por 30 (`scripts/farming/grade_solo.gd`). A ideia:

- Um nó de talhão (por exemplo `TalhaoDeCultivo`, com um tamanho em células) posto na
  cena da fazenda, quantos forem precisos.
- A `GradeSolo` junta os talhões filhos ou do grupo e só aceita `arar` dentro de algum
  deles. `molhar` e `plantar` já dependem de a célula estar arada, então seguem a regra
  sozinhos.
- Save antigo pode ter terra arada fora dos talhões. Decidir: apagar ao carregar ou deixar
  até a planta sair.

## Decisões a fechar com o Antonio

- As áreas e os nomes do mapa de manchas.
- Se o mundo também vira multiplayer, ou se continua só a dungeon. Isso muda o plano
  inteiro: mundo compartilhado precisa sincronizar NPC, loja e clima.
- Se a dungeon passa a ter entrada no mundo (alçapão, ruína, torre) em vez do portal.
- Quantos talhões a fazenda começa e como cresce.
- Se mais mapas de referência vão chegar (o pedido fala em "mapas"; até agora veio um).

## Tarefas

- [x] **1.** (Rascunho em `equipe/mapas/manchas.html`, 2026-10-14; falta o Antonio aprovar.) Mapa de manchas em HTML: cada área como uma mancha colorida, com nome, marco,
  tamanho aproximado e por onde se liga às outras; o mapa da fazenda ao lado, com os
  talhões. Mostrar ao Antonio antes de seguir.
- [ ] **2.** Medir o orçamento: uma cena de teste com o tamanho do mapa e a densidade
  pensada, nos dois alvos (notebook e web).
- [ ] **3.** Talhões na `GradeSolo` e o fim do arar global.
- [ ] **4.** Cena do mapa da fazenda e a transição para o mundo.
- [ ] **5.** Assets novos do deserto no Blender, registrando o estilo na bíblia de 3D.
- [ ] **6.** Cena do mapa mundi, área por área, com MultiMesh na repetição.
- [ ] **7.** Mover NPCs, lojas, portal e camas para os mapas novos; refazer as malhas de
  navegação.
- [ ] **8.** Partículas do que for novo, testes e documentação.

## Partículas

Plano escrito depois da regra de partículas: arar no talhão já tem efeito; o que surgir de
ação nova (atravessar a porteira, por exemplo) nasce com efeito.
