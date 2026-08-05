extends Node

const CAMINHO_DO_SAVE: String = "user://save_game.json"

func salvar_jogo() -> void:
	var dados := {
		"numero_do_dia": DayCycleManager.numero_do_dia,
		"fase_atual": GameManager.fase_atual,
		"marcos_desbloqueados": GameManager.marcos_desbloqueados,
	}
	var arquivo := FileAccess.open(CAMINHO_DO_SAVE, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(dados))

func carregar_jogo() -> bool:
	if not FileAccess.file_exists(CAMINHO_DO_SAVE):
		return false
	var arquivo := FileAccess.open(CAMINHO_DO_SAVE, FileAccess.READ)
	var dados = JSON.parse_string(arquivo.get_as_text())
	if dados == null:
		return false
	DayCycleManager.numero_do_dia = dados.get("numero_do_dia", 1)
	GameManager.fase_atual = dados.get("fase_atual", GameManager.FaseDaHistoria.INICIO)
	GameManager.marcos_desbloqueados.clear()
	for marco in dados.get("marcos_desbloqueados", []):
		GameManager.marcos_desbloqueados.append(marco)
	return true
