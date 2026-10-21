class_name ConfiguracaoDeRede
extends Resource

## Onde fica o servidor de repasse e como a conexão com ele é mantida.

## O servidor local de backend/servidor_local/, usado no desenvolvimento.
@export var endereco: String = "ws://localhost:8765"
## O API Gateway WebSocket da AWS (o wss_url que o Pulumi exporta). Só vale no jogo
## exportado para a Web, que não tem servidor local. Vazio, o jogo usa o endereco acima.
@export var endereco_na_nuvem: String = ""
## Tenta conectar sozinho ao abrir o jogo. Sem servidor no ar, o jogo segue offline.
@export var conectar_ao_iniciar: bool = true
## Com a conexão caída, de quanto em quanto tempo tenta de novo.
@export var segundos_entre_tentativas: float = 5.0
## Depois de quanto tempo sem enviar nada o jogo manda um ping. O API Gateway fecha a
## conexão que fica 10 minutos parada. Zero desliga o ping.
@export var segundos_entre_pings: float = 300.0
## Região do User Pool do Cognito, onde ficam as contas dos jogadores (plano 36).
@export var cognito_regiao: String = "sa-east-1"
## O cognito_client_id que o Pulumi exporta. Vazio, o jogo não oferece login e conecta
## sem token, o que só funciona com a chave exigir_login desligada no servidor.
@export var cognito_client_id: String = ""
