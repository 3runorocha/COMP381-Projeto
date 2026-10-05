extends Node3D
## Coqueiros dos dois lados da orla, reciclados como os portoes.
##
## Nao e so enfeite. Sem nada passando de lado, o jogador nao tem referencial
## para perceber velocidade, e a escalada do jogo, que e o coracao da
## dificuldade, fica invisivel. Os coqueiros resolvem isso.
##
## Reciclados pelo mesmo motivo dos portoes: o chao desliza junto com o
## jogador, entao nada pode ficar preso a ele.

@export var cena_coqueiro: PackedScene
## Quantos coqueiros por lado ficam vivos ao mesmo tempo.
@export var por_lado: int = 14
## Distancia entre um coqueiro e o seguinte, no mesmo lado.
@export var espacamento: float = 13.0
## Quanto eles ficam afastados do centro da pista. A pista util vai ate 6.4.
@export var afastamento: float = 8.2

var _player: Node3D = null
var _coqueiros: Array[Node3D] = []
var _alcance: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    _rng.seed = 20261005
    _player = Comum.jogador(get_tree()) as Node3D
    if cena_coqueiro == null:
        push_warning("roadside: cena_coqueiro nao definida.")
        return

    _alcance = float(por_lado) * espacamento
    for lado in [-1.0, 1.0]:
        for i in por_lado:
            var arvore: Node3D = cena_coqueiro.instantiate()
            add_child(arvore)
            _variar(arvore)
            # Os dois lados saem defasados de meio passo, senao os coqueiros
            # ficam em pares simetricos e a orla vira um corredor de portico.
            var recuo := 0.0 if lado < 0.0 else espacamento * 0.5
            arvore.position = Vector3(
                lado * afastamento + _rng.randf_range(-0.5, 0.5),
                0.0,
                -float(i) * espacamento - recuo)
            _coqueiros.append(arvore)


func _process(_delta: float) -> void:
    if _player == null:
        return
    # Interpolada, pelo mesmo motivo da camera e do cordao: a posicao crua
    # anda em degraus de 60 Hz e isso apareceria como tranco no cenario.
    var z := Comum.posicao_suave(_player).z
    for arvore in _coqueiros:
        if arvore.global_position.z > z + espacamento:
            arvore.global_position.z -= _alcance
            _variar(arvore)


## Gira e redimensiona um pouco, para a fileira nao parecer copias do mesmo
## objeto repetidas em intervalo fixo.
func _variar(arvore: Node3D) -> void:
    arvore.rotation.y = _rng.randf_range(0.0, TAU)
    arvore.scale = Vector3.ONE * _rng.randf_range(0.82, 1.18)
