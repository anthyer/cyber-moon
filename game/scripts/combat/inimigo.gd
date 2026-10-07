class_name Inimigo
extends CharacterBody3D

## Um inimigo corpo a corpo. A cena e este script servem para todos os tipos: o que muda
## entre o drone, o ciborgue e a sentinela vem do PerfilInimigo.
##
## O comportamento é uma máquina de quatro estados num match, sem um nó por estado,
## porque para quatro estados isso é mais cerimônia que ajuda:
##
##   OCIOSO      -> jogador entrou no raio de percepção     -> PERSEGUINDO
##   PERSEGUINDO -> jogador saiu do raio de desistência     -> OCIOSO
##   PERSEGUINDO -> jogador ao alcance do ataque            -> ATACANDO
##   ATACANDO    -> golpe e intervalo terminaram            -> PERSEGUINDO
##   qualquer    -> vida chegou a zero                      -> MORRENDO
##
## Persegue pela malha de navegação da fase, contornando obstáculo (plano 14). Na dungeon
## em equipe ele pode ser fantoche do inimigo do anfitrião (plano 22); veja a parte de
## rede no fim do script.
##
## Na cena, o inimigo (e o jogador) só aceitam a camada mundo como chão de plataforma
## (platform_floor_layers = 1). Sem isso, quando um personagem encosta no outro, a
## cápsula de um sobe na do outro, a física trata quem está andando como plataforma em
## movimento e arremessa quem está em cima.

## Emitido quando o inimigo cai, antes de sumir. A dungeon usa para avisar os outros jogos.
signal defeated(inimigo: Inimigo)
## Só no modo fantoche: este jogo acertou o inimigo, e quem tira a vida é o anfitrião.
signal puppet_hit(numero_na_rede: int, quantidade: int)

enum Estado { OCIOSO, PERSEGUINDO, ATACANDO, MORRENDO }

## O golpe acerta numa fração da duração do clipe, a mesma técnica do ataque do jogador:
## as animações vêm prontas no .glb e não aceitam marcação de quadro.
const INICIO_DA_JANELA_DE_ACERTO: float = 0.35
const FIM_DA_JANELA_DE_ACERTO: float = 0.65
const ALTURA_DO_GOLPE: float = 0.3
const DISTANCIA_DA_BOCA_DO_TIRO: float = 0.4
const CAMADA_MUNDO: int = 1

const RAIO_DO_CIRCULO_OCIOSO: float = 2.0
const VELOCIDADE_DO_GIRO_PARADO: float = 0.6
## No ócio o inimigo anda mais devagar que perseguindo, para a mudança de estado ficar
## visível.
const FRACAO_DA_VELOCIDADE_NO_OCIO: float = 0.45
const DISTANCIA_PARA_CHEGAR_NO_PONTO: float = 0.3
## O caminho pela malha só é refeito quando o alvo andou mais que isto, para não recalcular
## a cada quadro atrás de um jogador que se mexe.
const DISTANCIA_PARA_REFAZER_O_CAMINHO: float = 0.5
## Se não houver ponto de patrulha, o inimigo patrulha até este deslocamento a partir de
## onde nasceu.
const GRUPO_DE_ALVOS: StringName = &"alvos_de_inimigo"
## De quanto em quanto tempo ele reconsidera quem é o jogador mais perto.
const SEGUNDOS_ENTRE_ESCOLHAS_DE_ALVO: float = 0.3
## O fantoche segue a posição que chega pela rede com esta suavidade, porque as
## mensagens vêm umas 10 vezes por segundo e sem isso ele andaria aos pulos.
const SUAVIDADE_DO_FANTOCHE: float = 12.0
const PATRULHA_PADRAO: Vector3 = Vector3(4.0, 0.0, 0.0)

@export var perfil: PerfilInimigo
## Segundo ponto da patrulha. O primeiro é onde o inimigo nasceu.
@export var caminho_do_ponto_de_patrulha: NodePath
## Na dungeon em equipe, o inimigo é de verdade só no jogo do anfitrião. Nos outros ele é
## fantoche: não pensa, só mostra o que o anfitrião manda e repassa o golpe que leva.
var fantoche: bool = false
## O número deste inimigo na dungeon, igual em todos os jogos. É como as mensagens da
## rede dizem de qual inimigo estão falando.
var numero_na_rede: int = -1

