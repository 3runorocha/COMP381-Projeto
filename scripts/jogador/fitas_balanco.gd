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
##   2. uma ondulacao presa ao PASSO: o corpo sobe e desce a cada pe que
##      encosta, e a fita chega atrasada nesse movimento;
##   3. um empurrao lateral contrario ao desvio do jogador, que e o que liga a
##      animacao ao que ele acabou de fazer no controle.
##
## Duas tentativas anteriores nao funcionaram, e pelo mesmo motivo de fundo: a
## fita oscilava num relogio proprio, descolado do corpo. Primeiro varrendo de
## lado, que e movimento de PENDULO; depois tremendo numa frequencia fixa, que
## e movimento de MOTOR. O que falta nos dois e a causa: quem mexe a fita e a
## pancada do passo. Agora ela le o ciclo da caminhada, e cada fita entra com
## um atraso proprio, o que faz a onda atravessar o conjunto.

@export var player_path: NodePath = ^".."
## Amplitude da ondulacao, em graus.
@export var ondulacao_graus: float = 9.0
## Atraso de uma fita para a seguinte. E o que faz a onda atravessar o grupo
## em vez de todas subirem juntas.
@export var atraso_entre_fitas: float = 0.45
## Quanto as fitas deitam para tras na velocidade de referencia.
@export var inclinacao_graus: float = 30.0
## Velocidade em que a inclinacao chega ao maximo.
@export var velocidade_referencia: float = 45.0
## Quanto elas jogam para o lado quando o jogador desvia.
@export var reacao_lateral_graus: float = 18.0

var _fitas: Array[Node3D] = []
var _caminhada: Node = null
var _player: Node = null
var _t: float = 0.0


func _ready() -> void:
    _player = get_node_or_null(player_path)
    _coletar(self)
    _caminhada = find_child("Caminhada", true, false)
    if _caminhada == null:
        push_warning("fitas_balanco: sem a caminhada, as fitas ficariam paradas.")
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

    # O corpo sobe DUAS vezes por ciclo de passo, uma a cada pe que encosta,
    # entao a onda da fita corre no dobro da frequencia do ciclo.
    var passo := TAU * _ciclo_do_passo()
    for i in _fitas.size():
        var forca := 0.3 + 0.7 * vento
        var onda := deg_to_rad(ondulacao_graus) * forca * sin(passo - float(i) * atraso_entre_fitas)
        # So para tras. Nao ha leque: abrir as fitas simetricamente para fora
        # do centro montava um cone invertido atras da cabeca, que nao e o que
        # fita pendurada faz.
        _fitas[i].rotation = Vector3(deitar + onda, 0.0, lateral)


## Ciclo da caminhada deste mesmo corpo.
##
## Lido do no irmao em vez de recalculado: duas contas iguais em lugares
## diferentes acabam divergindo, e aqui divergir significa a fita ondular fora
## do passo, que e exatamente o defeito que esta correcao veio consertar.
func _ciclo_do_passo() -> float:
    if _caminhada == null:
        return 0.0
    return _caminhada.ciclo()


## Procura recursivamente, porque a hierarquia de um glTF importado depende de
## como o exportador agrupou os objetos, e isso muda sem aviso.
func _coletar(no: Node) -> void:
    for filho in no.get_children():
        if filho is Node3D and filho.name.begins_with("fita"):
            _fitas.append(filho)
        _coletar(filho)
