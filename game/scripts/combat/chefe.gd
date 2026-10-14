class_name Chefe
extends Inimigo

## O subchefe e o chefe de uma dungeon. É um Inimigo, com tudo o que ele já faz (percebe,
## persegue pela malha, dá o golpe de perto, cai, solta o saque), e mais quatro coisas:
##
##   1. É uma máquina: o modelo é uma malha rígida, sem esqueleto e sem clipes. Quem
##      anima é este script, mexendo no nó do modelo.
##   2. É grande, e tem mais vida quando a equipe é maior.
##   3. Tem ataques próprios, todos anunciados por uma marca no chão (AvisoDeAtaque). O
##      dano só cai quando a marca termina, em quem ainda estiver dentro dela.
##   4. Abaixo de uma fração da vida entra na segunda fase: fica mais rápido, ataca com
##      menos intervalo e ganha os ataques marcados como so_na_fase_2.
##
## Em equipe vale a mesma divisão do Inimigo: o chefe de verdade roda no jogo do
## anfitrião e os outros jogos mostram um fantoche. O fantoche desenha as mesmas marcas,
## avisado pela rede, mas não tira vida de ninguém: o dano chega a cada jogador pela
## mensagem de dano que a Dungeon já manda.

## O tamanho da cápsula antes de multiplicar pela escala do perfil.
const RAIO_BASE_DA_CAPSULA: float = 0.25
const ALTURA_BASE_DA_CAPSULA: float = 0.7
## Usado quando a dungeon não tem definição (uma cena de teste, por exemplo).
const VIDA_A_MAIS_POR_JOGADOR_PADRAO: float = 0.6
## Depois que a marca termina o chefe ainda fica um instante parado, para o jogador ter
## uma brecha para bater.
const SEGUNDOS_DE_RECUPERACAO: float = 0.4

const TIPO_DO_AVISO_NA_REDE: String = "aviso_de_chefe"
const TIPO_DA_FASE_NA_REDE: String = "fase_de_chefe"

# Animação por código. Os ângulos estão em radianos e as distâncias valem para escala 1.
const VELOCIDADE_DO_BALANCO: float = 2.2
const ALTURA_DO_BALANCO: float = 0.03
const ANGULO_DO_BALANCO: float = 0.035
const INCLINACAO_ANDANDO: float = 0.16
const SUAVIDADE_DA_INCLINACAO: float = 8.0
const FORCA_DO_TREMOR: float = 0.03
const FORCA_DO_TREMOR_NA_QUEDA: float = 0.05
## Na queda o modelo afunda no chão e encolhe até esta fração do tamanho.
const AFUNDAMENTO_NA_QUEDA: float = 0.5
const TAMANHO_NO_FIM_DA_QUEDA: float = 0.15
const INCLINACAO_NA_QUEDA: float = 0.5

## A vida máxima já com o acréscimo da equipe. A barra de vida do chefe divide por ela.
var vida_maxima_efetiva: int = 0
## 1 no começo da luta, 2 depois que a vida cai abaixo da fração do perfil.
var fase: int = 1

@onready var _forma_de_colisao: CollisionShape3D = $FormaColisao

## O mesmo perfil do Inimigo, já visto como PerfilChefe. Null se puseram um perfil comum
## nesta cena; aí o chefe se comporta como um inimigo qualquer.
var _perfil_de_chefe: PerfilChefe
var _dungeon: Dungeon
var _ja_engajou: bool = false

var _segundos_ate_o_ataque_especial: float = 0.0
## Enquanto for maior que zero o chefe está preso num ataque anunciado e não anda.
var _segundos_parado_pelo_ataque: float = 0.0
var _segundos_tremendo: float = 0.0
## As marcas que ainda estão no chão, para tirar todas se o chefe cair antes do fim.
var _avisos: Array[AvisoDeAtaque] = []

var _relogio_da_animacao: float = 0.0
var _posicao_no_quadro_anterior: Vector3
var _inclinacao: float = 0.0
var _segundos_caindo: float = 0.0

