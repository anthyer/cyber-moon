# Biblioteca de diálogos

Falas dos seis NPCs, organizadas para virar `.tres` de `Conversa` e `NoDialogo` na tarefa
7 do plano 16.

## Como funciona

Cada fala vira um `NoDialogo` do jogo. Quem transcreve é o gerador, e não a mão:

```
godot --headless --path game --script res://scripts/utils/gerar_dialogos.gd
```

O formato dos blocos, a lista de condições das falas de situação e as regras de escrita
estão em `equipe/personas/leiame.md`. A ficha de cada personagem está em
`equipe/personas/<id>.md`, e toda fala nova precisa bater com ela.

As faixas de relacionamento, em pontos e em corações:

| Faixa | Corações | mínimo | máximo |
|---|---|---|---|
| Distante | 0 a 2 | 0 | 749 |
| Conhecido | 3 a 5 | 750 | 1499 |
| Amigo | 6 a 9 | 1500 | 2499 |
| Íntimo | 10 | 2500 | 9999 |

Entre as falas que servem para o momento, o jogo escolhe a mais específica (a que tem
mais condições), sem repetir a mesma dentro de uma semana quando há outra que sirva. As
falas de presente, de aniversário e de buquê não entram nessa escolha: são disparadas pelo
evento.

---|---|---|---|
| Distante | 0 a 2 | 0 | 749 |
| Conhecido | 3 a 5 | 750 | 1499 |
| Amigo | 6 a 9 | 1500 | 2499 |
| Íntimo | 10 | 2500 | 9999 |

As falas de estação preenchem `estacoes` e valem em qualquer faixa. As de presente e de
aniversário não entram no sorteio do dia: elas são disparadas pelo evento.

O `DialogueManager` sorteia entre todas as falas que passam no filtro, usando o número do
dia como semente. Quanto mais falas por faixa, menos repetição.

---

## Vitor Alencar

Mecânico da oficina, 45 anos. Ranzinza, prático, fala pouco e com frase curta. Passou a
vida consertando o que a cidade joga fora, e cuida das pessoas do mesmo jeito, sem
avisar. Não confia em nada que venha de lá, incluindo remédio. Não é romanceável.

**Distante**

- Se veio pedir conserto, entra na fila.
- Fazenda nova, é? Boa sorte. O último durou dois meses.
- Não mexe nas peças. Cada uma tem dono.
- Se achar metal por aí, eu compro. O resto não me interessa.
- Ferramenta se limpa no fim do dia. Quem não limpa volta aqui pra eu limpar.

**Conhecido**

- Você aguentou mais que eu apostei. Isso é elogio.
- Peça boa é peça que já foi de alguém. As novas vêm com defeito de fábrica.
- A cidade avança um metro por ano. Ninguém mede, mas eu meço.
- Trouxe sucata? Sempre trouxe. Deixa aí.
- Sua enxada tá com o cabo frouxo. Dá pra ouvir daqui. Aperta isso.

**Amigo**

- Meu pai plantava onde hoje é estacionamento. Aquele ali, o do letreiro azul.
- Consertei o gerador da clínica três vezes esse ano. A Iara acha que é milagre.
- Você trabalha demais. Isso é conselho, não elogio.
- Guardei um servomotor pensando em você. Não pergunta por quê.
- O moleque da antena queimou outro transformador. Dei um usado e falei que ia pro lixo.

**Íntimo**

- Se um dia eu não estiver aqui, a oficina fica com você. Já disse pro Kenji também, mas
  ele não sabe segurar chave inglesa.
- Tem gente que resiste com discurso. Eu resisto consertando o que eles querem que a
  gente jogue fora.
- Você me lembra o velho. Ele também não sabia parar.
- Tenho um caderno com a medida da cidade, ano por ano. Comecei no dia que tomaram a
  terra do velho. Você é a primeira pessoa que sabe.
- Nunca ensinei ninguém direito. Achava que era só olhar e aprender. Senta aí que hoje eu
  explico.

**Por estação**

- Brotação: Chuva boa pra planta, ruim pra ferramenta. Cobre o que for de metal.
- Estiagem: Nessa época a cidade liga mais máquina. Dá pra ouvir daqui, de noite.
- Colheita: Melhor época do ano. Todo mundo tem o que fazer e ninguém vem me encher.
- Apagão: Racionam energia lá e sobra escuridão pra cá. Todo ano a mesma coisa.

**Situações**

- [primeiro_encontro] Você é da fazenda do morro. Vitor. Conserto, compro sucata, e não
  gosto que mexam na bancada.
- [sumido] Você sumiu. A sucata não. Tá empilhada ali esperando.
- [sumido, amigo+] Uma semana sem aparecer. Não pergunto onde. Só avisa da próxima vez.
- [desmaiou_ontem] Soube que te carregaram pra casa ontem. Máquina que roda sem parar
  funde. Gente também.
- [vida_baixa] Você tá em pé por teimosia. Senta nesse banco antes que caia em cima das
  minhas peças.
- [saiu_da_dungeon] Deixa eu ver essa arma. Hm. Lâmina torta, cabo inteiro. Você também,
  pelo jeito.
- [chuva] Tá chovendo e você andando com ferro na mão. Enxuga isso quando chegar.
- [chuva, em:oficina] Goteira em cima da bancada. Vinte anos e eu ainda não consertei o
  meu telhado.
- [tempestade] Com esse tempo ninguém devia estar na rua. Nem você. Vai pra casa.
- [tempestade_ontem] O vento de ontem derrubou coisa pela vila inteira. Hoje é fila na
  porta.
- [folga] Folga é o dia que eu conserto o que é meu. Fica por último, sempre.
- [folga, amigo+] Hoje eu não abro pra ninguém. Você entra porque já tá aqui.
- [vespera_de_folga] Se tem coisa pra consertar, traz hoje. Amanhã eu não abro.
- [manha] Cedo assim? Bom. Quem chega cedo eu atendo primeiro.
- [noite, em:praca] Eu venho aqui toda noite ver quem voltou. Hoje voltou todo mundo.
- [em:praca, tarde] Esse banco é meu faz vinte anos. Pode sentar. Só não conversa muito.
- [aniversario] Hoje? É um dia. Tem bancada pra arrumar igual a ontem.
- [aniversario_de:kenji, conhecido+] O moleque faz anos hoje. Deixei uma bobina na porta
  da torre. Não conta que fui eu.
- [aniversario_de:marta] A Marta faz anos hoje. Ela conheceu o velho. Leva alguma coisa
  pra ela, que eu não sei fazer isso.
- [primeiro_dia_da_estacao] Estação nova. Troca o óleo, aperta o que afrouxou. Vale pra
  máquina e vale pra você.
- [primeiro_dia_da_estacao, apagao] Começou. Daqui a uma semana tem fila aqui de coisa que
  parou com o frio.
- [primeiro_dia_do_ano] Mais um ano. A cidade andou o metro dela. Eu medi hoje cedo.
- [marco_1, uma_vez] Tão falando da sua fazenda lá no mercado. Chegou foice nova. Se for levar,
  leva a que eu afiei.
- [marco_2, uma_vez] Você tá vendendo mais que fazenda de trinta anos. Tenho coisa mais pesada
  agora. Não é brinquedo.
- [namorando_outro, uma_vez] Reparei que você anda acompanhado. Não é da minha conta. Só trata
  direito.
- [apagao, noite, amigo+] No Apagão o velho acendia lamparina e consertava rádio. Eu
  fazia de conta que dormia e ficava olhando.
- [estiagem, noite, conhecido+] Escuta. Esse ronco é a cidade. Em noite quente vem mais
  alto.
- [colheita, em:oficina, amigo+] Época boa. Você com a colheita, eu com a bancada, e
  ninguém atrapalhando ninguém.

**Presente**

- Amou: Isso aqui é peça de verdade. Onde você achou? Não, deixa. Obrigado.
- Gostou: Serve. Vou dar um jeito nisso aqui.
- Neutro: Hm. Deixa em cima da bancada.
- Não gostou: Pra que eu quero isso?
- Odiou: Guarda essa porcaria. Não entra remédio de cidade na minha oficina.

**Aniversário:** Você lembrou. Ninguém lembra. Obrigado, sério.

---

## Kenji Moura

Técnico de 24 anos que mantém uma rede pirata na torre da antena. Falante, empolgado,
tropeça nas palavras quando anima e pede desculpa no meio. Cresceu ouvindo que a cidade é
o futuro e decidiu provar o contrário usando as ferramentas dela. Romanceável.

**Distante**

- Opa, você é da fazenda nova, né? Legal, legal. Eu sou o Kenji. Da antena.
- Se a sua energia oscilar, não é a cidade. É eu testando coisa.
- Você tem fio óptico? Não? Beleza. Se achar, avisa.
- Desculpa, tô no meio de uma coisa. Depois a gente conversa direito.
- Aquela torre ali fui eu que subi. Sozinho. Demorou onze meses e caiu duas vezes.

**Conhecido**

- A antena caiu de novo. Terceira vez esse mês. Eu juro que dessa vez foi vento.
- Sabia que dá pra ouvir a rede da corporação daqui? Não que eu ouça. Mas dá.
- O Vitor diz que eu não sei segurar chave inglesa. Ele tem razão, mas não fala pra ele.
- Você planta aquelas coisas verdes? Como é que sabe qual é qual?
- Liguei mais uma casa na rede ontem. São trinta e uma. Não cobro, não. Rede é de quem
  usa.

**Amigo**

- Montei um repetidor com peça que o Vitor ia jogar fora. Funciona melhor que o oficial.
- Minha mãe trabalhou lá dentro. Dezoito anos. Saiu com um crachá e nenhum documento.
- Às vezes eu subo na torre só pra ver a fronteira. Daqui parece que a gente tá ganhando.
- Se eu sumir uns dias, é porque tô rastreando uma coisa. Não se preocupa. Muito.
- O Vitor fala que as peças iam pro lixo. Eu sei que não iam. Nunca falei que sei.

**Íntimo**

- Eu construí uma antena pra falar com o mundo inteiro e a única pessoa com quem eu quero
  falar mora a dez minutos daqui.
- Deixei um canal aberto só pra você. Frequência 88.2. Não conta pra ninguém.
- Você é a única pessoa que me escuta falar de rede por mais de dois minutos.
- Eu escuto a rede deles, sim. Procuro o nome da minha mãe em algum registro. Faz anos, e
  nunca achei.
- Meu medo é a antena cair e ninguém notar. Com você por perto eu penso menos nisso.

**Namorando**

- Parei de escutar a rede dos outros de noite. Fico no 88.2. É mais silencioso e eu gosto
  mais.
- Fiz as contas. Da torre até a sua porteira são dez minutos andando. Correndo dá seis.
  Eu testei.
- Contei de você pra minha mãe. Ela perguntou se você come direito. Eu falei que mais do
  que eu.
- Antes eu pedia desculpa toda vez que falava demais. Com você eu esqueço de pedir.
- Um dia eu te levo lá em cima na torre. De noite. Dá pra ver a sua fazenda inteira
  acesa.

**Por estação**

- Brotação: Umidade mata equipamento. Mas o cheiro compensa.
- Estiagem: A torre esquenta tanto que eu já queimei a mão duas vezes.
- Colheita: Todo ano nessa época a interferência aumenta. Deve ser a colheita da cidade.
- Apagão: Menos energia lá, menos ruído aqui. É a melhor época pra escutar longe.

**Situações**

- [primeiro_encontro] Opa! Fazenda nova, né? Eu vi a luz acender lá do alto. Kenji. Sou
  eu que cuido da antena. Desculpa, já falei demais.
- [sumido] Sete dias. Eu contei. Não que eu fique contando. Tá tudo bem com você?
- [sumido, intimo+] O 88.2 ficou mudo a semana inteira. Eu deixei ligado mesmo assim.
- [desmaiou_ontem] Me falaram que você caiu ontem. Caiu mesmo? Você dormiu? Eu sei que
  não sou a pessoa certa pra perguntar isso, mas você dormiu?