@export var gravidade: float = 24.0
@export var velocidade_de_giro: float = 8.0

@onready var _reacao: ReacaoADano = $ReacaoADano
@onready var _agente: NavigationAgent3D = $Agente
@onready var _hitbox: Area3D = $HitboxAtaque
@onready var _forma_da_hitbox: CollisionShape3D = $HitboxAtaque/FormaHitbox

var estado: Estado = Estado.OCIOSO
var vida_atual: int = 0

var _modelo: Node3D
var _animacao: AnimationPlayer
var _jogador: Node3D

var _ponto_de_origem: Vector3
var _ponto_de_patrulha: Vector3
var _indo_para_a_patrulha: bool = true
var _angulo_do_circulo: float = 0.0

var _tempo_do_golpe: float = 0.0
var _duracao_do_golpe: float = 0.0
var _golpe_ja_acertou: bool = false
var _tempo_ate_poder_atacar: float = 0.0
var _segundos_ate_escolher_alvo: float = 0.0
## Modo fantoche: para onde ir e para onde olhar, conforme a última mensagem.
var _posicao_da_rede: Vector3
var _giro_da_rede: float = 0.0

func _ready() -> void:
	_ponto_de_origem = global_position
	_ponto_de_patrulha = _ponto_de_origem + PATRULHA_PADRAO
	var marcador: Node3D = get_node_or_null(caminho_do_ponto_de_patrulha) as Node3D
	if marcador != null:
		_ponto_de_patrulha = marcador.global_position
	_angulo_do_circulo = randf() * TAU
	if perfil == null:
		push_warning("Inimigo sem perfil: %s" % name)
		return
	vida_atual = perfil.vida_maxima
	_posicao_da_rede = position
	_montar_modelo()
	_reacao.ligar_modelo(_modelo)

func _physics_process(delta: float) -> void:
	if perfil == null or estado == Estado.MORRENDO:
		_aplicar_gravidade(delta)
		move_and_slide()
		return
	if fantoche:
		_seguir_a_rede(delta)
		return
	_procurar_jogador(delta)
	_tempo_ate_poder_atacar = maxf(_tempo_ate_poder_atacar - delta, 0.0)

	match estado:
		Estado.OCIOSO:
			_processar_ocio(delta)
		Estado.PERSEGUINDO:
			_processar_perseguicao(delta)
		Estado.ATACANDO:
			_processar_ataque(delta)

	# O empurrão do dano tira o controle por um instante: soma por cima de tudo.
	if _reacao.esta_sendo_empurrado():
		var empurrao: Vector3 = _reacao.empurrao_atual()
		velocity.x = empurrao.x
		velocity.z = empurrao.z
	_aplicar_gravidade(delta)
	move_and_slide()

## Contrato de dano do jogo. A origem é quem bateu, e serve para empurrar o inimigo
## para longe dela. Durante a invencibilidade curta o dano é ignorado, para um golpe não
## contar várias vezes.
func receber_dano(quantidade: int, origem: Node3D) -> void:
	if estado == Estado.MORRENDO or not _reacao.pode_levar_dano():
		return
	if fantoche:
		# O clarão aparece na hora, para o golpe ter resposta; a vida quem tira é o
		# anfitrião, e a nova vida volta na próxima mensagem dele.
		_reacao.reagir(origem.global_position if origem != null else global_position)
		puppet_hit.emit(numero_na_rede, quantidade)
		return
	vida_atual = maxi(vida_atual - quantidade, 0)
	var posicao_de_quem_bateu: Vector3 = origem.global_position if origem != null else global_position
	_reacao.reagir(posicao_de_quem_bateu)
	EventBus.damage_dealt.emit(self, quantidade)
	if vida_atual <= 0:
		_morrer()
	elif estado == Estado.OCIOSO:
		# Apanhar de longe acorda o inimigo, mesmo fora do raio de percepção.
		estado = Estado.PERSEGUINDO

func esta_vivo() -> bool:
	return estado != Estado.MORRENDO

