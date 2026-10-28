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

Ex-zelador da Galeria, 68 anos (plano 30). Brincalhão, contador de causo, o primeiro a
receber quem chega. Passou trinta e um anos nos túneis e ensinou às máquinas a rotina que
hoje fecha a água das fazendas. O humor é o jeito de carregar isso. Não é romanceável.

**Distante**

- Ô, criatura! Fazenda nova, é? Chegou gente na fronteira. A água tá atrasada, mas o
  vizinho chegou na hora.
- Bento. Bento Arruda. Trinta e um anos de Galeria e nenhum de juízo. Pode rir.
- Tá vendo aquela porta? Eu abri e fechei ela onze mil vezes. Contei. Não tinha o que
  fazer.
- Isso me lembra uma vez que uma bomba lá embaixo engoliu a minha marmita. Inteira. Com a
  colher.
- A fazenda tá seca, eu sei. Não é culpa sua. Tem uma válvula lá embaixo com muita
  opinião.
- Se ouvir um ronco debaixo do chão de noite, não se assusta. É a Galeria. Ou sou eu.

**Conhecido**

- Lá embaixo as máquinas continuam varrendo. Varrem até o que não é sujeira. Por isso eu
  fico aqui fora.
- Eu conheço cada cano daquela Galeria pelo ronco. O da bomba três parece o Vitor de
  manhã.
- O Téo vem todo dia ouvir história. Eu já repeti a do rato gigante umas quarenta vezes.
  Ele finge que é a primeira.
- A Marta me conhece de quando eu tinha cabelo. Ela jura que eu tinha. Eu não lembro.
- Zelador não tem folga. Tem só dia em que ninguém chama.
- Se for lá embaixo um dia, leva lanterna. A minha eu não empresto, que ela é mais velha
  que você.

**Amigo**

- A água das fazendas passava por um registro lá na sala das bombas. Um dia fechou. Não
  quebrou, criatura. Fechou.
- Antes de me mandarem embora, me pediram pra ensinar a rotina pras máquinas. Eu ensinei.
  Caprichei, até.
- Eu fico nessa porta porque ainda tenho a chave de serviço no bolso. Não sei pra quê.
  Pra nada, talvez.
- Tem dia que eu acho que a Galeria me chama. Tem dia que eu acho que é só a idade.
- A sua fazenda é a primeira em anos que alguém quis tocar com aquela terra seca. Eu fiquei
  bobo. Não conta pra ninguém.

**Íntimo**

- Fui eu que ensinei aquelas máquinas a fechar a água. Ensinei direitinho.
- Trinta e um anos cuidando da água da fronteira, e o meu último serviço foi tirar ela
  de vocês.
- Eu conto causo o dia inteiro pra ninguém me perguntar o que eu fazia lá embaixo. Você
  perguntou mesmo assim.
- A chave do registro tá aqui. Se um dia você chegar na sala das bombas, abre. Eu não
  tenho mais perna pra isso.
- Com você por aqui, a porta da Galeria ficou menor. Não sei explicar. Ficou.

**Por estação**

- Brotação: A primeira chuva da Brotação tem um cheiro que lá embaixo não chegava nunca.
  Eu saía do turno só pra sentir.
- Estiagem: Estiagem é quando a falta da água aparece em tudo. Até no humor do Vitor.
  Mais do que o normal, digo.
- Colheita: No meu tempo, na Colheita, a fronteira inteira cheirava a milho. Agora cheira
  a poeira. Mas tem a sua fazenda.
- Apagão: No Apagão a Galeria fica quieta. As máquinas economizam. Eu nasci no Apagão, por
  isso enxergo no escuro.

**Situações**

- [primeiro_encontro] Ô, criatura! Você é da fazenda nova! Bento, ex-zelador, atual
  vigia de porta. Seja quem for, a vila agradece.
- [sumido] Sete dias sem aparecer. Eu pensei que tinha ido embora, como os outros. Que bom
  que não foi.
- [desmaiou_ontem] Caiu de cansaço, foi? No meu primeiro turno eu dormi em pé encostado
  numa bomba. Acordei com a orelha quente.
- [vida_baixa] Para tudo. Isso não é graça. Vai na Iara agora, que eu fico de olho na
  sua fazenda.