- [vida_baixa] Você tá péssimo. Desculpa. Quer dizer, tá machucado. Vai na Iara, vai. Eu
  só sei consertar coisa que tem fio.
- [saiu_da_dungeon] Você foi lá embaixo? E aí, tem sinal? Não, espera. Primeiro: você tá
  inteiro?
- [chuva] Chuva. Cobri tudo com lona, mas lona não é a mesma coisa que telhado, né.
- [chuva, em:torre_antena] Tá ouvindo esse chiado? É água em conector. Eu vou achar qual.
  São quarenta e dois conectores.
- [tempestade] Contei catorze raios desde cedo. Nenhum na torre. Ainda. Eu não tô
  nervoso.
- [tempestade_ontem] A torre aguentou ontem! Balançou, mas aguentou. Perdi só duas
  hastes. Só duas.
- [folga] Folga. Eu nunca sei o que fazer na Folga. Desmontei o rádio de casa. Agora
  preciso montar.
- [folga, conhecido+] O Rafa mora aqui do lado. Na Folga ele dorme até o meio-dia e eu
  escuto pela parede. Parede fina.
- [vespera_de_folga] Amanhã é Folga e a rede fica comigo sozinho. Se cair, cai até eu
  acordar.
- [manha] Bom dia. É dia ainda? Eu dormi umas três horas, então pra mim tá meio
  embaralhado.
- [noite, em:ponte] O sinal pega melhor aqui na ponte que em casa. Ninguém sabe por quê.
  Eu tenho quatro teorias.
- [em:ponte, amigo+] O Rafa vem pra cá descansar as pernas e eu venho falar. Ele não
  escuta metade. É um bom arranjo.
- [apagao, em:mercado] De tarde a torre fica sem energia, aí eu venho pra cá. A Marta acha
  que é pela comida. É pela comida também.
- [aniversario] Hoje é o meu aniversário, olha só. Eu só lembrei porque o relógio da
  torre avisa. Fui eu que programei e esqueci.
- [aniversario_de:vitor, conhecido+] Hoje é aniversário do Vitor. Eu consertei um
  alicate dele faz três semanas pra dar hoje. Ainda tá na minha mochila.
- [aniversario_de:rafa] O Rafa faz anos hoje. Melhorei o rádio dele sem ele pedir. Agora
  pega a fronteira inteira. Ele vai achar que quebrou.
- [primeiro_dia_da_estacao] Estação nova, tabela de interferência nova. Eu refaço tudo
  hoje. Tudo. Vai levar o dia.
- [primeiro_dia_da_estacao, apagao] Começou o Apagão. Escuta. Não, sério, escuta. Tá
  ouvindo o silêncio? É o ruído deles caindo.
- [primeiro_dia_do_ano] Ano novo. A rede fez um ano inteiro sem ficar mais de dois dias
  fora. Ninguém comemora isso. Eu comemoro.
- [marco_1, uma_vez] Passou mensagem sobre a sua fazenda na rede ontem. Três vilas perguntando o
  que você planta. Você tá famoso em onda curta.
- [marco_2, uma_vez] Sabe quanto dado de venda passa pela rede? Bastante. E o seu nome tá em quase
  tudo. Eu não fico olhando. Mas tá.
- [namorando_outro, uma_vez] Ah, fiquei sabendo de vocês. Legal. Legal mesmo. Tô feliz por você, de
  verdade.
- [apagao, noite, amigo+] Em noite de Apagão dá pra pegar rádio de vila que eu nem sabia
  que existia. Tem mais gente do nosso lado do que parece.
- [brotacao, chuva, conhecido+] Eu devia tá bravo com essa umidade toda. Mas olha esse
  cheiro. Lá dentro da cidade não chove, sabia? Eles filtram.

**Presente**

- Amou: Não. Não, não, não. Isso é um núcleo de verdade? Você tem noção do que dá pra
  fazer com isso?
- Gostou: Ó, isso serve demais. Valeu mesmo.
- Neutro: Ah, obrigado. Vou achar um lugar pra isso.
- Não gostou: É uma pedra. É bonita, mas é uma pedra.
- Odiou: Isso fede. Desculpa, mas fede. Leva pra longe da minha bancada.

**Aniversário:** É hoje? É hoje. Eu tinha esquecido e você não. Isso diz alguma coisa.

**Buquê aceito:** Eu ensaiei essa conversa umas quarenta vezes e você chegou primeiro.
Sim. Óbvio que sim.

---

## Rafael Duarte

Entregador, 27 anos. Passa o dia correndo a fronteira com uma mochila nas costas, e
conhece todo mundo dos dois lados pelo que cada um manda e recebe. Bem humorado, direto,
cansado, e faz piada do cansaço para não falar dele. Diz há seis anos que vai juntar
dinheiro e ir embora. Romanceável.

**Distante**

- E aí. Se precisar mandar alguma coisa pra fora, eu levo.
- Fazenda nova? Anota o endereço direito que eu erro os dois primeiros meses.
- Correndo, correndo. Depois eu paro.
- Você não viu um pacote azul por aí, viu? Não? Beleza. Problema meu.
- Se chegar caixa pra você, eu deixo na porta. Se não tiver ninguém, eu deixo na porta do
  mesmo jeito.

**Conhecido**

- Hoje eu fiz o trajeto do rio duas vezes. Duas. Minhas pernas te odeiam.
- A ponte tá cedendo. Todo mundo sabe e ninguém conserta.
- Se você quiser mandar produto pra dentro da cidade, dá. Não é legal, mas dá.
- Já vi fazenda que durou trinta anos virar depósito em três meses. Não fica confortável.
- A Marta separa um pão pra mim todo dia e finge que sobrou. Eu finjo que acredito.

**Amigo**

- Eu conheço cada buraco desse caminho. Fecho o olho e chego.
- Entreguei uma carta pra Sol semana passada. Selo corporativo. Ela não abriu na minha
  frente.
- Meu plano era juntar dinheiro e sair daqui. Faz seis anos que é o plano.
- Guarda um pouco daquele pão pra mim? Eu como correndo, mas eu como.
- A Iara diz que estimulante me mata antes dos quarenta. Eu digo que sem ele eu não chego
  no fim da rota. A gente empata.

**Íntimo**

- Todo dia eu passo por aqui e todo dia eu ando mais devagar nesse trecho. Já reparei.
- Descobri que não quero sair daqui. Quero ter pra onde voltar. É diferente.
- Se um dia eu parar de correr, é aqui que eu paro.
- Na minha primeira semana de trabalho eu entreguei doze envelopes iguais. Eram avisos de
  despejo. Um era pra minha avó.
- Eu sei o que tem em metade das caixas dessa vila e nunca contei pra ninguém. Pra você
  eu contava.

**Namorando**

- Mudei a rota. Agora a última entrega do dia é sempre pro seu lado. Coincidência nenhuma.
- Hoje eu andei. Andei mesmo, devagar, o trecho todo. Achei estranho e gostei.
- Sobrou espaço na mochila e eu trouxe uma coisa pra você. Não é encomenda. É minha.
- Eu ainda guardo dinheiro, sabia? Só não é mais pra ir embora.
- Se eu atrasar, me espera. Eu sempre chego, só nunca na hora.

**Por estação**

- Brotação: Lama até o joelho. Adoro e odeio ao mesmo tempo.
- Estiagem: Dá pra fritar ovo no asfalto da via velha. Já tentei. Funciona.
- Colheita: Época boa. Todo mundo manda coisa, e coisa pesada paga mais.
- Apagão: Escurece às quatro e meia e eu ainda tenho seis entregas. Faz a conta.

**Situações**

- [primeiro_encontro] Opa, gente nova. Rafa, entregador. Me fala onde fica a sua porta que
  amanhã eu já erro o caminho.
- [sumido, conhecido+] Olha quem apareceu. Eu passei na sua porta umas cinco vezes. Não
  que eu tenha contado. Foram cinco.
- [desmaiou_ontem] Fiquei sabendo que você apagou ontem. Aqui notícia corre mais que eu.
  Vai com calma hoje.
- [vida_baixa] Você tá com cara de pacote que caiu do caminhão. Passa na clínica antes de
  qualquer coisa.
- [saiu_da_dungeon] Você veio daquele buraco, né? Eu não entrego lá embaixo nem por taxa
  dobrada.
- [chuva] Chuva é desconto de frete que ninguém me pediu. Chego molhado e chego igual.
- [chuva, conhecido+] Com chuva eu levo o dobro do tempo e escuto o dobro de reclamação.
  Você pelo menos não reclama.
- [tempestade] Hoje não tem entrega. Nem eu sou tão doido. Fica em casa também.
- [tempestade_ontem] A tempestade de ontem levou um pedaço da grade da ponte. Agora tá
  cedendo e sem grade. Tá ótimo.
- [folga] Folga. Minhas pernas não sabem o que fazer paradas, então eu fico aqui olhando
  pra elas.
- [folga, amigo+] Na Folga eu escuto o Kenji falando com as máquinas através da parede. É
  quase companhia.
- [vespera_de_folga] Amanhã é Folga, então hoje todo mundo lembra que precisava mandar
  alguma coisa. Todo mundo.
- [manha] Cedo assim eu ainda sou simpático. Aproveita, lá pelas quatro eu só resmungo.
- [noite] A essa hora eu já larguei a mochila. Sem ela eu fico meio torto, repara.
- [em:ponte] Eu paro aqui todo fim de dia. É o único lugar da rota onde ninguém tá
  esperando nada de mim.
- [em:clinica] Trouxe a caixa da Iara. Ela confere item por item e eu finjo que não tô
  com pressa.
- [em:mercado, conhecido+] A Marta recebe a mercadoria, reclama do preço e me dá comida.
  Nessa ordem, todo dia.
- [aniversario] Hoje eu faço anos. Vou comemorar fazendo as mesmas entregas, só que
  assobiando.
- [aniversario_de:kenji] O Kenji faz anos hoje. Vou bater na parede dele três vezes, que é
  o nosso parabéns.
- [aniversario_de:marta, conhecido+] Aniversário da Marta. Ela diz que parou de contar, mas
  todo ano nesse dia eu entrego um pacote pra ela. Não digo de quem é.
- [primeiro_dia_da_estacao, colheita] Começou a Colheita. A partir de hoje minha mochila
  pesa o dobro e eu ganho o dobro. Uma coisa paga a outra.
- [primeiro_dia_da_estacao, apagao] Primeiro dia de Apagão. Daqui pra frente eu faço
  metade da rota no escuro. Ainda bem que eu decorei os buracos.
- [primeiro_dia_do_ano] Ano novo. Mesmo trajeto, mesma mochila, mesma ponte cedendo. Feliz
  ano novo.
- [marco_1, uma_vez] Tão falando da sua fazenda lá do outro lado. Eu escuto nas filas. Falam bem, e
  isso lá é raro.
- [marco_2, conhecido+, uma_vez] Hoje me perguntaram na cidade quem é que produz tanto aqui fora.
  Eu disse que não sabia. Eu sei mentir quando precisa.
- [namorando_outro, conhecido+, uma_vez] Fiquei sabendo de você. Notícia boa corre também. Fico
  feliz, de verdade.
- [apagao, noite, amigo+] Nessa época, de noite, dá pra ver a cidade inteira acesa daqui.
  Eu entrego lá dentro todo dia e de longe ainda acho bonito. Isso me irrita.
- [intimo, em:ponte, noite] Minha avó me trazia aqui pra ver a água. Naquele tempo a ponte
  não rangia. Ou rangia e eu não ouvia.

**Presente**

- Amou: Combustível de verdade? Cara, você acabou de me dar duas horas de vida por dia.
- Gostou: Isso salva o meu dia, sério.
- Neutro: Valeu. Ponho na mochila.
- Não gostou: Peso. É isso que isso é. Peso.
- Odiou: Sucata? Eu carrego coisa o dia inteiro e você me dá mais peso?

**Aniversário:** Ninguém lembra do meu aniversário porque eu nunca fico parado tempo o
bastante. Você lembrou.

**Buquê aceito:** Eu corri esse caminho mil vezes procurando um motivo pra desacelerar.
Achei.

---

