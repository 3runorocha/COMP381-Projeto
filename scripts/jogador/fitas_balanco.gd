extends Node3D
## Balanco das fitas do capacete.
##
## As fitas sao nos separados no modelo, com o pivo no topo, onde encostam no
## capacete. Girar a partir do topo e o que faz a ponta de cima ficar presa e
## so a de baixo se mexer, como fita de verdade.
##
## O movimento tem tres partes somadas, e cada uma responde a uma coisa
## diferente:
##   1. um vai e vem constante, para elas nunca ficarem congeladas;
##   2. uma inclinacao para tras que cresce com a velocidade, porque a corrida
##      nao tem teto e a 200 por hora fita nao fica na vertical;
##   3. um empurrao lateral contrario ao desvio do jogador, que e o que liga a
##      animacao ao que ele acabou de fazer no controle.

@export var player_path: NodePath = ^".."
## Amplitude do vai e vem parado, em graus.
@export var balanco_graus: float = 6.0
## Quantas oscilacoes por segundo.
@export var frequencia: float = 3.2
## Quanto as fitas deitam para tras na velocidade de referencia.
@export var inclinacao_graus: float = 30.0
## Velocidade em que a inclinacao chega ao maximo.
@export var velocidade_referencia: float = 45.0
## Quanto elas jogam para o lado quando o jogador desvia.
@export var reacao_lateral_graus: float = 18.0

var _fitas: Array[Node3D] = []
var _player: Node = null
var _t: float = 0.0


func _ready() -> void:
    _player = get_node_or_null(player_path)
    _coletar(self)
    if _fitas.is_empty():
        push_warning("fitas_balanco: nenhuma fita encontrada sob %s." % name)


func _process(delta: float) -> void:
    _t += delta

    var velocidade := Comum.velocidade(_player)
    var deitar := -deg_to_rad(inclinacao_graus) * clampf(velocidade / velocidade_referencia, 0.0, 1.0)

    var lateral := 0.0
    if _player != null and "velocity" in _player:
        lateral = -deg_to_rad(reacao_lateral_graus) * clampf(_player.velocity.x / 10.0, -1.0, 1.0)

    for i in _fitas.size():
        # Fase diferente por fita: em fase, as seis viram uma placa so.
        var fase := float(i) * 0.7
        var vaivem := deg_to_rad(balanco_graus) * sin(_t * frequencia + fase)
        _fitas[i].rotation = Vector3(deitar, 0.0, vaivem + lateral)


## Procura recursivamente, porque a hierarquia de um glTF importado depende de
## como o exportador agrupou os objetos, e isso muda sem aviso.
func _coletar(no: Node) -> void:
    for filho in no.get_children():
        if filho is Node3D and filho.name.begins_with("fita"):
            _fitas.append(filho)
        _coletar(filho)