func _processar_ocio(delta: float) -> void:
	if _jogador != null and _distancia_ate(_jogador) <= perfil.raio_de_percepcao:
		estado = Estado.PERSEGUINDO
		return
	var velocidade_no_ocio: float = perfil.velocidade * FRACAO_DA_VELOCIDADE_NO_OCIO
	match perfil.comportamento_ocioso:
		PerfilInimigo.ComportamentoOcioso.CIRCULO:
			_angulo_do_circulo += velocidade_no_ocio / RAIO_DO_CIRCULO_OCIOSO * delta
			var alvo: Vector3 = _ponto_de_origem + Vector3(cos(_angulo_do_circulo), 0.0, sin(_angulo_do_circulo)) * RAIO_DO_CIRCULO_OCIOSO
			# O círculo é curto e em área aberta: vai em linha reta, sem a malha.
			_andar_ate(alvo, velocidade_no_ocio, delta, false)
		PerfilInimigo.ComportamentoOcioso.PATRULHA:
			var destino: Vector3 = _ponto_de_patrulha if _indo_para_a_patrulha else _ponto_de_origem
			if _distancia_horizontal(global_position, destino) <= DISTANCIA_PARA_CHEGAR_NO_PONTO:
				_indo_para_a_patrulha = not _indo_para_a_patrulha
			_andar_ate(destino, velocidade_no_ocio, delta)
		PerfilInimigo.ComportamentoOcioso.PARADO:
			velocity.x = 0.0
			velocity.z = 0.0
			_modelo.rotation.y += VELOCIDADE_DO_GIRO_PARADO * delta
			_tocar(&"idle")

func _processar_perseguicao(delta: float) -> void:
	if _jogador == null or _distancia_ate(_jogador) > perfil.raio_de_desistencia:
		estado = Estado.OCIOSO
		return
	if _distancia_ate(_jogador) <= perfil.alcance_de_ataque:
		velocity.x = 0.0
		velocity.z = 0.0
		_virar_para(_jogador.global_position, delta)
		if _tempo_ate_poder_atacar <= 0.0:
			_comecar_golpe()
		else:
			_tocar(&"idle")
		return
	_andar_ate(_jogador.global_position, perfil.velocidade, delta)

func _comecar_golpe() -> void:
	estado = Estado.ATACANDO
	_animacao.play(perfil.animacao_de_ataque, -1.0, perfil.velocidade_da_animacao_de_ataque)
	_duracao_do_golpe = _animacao.get_animation(perfil.animacao_de_ataque).length / perfil.velocidade_da_animacao_de_ataque
	_tempo_do_golpe = 0.0
	_golpe_ja_acertou = false
	# O golpe sai virado para o jogador. Sem isso, o giro suave ainda não terminou quando
	# o golpe começa, e a área de acerto nasce para o lado errado.
	var para_o_jogador: Vector3 = _jogador.global_position - global_position
	_modelo.rotation.y = atan2(para_o_jogador.x, para_o_jogador.z)
	# A área de acerto vai do inimigo até o alcance do ataque, na direção em que ele olha.
	var direcao: Vector3 = _direcao_do_modelo()
	(_forma_da_hitbox.shape as SphereShape3D).radius = perfil.alcance_de_ataque * 0.5
	_hitbox.position = direcao * perfil.alcance_de_ataque * 0.5 + Vector3.UP * ALTURA_DO_GOLPE

