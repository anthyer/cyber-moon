# Convencoes

## Nomenclatura

- Arquivos e pastas: `snake_case` (`crop_manager.gd`, `player_scene.tscn`).
- Classes GDScript declaradas com `class_name`: `PascalCase` (`CropManager`, `DayCycleManager`).
- Nos dentro de cenas: `PascalCase` descritivo (`Player`, `InteractionArea`).
- Constantes: `SCREAMING_SNAKE_CASE`.
- Sinais: verbo no passado, `snake_case` (`crop_harvested`, `day_started`).
- Recursos de dados (`.tres`): nome do conteudo em `snake_case` (`tomate.tres`, `ana_perfil.tres`).

## Idioma

Codigo (identificadores, nomes de classe, nomes de arquivo) em ingles. Comentarios e documentacao em portugues. Consulte `glossario.md` para o mapeamento entre termos de design em portugues e nomes tecnicos em ingles.

## Estrutura de pastas

```
res://
  scenes/        cenas por sistema de jogo
  scripts/       scripts por sistema de jogo, mais scripts/core (autoloads) e scripts/resources (definicao das classes Resource)
  resources/     instancias .tres dos dados de jogo
  assets/        arte, audio e fontes finalizados
  ui/            temas e icones de interface
  _import/       assets brutos ainda nao organizados
  docs/          esta documentacao
```

## Estilo de codigo

- Um autoload por responsabilidade. Comunicacao entre sistemas que nao precisam se conhecer diretamente passa pelo `EventBus`.
- Dados de jogo (cultivos, itens, NPCs, dialogos) sao Resources customizadas, nao classes hardcoded nem dados soltos em codigo.
- Leitura de entrada do jogador sempre via `InputManager`, nunca checagem direta de tecla no codigo de gameplay.
