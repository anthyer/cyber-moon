# Biblioteca de diálogos

Falas dos seis NPCs, organizadas para virar `.tres` de `Conversa` e `NoDialogo` na tarefa
7 do plano 16.

## Como transcrever

Cada fala vira um `NoDialogo`. As faixas de relacionamento preenchem
`relacionamento_minimo` e `relacionamento_maximo` em pontos, não em corações:

| Faixa | Corações | mínimo | máximo |
|---|---|---|---|
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
vida consertando o que a cidade joga fora. Não confia em nada que venha de lá, incluindo
remédio. Não é romanceável.

**Distante**

- Se veio pedir conserto, entra na fila.
- Fazenda nova, é? Boa sorte. O último durou dois meses.
- Não mexe nas peças. Cada uma tem dono.
- Se achar metal por aí, eu compro. O resto não me interessa.

**Conhecido**

- Você aguentou mais que eu apostei. Isso é elogio.
- Peça boa é peça que já foi de alguém. As novas vêm com defeito de fábrica.
- A cidade avança um metro por ano. Ninguém mede, mas eu meço.
- Trouxe sucata? Sempre trouxe. Deixa aí.

**Amigo**

- Meu pai plantava onde hoje é estacionamento. Aquele ali, o do letreiro azul.
- Consertei o gerador da clínica três vezes esse ano. A Iara acha que é milagre.
- Você trabalha demais. Isso é conselho, não elogio.
- Guardei um servomotor pensando em você. Não pergunta por quê.

**Íntimo**

- Se um dia eu não estiver aqui, a oficina fica com você. Já disse pro Kenji também, mas
  ele não sabe segurar chave inglesa.
- Tem gente que resiste com discurso. Eu resisto consertando o que eles querem que a
  gente jogue fora.
- Você me lembra o velho. Ele também não sabia parar.

**Por estação**

- Brotação: Chuva boa pra planta, ruim pra ferramenta. Cobre o que for de metal.
- Estiagem: Nessa época a cidade liga mais máquina. Dá pra ouvir daqui, de noite.
- Colheita: Melhor época do ano. Todo mundo tem o que fazer e ninguém vem me encher.
- Apagão: Racionam energia lá e sobra escuridão pra cá. Todo ano a mesma coisa.

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
tropeça nas palavras quando anima. Cresceu ouvindo que a cidade é o futuro e decidiu
provar o contrário usando as ferramentas dela. Romanceável.

**Distante**

- Opa, você é da fazenda nova, né? Legal, legal. Eu sou o Kenji. Da antena.
- Se a sua energia oscilar, não é a cidade. É eu testando coisa.
- Você tem fio óptico? Não? Beleza. Se achar, avisa.
- Desculpa, tô no meio de uma coisa. Depois a gente conversa direito.

**Conhecido**

- A antena caiu de novo. Terceira vez esse mês. Eu juro que dessa vez foi vento.
- Sabia que dá pra ouvir a rede da corporação daqui? Não que eu ouça. Mas dá.
- O Vitor diz que eu não sei segurar chave inglesa. Ele tem razão, mas não fala pra ele.
- Você planta aquelas coisas verdes? Como é que sabe qual é qual?

**Amigo**

- Montei um repetidor com peça que o Vitor ia jogar fora. Funciona melhor que o oficial.
- Minha mãe trabalhou lá dentro. Dezoito anos. Saiu com um crachá e nenhum documento.
- Às vezes eu subo na torre só pra ver a fronteira. Daqui parece que a gente tá ganhando.
- Se eu sumir uns dias, é porque tô rastreando uma coisa. Não se preocupa. Muito.

**Íntimo**

- Eu construí uma antena pra falar com o mundo inteiro e a única pessoa com quem eu quero
  falar mora a dez minutos daqui.
- Deixei um canal aberto só pra você. Frequência 88.2. Não conta pra ninguém.
- Você é a única pessoa que me escuta falar de rede por mais de dois minutos.

**Por estação**

- Brotação: Umidade mata equipamento. Mas o cheiro compensa.
- Estiagem: A torre esquenta tanto que eu já queimei a mão duas vezes.
- Colheita: Todo ano nessa época a interferência aumenta. Deve ser a colheita da cidade.
- Apagão: Menos energia lá, menos ruído aqui. É a melhor época pra escutar longe.

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