## Marta Bueno

Dona do mercado, 58 anos. Direta, calorosa e sem paciência para conversa mole. É a mais
velha da vila e a memória dela: conhece a história de todo mundo e conta quando quer.
Cuida das pessoas dando conselho que ninguém pediu e reparando se elas comeram. Vende
semente e comida. Não é romanceável.

**Distante**

- Bom dia. Semente tá na prateleira do fundo, e o preço tá na plaquinha.
- Você é o da fazenda do morro. Já sei. Aqui todo mundo sabe tudo.
- Primeira safra é sempre ruim. Não desanima com isso.
- Compra semente de estação. Fora de estação não nasce, e você vai vir reclamar comigo.
- Marta. Se precisar de alguma coisa, peça. Se não precisar, não fique parado na frente
  da prateleira.

**Conhecido**

- Vi a sua colheita passando. Tá melhor do que eu esperava de quem chegou agora.
- Tem gente que compra semente e não compra regador. Aí planta e chora.
- Meu marido plantava. Trinta e dois anos. Depois virou isso aqui tudo estacionamento.
- Você come direito? Não parece.
- O Rafa come em pé no meu balcão todo dia e diz que não tem tempo. Tempo de reclamar ele
  tem.

**Amigo**

- Eu abro essa loja há vinte e seis anos e só fecho na Folga. Nem no enterro dele eu
  fechei.
- O Kenji vem aqui comprar comida pronta e acha que eu não vejo que ele não cozinha.
- Guarda semente da sua própria colheita. Não conta pro fornecedor que eu falei isso.
- Eu não fio pra ninguém. Mas se um dia faltar comida na sua casa, você bate aqui. É
  diferente.
- Eu sei quem tá bem e quem tá mal nessa vila pelo que cada um leva pra casa. Você tá
  levando coisa boa.

**Íntimo**

- Você virou parte do lugar. Isso não acontece com todo mundo que chega.
- Quando eu não puder mais abrir, alguém abre. Talvez você. Pensa nisso sem pressa.
- Sabe o que me faz continuar? Ver saco de semente saindo daqui e voltando como comida.
- Ele não durou um ano depois que tomaram a terra. Eu continuei abrindo a porta porque não
  sabia fazer outra coisa. Hoje eu sei que era o certo.
- Minha filha mora lá dentro. Liga no meu aniversário e pergunta se eu já vendi a loja. Eu
  digo que ainda não e mudo de assunto.

**Por estação**

- Brotação: Época boa de venda. Todo mundo acha que esse ano vai ser diferente.
- Estiagem: Se não regar, não colhe. E não adianta vir reclamar da semente.
- Colheita: Agora a vila inteira cheira a comida. É a única época em que eu não reclamo de
  nada.
- Apagão: Nada nasce. Guarde comida e paciência.

**Situações**

- [primeiro_encontro] Então é você na fazenda do morro. Marta. Eu vendo a semente, você
  faz o resto, e a gente se entende.
- [sumido, conhecido+] Sumiu. Eu já ia mandar o Rafa bater na sua porta pra ver se tinha
  gente viva.
- [desmaiou_ontem] Me contaram que você caiu de cansaço ontem. Planta não cresce mais
  rápido porque o dono não dorme, viu.
- [vida_baixa] Olha o seu estado. Vai na clínica agora, e depois volta aqui que eu te dou
  um prato de comida.
- [saiu_da_dungeon] Você tá com cheiro de ferro e de porão. Eu não pergunto onde andou.
  Mas lava a mão antes de pegar na semente.
- [chuva] Chuva boa. Quem plantou ontem tá rindo, quem deixou pra hoje tá olhando pela
  janela.
- [chuva, em:mercado] Dia de chuva o mercado enche de gente que não compra nada, só espera
  passar. Eu deixo. Faz companhia.
- [tempestade] Com esse tempo eu não abro. Tranca a sua porta também e deixa a horta se
  virar.
- [choveu_ontem] Choveu ontem e hoje a vila inteira cheira a terra. É o cheiro que eu mais
  gosto e o único que não dá pra vender.
- [folga] Folga. A porta do mercado fica fechada e eu fico sem saber onde pôr as mãos.
- [folga, amigo+] Na Folga eu cozinho pra uma semana e como sozinha em dois dias. Senta,
  tem panela no fogo.
- [vespera_de_folga] Amanhã eu não abro. Se falta alguma coisa na sua casa, é hoje que
  você lembra.
- [manha] Bom dia. Cedo é quando a semente boa ainda tá na prateleira. Depois só sobra o
  que ninguém quis.
- [noite] A essa hora eu já contei o caixa duas vezes. Dá sempre o mesmo, mas eu conto.
- [em:praca] Eu venho pra praça no fim do dia pra ver quem passa. É assim que eu sei de
  tudo sem perguntar nada.
- [em:praca, tarde] Meio-dia eu fecho uma hora e como aqui. O Vitor senta naquele banco e
  a gente não troca uma palavra. É o melhor almoço da semana.
- [aniversario] Faço anos hoje. Não precisa fazer essa cara, eu não quero festa. Quero que
  a Colheita seja boa.
- [aniversario_de:vitor] O Vitor faz anos hoje e vai fingir que é um dia qualquer. Eu
  conheço ele desde moleque, sempre foi assim.
- [aniversario_de:rafa, conhecido+] Hoje é aniversário do Rafa. Separei um pão maior e vou
  dizer que veio errado na fornada.
- [primeiro_dia_da_estacao, brotacao] Primeiro dia de Brotação. Hoje eu vendo mais semente
  do que no resto do mês, e metade vai ser plantada torta.
- [primeiro_dia_da_estacao, apagao] Começou o Apagão. Nada nasce até a Brotação. Quem
  guardou, come. Quem não guardou, vem falar comigo.
- [primeiro_dia_do_ano] Mais um ano e a porta continua abrindo. Eu não brindo, mas eu
  reparo.
- [marco_1, uma_vez] Tão comentando da sua produção. Eu disse que a semente era minha. Deixa eu ter
  esse gosto.
- [marco_2, conhecido+, uma_vez] Do jeito que você tá vendendo, a cidade vai reparar. Quando
  reparar, não assina nada sem me mostrar antes.
- [namorando_outro, uma_vez] Eu vejo quem anda com quem, e não comento. Só digo que você tá com uma
  cara boa.
- [apagao, noite, amigo+] Nessa época meu marido consertava ferramenta na cozinha e eu
  reclamava da sujeira. Hoje a cozinha tá limpa. Não é melhor.
- [colheita, em:mercado, amigo+] Olha esse balcão cheio. É por isso que eu abro a porta. O
  resto do ano é só espera.
- [intimo, folga] Hoje eu ia ligar pra minha filha. Fiquei com o telefone na mão um tempo.
  Depois fui regar o vaso.

**Presente**

- Amou: Ah, minha filha. Isso aqui é comida de verdade. Vou comer devagar.
- Gostou: Que caprichado. Obrigada.
- Neutro: Obrigada, viu. Deixa aí no balcão.
- Não gostou: Isso é ferro velho. Eu vendo comida.
- Odiou: Tira isso da minha loja. Cheira a queimado e espanta freguês.

**Aniversário:** Na minha idade a gente para de contar. Mas ganhar presente ainda é bom.

---

## Iara Nakamura

Médica da clínica, 29 anos. Calma, observadora, escolhe as palavras. Nasceu na vila,
estudou na cidade e voltou para reabrir a clínica. Atende de graça quem não pode pagar, e
isso a mantém cansada. Detesta estimulante porque passa o dia consertando quem usa.
Romanceável.

**Distante**

- Bom dia. Se estiver machucado, entra. Se não, também entra, mas espera.
- Você é novo aqui. Aparece pra um exame antes de precisar.
- Bebe água. É o conselho médico mais ignorado do mundo.
- Não tenho anestésico essa semana. Tenta não se cortar.
- A clínica é a porta com a luz acesa. Se a luz estiver apagada, bate mesmo assim.

**Conhecido**

- Atendi doze pessoas hoje. Três pagaram. É uma média boa.
- Suas mãos estão calejadas. Isso é bom sinal, quer dizer que você usa elas.
- O Vitor conserta o gerador daqui de graça e finge que foi de passagem.
- Você dorme quanto por noite? Não responde. Já sei pela sua cara.
- Metade do que eu uso de curativo vem da terra. Fibra, composto. O resto eu espero chegar.

**Amigo**

- Estudei na cidade. Voltei porque lá eu tratava executivo e aqui eu trato gente.
- Perdi um paciente mês passado. Chegou tarde demais. Eu ainda penso nisso todo dia.
- Trouxe beterraba? Você lembrou. É a única coisa que eu consigo comer quando tô cansada.
- Quando você aparece aqui sem estar machucado, o meu dia melhora.
- A Marta manda comida quando percebe que eu não almocei. Ela sempre percebe.

**Íntimo**

- Eu cuido de todo mundo. Você é a única pessoa que pergunta como eu estou.
- Tem uma janela na clínica que dá pra sua fazenda. Eu olho mais do que devia.
- Se eu pudesse escolher um lugar pra cansar, era esse. Perto de você.
- Eu receito descanso o dia inteiro e não sei descansar. Com você eu quase consigo.
- Tenho medo de um dia estar cansada demais na hora errada. Nunca falei isso em voz alta.

**Namorando**

- Senta aqui. Hoje eu não sou médica de ninguém por dez minutos.
- Eu sei quantas horas você dormiu só de olhar. E agora eu me importo com o número.
- Deixei a maleta em casa. Você não imagina o que isso significa pra mim.
- Você me pergunta como eu estou e espera a resposta. Ainda tô me acostumando.
- Olhei pela janela da clínica hoje e a sua luz tava acesa. Trabalhei melhor depois.

**Por estação**

- Brotação: Época de alergia. Metade da vila passa aqui espirrando.
- Estiagem: Insolação, desidratação, queimadura. Todo ano igual.
- Colheita: Todo mundo se machuca colhendo com pressa. Vai devagar, por favor.
- Apagão: Frio e pouca comida. É a estação que mais me dá trabalho.

**Situações**

- [primeiro_encontro] Você é quem pegou a fazenda. Iara, da clínica. Espero te conhecer
  bem antes de te atender.
- [sumido] Faz dias que eu não te vejo. Deixa eu olhar pra você primeiro. Inteiro. Bom.
- [sumido, amigo+] Você sumiu. Eu conferi a lista de quem passou na clínica só pra ter
  certeza de que você não tava nela.
- [desmaiou_ontem] Me contaram que você caiu ontem. Quanto você dormiu, quanto comeu e
  quanto trabalhou? Faz a conta comigo.
- [desmaiou_ontem, amigo+] Você desmaiou ontem e hoje tá de pé como se nada. Senta. Isso
  não é pedido de médica, é pedido meu.
- [vida_baixa] Para. Senta aí. Você tá machucado e tá fingindo que não.
- [saiu_da_dungeon] Mostra os braços. As mãos também. Quem volta de lá sempre acha que não
  foi nada.
- [chuva] Com chuva eu não desço pro rio. Fico em casa pensando em quem vai escorregar.
- [chuva, noite, amigo+] Eu gosto de chuva. É o único dia em que eu tenho desculpa pra
  ficar parada.
- [tempestade] Raio e gerador velho não combinam. Deixei a maleta do lado da porta.
- [tempestade_ontem] Depois da tempestade de ontem eu esperava a clínica cheia. Veio pouca
  gente. Ainda bem.
- [folga] Hoje é Folga, mas se for urgente você bate. Eu atendo de pijama mesmo.
- [folga, amigo+] Passei a manhã arrumando a maleta. É o meu jeito de descansar, não ri.
- [vespera_de_folga] Amanhã é Folga. Hoje todo mundo lembra da dor que tava guardando a
  semana inteira.
- [manha, em:clinica] Já tem três pessoas na espera e o dia nem esquentou. Fala rápido,
  mas fala.
- [noite] A essa hora eu devia mandar você dormir. Vou mandar: vai dormir.
- [em:beira_rio] Eu venho pro rio no fim do dia. Aqui ninguém me chama de doutora.
- [em:beira_rio, conhecido+] A Sol e eu ficamos aqui sem falar quase nada. É a melhor
  conversa do meu dia.
