# Leia primeiro

Bernardo, esta pasta é o pacote de trabalho para as próximas semanas, enquanto o
Antonio estiver fora. Ela tem tudo que você precisa para tocar o Cyber Moon sozinho:
como montar o ambiente, o que fazer, em que ordem, e o que fazer quando travar.

## Os cinco minutos iniciais

1. Leia `instalacao.md` e monte o ambiente. São Godot, o agente e o servidor MCP.
2. Leia `ordem-de-execucao.md`. Ele lista as 17 features na ordem em que devem ser
   feitas e explica por que a ordem é essa.
3. Abra `planos/01-colisao-de-cenario.md` e comece.

## Como o trabalho funciona

Cada feature tem um arquivo próprio em `planos/`, numerado. O plano descreve o que
construir, quais arquivos tocar, e termina com uma seção de fora de escopo dizendo o que
deliberadamente não entra. Não é para seguir ao pé da letra quando a realidade do código
contradiz o plano, é para usar como mapa.

O repositório tem quatro skills em `.claude/skills/` que o agente carrega sozinho
conforme a situação: uma com o padrão de código, uma com o jeito de rodar e depurar,
uma com o formato de commit, e uma com o roteiro de executar um plano. Você não precisa
invocar nada na mão.

## As duas prioridades, e o vídeo

Os planos 01 (colisão de cenário) e 02 (som) são prioridade. **Depois de terminar esses
dois, grave um vídeo mostrando o resultado.** O `gravacao-de-video-obs.md` explica como
instalar e configurar o OBS do zero, incluindo o que enquadrar e o que falar.

## Duas coisas que dependem de você

**Os clipes de áudio.** O plano 02 constrói o sistema de som inteiro funcionando com
zero arquivos de áudio carregados, justamente para não travar esperando. Mas o vídeo
fica muito melhor com passo tocando. Providencie os clipes de passo e a música de fundo
antes de gravar. O `planos/02-som.md` diz exatamente quantos arquivos, em que formato e
com que nome.

**A pergunta do Epidemic Sound.** Está no topo do `planos/02-som.md`. Se você usa a
plataforma, dá para configurar o MCP dela e passar a construir os sons restantes direto
pelo agente. Responda essa antes de começar o plano 02.

## Quando travar

- Dúvida de como fazer no Godot: investigue, a skill `rodar-o-jogo` tem as armadilhas
  que já morderam este projeto.
- Dúvida de o que o jogo deveria fazer: escolha a opção mais simples que atende ao
  plano, deixe funcionando, e anote a decisão em `pendencias.md`. Não deixe a feature
  pela metade esperando o Antonio responder.

## Onde registrar as coisas

- `pendencias.md`: o que ficou faltando, decisão de design que você tomou sozinho,
  divergência entre plano e código real. É o primeiro arquivo que o Antonio vai ler
  quando voltar.
- `sugestoes-de-features.md`: ideia que surgiu e não estava em nenhum plano. Anote lá em
  vez de implementar por fora.
- `ordem-de-execucao.md`: marque o plano como feito quando terminar.

## Mapa da pasta

```
equipe/
  leiame.md                   este arquivo
  instalacao.md               Godot, agente, MCP
  controles.md                mapa de controles alvo (Minecraft e Rune Factory 4)
  ordem-de-execucao.md        as 17 features, a ordem, e o que ja foi feito
  biblioteca-de-dialogos.md   falas dos 6 NPCs, para virar .tres no plano 16
  gravacao-de-video-obs.md    instalar e configurar o OBS
  pendencias.md               o que faltou
  sugestoes-de-features.md    ideias fora dos planos
  ferramentas/
    dividir_passos.py         corta um clipe com varios passos em arquivos separados
  planos/
    01-colisao-de-cenario.md  ate  17-comercio-e-economia.md
```
