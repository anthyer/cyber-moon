# Entrada

O jogo tem como alvo inicial a plataforma web, com suporte a mobile e a joystick previstos para depois do lançamento inicial.

## Ações do Input Map

| Ação | Teclado | Mouse | Joystick |
|---|---|---|---|
| `mover_cima` | W / seta para cima | Nenhum | D-pad ou stick esquerdo para cima |
| `mover_baixo` | S / seta para baixo | Nenhum | D-pad ou stick esquerdo para baixo |
| `mover_esquerda` | A / seta para esquerda | Nenhum | D-pad ou stick esquerdo para esquerda |
| `mover_direita` | D / seta para direita | Nenhum | D-pad ou stick esquerdo para direita |
| `interagir` | F | Nenhum | Botão A / Cross, ou L1 |
| `abrir_inventario` | E | Nenhum | Botão Y / Triangle, ou Start |
| `menu_pausa` | Esc | Nenhum | Back / Select |
| `correr` | Shift esquerdo | Nenhum | Botão B / Circle |
| `dash` | Espaço | Botão direito | R1 (botão direito superior) |
| `atacar` | Nenhum | Botão esquerdo | Quadrado / X (botão West) |
| `slot_1` a `slot_9` | 1 a 9 (seleciona o slot rápido) | Nenhum | Nenhum |
| `slot_proximo` | Nenhum | Roda para baixo | Gatilho direito (RT / R2) |
| `slot_anterior` | Nenhum | Roda para cima | Gatilho esquerdo (LT / L2) |
| `teste_avancar_dia` | N (atalho de teste: avança um dia na hora, sem penalidade) | Nenhum | Nenhum |

O stick esquerdo move o jogador junto com o D-pad. As quatro ações de movimento usam zona morta de 0.2 (as outras ficam em 0.5) para o stick analógico responder a um toque leve; teclado e D-pad não são afetados, porque só valem 0 ou 1.

## Regras

- O `InputManager` também sabe de qual aparelho veio a última entrada (`usando_teclado_e_mouse()`) e onde o mouse está (`posicao_do_mouse()`, `mouse_se_moveu_agora()`). Código de gameplay que precisa do mouse pergunta a ele, e não ao `Input` nem ao viewport.
- Toda leitura de entrada passa pelo `InputManager` (`scripts/core/input_manager.gd`), nunca por verificação direta de tecla no código de gameplay.
- Cada ação é mapeada, desde o início, para teclado e joystick simultaneamente; `dash` soma ainda um botão de mouse como atalho extra. O suporte a toque na tela será adicionado futuramente mapeando as mesmas ações.
- `dash` vai na direção do direcional, ou para a frente do personagem quando o direcional está solto. Ele pode cortar o fim de um golpe: sai assim que o golpe termina de acertar, sem esperar a animação acabar.
- `correr` planta o personagem no lugar quando a arma na mão pede isso (hoje, a escopeta): segurando o botão, ele não anda, e o direcional vira o personagem do jeito normal, para mirar em volta sem sair do lugar. No teclado e mouse, plantado, a mira também segue o mouse: vale o que foi usado por último, o mouse quando ele se mexe e as teclas de direção quando uma é apertada. No controle o mouse é ignorado. Com qualquer outro item, o botão continua sendo correr.
- `atacar` é o botão de usar o item da mão: ferramenta age na célula à frente, semente planta, consumível é comido, e com os cestos, slot vazio ou qualquer outro item ele dá soco.
- Nos menus, as direções (`ui_up`, `ui_down`, `ui_left`, `ui_right`) respondem às setas, ao D-pad, ao stick esquerdo e também ao WASD, para quem joga no WASD não precisar trocar de mão ao abrir o inventário. Com o menu aberto o jogo está pausado, então as mesmas teclas não movem o personagem.
- Nos menus, `ui_accept` confirma. Além dos binds padrão do Godot (Enter, Espaço e o botão A), ele também responde ao botão X/West, que é onde chega o botão A do painel arcade; sem isso o painel navegaria no menu sem conseguir confirmar. Com o jogo pausado não há conflito com `atacar`.
- `abrir_inventario` e `menu_pausa` abrem a mesma tela por enquanto, o menu de pausa com o inventário, porque ainda não existe tela de opções. Com o menu aberto, qualquer uma das duas fecha, e o jogo fica pausado de verdade enquanto ele está aberto.
- Menus e telas de UI usam o sistema nativo de foco dos nós `Control` do Godot, permitindo navegação por teclado ou joystick sem depender do mouse.

## Painel arcade (placa DragonRise)

O painel arcade usado nos testes tem uma placa USB DragonRise "Generic USB Joystick"
(USB `0079:0006`), com alavanca digital, 6 botões de ação (A, B, C em baixo e X, Y, Z
em cima, no padrão Sega), Start e Select. O Godot 4.7 lê
controles pelo SDL, e o SDL reconhece essa placa como um gamepad DragonRise comum, com
um mapeamento que não corresponde ao painel: só parte dos botões chega ao jogo, e os
outros o SDL descarta antes do Godot ver.

`Input.add_joy_mapping()` não resolve. Quando o SDL já trata o aparelho como gamepad,
o Godot pula o próprio sistema de mapeamento, e aplicar um mapeamento por cima faz o
controle parar de responder por completo (testado). O mapeamento precisa ser entregue
ao próprio SDL, pela variável de ambiente `SDL_GAMECONTROLLERCONFIG`, que ele lê ao
iniciar:

```
0300457e790000000600000010010000,Painel Arcade DragonRise,x:b0,b:b1,lefttrigger:b2,righttrigger:b3,leftshoulder:b4,rightshoulder:b5,start:b6,back:b11,leftx:a0,lefty:a1,platform:Linux,
```

O mapeamento traduz cada botão físico para o botão padrão que o Input Map já usa, então
nenhum bind específico do painel entra no `project.godot`. Botões do painel, com o
número bruto da placa:

| Botão do painel | Número bruto | Vira | Ação |
|---|---|---|---|
| A | 0 | X (West) | `atacar`, e confirmar nos menus |
| B | 1 | B (East) | `correr` |
| C | 5 | R1 | `dash` |
| X | 2 | Gatilho esquerdo | `slot_anterior` |
| Y | 3 | Gatilho direito | `slot_proximo` |
| Z | 4 | L1 | `interagir` |
| Start | 6 | Start | `abrir_inventario` |
| Select | 11 | Back / Select | `menu_pausa` |
| Alavanca | eixos 0 e 1 | Stick esquerdo | movimento |

O Z chega ao Godot como L1 e ficou com `interagir`, que era a única ação sem botão no
painel: nenhum botão dele chega como A, que é o `interagir` dos controles comuns. O
Select ficou com a `menu_pausa` (o plano 04 previa Start para ela, mas no painel o Start
ficou com o inventário).

Para o Godot instalado por flatpak, a variável fica gravada uma vez por máquina e vale
para o editor e para o jogo rodado por ele:

```bash
flatpak override --user --env=SDL_GAMECONTROLLERCONFIG="<linha acima>" org.godotengine.Godot
```

Para desfazer, `flatpak override --user --unset-env=SDL_GAMECONTROLLERCONFIG org.godotengine.Godot`.
Fora do flatpak (build exportado, por exemplo), basta exportar a mesma variável antes de
abrir o jogo. O GUID do início da linha é o que o Godot informa em
`Input.get_joy_guid()`; o trecho `457e` vem do nome da placa, o que impede que o
mapeamento afete gamepads DragonRise de mesmo código USB. Outra placa arcade precisa
de linha própria, montada lendo os números brutos com `/dev/input/js0`.