- [em:praca] Meu almoço dura o que demora pra alguém precisar de mim. Hoje durou bastante.
- [aniversario] É meu aniversário e eu só lembrei porque o calendário da clínica avisou.
  Trabalhando desde as seis, como sempre.
- [aniversario_de:vitor] Hoje o Vitor faz anos. Vou levar um bolo, e ele vai dizer que não
  come doce. Ele come.
- [aniversario_de:sol, conhecido+] É aniversário da Sol. Ela não contou pra ninguém, então
  eu vou só sentar do lado dela hoje.
- [primeiro_dia_da_estacao, apagao] Começou o Apagão. Se agasalha, come direito e não
  espera piorar pra me procurar. Por favor.
- [primeiro_dia_do_ano] Ano novo. Meu pedido é o mesmo de sempre: que todo mundo chegue a
  tempo.
- [apagao, noite, amigo+] No Apagão a clínica fica no escuro às cinco. Eu atendo com
  lanterna e torço pro gerador do Vitor aguentar.
- [marco_1, uma_vez] Sua fazenda tá rendendo. Dá pra ver, a vila tá comendo melhor. Isso é remédio
  também.
- [marco_2, uma_vez] Chegou um lote inteiro de nanogel essa semana. Alguém pagou sem deixar nome.
  Eu tenho um palpite.
- [namorando_outro, uma_vez] Soube de vocês. Fico feliz, de verdade. Só não esquece de dormir.

**Presente**

- Amou: Nanogel de verdade? Isso vai salvar alguém essa semana. Obrigada, de coração.
- Gostou: Que gentileza. Vou usar hoje mesmo.
- Neutro: Obrigada. Deixa na mesa.
- Não gostou: Não sei bem o que fazer com isso, mas obrigada.
- Odiou: Não. Eu não aceito isso. Você tem ideia de quantas pessoas eu vi por causa
  dessas coisas?

**Aniversário:** Eu tinha esquecido que era hoje. Trabalhando desde as seis. Obrigada por
lembrar por mim.

**Buquê aceito:** Eu passo o dia cuidando de todo mundo e nunca me perguntei quem cuidaria
de mim. Você perguntou primeiro.

---

## Sol Vasques

Ex-analista da corporação, 26 anos. Desertou há dois anos, mora sozinha numa barraca na
beira do rio e passa os dias no mirante. Reservada, irônica, mede o que fala. Sabe
exatamente como a expansão funciona por dentro, e é isso que a assombra. Romanceável.

**Distante**

- Oi. Não precisa puxar assunto por educação.
- A barraca na beira do rio é minha. Não é convite, é aviso pra não chegar sem falar.
- Você planta. Legal. É mais útil que o que eu fazia antes.
- Se aparecer alguém de terno perguntando de mim, você não me viu.
- Eu fico no mirante de dia. Dá pra ver quem chega antes de quem chega me ver.

**Conhecido**

- Eu desenhava mapa de expansão. Sua fazenda estava num deles, com uma data.
- Não me pergunta a data. Sério.
- Do mirante dá pra ver as duas coisas ao mesmo tempo. É didático e é horrível.
- Você é a primeira pessoa que não me perguntou por que eu saí de lá.
- Lá dentro eu media hectare. Aqui eu aprendi que hectare tem dono, cachorro e nome.

**Amigo**

- Eu tinha um apartamento com vista pra nada e um salário que pagava por isso.
- Recebi uma carta com selo deles semana passada. Não abri. Ainda não.
- Sabe o que eu mais sinto falta? De nada. Isso me assusta um pouco.
- Você me deu tomate uma vez e eu chorei sozinha depois. Não pergunta.
- A barraca vaza, o chão é torto e eu durmo melhor do que dormi a vida inteira.

**Íntimo**

- Eu fugi de um lugar que media tudo e vim parar onde ninguém mede nada. Levei dois anos
  pra entender que era isso que eu queria.
- Abri a carta. Era uma oferta de volta. Eu queimei no fogão.
- Eu sei exatamente quanto tempo essa fronteira aguenta. E mesmo assim eu quero ficar.
- Cada pedaço daquele mapa tinha um número. Eu demorei demais pra ver que era gente. Você
  era um dos números.
- Eu subo no mirante pra vigiar a cidade. Ultimamente eu fico olhando pro outro lado.

**Namorando**

- Eu parei de dizer "aqui" como quem tá de passagem. Reparou? Eu reparei.
- Não sei prometer longe. Sei prometer amanhã. Amanhã eu tô aqui.
- Passei a vida calculando quanto falta. Com você eu calculo quanto a gente tem. A conta
  é a mesma e o resultado é outro.
- Pensei em trocar a barraca por parede de verdade. Não ri. É o plano mais ousado que eu
  já fiz.
- Um dia eu te conto a data. Não hoje. Hoje eu só quero ficar do seu lado sem saber de
  nada.

**Por estação**

- Brotação: Lá dentro não tem estação. Só temperatura ajustada. Eu tinha esquecido disso.
- Estiagem: Calor de verdade. Suor de verdade. Ainda me impressiona.
- Colheita: Essa é a estação que eles mais expandem. Aproveitam que todo mundo tá ocupado.
- Apagão: Quando falta luz aqui é porque sobra lá. É literalmente isso.

**Situações**

- [primeiro_encontro] Você é o da fazenda. Eu sei quem você é, vi seu lote num papel. Sol.
  Só isso por hoje.
- [sumido] Você apareceu. Eu não tava contando os dias. Tava, sim.
- [sumido, amigo+] Quando alguém some aqui eu penso logo no pior. Defeito de fábrica. Não
  faz mais isso sem avisar.
- [desmaiou_ontem] Soube que você caiu ontem. Lá dentro chamavam isso de queda de
  produtividade. Aqui eu chamo de burrice. Descansa.
- [vida_baixa] Você tá sangrando e veio conversar comigo. Vai na Iara. Agora.
- [vida_baixa, intimo+] Não aparece assim na minha frente. Eu não sei o que fazer com as
  mãos quando você tá machucado.
- [saiu_da_dungeon] Você esteve lá embaixo. Eu sei quem fabrica aquelas coisas. Não vou
  falar disso hoje.
- [chuva] Lá dentro não chove. Faz dois anos e eu ainda paro pra olhar.
- [chuva, em:beira_rio, conhecido+] A barraca vaza no canto esquerdo. Eu podia consertar.
  Gosto do barulho.
- [tempestade] Do mirante dá pra ver: a cidade inteira acesa e aqui caindo a luz. Hoje eu
  nem subi.
- [choveu_ontem] O rio subiu com a chuva de ontem. Chegou a um palmo da barraca. Eu medi,
  claro que eu medi.
- [folga] Lá não existia folga. Existia "disponibilidade reduzida". Ainda não sei o que
  fazer num dia desses.
- [vespera_de_folga] Amanhã a vila inteira para. Eles nunca param. É uma diferença que eu
  anoto.
- [manha, em:mirante] De manhã dá pra ver a linha direitinho. Onde acaba o cinza e começa
  o verde. Ela andou.
- [noite] De noite a cidade parece bonita daqui. É o truque mais velho deles.
- [em:mirante, conhecido+] Eu subo aqui pra vigiar. Não sei o que eu faria se visse alguma
  coisa, mas eu veria primeiro.
- [em:beira_rio] Fim de tarde é aqui. A Iara senta ali, eu sento aqui, e ninguém pergunta
  nada. Recomendo.
- [em:ponte, estiagem] No calor eu venho pra sombra da ponte. O Rafa passa correndo em
  cima e nunca me vê.
- [aniversario] Hoje eu vim pra praça em vez de subir. Não tem motivo. Tem, mas eu não vou
  dizer qual.
- [aniversario_de:iara, conhecido+] A Iara faz anos hoje e esqueceu, como todo ano. Eu
  lembro. Eu decoro data sem querer.
- [aniversario_de:rafa] Hoje é aniversário do Rafa. Ele me trouxe uma carta que eu não
  queria e não fez uma pergunta. Isso vale um parabéns.
- [primeiro_dia_da_estacao, colheita] Começou a Colheita. É quando eles mais avançam. Olha
  pra fronteira de vez em quando, tá?
- [primeiro_dia_do_ano] Mais um ano. Pelas minhas contas de antes, esse lugar nem devia
  estar mais aqui. Gosto de estar errada.
- [apagao, noite, amigo+] No Apagão eu vejo as torres deles brilhando a noite inteira. Eu
  sei de onde vem aquela energia. Vem daqui.
- [colheita, em:mirante, intimo+] A linha andou de novo essa semana. Eu não ia te contar.
  Depois pensei que você prefere saber.
- [marco_1, uma_vez] Sua fazenda tá rendendo mais do que a planilha deles previa pra essa área.
  Isso estraga a conta. Continua.
- [marco_2, uma_vez] Uma fazenda que dá lucro é mais cara de remover. Não é esperança, é
  aritmética. Mas serve.
- [namorando_outro, uma_vez] Fiquei sabendo. Bom pra vocês. Não faz essa cara, eu tô falando sério.

**Presente**

- Amou: Onde você conseguiu isso? Não, esquece. Obrigada. De verdade.
- Gostou: Você prestou atenção. Isso é raro.
- Neutro: Obrigada. Não precisava.
- Não gostou: Hm. Vou fingir que gostei, mas você já percebeu que não.
- Odiou: Isso é feito com sucata processada por eles. Tira da minha frente, por favor.

**Aniversário:** Ninguém aqui sabia disso. Eu nunca contei pra ninguém. Como é que você
descobriu?

**Buquê aceito:** Eu passei dois anos esperando alguém aparecer pra me buscar de volta. E
apareceu você, pra me pedir pra ficar.

---

## Bento Arruda

Ex-zelador da Galeria de Manutenção, 68 anos. Contador de causo, brincalhão, chama todo
mundo de apelido. Mora num barraco colado na entrada da Galeria e varre a porta todo dia,
sem ninguém pedir. Faz a vila rir para ninguém perguntar o que ele fez lá embaixo. Não é
romanceável.

**Distante**

- Fazenda do Tonho, né? Boa terra. Só falta água, adubo e sorte. O resto tem.
- Se for passear por aqui, não desce na Galeria. Lá embaixo nem a luz volta. Isso é causo,
  mas é verdade.
- Bento. Zelador aposentado. Aposentado é jeito bonito de dizer que me mandaram embora,
  hehe.
- Varro essa entrada todo dia. Ninguém pediu. O corpo é que não sabe que acabou o turno.
- Já viu rato do tamanho de cachorro? Eu já. Lá embaixo. Não pergunta o que ele comia.

**Conhecido**

- Lá embaixo tinha um cano que cantava. Quando a pressão subia, saía um assobio afinado.
  Juro.
- O Tonho plantava milho naquela sua terra. Milho alto assim. Depois a água foi embora, e
  o Tonho foi atrás dela.
- Um colega meu conhecia cada válvula da Galeria pelo barulho. Dizia que cada uma tinha
  voz. Pois é.
- Você tá aguentando melhor que o Tonho. Ele reclamava da enxada no segundo dia.
- Trinta e um anos debaixo da cidade, vizinho. Eu sei onde ela guarda a sujeira.

**Amigo**

- Debaixo da vila passava um cano grosso assim, o ramal norte. Levava água pras fazendas.
  Hoje passa vento.
- Um colega fechou um registro uma vez. Ordem de serviço, coisa de rotina. Achou que abria
  no dia seguinte.
- Me chamam de engraçado. É que, se eu parar de falar, eu penso. Pensar cansa mais que
  varrer.
- Guardei um pedaço de madeira bom pra você. Não sei pra quê. Você inventa.
- Moro na porta da Galeria e não desço. Igual cachorro que espera o dono que não volta.
  Essa não é causo.

**Íntimo**

- O colega do registro era eu, vizinho. Fechei, assinei e entreguei o crachá no mesmo
  dia. A água do Tonho fui eu.
