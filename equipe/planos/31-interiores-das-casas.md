# Plano 31: Interiores das casas

**Objetivo:** as casas do jogador e dos NPCs ganham interior onde se entra. Na casa do
jogador ficam a cama, o calendário e os baús. Os NPCs voltam para casa ao anoitecer, e a
casa deles fica trancada à noite.

**Depende de:** 14 (rotinas dos NPCs), 26 (os mapas e as casas modeladas), 28 (destaque
de interação, para a porta), 20 (save, porque baú e cama mudam de lugar).

**Situação:** só registrado, em 2026-10-19, a pedido do Antonio.

## O pedido do Antonio (2026-10-19)

- As casas dos NPCs têm que ter interior, inclusive a do jogador.
- Calendário, baú e cama vão para dentro da casa do jogador.
- Na rotina, os NPCs vão para casa ao anoitecer.
- Não deve ser possível entrar na casa deles de noite.

## O que já existe

- **Rotina:** quando nenhum compromisso serve, o NPC vai para o marcador da casa dele
  (`PerfilNpc.casa`, um `Marker3D` em `PontosDeRotina`). Hoje alguns compromissos vão até
  tarde (o do Kenji acaba às 23:00), então "ir para casa ao anoitecer" ainda não é regra.
- **Troca de lugar:** o `MapManager` já leva o jogador entre a fazenda e o mundo por uma
  `PassagemDeMapa`, e a dungeon é montada à parte, longe dos mapas. Um interior pode seguir
  o mesmo caminho.
- **Interação:** a porta pode ser um interagível com verbo ("Entrar", "Trancada"), e o
  destaque do plano 28 já mostra isso sem código novo.
- **Casas:** o exterior de cada casa está em `casas.py` e `fazenda.py`. A casa do
  jogador já é grande (6 por 4,2).

## Proposta (a fechar com o Antonio)

1. **Interior como cômodo à parte.** Cada interior é uma cena pequena (um cômodo, às vezes
   dois), montada longe dos mapas, como a dungeon. Entrar pela porta leva o jogador para
   lá e a câmera vê o cômodo inteiro; sair o devolve na frente da porta. Mais simples que
   abrir o telhado da casa no mapa, e não pesa no mapa.
2. **Porta como interagível.** `PortaDeCasa` com `interagir()` e
   `texto_de_interacao()`: "Entrar na casa da Marta" de dia, "Trancada (volte de manhã)"
   de noite. Trancada, avisa e não abre.
3. **Horário da casa.** Cada NPC tem no perfil a hora em que se recolhe (por exemplo,
   19:00) e a hora em que abre a casa (por exemplo, 8:00). Fora disso a porta fica
   trancada para o jogador. Dentro do horário aberto, o NPC que estiver em casa aparece
   no interior, e dá para conversar com ele lá.
4. **Recolher ao anoitecer.** Uma regra só na rotina: depois da hora de recolher, todo
   compromisso perde para a casa. Os compromissos que hoje passam disso são encurtados.
5. **A casa do jogador** nunca tranca. Dentro: a cama, o quadro do calendário, o baú de
   guardar e, perto da porta, o de venda (ou o de venda fica do lado de fora, para vender
   sem entrar; decidir). Acordar acontece na cama, dentro de casa.
6. **Save:** os baús mudam de nó; o save precisa achar os baús antigos pelo nome e trazer
   o conteúdo, para ninguém perder item.

## Decisões a fechar

- Interior à parte (proposta 1) ou casa que abre o telhado no próprio mapa?
- O baú de venda vai para dentro ou fica na porta, do lado de fora?
- Que horário cada NPC se recolhe e abre a casa? A sugestão é de 19:00 às 8:00 para
  todos, com exceções que combinem com a persona (o Kenji fica acordado na antena?).
- O comércio (loja da Marta, ferreiro do Vitor) acontece dentro do mercado e da oficina,
  ou continua na porta?
- Em multiplayer, cada jogador entra no interior sozinho, ou os dois veem o mesmo?

## Tarefas (depois das decisões)

1. Cena e gerador de interior: cômodo, móveis do estilo da bíblia de 3D, luz de dentro.
2. `PortaDeCasa` e a troca de lugar (entrar e sair), com a câmera.
3. Interior da casa do jogador; cama, calendário e baús mudam para dentro; acordar na
   cama.
4. Migração do save dos baús.
5. Horário de recolher no `PerfilNpc` e a regra na rotina; ajustar os compromissos.
6. Interiores dos NPCs, um com a cara de cada persona.
7. Porta trancada à noite, com aviso.
8. Partículas: entrar e sair (um sopro na porta), porta trancada (nada vermelho).

## Fora de escopo

- Móveis que se compram e se mudam de lugar dentro de casa.
- Expandir a casa do jogador.