- [saiu_da_dungeon] Você entrou lá? O registro ainda tá lá? Digo, você tá bem? Nessa
  ordem. Desculpa a ordem.
- [chuva] Chuva! A única água que máquina nenhuma fecha.
- [tempestade_ontem] Ontem a Galeria roncou a noite toda. Ela não gosta de raio. Eu
  também não.
- [folga] Folga, é? Zelador não tem folga. Mas eu sento um pouco mais longe da porta.
- [manha, em:porta_da_galeria] Bati o ponto. Ninguém mais anota, mas eu bato.
- [em:praca] Senta aí que eu conto a do rato gigante. Ou a do cano que cantava. Escolhe.
- [noite, em:ponte] O Kenji fala, o Rafa cochila e eu conto causo. A ponte é a melhor
  repartição da fronteira.
- [aniversario] Hoje eu faço sessenta e oito. Ou sessenta e nove. Na Galeria a gente
  perdia a conta.
- [aniversario_de:teo] O Téo faz anos hoje. Guardei pra ele a lanterna velha do turno da
  noite. Ele vai achar que é tesouro. E é.
- [aniversario_de:marta, conhecido+] A Marta faz anos hoje. Ela me deu fiado por vinte
  anos. Hoje eu levo uma flor e não cobro troco.
- [primeiro_dia_do_ano] Ano novo! Mais um ano de fronteira, criatura. Ela continua aqui.
  A gente também.
- [estiagem, amigo+] Na Estiagem eu olho a sua terra rachada e penso no registro. Penso
  todo dia. Na Estiagem penso dobrado.
- [marco_1, uma_vez] Tão falando da sua fazenda até no mercado. Eu falei que fui o
  primeiro a saber. Fui mesmo.
- [namorando_outro, uma_vez] Fiquei sabendo que você tá de namoro. Que coisa boa! Na
  fronteira, quem fica, fica junto.

**Presente**

- Amou: Sopa! Comida de turno! Você não sabe o que fez, criatura. Ou sabe e fez de
  propósito.
- Gostou: Isso serve. Obrigado, viu. Vou guardar no barraco junto das minhas relíquias.
- Neutro: Ah, que gentileza. Vou achar um canto pra isso.
- Não gostou: Estimulante? Vi muito colega de turno ir embora com isso. Leva de volta,
  por favor.
- Odiou: Biocombustível. Tem o cheiro da sala das bombas. Tira daqui, criatura.

**Aniversário:** Lembrou do meu aniversário? Nem a Galeria lembrava. E olha que ela me via
todo dia.

---

## Hélio Tavares

Ex-pesquisador do Biodomo, 55 anos (plano 30). Calmo, preciso, fala de semente como de
gente. Copiou à mão o catálogo das sementes nativas que a corporação ia destruir e mora
na cisterna velha com o caderno. Não é romanceável.

**Distante**

- Boa tarde. Hélio. Você é da fazenda nova? O que você planta? Veja bem, eu pergunto pra
  anotar.
- Essa cisterna é fresca e escura. Bom lugar pra guardar o que precisa esperar.
- Paciência. A terra daqui não gosta de ser apressada. Ninguém gosta.
- A cenoura é teimosa, mas é leal. Se você cuidar no começo, ela cuida de você no fim.
- Anotado. Fazenda nova, Brotação. Isso vai pro caderno.

**Conhecido**

- Eu trabalhei num lugar onde guardavam semente. Muita semente. Hoje eu guardo só as que
  cabem numa bolsa.
- Beterraba gosta de frio na raiz e sol na folha. Ela é contraditória. Como todo mundo.
- A Marta e eu trocamos semente há anos. Ela finge que é negócio. É amizade.
- Toda semente tem uma origem. Quem plantou antes, onde, por quanto tempo. Eu tento não
  esquecer nenhuma.
- Isso tem um ciclo. A sua fazenda também tem. Você ainda está no começo dele.

**Amigo**

- Eu trabalhei vinte anos no Biodomo. Catalogando o que a corporação comprava dos
  agricultores. Depois parou de comprar, e passou a só tomar.
- Veio uma ordem de destruir o banco de sementes nativas. Eu copiei o catálogo inteiro à
  mão, numa noite. Esse é o caderno.