func _ready() -> void:
	super._ready()
	_perfil_de_chefe = perfil as PerfilChefe
	if _perfil_de_chefe == null:
		push_warning("Chefe sem PerfilChefe: %s" % name)
		return
	_dungeon = get_tree().get_first_node_in_group(Dungeon.GRUPO) as Dungeon
	_aplicar_escala()
	vida_maxima_efetiva = perfil.vida_maxima
	if fantoche:
		# A vida do fantoche chega pela rede, junto com a vida máxima (veja
		# aplicar_estado_da_rede). As marcas e a troca de fase chegam como evento.
		if _dungeon != null:
			_dungeon.event_received.connect(_ao_receber_evento)
	else:
		_calcular_vida_de_equipe()
	_segundos_ate_o_ataque_especial = _perfil_de_chefe.intervalo_entre_ataques_especiais
	_posicao_no_quadro_anterior = global_position

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _perfil_de_chefe == null:
		return
	if estado == Estado.MORRENDO:
		_animar_queda(delta)
		return
	_conferir_engajamento()
	if not fantoche:
		_conferir_fase()
	_segundos_tremendo = maxf(_segundos_tremendo - delta, 0.0)
	_animar_por_codigo(delta)

# Tamanho e vida

## O modelo e a cápsula crescem juntos. A forma de colisão é duplicada antes, porque a
## da cena é compartilhada entre todos os chefes e mudar uma mudaria as outras.
func _aplicar_escala() -> void:
	var escala: float = _perfil_de_chefe.escala
	_modelo.scale = Vector3.ONE * escala
	var capsula: CapsuleShape3D = (_forma_de_colisao.shape as CapsuleShape3D).duplicate() as CapsuleShape3D
	capsula.radius = RAIO_BASE_DA_CAPSULA * escala
	capsula.height = ALTURA_BASE_DA_CAPSULA * escala
	_forma_de_colisao.shape = capsula
	# A cápsula fica com a base no pé do chefe, como a do inimigo comum.
	_forma_de_colisao.position.y = capsula.height * 0.5

## Em equipe o chefe tem mais vida, senão quatro jogadores o derrubam antes de ele
## mostrar os ataques. Cada jogador além do primeiro soma uma fração da vida do perfil.
func _calcular_vida_de_equipe() -> void:
	var jogadores: int = 1
	var vida_a_mais_por_jogador: float = VIDA_A_MAIS_POR_JOGADOR_PADRAO
	if _dungeon != null:
		jogadores = _dungeon.numero_de_jogadores()
		if _dungeon.definicao != null:
			vida_a_mais_por_jogador = _dungeon.definicao.vida_a_mais_por_jogador
	var multiplicador: float = 1.0 + vida_a_mais_por_jogador * float(jogadores - 1)
	vida_maxima_efetiva = roundi(float(perfil.vida_maxima) * multiplicador)
	vida_atual = vida_maxima_efetiva

# Começo da luta e segunda fase

## Avisa uma vez só que a luta começou, para a barra de vida aparecer. No anfitrião a
## luta começa quando o chefe, já acordado, sai do ócio atrás de alguém. O fantoche não
## pensa, então ele olha o que dá para ver: um jogador perto ou a vida já gasta.
func _conferir_engajamento() -> void:
	if _ja_engajou or adormecido:
		return
	if fantoche:
		if vida_atual >= vida_maxima_efetiva and not _ha_jogador_no_raio_de_percepcao():
			return
	elif estado == Estado.OCIOSO:
		return
	_ja_engajou = true
	EventBus.boss_engaged.emit(self)

func _ha_jogador_no_raio_de_percepcao() -> bool:
	for jogador in _jogadores_na_luta():
		if is_instance_valid(jogador) and _distancia_ate(jogador) <= perfil.raio_de_percepcao:
			return true
	return false

## Só o anfitrião decide a troca de fase, porque só ele sabe a vida de verdade. Os outros
## jogos recebem o aviso pela rede.
func _conferir_fase() -> void:
	if fase != 1 or _perfil_de_chefe.fracao_de_vida_da_fase_2 <= 0.0:
		return
	var limite: float = _perfil_de_chefe.fracao_de_vida_da_fase_2 * float(vida_maxima_efetiva)
	if vida_atual <= 0 or float(vida_atual) >= limite:
		return
	_entrar_na_fase(2)
	if _dungeon != null:
		_dungeon.enviar_evento(TIPO_DA_FASE_NA_REDE, {"chefe": numero_na_rede, "fase": fase})

func _entrar_na_fase(nova_fase: int) -> void:
	if nova_fase == fase:
		return
	fase = nova_fase
	EventBus.boss_phase_changed.emit(self, fase)

func _intervalo_entre_ataques_especiais() -> float:
	var intervalo: float = _perfil_de_chefe.intervalo_entre_ataques_especiais
	if fase >= 2:
		intervalo *= _perfil_de_chefe.multiplicador_de_intervalo_na_fase_2
	return intervalo

