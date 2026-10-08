class_name GradeSolo
extends GridMap

enum EstadoTile { VAZIO, ARADO_SECO, ARADO_MOLHADO }

## Uma planta em cima de uma célula. É classe interna, e não Resource, porque é estado
## da partida (em que estágio esta planta está), não conteúdo de jogo. O conteúdo é o
## Cultivo que ela aponta.
class PlantaNaGrade:
	var cultivo: Cultivo
	var estagio: int = 0
	## Dias de solo molhado já contados dentro do estágio atual.
	var dias_no_estagio: int = 0
	## Planta que passou um dia em solo seco. Não cresce mais nem dá colheita, e fica na
	## célula até ser arrancada com a enxada.
	var murcha: bool = false
	var visual: Node3D

var _estado: Dictionary = {}
## Célula para PlantaNaGrade. Célula sem entrada é célula sem planta.
var _plantas: Dictionary = {}
## Cultivo para o número de linhas vazias na base das texturas dele. Medir a textura
## custa caro, então cada cultivo é medido uma vez só.
var _margem_inferior_por_cultivo: Dictionary = {}

## Terra que ficou seca com a chuva caindo (arada agora, por exemplo) e ainda não
## molhou: célula para os segundos que faltam.
var _secas_na_chuva: Dictionary[Vector2i, float] = {}

## Quanto tempo a chuva leva para molhar a terra que foi arada com ela já caindo. Não é
## na hora, para dar para ver a terra seca virar molhada.
@export var segundos_para_a_chuva_molhar: float = 3.0

@export var limite: Rect2i = Rect2i(Vector2i(-15, -15), Vector2i(30, 30))

@export_group("Visual da planta")
## Tamanho de um pixel da textura no mundo. Com 0.03, a planta de 16 pixels fica com
## cerca de meio metro, um pouco menor que o personagem.
@export var tamanho_do_pixel_da_planta: float = 0.03
## A planta é desenhada como sprites em pé, fixos, virados para a câmera (que não gira),
## como as plantações do Minecraft. São duas fileiras por célula, uma atrás da outra,
## nesta distância do centro, para o quadrado parecer plantado e não ter um sprite só.
@export var recuo_das_fileiras: float = 0.13
## A terra não fica no centro da célula: na textura do solo ela ocupa as 12 linhas de
## baixo das 16, então a faixa de terra fica deslocada para a frente. Este é o
## deslocamento, em metros, do centro da célula até o centro da faixa de terra
## (2 linhas de 16, num quadrado de 1 metro). Se a arte do solo mudar, mude junto.
@export var centro_da_terra_na_celula: float = 0.125
@export var fileiras_por_celula: int = 2

func _ready() -> void:
	DayCycleManager.day_started.connect(_ao_comecar_o_dia)
	SeasonManager.season_changed.connect(_ao_mudar_estacao)
	WeatherManager.weather_changed.connect(_ao_mudar_clima)
	add_to_group(SaveManager.GRUPO_DOS_SALVAVEIS)

## Em célula vazia, ara. Em célula com planta, arranca a planta e mantém a terra arada:
## é como o jogador se livra da planta murcha, e também serve para desistir de um
## plantio.
func arar(celula: Vector2i) -> bool:
	if not limite.has_point(celula):
		return false
	if _plantas.has(celula):
		_tirar_planta(celula)
		EventBus.crop_removed.emit(celula)
		return true
	if _estado.get(celula, EstadoTile.VAZIO) != EstadoTile.VAZIO:
		return false
	_definir_estado(celula, EstadoTile.ARADO_SECO)
	EventBus.tile_plowed.emit(celula)
	return true

func molhar(celula: Vector2i) -> bool:
	if not limite.has_point(celula):
		return false
	if _estado.get(celula, EstadoTile.VAZIO) != EstadoTile.ARADO_SECO:
		return false
	_definir_estado(celula, EstadoTile.ARADO_MOLHADO)
	EventBus.tile_watered.emit(celula)
	return true