Entregador, 27 anos. Passa o dia correndo a fronteira levando encomenda. Bem humorado,
direto, cansado. Conhece todo mundo dos dois lados. Romanceável.

**Distante**

- E aí. Se precisar mandar alguma coisa pra fora, eu levo.
- Fazenda nova? Anota o endereço direito que eu erro os dois primeiros meses.
- Correndo, correndo. Depois eu paro.
- Você não viu um pacote azul por aí, viu? Não? Beleza. Problema meu.

**Conhecido**

- Hoje eu fiz o trajeto do rio duas vezes. Duas. Minhas pernas te odeiam.
- A ponte tá cedendo. Todo mundo sabe e ninguém conserta.
- Se você quiser mandar produto pra dentro da cidade, dá. Não é legal, mas dá.
- Já vi fazenda que durou trinta anos virar depósito em três meses. Não fica confortável.

**Amigo**

- Eu conheço cada buraco desse caminho. Fecho o olho e chego.
- Entreguei uma carta pra Sol semana passada. Selo corporativo. Ela não abriu na minha
  frente.
- Meu plano era juntar dinheiro e sair daqui. Faz seis anos que é o plano.
- Guarda um pouco daquele pão pra mim? Eu como correndo, mas eu como.

**Íntimo**

- Todo dia eu passo por aqui e todo dia eu ando mais devagar nesse trecho. Já reparei.
- Descobri que não quero sair daqui. Quero ter pra onde voltar. É diferente.
- Se um dia eu parar de correr, é aqui que eu paro.

**Por estação**

- Brotação: Lama até o joelho. Adoro e odeio ao mesmo tempo.
- Estiagem: Dá pra fritar ovo no asfalto da via velha. Já tentei. Funciona.
- Colheita: Época boa. Todo mundo manda coisa, e coisa pesada paga mais.
- Apagão: Escurece às quatro e meia e eu ainda tenho seis entregas. Faz a conta.

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

Dona do mercado, 58 anos. Direta, calorosa e sem paciência para conversa mole. Conhece a
história de todo mundo e conta quando quer. Vende semente, ferramenta e comida. Não é
romanceável.

**Distante**

- Bom dia. Semente tá na prateleira do fundo, e o preço tá na plaquinha.
- Você é o da fazenda do morro. Já sei. Aqui todo mundo sabe tudo.
- Primeira safra é sempre ruim. Não desanima com isso.
- Compra semente de estação. Fora de estação não nasce, e você vai vir reclamar comigo.

**Conhecido**

- Sua cenoura tá melhor que a do ano passado. E eu vendi a semente dos dois anos.
- Tem gente que compra semente e não compra regador. Aí planta e chora.
- Meu marido plantava. Trinta e dois anos. Depois virou isso aqui tudo estacionamento.
- Você come direito? Não parece.

**Amigo**

- Eu abro essa loja há vinte e seis anos e nunca fechei um dia. Nem no enterro dele.
- O Kenji vem aqui comprar comida pronta e acha que eu não vejo que ele não cozinha.
- Guarda semente da sua própria colheita. Não conta pro fornecedor que eu falei isso.
- Se um dia faltar dinheiro, você leva e paga depois. Uma vez só. Não abuse.

**Íntimo**

- Você virou parte do lugar. Isso não acontece com todo mundo que chega.
- Quando eu não puder mais abrir, alguém abre. Talvez você. Pensa nisso sem pressa.
- Sabe o que me faz continuar? Ver saco de semente saindo daqui e voltando como comida.

**Por estação**

- Brotação: Época boa de venda. Todo mundo acha que esse ano vai ser diferente.
- Estiagem: Se não regar, não colhe. E não adianta vir reclamar da semente.
- Colheita: Agora eu compro mais do que vendo. Traga tudo.
- Apagão: Nada nasce. Guarde comida e paciência.

**Presente**