## Na segunda fase o chefe anda mais rápido. O Inimigo passa a velocidade do perfil para
## cá, e multiplicar aqui evita mexer no perfil, que é compartilhado.
func _andar_ate(destino: Vector3, velocidade: float, delta: float, pela_malha: bool = true) -> void:
	var velocidade_na_fase: float = velocidade
	if _perfil_de_chefe != null and fase >= 2:
		velocidade_na_fase *= _perfil_de_chefe.multiplicador_de_velocidade_na_fase_2
	super._andar_ate(destino, velocidade_na_fase, delta, pela_malha)

# Ataques anunciados

## A perseguição do Inimigo, com os ataques próprios por cima. Enquanto uma marca está no
## chão o chefe fica parado; fora disso conta o intervalo e, entre um ataque especial e
## outro, persegue e dá o golpe de perto como qualquer inimigo.
func _processar_perseguicao(delta: float) -> void:
	if _perfil_de_chefe == null:
		super._processar_perseguicao(delta)
		return
	if _segundos_parado_pelo_ataque > 0.0:
		_segundos_parado_pelo_ataque -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		return
	_segundos_ate_o_ataque_especial -= delta
	if _segundos_ate_o_ataque_especial <= 0.0 and is_instance_valid(_jogador):
		# O intervalo recomeça mesmo se não houver ataque que valha nesta fase, para não
		# sortear de novo a cada quadro.
		_segundos_ate_o_ataque_especial = _intervalo_entre_ataques_especiais()
		var ataque: AtaqueDeChefe = _sortear_ataque()
		if ataque != null:
			_comecar_ataque_especial(ataque)
			return
	super._processar_perseguicao(delta)

## Um ataque ao acaso entre os que valem na fase atual, ou null se não houver nenhum.
func _sortear_ataque() -> AtaqueDeChefe:
	var validos: Array[AtaqueDeChefe] = []
	for ataque in _perfil_de_chefe.ataques:
		if ataque == null:
			continue
		if ataque.so_na_fase_2 and fase < 2:
			continue
		validos.append(ataque)
	if validos.is_empty():
		return null
	return validos.pick_random() as AtaqueDeChefe

## Para, vira para o alvo e põe as marcas no chão. O intervalo até o próximo ataque só
## volta a contar quando o chefe se solta deste.
func _comecar_ataque_especial(ataque: AtaqueDeChefe) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	var posicao_do_alvo: Vector3 = _jogador.global_position
	var para_o_alvo: Vector3 = posicao_do_alvo - global_position
	var giro: float = _modelo.rotation.y
	if Vector2(para_o_alvo.x, para_o_alvo.z).length() > 0.01:
		giro = atan2(para_o_alvo.x, para_o_alvo.z)
	_modelo.rotation.y = giro
	var pontos: Array[Vector3] = _pontos_do_ataque(ataque, posicao_do_alvo)
	_criar_avisos(ataque, pontos, giro, true)
	_segundos_parado_pelo_ataque = ataque.segundos_de_aviso + SEGUNDOS_DE_RECUPERACAO
	_segundos_tremendo = ataque.segundos_de_aviso
	if _maquina != null:
		_maquina.golpear(ataque.segundos_de_aviso + SEGUNDOS_DE_RECUPERACAO)
	_enviar_aviso_pela_rede(ataque, pontos, giro)

## Onde cada marca do ataque nasce. O ponto é sempre no chão em que o chefe pisa: a arena
## de chefe é plana, e a altura do alvo (que pode estar no meio de um pulo) não serve.
func _pontos_do_ataque(ataque: AtaqueDeChefe, posicao_do_alvo: Vector3) -> Array[Vector3]:
	var alvo_no_chao: Vector3 = Vector3(posicao_do_alvo.x, global_position.y, posicao_do_alvo.z)
	var pontos: Array[Vector3] = []
	match ataque.forma:
		AtaqueDeChefe.Forma.CIRCULO_NO_CHEFE, AtaqueDeChefe.Forma.FAIXA_NA_DIRECAO_DO_ALVO:
			pontos.append(global_position)
		AtaqueDeChefe.Forma.CIRCULO_NO_ALVO:
			pontos.append(alvo_no_chao)
		AtaqueDeChefe.Forma.CHUVA_EM_VOLTA_DO_ALVO:
			# O primeiro círculo cai em cima do alvo, para a chuva sempre obrigar alguém a
			# sair do lugar. Os outros se espalham por igual dentro do raio.
			pontos.append(alvo_no_chao)
			for _indice in maxi(ataque.quantidade, 1) - 1:
				var angulo: float = randf() * TAU
				var distancia: float = sqrt(randf()) * ataque.espalhamento
				pontos.append(alvo_no_chao + Vector3(cos(angulo), 0.0, sin(angulo)) * distancia)
	return pontos

