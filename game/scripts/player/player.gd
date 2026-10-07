extends CharacterBody3D

@export var velocidade_andar: float = 3.0
@export var velocidade_correr: float = 6.0
@export var velocidade_rotacao: float = 10.0
@export var velocidade_dash: float = 12.0
@export var duracao_dash: float = 0.2
@export var cooldown_dash: float = 0.8
@export var velocidade_ataque: float = 1.6
@export var folga_pos_golpe: float = 0.1
@export var janela_combo_ataque: float = 0.6
@export var cooldown_ataque: float = 0.3
## Fração do golpe a partir da qual o dash já pode sair, cortando o resto da animação.
## É o ponto em que o golpe termina de acertar: dali em diante é só recuperação, e
## poder sair dela com um dash deixa o jogador responder a um ataque rápido.
@export_range(0.0, 1.0) var fracao_do_golpe_que_libera_o_dash: float = 0.65
@export var gravidade: float = 24.0
@export var altura_degrau: float = 0.4
## O que ataca quando não há arma na mão: slot vazio, ou item que não é arma nem tem uso
## próprio. É uma Arma como as outras, só que não mora no inventário.
@export var punho: Arma
@export var som_de_batida_na_parede: AudioStream
@export var volume_batida_na_parede_db: float = -15.0

const CLIPES_COMBO_ATAQUE: Array[String] = ["attack-melee-left", "attack-melee-left", "attack-melee-right"]
const CLIPES_INTERACAO: Array[String] = ["interact-left", "interact-right"]
const CLIPE_DE_QUEDA: String = "die"
const CLIPE_DE_GOLPE_DE_ARMA: String = "attack-melee-right"
const CLIPE_DE_DISPARO: String = "holding-both-shoot"
const CLIPE_PARADO_COM_ARMA_DE_DISTANCIA: String = "holding-both"
## Altura do plano em que o mouse é projetado, a mesma de onde o tiro sai.
const ALTURA_DA_MIRA_PELO_MOUSE: float = 0.3
## Com o mouse em cima do personagem o ângulo fica instável, então a mira não muda.
const DISTANCIA_MINIMA_DA_MIRA_PELO_MOUSE: float = 0.3

@export var caminho_grade_solo: NodePath = ^"../GradeSolo"
@export var caminho_indicador_alvo: NodePath = ^"../IndicadorAlvo"
## Onde o jogador acorda depois de desmaiar. É a casa dele.
@export var caminho_ponto_de_spawn: NodePath = ^"../PontoDeSpawn"

@onready var personagem: Node3D = $Personagem
@onready var animation_player: AnimationPlayer = $Personagem/AnimationPlayer
@onready var grade_solo: GradeSolo = get_node_or_null(caminho_grade_solo)
@onready var indicador_alvo: MeshInstance3D = get_node_or_null(caminho_indicador_alvo)
@onready var area_interacao: AreaDeInteracao = $AreaInteracao
@onready var ataque: AtaqueDoJogador = $AtaqueDoJogador
@onready var reacao_a_dano: ReacaoADano = $ReacaoADano

var _tempo_dash_restante: float = 0.0
var _tempo_cooldown_restante: float = 0.0
var _direcao_dash: Vector3 = Vector3.ZERO

var _indice_combo: int = 0
var _indice_interacao: int = 0
var _tempo_ataque_restante: float = 0.0
var _tempo_movimento_travado_ataque_restante: float = 0.0
var _tempo_janela_combo_restante: float = 0.0
var _tempo_cooldown_ataque_restante: float = 0.0
var _duracao_do_golpe_atual: float = 0.0
## Plantado no lugar, a mira está seguindo o mouse em vez das teclas de direção.
var _mirando_pelo_mouse: bool = false

## Entre cair e acordar o jogador não responde a nenhum comando.
var _desmaiado: bool = false

