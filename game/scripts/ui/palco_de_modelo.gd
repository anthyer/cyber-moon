class_name ModelStage
extends Control

## O palco de modelo: mostra o modelo 3D de um personagem dentro de uma tela, no lugar de
## um retrato (plano 40, "Modelos 3D no lugar de retrato"). A conversa usa dois, e as
## telas de equipamento, relacionamentos, serviços, desmaio e diário usam o mesmo.
##
## O modelo fica num SubViewport com mundo próprio (own_world_3d), câmera, luz e uma luz
## ciano no chão. Assim a cena do jogo não aparece no palco, e o modelo do palco não
## aparece no jogo. O palco anima mesmo com o jogo pausado (process_mode ALWAYS), porque
## o menu de pausa também mostra modelo.
##
## Uso, numa tela:
##
##     @onready var palco: ModelStage = %PalcoDoMorador
##     palco.mostrar_npc("marta")
##     palco.tocar(&"emote-yes")
##     palco.definir_aceso(false)
##
## Para muitos modelos na mesma tela (a aba de relacionamentos), use o modo foto:
## `await palco.tirar_foto()` renderiza uma vez e deixa a imagem parada no lugar, sem
## custo de renderização por quadro; `voltar_a_animar()` desfaz.

## Emitido quando o modo foto termina de tirar a imagem.
signal foto_tirada(foto: Texture2D)

const PASTA_DOS_NPCS: String = "res://resources/npcs/"
const PASTA_DAS_FIGURANTES: String = "res://resources/npcs/figurantes/"
## O id que `mostrar_por_id` entende como "o jogador desta máquina".
const ID_DO_JOGADOR: StringName = &"jogador"
const ANIMACAO_PARADA: StringName = &"idle"
## Os clipes da Kenney vêm sem loop. No palco, estes repetem.
const ANIMACOES_EM_LOOP: Array[StringName] = [&"idle", &"walk", &"sprint"]
## Quem escuta fica mais escuro, como o filtro do mock da conversa.
const COR_DE_QUEM_ESTA_APAGADO: Color = Color(0.5, 0.5, 0.58)
## Quanto quem fala chega para perto da câmera, em metros.
const AVANCO_DE_QUEM_ESTA_ACESO: float = 0.15
const SEGUNDOS_PARA_ACENDER: float = 0.15
const GRAUS_POR_PIXEL_DO_MOUSE: float = 0.6
const GRAUS_POR_SEGUNDO_DO_DIRECIONAL: float = 180.0

## Onde os pés do modelo ficam no mundo do palco. A câmera olha para x = 0; mexer no x
## desloca o modelo para o lado dentro do palco.
@export var posicao_do_modelo: Vector3 = Vector3(0.0, 0.2, 0.0)
## Para onde o modelo olha ao aparecer. Zero é de frente para a câmera; positivo vira
## para a direita da tela.
@export var giro_inicial_graus: float = 0.0
@export var distancia_da_camera: float = 2.2
@export var altura_da_camera: float = 0.5
## Ângulo de visão vertical da câmera. Menor aproxima (o modelo fica maior).
@export var campo_de_visao: float = 30.0
## Liga o giro do modelo arrastando com o botão esquerdo do mouse ou com o direcional
## direito do controle (aba de equipamento).
@export var gira_com_mouse_e_direcional: bool = false
@export var mostrar_brilho_do_chao: bool = true

@onready var _tela: SubViewportContainer = $Tela
@onready var _viewport: SubViewport = $Tela/SubViewport
@onready var _camera: Camera3D = $Tela/SubViewport/Camera3D
@onready var _suporte: Node3D = $Tela/SubViewport/Suporte
@onready var _brilho_do_chao: MeshInstance3D = $Tela/SubViewport/BrilhoDoChao
@onready var _luz_do_chao: OmniLight3D = $Tela/SubViewport/LuzDoChao
@onready var _foto: TextureRect = $Foto