func remover(celula: Vector2i) -> bool:
	if not limite.has_point(celula):
		return false
	if _estado.get(celula, EstadoTile.VAZIO) == EstadoTile.VAZIO:
		return false
	# Desfazer o solo leva junto o que estava plantado nele, sem render colheita.
	_tirar_planta(celula)
	_definir_estado(celula, EstadoTile.VAZIO)
	EventBus.tile_removed.emit(celula)
	return true

## Planta o cultivo na célula. Recusa célula que não está arada e célula que já tem
## planta. A checagem de estação entra no plano 11.
func plantar(celula: Vector2i, cultivo: Cultivo) -> bool:
	if cultivo == null or cultivo.estagios_de_crescimento.is_empty():
		return false
	if _estado.get(celula, EstadoTile.VAZIO) == EstadoTile.VAZIO:
		return false
	if _plantas.has(celula):
		return false
	var estacao: StringName = SeasonManager.estacao_atual()
	if not cultivo.cresce_na_estacao(estacao):
		EventBus.notice_requested.emit("%s não cresce nesta estação (%s)." % [cultivo.nome, SeasonManager.nome_exibido(estacao)])
		return false
	var planta: PlantaNaGrade = PlantaNaGrade.new()
	planta.cultivo = cultivo
	planta.visual = _criar_visual_da_planta(celula)
	_plantas[celula] = planta
	_atualizar_visual_da_planta(planta)
	EventBus.crop_planted.emit(celula, cultivo)
	return true

func planta_em(celula: Vector2i) -> PlantaNaGrade:
	return _plantas.get(celula, null)

func esta_madura(celula: Vector2i) -> bool:
	var planta: PlantaNaGrade = planta_em(celula)
	return planta != null and not planta.murcha and planta.estagio >= planta.cultivo.estagio_maduro()

## Colhe a planta madura da célula: o item cai no chão, em cima dela, e a planta some
## ou volta ao estágio de rebrota. Planta imatura não faz nada e a função retorna false.
func colher(celula: Vector2i) -> bool:
	if not esta_madura(celula):
		return false
	var planta: PlantaNaGrade = planta_em(celula)
	var cultivo: Cultivo = planta.cultivo
	var quantidade: int = randi_range(cultivo.quantidade_colhida_minima, cultivo.quantidade_colhida_maxima)
	if cultivo.item_colhido != null:
		ItemNoMundo.soltar(cultivo.item_colhido, quantidade, _centro_da_celula_no_mundo(celula), get_parent())

	if cultivo.estagio_de_rebrota > 0:
		planta.estagio = cultivo.estagio_de_rebrota
		planta.dias_no_estagio = 0
		_atualizar_visual_da_planta(planta)
	else:
		_tirar_planta(celula)
	EventBus.crop_harvested.emit(cultivo, quantidade)
	return true

## A estação virou: toda planta viva cuja cultura não serve para a estação nova murcha,
## em qualquer estágio, igual à planta que passou o dia em solo seco. Roda antes do
## crescimento do dia, porque o SeasonManager é autoload e recebe o day_started primeiro.
func _ao_mudar_estacao(nova: StringName) -> void:
	for celula: Vector2i in _plantas:
		var planta: PlantaNaGrade = _plantas[celula]
		if planta.murcha or planta.cultivo.cresce_na_estacao(nova):
			continue
		planta.murcha = true
		_atualizar_visual_da_planta(planta)
		EventBus.crop_withered.emit(celula)

