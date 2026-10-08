# Plano 20: Salvar o jogo

**Objetivo:** fechar o jogo e voltar no mesmo ponto. Hoje o `SaveManager` salva só o
número do dia, a fase da história e os marcos. Todo o resto (inventário, status, plantas,
horário) se perde ao fechar.

**Depende de:** todos os planos de sistema que estiverem feitos quando este começar. O
modelo abaixo já prevê os dados dos planos 11 a 17; o que ainda não existir fica de fora
e entra quando o sistema dele entrar.

**Quando fazer:** antes de qualquer entrega jogável de verdade. Decisão do Antonio em
2026-10-02: fica documentado agora e é feito depois, na ordem de
`ordem-de-execucao.md`.

## Revisão de 2026-10-07 (vale sobre o resto do plano)

**Situação:** feito. Conferido em duas execuções separadas do jogo. A primeira montou um
estado bem diferente do inicial e salvou; a segunda abriu o jogo e conferiu o que foi
carregado sozinho: o dia 41 às 15:30, a Estiagem no relógio, a chuva, o nível, a vida e a
stamina, 12 tomates no slot 20, o slot selecionado, os créditos e o total vendido, o
`marco_1`, os 10 corações e o namoro com o Kenji, o presente da semana da Marta, a
conversa do dia com o Vitor, o milho no estágio 2 com 1 dia contado, o tomate murcho, o
solo molhado, a picareta e os 7 servomotores no baú, e a posição do jogador. Também
conferido: jogo novo sem save começa no dia 1 com 500 créditos; virar o dia cria o save e
mostra "Jogo salvo."; um save antigo só com o dia carrega e o resto fica no padrão; um
arquivo corrompido é ignorado e o jogo segue.

**Ajustes ao plano:**

- **O jogo salva quando o dia começa**, seja dormindo na cama, caindo de sono ou
  desmaiando, e também ao fechar a janela. O plano dizia "ao dormir na cama e ao sair pelo
  menu"; não existe opção de sair no menu, e salvar em toda virada de dia é mais simples
  de explicar.
- **Os nós da fase entram pelo grupo `salvaveis`** e dizem a própria chave com
  `chave_de_save()`. Hoje são a grade de solo, o jogador e os baús. Os autoloads ficam
  numa lista no `SaveManager`, na ordem em que são importados.
- **`EventBus.game_loaded`** avisa quem mostra estado na tela (o relógio, a estação e a
  grama, os NPCs) depois de carregar. Carregar não emite `day_started`, para as plantas
  não crescerem de novo.
- **A estação não é salva**, porque sai do número do dia.
- **Dentro da dungeon a posição não é salva.** Ao carregar, o jogador nasce no ponto de
  spawn.
- **Itens no chão e inimigos não são salvos**, como o plano já previa.
- **`--sem-save`** na linha de comando ignora o save e não grava nada. É para teste e para
  abrir dois jogos na mesma máquina.
- **O `CatalogoDeItens`** é uma classe com funções estáticas, e o submenu de itens do menu
  de debug passou a usá-la.
- **Partículas:** o brilho verde em volta do jogador ao salvar reusa a cena da poeira de
  passo, com outra cor e mais partículas.
- **Menu de debug:** seção Save, com salvar, carregar e apagar.

## Contexto

Cada sistema guarda o próprio estado no autoload ou no nó dele, e nenhum sabe salvar.
Salvar tudo de uma vez, num arquivo só, é mais simples do que salvar aos pedaços, e foi
por isso que cada plano deixou o save de fora.

O arquivo continua sendo JSON em `user://`, como o `SaveManager` já faz. JSON é legível
para depurar e funciona no alvo web (no navegador, `user://` vai para o armazenamento do
próprio navegador).

## Decisões fechadas

**Cada sistema sabe exportar e importar o próprio estado.** Em vez de o `SaveManager`
conhecer o interior de todo mundo, cada autoload (e a `GradeSolo`) ganha dois métodos:

```gdscript
func exportar_estado() -> Dictionary
func importar_estado(dados: Dictionary) -> void
```

O `SaveManager` só junta os dicionários numa chave por sistema e grava. Sistema novo
entra no save acrescentando uma linha no `SaveManager`.

**Item é salvo pelo `id`, nunca pelo caminho nem pelo objeto.** O `id` existe desde o
plano 03 exatamente para isso. Na hora de carregar, um catálogo (`CatalogoDeItens`, que
varre `resources/items/` uma vez e monta um dicionário de `id` para `Item`) devolve o
recurso. Mudar um item de pasta não quebra o save.

**O arquivo tem versão.** Uma chave `versao` no topo. Ao carregar um save de versão
antiga, o `SaveManager` completa com os valores padrão em vez de quebrar. Sem isso, cada
mudança no jogo invalidaria os saves de teste.

**Quando salvar:** ao dormir na cama (como em Stardew Valley) e ao sair pelo menu. Sem
salvamento a qualquer momento, que deixaria o jogador desfazer escolhas.

## O que entra no save

| Sistema | Dados |
|---|---|
| `DayCycleManager` | dia, hora |
| `StatusManager` | vida, stamina, nível, experiência, se desmaiou ontem |
| `InventoryManager` | os 36 slots (`id` e quantidade) e os espaços de equipamento |
| `EquipmentManager` | slot rápido selecionado |
| `GradeSolo` | estado de cada célula (seco, molhado) e cada planta (cultivo, estágio, dias no estágio, murcha) |
| Jogador | posição |
| Itens no chão | `id`, quantidade e posição de cada `ItemNoMundo` (opcional: pode ser mais simples só descartar) |
| `GameManager` | fase da história e marcos (já salvos hoje) |
| Planos 11 a 17 | estação e ano, clima do dia, amizade de cada NPC, créditos, baú, o que existir |

Inimigos não são salvos: voltam ao lugar e à vida cheia ao carregar.

## Partículas

Plano escrito depois da regra de partículas, então as ações dele nascem com efeito: um
brilho curto no canto da tela, ou em volta da cama, quando o jogo salva. É o aviso de que
deu certo, e é a única ação visível deste plano.

## Tarefas

- [x] **1.** Criar o `CatalogoDeItens` e conferir que acha todo `.tres` de item pelo `id`.
- [x] **2.** `exportar_estado()` e `importar_estado()` em cada sistema da tabela. Testar
  cada um isolado por script: exportar, mudar o estado, importar e comparar.
- [x] **3.** Reescrever o `SaveManager` juntando os sistemas, com a chave `versao`.
- [x] **4.** Salvar ao dormir na cama e ao sair pelo menu. Carregar ao abrir o jogo, se
  houver save.
- [x] **5.** Efeito de partículas e aviso na tela ao salvar.
- [x] **6.** Botão no menu de debug (F3): salvar agora, carregar agora e apagar o save.
- [x] **7.** Testar o ciclo inteiro: plantar, colher, encher o inventário, dormir, fechar o
  jogo, abrir de novo e conferir tudo.
- [x] **8.** Documentar e commitar.

## Critério de pronto

- Fechar e abrir o jogo devolve o dia, a hora, o inventário, o status, as plantas e a
  posição do jogador.
- Um save de versão antiga carrega sem erro, completando o que faltar.
- Mudar um item de pasta não quebra um save existente.
- Salvar mostra o aviso e o efeito.

## Fora de escopo

- **Vários espaços de save.** Um jogo salvo só. Mais de um é uma tela a mais.
- **Save na nuvem.** O plano 18 (chat) tem o back-end na AWS, mas save na nuvem é outro
  sistema.
- **Criptografia do arquivo.** É um jogo acadêmico, e o JSON legível ajuda a depurar.
