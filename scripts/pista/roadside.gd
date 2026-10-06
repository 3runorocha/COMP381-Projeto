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
## Quantos coqueiros por fileira ficam vivos ao mesmo tempo.
##
## Subiu junto com a margem de reciclagem: parte da fileira passa a ser gasta
## atras do jogador, e sem compensar, o fim dela entraria no campo de visao.
@export var por_fileira: int = 19
## Distancia entre um coqueiro e o seguinte, na mesma fileira.
@export var espacamento: float = 13.0
## Afastamento da fileira que fica junto da ciclofaixa. A pista util vai ate 6.4.
@export var afastamento: float = 8.2
## Fileiras extras SO do lado do gramado.
##
## A orla nao e simetrica: do lado do mar e praia aberta, com a fileira da
## calcada e mais nada, e do lado de terra ha mata. Espelhar os dois lados
## apagaria justamente o que faz um lado ser praia e o outro nao.
@export var fileiras_grama: int = 8
## Com nove fileiras, o passo precisa caber dentro do gramado, que vai ate
## x = 46. As copas se sobrepoem de proposito: separadas o bastante para nao
## se tocarem, a mata vira pomar enfileirado.
@export var passo_entre_fileiras: float = 4.4
## Quanto o coqueiro precisa ficar para tras antes de ser reciclado.
##
## Nao basta estar atras da CAMERA. O coqueiro tem 9 de altura e o sol vem de
## cima e de lado, entao a sombra dele continua caindo dentro do quadro bem
## depois de ele proprio ter saido. Reciclando cedo demais, a sombra some de
## repente e o tamanho muda no mesmo instante, e isso aparece como piscada.
@export var margem_atras: float = 48.0

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

    _alcance = float(por_fileira) * espacamento

    # Lado do mar: so a fileira da calcada. Lado do gramado: essa mais as
    # extras, cada uma mais afastada.
    var fileiras: Array[float] = [-afastamento, afastamento]
    for k in fileiras_grama:
        fileiras.append(afastamento + float(k + 1) * passo_entre_fileiras)

    for f in fileiras.size():
        var x_base: float = fileiras[f]
        for i in por_fileira:
            var arvore: Node3D = cena_coqueiro.instantiate()
            add_child(arvore)
            _variar(arvore)
            # Cada fileira sai defasada da anterior, senao os coqueiros ficam
            # em pares alinhados e a orla vira um corredor de portico.
            var recuo := espacamento * (float(f) / float(fileiras.size()))
            arvore.position = Vector3(
                x_base + _rng.randf_range(-0.7, 0.7),
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
        if arvore.global_position.z > z + margem_atras:
            arvore.global_position.z -= _alcance
            _variar(arvore)


## Gira e redimensiona um pouco, para a fileira nao parecer copias do mesmo
## objeto repetidas em intervalo fixo.
func _variar(arvore: Node3D) -> void:
    arvore.rotation.y = _rng.randf_range(0.0, TAU)
    arvore.scale = Vector3.ONE * _rng.randf_range(0.82, 1.18)
