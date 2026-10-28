# Plano 37: Mundo real: hora, clima e fase da Lua

**Objetivo:** ligar o jogo ao mundo de fora. Ao abrir o jogo, o relógio começa na hora
real do computador. O clima do dia vem do tempo real de Florianópolis (API Open-Meteo), e
a fase da Lua vem do calendário real (API do USNO), com efeito na noite e na lavoura.

**Depende de:** 10 (dia e noite), 13 (clima), 06 (plantio) e 20 (save).

**Situação:** só registrado.

## O pedido do Antonio (2026-10-27)

- Usar uma API web que combine com o jogo: Open-Meteo para o clima e uma API de fases da
  Lua.
- **Dormir continua sendo a virada do dia.** Sem dormir (ou cair de sono à 1:00), o dia
  não vira e as plantas não crescem. O tempo real não substitui o relógio do jogo.
- **Ao iniciar o jogo, o primeiro horário é sincronizado com o tempo real.** Depois disso o
  relógio anda na velocidade normal do jogo (5 minutos reais de dia e 5 de noite).

## Decisões do Antonio (2026-10-27)

- **A Lua mexe em três coisas:** a iluminação da noite, um bônus de crescimento e um
  bônus de rendimento na colheita. Detalhes em "O que a Lua faz no jogo".
- **A hora pode voltar dentro do mesmo dia.** Salvar às 22:00 e reabrir às 10:00 começa
  às 10:00 do mesmo dia do jogo. Depois de sincronizar, o tempo anda rápido, igual
  funciona hoje.

## Como fica, em resumo

| O quê | De onde vem | Quando |
| --- | --- | --- |
| Hora inicial | Relógio do computador (`Time`), sem internet | Uma vez, ao abrir o jogo |
| Hora depois disso | `DayCycleManager`, como hoje | O tempo todo |
| Virada do dia | Dormir na cama, cair de sono ou desmaiar, como hoje | Só assim |
| Clima do dia | Open-Meteo; sem resposta, o sorteio da estação de hoje | Ao abrir o jogo e a cada dia novo |
| Fase da Lua | USNO; sem resposta, cálculo local | Ao abrir o jogo e a cada dia novo |
| Estação e número do dia | O jogo, como hoje (não seguem o calendário real) | Sem mudança |

## A hora inicial

Não precisa de API: o sistema operacional já sabe a hora local.
`Time.get_time_dict_from_system()` devolve hora e minuto, e isso vira `hora_atual` com
`DayCycleManager.definir_hora()`, uma vez, depois que o save carregou (senão o save
sobrescreve a hora sincronizada).

O dia do jogo vai das 6:00 à 1:00, então a madrugada real não cabe nele:

- **Entre 6:00 e 23:59**, a hora real vale como está.
- **Entre 0:00 e 0:59**, vale como 24.0 a 24.98 (é assim que o relógio conta depois da
  meia-noite). Decidir: nesse caso o jogador cai de sono poucos segundos depois de abrir.
  Sugestão: tratar como madrugada e começar às 6:00.
- **Entre 1:00 e 5:59** (a madrugada, que não existe no jogo), começa às 6:00.

A sincronização acontece só ao abrir. Dormir continua acordando às 6:00 do dia seguinte,
sem consultar o relógio real de novo.

**Com save:** o save guarda o número do dia e a hora. Ao abrir, o número do dia vem do
save e a hora vem do relógio real. Isso pode voltar a hora dentro do mesmo dia (salvou às
22:00, abriu às 10:00), o que dá mais tempo ao jogador. Decidido que pode: o crescimento só
acontece dormindo, então voltar a hora não adianta a lavoura.

**Com `--sem-save` e no coop:** a hora inicial vale para quem hospeda. Quem entra segue a
hora de quem hospeda, como já acontece hoje.

## O clima real (Open-Meteo)

```
https://api.open-meteo.com/v1/forecast?latitude=-27.59&longitude=-48.55&current=weather_code&timezone=auto
```

Gratuita, sem chave e com CORS liberado (funciona também no export web). A resposta traz
`current.weather_code`, um código WMO, que vira um dos três climas do jogo:

| Código WMO | Significado | Clima do jogo |
| --- | --- | --- |
| 0 a 3, 45, 48 | Céu limpo, nuvens, neblina | `sol` |
| 51 a 67, 71 a 77, 80 a 86 | Garoa, chuva, neve, pancadas | `chuva` |
| 95 a 99 | Trovoada | `tempestade` |

A tabela fica no `.tres` de configuração, não no código.

**Quando consulta:**

- **Ao abrir o jogo:** a resposta troca o clima de hoje com `WeatherManager.definir_clima()`.
  Se vier chuva, o `weather_changed` sai e a `GradeSolo` molha o solo, como já faz.
- **A cada dia novo:** depois do `day_started`, consulta de novo e troca o clima do dia
  que começou. O clima continua sem mudar no meio do dia, como diz o plano 13.