## Um dia passou. A planta em solo molhado conta um dia de crescimento; a planta em
## solo seco murcha e está perdida, em qualquer estágio, inclusive madura. Depois todo
## solo molhado seca, então é preciso regar de novo a cada dia. É o único lugar que mexe
## no crescimento das plantas.
func avancar_um_dia() -> void:
	for celula: Vector2i in _plantas:
		var planta: PlantaNaGrade = _plantas[celula]
		if planta.murcha:
			continue
		var molhado: bool = _estado.get(celula, EstadoTile.VAZIO) == EstadoTile.ARADO_MOLHADO
		if not molhado:
			planta.murcha = true
			_atualizar_visual_da_planta(planta)
			EventBus.crop_withered.emit(celula)
			continue
		if planta.estagio >= planta.cultivo.estagio_maduro():
			continue
		planta.dias_no_estagio += 1
		if planta.dias_no_estagio >= planta.cultivo.dias_por_estagio:
			planta.dias_no_estagio = 0
			planta.estagio += 1
			_atualizar_visual_da_planta(planta)
			EventBus.crop_grown.emit(celula, planta.estagio)

	for celula: Vector2i in _estado.keys():
		if _estado[celula] == EstadoTile.ARADO_MOLHADO:
			_definir_estado(celula, EstadoTile.ARADO_SECO)

## A chuva molha depois de o dia virar, e não antes, porque virar o dia seca todo o solo.
## Por isso a checagem fica aqui, e não só no weather_changed: assim não importa em que
## ordem os dois sinais chegam.
func _ao_comecar_o_dia(_numero_do_dia: int) -> void:
	avancar_um_dia()
	_molhar_se_estiver_chovendo()

func _ao_mudar_clima(_clima: StringName) -> void:
	_molhar_se_estiver_chovendo()

func _molhar_se_estiver_chovendo() -> void:
	if WeatherManager.esta_chovendo():
		molhar_todo_o_solo()
	else:
		# Parou de chover: o que ainda estava esperando fica seco.
		_secas_na_chuva.clear()

## Conta o tempo da terra que ficou seca com a chuva caindo, e a molha quando o tempo
## acaba. A fila costuma estar vazia, então isto quase nunca faz nada.
func _process(delta: float) -> void:
	if _secas_na_chuva.is_empty():
		return
	for celula: Vector2i in _secas_na_chuva.keys():
		_secas_na_chuva[celula] -= delta
		if _secas_na_chuva[celula] <= 0.0:
			# molhar() troca o estado, e a troca tira a célula da fila.
			molhar(celula)

func aplicar(id_acao: StringName, celula: Vector2i) -> bool:
	match id_acao:
		&"enxada":
			return arar(celula)
		&"regador":
			return molhar(celula)
		&"picareta":
			return remover(celula)
		_:
			return false

func obter_celula_alvo(posicao_jogador: Vector3, rotacao_y: float) -> Vector2i:
	var direcao := Vector3(sin(rotacao_y), 0.0, cos(rotacao_y))
	var alvo_local := local_to_map(to_local(posicao_jogador + direcao))
	return Vector2i(alvo_local.x, alvo_local.z)

func _definir_estado(celula: Vector2i, novo_estado: EstadoTile) -> void:
	if novo_estado == EstadoTile.VAZIO:
		_estado.erase(celula)
	else:
		_estado[celula] = novo_estado
	# Toda mudança de estado passa por aqui, então é aqui que a célula entra e sai da fila
	# da chuva: entra ao ficar seca com chuva, e sai ao molhar ou ao ser desfeita.
	if novo_estado == EstadoTile.ARADO_SECO and WeatherManager.esta_chovendo():
		_secas_na_chuva[celula] = segundos_para_a_chuva_molhar
	else:
		_secas_na_chuva.erase(celula)
	_atualizar_variante(celula)
	_atualizar_variante(celula + Vector2i.LEFT)
	_atualizar_variante(celula + Vector2i.RIGHT)

