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


func _process(delta: float) -> void:
    if _alvo == null:
        return

    # Suavizacao independente de framerate. Com um lerp cru por delta, a
    # camera fica mais dura em maquina rapida e mais mole em maquina lenta.
    var peso := 1.0 - exp(-suavidade * delta)
    global_position = global_position.lerp(_posicao_desejada(), peso)
    look_at(_alvo_posicao() + Vector3.UP * altura_do_olhar)


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