- Ficaram caixas lá dentro. Quatro, eu acho. Eu não consegui carregar tudo. Penso nelas
  toda Brotação.
- Eu durmo mal. Não é a cisterna. É lembrar que tem semente lá dentro esperando, e que
  semente não espera para sempre.

**Íntimo**

- Toma. Lê o caderno. Você é a primeira pessoa que eu deixo ler. Veja bem, isso é sério.
- Essa aqui era de uma família do vale. Seis gerações plantando. Eu sei o nome de todos.
  Eles não sabem que eu sei.
- Eu ajudei a catalogar o que eles tomaram. O caderno é o meu pedido de desculpas.
- Se eu morrer, o caderno é seu. Não faz essa cara. Semente sobrevive a quem guarda.

**Por estação**

- Brotação: A Brotação é a minha estação. Tudo está tentando ao mesmo tempo. É bonito e é
  cansativo.
- Estiagem: Na Estiagem eu guardo as caixas no fundo da cisterna. Semente sente calor
  como a gente.
- Colheita: Na Colheita eu peço uma coisa só: guarda semente de tudo o que você colher.
  Tudo.
- Apagão: No Apagão nada cresce. Eu aproveito e passo o caderno a limpo. Pela quinta vez.

**Situações**

- [primeiro_encontro] Boa tarde. Hélio. Ouvi dizer que alguém voltou a plantar aquela
  terra seca. Que coragem. Que bom.
- [sumido] Pensei que você tinha desistido da terra. Muita gente desiste. Fico contente
  de estar errado.
- [desmaiou_ontem] Você caiu ontem. O corpo também tem ciclo. Respeita o dele.
- [vida_baixa] Você se machucou. Vai na Iara. E toma um chá de erva-cidreira depois, que
  eu tenho aqui.
- [saiu_da_dungeon] Você esteve lá embaixo. No Biodomo, por acaso? Viu alguma caixa com
  etiqueta escrita à mão?
- [chuva] Chuva. Veja bem, não existe coisa melhor no mundo. Eu já pesquisei.
- [tempestade_ontem] A água ontem chegou perto das caixas. Passei a noite com um balde.
  Nenhuma molhou.
- [em:cisterna, manha] Estou separando as de milho. Essa aqui germina em quatro dias.
  Essa outra, em quatro anos, se quiser.
- [em:mercado] A Marta me paga em sopa. É o melhor negócio da fronteira.
- [noite, em:beira_rio] O rio está mais baixo que no ano passado. Eu anoto isso também.
- [folga] Na Folga eu leio. Releio, na verdade. O caderno tem mais de trezentas páginas.
- [aniversario] Hoje eu faço cinquenta e cinco. Não precisa de nada. Bom, se tiver
  composto, eu não recuso.
- [aniversario_de:marta, conhecido+] Hoje é aniversário da Marta. Guardei pra ela uma
  semente de tomate que ela procura há dez anos.
- [primeiro_dia_da_estacao, brotacao] Começou a Brotação. Hoje eu planto a primeira de
  cada caixa. É uma cerimônia. Pequena.
- [marco_1, uma_vez] Sua fazenda está produzindo. Eu passei lá na porteira e contei os
  canteiros. Desculpa. É vício.
- [namorando_outro, uma_vez] Soube que você está namorando. Que bom. Semente também
  precisa de companhia pra dar certo.

**Presente**

- Amou: Terra viva! Veja bem, isso aqui vale mais que qualquer moeda. Obrigado. De
  verdade.
- Gostou: Isso é bom. Muito bom. Anotado: você tem gosto pra coisa certa.
- Neutro: Obrigado. Vou encontrar uma utilidade. Tudo tem uma.
- Não gostou: Sucata. Eu não sei o que fazer com isso. Talvez o Vitor saiba.
- Odiou: Um núcleo sintético. É peça deles. Por favor, leva embora daqui.

**Aniversário:** Você lembrou do meu aniversário. Isso vai pro caderno. Na primeira página.

---

## Dandara Reis

Líder das motoqueiras, 34 anos (plano 30). Direta, ri alto, chama o jogador de "lavoura".
Leva carga, recado e os repetidores do Kenji entre as vilas, e conhece a rota até a
cidade. Diz que não para em lugar nenhum. Romanceável.

