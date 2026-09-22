extends Camera3D
## Camera que persegue o lider.
##
## Nao e filha do jogador de proposito. Como filha rigida ela copia cada
## tremida do corpo fisico; perseguindo com suavizacao, o movimento lateral
## fica legivel e a leitura dos portoes nao embaralha.

## No que a camera persegue.
@export var alvo_path: NodePath = ^"../Player"
## Deslocamento em relacao ao alvo. Z positivo fica atras, ja que o jogo corre para -Z.
@export var deslocamento: Vector3 = Vector3(0.0, 5.5, 8.0)
## Altura do ponto para onde a camera olha, acima da base do alvo.
@export var altura_do_olhar: float = 1.6
## Quanto a camera acompanha o lateral do alvo. 1.0 copia, 0.0 ignora.
@export var acompanha_lateral: float = 0.6
## Constante de suavizacao. Maior = mais colada.
@export var suavidade: float = 6.0

var _alvo: Node3D = null


func _ready() -> void:
    # A camera e movida por script em _process, nao pela fisica. Deixar o
    # motor interpolar por cima disso so adicionaria atraso.
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    _alvo = get_node_or_null(alvo_path) as Node3D
    if _alvo == null:
        push_warning("camera_follow: alvo nao encontrado em '%s'." % alvo_path)
        return
    global_position = _posicao_desejada()
    _fixar_orientacao()


func _process(delta: float) -> void:
    if _alvo == null:
        return

    # Suavizacao independente de framerate. Com um lerp cru por delta, a
    # camera fica mais dura em maquina rapida e mais mole em maquina lenta.
    var desejada := _posicao_desejada()
    # So o lateral e suavizado. Suavizacao de primeira ordem tem erro em
    # regime permanente igual a velocidade dividida pela constante: com
    # suavidade 6, a camera fica v/6 atras, ou seja 2 unidades a 12 de
    # velocidade e 17 a 100. Sem teto de velocidade isso fazia o jogador ir
    # encolhendo rumo ao horizonte. Em Z o avanco e constante, entao nao ha
    # nada a suavizar: seguir exato mantem o enquadramento em qualquer
    # velocidade.
    var peso := 1.0 - exp(-suavidade * delta)
    global_position = Vector3(
        lerpf(global_position.x, desejada.x, peso),
        desejada.y,
        desejada.z)


## Inclinacao unica, calculada uma vez, e nunca mais tocada.
##
## A camera NAO gira durante a partida. Com look_at seguindo o jogador, ir
## para o lado girava o enquadramento, o ponto de fuga andava junto e a pista
## parecia tombar. Fixando a orientacao, a pista fica sempre reta e o que se
## mexe e so o deslocamento lateral, que e o que o jogador precisa ler.
func _fixar_orientacao() -> void:
    var ate_o_olhar := Vector3(0.0, altura_do_olhar, 0.0) - deslocamento
    var chao := sqrt(ate_o_olhar.x * ate_o_olhar.x + ate_o_olhar.z * ate_o_olhar.z)
    rotation = Vector3(atan2(ate_o_olhar.y, chao), 0.0, 0.0)


func _posicao_desejada() -> Vector3:
    var alvo := _alvo_posicao()
    var base := alvo + deslocamento
    # A camera so acompanha parte do lateral, para dar sensacao de desvio.
    base.x = alvo.x * acompanha_lateral
    return base


## Posicao do alvo INTERPOLADA entre os passos da fisica.
##
## O jogador anda em _physics_process, travado a 60 Hz. Lendo global_position
## direto, a camera ve o alvo parado durante varios frames de render e depois
## pulando de uma vez: ela alcanca, o alvo salta, ela alcanca de novo. Isso e
## a tela tremendo.
func _alvo_posicao() -> Vector3:
    return _alvo.get_global_transform_interpolated().origin