func _atualizar_variante(celula: Vector2i) -> void:
	var estado: EstadoTile = _estado.get(celula, EstadoTile.VAZIO)
	if estado == EstadoTile.VAZIO:
		set_cell_item(Vector3i(celula.x, 0, celula.y), -1)
		return

	var tem_esquerda: bool = _estado.get(celula + Vector2i.LEFT, EstadoTile.VAZIO) != EstadoTile.VAZIO
	var tem_direita: bool = _estado.get(celula + Vector2i.RIGHT, EstadoTile.VAZIO) != EstadoTile.VAZIO
	var sufixo: String = "single"
	if tem_esquerda and tem_direita:
		sufixo = "middle"
	elif tem_direita:
		sufixo = "left"
	elif tem_esquerda:
		sufixo = "right"

	var prefixo: String = "dry" if estado == EstadoTile.ARADO_SECO else "watered"
	var nome_item: String = "soil_plow_%s_%s" % [prefixo, sufixo]
	var indice_item: int = mesh_library.find_item_by_name(nome_item)
	if indice_item == -1:
		push_error("GradeSolo: item de MeshLibrary nao encontrado: %s" % nome_item)
	set_cell_item(Vector3i(celula.x, 0, celula.y), indice_item)

func _centro_da_celula_no_mundo(celula: Vector2i) -> Vector3:
	return to_global(map_to_local(Vector3i(celula.x, 0, celula.y)))

## Monta as fileiras de sprites da planta na célula. Os sprites não usam billboard: ficam
## fincados na terra, e a base da textura encosta no chão.
func _criar_visual_da_planta(celula: Vector2i) -> Node3D:
	var raiz: Node3D = Node3D.new()
	raiz.name = "Planta_%d_%d" % [celula.x, celula.y]
	add_child(raiz)
	raiz.position = map_to_local(Vector3i(celula.x, 0, celula.y))
	for indice in fileiras_por_celula:
		var sprite: Sprite3D = Sprite3D.new()
		sprite.pixel_size = tamanho_do_pixel_da_planta
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.shaded = false
		# Com uma fileira ela fica no centro; com duas, uma atrás e uma na frente.
		var posicao_relativa: float = 0.0
		if fileiras_por_celula > 1:
			posicao_relativa = lerpf(-recuo_das_fileiras, recuo_das_fileiras, float(indice) / float(fileiras_por_celula - 1))
		sprite.position.z = centro_da_terra_na_celula + posicao_relativa
		raiz.add_child(sprite)
	return raiz

func _atualizar_visual_da_planta(planta: PlantaNaGrade) -> void:
	var textura: Texture2D = planta.cultivo.textura_murcha if planta.murcha else planta.cultivo.estagios_de_crescimento[planta.estagio]
	# A murcha mantém o tamanho que a planta tinha quando secou.
	var tamanho_do_pixel: float = tamanho_do_pixel_da_planta * planta.cultivo.escala_no_estagio(planta.estagio)
	for filho in planta.visual.get_children():
		var sprite: Sprite3D = filho as Sprite3D
		sprite.texture = textura
		sprite.pixel_size = tamanho_do_pixel
		# O sprite é centralizado na textura, então sobe meia altura para a base
		# encostar no chão, e desce a margem vazia que a arte tem embaixo. Sem descontar
		# a margem a planta flutua, e de cima parece plantada fora do quadrado.
		var altura_em_pixels: float = textura.get_height() * 0.5 - _margem_inferior(planta.cultivo)
		sprite.position.y = altura_em_pixels * tamanho_do_pixel

func _tirar_planta(celula: Vector2i) -> void:
	var planta: PlantaNaGrade = planta_em(celula)
	if planta == null:
		return
	planta.visual.queue_free()
	_plantas.erase(celula)

## Quantas linhas totalmente transparentes existem na base das texturas do cultivo. Usa
## a menor margem entre os estágios, para todos ficarem na mesma linha de chão e a
## planta não pular de altura ao crescer.
func _margem_inferior(cultivo: Cultivo) -> int:
	if _margem_inferior_por_cultivo.has(cultivo):
		return _margem_inferior_por_cultivo[cultivo]
	var menor_margem: int = -1
	for textura in cultivo.estagios_de_crescimento:
		var imagem: Image = textura.get_image()
		var margem: int = 0
		for linha in range(imagem.get_height() - 1, -1, -1):
			if _linha_tem_pixel(imagem, linha):
				break
			margem += 1
		if menor_margem == -1 or margem < menor_margem:
			menor_margem = margem
	_margem_inferior_por_cultivo[cultivo] = maxi(menor_margem, 0)
	return _margem_inferior_por_cultivo[cultivo]

