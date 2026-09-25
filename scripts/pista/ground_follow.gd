extends Node3D
## Chao infinito.
##
## Em vez de gerar e reciclar trechos, o chao inteiro acompanha o jogador em Z.
## Como a pista nao tem textura, deslizar o proprio bloco e invisivel e custa
## nada. Se um dia entrar textura ou detalhe no piso, isto precisa virar
## reciclagem de segmentos de verdade, senao o padrao vai parecer colado na
## camera.

@export var player_path: NodePath = ^"../Player"

var _player: Node3D = null


func _ready() -> void:
    _player = Comum.achar(self, player_path, "ground_follow") as Node3D


func _process(_delta: float) -> void:
    if _player == null:
        return
    global_position.z = Comum.posicao_suave(_player).z