**Distante**

- Ô, lavoura. Dandara. Pode chamar de Dada. Precisa de alguma coisa da estrada? Fala agora
  que eu saio às seis.
- Essa fazenda tava abandonada faz tempo. Bom ver luz lá. A gente usa de referência na
  pista.
- Não encosta na moto. Pode olhar. Olhar é de graça.
- Se tiver biocombustível sobrando, eu compro. Se não tiver, faz.
- Patrulha nova no trecho do viaduto. Se for pra lá, vai pela pista de baixo.

**Conhecido**

- Levo os repetidores do Kenji pras outras vilas. Ele monta, eu entrego. Ele fala, eu
  ando.
- As meninas do acampamento vieram cada uma de um lugar. Nenhuma quis ir pra cidade.
  Bora, que é isso que a gente tem em comum.
- O Rafa diz que eu corro demais. O Rafa é pedestre.
- O Vitor é o único que mexe em moto tão bem quanto eu. Não conta pra ele que eu disse.
- Tem uma estrada que sobe até a Torre deles. Eu conheço. Não te levo. Ainda.

**Amigo**

- Minha vila foi a primeira que a expansão engoliu. Minha família aceitou o crédito e foi
  morar num bloco. Eu peguei a moto do meu pai e não fui.
- Toda noite eu conserto a moto de uma das meninas. Escondido. Elas acham que a moto é que
  é boa.
- Eu falo de liberdade o tempo todo. E sou a que mais tem gente pra cuidar. Engraçado,
  né.
- Se uma das meninas não volta da estrada, eu não durmo. Já aconteceu. Não vou contar.

**Íntimo**

- Eu desligo a moto quando chego aqui. Em lugar nenhum eu faço isso.
- Minha irmã mais nova manda mensagem da cidade pela rede do Kenji. Toda semana. Eu nunca
  respondi.
- Eu sempre achei que parar era prender. Com você eu tô reaprendendo a palavra.
- Se um dia eu sumir na estrada, procura no trecho do viaduto. Eu sempre volto por lá.

**Namorando**

- Trouxe uma coisa de cada vila do caminho. Não é muito. Mas é de toda a fronteira.
- Voltei mais cedo hoje. As meninas tão rindo de mim. Deixa rirem.
- Fechou, lavoura. Agora eu tenho um ponto fixo na rota. É a sua porteira.
- Respondi minha irmã ontem. Falei de você. Ela perguntou se você tem moto. Eu disse que
  tem enxada.

**Por estação**

- Brotação: Brotação é lama. A moto vira um bicho de barro. Eu adoro.
- Estiagem: Estiagem é poeira e o meu aniversário. As duas coisas sobem na cabeça.
- Colheita: Na Colheita tem carga pra todo lado. É quando a fronteira mais precisa da
  gente.
- Apagão: No Apagão a estrada fica escura e a patrulha some. É quando eu mais rodo.

**Situações**

- [primeiro_encontro] Ô, você é da fazenda nova! Dandara, das motoqueiras. Se precisar de
  coisa da estrada, é comigo.
- [sumido] Achei que você tinha pegado a estrada. Ia ficar com inveja.
- [desmaiou_ontem] Apagou ontem, foi? Na pista a gente chama isso de pane seca. Bebe água,
  lavoura.
- [vida_baixa] Você tá em pedaços. Sobe na garupa que eu te deixo na Iara em dois
  minutos.
- [saiu_da_dungeon] Desceu lá? Me conta o caminho. A luta não, o caminho. Por onde entra,
  por onde sai.
- [chuva] Estrada lisa. Vou sair mesmo assim. A carga não espera a chuva parar.
- [tempestade_ontem] Ontem eu contei as motos três vezes. Nenhuma tombou. Nenhuma menina
  saiu.
- [em:oficina_das_motoqueiras] Passa a chave de doze. Não, essa é de dez. Tudo bem, você é
  da lavoura.
- [noite, em:fogueira] Senta na fogueira. Aqui ninguém pergunta de onde você veio.
- [em:torre_antena] O Kenji tá ouvindo o sinal da cidade. Eu vim saber por onde a patrulha
  vai passar amanhã.
