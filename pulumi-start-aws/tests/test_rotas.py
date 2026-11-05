"""As rotas do chat e da sala, com a mesma cobertura do backend/servidor_local/testar_protocolo.py."""

import on_chat
import on_connect
import on_convidar
import on_disconnect
import on_entrar
import on_iniciar_dungeon
import on_responder_convite
import on_sair_da_sala
import on_sala
import utils

from .conftest import call


def connect_players(*players):
    """Abre a conexão e manda o entrar de cada jogador, na ordem. O id é o nome minúsculo."""
    for name in players:
        call(on_connect, name.lower())
        call(on_entrar, name.lower(), nome=name)


def build_room(api, host, *guests):
    """O anfitrião convida cada um, e cada um aceita. Devolve o id da sala."""
    for guest in guests:
        call(on_convidar, host, para=guest)
        room_id = api.last(guest, 'convite')['sala']
        call(on_responder_convite, guest, sala=room_id, aceita=True)
    return room_id


def test_bem_vindo_traz_quem_ja_esta_online(api):
    connect_players('Ana', 'Beto')
    assert api.last('beto', 'bem_vindo') == {
        'tipo': 'bem_vindo',
        'id': 'beto',
        'nome': 'Beto',
        'online': [{'id': 'ana', 'nome': 'Ana'}],
    }
    assert api.last('ana', 'jogador_entrou') == {'tipo': 'jogador_entrou', 'id': 'beto', 'nome': 'Beto'}


def test_chat_chega_em_todos(api):
    connect_players('Ana', 'Beto')
    call(on_chat, 'ana', texto='oi')
    assert api.last('beto', 'chat') == {'tipo': 'chat', 'de': 'ana', 'nome': 'Ana', 'texto': 'oi'}
    assert api.last('ana', 'chat')['texto'] == 'oi'


def test_quem_nao_entrou_nao_manda_chat(api):
    connect_players('Ana')
    call(on_connect, 'intruso')
    call(on_chat, 'intruso', texto='oi')
    assert 'chat' not in api.types('ana')


def test_nome_da_conta_vale_mais_que_o_do_jogo(api):
    event = {
        'requestContext': {
            'connectionId': 'ana',
            'authorizer': {'principalId': 'conta-1', 'nome': 'AnaDaConta'},
        },
    }
    on_connect.handler(event, None)
    call(on_entrar, 'ana', nome='OutroNome')
    assert api.last('ana', 'bem_vindo')['nome'] == 'AnaDaConta'


def test_convite_aceito_monta_a_sala(api):
    connect_players('Ana', 'Beto')
    call(on_convidar, 'ana', para='beto')
    assert api.last('ana', 'sala_atualizada')['membros'] == [{'id': 'ana', 'nome': 'Ana'}]
    convite = api.last('beto', 'convite')
    assert convite['de'] == 'ana' and convite['nome'] == 'Ana'

    call(on_responder_convite, 'beto', sala=convite['sala'], aceita=True)
    for jogador in ('ana', 'beto'):
        sala = api.last(jogador, 'sala_atualizada')
        assert [membro['id'] for membro in sala['membros']] == ['ana', 'beto']
        assert sala['anfitriao'] == 'ana'


def test_convite_recusado_avisa_o_anfitriao_e_nao_serve_de_novo(api):
    connect_players('Ana', 'Beto')
    call(on_convidar, 'ana', para='beto')
    sala = api.last('beto', 'convite')['sala']
    call(on_responder_convite, 'beto', sala=sala, aceita=False)
    assert api.last('ana', 'convite_recusado') == {'tipo': 'convite_recusado', 'de': 'beto', 'nome': 'Beto'}

    # O convite foi gasto na recusa: aceitar depois não põe o Beto na sala.
    call(on_responder_convite, 'beto', sala=sala, aceita=True)
    assert utils.get_room(sala)['membros'] == ['ana']


def test_quem_nao_foi_convidado_nao_entra_mesmo_sabendo_o_id(api):
    connect_players('Ana', 'Beto', 'Caio')
    sala = build_room(api, 'ana', 'beto')
    call(on_responder_convite, 'caio', sala=sala, aceita=True)
    assert utils.get_room(sala)['membros'] == ['ana', 'beto']


def test_so_o_anfitriao_convida(api):
    connect_players('Ana', 'Beto', 'Caio')
    build_room(api, 'ana', 'beto')
    call(on_convidar, 'beto', para='caio')
    assert 'convite' not in api.types('caio')


def test_so_o_anfitriao_inicia_a_dungeon(api):
    connect_players('Ana', 'Beto')
    build_room(api, 'ana', 'beto')
    call(on_iniciar_dungeon, 'beto', dungeon='mina')
    assert 'dungeon_iniciada' not in api.types('ana')

    call(on_iniciar_dungeon, 'ana', dungeon='mina')
    for jogador in ('ana', 'beto'):
        assert api.last(jogador, 'dungeon_iniciada')['dungeon'] == 'mina'


def test_rota_sala_repassa_aos_outros_e_nao_a_quem_mandou(api):
    connect_players('Ana', 'Beto', 'Caio')
    build_room(api, 'ana', 'beto', 'caio')
    call(on_sala, 'beto', dados={'x': 1})
    for jogador in ('ana', 'caio'):
        assert api.last(jogador, 'sala') == {'tipo': 'sala', 'de': 'beto', 'dados': {'x': 1}}
    assert 'sala' not in api.types('beto')


def test_anfitriao_desconecta_e_a_sala_acaba(api):
    connect_players('Ana', 'Beto')
    sala = build_room(api, 'ana', 'beto')
    call(on_disconnect, 'ana')
    assert api.last('beto', 'sala_encerrada') == {'tipo': 'sala_encerrada', 'sala': sala}
    assert api.last('beto', 'jogador_saiu') == {'tipo': 'jogador_saiu', 'id': 'ana', 'nome': 'Ana'}
    assert utils.get_room(sala) is None
    assert 'sala' not in utils.get_connection('beto')


def test_membro_sai_e_a_sala_continua(api):
    connect_players('Ana', 'Beto', 'Caio')
    sala = build_room(api, 'ana', 'beto', 'caio')
    call(on_sair_da_sala, 'caio')
    assert utils.get_room(sala)['membros'] == ['ana', 'beto']
    assert [membro['id'] for membro in api.last('ana', 'sala_atualizada')['membros']] == ['ana', 'beto']


def test_conexao_que_caiu_nao_interrompe_o_envio_e_e_apagada(api):
    connect_players('Ana', 'Beto', 'Caio')
    api.gone.add('beto')
    call(on_chat, 'ana', texto='oi')
    assert api.last('caio', 'chat')['texto'] == 'oi'
    assert utils.get_connection('beto') is None


def test_replace_members_recusa_quem_leu_a_sala_antes_de_outra_gravacao(api):
    connect_players('Ana', 'Beto', 'Caio')
    sala = build_room(api, 'ana', 'beto')
    lida_antes = utils.get_room(sala)
    assert utils.replace_members(utils.get_room(sala), ['ana']) is True
    assert utils.replace_members(lida_antes, ['ana', 'beto', 'caio']) is False
    assert utils.get_room(sala)['membros'] == ['ana']
