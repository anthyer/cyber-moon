# Demo

A branch `demo` é uma versão de demonstração do Cyber Moon, para mostrar o jogo a quem
nunca jogou. Ela nasceu da `main` (depois do plano 35) e foi cortada de propósito: este
documento diz o que saiu, o que mudou e o que entrou. Onde ele contradiz
`arquitetura.md`, vale este.

## Como roda

A cena principal é o menu (`scenes/ui/menu_principal.tscn`), com Jogar, Controles e
Sair. Jogar abre a fase `scenes/levels/demo.tscn`, que começa com a tela de tutorial
(`TelaDeTutorial`) mostrando os controles e onde fica cada coisa. A tela pausa o jogo até
o jogador apertar Começar ou Esc.

Não há save. Todo Jogar é um jogo novo, e sair é só fechar (botão Sair do jogo, na
ponta das abas do menu de pausa).

## O mapa

É a cidade antiga: o playground de antes do plano 26 (commit `fd23f25^`), com a horta
na frente de casa, os prédios dos kits de cidade da Kenney e a cama. Duas mudanças:

- Os galpões `building-k4` e `building-q2` saíram para abrir o pátio industrial, ao
  norte, onde fica a área de combate.
- Todo prédio e toda árvore ganhou um `CoberturaTranslucida`, para o jogador não sumir
  atrás deles.

A malha de navegação é `resources/navigation/demo.tres`. Mexeu no mapa, gere de novo:

```bash
godot --headless --path game res://scenes/utils/gerar_malha_de_navegacao.tscn -- res://scenes/levels/demo.tscn
```

## O que entrou

- **Menu principal** (`menu_principal.gd`), com a tela inicial em pixel art: céu com a
  lua, três faixas de cidade que rolam em velocidades diferentes (`CamadaDeParallax`),
  a via elevada na frente, carros voadores em quatro pistas e o título flutuando, tudo
  montado pelo `CenarioDoMenu`. A arte é feita em 384x216 e ampliada por número inteiro.
  As imagens saem de `equipe/ferramentas/gerar_tela_inicial.py`; para mudar o desenho,
  mude o script e rode de novo. Os botões usam o tema `ui/themes/tema_do_menu.tres`.
- **Tutorial de controles** (`TelaDeTutorial`). A tabela vem de um `GuiaDeControles`
  (`resources/ui/controles_da_demo.tres`) desenhado pela `ListaDeControles`, a mesma
  cena usada no menu principal e na aba Controles do menu de pausa, que tomou o lugar da
  aba Relacionamentos.
- **Vendinha** (`scenes/world/vendinha.tscn`, classe `Vendinha`): a barraca fixa na rua
  da frente de casa. O balcão abre a `TelaDeLoja` com o catálogo
  `resources/lojas/vendinha.tres`, a qualquer hora. O baú de venda ao lado tem
  `vende_ao_fechar` ligado e vende tudo quando a tela dele fecha, em vez de esperar a
  virada do dia. Como o único baú de venda vende na hora, a fase não tem o
  `ResumoDeVendas`.
- **Área de combate** (`AreaDeCombate`, no pátio industrial): seis `PontoDeInimigo`,
  cada um com um `PerfilInimigo`. O inimigo que cai nasce de novo no mesmo ponto depois
  de `segundos_para_renascer`.
- **Pacote de teste** no `resources/items/inventario_inicial.tres`: as cinco armas, as
  três ferramentas, sementes da Brotação, consumíveis, colheita para vender, materiais e
  5000 créditos.
- **Efeitos de partícula** das ações novas, na tabela do `EfeitosDoJogo`: `comprar` e
  `vender` (saem no jogador quando a tela da loja ou do baú fecha) e `inimigo_surge`.
  Sinais novos: `EventBus.enemy_spawned(posicao)` e
  `EconomyManager.item_purchased(item, quantidade)`. O `EventBus.shop_requested` passou a
  levar `(nome_da_loja, catalogo)` em vez do perfil de um NPC.

## O que saiu

| Sistema | O que foi apagado |
|---|---|
| Multiplayer e chat | `NetworkManager`, `ChatManager`, `LobbyManager`, `scripts/coop/`, `scenes/coop/`, lobby, convite, chat, `resources/rede/` |
| Dungeons | `DungeonManager`, as três dungeons, portal, entradas, chefes, aviso de ataque, HUDs de dungeon e de chefe |
| NPCs e diálogo | `DialogueManager`, `RelationshipManager`, `scripts/npcs/`, `scripts/dialogue/`, perfis, conversas, rotinas, catálogos da Marta e do Vitor, menu de serviços, aprimoramento na bancada |
| Save | `SaveManager` e as partes de save do jogador, da grade de solo e do baú |
| Mapas novos | `MapManager`, `fazenda.tscn`, `mundo.tscn`, `mapa.gd`, `passagem_de_mapa.gd`, o `playground.tscn` |
| Clima e calendário | chuva, raios, calendário e quadro do calendário |
| Ferramentas de teste | menu de debug (F3), atalhos de teste e a ação de avançar o dia (N) |

As ações `abrir_chat`, `menu_debug` e `teste_avancar_dia` saíram do Input Map.

## O que ficou, desligado

- **Clima:** o `WeatherManager` continua, mas `CLIMA_FIXO_DA_DEMO` faz todo dia ser de
  sol. Esvaziar a constante volta o sorteio.
- **Estações:** o `SeasonManager` continua, parado na Brotação. Por isso o catálogo e o
  pacote só trazem sementes que crescem nela (cenoura, trigo, beterraba e repolho).
- **Dia e noite** e **desmaio** continuam como no jogo completo: dormir na cama vira o
  dia, e zerar a vida ou passar da 1:00 faz o jogador acordar em casa.
