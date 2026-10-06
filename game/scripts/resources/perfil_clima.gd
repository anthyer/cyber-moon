class_name PerfilClima
extends Resource

## O que um clima faz no mundo. Como o PerfilEstacao, são ajustes por cima do ciclo do
## dia: o clima multiplica e tinge a luz que a hora e a estação já definiram.

@export var id: StringName = &""
@export var nome_exibido: String = ""
@export var icone: Texture2D
## Se o amanhecer com este clima molha todo o solo arado.
@export var molha_o_solo: bool = false
## Multiplica a cor do sol. Branco não muda nada.
@export var cor_da_luz: Color = Color.WHITE
## Multiplica a energia do sol, do ambiente e do céu.
@export var multiplicador_de_energia: float = 1.0
## Com o céu fechado a sombra do sol fica difusa: mais clara e de borda borrada. Opacidade
## 1 é a sombra cheia do dia de sol, e desfoque 1 é a borda padrão.
@export_range(0.0, 1.0) var opacidade_da_sombra: float = 1.0
@export var desfoque_da_sombra: float = 1.0
## Névoa que encurta o alcance da visão. Zero desliga a névoa.
@export var densidade_da_nevoa: float = 0.0
@export var cor_da_nevoa: Color = Color(0.55, 0.6, 0.7)
## Quantas gotas de chuva caem ao mesmo tempo em volta do jogador. Zero é sem chuva.
@export var quantidade_de_gotas: int = 0
## Com este clima os NPCs não saem de casa.
@export var npcs_ficam_em_casa: bool = false
## Clarão e trovão de tempos em tempos.
@export var tem_raio: bool = false
## Som em loop enquanto o clima dura, e o som do trovão. Vazio não toca nada.
@export var som_ambiente: AudioStream
@export var som_do_trovao: AudioStream
