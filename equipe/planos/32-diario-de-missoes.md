# Plano 32: Diário de missões (quest log)

**Objetivo:** o jogador sempre sabe o que tem para fazer. Um diário lista as missões
ativas e as concluídas, com o que falta em cada uma, quem pediu e onde ir.

**Depende de:** 27 (a história das dungeons, que gera as missões principais), 30 (o
elenco, que pede as missões), 15 (diálogo, onde a missão é dada).

**Situação:** só registrado, em 2026-10-19, a pedido do Antonio.

## O pedido do Antonio (2026-10-19)

- Tem que ter um quest log.

## Ideias para discutir

- **Missão como Resource** (`.tres`), como todo dado de jogo: id, título, quem pede,
  descrição, etapas (cada uma com um objetivo verificável: falar com alguém, ir a um
  lugar, entregar item, vencer chefe), recompensa e o lugar de cada etapa (para o
  waypoint do plano 33).
- **Um autoload `QuestManager`**: guarda o estado de cada missão, ouve o `EventBus`
  (item coletado, chefe vencido, conversa) para avançar as etapas sozinho, e vai para o
  save.
- **Tela do diário** numa aba do menu de pausa, ao lado do inventário: ativas no alto,
  com a etapa atual em destaque; concluídas embaixo. Uma missão "acompanhada" por vez,
  que aparece resumida na HUD e vira o waypoint do minimapa.
- **Aviso na tela** ao receber, avançar e concluir, com partícula na conclusão (nada
  vermelho).
- Tipos: principal (a história), de morador (pedidos menores, ligados à amizade) e
  diária (do quadro do mercado, por exemplo).