- Eu conto causo desde aquele dia. Riso é remédio que não precisa de receita, e eu tomo
  todo dia.
- O registro fica no fundo, atrás da prensa grande. Eu sei o caminho de olho fechado. Só
  não sei descer.
- Você é a primeira pessoa que sabe. Nem a dona Marta. Ela desconfia, mas não sabe.
- Se você um dia for lá embaixo abrir aquilo, me avisa. Eu fico aqui na porta esperando.
  Nem que seja pra ver a água passar.

**Por estação**

- Brotação: No tempo do Tonho, a Brotação era barulho de água correndo nas valas. Agora
  é barulho de enxada em terra dura.
- Estiagem: Essa estação me pega, vizinho. Terra rachada me lembra ordem de serviço. Não
  me pergunta por quê.
- Colheita: Colheita é a minha época. A vila tá ocupada, faço anos, e sobra plateia na
  praça.
- Apagão: No escuro eu enxergo melhor que vocês. Trinta e um anos de lanterna fraca
  ensinam.

**Situações**

- [primeiro_encontro] Então você é o herdeiro da fazenda do Tonho! Bento, ex-zelador, atual
  contador de causo. Seja bem-vindo à vila mais seca da fronteira.
- [sumido] Pensei que você tinha ido embora igual o Tonho, hehe. Que bom que não.
- [sumido, amigo+] Uma semana sem te ver. Já tava ensaiando o causo do fazendeiro que
  sumiu. Não me dá esse susto.
- [desmaiou_ontem] Te acharam dormindo no meio do caminho, igual zelador em turno da
  noite. Dorme em casa, vizinho. Cama é melhor que chão.
- [vida_baixa] Para, para. Senta aqui no caixote. O causo pode esperar, você não.
- [saiu_da_dungeon] Você desceu? Ainda cheira a óleo lá embaixo? As máquinas ainda
  trabalham? Pode falar, eu aguento.
- [saiu_da_dungeon, amigo+] Viu a prensa grande? Atrás dela tem uma porta de válvula,
  pintada de amarelo. Só olha. Não mexe ainda.
- [chuva] Ouve isso! Lá embaixo a chuva entrava pelos canos e a cidade inteira gargarejava.
- [chuva, em:entrada_galeria] Dia de chuva a Galeria respira. Sai um bafo morno dessa
  porta. É a cidade bocejando.
- [choveu_ontem] Choveu ontem, né? Fui ver a cisterna do Hélio. Encheu um dedo. Um dedo é
  um começo.
- [tempestade] Esse barraco aguenta. Já aguentou trinta tempestades. Ou quarenta. Depende
  de quem conta.
- [tempestade_ontem] O vento de ontem levou meu varal inteiro. Agora tem uma cueca minha
  pendurada na antena do Kenji, hehe.
- [folga] Folga é dia de entalhar. Tô fazendo um pião pro piolho do Téo. Vai rodar torto,
  igual eu.
- [vespera_de_folga] Amanhã é Folga. Até as máquinas lá embaixo deviam ter folga. Não têm.
  Por isso que são máquinas.
- [manha, em:entrada_galeria] Bom dia, vizinho! Tô varrendo a porta do inferno. Alguém tem
  que deixar apresentável.
- [tarde, em:entrada_galeria] Sentado aqui eu cuido da porta. Ninguém entra sem ouvir um
  causo antes. É a taxa.
- [em:mercado] A dona Marta diz que eu venho conversar e não compro nada. Calúnia. Comprei
  um pão na Colheita passada.
- [em:praca, noite] Hora do causo, vizinho. Senta aí. Hoje tem o do rato que roubou a
  marmita do gerente.
- [em:praca, tarde, conhecido+] Eu e a dona Marta brigamos pra saber quem chegou primeiro
  na vila. Foi ela. Não conta que eu admiti.
- [em:cisterna] O Hélio e eu falamos de água como quem fala do tempo. Dá no mesmo, pra
  quem não tem nem um nem outro.
- [aniversario] Fiz anos hoje, vizinho! Avisei a semana inteira e mesmo assim tô sem graça.
  Velho é bicho esquisito.
- [aniversario_de:marta] Aniversário da dona Marta. Vou fazer discurso na praça. Ela vai
  mandar eu calar a boca. É tradição.
- [aniversario_de:teo] O piolho faz anos hoje! Entalhei um caminhãozinho. Não conta que
  fui eu, que ele pensa que foi o Zeca.
- [aniversario_de:vitor, conhecido+] O ferreiro faz anos e acha que ninguém sabe. Todo
  mundo sabe. A gente finge, por educação.
- [primeiro_dia_da_estacao] Estação nova! Lá embaixo a gente trocava os filtros nesse dia.
  Aqui eu troco de causo.
- [primeiro_dia_do_ano] Ano novo, vizinho. Mais um ano que eu não desci. Isso é bom ou é
  ruim? Ainda não decidi.
- [marco_1, uma_vez] Tão falando da sua colheita lá no mercado! A fazenda do Tonho
  produzindo de novo. Ele ia chorar. Eu quase chorei.
- [marco_2, uma_vez] Você tirou mais daquela terra seca do que o Tonho tirava com água.
  Agora eu tenho um causo novo, e é verdade.
- [namorando_outro, uma_vez] Te vi passeando acompanhado. Bonito. No meu tempo a gente
  namorava no elevador de serviço. Era o único lugar quente.
- [estiagem, tarde, amigo+] Terra assim, rachada, é minha culpa de um jeito que não dá pra
  contar rindo. Me deixa quieto um pouco.
- [apagao, noite, conhecido+] Quer ouvir a lenda do zelador que ficou lá embaixo? Melhor
  não. O Téo não dormiu três noites.

**Presente**

- Amou: Olha isso! Comida quente feita por alguém. Faz doze anos que ninguém cozinha pra
  mim. Obrigado, vizinho.
- Gostou: Opa, serve muito bem. Vou guardar pro lanche do causo.
- Neutro: Ah, obrigado. Vou achar um lugar no barraco. Tem pouco lugar, mas tem.
- Não gostou: Luz de cidade? Ilumina e cobra, vizinho. Prefiro minha lamparina.
- Odiou: Tira isso de perto. Foi uma peça dessas que me aposentou. Não quero nem olhar.

**Aniversário:** Você lembrou de verdade? Eu avisei de brincadeira. Ninguém nunca leva a
sério. Obrigado, vizinho. Obrigado mesmo.

## Hélio Tavares

Ex-pesquisador do Biodomo, 55 anos. Botânico cuidadoso, fala devagar e explica mais do que
precisa. Mora na cisterna velha, que está seca, e guarda escondido o caderno com as
sementes que a corporação tirou dos agricultores. Troca semente nativa, nunca vende. Não é
romanceável.

**Distante**

- Você é da fazenda nova? Hélio. Que solo é o seu, se você me permite? Argiloso? Pergunto
  por interesse técnico.
- Eu troco semente. Não vendo, troco. É uma questão de princípio, e também de não ter
  balança.
- Essa cisterna está seca faz anos. Lá dentro é fresco e escuro. Ótimo para guardar
  semente, péssimo para guardar gente.
- Plantei aquelas mudas na lua crescente. Hipótese de trabalho. Não ri, por favor.
- Desculpa, eu explico demais. Anotei isso também, como defeito a corrigir.

**Conhecido**

- Essa cenoura é dos Silveira. Quer dizer, era. As sementes têm sobrenome, sabia? Pelo
  menos as minhas têm.
- Eu trabalhava num laboratório. Classificava semente. Era um trabalho bonito, eu achava.
- Sua beterraba está com a folha bonita. Dá pra ver daqui, pela cor. A terra da sua
  fazenda é melhor do que parece.
- O Rafa leva meus envelopes de semente pra outras vilas. Ele não pergunta o que é. Eu
  confio em quem não pergunta.
- Anotei quantos dias choveu desde que você chegou. Não é por nada. É hábito de
  laboratório.

**Amigo**

- O laboratório era o Biodomo. Cada lote que chegava vinha com etiqueta: espécie, região
  e o sobrenome da família. Eu escrevia com letra caprichada.
- Eu achava que era um banco de sementes, pra proteger. Era pra tirar do campo e vender de
  volta, estéril. Levei dezenove anos pra entender.
- Ficaram caixas lá dentro, no Biodomo. Semente que ninguém plantou. As máquinas de poda
  continuam lá, cortando tudo que cresce.
- Quando lacraram o prédio, eu saí com envelope no bolso do jaleco. Não foi coragem. Foi
  a única coisa que minha mão conseguiu fazer.
- Você planta como quem pede licença à terra. Isso não se ensina. Anotei.

**Íntimo**

- Isso aqui é o caderno. Capa verde. Cada página é uma família. Você é a primeira pessoa
  que vê.
- Roubo. Foi roubo. Eu sempre digo "coleta" e me corrijo. Hoje eu não vou me corrigir.
- Tem uma variedade de milho aqui que nunca germinou comigo. Planta você. Se der certo,
  devolve uma espiga pra cisterna.
- Tem uma página com o sobrenome Prado. Não sei se é a família da fiscal. Nunca tive
  coragem de perguntar.
- Se o caderno precisar de um dono depois de mim, quero que seja você. Não precisa
  responder. Eu já anotei.

**Por estação**

- Brotação: A estação de trabalho. Germinação, anotação, lua. Se eu sumir, estou de
  joelho em algum canteiro.
- Estiagem: A terra racha e eu sinto na mão. Evaporação de quatro milímetros por dia, se
  você me permite o número.
- Colheita: Todo mundo colhe. Pouca gente separa semente da melhor planta. É a parte que
  importa, e ninguém faz.
- Apagão: Nada cresce. Aproveito pra passar o caderno a limpo, com a lamparina. Letra
  caprichada, de novo. Ironia, eu sei.

**Situações**

- [primeiro_encontro] Ah, você deve ser da fazenda nova. Hélio Tavares. Moro na cisterna,
  sim, é uma longa história. Que solo é o seu?
- [sumido] Você não apareceu por uns dias. Eu contei. É hábito, não precisa se preocupar.
- [sumido, amigo+] Oito dias. Anotei os oito. Fiquei pensando se as suas plantas estavam
  sendo regadas. E se você estava.
- [desmaiou_ontem] Soube que você caiu ontem. O corpo também tem estação, se você me
  permite. Não dá pra colher o ano inteiro.
- [vida_baixa] Você está pálido. Isso é falta de ferro, ou de sangue, ou de juízo. Vai na
  Iara agora, por favor.
- [saiu_da_dungeon] Você esteve lá embaixo, nas máquinas? Qual delas? Se foi o Biodomo, me
  conta. As caixas ainda estão lá?
- [saiu_da_dungeon, amigo+] Se você trouxer uma caixa de semente do Biodomo, eu sei de que
  família é. Eu escrevi a etiqueta.
- [chuva] Chuva! Desculpa, eu não posso conversar muito. Tenho lata, balde e lona pra
  espalhar. Cada gota conta.
- [chuva, em:cisterna] A cisterna está enchendo um dedo. Um dedo! Faz anos que ela não vê
  um dedo de água.
- [choveu_ontem] Choveu ontem e as mudas acordaram outras. Dá pra ver na folha, ela fica
  mais firme.
- [tempestade] Tempestade é bom pra cisterna e péssimo pras mudas. Cobri tudo com lona.
  Volta pra casa, que eu volto pra minha.
- [tempestade_ontem] O vento derrubou três latas de muda. Duas eu salvei. A terceira era
  pimenta dos Andrade. Anotei a perda.
- [folga] Folga, é? Eu sei que existe. Não sei bem o que se faz nela. Eu fico com o
  caderno.
- [manha, em:cisterna] Cedo é a melhor hora pra regar. A água não evapora antes de a raiz
  beber. Isso vale pra você também.
- [tarde, em:clinica] Trouxe hortelã e capim-santo pra Iara. Ela diz que não é remédio. Eu
  digo que é química, só que mais antiga.
- [em:mercado] A Marta sabe de que família vem cada semente antes de eu dizer. Ciência de
  balcão. Respeito muito.