- Amou: Ah, minha filha. Isso aqui é comida de verdade. Vou comer devagar.
- Gostou: Que caprichado. Obrigada.
- Neutro: Obrigada, viu. Deixa aí no balcão.
- Não gostou: Isso é ferro velho. Eu vendo comida.
- Odiou: Tira isso da minha loja. Cheira a queimado e espanta freguês.

**Aniversário:** Na minha idade a gente para de contar. Mas ganhar presente ainda é bom.

---

## Iara Nakamura

Médica da clínica, 29 anos. Calma, observadora, escolhe as palavras. Atende de graça
quem não pode pagar, e isso a mantém cansada. Detesta estimulante porque passa o dia
consertando quem usa. Romanceável.

**Distante**

- Bom dia. Se estiver machucado, entra. Se não, também entra, mas espera.
- Você é novo aqui. Aparece pra um exame antes de precisar.
- Bebe água. É o conselho médico mais ignorado do mundo.
- Não tenho anestésico essa semana. Tenta não se cortar.

**Conhecido**

- Atendi doze pessoas hoje. Três pagaram. É uma média boa.
- Suas mãos estão calejadas. Isso é bom sinal, quer dizer que você usa elas.
- O Vitor conserta o gerador daqui de graça e finge que foi de passagem.
- Você dorme quanto por noite? Não responde. Já sei pela sua cara.

**Amigo**

- Estudei na cidade. Voltei porque lá eu tratava executivo e aqui eu trato gente.
- Perdi um paciente mês passado. Chegou tarde demais. Eu ainda penso nisso todo dia.
- Trouxe beterraba? Você lembrou. É a única coisa que eu consigo comer quando tô cansada.
- Quando você aparece aqui sem estar machucado, o meu dia melhora.

**Íntimo**

- Eu cuido de todo mundo. Você é a única pessoa que pergunta como eu estou.
- Tem uma janela na clínica que dá pra sua fazenda. Eu olho mais do que devia.
- Se eu pudesse escolher um lugar pra cansar, era esse. Perto de você.

**Por estação**

- Brotação: Época de alergia. Metade da vila passa aqui espirrando.
- Estiagem: Insolação, desidratação, queimadura. Todo ano igual.
- Colheita: Todo mundo se machuca colhendo com pressa. Vai devagar, por favor.
- Apagão: Frio e pouca comida. É a estação que mais me dá trabalho.

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

Ex-analista da corporação, 26 anos. Desertou há dois anos e mora sozinha no mirante.
Reservada, irônica, mede o que fala. Sabe exatamente como a expansão funciona por dentro,
e é isso que a assombra. Romanceável.

**Distante**

- Oi. Não precisa puxar assunto por educação.
- Eu moro ali em cima. Não é hospitalidade, é aviso pra não subir sem falar.
- Você planta. Legal. É mais útil que o que eu fazia antes.
- Se aparecer alguém de terno perguntando de mim, você não me viu.

**Conhecido**

- Eu desenhava mapa de expansão. Sua fazenda estava num deles, com uma data.
- Não me pergunta a data. Sério.
- Aqui do mirante dá pra ver as duas coisas ao mesmo tempo. É didático e é horrível.
- Você é a primeira pessoa que não me perguntou por que eu saí de lá.

**Amigo**

- Eu tinha um apartamento com vista pra nada e um salário que pagava por isso.
- Recebi uma carta com selo deles semana passada. Não abri. Ainda não.
- Sabe o que eu mais sinto falta? De nada. Isso me assusta um pouco.
- Você me deu tomate uma vez e eu chorei sozinha depois. Não pergunta.

**Íntimo**

- Eu fugi de um lugar que media tudo e vim parar onde ninguém mede nada. Levei dois anos
  pra entender que era isso que eu queria.
- Abri a carta. Era uma oferta de volta. Eu queimei no fogão.
- Eu sei exatamente quanto tempo essa fronteira aguenta. E mesmo assim eu quero ficar.

**Por estação**

- Brotação: Lá dentro não tem estação. Só temperatura ajustada. Eu tinha esquecido disso.
- Estiagem: Calor de verdade. Suor de verdade. Ainda me impressiona.
- Colheita: Essa é a estação que eles mais expandem. Aproveitam que todo mundo tá ocupado.
- Apagão: Quando falta luz aqui é porque sobra lá. É literalmente isso.

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