func _linha_tem_pixel(imagem: Image, linha: int) -> bool:
	for coluna in imagem.get_width():
		if imagem.get_pixel(coluna, linha).a > 0.0:
			return true
	return false

## Leva toda planta viva ao estágio maduro, para testar colheita sem esperar os dias.
## Usado pelo menu de debug.
func amadurecer_todas_as_plantas() -> void:
	for celula: Vector2i in _plantas:
		var planta: PlantaNaGrade = _plantas[celula]
		if planta.murcha:
			continue
		planta.estagio = planta.cultivo.estagio_maduro()
		planta.dias_no_estagio = 0
		_atualizar_visual_da_planta(planta)

## Molha toda célula arada, para testar crescimento sem regar uma por uma.
func molhar_todo_o_solo() -> void:
	for celula: Vector2i in _estado.keys():
		if _estado[celula] == EstadoTile.ARADO_SECO:
			molhar(celula)

# Save

const PASTA_DOS_CULTIVOS: String = "res://resources/farming/cultivos/"

func chave_de_save() -> String:
	return "grade_de_solo"

## A célula vira o texto "x,y", porque a chave de um dicionário JSON só pode ser texto. A
## planta guarda o id do cultivo, e não o caminho do arquivo.
func exportar_estado() -> Dictionary:
	var celulas: Dictionary = {}
	for celula: Vector2i in _estado:
		celulas["%d,%d" % [celula.x, celula.y]] = _estado[celula]
	var plantas: Dictionary = {}
	for celula: Vector2i in _plantas:
		var planta: PlantaNaGrade = _plantas[celula]
		plantas["%d,%d" % [celula.x, celula.y]] = {
			"cultivo": String(planta.cultivo.id),
			"estagio": planta.estagio,
			"dias_no_estagio": planta.dias_no_estagio,
			"murcha": planta.murcha,
		}
	return {"celulas": celulas, "plantas": plantas}

## Desfaz tudo que está na grade e refaz a partir do save. Não emite os sinais de arar e
## plantar: nada disso aconteceu agora, e eles disparariam som e efeito.
func importar_estado(dados: Dictionary) -> void:
	for celula: Vector2i in _plantas.keys():
		_tirar_planta(celula)
	for celula: Vector2i in _estado.keys():
		_definir_estado(celula, EstadoTile.VAZIO)
	_secas_na_chuva.clear()
	var celulas: Dictionary = dados.get("celulas", {})
	for chave: String in celulas:
		_definir_estado(_celula_do_texto(chave), int(celulas[chave]) as EstadoTile)
	var plantas: Dictionary = dados.get("plantas", {})
	for chave: String in plantas:
		var salvo: Dictionary = plantas[chave]
		var caminho: String = PASTA_DOS_CULTIVOS + String(salvo.get("cultivo", "")) + ".tres"
		if not ResourceLoader.exists(caminho):
			continue
		var celula: Vector2i = _celula_do_texto(chave)
		var planta: PlantaNaGrade = PlantaNaGrade.new()
		planta.cultivo = load(caminho) as Cultivo
		planta.estagio = clampi(int(salvo.get("estagio", 0)), 0, planta.cultivo.estagio_maduro())
		planta.dias_no_estagio = int(salvo.get("dias_no_estagio", 0))
		planta.murcha = bool(salvo.get("murcha", false))
		planta.visual = _criar_visual_da_planta(celula)
		_plantas[celula] = planta
		_atualizar_visual_da_planta(planta)

func _celula_do_texto(texto: String) -> Vector2i:
	var partes: PackedStringArray = texto.split(",")
	return Vector2i(int(partes[0]), int(partes[1]))
