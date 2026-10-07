"""Servidor local de repasse do Cyber Moon.

Faz no computador de quem desenvolve o papel que o API Gateway WebSocket com Lambda fará
na AWS: recebe mensagens JSON dos jogos conectados e repassa para quem deve receber. Ele
não simula o jogo. O protocolo está em equipe/planos/21-rede-e-chat.md.

Rodar:
    python3 backend/servidor_local/servidor.py
    python3 backend/servidor_local/servidor.py --porta 9000

Precisa do pacote websockets (pip install websockets).
"""

import argparse
import asyncio
import itertools
import json

import websockets

DEFAULT_PORT = 8765
MAX_NAME_LENGTH = 20
MAX_CHAT_LENGTH = 200

# Conexões abertas: id do jogador -> {"socket", "name", "room"}.
players = {}
# Salas da dungeon: id da sala -> {"host", "members"}. members é a lista de ids, na ordem
# em que entraram, com o anfitrião primeiro.
rooms = {}

_player_ids = itertools.count(1)
_room_ids = itertools.count(1)


async def send(player_id, message_type, **fields):
    """Manda uma mensagem a um jogador. Jogador que já saiu é ignorado."""
    player = players.get(player_id)
    if player is None:
        return
    try:
        await player["socket"].send(json.dumps({"tipo": message_type, **fields}))
    except websockets.ConnectionClosed:
        pass


async def broadcast(message_type, skip=None, **fields):
    """Manda uma mensagem a todos os jogadores que já disseram o nome."""
    for player_id in list(players):
        if player_id != skip and players[player_id]["name"] is not None:
            await send(player_id, message_type, **fields)


def room_summary(room_id):
    room = rooms[room_id]
    return {
        "sala": room_id,
        "anfitriao": room["host"],
        "membros": [{"id": member, "nome": players[member]["name"]} for member in room["members"]],
    }


async def notify_room(room_id):
    for member in rooms[room_id]["members"]:
        await send(member, "sala_atualizada", **room_summary(room_id))


async def leave_room(player_id):
    """Tira o jogador da sala em que está. Se ele era o anfitrião, a sala acaba."""
    room_id = players[player_id]["room"]
    if room_id is None or room_id not in rooms:
        return
    players[player_id]["room"] = None
    room = rooms[room_id]
    room["members"].remove(player_id)
    if room["host"] == player_id or not room["members"]:
        for member in room["members"]:
            players[member]["room"] = None
            await send(member, "sala_encerrada", sala=room_id)
        del rooms[room_id]
    else:
        await notify_room(room_id)


async def on_enter(player_id, message):
    name = str(message.get("nome", "")).strip()[:MAX_NAME_LENGTH] or f"Jogador{player_id}"
    players[player_id]["name"] = name
    online = [
        {"id": other, "nome": players[other]["name"]}
        for other in players
        if other != player_id and players[other]["name"] is not None
    ]
    await send(player_id, "bem_vindo", id=player_id, nome=name, online=online)
    await broadcast("jogador_entrou", skip=player_id, id=player_id, nome=name)
    print(f"[entrou] {name} ({player_id})")


async def on_chat(player_id, message):
    text = str(message.get("texto", "")).strip()[:MAX_CHAT_LENGTH]
    if text:
        await broadcast("chat", de=player_id, nome=players[player_id]["name"], texto=text)


async def on_invite(player_id, message):
    target = message.get("para")
    if target not in players or target == player_id:
        return
    room_id = players[player_id]["room"]
    if room_id is None:
        room_id = f"sala{next(_room_ids)}"
        rooms[room_id] = {"host": player_id, "members": [player_id]}
        players[player_id]["room"] = room_id
        await notify_room(room_id)
    # Só o anfitrião convida, para a sala ter um dono só.
    if rooms[room_id]["host"] != player_id:
        return
    await send(target, "convite", de=player_id, nome=players[player_id]["name"], sala=room_id)


async def on_invite_answer(player_id, message):
    room_id = message.get("sala")
    if room_id not in rooms:
        return
    if not message.get("aceita", False):
        await send(rooms[room_id]["host"], "convite_recusado", de=player_id, nome=players[player_id]["name"])
        return
    await leave_room(player_id)
    rooms[room_id]["members"].append(player_id)
    players[player_id]["room"] = room_id
    await notify_room(room_id)


async def on_leave_room(player_id, _message):
    await leave_room(player_id)


async def on_start_dungeon(player_id, _message):
    room_id = players[player_id]["room"]
    if room_id is None or rooms[room_id]["host"] != player_id:
        return
    for member in rooms[room_id]["members"]:
        await send(member, "dungeon_iniciada", **room_summary(room_id))


async def on_room_message(player_id, message):
    """O canal do jogo: repassa o conteúdo aos outros membros, sem olhar o que é."""
    room_id = players[player_id]["room"]
    if room_id is None:
        return
    for member in rooms[room_id]["members"]:
        if member != player_id:
            await send(member, "sala", de=player_id, dados=message.get("dados", {}))


# As rotas, como no API Gateway: o campo "action" da mensagem escolhe a função.
ROUTES = {
    "entrar": on_enter,
    "chat": on_chat,
    "convidar": on_invite,
    "responder_convite": on_invite_answer,
    "sair_da_sala": on_leave_room,
    "iniciar_dungeon": on_start_dungeon,
    "sala": on_room_message,
}


async def handle_connection(socket):
    player_id = f"j{next(_player_ids)}"
    players[player_id] = {"socket": socket, "name": None, "room": None}
    try:
        async for raw_message in socket:
            try:
                message = json.loads(raw_message)
            except json.JSONDecodeError:
                continue
            route = ROUTES.get(message.get("action"))
            # Antes de dizer o nome, a única rota aceita é a de entrada.
            if route is None or (players[player_id]["name"] is None and route is not on_enter):
                continue
            await route(player_id, message)
    except websockets.ConnectionClosed:
        pass
    finally:
        name = players[player_id]["name"]
        await leave_room(player_id)
        del players[player_id]
        if name is not None:
            await broadcast("jogador_saiu", id=player_id, nome=name)
            print(f"[saiu] {name} ({player_id})")


async def main():
    parser = argparse.ArgumentParser(description="Servidor local de repasse do Cyber Moon.")
    parser.add_argument("--porta", type=int, default=DEFAULT_PORT)
    arguments = parser.parse_args()
    async with websockets.serve(handle_connection, "0.0.0.0", arguments.porta):
        print(f"Servidor de repasse ouvindo em ws://localhost:{arguments.porta}")
        await asyncio.Future()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
