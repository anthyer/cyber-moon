extends Node

const CAMINHO_DO_SAVE: String = "user://save_game.json"

func salvar_jogo() -> bool:
	var dados := {
		"numero_do_dia": DayCycleManager.numero_do_dia,
		"fase_atual": GameManager.fase_atual,
		"marcos_desbloqueados": GameManager.marcos_desbloqueados,
	}
	var arquivo := FileAccess.open(CAMINHO_DO_SAVE, FileAccess.WRITE)
	if arquivo == null:
		push_error("Nao foi possivel abrir o arquivo de save para escrita: " + str(FileAccess.get_open_error()))
		return false
	arquivo.store_string(JSON.stringify(dados))
	return true

func carregar_jogo() -> bool:
	if not FileAccess.file_exists(CAMINHO_DO_SAVE):
		return false
	var arquivo := FileAccess.open(CAMINHO_DO_SAVE, FileAccess.READ)
	if arquivo == null:
		push_error("Nao foi possivel abrir o arquivo de save para leitura: " + str(FileAccess.get_open_error()))
		return false
	var dados = JSON.parse_string(arquivo.get_as_text())
	if dados == null:
		return false
	DayCycleManager.numero_do_dia = dados.get("numero_do_dia", 1)
	GameManager.fase_atual = dados.get("fase_atual", GameManager.FaseDaHistoria.INICIO)
	GameManager.marcos_desbloqueados.clear()
	for marco in dados.get("marcos_desbloqueados", []):
		GameManager.marcos_desbloqueados.append(marco)
	return true
