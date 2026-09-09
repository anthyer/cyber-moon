---
name: commitar
description: Use ao preparar um commit, escrever mensagem de commit, fazer git add, git push ou abrir pull request no Cyber Moon. Também ao decidir quando quebrar o trabalho em commits e ao lidar com arquivos gerados pelo Godot como .uid, .import e .godot.
---

# Commits e push no Cyber Moon

## Formato da mensagem

`tipo(escopo): descricao no imperativo, em portugues, minusculo`

Tipos em uso no histórico, use só estes:

| Tipo | Quando |
|---|---|
| `feat` | comportamento novo de jogo |
| `fix` | correção de algo que estava errado |
| `refactor` | muda estrutura sem mudar comportamento |
| `polish` | ajuste visual ou de sensação, sem lógica nova |
| `chore` | encanamento, arquivos gerados, movimentação |
| `docs` | só documentação |

Escopos em uso: `farming`, `player`, `mapa`, `playground`, `assets`, `estrutura`,
`readme`, `gdd`, `entregas`, `plano`. Escopo novo é aceitável quando a feature é de um
sistema que ainda não apareceu no histórico (`audio`, `inventario`, `combate`,
`npc`, `clima`).

Exemplos reais do repositório:

```
feat(farming): adiciona logica de arar/molhar e autotile horizontal do grid
fix(farming): renomeia texturas sem borda e corrige compressao VRAM
refactor(player): desacopla player dos caminhos fixos de grade e indicador
chore(playground): normaliza uids e ids gerados pelo editor
```

O corpo da mensagem é opcional. Use quando o porquê não couber no assunto, e escreva em
frases normais, sem lista com marcador quando não precisar.

## Proibido na mensagem

Nada de travessão e nada de emoji. Nada de linha de coautoria, de rodapé de ferramenta
ou de qualquer referência a como o commit foi produzido. A mensagem descreve a mudança
no jogo, e nada além disso. Isso vale também para descrição de pull request.

## Quando commitar

Um commit por unidade que faz sentido sozinha e deixa o jogo rodando. Um plano de
`equipe/planos/` costuma render de três a seis commits, um por tarefa, não um commit
gigante no fim.

Antes de cada commit, o jogo tem que abrir sem erro no console. Veja a skill
`rodar-o-jogo`.

## Arquivos gerados pelo Godot

- `.gd.uid`, `.tscn`, `.tres`, `.import`: **entram** no commit. São parte do projeto e
  quebram referência se ficarem de fora. O histórico tem commit dedicado a isso
  (`chore(farming): rastreia .gd.uid pendentes`), justamente porque esquecer dá erro em
  outra máquina.
- `game/.godot/`: **fica de fora**, já está no `.gitignore`.
- `game/_import/*.zip`: **fica de fora**, são os pacotes brutos baixados.
- `.superpowers/`: **fica de fora**.

Depois de importar asset novo, rode `git status` e confira se algum `.import` ou `.uid`
apareceu solto. Eles precisam ir junto com o arquivo que descrevem, no mesmo commit.

## Push

O repositório tem uma branch só, `main`. Trabalhe direto nela e faça push quando o
conjunto de commits fecha uma feature inteira do plano, não a cada commit.

```bash
git status
git add <arquivos especificos, nao ponto>
git commit -m "feat(escopo): descricao"
git push
```

Prefira listar os arquivos no `git add` a usar `git add .`, porque a pasta do projeto
acumula arquivo temporário do editor com facilidade.
