---
name: executar-plano
description: Use ao começar a implementar uma feature do Cyber Moon a partir de um arquivo de equipe/planos/, ao perguntar qual é a próxima feature a fazer, ao retomar um plano interrompido no meio, ou quando alguém pede para implementar colisão, som, itens, inventário, plantio, status, armas, inimigos, ciclo de dia, estações, calendário, clima, NPCs, diálogo, amizade ou comércio.
---

# Executar um plano do Cyber Moon

Os planos ficam em `equipe/planos/`, numerados de 01 a 17 na ordem de dependência
explicada em `equipe/ordem-de-execucao.md`.

## Escolher o plano

Pegue o de menor número que ainda não está marcado como feito em
`equipe/ordem-de-execucao.md`. A numeração não é sugestão: um plano assume que os
anteriores existem, e implementar fora de ordem gera retrabalho. Se houver um motivo
real para pular, registre o motivo em `equipe/pendencias.md`.

Os planos 01 (colisão) e 02 (som) são prioridade, e depois desses dois o Bernardo grava
um vídeo de entrega. Veja `equipe/gravacao-de-video-obs.md`.

## Antes de escrever código

1. Leia o plano inteiro, do começo ao fim, antes da primeira linha de código. A seção
   "Fora de escopo" no fim costuma responder a dúvida que aparece no meio.
2. Leia os arquivos que o plano diz que vai modificar. O plano foi escrito num momento
   anterior e o código pode ter mudado.
3. Carregue a skill `padrao-cyber-moon`.
4. Transforme as tarefas do plano numa lista de afazeres, uma entrada por tarefa.

## Durante

Uma tarefa por vez, na ordem. Cada tarefa do plano termina com uma verificação
observável: rode o jogo, confirme o comportamento descrito, e só então passe para a
próxima. Não encadeie três tarefas e verifique no fim, porque quando quebrar você não
vai saber qual das três quebrou.

Cada tarefa concluída e verificada vira um commit. Veja a skill `commitar`.

Quando o plano estiver errado, e vai acontecer, não force o plano. O plano foi escrito
sem o código na frente. Se a realidade do repositório contradiz o plano, siga a
realidade, e anote a divergência para registrar no fim.

## Quando travar

Antes de improvisar uma solução grande, veja se a dúvida é de design ou de execução.

- Dúvida de execução (como fazer isso no Godot) se resolve investigando: leia o código
  vizinho, rode um teste pequeno, consulte a skill `rodar-o-jogo`.
- Dúvida de design (o que o jogo deveria fazer aqui) não se resolve sozinha. Escolha a
  opção mais simples que atende ao plano, deixe funcionando, e registre a decisão e a
  alternativa em `equipe/pendencias.md` para o Antonio revisar quando voltar.

Não deixe a feature pela metade esperando resposta. Deixe funcionando com a decisão
mais simples e documentada.

## Ao terminar

1. Rode o jogo uma última vez e confirme que nada do que já existia quebrou. Ande com o
   personagem, use as ferramentas, veja o console limpo.
2. Marque o plano como feito em `equipe/ordem-de-execucao.md`.
3. Registre em `equipe/pendencias.md` tudo que ficou de fora, toda decisão de design que
   você tomou sozinho e toda divergência entre plano e realidade.
4. Atualize a documentação em `game/docs/` que a feature tornou desatualizada. Ação de
   entrada nova vai para `entrada.md`. Autoload ou sinal novo vai para `arquitetura.md`.
   Termo de design novo vai para `glossario.md`.
5. Commit final e push.

## O que nunca fazer

- Dizer que está pronto sem ter rodado o jogo e visto o comportamento acontecer.
- Implementar feature que o plano não pediu porque pareceu uma boa ideia. Anote a ideia
  em `equipe/sugestoes-de-features.md` e siga o plano.
- Refatorar sistema que a feature atual não toca.