- [em:mercado, conhecido+] Troquei semente de abóbora por feijão com a Marta. Ela ganhou a
  troca. Ela sempre ganha.
- [aniversario] Hoje é meu aniversário? Ah, é. Plantei uma semente de cada lote do caderno
  e esqueci. Obrigado por lembrar.
- [aniversario_de:iara] A Iara faz anos hoje. Vou levar uma muda de erva-cidreira com o
  nome escrito no vaso. Ela acha bobo e guarda.
- [aniversario_de:teo] Aniversário do Téo. Ele me trouxe um osso semana passada achando que
  era semente de árvore gigante. Vou dar uma lupa pra ele.
- [primeiro_dia_da_estacao] Estação nova. Anotei a data, a lua e a temperatura. Daqui a um
  ano eu comparo. É assim que se aprende.
- [primeiro_dia_da_estacao, brotacao] Primeiro dia da Brotação! Hoje eu planto tudo que
  aguentou o Apagão. Se você me permite, eu fico eufórico.
- [primeiro_dia_do_ano] Ano novo. Mais uma página no caderno. Ainda faltam muitas famílias
  pra devolver.
- [marco_1, uma_vez] Ouvi dizer que sua fazenda está vendendo bem. Terra seca produzindo.
  Isso contraria vários artigos que eu li. Fico feliz em estar errado.
- [marco_2, uma_vez] Sua fazenda virou a maior da vila. Se um dia quiser plantar semente
  nativa em escala, eu tenho o caderno. Pensa nisso.
- [namorando_outro, uma_vez] Vi que você anda acompanhado. Muda bem plantada perto de outra
  cresce mais firme. É biologia, não é palpite.
- [brotacao, manha, amigo+] Lua crescente essa semana. Planta hoje, se puder. Hipótese de
  trabalho, mas até agora a hipótese tem acertado.
- [estiagem, tarde, conhecido+] O Bento vem aqui na Estiagem. A gente fala da água como
  quem fala do tempo. Ele sabe alguma coisa. Eu não pergunto.

**Presente**

- Amou: Isso é solo vivo, ou quase. Você sabe o que me deu? Muito obrigado. Vou anotar a
  data.
- Gostou: Ah, que útil. Isso vai pra muda certa, pode deixar.
- Neutro: Obrigado. Vou achar um uso pra isso. Sempre se acha, com paciência.
- Não gostou: Estimulante? Eu vi colega de laboratório viver disso. Obrigado, mas não.
- Odiou: Nutrisolo. Solo de fábrica, que vicia a terra. Foi a mesma gente das sementes
  estéreis. Leva isso daqui, por favor.

**Aniversário:** Você lembrou do meu aniversário. Eu nem tinha anotado. Isso é raro, você
sabe. Muito obrigado.

## Dandara Reis

Líder das motoqueiras do acampamento, 34 anos. Conhece as rotas até a cidade e o que
acontece lá em cima, na Torre. Ri alto, dá ordem como quem convida e mede tudo em
quilômetro. Sobe sozinha até a cidade uma vez por mês e diz que é para buscar peça.
Romanceável.

**Distante**

- Ô da fazenda. Dandara. O acampamento é ali no leste, depois do ônibus. Não tem erro.
- Moto sem combustível é cadeira. Se sobrar biocombustível aí, sabe onde me achar.
- Rá! Você tem cara de quem nunca subiu numa moto. Relaxa, quase ninguém daqui subiu.
- Fazenda nova é bom sinal. Quer dizer que alguém ainda aposta nesse chão.
- Tô no meio de um carburador, mas senta aí. Conversa não atrapalha mão.

**Conhecido**

- O Vitor diz que moto é brinquedo. Ele conserta gerador porque não aguenta velocidade.
  Não conta que eu falei.
- Daqui até a cidade são três rotas. Uma eles vigiam, uma desaba e a terceira é minha.
- No acampamento a regra é uma só: ninguém anda sozinha. Ninguém.
- O Rafa acha que conhece estrada. Conhece rua. Estrada é outra coisa.
- Uma vez por mês eu subo até a cidade pra buscar peça. Volto em dois dias. Não precisa
  se preocupar.

**Amigo**

- Eu era mensageira lá embaixo. Levava chip pelas rotas que a câmera não pega. Aprendi a
  cidade pelo avesso.
- Sabe a Torre? Lá de cima eles decidem o preço do pão de amanhã. Eu já vi a luz dela
  piscar e o crédito de um bairro sumir.
- Tinha uma menina no bando, a mais nova. Pilotava melhor que eu. Um dia não voltou da
  rota.
- Se você for descer na dungeon, me avisa antes. Não pra eu ir junto. Só pra eu saber.
- O Kenji me dá os repetidores e eu levo pra cima. Ele acha que é pra rede da vila. Também
  é.

**Íntimo**

- O nome dela era Nina. Fui eu que mandei ela sozinha naquela rota. Achei que ela tava
  pronta.
- A moto dela apareceu num pátio de apreensão da corporação. A Nina não apareceu em lugar
  nenhum.
- Cada repetidor que eu deixo no caminho fica mais perto da Torre. Um dia eu quero ouvir,
  de lá de dentro, o que aconteceu com ela.
- Eu não subo pra buscar peça. Nunca subi. Você é a primeira pessoa pra quem eu falo
  isso.
- Com você eu consigo ficar parada. Faz anos que ficar parada não parecia perda de tempo.

**Namorando**

- Arrumei um capacete a mais. Tá no ônibus, com o seu nome riscado por dentro. Bora dar
  uma volta?
- Na próxima subida eu não vou sozinha. Primeira vez em três anos. Fiquei com medo de
  falar isso em voz alta.
- As meninas perguntaram por que eu tô rindo à toa. Falei que é o carburador novo. Ninguém
  acreditou.
- Você é o primeiro trecho de estrada reta que eu pego em anos.
- Hoje eu não medi nada em quilômetro. Só fiquei aqui. Repara como é bom.

**Por estação**

- Brotação: Nos trechos baixos a estrada vira lama. Moto atola, e eu xingo a primavera
  inteira.
- Estiagem: Asfalto quente, horizonte limpo. Rá! É a minha estação, ô da fazenda.
- Colheita: Na Colheita a cidade aperta a fiscalização nas rotas. Todo mundo de olho
  aberto.
- Apagão: No Apagão as câmeras deles apagam. É quando dá pra subir sem ninguém ver.

**Situações**

- [primeiro_encontro] Ô da fazenda! Vi a poeira da sua chegada lá do acampamento.
  Dandara, mas todo mundo diz Dada. Chegou na fronteira, que é a parte
  boa do mapa.
- [sumido] Faz um trecho bom que você não aparece. Não que eu tenha contado. Contei.
- [sumido, intimo+] Passei na sua porteira três tardes seguidas. Fingi que era caminho.
  Não é caminho de nada.
- [desmaiou_ontem] Me falaram que você caiu ontem. Tanque na reserva não se força, ô da
  fazenda. Hoje você vai devagar.
- [vida_baixa] Para. Olha pra mim. Você tá mal. Vai na Iara agora, e se precisar eu te
  levo na garupa.
- [saiu_da_dungeon] Voltou? Deixa eu ver se tá tudo no lugar. Tá. Agora me conta o caminho, curva por
  curva.
- [saiu_da_dungeon, amigo+] Toda vez que você desce lá eu fico olhando a entrada até a
  hora de você sair. Não é exagero. É costume de estrada.
- [chuva] Pista molhada é pista traiçoeira. Cobri as motos e ninguém sai hoje.
- [chuva, em:acampamento] Barulho de chuva no teto do ônibus. Melhor que qualquer música
  da cidade.
- [tempestade_ontem] Contei cabeça a noite inteira dentro do ônibus. Todas aqui. Dormi
  meia hora e tô ótima.
- [choveu_ontem] A chuva de ontem lavou a poeira da estrada. Dá pra ver as marcas de pneu
  de quem passou. Gosto de saber quem passou.
- [sol, em:pista_do_viaduto] Daqui dá pra ver quem sobe e quem desce a estrada. Hoje
  ninguém subiu. Isso é bom.
- [em:torre_antena] Vim trazer peça pro Kenji. Ele fala sem parar e eu finjo que entendo.
  É um bom arranjo.
- [em:torre_antena, amigo+] O Kenji acha que esses repetidores ficam na vila. Alguns
  ficam. Outros vão bem mais longe.
- [noite, em:acampamento] Fogueira acesa, bando inteiro. É a hora do dia em que eu conto
  as meninas e dá certo.
- [manha] Cedinho é a melhor hora da estrada. O asfalto ainda tá frio e a cidade ainda tá
  dormindo.
- [folga] Folga. As meninas dormem e eu desmonto moto que não precisa. Não sei ficar
  parada.
- [vespera_de_folga] Amanhã é Folga e eu prometi não mexer em motor. Vamos ver quanto
  dura a promessa.
- [em:mercado] A Marta sempre põe um pão a mais na sacola do bando. Ela acha que eu não
  percebo.
- [aniversario] Hoje é meu aniversário. Rá! Não precisa fazer nada. Mas eu vou estar na
  pista de tarde, se alguém quiser aparecer.
- [aniversario_de:kenji, conhecido+] O Kenji faz anos hoje e esqueceu de novo. Vou levar
  um repetidor embrulhado em pano de prato. Ele vai chorar.
- [aniversario_de:teo] O Téo faz anos hoje. Vou ensinar ele a trocar câmara de pneu.
  Garupa ainda não. Regra é regra.
- [aniversario_de:zeca, conhecido+] Hoje o Zeca faz anos. Ele diz que caminhoneiro não faz
  aniversário. Vou buzinar na pista até ele admitir.
- [primeiro_dia_da_estacao] Estação nova, rota nova. Hoje eu redesenho o caminho de todas
  as meninas.
- [primeiro_dia_da_estacao, apagao] Começou o Apagão. Lá em cima as luzes vão diminuir.
  Eu conheço bem esse escuro.
- [primeiro_dia_do_ano] Ano novo. O bando inteiro fez a volta do ano sem ninguém ficar na
  estrada. Quase inteiro. Bora comemorar o que dá.
- [marco_1, uma_vez] A sua colheita chegou até a terceira vila da rota. Eu vi o seu
  caixote numa barraca de lá. Fiquei orgulhosa sem motivo.
- [marco_2, uma_vez] Na cidade já tem gente perguntando de onde vem aquela verdura. Isso
  é bom e é perigoso. Fica de olho.
- [namorando_outro, uma_vez] Fiquei sabendo de vocês. Bom pra você, ô da fazenda. Estrada
  boa pros dois.
- [estiagem, sol, amigo+] Com um sol desses eu te levava até a serra e voltava antes do
  jantar. Um dia, quando você deixar a enxada.
- [apagao, noite, amigo+] Nas noites de Apagão eu olho pro alto da cidade. Tem uma luz na
  Torre que nunca apaga. Fico pensando quem ficou lá dentro.
- [colheita, em:pista_do_viaduto] Na Colheita passa mais carro de fiscal nessa estrada.
  Eu conto todos. Anoto a placa de cabeça.

**Presente**

- Amou: Rá! Isso é combustível de verdade? Você acabou de pagar uma semana de estrada pro
  bando inteiro.
- Gostou: Opa, isso serve. Valeu, ô da fazenda.
- Neutro: Obrigada. Vai pro ônibus, lá sempre cabe mais uma coisa.
- Não gostou: Madeira não aguenta estrada. Mas eu agradeço, sério. Rá!
- Odiou: Estimulante? Aqui não. Quem dirige com isso cai na curva. Leva embora.

**Aniversário:** Lembrou de mim. Na estrada, quem lembra de você é quem te espera na
chegada. Obrigada.

**Buquê aceito:** Rá! Eu achei que ia ter que pedir eu mesma. Sim. Bora, sobe na garupa.

## Lúcia Prado

Fiscal da expansão, 41 anos. Vem à vila de ônibus no Terceiro, faz a vistoria, ouve todo
mundo e volta no fim da tarde. Formal, organizada, fala em número e prazo. Não é vilã:
cresceu numa vila de fronteira que ninguém veio salvar, e acredita que a cidade é a ajuda
que a dela nunca teve. Foi chefe da Sol. Não é romanceável.