- [folga] A estrada não tem folga. Mas hoje eu fico na fogueira. Só hoje.
- [aniversario] Hoje é meu aniversário. Trinta e quatro. E nenhuma multa. Isso é que é
  vitória.
- [aniversario_de:kenji, conhecido+] O Kenji faz anos hoje. Trouxe pra ele um conector
  de três vilas daqui. Ele vai chorar. Ele sempre chora.
- [apagao, noite, amigo+] Noite de Apagão. Vem comigo até o viaduto um dia. Dá pra ver a
  cidade apagando bairro por bairro.
- [marco_2, uma_vez] Sua colheita tá chegando em vila que eu nem sabia que comia. Tô
  levando com o seu nome na caixa.
- [namorando_outro, uma_vez] Fiquei sabendo que você tá com alguém. Fechou. Que seja
  gente boa, senão eu fico sabendo.

**Presente**

- Amou: Biocombustível! Você entende de gente, lavoura. Isso aqui me leva três vilas
  adiante.
- Gostou: Opa, serve. Valeu. Vai pra bolsa da moto.
- Neutro: Beleza. Obrigada. Vou achar onde encaixar.
- Não gostou: Repolho. Eu vou dar pras meninas. Sem ofensa.
- Odiou: Nanogel não. Tem cheiro de posto de realocação. Leva embora.

**Aniversário:** Você lembrou. Ninguém lembra de quem tá sempre de passagem. Você lembrou.

**Buquê aceito:** Eu sempre disse que não paro em lugar nenhum. Acho que acabei de parar.
Fechou, lavoura. Sim.

---

## Lúcia Prado

Fiscal da expansão, 41 anos (plano 30). Educada, fala em números, acredita que a cidade
traz água, luz e hospital. Mora na cidade e vem de ônibus uma vez por semana. Foi chefe
da Sol. Não é vilã de desenho. Não é romanceável.

**Distante**

- Bom dia. Lúcia Prado, do programa de expansão. Não vim incomodar, vim conhecer.
- Veja, eu entendo a desconfiança. Mas a cidade tem hospital a vinte minutos daqui. A vila
  tem a Iara.
- Os números mostram que uma fazenda nessa terra fecha no vermelho em dois anos. Mas os
  números já erraram antes.
- Eu venho toda semana, no mesmo ônibus. Pode me procurar se tiver dúvida sobre o
  programa.
- Com todo respeito, essa bomba solar não aguenta mais uma Estiagem. A cidade aguenta.

**Conhecido**

- Eu não sou daqui, mas sou de um lugar igual. Por isso me mandam pra cá. Dizem que eu
  falo a língua.
- Na cidade ninguém almoça na praça. Aqui eu almoço. Não conta no relatório.
- A Marta me olha como se eu fosse a seca em pessoa. Eu respeito. Ela tá defendendo o que
  é dela.
- A adesão ao programa nesta vila é de zero por cento. É o pior indicador da fronteira.
  Eu acho isso, sinceramente, admirável.
- A sua fazenda é o único indicador que sobe por aqui. Isso me deixa curiosa. E
  preocupada, um pouco.

**Amigo**

- Minha mãe morreu de uma infecção que o hospital da cidade curava em dois dias. A vila
  dela não tinha hospital. É por isso que eu faço o que faço.
- Eu trago no bolso um saquinho de semente de tomate da minha mãe. Nunca plantei. Não sei
  onde.
- A Sol trabalhou comigo. Era a melhor. Eu não vou dizer mais nada sobre isso.
- Às vezes eu desço do ônibus e fico um minuto parada no ponto. Só respirando. Na cidade
  o ar é filtrado.

**Íntimo**

- Eu sabia para onde a Sol tinha ido. Nunca escrevi no relatório. Ela não sabe disso.
- Eu não sei mais o que estou entregando quando a cidade chega. Antes eu sabia. Antes eu
  tinha certeza.
- Se eu sair do programa, mandam alguém que não almoça na praça. É por isso que eu fico.
  É o que eu digo pra mim.
- Toma. A semente da minha mãe. Planta na sua fazenda. Eu queria ver ela crescer em algum
  lugar.

