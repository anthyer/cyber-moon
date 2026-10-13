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
