extends Node3D
## Balanco das fitas do capacete.
##
## As fitas sao nos separados no modelo, com o pivo no topo, onde encostam no
## capacete. Girar a partir do topo e o que faz a ponta de cima ficar presa e
## so a de baixo se mexer, como fita de verdade.
##
## O movimento tem tres partes somadas:
##   1. uma inclinacao para tras que cresce com a velocidade, porque a corrida
##      nao tem teto e a 200 por hora fita nao fica na vertical;
##   2. uma tremulacao NO MESMO EIXO da inclinacao, ou seja, a fita sobe e
##      desce no vento;
##   3. um empurrao lateral contrario ao desvio do jogador, que e o que liga a
##      animacao ao que ele acabou de fazer no controle.
##
## A tremulacao era, antes, um vai e vem lateral. Ficava mecanico: varrer de um
## lado para o outro e movimento de PENDULO, e fita ao vento nao faz isso. Ela
## ondula na direcao em que esta sendo arrastada.

@export var player_path: NodePath = ^".."
## Amplitude da tremulacao, em graus.
@export var tremulacao_graus: float = 7.0
## Quantas oscilacoes por segundo. Alta de proposito: pano treme rapido.
@export var frequencia: float = 7.5
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
    var vento := clampf(velocidade / velocidade_referencia, 0.0, 1.0)
    var deitar := -deg_to_rad(inclinacao_graus) * vento

    var lateral := 0.0
    if _player != null and "velocity" in _player:
        lateral = -deg_to_rad(reacao_lateral_graus) * clampf(_player.velocity.x / 10.0, -1.0, 1.0)

    var meio := (float(_fitas.size()) - 1.0) * 0.5
    for i in _fitas.size():
        # Fase diferente por fita: em fase, as seis viram uma placa so.
        var fase := float(i) * 0.9
        # Parada, a fita ainda treme um pouco; correndo, treme muito mais.
        var forca := 0.25 + 0.75 * vento
        var tremer := deg_to_rad(tremulacao_graus) * forca * sin(_t * frequencia + fase)
        # Leque fixo, nao animado: as fitas abrem levemente para fora do centro
        # e param de parecer seis copias paralelas da mesma peca.
        var leque := deg_to_rad(3.0) * (float(i) - meio)
        _fitas[i].rotation = Vector3(deitar + tremer, 0.0, lateral + leque)


## Procura recursivamente, porque a hierarquia de um glTF importado depende de
## como o exportador agrupou os objetos, e isso muda sem aviso.
func _coletar(no: Node) -> void:
    for filho in no.get_children():
        if filho is Node3D and filho.name.begins_with("fita"):
            _fitas.append(filho)
        _coletar(filho)
