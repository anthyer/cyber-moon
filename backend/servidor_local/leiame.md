# Servidor local de repasse

Faz no computador de quem desenvolve o papel que o API Gateway WebSocket com Lambda fará
na AWS: recebe mensagens JSON dos jogos conectados e repassa. Não simula o jogo. O
protocolo está em `equipe/planos/21-rede-e-chat.md`.

## Rodar

```
pip install websockets
python3 backend/servidor_local/servidor.py
```

Ele ouve em `ws://localhost:8765`, que é o endereço padrão do jogo
(`game/resources/rede/configuracao.tres`). O jogo conecta sozinho ao abrir e tenta de novo
a cada 5 segundos se o servidor não estiver no ar.

## Testar com dois jogadores na mesma máquina

Com o servidor rodando, abra o jogo duas vezes, cada um com um nome:

```
godot --path game -- --nome=Ana
godot --path game -- --nome=Beto --sem-save
```

O `--sem-save` no segundo evita que os dois jogos gravem no mesmo arquivo de save. Com o
Godot instalado pelo Flatpak, o comando é `flatpak run org.godotengine.Godot` no lugar de
`godot`.

Num deles, vá até o portal na frente da casa, interaja, convide o outro e entre na
dungeon. O chat abre com Enter ou T.

Em dois computadores da mesma rede, rode o servidor num deles e passe o endereço ao
outro: `godot --path game -- --nome=Beto --servidor=ws://IP_DO_SERVIDOR:8765`.

## Conferir o protocolo

```
python3 backend/servidor_local/testar_protocolo.py
```

Sobe um servidor numa porta própria, conecta dois clientes e confere cada rota.