**Sem internet, ou se a resposta demorar mais que o limite (5 segundos):** fica o sorteio
da estação, que já roda hoje. O jogo nunca espera a API para começar.

**Clima de amanhã:** continua sorteado. A Open-Meteo dá previsão (`daily=weather_code`),
mas o dia do jogo não é o dia real; usar a previsão só faria sentido se a previsão do tempo
na TV (ideia antiga do plano 13) virar feature.

## A fase da Lua (USNO)

```
https://aa.usno.navy.mil/api/moon/phases/date?date=2026-10-19&nump=4
```

Gratuita, sem chave. Pedindo a partir de 8 dias atrás com `nump=4`, a resposta traz as
fases principais em volta de hoje (`phasedata`, com `phase` em inglês: `New Moon`,
`First Quarter`, `Full Moon`, `Last Quarter`, e a data). A fase de hoje é a última fase da
lista com data até hoje, e vira um enum:

```gdscript
enum FaseDaLua { NOVA, CRESCENTE, CHEIA, MINGUANTE }
```

**Sem internet:** a fase sai de conta local. O mês lunar tem 29,53 dias, e houve lua nova
em 6 de janeiro de 2000, às 18:14 UTC. Os dias desde então, divididos por 29,53, dão a
posição no ciclo. A conta tem erro de cerca de um dia, que não importa para o jogo, e é a
mesma que garante que a feature funciona na apresentação mesmo sem rede.

**Verificar no passo 1:** se o USNO responde com CORS liberado. Se não, o export web usa
sempre a conta local (e aí vale perguntar se a API faz falta ou se a conta basta).

**A Lua segue o calendário real, não o dia do jogo.** Dormir três vezes seguidas não troca
a fase. Ela só muda quando o dia real muda.

### O que a Lua faz no jogo

Decidido (2026-10-27): iluminação, crescimento e rendimento.

- **Luz da noite.** A `IluminacaoDoCiclo` já faz a luz direcional virar lua à noite. A
  energia dessa luz passa a depender da fase: lua cheia clareia a fazenda, lua nova deixa
  bem escuro, crescente e minguante ficam no meio.
- **Bônus de crescimento.** Ao dormir numa noite de lua cheia, cada planta regada tem uma
  chance (sugestão: 25%) de crescer um dia a mais. Entra dentro de `avancar_um_dia()` da
  `GradeSolo`, que continua sendo o único lugar que mexe no crescimento. Planta seca
  continua murchando; a Lua não salva quem não regou. Crescente dá uma chance menor
  (sugestão: 10%); nova e minguante não dão bônus.
- **Bônus de rendimento.** Colher com lua cheia rende mais: depois do sorteio entre
  `quantidade_colhida_minima` e `quantidade_colhida_maxima` em `colher()` da `GradeSolo`,
  a quantidade ganha um item a mais com uma chance (sugestão: 50%). O `crop_harvested`
  já sai com a quantidade final, então o inventário, a economia e o diário não mudam.
- **Relógio da tela.** Um ícone pequeno da fase ao lado do relógio (`hud_relogio`), para
  o jogador saber quando vale a pena plantar e colher.

Os números (chance de crescer e de render por fase, energia da luz por fase) ficam no
`.tres`, para o balanceamento final mexer sem tocar no código. A `GradeSolo` só lê
`RealWorldManager.fase_da_lua` e os números da configuração; ela não sabe de onde a fase
veio.

Fica de fora, por enquanto: lua nova deixando a dungeon mais difícil ou com mais saque.

## Arquitetura

Um autoload novo, `RealWorldManager` (`scripts/core/real_world_manager.gd`), com uma
responsabilidade só: perguntar ao mundo de fora e avisar o resto do jogo. Ele não mexe em
planta, luz nem interface.

```gdscript
signal real_weather_received(clima: StringName)
signal moon_phase_changed(fase: FaseDaLua)

var fase_da_lua: FaseDaLua
## Falso quando a fase veio da conta local, para o menu de debug mostrar a origem.
var fase_veio_da_api: bool = false

func sincronizar_hora_inicial() -> void
func consultar_clima() -> void
func consultar_fase_da_lua() -> void
func fase_calculada_localmente(data_unix: float) -> FaseDaLua
func clima_do_codigo_wmo(codigo: int) -> StringName
```

- Cada consulta usa um `HTTPRequest` filho, com `timeout` do `.tres`. A resposta é lida
  com `JSON.parse_string()`; qualquer coisa fora do formato esperado conta como "sem
  resposta" e cai no plano B, com um `push_warning`, nunca `push_error` (estar sem
  internet não é erro).
- **Quem escuta:** o `WeatherManager` escuta `real_weather_received` e chama
  `definir_clima()`. A `GradeSolo` e a `IluminacaoDoCiclo` leem `fase_da_lua` e escutam
  `moon_phase_changed`. O `RealWorldManager` não conhece nenhum deles.
