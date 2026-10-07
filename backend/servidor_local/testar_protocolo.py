"""Teste do protocolo do servidor local: sobe o servidor, conecta dois clientes e confere
cada rota. Rodar com: python3 backend/servidor_local/testar_protocolo.py
"""

import asyncio
import json
import subprocess
import sys
from pathlib import Path

import websockets

PORT = 8799
URL = f"ws://localhost:{PORT}"


async def send(socket, action, **fields):
    await socket.send(json.dumps({"action": action, **fields}))


async def receive(socket, expected_type):
    """Lê mensagens até chegar uma do tipo esperado, e a devolve."""
    while True:
        message = json.loads(await asyncio.wait_for(socket.recv(), timeout=2))
        if message["tipo"] == expected_type:
            return message


async def run():
    async with websockets.connect(URL) as ana, websockets.connect(URL) as beto:
        await send(ana, "entrar", nome="Ana")
        ana_id = (await receive(ana, "bem_vindo"))["id"]
        await send(beto, "entrar", nome="Beto")
        welcome = await receive(beto, "bem_vindo")
        beto_id = welcome["id"]
        assert welcome["online"] == [{"id": ana_id, "nome": "Ana"}], welcome
        assert (await receive(ana, "jogador_entrou"))["nome"] == "Beto"
        print("ok: entrar, bem_vindo e jogador_entrou")

        await send(ana, "chat", texto="oi")
        assert (await receive(beto, "chat")) == {"tipo": "chat", "de": ana_id, "nome": "Ana", "texto": "oi"}
        assert (await receive(ana, "chat"))["texto"] == "oi"
        print("ok: chat chega a todos")

        # Sem convite, ninguém entra numa sala, mesmo sabendo o id dela.
        async with websockets.connect(URL) as intruso:
            await send(intruso, "entrar", nome="Intruso")
            await receive(intruso, "bem_vindo")
            await send(ana, "convidar", para=beto_id)
            first_invite = await receive(beto, "convite")
            await send(intruso, "responder_convite", sala=first_invite["sala"], aceita=True)
            await send(beto, "responder_convite", sala=first_invite["sala"], aceita=False)
            assert (await receive(ana, "convite_recusado"))["de"] == beto_id
            try:
                await asyncio.wait_for(receive(intruso, "sala_atualizada"), timeout=0.5)
                raise AssertionError("o intruso entrou na sala sem convite")
            except asyncio.TimeoutError:
                pass
        print("ok: sem convite não entra na sala, e a recusa chega ao anfitrião")

        await send(ana, "convidar", para=beto_id)
        invite = await receive(beto, "convite")
        assert invite["de"] == ana_id
        await send(beto, "responder_convite", sala=invite["sala"], aceita=True)
        room = await receive(beto, "sala_atualizada")
        assert room["anfitriao"] == ana_id and [m["id"] for m in room["membros"]] == [ana_id, beto_id], room
        print("ok: convite e sala com os dois")

        await send(beto, "iniciar_dungeon")
        await send(ana, "iniciar_dungeon")
        assert (await receive(beto, "dungeon_iniciada"))["anfitriao"] == ana_id
        print("ok: só o anfitrião inicia a dungeon")

        await send(beto, "sala", dados={"tipo": "golpe", "inimigo": 3, "dano": 10})
        relayed = await receive(ana, "sala")
        assert relayed["de"] == beto_id and relayed["dados"]["inimigo"] == 3
        print("ok: mensagem da sala repassada ao outro membro")

        await ana.close()
        assert (await receive(beto, "sala_encerrada"))["sala"] == invite["sala"]
        assert (await receive(beto, "jogador_saiu"))["id"] == ana_id
        print("ok: anfitrião saiu, sala encerrada e jogador_saiu")


def main():
    server = subprocess.Popen(
        [sys.executable, str(Path(__file__).parent / "servidor.py"), "--porta", str(PORT)],
        stdout=subprocess.DEVNULL,
    )
    try:
        asyncio.run(asyncio.sleep(0.6))
        asyncio.run(run())
        print("Protocolo conferido.")
    finally:
        server.terminate()


if __name__ == "__main__":
    main()