func _ready() -> void:
	# Os inimigos acham o jogador por este grupo, sem depender do caminho na cena.
	add_to_group(&"jogador")
	# Os inimigos escolhem o alvo mais perto neste grupo, onde também entram os fantoches
	# dos outros jogadores na dungeon em equipe.
	add_to_group(&"alvos_de_inimigo")
	StatusManager.player_fainted.connect(_ao_desmaiar)
	StatusManager.player_woke_up.connect(_ao_acordar)
	# O modelo na mão acompanha o item na mão, que muda ao trocar de slot e também ao
	# mexer no inventário (o item do slot selecionado pode ter saído de lá).
	EquipmentManager.slot_selecionado_alterado.connect(_ao_mudar_item_na_mao.unbind(1))
	InventoryManager.inventory_changed.connect(_ao_mudar_item_na_mao)
	_ao_mudar_item_na_mao()

func _physics_process(delta: float) -> void:
	if _desmaiado:
		_cair_parado(delta)
		return

	_tempo_cooldown_restante = max(_tempo_cooldown_restante - delta, 0.0)
	_tempo_ataque_restante = max(_tempo_ataque_restante - delta, 0.0)
	_tempo_movimento_travado_ataque_restante = max(_tempo_movimento_travado_ataque_restante - delta, 0.0)
	_tempo_janela_combo_restante = max(_tempo_janela_combo_restante - delta, 0.0)
	_tempo_cooldown_ataque_restante = max(_tempo_cooldown_ataque_restante - delta, 0.0)

	var slot_pedido: int = InputManager.slot_numerico_pressionado()
	if slot_pedido != -1:
		EquipmentManager.selecionar(slot_pedido)
	elif InputManager.slot_proximo_pressionado():
		EquipmentManager.ciclar(1)
	elif InputManager.slot_anterior_pressionado():
		EquipmentManager.ciclar(-1)

	if _tempo_janela_combo_restante <= 0.0:
		_indice_combo = 0

	var ferramenta_equipada: Ferramenta = EquipmentManager.ferramenta_na_mao()
	var semente_na_mao: Semente = EquipmentManager.item_na_mao() as Semente

	var celula_alvo: Vector2i
	var tem_planta_madura_no_alvo: bool = false
	if grade_solo != null:
		celula_alvo = grade_solo.obter_celula_alvo(global_position, personagem.rotation.y)
		tem_planta_madura_no_alvo = grade_solo.esta_madura(celula_alvo)
	# O indicador aparece quando apertar um botão pode fazer algo na célula à frente:
	# usar ferramenta, plantar semente ou colher planta madura.
	var tem_celula_alvo: bool = grade_solo != null and (ferramenta_equipada != null or semente_na_mao != null or tem_planta_madura_no_alvo)

	if indicador_alvo != null:
		indicador_alvo.visible = tem_celula_alvo and grade_solo.limite.has_point(celula_alvo)
		if indicador_alvo.visible:
			var posicao_local: Vector3 = grade_solo.map_to_local(Vector3i(celula_alvo.x, 0, celula_alvo.y))
			indicador_alvo.global_position = grade_solo.global_transform * posicao_local
			indicador_alvo.global_position.y += 0.01

	if _tempo_dash_restante <= 0.0 and _dash_liberado_pelo_golpe() and _tempo_cooldown_restante <= 0.0 and InputManager.dash_pressionado():
		# O dash vai para onde o direcional aponta, e só usa a frente do personagem
		# quando não há direção. Depois de um golpe o personagem está virado para o
		# alvo, e é justamente dele que o jogador quer se afastar.
		var entrada_do_dash: Vector2 = InputManager.obter_direcao_movimento()
		if entrada_do_dash != Vector2.ZERO:
			_direcao_dash = Vector3(entrada_do_dash.x, 0.0, entrada_do_dash.y).normalized()
			personagem.rotation.y = atan2(_direcao_dash.x, _direcao_dash.z)
		else:
			_direcao_dash = Vector3(sin(personagem.rotation.y), 0.0, cos(personagem.rotation.y))
		# O dash corta a recuperação do golpe que estava em andamento.
		_tempo_ataque_restante = 0.0
		_tempo_movimento_travado_ataque_restante = 0.0
		_tempo_dash_restante = duracao_dash
		_tempo_cooldown_restante = cooldown_dash + duracao_dash
		_indice_combo = 0
		_tempo_janela_combo_restante = 0.0

	# O player não sabe se o alvo é item, NPC ou baú: só chama interagir(), e cada
	# alvo decide o que acontece. Ver AreaDeInteracao.
	if _tempo_dash_restante <= 0.0 and _tempo_movimento_travado_ataque_restante <= 0.0 and InputManager.interagir_pressionado():
		# Colher vem antes dos outros alvos porque usa a mesma célula à frente que as
		# ferramentas, e não a área de interação. Planta imatura não colhe e cai no
		# caminho normal.
		if _colher_na_celula(celula_alvo):
			_tocar_animacao_de_interacao()
		else:
			var alvo_da_interacao: Node3D = area_interacao.alvo_mais_proximo()
			if alvo_da_interacao != null:
				alvo_da_interacao.call(&"interagir")

	if _tempo_dash_restante <= 0.0 and _tempo_ataque_restante <= 0.0 and _tempo_cooldown_ataque_restante <= 0.0 and InputManager.atacar_pressionado():
		if _plantar_semente_da_mao(semente_na_mao, celula_alvo):
			_tocar_animacao_de_interacao()
		elif _comer_consumivel_da_mao():
			_tocar_animacao_de_interacao()
		elif ferramenta_equipada != null:
			if _usar_ferramenta(ferramenta_equipada, celula_alvo):
				_tocar_animacao_de_interacao()
		else:
			_atacar_com(_arma_em_uso())

	if _tempo_dash_restante > 0.0:
		_tempo_dash_restante = max(_tempo_dash_restante - delta, 0.0)

		velocity.x = _direcao_dash.x * velocidade_dash
		velocity.z = _direcao_dash.z * velocidade_dash

		_atualizar_animacao(Vector3.ZERO, false, true)
	elif _tempo_movimento_travado_ataque_restante > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var entrada: Vector2 = InputManager.obter_direcao_movimento()
		var direcao: Vector3 = Vector3(entrada.x, 0.0, entrada.y)

		if direcao != Vector3.ZERO and _indice_combo != 0:
			_indice_combo = 0
			_tempo_janela_combo_restante = 0.0

		# Com a escopeta na mão, o botão de correr planta o personagem no lugar: ele vira
		# para onde o direcional aponta, do jeito normal, mas não anda.
		var plantado: bool = _correr_planta_no_lugar()
		var esta_correndo: bool = direcao != Vector3.ZERO and InputManager.correr_pressionado() and not plantado
		var velocidade_atual: float = velocidade_correr if esta_correndo else velocidade_andar
		if plantado:
			velocidade_atual = 0.0

		velocity.x = direcao.x * velocidade_atual
		velocity.z = direcao.z * velocidade_atual

		# Plantado, no teclado e mouse, a mira segue quem foi usado por último: o mouse
		# quando ele se mexe, as teclas de direção quando uma é apertada.
		if plantado and direcao != Vector3.ZERO:
			_mirando_pelo_mouse = false
		elif plantado and InputManager.usando_teclado_e_mouse() and InputManager.mouse_se_moveu_agora():
			_mirando_pelo_mouse = true
		elif not plantado:
			_mirando_pelo_mouse = false

		if direcao != Vector3.ZERO:
			var angulo_alvo: float = atan2(direcao.x, direcao.z)
			# A arma na mão pode acelerar o giro: com a escopeta o personagem vira mais
			# rápido, para a mira acompanhar o direcional.
			var velocidade_de_giro: float = velocidade_rotacao * _arma_em_uso().multiplicador_de_giro
			personagem.rotation.y = lerp_angle(personagem.rotation.y, angulo_alvo, minf(velocidade_de_giro * delta, 1.0))
		elif _mirando_pelo_mouse:
			_virar_para_o_mouse()

		_atualizar_animacao(Vector3.ZERO if plantado else direcao, esta_correndo, false)

	# O empurrão de um golpe tira o controle por um instante e vale por cima do resto.
	if reacao_a_dano.esta_sendo_empurrado():
		var empurrao: Vector3 = reacao_a_dano.empurrao_atual()
		velocity.x = empurrao.x
		velocity.z = empurrao.z

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravidade * delta

	var velocidade_horizontal: Vector3 = velocity
	velocidade_horizontal.y = 0.0

	var estava_na_parede: bool = is_on_wall()
	move_and_slide()
	if not estava_na_parede and is_on_wall():
		AudioManager.tocar_sfx(som_de_batida_na_parede, global_position, volume_batida_na_parede_db)
	_tentar_subir_degrau(velocidade_horizontal)