## Cria uma marca por ponto. As marcas ficam no pai do chefe, e não nele, para não
## andarem nem tremerem junto com ele. Com com_dano falso a marca é só o desenho (é o
## caso do fantoche).
func _criar_avisos(ataque: AtaqueDeChefe, pontos: Array[Vector3], giro: float, com_dano: bool) -> void:
	var pai: Node = get_parent()
	for ponto in pontos:
		var aviso: AvisoDeAtaque
		if ataque.forma == AtaqueDeChefe.Forma.FAIXA_NA_DIRECAO_DO_ALVO:
			aviso = AvisoDeAtaque.criar_faixa(pai, ponto, giro, ataque.comprimento, ataque.raio, ataque.segundos_de_aviso, ataque.cor)
		else:
			aviso = AvisoDeAtaque.criar_circulo(pai, ponto, ataque.raio, ataque.segundos_de_aviso, ataque.cor)
		aviso.finished.connect(_ao_terminar_o_aviso.bind(aviso, ataque, com_dano))
		_avisos.append(aviso)

## A marca terminou: é a hora em que o ataque acerta. O efeito visual sai nos dois lados
## (anfitrião e fantoche); o dano, só no jogo que manda no chefe.
func _ao_terminar_o_aviso(aviso: AvisoDeAtaque, ataque: AtaqueDeChefe, com_dano: bool) -> void:
	_avisos.erase(aviso)
	EventBus.boss_attack_landed.emit(aviso.centro(), aviso.raio_visual(), ataque.cor)
	if not com_dano:
		return
	for jogador in _jogadores_na_luta():
		if not is_instance_valid(jogador) or not jogador.has_method(&"receber_dano"):
			continue
		if aviso.contem(jogador.global_position):
			# No fantoche de outro jogador isto só pisca e avisa a Dungeon, que manda o
			# dano pela rede para o jogo dele.
			jogador.call(&"receber_dano", ataque.dano, self)

## Quem pode ser acertado. Na dungeon são os jogadores presentes; fora dela (uma cena de
## teste), quem estiver no grupo de alvos dos inimigos.
func _jogadores_na_luta() -> Array[Node3D]:
	if _dungeon != null:
		return _dungeon.jogadores_presentes()
	var lista: Array[Node3D] = []
	for no in get_tree().get_nodes_in_group(GRUPO_DE_ALVOS):
		var jogador: Node3D = no as Node3D
		if jogador != null:
			lista.append(jogador)
	return lista

func _cancelar_avisos() -> void:
	for aviso in _avisos:
		if is_instance_valid(aviso):
			aviso.cancelar()
	_avisos.clear()

# Queda

## Chefe que cai no meio de um aviso leva as marcas junto: o ataque não chega a acertar.
## O resto da queda (experiência, saque, sumir) é o do Inimigo.
func _morrer() -> void:
	if _perfil_de_chefe != null:
		_cancelar_avisos()
		_segundos_caindo = 0.0
		EventBus.boss_defeated.emit(self)
	super._morrer()

# Rede

## O estado do Inimigo com a vida máxima no fim da lista, para a barra de vida do
## convidado bater com a do anfitrião. O inimigo comum não lê essa posição.
func estado_para_a_rede() -> Array:
	var dados: Array = super.estado_para_a_rede()
	dados.append(vida_maxima_efetiva)
	return dados

func aplicar_estado_da_rede(dados: Array) -> void:
	super.aplicar_estado_da_rede(dados)
	if dados.size() > 7:
		vida_maxima_efetiva = int(dados[7])

## As posições das marcas vão relativas à dungeon, como a posição dos inimigos, e só com
## x e z: a altura cada jogo tira do chão do próprio chefe.
func _enviar_aviso_pela_rede(ataque: AtaqueDeChefe, pontos: Array[Vector3], giro: float) -> void:
	if _dungeon == null:
		return
	var pontos_para_a_rede: Array = []
	for ponto in pontos:
		var na_dungeon: Vector3 = _dungeon.to_local(ponto)
		pontos_para_a_rede.append([snappedf(na_dungeon.x, 0.01), snappedf(na_dungeon.z, 0.01)])
	_dungeon.enviar_evento(TIPO_DO_AVISO_NA_REDE, {
		"chefe": numero_na_rede,
		"ataque": _perfil_de_chefe.ataques.find(ataque),
		"pontos": pontos_para_a_rede,
		"giro": snappedf(giro, 0.01),
	})

