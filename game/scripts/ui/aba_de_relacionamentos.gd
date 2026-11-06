class_name AbaDeRelacionamentos
extends PanelContainer

## A aba de relacionamentos do menu de pausa: um cartão por morador (CartaoDeMorador), em
## duas colunas, com o modelo 3D, os corações, o aniversário e as marcas do dia.
##
## Os gostos de cada um não aparecem de propósito: descobrir do que o NPC gosta é parte do
## jogo. A aba só mostra o que o jogador já conquistou e o que ainda está disponível.
##
## Os cartões são montados uma vez, a partir dos perfis de resources/npcs/ (a mesma lista
## do elenco e do calendário, então o elenco do plano 30 e qualquer NPC novo aparecem sem
## mexer nesta cena). Depois disso só os textos são atualizados, porque cada cartão tem um
## palco de modelo e recriar doze modelos a cada abertura do menu seria caro.

@onready var lista: GridContainer = %ListaDeMoradores

var _cartoes: Array[CartaoDeMorador] = []

func _ready() -> void:
	var perfis: Array[PerfilNpc] = ElencoDeNpcs.carregar_perfis()
	perfis.sort_custom(func(a: PerfilNpc, b: PerfilNpc) -> bool: return a.nome_exibido.naturalnocasecmp_to(b.nome_exibido) < 0)
	if perfis.is_empty():
		var vazio: Label = Label.new()
		vazio.text = "Você ainda não conhece ninguém."
		vazio.theme_type_variation = &"TextoApagado"
		lista.add_child(vazio)
	for perfil in perfis:
		var cartao: CartaoDeMorador = CartaoDeMorador.novo(perfil)
		lista.add_child(cartao)
		_cartoes.append(cartao)
	RelationshipManager.relationship_changed.connect(_ao_mudar_relacionamento)
	RelationshipManager.dating_started.connect(_ao_comecar_namoro)
	visibility_changed.connect(_ao_mudar_visibilidade)

## Relê os textos de todos os cartões.
func atualizar() -> void:
	for cartao in _cartoes:
		cartao.atualizar()

## O primeiro cartão, para o menu dar o foco ao abrir a aba. Null sem moradores.
func primeiro_cartao() -> Control:
	return _cartoes[0] if not _cartoes.is_empty() else null

func cartoes() -> Array[CartaoDeMorador]:
	return _cartoes

func _ao_mudar_relacionamento(_npc_id: String, _pontos: int, _coracoes: int) -> void:
	if is_visible_in_tree():
		atualizar()

func _ao_comecar_namoro(_npc_id: String) -> void:
	if is_visible_in_tree():
		atualizar()

## "Conversou hoje" e "presente" mudam com o dia e a semana, sem sinal próprio. Atualizar
## ao aparecer cobre os dois, porque a aba nunca fica aberta na virada do dia.
func _ao_mudar_visibilidade() -> void:
	if is_visible_in_tree():
		atualizar()