## As ações de fazenda seguem a mesma regra: sem stamina para o custo a ação é
## recusada, e a stamina só é cobrada quando a ação teve efeito de verdade. Usar a
## enxada num quadrado onde ela não faz nada não custa.

func _usar_ferramenta(ferramenta: Ferramenta, celula: Vector2i) -> bool:
	if grade_solo == null or not StatusManager.tem_stamina(ferramenta.custo_de_stamina):
		return false
	if not grade_solo.aplicar(ferramenta.id_acao, celula):
		return false
	AudioManager.tocar_sfx(ferramenta.som_de_uso, global_position)
	StatusManager.ganhar_experiencia(ferramenta.experiencia_ao_usar)
	StatusManager.gastar_stamina(ferramenta.custo_de_stamina)
	return true

## Planta a semente do slot selecionado na célula à frente e gasta uma unidade dela.
## Retorna false quando não há semente na mão ou a célula não aceita plantio, e aí o
## botão de atacar segue para o soco.
func _plantar_semente_da_mao(semente: Semente, celula: Vector2i) -> bool:
	if semente == null or semente.cultivo == null or grade_solo == null:
		return false
	if not StatusManager.tem_stamina(StatusManager.custos.stamina_plantar):
		return false
	if not grade_solo.plantar(celula, semente.cultivo):
		return false
	InventoryManager.remover_do_slot(EquipmentManager.indice_selecionado, 1)
	StatusManager.ganhar_experiencia(StatusManager.custos.experiencia_plantar)
	StatusManager.gastar_stamina(StatusManager.custos.stamina_plantar)
	return true

