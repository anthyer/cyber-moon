class_name ConfiguracaoDeRede
extends Resource

## Onde fica o servidor de repasse. Hoje é o servidor local de backend/servidor_local/;
## quando a AWS entrar, é só trocar o endereço pelo do API Gateway WebSocket.

@export var endereco: String = "ws://localhost:8765"
## Tenta conectar sozinho ao abrir o jogo. Sem servidor no ar, o jogo segue offline.
@export var conectar_ao_iniciar: bool = true
## Com a conexão caída, de quanto em quanto tempo tenta de novo.
@export var segundos_entre_tentativas: float = 5.0
