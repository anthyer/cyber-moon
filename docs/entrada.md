# Entrada

O jogo tem como alvo inicial a plataforma web, com suporte a mobile e a joystick previstos para depois do lançamento inicial.

## Ações do Input Map

| Ação | Teclado | Joystick |
|---|---|---|
| `mover_cima` | W / seta para cima | D-pad para cima |
| `mover_baixo` | S / seta para baixo | D-pad para baixo |
| `mover_esquerda` | A / seta para esquerda | D-pad para esquerda |
| `mover_direita` | D / seta para direita | D-pad para direita |
| `interagir` | E | Botão A / Cross |
| `abrir_inventario` | I | Botão Y / Triangle |
| `correr` | Shift esquerdo | Botão B / Circle |

O suporte ao eixo analógico dos manetes fica para uma iteração futura, quando o movimento do jogador for implementado e puder ser testado com um controle físico; por enquanto o D-pad cobre a entrada digital equivalente.

## Regras

- Toda leitura de entrada passa pelo `InputManager` (`scripts/core/input_manager.gd`), nunca por verificação direta de tecla no código de gameplay.
- Cada ação é mapeada, desde o início, para teclado e joystick simultaneamente. O suporte a toque na tela será adicionado futuramente mapeando as mesmas ações.
- Menus e telas de UI usam o sistema nativo de foco dos nós `Control` do Godot, permitindo navegação por teclado ou joystick sem depender do mouse.
