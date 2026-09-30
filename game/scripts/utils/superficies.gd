@tool
class_name Superficies
extends RefCounted

## Tabela única que traduz nome de modelo, de nó ou de célula do GridMap para a
## superfície do som de passo.
##
## É usada em dois momentos: na importação, pelo post_import_kenney.gd, que grava a
## superfície como metadata no corpo de colisão, e em jogo, pelo passos_do_jogador.gd,
## que lê o nome do que está sob o pé. Ficar num arquivo só evita que as duas cópias
## da tabela divirjam. O @tool é necessário porque o script de importação roda no
## editor e chama as funções estáticas daqui.

const PADRAO: StringName = &"grama"

## Trecho do nome em minúsculas para superfície. A primeira entrada que casar vence,
## então a ordem importa: "path_stone" precisa vir antes de "stone", e "watered" antes
## de "soil" para a terra molhada da grade de solo soar como água.
##
## O platform_grass.glb (o nó Piso do playground) toca água de propósito, decisão
## registrada em equipe/pendencias.md.
const POR_TRECHO: Array = [
	["watered", &"agua"],
	["water", &"agua"],
	["river", &"agua"],
	["lake", &"agua"],
	["piso", &"agua"],
	["road", &"asfalto"],
	["driveway", &"asfalto"],
	["sidewalk", &"pedra"],
	["path_stone", &"pedra"],
	["stone", &"pedra"],
	["cliff", &"pedra"],
	["rock", &"pedra"],
	["bridge", &"madeira"],
	["log_", &"madeira"],
	["plank", &"madeira"],
	["fence", &"madeira"],
	["crate", &"madeira"],
	["tree", &"madeira"],
	["building", &"metal"],
	["detail_", &"metal"],
	["tank", &"metal"],
	["silo", &"metal"],
	["ground_path", &"terra"],
	["dirt", &"terra"],
	["soil", &"terra"],
	["platform_grass", &"agua"],
	["ground_grass", &"agua"],
]

## Retorna a superfície do nome, ou PADRAO quando nenhum trecho casa.
static func do_nome(nome: String) -> StringName:
	var nome_minusculo: String = nome.to_lower()
	for par in POR_TRECHO:
		if nome_minusculo.contains(par[0] as String):
			return par[1] as StringName
	return PADRAO

## Diz se algum trecho da tabela casa com o nome, sem cair no valor padrão.
static func reconhece(nome: String) -> bool:
	var nome_minusculo: String = nome.to_lower()
	for par in POR_TRECHO:
		if nome_minusculo.contains(par[0] as String):
			return true
	return false