var _modelo: Node3D
var _animacao: AnimationPlayer
var _aceso: bool = true
var _transicao: Tween

func _ready() -> void:
	_camera.position = Vector3(0.0, altura_da_camera, distancia_da_camera)
	_camera.fov = campo_de_visao
	_suporte.position = posicao_do_modelo
	_suporte.rotation.y = deg_to_rad(giro_inicial_graus)
	_brilho_do_chao.position = Vector3(posicao_do_modelo.x, posicao_do_modelo.y + 0.005, posicao_do_modelo.z)
	_luz_do_chao.position = Vector3(posicao_do_modelo.x, posicao_do_modelo.y + 0.1, posicao_do_modelo.z + 0.5)
	_brilho_do_chao.visible = mostrar_brilho_do_chao
	_luz_do_chao.visible = mostrar_brilho_do_chao
	mouse_filter = Control.MOUSE_FILTER_STOP if gira_com_mouse_e_direcional else Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not gira_com_mouse_e_direcional or not is_visible_in_tree():
		return
	var giro: float = InputManager.giro_do_direcional_direito()
	_suporte.rotation.y += deg_to_rad(giro * GRAUS_POR_SEGUNDO_DO_DIRECIONAL * delta)

func _gui_input(evento: InputEvent) -> void:
	if not gira_com_mouse_e_direcional:
		return
	var movimento: InputEventMouseMotion = evento as InputEventMouseMotion
	if movimento != null and (movimento.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_suporte.rotation.y += deg_to_rad(movimento.relative.x * GRAUS_POR_PIXEL_DO_MOUSE)
		accept_event()

# Mostrar

## Mostra uma cena de modelo qualquer (um .glb de personagem, por exemplo). Tira o que
## estava no palco antes.
func mostrar_cena(cena: PackedScene) -> void:
	limpar()
	if esta_em_foto():
		voltar_a_animar()
	if cena == null:
		return
	_por_modelo(cena.instantiate() as Node3D)

## Mostra o morador pelo id do PerfilNpc (resources/npcs/<id>.tres, ou a pasta das
## figurantes). Devolve false se o perfil não existe.
func mostrar_npc(id_do_npc: String) -> bool:
	for pasta in [PASTA_DOS_NPCS, PASTA_DAS_FIGURANTES]:
		var caminho: String = pasta + id_do_npc + ".tres"
		if ResourceLoader.exists(caminho):
			var perfil: PerfilNpc = load(caminho) as PerfilNpc
			mostrar_cena(perfil.modelo)
			return true
	push_warning("Palco de modelo: não existe PerfilNpc com id %s" % id_do_npc)
	return false

## Mostra um dos visuais de protagonista pelo id (resources/protagonistas/<id>.tres).
## Devolve false se o perfil não existe.
func mostrar_protagonista(id_do_perfil: StringName) -> bool:
	var perfil: PerfilProtagonista = PerfilProtagonista.carregar(id_do_perfil)
	if perfil == null:
		push_warning("Palco de modelo: não existe PerfilProtagonista com id %s" % id_do_perfil)
		return false
	mostrar_cena(perfil.modelo)
	return true

## Mostra o jogador desta máquina com o visual que ele está vestindo. Sem visual escolhido
## (save antigo), mostra o modelo que o nó Personagem do jogador usa.
func mostrar_jogador() -> void:
	var jogador: Node = get_tree().get_first_node_in_group(&"jogador")
	if jogador == null:
		limpar()
		return
	var perfil: PerfilProtagonista = jogador.get(&"perfil_protagonista") as PerfilProtagonista
	if perfil != null and perfil.modelo != null:
		mostrar_cena(perfil.modelo)
		return
	var personagem: Node = jogador.get_node_or_null("Personagem")
	if personagem != null and personagem.scene_file_path != "":
		mostrar_cena(load(personagem.scene_file_path) as PackedScene)
	else:
		limpar()

## Um só ponto de entrada por id, para tela que recebe o id de fora (o diário, o
## desmaio): "jogador", o id de um morador, ou o id de um visual de protagonista.
func mostrar_por_id(id: StringName) -> bool:
	if id == ID_DO_JOGADOR:
		mostrar_jogador()
		return true
	if ResourceLoader.exists(PASTA_DOS_NPCS + String(id) + ".tres") or ResourceLoader.exists(PASTA_DAS_FIGURANTES + String(id) + ".tres"):
		return mostrar_npc(String(id))
	return mostrar_protagonista(id)

## Tira o modelo do palco.
func limpar() -> void:
	for filho in _suporte.get_children():
		filho.queue_free()
	_modelo = null
	_animacao = null

# Animação e luz

## Toca um clipe do modelo. Clipe que o modelo não tem vira idle, para uma fala com
## animação errada no .tres não deixar o modelo congelado.
func tocar(clipe: StringName) -> void:
	if _animacao == null:
		return
	var escolhido: StringName = clipe if _animacao.has_animation(clipe) else ANIMACAO_PARADA
	if _animacao.current_animation != escolhido:
		_animacao.play(escolhido)

## Aceso é quem fala: claro e um pouco à frente. Apagado é quem escuta: mais escuro e no
## lugar. Com `imediato`, troca sem a transição curta.
func definir_aceso(aceso: bool, imediato: bool = false) -> void:
	_aceso = aceso
	var cor: Color = Color.WHITE if aceso else COR_DE_QUEM_ESTA_APAGADO
	var z: float = posicao_do_modelo.z + (AVANCO_DE_QUEM_ESTA_ACESO if aceso else 0.0)
	if _transicao != null:
		_transicao.kill()
	if imediato:
		modulate = cor
		_suporte.position.z = z
		return
	_transicao = create_tween().set_parallel(true)
	_transicao.tween_property(self, "modulate", cor, SEGUNDOS_PARA_ACENDER)
	_transicao.tween_property(_suporte, "position:z", z, SEGUNDOS_PARA_ACENDER)

func esta_aceso() -> bool:
	return _aceso

## O modelo que está no palco, ou null. Para quem precisa mexer nele (vestir, trocar arma).
func modelo() -> Node3D:
	return _modelo

func animacao() -> AnimationPlayer:
	return _animacao

# Modo foto

## Renderiza o palco uma vez e troca a imagem animada por uma foto parada. Depois disso o
## SubViewport não renderiza mais nada e a animação fica pausada, até `voltar_a_animar()`.
## Funciona também com o palco escondido (numa aba que ainda não abriu).
##
##     var foto: Texture2D = await palco.tirar_foto()
func tirar_foto() -> Texture2D:
	_tela.visible = true
	_foto.visible = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Dois quadros: um para a animação pôr o modelo na pose, outro para desenhar.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var imagem: Image = _viewport.get_texture().get_image()
	var foto: ImageTexture = ImageTexture.create_from_image(imagem)
	_foto.texture = foto
	_foto.visible = true
	_tela.visible = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _animacao != null:
		_animacao.pause()
	foto_tirada.emit(foto)
	return foto

func esta_em_foto() -> bool:
	return _foto.visible

func voltar_a_animar() -> void:
	_foto.visible = false
	_tela.visible = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if _animacao != null:
		_animacao.play()

# Interno

func _por_modelo(modelo_novo: Node3D) -> void:
	_modelo = modelo_novo
	_suporte.add_child(modelo_novo)
	var animacoes: Array[Node] = modelo_novo.find_children("*", "AnimationPlayer", true, false)
	if animacoes.is_empty():
		return
	_animacao = animacoes[0] as AnimationPlayer
	for clipe in ANIMACOES_EM_LOOP:
		if _animacao.has_animation(clipe):
			_animacao.get_animation(clipe).loop_mode = Animation.LOOP_LINEAR
	_animacao.play(ANIMACAO_PARADA)
