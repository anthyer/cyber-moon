# Plano 24: Saque por força do inimigo e aprimoramento de armas

**Objetivo:** os inimigos soltam materiais, os mais fortes soltam materiais melhores, e
esses materiais servem para aprimorar as armas com um NPC ferreiro, numa tela própria.

**Depende de:** 09 (inimigos e saque), 08 (armas), 15 (o ferreiro é um NPC com quem se
conversa), 17 (créditos, se o aprimoramento também custar dinheiro).

**Situação:** só documentado. Pedido do Antonio em 2026-10-07, para entrar na lista do
que fazer.

## O que o Antonio pediu

Materiais dropados pelos inimigos, com inimigos mais fortes dropando itens melhores. Esses
itens podem ser usados para aprimorar armas num NPC ferreiro, numa interface específica.

## O que já existe

- **Saque:** cada `PerfilInimigo` tem `itens_dropados` e `chance_de_drop`. Ao morrer, o
  inimigo sorteia um item da lista. Hoje o drone solta um tipo de sucata, e o ciborgue e a
  sentinela soltam os mesmos dois. Não há diferença de qualidade por força.
- **Materiais:** seis sucatas no catálogo (`sucata_metal`, `placa_queimada`,
  `celula_energia`, `fio_optico`, `servomotor`, `nucleo_sintetico`), com valores de venda
  crescentes. Servem como ponto de partida para a escala de qualidade.
- **Armas:** `Arma` é um `Resource` com dano, alcance, custo de stamina, velocidade e
  cooldown. Não existe nível de arma.
- **Dungeon em equipe (plano 22):** o saque é individual. Cada jogo sorteia o próprio.
- **Regra dos itens (plano 17):** arma pode ser guardada e vendida, e não descartada.

## Ideias de desenho, para decidir

**Saque por faixa.** Em vez de uma lista só, o perfil do inimigo ganha uma tabela de saque:
cada linha com o item, a chance e a quantidade. A "força" do inimigo decide de qual faixa
de material ele sorteia. Três faixas bastam para começar (comum, incomum, raro), ligadas
às sucatas que já existem.

**Aprimorar é subir o nível da arma.** Cada arma tem níveis; cada nível pede uma receita
(tantos de tal material, e talvez créditos) e melhora um ou mais números da arma. A
receita e o ganho de cada nível são dado (`Resource`), e não código.

**O nível mora no item do jogador, não no arquivo da arma.** Hoje todas as foices são o
mesmo `Resource`. Para uma foice ter nível 3 e outra nível 1, o nível precisa ficar na
pilha do inventário (ou a arma aprimorada vira outro item). Esta é a decisão técnica mais
importante do plano, e mexe com o inventário e com o save (plano 20).

**A tela do ferreiro.** Abre pela conversa, como a loja. Mostra as armas do jogador, a
arma escolhida com os números de agora e os do próximo nível lado a lado, a receita com o
que o jogador tem e o que falta, e o botão de aprimorar.

## O que precisa ser decidido antes de executar

- **Quem é o ferreiro.** O Vitor, que já é o mecânico e vende as armas, ou um NPC novo?
- **Quantos níveis** cada arma tem, e o que cada nível melhora (dano, alcance, custo de
  stamina, velocidade, cooldown).
- **A receita de cada nível:** só materiais, ou materiais e créditos?
- **O que é "inimigo mais forte".** Hoje são três inimigos. A dungeon (plano 23) vai
  trazer subchefes e chefes, que são o lugar natural do material raro.
- **Materiais novos ou os seis que já existem?**
- **Ferramenta de fazenda entra aqui?** O Antonio já disse que ferramenta é melhorada,
  trocada por versão melhor (nota do plano 17). Pode ser a mesma tela e o mesmo ferreiro,
  ou continuar como compra. Vale decidir junto.
- **Em equipe na dungeon:** o saque continua individual?

## Partículas

Plano escrito depois da regra de partículas, então as ações dele nascem com efeito: o
material raro caindo do inimigo (um brilho na cor da raridade) e a arma sendo aprimorada
no ferreiro (faíscas).

## Tarefas (rascunho, a fechar depois das decisões)

- [ ] **1.** Tabela de saque no `PerfilInimigo`, com faixas de raridade.
- [ ] **2.** Onde mora o nível da arma, e o inventário e o combate lendo dele.
- [ ] **3.** As receitas de aprimoramento como `Resource`.
- [ ] **4.** O ferreiro e a tela de aprimorar.
- [ ] **5.** Partículas do saque raro e do aprimoramento.
- [ ] **6.** Documentar e commitar.

## Fora de escopo

- **Encantamento, gema e atributo aleatório.** Aprimorar é subir de nível, e só.
- **Desmontar arma para recuperar material.**
- **Armadura e acessório aprimoráveis.** Os espaços existem no inventário, mas não há
  itens para eles ainda.
