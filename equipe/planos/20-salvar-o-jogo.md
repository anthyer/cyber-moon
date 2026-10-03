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

- [ ] **1.** Criar o `CatalogoDeItens` e conferir que acha todo `.tres` de item pelo `id`.
- [ ] **2.** `exportar_estado()` e `importar_estado()` em cada sistema da tabela. Testar
  cada um isolado por script: exportar, mudar o estado, importar e comparar.
- [ ] **3.** Reescrever o `SaveManager` juntando os sistemas, com a chave `versao`.
- [ ] **4.** Salvar ao dormir na cama e ao sair pelo menu. Carregar ao abrir o jogo, se
  houver save.
- [ ] **5.** Efeito de partículas e aviso na tela ao salvar.
- [ ] **6.** Botão no menu de debug (F3): salvar agora, carregar agora e apagar o save.
- [ ] **7.** Testar o ciclo inteiro: plantar, colher, encher o inventário, dormir, fechar o
  jogo, abrir de novo e conferir tudo.
- [ ] **8.** Documentar e commitar.

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
