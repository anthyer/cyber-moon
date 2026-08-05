# Entrada

O jogo tem como alvo inicial a plataforma web, com suporte a mobile e a joystick previstos para depois do lancamento inicial.

## Acoes do Input Map

| Acao | Teclado | Joystick |
|---|---|---|
| `mover_cima` | W / seta para cima | D-pad para cima |
| `mover_baixo` | S / seta para baixo | D-pad para baixo |
| `mover_esquerda` | A / seta para esquerda | D-pad para esquerda |
| `mover_direita` | D / seta para direita | D-pad para direita |
| `interagir` | E | Botao A / Cross |
| `abrir_inventario` | I | Botao Y / Triangle |

O suporte ao eixo analogico dos manetes fica para uma iteracao futura, quando o movimento do jogador for implementado e puder ser testado com um controle fisico; por enquanto o D-pad cobre a entrada digital equivalente.

## Regras

- Toda leitura de entrada passa pelo `InputManager` (`scripts/core/input_manager.gd`), nunca por verificacao direta de tecla no codigo de gameplay.
- Cada acao e mapeada, desde o inicio, para teclado e joystick simultaneamente. O suporte a toque na tela sera adicionado futuramente mapeando as mesmas acoes.
- Menus e telas de UI usam o sistema nativo de foco dos nos `Control` do Godot, permitindo navegacao por teclado ou joystick sem depender do mouse.