**Por estação**

- Brotação: A cidade chama a Brotação de "trimestre de adesão". Eu chamo de primavera,
  quando ninguém escuta.
- Estiagem: Na Estiagem eu uso a seca como argumento. Eu sei. Não me orgulho disso.
- Colheita: Na Colheita a vila fica bonita. Fica mais difícil escrever o relatório.
- Apagão: Na cidade dizem que o Apagão é "ajuste de demanda". Aqui é só escuro. Eu
  prefiro a palavra de vocês.

**Situações**

- [primeiro_encontro] Bom dia. Você é a pessoa da fazenda nova? Lúcia Prado. Eu estava
  curiosa pra te conhecer. Profissionalmente, claro.
- [sumido] Faz tempo que não te vejo. Na cidade, quem some assim costuma ter mudado de
  endereço. Que bom que aqui não é a cidade.
- [vida_baixa] Você se machucou. Se quiser, eu consigo um encaminhamento pro hospital da
  cidade. Sem compromisso. Eu falo sério.
- [saiu_da_dungeon] Você esteve nas instalações antigas? Com todo respeito, aquilo é
  propriedade da corporação. E também é perigoso. Nessa ordem eu devia dizer, mas não é.
- [chuva] O ônibus atrasou com a chuva. Eu cheguei molhada e com o relatório borrado. Não
  conta pra ninguém.
- [em:mercado] A Marta não me vende nada. Eu compro do mesmo jeito, deixando o dinheiro
  no balcão.
- [em:praca] Eu almoço aqui toda semana. É a única hora que eu não sou fiscal.
- [em:oficina] O Vitor me olha como se eu fosse uma peça com defeito. Talvez eu seja.
- [aniversario] É meu aniversário. Na cidade ninguém lembra. Eu nem sei por que estou
  contando.
- [aniversario_de:sol, amigo+] Hoje é aniversário da Sol. Eu lembro. Eu sempre lembrei.
  Ela não precisa saber.
- [colheita, amigo+] Essa época me lembra da minha mãe. Ela colhia tomate de chapéu de
  palha. Eu achava aquilo pequeno. Não era.
- [marco_1, uma_vez] Sua produção apareceu nos números da fronteira. Meu chefe perguntou
  quem é você. Eu disse que não sabia.
- [marco_2, uma_vez] Você virou um problema no meu relatório. Um problema bom. Eu escrevo
  isso com cuidado.

**Presente**

- Amou: Tomate. Do jeito que a minha mãe plantava. Obrigada. Desculpa, me dá um minuto.
- Gostou: Muito gentil. Obrigada, de verdade.
- Neutro: Obrigada. Vou levar comigo pra cidade.
- Não gostou: Com todo respeito, eu não tenho onde guardar isso no ônibus.
- Odiou: Biocombustível. Na cidade dizem que isso não existe. Eu prefiro não ter na mão a
  prova de que existe.

**Aniversário:** Você lembrou. Na cidade, ninguém. Aqui, você. Eu não sei o que fazer com
isso.

---

## Téo

Criança da vila, 10 anos, sobrinho do Kenji (plano 30). Corre o mapa inteiro, coleciona
osso e lenda, pergunta tudo e exagera tudo. A mãe trabalha na cidade e vem nas Folgas,
quando consegue. Não é romanceável.

**Distante**

- Você é da fazenda nova? Tem bicho? Tem trator? Tem osso?
- Sabia que tem um osso no campo maior que eu? Juro. Eu medi deitado.
- Eu sou o Téo. Sobrinho do tio Kenji. Ele é o da antena. Ele subiu sozinho. Duas vezes.
- O Bento disse que lá dentro da Galeria tem um robô que varre gente. Varre mesmo.
- Minha mochila tem catorze tesouros. Não pode ver. Pode ver um.

**Conhecido**

- Achei uma placa queimada perto do viaduto. É de nave espacial. Juro. Bom, o tio disse
  que não, mas ele não viu.
- A Dandara disse que quando eu crescer eu posso andar de moto. Ela disse "vamos ver",
  que é sim.
- O Hélio sabe o nome de toda planta. Até das feias. Principalmente das feias.
- O tio Kenji esquece de jantar. Aí eu esqueço também. Aí a Marta lembra os dois.
- Se você achar osso, me dá? Eu troco por pedra. Tenho pedra boa.