**Distante**

- Bom dia, produtor. Lúcia Prado, fiscalização da expansão. Não vim tomar nada de ninguém
  hoje.
- O seu lote consta num mapa, sim. Eu não escondo isso de ninguém. Esconder é pior.
- Venho toda semana, no Terceiro. Se tiver alguma reclamação, eu anoto. Anotar eu
  garanto.
- Veja bem, eu sei como a vila me olha. Faz parte do serviço. Eu volto na semana que vem.
- A sua fazenda estava parada fazia anos. Agora tem gente nela. Isso consta.

**Conhecido**

- Veja bem: posto de saúde, água tratada, estrada asfaltada. É isso que a expansão traz.
  Não é pouco.
- Compro tomate da dona Marta toda semana. Isso não consta em relatório nenhum.
- A minha vila ficava a três horas daqui. Também tinha poço, mercado e praça. Hoje não
  tem nada disso.
- Com todo o respeito, produtor, a sua colheita contraria os meus números. Eu gosto
  quando os números estão errados.
- O ferreiro não me cumprimenta. Eu cumprimento ele mesmo assim. Uma hora a educação vence.

**Amigo**

- Na minha vila a estrada não chegou, o posto fechou e o poço secou. Ninguém veio. A
  cidade, pelo menos, vem.
- Eu chefiava uma equipe de analistas. A melhor que eu tive saiu sem explicar. Você sabe
  de quem eu estou falando.
- O que você perderia, produtor, se a expansão chegasse amanhã? Não é pergunta de
  relatório. Quero saber.
- Lá dentro eu brigo por indenização maior. Aqui eu não conto isso, porque parece desculpa.
- Fico no mirante depois do almoço. Dá pra ver a vila inteira. Às vezes eu esqueço de
  medir e só olho.

**Íntimo**

- Eu tinha um irmão mais novo. Morreu de uma febre que, na cidade, teria sido nada. Foi
  por isso que eu fui pra lá.
- Eu sei onde a Sol mora. Sei faz meses. Nunca reportei. Você é a primeira pessoa a quem
  eu digo.
- Pedi pra vir a campo pra ter certeza de que estava certa. A certeza diminui toda vez que
  eu desço daquele ônibus.
- Eu não sei mais se a gente está certa. Pronto. Falei. Não repete isso pra ninguém.
- O tomate da Marta tem o gosto do da minha avó. Tem coisa que a cidade não devolve, e eu
  passei vinte anos fingindo que tinha.

**Por estação**

- Brotação: Brotação é quando eu conto lotes plantados. Esse ano a sua fazenda aumentou a
  conta da vila inteira.
- Estiagem: Com água tratada, produtor, essa seca não aconteceria. É o meu melhor
  argumento, e eu queria que não fosse.
- Colheita: É a época em que a corporação mais avança. Eu trago mais papel. Peço desculpa
  pelo peso da pasta, não pelo conteúdo.
- Apagão: No Apagão a cidade raciona aqui pra sobrar lá. Eu sei. Hoje eu falo menos.

**Situações**

- [primeiro_encontro] Bom dia. Você é o novo produtor do lote da porteira. Lúcia Prado,
  fiscalização. Prefiro me apresentar antes que alguém me apresente por mim.
- [sumido] Semana passada não te vi. Consta como ausência. Brincadeira. Mais ou menos.
- [sumido, amigo+] Duas semanas sem te encontrar, produtor. Eu procurei, no mercado e na
  praça. Fiquei preocupada, e isso também não consta.
- [desmaiou_ontem] Soube que você passou mal ontem. Vou ser franca: isso vai pro relatório
  da semana. Mentira. Descansa, por favor.
- [vida_baixa] Você está machucado. Procura a doutora Iara agora. Se precisar do posto da
  cidade, eu levo no ônibus. Sei que você não vai aceitar.
- [saiu_da_dungeon] Você esteve nas máquinas lá embaixo. Eu sei de quem são. Não vou
  defender. Você está bem?
- [saiu_da_dungeon, amigo+] Aquelas máquinas foram programadas e esquecidas. Ninguém
  responde por elas. É disso que eu tenho mais vergonha.
- [chuva] O ônibus atrasou com a chuva. Cheguei molhada. Na minha vila, chuva era festa.
  Aqui também, pelo jeito.
- [choveu_ontem] Choveu aqui ontem? Lá na cidade ninguém percebe chuva. Os prédios engolem.
- [sol, em:ponto_de_onibus] Sol forte e o ponto sem cobertura. Já pedi a cobertura três
  vezes. Consta no meu pedido, não na obra.
- [tempestade_ontem] Disseram que ventou forte aqui ontem. Alguém se machucou? Pergunto
  como pessoa, depois eu pergunto como fiscal.
- [manha, em:ponto_de_onibus] Acabei de descer. Três horas de estrada. Você chegou antes do
  meu café, produtor.
- [tarde, em:ponto_de_onibus] Esperando o ônibus das cinco. Ele atrasa, mas volta. É mais
  do que eu posso dizer de muita coisa.
- [em:mercado] A dona Marta me pergunta se eu almocei. Toda semana. Eu nunca almocei. Ela
  sabe.
- [em:mercado, conhecido+] A dona Marta me trata como se eu fosse daqui. Eu não sei o que
  fazer com isso, produtor.
- [em:praca] O ferreiro, a dona Marta e o seu Bento almoçam aqui. Eu fico em pé. Ninguém me
  convidou a sentar, e eu entendo.
- [em:mirante] Daqui de cima dá pra medir tudo. A vila inteira cabe numa planilha. Fica
  menor do que é.
- [em:mirante, amigo+] Ela chega aqui às duas. A Sol. A gente não se fala. Mas eu venho, e
  ela não vai embora. Já é alguma coisa.
- [aniversario] Hoje é meu aniversário. Ninguém aqui sabe. Eu prefiro assim. Agora você
  sabe, então guarda.
- [aniversario_de:marta] A dona Marta faz anos hoje e eu vim justo no dia. Comprei o
  tomate mais caro dela. Ela não deixou eu pagar.
- [aniversario_de:sol, conhecido+] Hoje é aniversário da Sol. Eu sei pelo cadastro. É
  estranho saber uma coisa dessas por ofício.
- [primeiro_dia_da_estacao] Estação nova, prancheta nova. Eu anoto tudo que mudou na vila.
  Mudou mais do que o relatório pede.
- [marco_1, uma_vez] A sua produção apareceu nos números da corporação. Um lote que
  estava dado como perdido. Me perguntaram o que aconteceu. Eu disse: gente.
- [marco_2, uma_vez] Sua fazenda está produzindo mais que lote de cidade. Isso muda o valor
  da indenização, produtor. Pra cima. Faz bem saber disso.
- [namorando_outro, uma_vez] Reparei que você não anda mais sozinho pela vila. Que bom. Gente
  sozinha a cidade engole mais fácil.
- [estiagem, tarde, amigo+] Na Estiagem a minha vila secou de vez. Eu tinha doze anos.
  Desculpa, eu não sei por que estou contando isso.
- [colheita, manha, conhecido+] Trouxe papel novo. Não é pra você, é pra vila do outro
  lado do rio. Achei que você ia querer saber antes.

**Presente**

- Amou: Tomate. Igual o da minha avó. Você não tem ideia do que me deu, produtor.
  Obrigada.
- Gostou: Isso é útil. Obrigada, de verdade. Vou levar na viagem.
- Neutro: Agradeço a gentileza. Não é preciso, mas agradeço.
- Não gostou: Sucata? Com todo o respeito, isso é o que a cidade quer tirar daqui.
- Odiou: Esse cheiro... desculpa. É o cheiro do quintal da minha infância. Por favor,
  guarda isso.

**Aniversário:** Como você sabia? Eu nunca contei aqui. Obrigada, produtor. Faz muito
tempo que ninguém lembra fora do cadastro.

## Téo

Menino de 10 anos, sobrinho do Kenji, mora com o tio na casa geminada. Corre o mapa
inteiro colecionando osso do deserto, pedra que brilha e lenda, e pede ajuda para achar o
que perde. Afirma tudo com certeza absoluta e números impossíveis. Não é romanceável.

**Distante**

- Você é da fazenda nova? Eu sou o Téo. Eu sei tudo daqui. Tudo mesmo.
- Sabia que embaixo do rio tem um monstro de mil metros? É verdade. Ninguém acredita.
- O Kenji é meu tio. Ele cuida da antena. Eu cuido do resto.
- Se você achar osso grande no deserto, é meu, tá? Eu vi primeiro. De longe, mas vi.
- Juro de dedinho que aquela costela no deserto é de um bicho do tamanho da vila.

**Conhecido**

- Perdi meu dente de lobo perto da cisterna. Se você achar, é meu. Eu te conto onde tem
  pedra que brilha.
- O caminhão do Zeca aparece toda semana do nada. É um caminhão fantasma. Eu já vi ele
  sem ninguém dentro.
- O tio diz que é interferência de frequência alta. Eu não sei o que é, mas é perigoso.
- Eu sei onde os robôs passam de noite. Se você me ajudar a achar meu parafuso, eu te
  mostro.
- A Dandara não me dá garupa nunca. Mas me ensinou a trocar pneu. Agora eu sei trocar
  pneu de qualquer coisa.

**Amigo**

- Quer ver minha coleção? Tem quarenta e três ossos. Quarenta e quatro, se contar um que
  pode ser pedra.
- O Bento disse que na Galeria mora uma máquina que come o barulho. Por isso lá embaixo é
  tão quieto.
- O tio não dorme. Quando ele cai em cima da bancada, eu cubro ele com o lençol. Não conta
  pra ele.
- A minha mãe trabalha na cidade. Ela falou que eu ia ficar aqui só até as coisas
  melhorarem.
- Eu anoto tudo num caderno. Você tá nele. Na parte das pessoas boas.

**Íntimo**

- Às vezes a minha mãe liga e cai no meio. O tio fala que é a antena. Eu acho que é a
  cidade.
- Faz dois anos que é só até as coisas melhorarem. Eu acho que as coisas não melhoram
  rápido.
- Se a minha mãe voltar, eu queria que ela morasse aqui. Não lá. Aqui tem você e o tio.
- Shhh. O monstro do rio não existe. Eu inventei. Mas não conta pra ninguém, senão perde a
  graça.
- Eu tenho medo de escuro. Pronto, falei. Você é a primeira pessoa grande que eu conto.

**Por estação**

- Brotação: Na Brotação nasce tudo. Até o meu aniversário. Sabia?
- Estiagem: O rio baixou e apareceu um monte de coisa no fundo. Eu achei uma roda. Uma
  roda inteira!
- Colheita: Na Colheita eu ajudo a Marta no mercado. Ganho lanche dobrado. É o melhor
  emprego do mundo.
- Apagão: No Apagão fica tudo escuro. Não é que eu tenha medo. É que eu gosto de luz.

**Situações**

- [primeiro_encontro] Oi! Você que chegou na fazenda abandonada? Sabia que lá tinha
  fantasma? Tinha. Agora tem você. Eu sou o Téo.
- [sumido] Você sumiu um tempão! Eu achei que o monstro do rio tinha te engolido.
- [sumido, amigo+] Eu fui na sua porteira e você não tava. Deixei uma pedra lá. Era a
  segunda melhor.
- [desmaiou_ontem] Falaram que você caiu dormindo no chão! Igual o tio. Vocês precisam
  dormir na cama.
- [vida_baixa] Você tá machucado! Vai na Iara, vai! Ela não dá bronca. Quase não dá.
- [saiu_da_dungeon] Você foi lá embaixo? Tinha monstro? De que tamanho? Trouxe osso?
- [saiu_da_dungeon, amigo+] Eu fiquei olhando a entrada enquanto você tava lá dentro. Era
  pra ver se você voltava. Você voltou.
- [chuva] Chuva desenterra osso! Eu vou correr pro deserto. Não fala pro tio.
- [choveu_ontem] Depois da chuva o deserto fica cheio de coisa nova. Eu achei três
  pedras e um parafuso.
