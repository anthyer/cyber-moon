# Plano 35: Giro automático no golpe

**Objetivo:** ao atacar, o personagem vira sozinho para o inimigo mais perto que estiver
num cone na frente dele, para o golpe não sair no vazio por causa de alguns graus.

**Depende de:** 08 (armas) e 09 (inimigos).

**Situação:** só registrado, em 2026-10-20, a pedido do Antonio.

## O pedido do Antonio (2026-10-20)

- Quando se vai bater em um inimigo, o mais próximo que estiver numa área cônica na
  frente do personagem recebe um snap: o personagem vira na direção desse inimigo.
- O cone não aparece na tela: é só da mecânica, para escolher o alvo. Nada de desenho
  de área, marcador ou contorno (2026-10-20).

## Ideias para discutir

- O cone sai da frente do personagem, com ângulo e alcance por arma (corpo a corpo mais
  curto e mais aberto; arma de projétil mais longo e mais fechado), guardados no `.tres`
  da arma, como o `multiplicador_de_giro`.
- O giro acontece no início do golpe, de uma vez, e só se houver inimigo no cone. Sem
  inimigo, o golpe sai para onde o jogador estava olhando.
- Mirando pelo mouse, a ajuda respeita a mira: o cone sai da direção do mouse, para não
  brigar com quem mira de propósito.
- Alvo de treino e chefe também contam como inimigo.
- Mesma lógica da ajuda para mirar no solo (plano 29): ajuda, mas não prende.