**Amigo**

- Não tem escola aqui. O tio me ensina conta com rádio. Eu sei somar frequência.
- Eu durmo com a lanterna acesa. Não é medo. É pra achar osso de noite se precisar.
- A Dandara me deixou sentar na moto. Parada. Mas valeu.
- Quando eu crescer eu vou entrar na Galeria e trazer o robô pra casa. Pra ele varrer o
  meu quarto.

**Íntimo**

- Minha mãe vem na Folga. Às vezes. Você acha que ela vem nessa?
- Eu guardo a passagem de ônibus que ela deixou. Um dia eu vou atrás dela. Não conta pro
  tio.
- O tio Kenji acha que tá fazendo tudo errado comigo. Ele não tá. Fala pra ele. Pra mim
  ele não acredita.

**Por estação**

- Brotação: Brotação tem bicho saindo de tudo que é buraco. E meu aniversário!
- Estiagem: Na Estiagem o vento descobre osso novo. É a melhor estação pra caçar.
- Colheita: Na Colheita a Marta dá milho escondido. Não conta que eu contei.
- Apagão: No Apagão fica escuro de dia. Eu não tenho medo. Eu só ando mais perto do tio.

**Situações**

- [primeiro_encontro] Oi! Você é da fazenda nova? Eu vi o caminhão da mudança! Bom, não
  vi, mas imaginei.
- [sumido] Você sumiu! Eu procurei você no mapa inteiro. Bom, em metade.
- [vida_baixa] Você se machucou? Você vai morrer? Vai na Iara. Cuidado que ela dá vacina.
- [saiu_da_dungeon] Você entrou lá! Tinha robô que varre gente? Ele varreu você? Conta
  tudo!
- [chuva] Chuva! Tem poça no mapa inteiro! Eu já pulei em todas. Faltou uma.
- [tempestade_ontem] Ontem eu e o tio contamos raio. Ele contou quarenta. Eu contei
  quarenta e um. Eu ganhei.
- [folga] Hoje é Folga. Eu vou esperar no ponto de ônibus. Minha mãe pode vir.
- [em:porta_da_galeria] Shhh. O Bento tá contando a do cano que cantava. É a melhor.
- [em:mirante] Daqui dá pra ver o campo de ossos inteiro. Eu já achei sete lá. Oito, se
  contar o pequeno.
- [noite, em:torre_antena] O tio deixa eu ficar na antena até as nove. Eu escuto o rádio
  das outras vilas. Tem uma que só toca música.
- [aniversario] Hoje é meu aniversário! Eu fiz dez. Bom, onze. Não, dez. Dez!
- [aniversario_de:kenji] Hoje é aniversário do tio! Ele esqueceu. Eu não. Eu fiz um
  cartão de papelão com antena.
- [aniversario_de:bento] Hoje o Bento faz anos! Eu dei pra ele um osso. O melhor. Quer
  dizer, o segundo melhor.
- [marco_1, uma_vez] Todo mundo tá falando da sua fazenda. Eu falei que fui o primeiro a
  saber. Fui o segundo, mas o Bento não conta.

**Presente**

- Amou: Milho! Você é a pessoa mais legal da fronteira. Depois do tio. Empatado com o
  tio.
- Gostou: Isso é tesouro! Vai pra mochila. Agora são quinze.
- Neutro: Ah. Obrigado. Dá pra trocar por osso?
- Não gostou: Repolho? Eu não como verde. O tio também não, mas finge.
- Odiou: Isso é remédio! Tem gosto de remédio! Por que você me deu remédio?

**Aniversário:** Você lembrou! Você lembrou do meu aniversário! Vou contar pra todo mundo
até a Folga.

---

## Zeca

Caminhoneiro, 52 anos (plano 30). Para debaixo do viaduto um dia por semana e vende o que
ninguém da vila vende. Fala alto, puxa assunto, traz a notícia de graça. É o último
motorista de carne e osso da rota. Não é romanceável.

**Distante**

