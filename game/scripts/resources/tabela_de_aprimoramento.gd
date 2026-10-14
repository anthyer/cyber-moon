class_name TabelaDeAprimoramento
extends Resource

## Os números do aprimoramento de armas e ferramentas, num lugar só para balancear.
##
## Todo item começa no nível 1. Cada lista de receitas tem uma receita por subida: a
## primeira leva do nível 1 ao 2, a segunda do 2 ao 3. O nível máximo é o número de
## receitas mais um.

## Receitas das armas. Só o dano muda com o nível.
@export var receitas_de_arma: Array[ReceitaDeAprimoramento] = []
## Receitas das ferramentas de fazenda. O nível aumenta a área que ela alcança.
@export var receitas_de_ferramenta: Array[ReceitaDeAprimoramento] = []
## Por quanto o dano da arma é multiplicado em cada nível, começando do nível 1.
@export var multiplicador_de_dano_por_nivel: Array[float] = [1.0, 1.25, 1.5]
## Quantas vezes o custo de stamina de um quadrado custa cada etapa de área da
## ferramenta: 1 quadrado, 3 em linha, 3 por 3. A área maior sai mais barata por quadrado.
@export var fator_de_stamina_por_etapa: Array[float] = [1.0, 2.0, 5.0]
## Segundos segurando o botão para a área da ferramenta passar à etapa seguinte.
@export var segundos_por_etapa_de_carga: float = 0.45
