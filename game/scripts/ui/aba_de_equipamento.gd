class_name AbaDeEquipamento
extends PanelContainer

## A aba de equipamento do menu de pausa: o que o jogador carrega (a arma na mão, as
## ferramentas, a armadura, o acessório e os troféus) à esquerda, o modelo dele no meio
## com o nível e a experiência, e os números de combate à direita, com a comparação de
## troca de arma.
##
## É só para olhar. Equipar e trocar o item da mão continuam na aba de inventário, onde o
## item está; aqui os quadrados não arrastam nem recebem foco.
##
## Tudo é relido ao aparecer, porque a aba nunca fica aberta enquanto o jogo anda (o menu
## pausa o jogo). Assim não é preciso escutar cada sinal de cada sistema.

const TAMANHO_DO_QUADRO: Vector2 = Vector2(48.0, 48.0)
const MARGEM_DO_ICONE: float = 6.0
const TAMANHO_DO_NIVEL: int = 8

## Como cada tipo de arma aparece na tela: a descrição curta e a velocidade do golpe. É
## texto de tela, não regra: o golpe de cada tipo continua sendo decidido no player.gd.
const DESCRICAO_DO_TIPO: Dictionary = {
	Arma.Tipo.PUNHO: "soco, combo de 3",
	Arma.Tipo.LEVE: "leve, um golpe por vez",
	Arma.Tipo.PESADA: "pesada, golpe largo",
	Arma.Tipo.DISTANCIA: "dispara de longe",
}
const VELOCIDADE_DO_TIPO: Dictionary = {
	Arma.Tipo.PUNHO: "rápida",
	Arma.Tipo.LEVE: "rápida",
	Arma.Tipo.PESADA: "lenta",
	Arma.Tipo.DISTANCIA: "média",
}

@onready var quadro_da_arma: HBoxContainer = %QuadroDaArma
@onready var nome_da_arma: Label = %NomeDaArma
@onready var tipo_da_arma: Label = %TipoDaArma
@onready var ferramentas: HBoxContainer = %Ferramentas
@onready var armadura: HBoxContainer = %Armadura
@onready var acessorio: HBoxContainer = %Acessorio
@onready var trofeus: HBoxContainer = %Trofeus
@onready var palco: ModelStage = %PalcoDoJogador
@onready var dica_do_giro: Label = %DicaDoGiro
@onready var nome_e_nivel: Label = %NomeENivel
@onready var barra_de_experiencia: ProgressBar = %BarraDeExperiencia
@onready var texto_da_experiencia: Label = %TextoDaExperiencia
@onready var vida_maxima: Label = %VidaMaxima
@onready var stamina_maxima: Label = %StaminaMaxima
@onready var dano: Label = %Dano
@onready var velocidade: Label = %Velocidade
@onready var alcance: Label = %Alcance
@onready var giro: Label = %Giro
@onready var titulo_da_troca: Label = %TituloDaTroca
@onready var linhas_da_troca: VBoxContainer = %LinhasDaTroca

func _ready() -> void:
	vida_maxima.add_theme_color_override(&"font_color", CoresDaInterface.verde())
	stamina_maxima.add_theme_color_override(&"font_color", CoresDaInterface.ouro())
	titulo_da_troca.add_theme_color_override(&"font_color", CoresDaInterface.ciano())
	visibility_changed.connect(_ao_mudar_visibilidade)

## Relê tudo e põe o jogador no palco. O menu chama ao mostrar a aba.
func atualizar() -> void:
	var arma: Arma = _arma_em_uso()
	_mostrar_arma(arma)
	_mostrar_ferramentas()
	_mostrar_espaco(armadura, InventoryManager.Espaco.ARMADURA, "Armadura", "Sem armadura.")
	_mostrar_espaco(acessorio, InventoryManager.Espaco.ACESSORIO, "Acessório", "Sem acessório.")
	_mostrar_trofeus()
	_mostrar_nivel()
	_mostrar_numeros(arma)
	_mostrar_troca(arma)
	dica_do_giro.text = "arraste com o mouse ou use o direcional direito para girar"

func _ao_mudar_visibilidade() -> void:
	if is_visible_in_tree():
		atualizar()
		palco.mostrar_jogador()
	else:
		# Escondida, a aba não precisa do modelo renderizando por baixo das outras.
		palco.limpar()

# Coluna da esquerda

