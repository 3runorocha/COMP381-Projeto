extends Node3D
## Caminhada: pernas em pendulo e corpo subindo e descendo.
##
## As pernas sao nos separados no modelo, com o pivo no QUADRIL. Girar pelo
## meio faria a coxa furar a barriga; penduradas do quadril elas balancam como
## pendulo, que e o que o olho espera.
##
## A cadencia vem de Comum.cadencia_passo(), a MESMA funcao que o audio usa
## para disparar o som do passo. Em copias separadas, o pe bateria fora do som.
##
## Cada instancia recebe uma fase propria em definir_fase(). Sem isso os 25
## guerreiros do cordao andam em passo identico e o grupo vira um desfile
## militar em vez de um cordao de folguedo.

@export var player_path: NodePath = ^".."
## Quanto a perna abre, em graus, na frente e atras.
@export var passada_graus: float = 26.0
## Quanto o corpo sobe e desce a cada passo.
@export var altura_do_salto: float = 0.045

var _perna_esq: Node3D = null
var _perna_dir: Node3D = null
var _corpo: Node3D = null
var _altura_base: float = 0.0
var _player: Node = null
var _fase: float = 0.0
var _ciclo: float = 0.0


func _ready() -> void:
    _player = get_node_or_null(player_path)
    # Procura no PAI, nao em si mesmo: este no e um irmao das pecas do modelo,
    # nao o dono delas. Um no so pode ter um script, e o do modelo ja e o das
    # fitas, entao a caminhada vive num no a parte.
    _corpo = get_parent() as Node3D
    _coletar(get_parent())
    if _corpo != null:
        _altura_base = _corpo.position.y
    if _perna_esq == null or _perna_dir == null:
        push_warning("caminhada: nao achei as duas pernas sob %s." % get_parent().name)


## Desloca o ciclo desta instancia, para o cordao nao andar em uniformidade.
func definir_fase(fase: float) -> void:
    _fase = fase


func _process(delta: float) -> void:
    # Avanca em PASSOS, nao em segundos: assim acelerar aperta a passada em vez
    # de so aumentar o deslocamento, e a perna acompanha a corrida.
    _ciclo += Comum.cadencia_passo(Comum.velocidade(_player)) * delta

    var angulo := TAU * (_ciclo + _fase) * 0.5
    var abertura := deg_to_rad(passada_graus) * sin(angulo)
    if _perna_esq != null:
        _perna_esq.rotation.x = abertura
    if _perna_dir != null:
        _perna_dir.rotation.x = -abertura

    # O modelo inteiro sobe duas vezes por ciclo, uma a cada pe que encosta.
    if _corpo != null:
        _corpo.position.y = _altura_base + altura_do_salto * absf(sin(angulo))


func _coletar(no: Node) -> void:
    for filho in no.get_children():
        if filho is Node3D:
            if filho.name.begins_with("perna_esq"):
                _perna_esq = filho
            elif filho.name.begins_with("perna_dir"):
                _perna_dir = filho
        _coletar(filho)