func _colher_na_celula(celula: Vector2i) -> bool:
	if grade_solo == null or not StatusManager.tem_stamina(StatusManager.custos.stamina_colher):
		return false
	if not grade_solo.colher(celula):
		return false
	StatusManager.ganhar_experiencia(StatusManager.custos.experiencia_colher)
	StatusManager.gastar_stamina(StatusManager.custos.stamina_colher)
	return true

## Com um consumível na mão, o botão de atacar come uma unidade. Não come quando vida e
## stamina já estão cheias, para o item não ser gasto à toa.
func _comer_consumivel_da_mao() -> bool:
	var consumivel: Consumivel = EquipmentManager.item_na_mao() as Consumivel
	if consumivel == null or not StatusManager.consumir(consumivel):
		return false
	InventoryManager.remover_do_slot(EquipmentManager.indice_selecionado, 1)
	return true

func _ao_desmaiar(_motivo: StatusManager.Motivo) -> void:
	_desmaiado = true
	_tempo_dash_restante = 0.0
	_indice_combo = 0
	if indicador_alvo != null:
		indicador_alvo.visible = false
	animation_player.play(CLIPE_DE_QUEDA)

## Acorda em casa, de pé. Sem o ponto de spawn na cena, acorda onde caiu.
func _ao_acordar(_motivo: StatusManager.Motivo) -> void:
	var ponto_de_spawn: Node3D = get_node_or_null(caminho_ponto_de_spawn) as Node3D
	if ponto_de_spawn != null:
		global_position = ponto_de_spawn.global_position
	velocity = Vector3.ZERO
	_desmaiado = false
	animation_player.play("idle")

