# Convenções

## Nomenclatura

- Arquivos e pastas: `snake_case` (`crop_manager.gd`, `player_scene.tscn`).
- Classes GDScript declaradas com `class_name`: `PascalCase` (`CropManager`, `DayCycleManager`).
- Nós dentro de cenas: `PascalCase` descritivo (`Player`, `InteractionArea`).
- Constantes: `SCREAMING_SNAKE_CASE`.
- Sinais: verbo no passado, `snake_case` (`crop_harvested`, `day_started`).
- Recursos de dados (`.tres`): nome do conteúdo em `snake_case` (`tomate.tres`, `ana_perfil.tres`).

## Idioma

Código (identificadores, nomes de classe, nomes de arquivo) em inglês. Comentários e documentação em português. Consulte `glossario.md` para o mapeamento entre termos de design em português e nomes técnicos em inglês.

## Estrutura de pastas

```
res://
  scenes/        cenas por sistema de jogo
  scripts/       scripts por sistema de jogo, mais scripts/core (autoloads) e scripts/resources (definição das classes Resource)
  resources/     instâncias .tres dos dados de jogo
  assets/        arte, áudio e fontes finalizados
  ui/            temas e ícones de interface
  _import/       assets brutos ainda não organizados
  docs/          esta documentação
```

## Estilo de código

- Um autoload por responsabilidade. Comunicação entre sistemas que não precisam se conhecer diretamente passa pelo `EventBus`.
- Dados de jogo (cultivos, itens, NPCs, diálogos) são Resources customizadas, não classes hardcoded nem dados soltos em código.
- Leitura de entrada do jogador sempre via `InputManager`, nunca checagem direta de tecla no código de gameplay.