## Parado no lugar enquanto o golpe toca. Na janela de acerto, um contato com o jogador
## tira vida dele, uma vez por golpe.
func _processar_ataque(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_tempo_do_golpe += delta
	var dentro_da_janela: bool = _tempo_do_golpe >= _duracao_do_golpe * INICIO_DA_JANELA_DE_ACERTO and _tempo_do_golpe <= _duracao_do_golpe * FIM_DA_JANELA_DE_ACERTO
	if dentro_da_janela and not _golpe_ja_acertou and perfil.projetil != null:
		_disparar()
		_golpe_ja_acertou = true
	elif dentro_da_janela and not _golpe_ja_acertou:
		for corpo in _hitbox.get_overlapping_bodies():
			if corpo.has_method(&"receber_dano"):
				corpo.call(&"receber_dano", perfil.dano, self)
				_golpe_ja_acertou = true
				break
	if _tempo_do_golpe >= _duracao_do_golpe:
		_tempo_ate_poder_atacar = perfil.intervalo_entre_ataques
		estado = Estado.PERSEGUINDO

## Solta os projéteis do perfil na direção em que o inimigo olha, abertos em leque por
## igual quando são vários, como a escopeta do jogador.
func _disparar() -> void:
	var centro: Vector3 = _direcao_do_modelo()
	var origem: Vector3 = global_position + centro * DISTANCIA_DA_BOCA_DO_TIRO + Vector3.UP * ALTURA_DO_GOLPE
	var quantidade: int = maxi(perfil.projeteis_por_disparo, 1)
	var meia_abertura: float = deg_to_rad(perfil.abertura_do_cone_em_graus) * 0.5
	for indice in quantidade:
		var direcao: Vector3 = centro
		if quantidade > 1:
			direcao = centro.rotated(Vector3.UP, lerpf(-meia_abertura, meia_abertura, float(indice) / float(quantidade - 1)))
		Projetil.disparar_de_inimigo(perfil.projetil, origem, direcao, perfil.dano, perfil.velocidade_do_projetil, perfil.alcance_do_projetil, perfil.cor, self, get_parent())

func _morrer() -> void:
	estado = Estado.MORRENDO
	velocity = Vector3.ZERO
	# Fora de todas as camadas, o corpo para de bloquear o jogador e de levar golpe
	# enquanto cai. A forma de colisão continua ligada e a máscara fica só no mundo,
	# senão o corpo atravessa o chão com a gravidade e some do mapa.
	collision_layer = 0
	collision_mask = CAMADA_MUNDO
	_animacao.play(&"die")
	StatusManager.ganhar_experiencia(perfil.experiencia_concedida)
	EventBus.enemy_defeated.emit(perfil, global_position)
	defeated.emit(self)
	await get_tree().create_timer(_animacao.get_animation(&"die").length + 0.6).timeout
	_soltar_drop()
	queue_free()

func _soltar_drop() -> void:
	if perfil.itens_dropados.is_empty() or randf() > perfil.chance_de_drop:
		return
	var item: Item = perfil.itens_dropados.pick_random()
	ItemNoMundo.soltar(item, 1, global_position, get_parent())

## Instancia o modelo do perfil e tinge todas as superfícies com a cor do tipo. Tingir
## sobrescreve uma cópia do material em cada superfície, sem mexer no .glb, que é o
## mesmo modelo usado pelo jogador e pelos NPCs.
func _montar_modelo() -> void:
	_modelo = perfil.modelo.instantiate() as Node3D
	_modelo.name = "Modelo"
	add_child(_modelo)
	for malha in _modelo.find_children("*", "MeshInstance3D", true, false):
		var instancia: MeshInstance3D = malha as MeshInstance3D
		for superficie in instancia.mesh.get_surface_count():
			var original: Material = instancia.get_active_material(superficie)
			if original is StandardMaterial3D:
				var tingido: StandardMaterial3D = (original as StandardMaterial3D).duplicate() as StandardMaterial3D
				tingido.albedo_color = tingido.albedo_color * perfil.cor
				instancia.set_surface_override_material(superficie, tingido)
	var animacoes: Array[Node] = _modelo.find_children("*", "AnimationPlayer", true, false)
	_animacao = animacoes[0] as AnimationPlayer
	_tocar(&"idle")

## O jogador é achado pelo grupo, e não por caminho fixo, para o inimigo funcionar em
## qualquer fase.
## Em equipe há mais de um jogador (o local e os fantoches dos outros, todos no grupo de
## alvos), e o inimigo vai atrás do mais perto. A escolha é refeita de tempos em tempos, e
## não a cada quadro, porque percorrer o grupo todo quadro para cada inimigo é desperdício.
func _procurar_jogador(delta: float) -> void:
	_segundos_ate_escolher_alvo -= delta
	if _jogador != null and is_instance_valid(_jogador) and _segundos_ate_escolher_alvo > 0.0:
		return
	_segundos_ate_escolher_alvo = SEGUNDOS_ENTRE_ESCOLHAS_DE_ALVO
	var mais_perto: Node3D = null
	var menor_distancia: float = INF
	for no in get_tree().get_nodes_in_group(GRUPO_DE_ALVOS):
		var alvo: Node3D = no as Node3D
		if alvo == null or alvo.is_queued_for_deletion():
			continue
		var distancia: float = _distancia_ate(alvo)
		if distancia < menor_distancia:
			menor_distancia = distancia
			mais_perto = alvo
	_jogador = mais_perto

# Rede: o inimigo na dungeon em equipe

## O que o anfitrião manda de cada inimigo: número, posição (relativa à dungeon), giro do
## modelo, animação e vida. Vai como lista, e não dicionário, para a mensagem ficar curta.
func estado_para_a_rede() -> Array:
	return [numero_na_rede, snappedf(position.x, 0.01), snappedf(position.y, 0.01), snappedf(position.z, 0.01), snappedf(_modelo.rotation.y, 0.01), String(_animacao.current_animation), vida_atual]

func aplicar_estado_da_rede(dados: Array) -> void:
	if estado == Estado.MORRENDO:
		return
	_posicao_da_rede = Vector3(dados[1], dados[2], dados[3])
	_giro_da_rede = dados[4]
	vida_atual = int(dados[6])
	var clipe: StringName = StringName(dados[5])
	if clipe != &"" and _animacao.has_animation(clipe):
		_tocar(clipe)

## O anfitrião avisou que este inimigo caiu. A queda é a mesma do inimigo de verdade:
## cada jogo ganha a experiência e sorteia o próprio saque.
func morrer_pela_rede() -> void:
	if estado != Estado.MORRENDO:
		vida_atual = 0
		_morrer()

func _seguir_a_rede(delta: float) -> void:
	var peso: float = minf(SUAVIDADE_DO_FANTOCHE * delta, 1.0)
	position = position.lerp(_posicao_da_rede, peso)
	_modelo.rotation.y = lerp_angle(_modelo.rotation.y, _giro_da_rede, peso)

## Anda até o destino. Pela malha de navegação ele contorna prédio e cerca em vez de
## encostar na parede; sem ela, vai em linha reta.
func _andar_ate(destino: Vector3, velocidade: float, delta: float, pela_malha: bool = true) -> void:
	var para_o_destino: Vector3 = destino - global_position
	para_o_destino.y = 0.0
	if para_o_destino.length() < 0.05:
		velocity.x = 0.0
		velocity.z = 0.0
		_tocar(&"idle")
		return
	var proximo: Vector3 = _proximo_ponto_do_caminho(destino) if pela_malha else destino
	var direcao: Vector3 = proximo - global_position
	direcao.y = 0.0
	direcao = direcao.normalized()
	velocity.x = direcao.x * velocidade
	velocity.z = direcao.z * velocidade
	_virar_para(proximo, delta)
	_tocar(&"sprint" if velocidade >= 4.0 else &"walk")

## O próximo ponto para onde andar no caminho até o destino, pela malha de navegação da
## fase (a mesma dos NPCs). Numa fase sem malha, ou com o inimigo fora dela, o agente não
## devolve caminho, e o inimigo volta a ir em linha reta, como antes.
func _proximo_ponto_do_caminho(destino: Vector3) -> Vector3:
	if _agente.target_position.distance_to(destino) > DISTANCIA_PARA_REFAZER_O_CAMINHO:
		_agente.target_position = destino
	if _agente.is_navigation_finished():
		return destino
	var proximo: Vector3 = _agente.get_next_path_position()
	if _distancia_horizontal(proximo, global_position) < 0.05:
		return destino
	return proximo

func _virar_para(destino: Vector3, delta: float) -> void:
	var para_o_destino: Vector3 = destino - global_position
	if Vector2(para_o_destino.x, para_o_destino.z).length() < 0.01:
		return
	var angulo_alvo: float = atan2(para_o_destino.x, para_o_destino.z)
	_modelo.rotation.y = lerp_angle(_modelo.rotation.y, angulo_alvo, minf(velocidade_de_giro * delta, 1.0))

func _direcao_do_modelo() -> Vector3:
	return Vector3(sin(_modelo.rotation.y), 0.0, cos(_modelo.rotation.y))

func _tocar(clipe: StringName) -> void:
	if _animacao.current_animation != clipe:
		_animacao.play(clipe)

func _distancia_ate(alvo: Node3D) -> float:
	return _distancia_horizontal(global_position, alvo.global_position)

func _distancia_horizontal(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _aplicar_gravidade(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravidade * delta
