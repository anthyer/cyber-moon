class_name ConfiguracaoMundoReal
extends Resource

## De onde o jogo tira a hora, o clima e a fase da Lua do mundo de fora (plano 37), e o
## quanto a Lua mexe na noite e na lavoura.
##
## Os números das fases ficam aqui para o balanceamento final mexer sem tocar no código.
## As chaves dos dicionários de fase são os valores de RealWorldManager.FaseDaLua:
## 0 nova, 1 crescente, 2 cheia, 3 minguante.

## Desligado, o jogo não consulta nada na rede: o clima fica no sorteio da estação e a Lua
## sai da conta local. Serve para teste e para jogar offline sem esperar o limite.
@export var usar_apis: bool = true

@export_group("Local")
## Florianópolis. O clima real é o desta coordenada.
@export var latitude: float = -27.59
@export var longitude: float = -48.55
## Depois deste tempo sem resposta, a consulta desiste e o jogo fica com a reserva. A
## consulta sai logo ao abrir, quando o mapa ainda está carregando e os primeiros quadros
## demoram; com 5 segundos ela estourava mesmo com a rede boa. O jogo não espera a
## resposta, então um limite maior não atrasa nada.
@export var segundos_de_limite: float = 15.0

@export_group("Endereços")
## {latitude} e {longitude} são trocados pela coordenada acima.
@export var url_do_clima: String = "https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&current=weather_code&timezone=auto"
## {data} é trocado pela data de alguns dias atrás (AAAA-MM-DD), para a lista trazer a
## última fase principal antes de hoje.
@export var url_da_lua: String = "https://aa.usno.navy.mil/api/moon/phases/date?date={data}&nump=4"
## Quantos dias antes de hoje a consulta da Lua começa. As fases principais caem a cada
## 7,4 dias, então 8 garante que a lista começa antes da fase de hoje.
@export var dias_antes_de_hoje_na_consulta_da_lua: int = 8

@export_group("Clima")
## Código WMO da Open-Meteo para o clima do jogo. Código que não está aqui conta como
## sem resposta, e o clima sorteado fica.
@export var clima_por_codigo_wmo: Dictionary[int, StringName] = {}

@export_group("Lua")
## Chance de cada planta regada crescer um dia a mais na noite em que o jogador dorme.
@export var chance_de_crescer_por_fase: Dictionary[int, float] = {}
## Chance de a colheita render um item a mais.
@export var chance_de_render_por_fase: Dictionary[int, float] = {}
## Multiplicador da luz da noite (a luz direcional fazendo o papel da lua).
@export var energia_da_lua_por_fase: Dictionary[int, float] = {}
## O ícone de cada fase, mostrado ao lado do relógio da tela.
@export var icone_por_fase: Dictionary[int, Texture2D] = {}

func url_do_clima_pronta() -> String:
	return url_do_clima.format({"latitude": latitude, "longitude": longitude})

func url_da_lua_pronta(data: String) -> String:
	return url_da_lua.format({"data": data})

func chance_de_crescer(fase: int) -> float:
	return chance_de_crescer_por_fase.get(fase, 0.0)

func chance_de_render(fase: int) -> float:
	return chance_de_render_por_fase.get(fase, 0.0)

func energia_da_lua(fase: int) -> float:
	return energia_da_lua_por_fase.get(fase, 1.0)

func icone_da_fase(fase: int) -> Texture2D:
	return icone_por_fase.get(fase, null)