- Olha a freguesia! Zeca, da estrada. Chegou fio óptico novinho. Preço de amigo, câmbio.
- Paro aqui uma vez por semana. Se perder o dia, só na outra. A estrada não espera.
- Na estrada a gente aprende: quem tem combustível tem amigo.
- Fazenda nova? Então é carga nova. Eu levo o que você colher pras outras vilas.
- Não pechincha com o Zeca. O Zeca já faz o preço pechinchado.

**Conhecido**

- A Dandara é a melhor freguesa e a mais pão-dura. Discute centavo por meia hora e depois
  me paga um café.
- Trinta anos de caminhão. Ele tem mais remendo que pintura. Igual a mim.
- Lá no porto já não tem motorista. Só comboio sem gente. Eu passo buzinando pra eles.
  Eles não buzinam de volta.
- O Téo sabe o dia que eu chego melhor que eu. Fica no viaduto desde cedo. Leva bala de
  graça.
- Na vila do lago tá faltando célula de energia. Na do morro, sobrando. Eu sou a ponte
  das duas. Câmbio.

**Amigo**

- Eu tinha doze amigos de estrada. Hoje tenho dois. Os outros viraram comboio. Quer dizer,
  foram trocados por um.
- Eu digo que não tenho casa. Mas conheço a família de toda parada. Acho que a casa é
  comprida.
- Já dei carona pra Lúcia quando o ônibus quebrou. Ela falou de números o caminho
  inteiro. No fim, chorou. Não sei por quê.

**Íntimo**

- Meu caminhão tem trinta anos. Se ele parar, eu paro junto.
- Cortaram a minha rota pro fim do ano. Ainda não decidi se paro ou se saio dela.
- Se um dia eu aparecer com o caminhão e não for embora, a sua fazenda tem lugar? Pergunto
  por perguntar.

**Por estação**

- Brotação: Na Brotação a estrada vira sabão. Eu chego atrasado, mas chego.
- Estiagem: Na Estiagem o asfalto derrete. Eu dirijo descalço. Não conta pra fiscalização.
- Colheita: Na Colheita eu compro tudo o que a fronteira produz. Me guarda um pouco do
  seu.
- Apagão: No Apagão a estrada fica escura e o farol é o que me resta. Ainda bem que o meu
  é bom.

**Situações**

- [primeiro_encontro] Olha a freguesia nova! Zeca, da estrada. Primeira compra tem
  desconto. A segunda também, se você voltar.
- [sumido] Perguntei de você em três vilas. Ninguém sabia. Que bom que você tá aqui.
- [vida_baixa] Senta aí na boleia que eu tenho um negócio pra isso. Brincadeira. Vai na
  Iara, câmbio.
- [saiu_da_dungeon] Desceu lá? Achou peça? Eu compro. Achou ferida? Isso eu não compro.
- [chuva] Choveu na estrada toda. O caminhão chegou lavado. Foi o único banho dele no
  mês.
- [em:parada_do_caminhao, manha] Cheguei agora. Ainda tô arrumando a carga. Olha, mas
  não pega.
- [aniversario] Hoje eu faço cinquenta e dois. Comemoro na estrada, como sempre. Mas hoje
  com você.
- [aniversario_de:dandara, conhecido+] Hoje é aniversário da Dandara. Vou dar desconto
  pra ela. De cinco por cento. Ela vai brigar por dez.
- [primeiro_dia_do_ano] Ano novo, rota velha. Mas tô aqui, câmbio.
- [marco_1, uma_vez] Sua fazenda tá ficando conhecida. Me pediram produto seu em duas
  vilas. Eu disse que conheço quem planta.
- [marco_2, uma_vez] Agora eu tenho coisa que só vendo pra freguesia boa. Você entrou na
  lista.

**Presente**

- Amou: Biocombustível! Isso rende mais que qualquer venda da semana. Você é dos meus.
- Gostou: Opa, isso vai na boleia. Obrigado, freguesia.
- Neutro: Obrigado. Vou levar pra alguém que precise.
- Não gostou: Fibra? Isso eu nem vendo. Mas aceito, que presente não se recusa.
- Odiou: Composto? Na boleia? Vai feder até o porto.

**Aniversário:** Lembrou do aniversário do caminhoneiro? Ninguém lembra do caminhoneiro.
Câmbio, obrigado.

---

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