## A arma na mão, ou o punho quando o item na mão não é arma, igual ao player.gd.
func _arma_em_uso() -> Arma:
	var na_mao: Arma = EquipmentManager.item_na_mao() as Arma
	if na_mao != null:
		return na_mao
	var jogador: Node = get_tree().get_first_node_in_group(&"jogador")
	if jogador != null:
		return jogador.get(&"punho") as Arma
	return null

func _mostrar_arma(arma: Arma) -> void:
	_esvaziar(quadro_da_arma)
	var na_mao: bool = EquipmentManager.item_na_mao() is Arma
	quadro_da_arma.add_child(_novo_quadro(arma if na_mao else null, &"SlotNaMao"))
	if arma == null:
		nome_da_arma.text = "Nada na mão"
		tipo_da_arma.text = ""
		return
	nome_da_arma.text = arma.nome if na_mao else "Mãos vazias"
	tipo_da_arma.text = DESCRICAO_DO_TIPO.get(arma.tipo, "")

func _mostrar_ferramentas() -> void:
	_esvaziar(ferramentas)
	var alguma: bool = false
	for item in UpgradeManager.itens_aprimoraveis_do_jogador():
		if item is Ferramenta:
			ferramentas.add_child(_novo_quadro(item, &"SlotNormal"))
			alguma = true
	if not alguma:
		ferramentas.add_child(_rotulo_apagado("Nenhuma na mochila."))

func _mostrar_espaco(linha: HBoxContainer, espaco: int, nome: String, vazio: String) -> void:
	_esvaziar(linha)
	var item: Item = InventoryManager.item_equipado(espaco)
	linha.add_child(_novo_quadro(item, &"SlotNormal"))
	var rotulo: Label = Label.new()
	rotulo.text = "%s: %s" % [nome, item.nome] if item != null else vazio
	if item == null:
		rotulo.theme_type_variation = &"TextoApagado"
	rotulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(rotulo)

## Um troféu por dungeon, na ordem delas. O que ainda não foi ganho fica trancado.
func _mostrar_trofeus() -> void:
	_esvaziar(trofeus)
	for definicao in DungeonManager.definicoes():
		if definicao.trofeu == null:
			continue
		var ganho: bool = DungeonManager.chefe_ja_foi_vencido(definicao.id)
		var quadro: Panel = _novo_quadro(definicao.trofeu, &"SlotNormal" if ganho else &"SlotTrancado")
		quadro.tooltip_text = definicao.trofeu.nome if ganho else "Vença o chefe de %s." % definicao.nome
		if not ganho:
			# O ícone aparece apagado, para o jogador saber o que falta sem ver a cor.
			(quadro.get_child(0) as CanvasItem).modulate = Color(CoresDaInterface.desligado(), 0.6)
		trofeus.add_child(quadro)

# Meio

func _mostrar_nivel() -> void:
	var nome: String = AccountManager.nome_da_conta if AccountManager.nome_da_conta != "" else "Você"
	nome_e_nivel.text = "%s . Nv %d" % [nome, StatusManager.nivel]
	var para_o_proximo: int = StatusManager.experiencia_para_o_proximo_nivel()
	barra_de_experiencia.max_value = para_o_proximo
	barra_de_experiencia.value = StatusManager.experiencia
	if StatusManager.nivel >= StatusManager.NIVEL_MAXIMO:
		texto_da_experiencia.text = "nível máximo"
	else:
		texto_da_experiencia.text = "%d / %d de experiência" % [StatusManager.experiencia, para_o_proximo]

# Coluna da direita

func _mostrar_numeros(arma: Arma) -> void:
	vida_maxima.text = str(StatusManager.vida_maxima())
	stamina_maxima.text = str(roundi(StatusManager.stamina_maxima()))
	if arma == null:
		dano.text = "0"
		velocidade.text = ""
		alcance.text = ""
		giro.text = ""
		return
	dano.text = str(UpgradeManager.dano_de(arma))
	velocidade.text = VELOCIDADE_DO_TIPO.get(arma.tipo, "")
	alcance.text = "%.1f m" % arma.alcance
	var tem_giro: bool = arma.abertura_do_giro_automatico_em_graus > 0.0
	giro.text = "ligado" if tem_giro else "desligado"
	giro.add_theme_color_override(&"font_color", CoresDaInterface.ciano() if tem_giro else CoresDaInterface.texto_apagado())