## Só o fantoche escuta. A dungeon pode ter mais de um chefe (o subchefe e o final), e
## cada evento diz de qual é pelo número na rede.
func _ao_receber_evento(_de: String, tipo: String, campos: Dictionary) -> void:
	if tipo != TIPO_DO_AVISO_NA_REDE and tipo != TIPO_DA_FASE_NA_REDE:
		return
	if int(campos.get("chefe", -1)) != numero_na_rede or estado == Estado.MORRENDO:
		return
	if tipo == TIPO_DA_FASE_NA_REDE:
		_entrar_na_fase(int(campos.get("fase", 2)))
		return
	_mostrar_aviso_da_rede(campos)

## Desenha no fantoche as mesmas marcas que o anfitrião criou, sem dano.
func _mostrar_aviso_da_rede(campos: Dictionary) -> void:
	var indice: int = int(campos.get("ataque", -1))
	if indice < 0 or indice >= _perfil_de_chefe.ataques.size():
		return
	var ataque: AtaqueDeChefe = _perfil_de_chefe.ataques[indice]
	if ataque == null:
		return
	var pontos: Array[Vector3] = []
	var pontos_da_rede: Array = campos.get("pontos", [])
	for par: Array in pontos_da_rede:
		var no_mundo: Vector3 = _dungeon.to_global(Vector3(float(par[0]), 0.0, float(par[1])))
		no_mundo.y = global_position.y
		pontos.append(no_mundo)
	_criar_avisos(ataque, pontos, float(campos.get("giro", 0.0)), false)
	_segundos_tremendo = ataque.segundos_de_aviso

# Animação por código

## O chefe não tem clipes, então a vida dele vem daqui: balança de leve parado, inclina
## para a frente andando e treme enquanto anuncia um ataque. Só a posição e os giros em X
## e Z do modelo são mexidos; o giro em Y continua sendo do Inimigo, que é para onde o
## chefe olha.
func _animar_por_codigo(delta: float) -> void:
	_relogio_da_animacao += delta
	var escala: float = _perfil_de_chefe.escala
	# A velocidade sai de quanto o corpo andou no quadro, e não de velocity, porque o
	# fantoche é movido pela rede e a velocity dele fica sempre zerada.
	var andado: float = _distancia_horizontal(global_position, _posicao_no_quadro_anterior)
	_posicao_no_quadro_anterior = global_position
	var quanto_anda: float = clampf((andado / delta) / maxf(perfil.velocidade, 0.1), 0.0, 1.0)
	_inclinacao = lerpf(_inclinacao, INCLINACAO_ANDANDO * quanto_anda, minf(SUAVIDADE_DA_INCLINACAO * delta, 1.0))
	var onda: float = sin(_relogio_da_animacao * VELOCIDADE_DO_BALANCO)
	_modelo.rotation.x = _inclinacao
	_modelo.rotation.z = onda * ANGULO_DO_BALANCO * (1.0 - quanto_anda)
	# A onda sobe a partir do chão (de zero ao dobro da altura), para o modelo não entrar
	# no piso na parte de baixo do balanço.
	var deslocamento: Vector3 = Vector3(0.0, (onda + 1.0) * ALTURA_DO_BALANCO * escala, 0.0)
	if _segundos_tremendo > 0.0:
		deslocamento += _tremor(FORCA_DO_TREMOR * escala)
	_modelo.position = deslocamento

## A queda de uma máquina: treme, tomba para a frente, afunda no chão e encolhe até sumir.
## Dura o mesmo tempo que o Inimigo espera antes de tirar o corpo. Sem vermelho nenhum.
func _animar_queda(delta: float) -> void:
	_segundos_caindo += delta
	var escala: float = _perfil_de_chefe.escala
	var fracao: float = clampf(_segundos_caindo / DURACAO_DA_QUEDA_SEM_ANIMACAO, 0.0, 1.0)
	_modelo.scale = Vector3.ONE * escala * lerpf(1.0, TAMANHO_NO_FIM_DA_QUEDA, fracao)
	_modelo.rotation.x = lerpf(_inclinacao, INCLINACAO_NA_QUEDA, fracao)
	var deslocamento: Vector3 = _tremor(FORCA_DO_TREMOR_NA_QUEDA * escala * (1.0 - fracao))
	deslocamento.y = -AFUNDAMENTO_NA_QUEDA * escala * fracao
	_modelo.position = deslocamento

## Um pequeno deslocamento ao acaso no plano do chão, sorteado de novo a cada quadro.
func _tremor(forca: float) -> Vector3:
	return Vector3(randf_range(-forca, forca), 0.0, randf_range(-forca, forca))