## Caído, o jogador só obedece à gravidade, para não ficar flutuando se cair no ar.
func _cair_parado(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravidade * delta
	move_and_slide()

## Contrato de dano do jogo, o mesmo dos inimigos. A vida mora no StatusManager; aqui
## fica a reação física: empurrão, piscada, invencibilidade curta e sacudida da câmera.
func receber_dano(quantidade: int, origem: Node3D) -> void:
	if _desmaiado or not reacao_a_dano.pode_levar_dano():
		return
	var posicao_de_quem_bateu: Vector3 = origem.global_position if origem != null else global_position
	reacao_a_dano.reagir(posicao_de_quem_bateu)
	StatusManager.receber_dano(quantidade, origem)
	EventBus.damage_dealt.emit(self, quantidade)
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera != null and camera.has_method(&"sacudir"):
		camera.call(&"sacudir")

## Sem golpe em andamento o dash está sempre liberado. Durante um golpe, só depois que
## ele terminou de acertar.
func _dash_liberado_pelo_golpe() -> bool:
	if _tempo_movimento_travado_ataque_restante <= 0.0:
		return true
	if _duracao_do_golpe_atual <= 0.0:
		return false
	var decorrido: float = _duracao_do_golpe_atual - _tempo_ataque_restante
	return decorrido >= _duracao_do_golpe_atual * fracao_do_golpe_que_libera_o_dash

## Vira o personagem para o ponto do chão que está embaixo do mouse. O ponto vem de um
## raio da câmera até o plano horizontal na altura do tiro, e não até o chão de verdade,
## para a mira não pular quando o mouse passa por cima de um telhado.
func _virar_para_o_mouse() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var mouse: Vector2 = InputManager.posicao_do_mouse()
	var origem: Vector3 = camera.project_ray_origin(mouse)
	var sentido: Vector3 = camera.project_ray_normal(mouse)
	if is_zero_approx(sentido.y):
		return
	var altura_do_plano: float = global_position.y + ALTURA_DA_MIRA_PELO_MOUSE
	var distancia: float = (altura_do_plano - origem.y) / sentido.y
	if distancia <= 0.0:
		return
	var ponto: Vector3 = origem + sentido * distancia
	var para_o_ponto: Vector3 = ponto - global_position
	if Vector2(para_o_ponto.x, para_o_ponto.z).length() < DISTANCIA_MINIMA_DA_MIRA_PELO_MOUSE:
		return
	personagem.rotation.y = atan2(para_o_ponto.x, para_o_ponto.z)

## Vale quando a arma na mão pede isso e o botão de correr está segurado. Com qualquer
## outro item, o botão de correr continua sendo correr.
func _correr_planta_no_lugar() -> bool:
	var arma: Arma = _arma_em_uso()
	return arma != null and arma.correr_planta_no_lugar and InputManager.correr_pressionado()

## A arma na mão, ou o punho quando o item na mão não é arma.
func _arma_em_uso() -> Arma:
	var arma_na_mao: Arma = EquipmentManager.item_na_mao() as Arma
	return arma_na_mao if arma_na_mao != null else punho

## Um caminho só para todo golpe. O que muda entre os tipos de arma é o clipe, a
## velocidade dele e se o golpe acerta por área ou dispara um projétil. O golpe em si
## não gasta stamina: ela só é cobrada quando acerta um oponente, e quem cobra é o
## AtaqueDoJogador (ou o projétil).
func _atacar_com(arma: Arma) -> void:
	if arma == null:
		return
	AudioManager.tocar_sfx(arma.som_do_golpe, global_position)

	if arma.tipo == Arma.Tipo.DISTANCIA:
		_travar_movimento_pela_animacao(CLIPE_DE_DISPARO, arma.velocidade_da_animacao)
		ataque.disparar(arma)
		_tempo_cooldown_ataque_restante = arma.cooldown
		return

	if arma.tipo == Arma.Tipo.PUNHO:
		# Só o punho tem combo: três golpes em sequência, com uma pausa no fim.
		var duracao: float = _travar_movimento_pela_animacao(CLIPES_COMBO_ATAQUE[_indice_combo], arma.velocidade_da_animacao)
		ataque.executar_golpe(arma, duracao)
		_tempo_janela_combo_restante = janela_combo_ataque
		_indice_combo += 1
		if _indice_combo >= CLIPES_COMBO_ATAQUE.size():
			_indice_combo = 0
			_tempo_cooldown_ataque_restante = cooldown_ataque
			_tempo_janela_combo_restante = 0.0
		return

	# Arma leve e pesada dão um golpe por vez. A pesada usa o mesmo clipe, mais lento.
	var duracao_do_golpe: float = _travar_movimento_pela_animacao(CLIPE_DE_GOLPE_DE_ARMA, arma.velocidade_da_animacao)
	ataque.executar_golpe(arma, duracao_do_golpe)
	_tempo_cooldown_ataque_restante = arma.cooldown

func _ao_mudar_item_na_mao() -> void:
	ataque.trocar_modelo(EquipmentManager.item_na_mao() as Arma)

func _tocar_animacao_de_interacao() -> void:
	var nome_clipe_interacao: String = CLIPES_INTERACAO[_indice_interacao]
	_travar_movimento_pela_animacao(nome_clipe_interacao)
	_indice_interacao = (_indice_interacao + 1) % CLIPES_INTERACAO.size()

## Toca o clipe e trava o movimento até ele acabar. Devolve a duração real do clipe, já
## dividida pela velocidade. Sem velocidade informada, usa a das ferramentas.
func _travar_movimento_pela_animacao(nome_clipe: String, velocidade: float = 0.0) -> float:
	# A ação que zerou a stamina já derrubou o jogador: a animação dela não pode tocar
	# por cima da queda.
	if _desmaiado:
		return 0.0
	if velocidade <= 0.0:
		velocidade = velocidade_ataque
	animation_player.play(nome_clipe, -1.0, velocidade)

	var duracao_clipe: float = animation_player.get_animation(nome_clipe).length / velocidade
	_duracao_do_golpe_atual = duracao_clipe
	_tempo_ataque_restante = duracao_clipe
	_tempo_movimento_travado_ataque_restante = duracao_clipe + folga_pos_golpe
	return duracao_clipe

func _atualizar_animacao(direcao: Vector3, esta_correndo: bool, esta_dando_dash: bool) -> void:
	# O quadro em que o jogador cai ainda passa pelo código de movimento, que voltaria
	# para a animação parada por cima da queda.
	if _desmaiado:
		return
	var animacao_alvo: String = "idle"
	# Parado com arma de distância na mão, o personagem segura a arma com as duas mãos.
	# Andando continua o clipe normal, porque não existe clipe de andar armado.
	if _arma_em_uso() != null and _arma_em_uso().tipo == Arma.Tipo.DISTANCIA:
		animacao_alvo = CLIPE_PARADO_COM_ARMA_DE_DISTANCIA
	if esta_dando_dash:
		animacao_alvo = "jump"
	elif direcao != Vector3.ZERO:
		animacao_alvo = "sprint" if esta_correndo else "walk"

	if animation_player.current_animation != animacao_alvo:
		animation_player.play(animacao_alvo)

func _tentar_subir_degrau(dir_plana_esperada: Vector3) -> void:
	## Permite subir degraus e rampas baixas (escadinha da ponte, beira de calçada)
	## sem precisar pular. Só tenta quando o player está encostado numa parede e
	## se movendo horizontalmente.
	if not is_on_wall():
		return
	var dir_plana: Vector3 = dir_plana_esperada
	if dir_plana.length() < 0.1:
		return
	dir_plana = dir_plana.normalized()

	var espaco: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var melhor_alvo: float = -1.0

	## Testa em três distâncias à frente para não perder o topo do degrau
	## quando o raio cai exatamente na face vertical da escada.
	for dist: float in [0.2, 0.4, 0.6]:
		var inicio: Vector3 = global_position + dir_plana * dist + Vector3.UP * (altura_degrau + 0.1)
		var fim: Vector3 = global_position + dir_plana * dist + Vector3.DOWN * 0.1
		var params := PhysicsRayQueryParameters3D.create(inicio, fim, collision_mask)
		params.exclude = [get_rid()]
		var resultado: Dictionary = espaco.intersect_ray(params)
		if resultado.is_empty():
			continue
		
		# Só sobe se a superfície for um chão (inclinação menor que 45 graus)
		var normal: Vector3 = resultado.get("normal", Vector3.UP)
		if normal.angle_to(Vector3.UP) > deg_to_rad(45.0):
			continue

		var alvo: float = resultado.position.y
		## Só considera se o alvo está acima do player e dentro da altura máxima
		if alvo > global_position.y + 0.02 and alvo <= global_position.y + altura_degrau:
			if alvo > melhor_alvo:
				melhor_alvo = alvo

	if melhor_alvo < 0.0:
		return

	## Teleporta para o topo do degrau e zera velocity.y para que a gravidade
	## acumulada não desfaça imediatamente a subida no próximo move_and_slide().
	global_position.y = melhor_alvo + 0.02
	velocity.y = maxf(velocity.y, 0.0)
