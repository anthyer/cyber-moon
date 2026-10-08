class_name CatalogoDeItens
extends RefCounted

## Todos os itens do jogo, achados pelo id.
##
## O save guarda o id do item, e não o caminho do arquivo: mudar um item de pasta não
## quebra um jogo salvo. Este catálogo percorre resources/items/ uma vez, na primeira
## consulta, e devolve o Item de cada id.

const PASTA_DOS_ITENS: String = "res://resources/items/"

static var _itens_por_id: Dictionary[StringName, Item] = {}
static var _carregado: bool = false

static func por_id(id: StringName) -> Item:
	_carregar()
	return _itens_por_id.get(id, null)

static func todos() -> Array[Item]:
	_carregar()
	var lista: Array[Item] = []
	lista.assign(_itens_por_id.values())
	return lista

static func _carregar() -> void:
	if _carregado:
		return
	_carregado = true
	_varrer(PASTA_DOS_ITENS)

## Percorre a pasta e as subpastas. No jogo exportado os arquivos aparecem com ".remap"
## no fim do nome, e o load precisa do nome sem ele.
static func _varrer(pasta: String) -> void:
	for subpasta in DirAccess.get_directories_at(pasta):
		_varrer(pasta + subpasta + "/")
	for arquivo in DirAccess.get_files_at(pasta):
		var nome: String = arquivo.trim_suffix(".remap")
		if not nome.ends_with(".tres"):
			continue
		var item: Item = load(pasta + nome) as Item
		if item != null and item.id != &"":
			_itens_por_id[item.id] = item