## Compara a arma na mão com a primeira outra arma da mochila: o que muda se trocar.
func _mostrar_troca(arma: Arma) -> void:
	_esvaziar(linhas_da_troca)
	var outra: Arma = _outra_arma(arma)
	if outra == null or arma == null:
		titulo_da_troca.text = "Troca de arma"
		linhas_da_troca.add_child(_rotulo_apagado("Nenhuma outra arma na mochila."))
		return
	titulo_da_troca.text = "Se trocar por %s Nv%d" % [outra.nome, UpgradeManager.nivel_de(outra)]
	var dano_agora: int = UpgradeManager.dano_de(arma)
	var dano_depois: int = UpgradeManager.dano_de(outra)
	_linha_da_troca("Dano", "%d (%+d)" % [dano_depois, dano_depois - dano_agora], _cor_da_diferenca(dano_depois - dano_agora))
	_linha_da_troca("Velocidade", VELOCIDADE_DO_TIPO.get(outra.tipo, ""), CoresDaInterface.ciano())
	var diferenca_de_alcance: float = outra.alcance - arma.alcance
	_linha_da_troca("Alcance", "%.1f m (%+.1f)" % [outra.alcance, diferenca_de_alcance], _cor_da_diferenca(diferenca_de_alcance))

## Ganho em verde, perda em âmbar (nunca vermelho), igual em texto normal.
func _cor_da_diferenca(diferenca: float) -> Color:
	if diferenca > 0.0:
		return CoresDaInterface.verde()
	if diferenca < 0.0:
		return CoresDaInterface.ambar()
	return CoresDaInterface.texto()

func _outra_arma(arma: Arma) -> Arma:
	for item in UpgradeManager.itens_aprimoraveis_do_jogador():
		if item is Arma and item != arma:
			return item as Arma
	return null

func _linha_da_troca(nome: String, valor: String, cor: Color) -> void:
	var linha: HBoxContainer = HBoxContainer.new()
	var rotulo: Label = Label.new()
	rotulo.text = nome
	rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(rotulo)
	var numero: Label = Label.new()
	numero.text = valor
	numero.add_theme_color_override(&"font_color", cor)
	linha.add_child(numero)
	linhas_da_troca.add_child(linha)

# Peças

## Um quadrado de item só para olhar: o estado vem da variation do Theme, o ícone fica no
## meio e o nível (arma e ferramenta) no canto, em ciano.
func _novo_quadro(item: Item, variacao: StringName) -> Panel:
	var quadro: Panel = Panel.new()
	quadro.custom_minimum_size = TAMANHO_DO_QUADRO
	quadro.theme_type_variation = variacao
	var icone: TextureRect = TextureRect.new()
	icone.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icone.offset_left = MARGEM_DO_ICONE
	icone.offset_top = MARGEM_DO_ICONE
	icone.offset_right = -MARGEM_DO_ICONE
	icone.offset_bottom = -MARGEM_DO_ICONE
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	quadro.add_child(icone)
	if item == null:
		return quadro
	icone.texture = item.icone
	quadro.tooltip_text = item.nome
	if UpgradeManager.pode_ser_aprimorado(item):
		quadro.add_child(_novo_rotulo_de_nivel(UpgradeManager.nivel_de(item)))
	return quadro

## "Nv2" no canto de baixo do quadrado, em Silkscreen 8 (nítida em múltiplos de 8).
func _novo_rotulo_de_nivel(nivel: int) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = "Nv%d" % nivel
	rotulo.theme_type_variation = &"Titulo"
	rotulo.add_theme_font_size_override(&"font_size", TAMANHO_DO_NIVEL)
	rotulo.add_theme_color_override(&"font_color", CoresDaInterface.ciano())
	rotulo.add_theme_color_override(&"font_outline_color", CoresDaInterface.noite())
	rotulo.add_theme_constant_override(&"outline_size", 3)
	rotulo.anchor_top = 1.0
	rotulo.anchor_bottom = 1.0
	rotulo.offset_left = 5.0
	rotulo.offset_top = -16.0
	rotulo.offset_bottom = -3.0
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rotulo

func _rotulo_apagado(texto: String) -> Label:
	var rotulo: Label = Label.new()
	rotulo.text = texto
	rotulo.theme_type_variation = &"TextoApagado"
	rotulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rotulo

func _esvaziar(container: Node) -> void:
	for filho in container.get_children():
		container.remove_child(filho)
		filho.queue_free()
