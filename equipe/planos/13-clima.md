# Plano 13: Condições climáticas

**Objetivo:** o dia pode amanhecer com sol ou com chuva. Chuva escurece a cena, reduz a
visibilidade, e molha todas as plantações sozinha.

**Depende de:** 10 (o clima é sorteado por dia), 11 (a chance de chuva vem da estação),
06 (molhar as plantações).

## Decisões fechadas

**O clima é sorteado no início do dia e não muda no meio.** Clima mudando no meio do dia
é bonito mas complica o planejamento do jogador, e o valor da chuva aqui é justamente
economizar a rega do dia: precisa ser previsível a partir do amanhecer.

**Três climas, não mais.** Sol, chuva e tempestade. Tempestade é chuva forte com raio, e
serve de evento raro.

| Clima | Peso | Efeito |
|---|---|---|
| `sol` | o resto | nada muda |
| `chuva` | `chance_de_chuva` da estação | molha tudo, escurece, reduz visibilidade |
| `tempestade` | um quinto da chance de chuva | igual à chuva, mais forte, com raio e som |

**A chuva molha o solo arado, não a planta.** O efeito real é: no amanhecer chuvoso, todo
tile `ARADO_SECO` vira `ARADO_MOLHADO`. Isso reaproveita o sistema do plano 06 inteiro,
sem inventar um segundo conceito de "molhado".

**Chuva é partícula, não shader de tela.** `GPUParticles3D` seguindo a câmera, com um
material simples de linha. Em GL Compatibility isso é mais barato e mais previsível que
efeito de pós-processamento.

## Modelo

`game/scripts/core/weather_manager.gd`, autoload novo:

```gdscript
extends Node

signal clima_mudou(clima: StringName)

const CLIMAS: Array[StringName] = [&"sol", &"chuva", &"tempestade"]

var clima_atual: StringName = &"sol"
var clima_de_amanha: StringName = &"sol"

func esta_chovendo() -> bool     # true para chuva e para tempestade
func sortear_clima_do_dia() -> StringName
```

`clima_de_amanha` é sorteado junto com o de hoje. Ele não é usado por nada ainda, e existe
para a previsão do tempo virar barata depois (está em `sugestoes-de-features.md`).

Conectado a `DayCycleManager.day_started`.

## Efeitos

**Molhar as plantações.** No `clima_mudou`, se está chovendo, a `GradeSolo` varre o
`_estado` e passa todo `ARADO_SECO` para `ARADO_MOLHADO`, emitindo `tile_watered` de cada
um para o visual acompanhar. Reuse `molhar()`, que já faz a checagem certa.

**Iluminação.** O `IluminacaoDoCiclo` multiplica a energia por 0.55 na chuva e por 0.4 na
tempestade, e desloca a cor para o cinza azulado. A luz do jogador ganha importância, o
que é bom.

**Visibilidade.** Névoa do `WorldEnvironment`: liga `fog_enabled`, densidade por volta de
0.02 na chuva e 0.035 na tempestade, cor cinza azulada. Isso reduz o alcance visual sem
custar quase nada.

**Partícula.** Cena `game/scenes/mundo/chuva.tscn`, um `GPUParticles3D` com caixa de
emissão larga e achatada, posicionada acima do jogador e seguindo ele em `_process`.
Quantidade por volta de 800 na chuva e 2000 na tempestade. Emissão desligada no sol.

**Som.** `AudioManager` no bus `Ambiente`, em loop, com fade ao ligar e desligar. Um
`AudioStreamPlayer` comum, não posicionado, porque chuva vem de todo lado. Sem clipe, não
sai som e não dá erro, como todo o resto do plano 02.

**Raio, na tempestade.** A cada 8 a 20 segundos, um clarão: a energia da luz direcional
sobe muito por 0.1 segundo e volta. Um `Tween` resolve. O trovão toca 1 a 3 segundos
depois, o que dá uma sensação de distância boa por quase nada de esforço.

## Interface

Um ícone ao lado do relógio da HUD indicando o clima do dia. Três ícones simples, ou três
letras se não houver arte.

## Tarefas

- [ ] **1.** Criar o `WeatherManager`, sortear no `day_started` usando a
  `chance_de_chuva` do perfil da estação. Verificar por script headless: rodar 400 dias e
  conferir que a proporção de chuva bate mais ou menos com a chance da estação.
- [ ] **2.** Molhar o solo arado no amanhecer chuvoso.
- [ ] **3.** Ligar a iluminação e a névoa ao clima.
- [ ] **4.** Criar `chuva.tscn` e fazer seguir a câmera.
- [ ] **5.** Ligar o som de chuva no bus `Ambiente`.
- [ ] **6.** Implementar o raio e o trovão da tempestade.
- [ ] **7.** Adicionar o ícone de clima na HUD.
- [ ] **8.** Documentar e commitar.

## Critério de pronto

- Dias alternam entre sol e chuva, e a proporção acompanha a estação.
- Amanhecer chuvoso deixa todo o solo arado molhado sem o jogador regar.
- Na chuva a cena escurece, a névoa reduz o alcance da visão, e a partícula cai.
- Na tempestade, o clarão e o trovão acontecem de tempos em tempos.
- O jogo roda sem erro com zero clipes de áudio de chuva.

## Fora de escopo

- **Clima mudando no meio do dia.** Decisão consciente, explicada acima.
- **Neve no apagão.** Seria a mesma partícula com outra textura e outra velocidade, e é
  barato de fazer depois. Está em `sugestoes-de-features.md`.
- **Chuva molhando o jogador.** Efeito visual no personagem.
- **Clima afetando o inimigo ou o NPC.** Chuva fazendo NPC ficar em casa é excelente e
  cabe no plano 14, mas exige a rotina existir primeiro.
- **Poça de água no chão.** Decalque exigiria arte nova.
