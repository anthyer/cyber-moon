extends Node

## A célula entrou no fim para o efeito de colheita saber onde aparecer.
signal crop_harvested(cultivo: Cultivo, quantidade: int, celula: Vector2i)
signal city_expansion_blocked(id_do_marco: String)
signal tile_plowed(celula: Vector2i)
signal tile_watered(celula: Vector2i)
signal tile_removed(celula: Vector2i)
signal musica_solicitada(faixa: AudioStream)
signal item_picked_up(item: Item, quantidade: int)
signal crop_planted(celula: Vector2i, cultivo: Cultivo)
signal crop_grown(celula: Vector2i, novo_estagio: int)
signal crop_withered(celula: Vector2i)
signal crop_removed(celula: Vector2i)
signal damage_dealt(alvo: Node3D, quantidade: int)
signal enemy_defeated(perfil: PerfilInimigo, posicao: Vector3)
## Um inimigo apareceu (ou reapareceu) num ponto da área de combate da demo.
signal enemy_spawned(posicao: Vector3)
## Um aviso curto na tela, como "Tomate não cresce no Apagão". Quem mostra é o HudAviso.
signal notice_requested(texto: String)
## Som de ambiente em loop, como a chuva. Nulo pede para parar o que estiver tocando.
signal ambience_requested(fluxo: AudioStream)
## O jogador interagiu com o balcão da vendinha. A loja mostra o catálogo com esse nome.
signal shop_requested(nome_da_loja: String, catalogo: CatalogoDeLoja)
## O jogador interagiu com um baú, de guardar ou de venda.
signal chest_requested(bau: Bau)
## Momentos que só existem para quem mostra algo na tela (o EfeitosDoJogo): onde um
## projétil bateu, onde o jogador começou um dash, e o que ele comeu.
signal projectile_impacted(posicao: Vector3)
signal player_dashed(posicao: Vector3)
## O jogador caiu na água e foi posto de volta no chão (o ResgateDoJogador).
signal player_rescued(posicao: Vector3)
## Mudou o que responde se o jogador apertar interagir agora (null quando não há nada).
## Quem destaca o alvo na tela (DestaqueDeInteracao) e o efeito de troca ouvem aqui.
signal interaction_target_changed(alvo: Node3D)
signal item_consumed(consumivel: Consumivel)
signal rare_loot_dropped(posicao: Vector3, cor: Color)
