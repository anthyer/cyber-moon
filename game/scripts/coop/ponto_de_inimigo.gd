class_name PontoDeInimigo
extends Marker3D

## Marca onde nasce um inimigo da dungeon, e qual. A cena da dungeon tem um destes por
## inimigo; a ordem deles na cena é o número do inimigo na rede, igual em todos os jogos.

@export var perfil: PerfilInimigo