- **Ordem:** entra na lista de autoloads depois do `SaveManager`, e a sincronização da
  hora espera o `game_loaded` (ou o fim do `_ready`, quando não há save).
- **Save:** não salva nada. Hora, clima e Lua são consultados de novo a cada abertura.
  O clima salvo continua valendo até a resposta chegar, e é a reserva se ela não chegar.

**Configuração** em `resources/mundo_real/configuracao.tres`, classe
`ConfiguracaoMundoReal` (`scripts/resources/configuracao_mundo_real.gd`):

- `latitude`, `longitude` (Florianópolis por padrão), `segundos_de_limite` (5.0).
- `url_do_clima`, `url_da_lua` (com marcadores para coordenada e data).
- `clima_por_codigo_wmo: Dictionary[int, StringName]`.
- `chance_de_crescer_por_fase`, `chance_de_render_por_fase`, `energia_da_lua_por_fase`,
  os três `Dictionary[int, float]` com a fase da Lua como chave.
- `usar_apis: bool`: desligado, o jogo usa só sorteio e conta local. Serve para teste e
  para jogar offline sem esperar o limite.

Documentar o autoload novo em `game/docs/arquitetura.md`, na lista dos autoloads.

## Partículas

Pela regra do projeto, a ação nova já nasce com efeito, pela tabela do `EfeitosDoJogo`:

- **`lua_cheia`:** a planta que ganhou o dia extra da lua cheia solta um brilho branco
  azulado subindo (o mesmo molde do `crescer`, com outra cor). Sinal novo no `EventBus`:
  `moon_growth_applied(celula: Vector2i)`.
- **`colheita_da_lua`:** quando a colheita ganha o item extra, um punhado de faíscas
  prateadas sai da célula, junto do efeito de colheita que já existe. Sinal novo no
  `EventBus`: `moon_harvest_bonus(celula: Vector2i)`.
- A troca de clima já tem efeito (a chuva do plano 13), e a hora inicial não é ação do
  jogador. Nada novo para elas.

## Assets

- Quatro ícones de fase da Lua para o relógio da tela, em pixel art no estilo dos ícones
  que já existem. Criar junto com o passo 7; se ficarem provisórios, registrar em
  `equipe/assets-pendentes.md` com o campo do `.tres` onde entram.

## Passos

- [ ] **1.** Testar as duas URLs no navegador e no Godot (um `HTTPRequest` num script de
  teste), conferir o formato da resposta e se o USNO libera CORS. Ajustar este plano se o
  formato mudou.
- [ ] **2.** Criar `ConfiguracaoMundoReal` e o `.tres`.
- [ ] **3.** Criar o `RealWorldManager` com a hora inicial. Testar abrindo o jogo às
  10:00 (começa às 10:00), à 0:30 e às 3:00 (começa às 6:00), com e sem save. Para testar
  sem esperar o relógio, aceitar um argumento `--hora-real=HH:MM`, como o `--sem-save`.
- [ ] **4.** Clima pela Open-Meteo, com o plano B do sorteio. Testar com a rede
  desligada (o jogo abre normal e sem travar) e com `usar_apis` desligado.
- [ ] **5.** Fase da Lua pelo USNO, com a conta local. Conferir a conta local contra a
  API em quatro datas conhecidas.
- [ ] **6.** Efeitos da Lua: a luz da noite por fase, o bônus de crescimento (partícula
  `lua_cheia`) e o bônus de rendimento (partícula `colheita_da_lua`). Testar forçando cada
  fase pelo menu de debug: plantar, regar e dormir com lua cheia e com lua nova, e colher
  dez vezes em cada uma, conferindo que só a cheia rende a mais.
- [ ] **7.** Ícone da fase no relógio da tela.
- [ ] **8.** Mostrar no menu de debug a origem de cada dado (API ou reserva) e um botão
  para forçar cada fase da Lua. Atualizar `arquitetura.md`.

## Como saber que ficou pronto

- Abrir o jogo às 14:20 reais mostra 14:20 no relógio, e o tempo anda na velocidade do
  jogo a partir daí.
- Sem dormir, o dia não vira e nenhuma planta cresce. Dormindo, acorda às 6:00 do dia
  seguinte, como antes.
- Chovendo em Florianópolis, chove na fazenda ao abrir o jogo, e o solo fica molhado.
- Sem internet, o jogo abre no mesmo tempo de sempre, com clima sorteado e Lua calculada.
- Numa noite de lua cheia real, a fazenda está mais clara que numa de lua nova.
- Com lua cheia, parte das plantas regadas cresce um dia a mais ao dormir, e parte das
  colheitas rende um item a mais, cada uma com a sua partícula.
- Abrir de novo no mesmo dia do jogo, mais cedo que a hora salva, volta o relógio, e o
  tempo anda na velocidade de sempre.
