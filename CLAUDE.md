# Cyber Moon

Jogo de simulação de fazenda com temática cyberpunk, feito em Godot 4.7 (renderizador
GL Compatibility, física Jolt). Projeto acadêmico do IFSC, 05 semestre, Tópicos Especiais.

O projeto Godot fica em `game/`, não na raiz do repositório. Todo caminho `res://`
corresponde a `game/`.

## Comece por aqui

Se é a primeira vez neste repositório, leia `equipe/leiame.md`. Ele explica a instalação,
a ordem de trabalho e onde ficam os planos das features.

## Documentação de referência

Leia antes de mexer em código, na ordem de relevância para a tarefa:

- `game/docs/convencoes.md`: nomenclatura, idioma, estrutura de pastas, estilo.
- `game/docs/arquitetura.md`: os autoloads e o modelo de dados como Resources.
- `game/docs/entrada.md`: o Input Map e a regra de passar tudo pelo `InputManager`.
- `game/docs/pipeline_de_assets.md`: como assets brutos viram assets do projeto.
- `game/docs/glossario.md`: termo de design em português para nome técnico em inglês.
- `equipe/controles.md`: o mapa de controles alvo, baseado em Minecraft e Rune Factory 4.

## Regras que valem sempre

- Identificadores (classes, funções, variáveis, arquivos) em inglês. Comentários e
  documentação em português, com acentuação normal.
- Nada de travessão (o caractere de traço longo) e nada de emoji em documentação,
  comentário ou mensagem de commit. Use vírgula, ponto e parênteses.
- Um autoload por responsabilidade. Sistemas que não precisam se conhecer conversam
  pelo `EventBus`.
- Dado de jogo (cultivo, item, NPC, diálogo) é `Resource` customizada com arquivo
  `.tres`, nunca valor hardcoded espalhado pelo código.
- Leitura de entrada sempre pelo `InputManager`, nunca `Input.is_action_pressed()`
  direto em código de gameplay.
- Código precisa ser legível por um estudante que vai defender o projeto numa
  apresentação. Prefira nome claro e estrutura explícita a one-liner esperto.

## Skills deste repositório

Estão em `.claude/skills/` e carregam sozinhas quando a situação aparece:

- `padrao-cyber-moon`: ao escrever ou revisar GDScript, cena ou Resource.
- `rodar-o-jogo`: ao rodar, testar ou depurar o jogo.
- `commitar`: ao preparar commit ou push.
- `executar-plano`: ao pegar um arquivo de `equipe/planos/` para implementar.

## Fluxo de trabalho

As features estão descritas uma a uma em `equipe/planos/`, numeradas na ordem de
dependência. A ordem e o motivo de cada dependência estão em `equipe/ordem-de-execucao.md`.
Pegue o plano de menor número que ainda não foi feito, siga a skill `executar-plano`,
e registre em `equipe/pendencias.md` o que ficou de fora.
