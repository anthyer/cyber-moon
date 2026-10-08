class_name AbaDeRelacionamentos
extends VBoxContainer

## A aba de relacionamentos do menu de pausa: uma linha por NPC, com os corações, o
## aniversário e o que ainda dá para fazer com ele hoje e nesta semana.
##
## Os gostos de cada um não aparecem de propósito: descobrir do que o NPC gosta é parte do
## jogo. A aba só mostra o que o jogador já conquistou e o que ainda está disponível.
##
## As linhas são montadas por código a partir dos perfis de resources/npcs/, a mesma
## lista do elenco e do calendário, então um NPC novo aparece aqui sem mexer nesta cena.

const COR_DO_CORACAO_CHEIO: Color = Color(1.0, 0.45, 0.75)
const COR_DO_CORACAO_VAZIO: Color = Color(0.2, 0.22, 0.3)
const COR_DO_TEXTO: Color = Color(0.92, 0.95, 1.0)
const COR_DO_TEXTO_APAGADO: Color = Color(0.6, 0.66, 0.8)
const COR_DE_DISPONIVEL: Color = Color(0.2, 0.95, 1.0)
const TAMANHO_DO_CORACAO: Vector2 = Vector2(12.0, 12.0)
const LARGURA_DO_NOME: float = 190.0
const LARGURA_DO_ANIVERSARIO: float = 130.0

@onready var lista: VBoxContainer = %ListaDeNpcs

var _perfis: Array[PerfilNpc] = []

func _ready() -> void:
	_perfis = ElencoDeNpcs.carregar_perfis()
	_perfis.sort_custom(func(a: PerfilNpc, b: PerfilNpc) -> bool: return a.nome_exibido.naturalnocasecmp_to(b.nome_exibido) < 0)
	RelationshipManager.relationship_changed.connect(_ao_mudar_relacionamento)
	RelationshipManager.dating_started.connect(_ao_comecar_namoro)
	visibility_changed.connect(_ao_mudar_visibilidade)
	redesenhar()

## Refaz todas as linhas. São seis NPCs e a aba só muda quando o jogador faz algo, então
## recriar tudo é mais simples e mais seguro que atualizar pedaço por pedaço.
func redesenhar() -> void:
	for filho in lista.get_children():
		filho.queue_free()
	if _perfis.is_empty():
		lista.add_child(_novo_rotulo("Você ainda não conhece ninguém.", 14, COR_DO_TEXTO_APAGADO))
		return
	for perfil in _perfis:
		lista.add_child(_nova_linha(perfil))

func _ao_mudar_relacionamento(_npc_id: String, _pontos: int, _coracoes: int) -> void:
	if is_visible_in_tree():
		redesenhar()

func _ao_comecar_namoro(_npc_id: String) -> void:
	if is_visible_in_tree():
		redesenhar()

## "Conversou hoje" e "pode presentear" mudam com o dia e a semana, sem sinal próprio.
## Redesenhar ao aparecer cobre os dois, porque a aba nunca fica aberta na virada do dia.
func _ao_mudar_visibilidade() -> void:
	if is_visible_in_tree():
		redesenhar()

func _nova_linha(perfil: PerfilNpc) -> VBoxContainer:
	var linha: VBoxContainer = VBoxContainer.new()
	linha.add_theme_constant_override(&"separation", 2)

	var de_cima: HBoxContainer = HBoxContainer.new()
	de_cima.add_theme_constant_override(&"separation", 14)
	linha.add_child(de_cima)

	var nome: HBoxContainer = HBoxContainer.new()
	nome.custom_minimum_size = Vector2(LARGURA_DO_NOME, 0.0)
	nome.add_theme_constant_override(&"separation", 8)
	nome.add_child(_novo_rotulo(perfil.nome_exibido, 16, COR_DO_TEXTO))
	if RelationshipManager.esta_namorando(perfil.id):
		nome.add_child(_novo_rotulo("Namorando", 12, COR_DO_CORACAO_CHEIO))
	de_cima.add_child(nome)

	de_cima.add_child(_novos_coracoes(RelationshipManager.coracoes(perfil.id)))

	var aniversario: Label = _novo_rotulo("%s, dia %d" % [SeasonManager.nome_exibido(perfil.estacao_do_aniversario), perfil.dia_do_aniversario], 13, COR_DO_TEXTO_APAGADO)
	aniversario.custom_minimum_size = Vector2(LARGURA_DO_ANIVERSARIO, 0.0)
	de_cima.add_child(aniversario)

	var de_baixo: HBoxContainer = HBoxContainer.new()
	de_baixo.add_theme_constant_override(&"separation", 18)
	linha.add_child(de_baixo)
	if RelationshipManager.pode_presentear(perfil.id):
		de_baixo.add_child(_novo_rotulo("Pode presentear", 12, COR_DE_DISPONIVEL))
	else:
		de_baixo.add_child(_novo_rotulo("Presente dado esta semana", 12, COR_DO_TEXTO_APAGADO))
	if DialogueManager.ja_conversou_hoje(perfil.id):
		de_baixo.add_child(_novo_rotulo("Conversou hoje", 12, COR_DO_TEXTO_APAGADO))
	else:
		de_baixo.add_child(_novo_rotulo("Ainda não conversou hoje", 12, COR_DE_DISPONIVEL))
	return linha

## Dez quadradinhos, cheios até o número de corações. Quadrado e não figura de coração
## porque não há arte para isso ainda; trocar por textura depois é mexer só aqui.
func _novos_coracoes(cheios: int) -> HBoxContainer:
	var coracoes: HBoxContainer = HBoxContainer.new()
	coracoes.add_theme_constant_override(&"separation", 3)
	coracoes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for indice in RelationshipManager.CORACOES_MAXIMOS:
		var coracao: ColorRect = ColorRect.new()
		coracao.custom_minimum_size = TAMANHO_DO_CORACAO
		coracao.color = COR_DO_CORACAO_CHEIO if indice < cheios else COR_DO_CORACAO_VAZIO
		coracoes.add_child(coracao)
	return coracoes

func _novo_rotulo(texto: String, tamanho: int, cor: Color) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.add_theme_font_size_override(&"font_size", tamanho)
	rotulo.add_theme_color_override(&"font_color", cor)
	return rotulo
