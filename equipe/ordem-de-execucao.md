# Ordem de execução

As 17 features na ordem em que devem ser feitas. A numeração não é sugestão: cada plano
assume que os anteriores existem. Marque o checkbox quando terminar.

## Situação

- [ ] 01 Colisão de cenário (**prioridade**)
- [ ] 02 Som (**prioridade**)
- [ ] Vídeo de entrega das duas prioridades
- [ ] 03 Sistema de itens
- [ ] 04 Inventário
- [ ] 05 Barra de acesso rápido
- [ ] 06 Plantio e colheita
- [ ] 07 Status: vida e stamina
- [ ] 08 Armas
- [ ] 09 Inimigos
- [ ] 10 Ciclo de dia e noite
- [ ] 11 Estações
- [ ] 12 Calendário
- [ ] 13 Clima
- [ ] 14 NPCs: rotinas e walk cycle
- [ ] 15 Sistema de diálogo
- [ ] 16 Amizade e romance
- [ ] 17 Comércio e economia

## Por que essa ordem

**01 antes de tudo.** A colisão define o esquema de camadas de física que praticamente
toda feature de baixo usa: item no chão precisa de camada própria para o jogador pegar,
inimigo precisa detectar o jogador, área de interação precisa não colidir com parede. Se
o esquema de camadas nascer depois, cada feature inventa a sua e vira bagunça. A colisão
também é o que faz o raycast de superfície do plano 02 acertar alguma coisa.

**02 depois de 01.** O passo varia por superfície, e a superfície é lida por um raycast
para baixo que precisa bater num corpo com colisão. Sem o plano 01, o raycast atravessa
o chão e o som não tem como saber se o pé está na grama ou no asfalto.

**03, 04, 05 juntos, nessa ordem.** O item é o dado, o inventário é onde ele fica, a
barra rápida é a fatia do inventário que aparece na tela. Não dá para fazer a barra
antes do inventário porque os slots rápidos são slots do inventário.

**06 depois de 03.** A colheita produz item e joga no chão. Precisa do item existindo e
do sistema de item dropado, que nasce no plano 03.

**07 antes de 08 e 09.** Vida e stamina são o que arma tira e o que inimigo ataca. Fazer
inimigo antes de existir vida significa fazer o inimigo duas vezes.

**08 antes de 09.** Mais fácil testar arma nova batendo em alvo parado do que em inimigo
que ainda não anda direito. E o inimigo precisa saber levar dano de arma.

**10 antes de 11, 12 e 13.** Estação conta dias, calendário mostra dia e estação, clima
sorteia por dia. Todos leem o mesmo relógio, que nasce no plano 10.

**14 antes de 15 e 16.** O NPC precisa existir e andar antes de ter conversa. A conversa
precisa existir antes da amizade, porque conversar é o que dá ponto de amizade.

**17 por último.** O comércio amarra tudo: vende o que a fazenda produziu (06), compra
semente (06) e baú (04), roda em NPC (14), e o balanceamento só faz sentido quando os
números dos outros sistemas já existem.

## O grafo, resumido

```
01 colisao
 |
 +-- 02 som
 |
 +-- 03 itens -- 04 inventario -- 05 barra rapida
 |                     |
 |                     +-- 06 plantio e colheita
 |
 +-- 07 status -- 08 armas -- 09 inimigos
 |
 +-- 10 dia e noite -- 11 estacoes -- 12 calendario
 |                        |
 |                        +-- 13 clima
 |
 +-- 14 npcs -- 15 dialogo -- 16 amizade
                                  |
                       17 comercio (depende de 04, 06, 14)
```

## Se precisar sair da ordem

Acontece. Se um plano travar por motivo externo (falta de asset, dúvida que só o Antonio
responde), pule para o próximo que não dependa dele e registre em `pendencias.md` o que
foi pulado e por quê. Os ramos são bem independentes: dá para fazer o ramo do mundo
(10 a 13) sem ter tocado no ramo de combate (07 a 09).

O que não dá para pular é o 01, e o 03 antes do 04.