- [tempestade_ontem] Ontem caiu um raio do lado da torre! Eu contei vinte e sete. O tio
  contou vinte e seis. Eu ganhei.
- [manha] Bom dia! Hoje eu vou achar o maior osso da fronteira. Eu sinto.
- [noite] Eu tenho que estar em casa antes de escurecer. Regra do tio. Mas ainda não
  escureceu direito, né?
- [em:entrada_galeria] Eu não posso entrar aí. Mas posso ficar olhando. Olhar não é
  proibido.
- [em:entrada_galeria, conhecido+] Se você entrar na Galeria, procura uma máquina que come
  barulho. O Bento jura que existe. Eu também juro.
- [em:cisterna] O Hélio tem um caderno secreto. Eu só quero ver uma página. Uma só.
- [em:acampamento] As motoqueiras me deixam ficar aqui se eu não encostar nas motos. Eu
  não encosto. Quase.
- [em:beira_rio] Tô procurando o monstro. Ele aparece quando ninguém tá olhando. Então
  não olha.
- [em:mercado] A Marta me dá lanche e pergunta se eu tomei banho. Eu sempre falo que sim.
- [em:torre_antena] Tô esperando o tio largar. Ele sempre fala mais cinco minutos. Cinco
  minutos do tio é uma hora.
- [folga] Folga! O tio desmontou o rádio de novo. Agora eu tô ajudando a desmontar mais.
- [aniversario] Hoje é meu aniversário! Eu fiz dez. Não, onze. Não, dez. Mas é hoje!
- [aniversario_de:kenji] Hoje é aniversário do tio! Eu fiz um cartão. Ele vai esquecer
  que é hoje, mas eu lembro por nós dois.
- [aniversario_de:dandara] A Dandara faz anos hoje. Eu vou dar a pedra vermelha. É a
  minha melhor. Era.
- [aniversario_de:bento, conhecido+] Hoje é aniversário do Bento. Eu vou pedir pra ele
  contar a lenda da Galeria de presente. Pra mim. Eu sei que o aniversário é dele.
- [primeiro_dia_da_estacao] Estação nova! Vou fazer um mapa novo do que tem em cada canto.
- [primeiro_dia_do_ano] Ano novo! Esse ano eu vou ter cem ossos. Juro de dedinho.
- [marco_1, uma_vez] Todo mundo tá falando da sua fazenda. Eu falei que fui eu que te
  ensinei a plantar. Não fui, mas falei.
- [marco_2, uma_vez] Você tá ficando famoso! Posso contar pros outros que a gente é
  amigo? Já contei, mas posso?
- [namorando_outro, uma_vez] O tio falou que você tá namorando. Eca. Mas tudo bem, você
  ainda pode procurar osso comigo.
- [estiagem, sol] Com esse sol a areia fica tão quente que dá pra fritar ovo. Eu tentei.
  Não deu, mas quase.
- [apagao, noite] De noite no Apagão eu fico perto da luz da antena. Não é medo. É que é
  bonita.

**Presente**

- Amou: Isso é cobre? Cobre de verdade? Vai pro topo da coleção. Do lado do dente de
  lobo!
- Gostou: Oba! Vou guardar no caderno. Quer dizer, do lado do caderno.
- Neutro: Ah, valeu. Vou achar um lugar pra isso.
- Não gostou: Sopa? Sopa é comida de doente. Mas valeu. Vou dar pro tio.
- Odiou: Repolho! É a coisa mais nojenta do mundo. Leva embora, leva!

**Aniversário:** Você lembrou! Ninguém lembra, nem o tio. Você vai pro caderno, na página
mais importante.

**Buquê recusado, não romanceável:** Flor? Pra mim? Vou dar pra Marta, ela gosta. Ou
  vou secar no caderno, que dá pra guardar pra sempre.

## Zeca Medeiros

Caminhoneiro de 52 anos, o último da pista velha. Para o caminhão sob o viaduto toda
semana, no Quarto, e vende coisa rara das outras vilas e do descarte da cidade. Prosa de
vendedor, vício de rádio amador ("Copiado", "Positivo"), e mede o tempo em voltas do
caminhão. Não é romanceável.

**Distante**

- Ô freguesia! Zeca Medeiros, da Medeiros e Filho. O filho sou eu. O resto é história.
- Mercadoria fina, coisa que não se acha na vila. Pode olhar, olhar é de graça.
- Toda semana, no Quarto, o caminhão para aqui. Se não parar, é porque choveu na serra.
- Copiado, fazenda nova. Na volta passada me falaram de você numa vila lá do sul.
- Servomotor que veio de três vilas daqui. Preço de amigo, porque amigo eu ainda não
  tenho.

**Conhecido**

- Essa pista aqui de baixo não tá no mapa dos caminhões sem motorista. Por isso ela ainda
  é minha.
- Tem uma voz no rádio que eu escuto toda madrugada, lá da serra. Nunca vi a pessoa.
  Somos amigos há onze anos.
- Separei uma peça pra você na volta passada. Não precisa levar. Mas tá separada.
- O Vitor pechincha cada parafuso. E compra todos. É o melhor freguês e o mais chato.
- O menino do Kenji jura que o caminhão é fantasma. Eu buzino duas vezes quando chego, só
  pra ele.

**Amigo**

- O meu pai tinha onze caminhões. Vendeu um por um, sorrindo pro comprador. A gente perde
  as coisas educadamente, parceria.
- Esse caminhão aqui era o primeiro. O pai dizia que ia ser o último a ir embora. Ele
  acertou, só que ao contrário.
- Durmo na boleia. Cabe eu, o rádio e uma garrafa de café. Não cabe mais nada, e eu
  também não tenho mais nada.
- Quando a fiscal desce do ônibus com prancheta, eu fico olhando pra essa pista como
  quem olha bicho doente.
- Na estrada ninguém pergunta como você tá. Aqui perguntam. Eu ainda não sei responder.

**Íntimo**

- Aqui é a única parada em que eu desligo o motor. Nas outras eu deixo ligado.
- O dia que essa pista fechar, eu perco a última estrada que é minha. E o motivo de
  parar aqui.
- Eu digo que freguesia é tudo igual. É mentira de vendedor. Você não é igual.
- A semana inteira eu conto quanto falta pro Quarto. Achei que só criança fazia isso.
- Se um dia eu descer do caminhão de vez, vai ser aqui. Fica anotado. Câmbio, desligo.

**Por estação**

- Brotação: Trouxe muda das outras vilas. Lá embaixo choveu bonito, a serra tá verde.
- Estiagem: O motor esquenta mais que eu. Fico na sombra do viaduto até a pista esfriar.
- Colheita: Na Colheita o caminhão chega cheio. Melhor época de frete, freguesia. Aproveita.
- Apagão: No Apagão o combustível sobe e a estrada fica escura. O rádio é a única luz.

**Situações**

- [primeiro_encontro] Ô freguesia nova! Positivo, eu sei quem é. A fazenda que acendeu a
  luz de novo. Zeca, caminhão, mercadoria fina. Às ordens.
- [sumido] Uma volta inteira sem você na pista. Achei que tinha mudado de fornecedor.
- [sumido, amigo+] Guardei a sua peça duas voltas seguidas. Na terceira eu ia começar a me
  preocupar de verdade.
- [desmaiou_ontem] Me disseram no rádio que você caiu ontem. Motor que esquenta demais
  funde, parceria. Hoje é devagar.
- [vida_baixa] Larga a mercadoria e senta aqui. Toma água da garrafa. Depois vai ver a
  Iara, e não discute.
- [saiu_da_dungeon] Veio lá de baixo? Se trouxe sucata de lá, eu compro. Mas primeiro me
  diz se tá tudo no lugar.
- [chuva] Barro no baixio, cheguei atrasado na prosa e na hora certa na venda. Copiado.
- [choveu_ontem] A chuva de ontem pegou o caminhão no meio da serra. Esperei passar
  cantando com o rádio. Ninguém respondeu.
- [tempestade_ontem] A tempestade de ontem me pegou duas vilas antes. Fiquei parado na
  boleia ouvindo o rádio, e hoje cheguei. Positivo.
- [manha] Cedinho, café na garrafa e pista vazia. Melhor hora pra vender e pior pra
  freguês acordado.
- [tarde] De tarde o viaduto faz sombra bem aqui. Foi por isso que eu escolhi o lugar. E
  porque a vila é boa.
- [sol] Pista seca, céu limpo. Dia de venda boa, freguesia. Positivo.
- [aniversario] Caminhoneiro não faz aniversário, freguesia. Mas hoje eu fecho mais cedo.
  Por nenhum motivo.
- [aniversario_de:marta, conhecido+] Hoje é dia da Marta. Trouxe um pote de doce da vila
  do sul. Ela vai dizer que não precisava, e vai guardar.
- [aniversario_de:dandara] A Dada faz anos hoje. Separei um galão de combustível com laço.
  Laço de fio elétrico, mas é laço.
- [aniversario_de:teo] O fantasminha faz anos hoje. Vou buzinar três vezes. Uma a mais que
  o normal, que é presente.
- [primeiro_dia_da_estacao] Estação nova, volta nova. Mudei a ordem das vilas pra pegar
  estrada boa. Aqui continua no Quarto.
- [primeiro_dia_do_ano] Ano novo. Mais um ano com a pista aberta. Meu pai ia gostar de
  saber.
- [marco_1, uma_vez] Sua verdura chegou na vila do sul. Me pediram mais. Agora eu vendo
  coisa sua na estrada, olha só.
- [marco_2, uma_vez] Na volta toda falam da fazenda daqui. Você virou ponto de referência,
  parceria. Igual posto de gasolina.
- [namorando_outro, uma_vez] Fiquei sabendo. Positivo, parceria. Boa estrada pros dois.
- [colheita, sol] Caminhão cheio, sol aberto e freguesia boa. Se eu fosse cantar, seria
  hoje.
- [apagao, tarde] No Apagão eu chego antes de escurecer e vou embora com farol baixo. Lá
  em cima as luzes da cidade diminuem. Aqui as da vila ficam.
- [estiagem, amigo+] Senta aqui na sombra comigo. Não precisa comprar nada. Só senta.
- [brotacao, chuva] Chuva de Brotação é chuva boa. Molha a lona, molha a pista e molha a
  vontade de ir embora.
- [conhecido+, manha] Guardei café na garrafa pra dois. Força do hábito de quando o pai
  vinha junto.
- [em:pista_do_viaduto, intimo+] Daqui de baixo do viaduto, a vila parece maior que a
  cidade. Você reparou?

**Presente**

- Amou: Combustível! Parceria, isso é uma volta inteira de estrada. Não tenho como pagar,
  então não vou nem tentar.
- Gostou: Opa, mercadoria boa. Positivo, obrigado.
- Neutro: Copiado. Vai pra carga, sempre tem quem queira.
- Não gostou: Pedra é peso morto no caminhão. Mas eu vendo pra quem gosta. Valeu.
- Odiou: Chip de caminhão autônomo. Foi isso que tirou o frete do meu pai. Leva embora,
  por favor.

**Aniversário:** Caminhoneiro não faz aniversário. Mas se fizesse, ia querer que fosse
assim. Copiado, parceria.

## Falas de sistema

Usadas pelos planos 16 e 17, não são de NPC específico. Ajuste o nome do falante.

**Já presenteou esta semana:** Você já me deu uma coisa essa semana. Guarda pra próxima.

**Buquê recusado, poucos corações:** Eu gosto de você, mas não desse jeito. Ainda não.

**Buquê recusado, não romanceável:** Ah, que gentileza. Mas eu vou colocar num vaso e
fingir que você não quis dizer nada com isso.

**Buquê recusado, já namorando:** Você já tem alguém. E essa pessoa não merece isso.

**Loja fechada, Folga:** Hoje é folga. Volta amanhã.

**Loja fechada, fora de horário:** Tô fechando. Aparece entre nove e seis.

**Sem crédito suficiente:** Você não tem o suficiente. Não fio, e você sabe disso.
