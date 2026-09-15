extends CharacterBody3D
## Lider do cordao.
##
## Avanca sozinho no eixo -Z. O jogador so controla o deslocamento lateral,
## por teclado (setas ou A/D) e por mouse. O corpo fica sozinho na collision
## layer 1: e ele, e so ele, que dispara os portoes. Se o cordao inteiro
## tivesse corpo, o grupo atravessaria os dois portoes do par ao mesmo tempo.

## Velocidade constante de avanco, em unidades por segundo.
@export var velocidade_frente: float = 12.0
## Velocidade maxima do deslocamento lateral.
@export var velocidade_lateral: float = 10.0
## Metade da largura util da pista. O alvo lateral nunca passa disso.
@export var meia_largura_pista: float = 5.0
## Quanto o movimento do mouse desloca o alvo lateral.
@export var sensibilidade_mouse: float = 0.012
## Quao rapido a posicao real persegue o alvo. Maior = mais seco.
@export var suavidade: float = 12.0

## Posicao lateral desejada. A posicao real persegue este valor.
var _alvo_x: float = 0.0


func _ready() -> void:
    _alvo_x = global_position.x


func _unhandled_input(evento: InputEvent) -> void:
    if evento is InputEventMouseMotion:
        _mover_alvo(evento.relative.x * sensibilidade_mouse)


func _physics_process(delta: float) -> void:
    var eixo := Input.get_axis("mover_esquerda", "mover_direita")
    if not is_zero_approx(eixo):
        _mover_alvo(eixo * velocidade_lateral * delta)

    # Controle proporcional: a velocidade lateral e proporcional a distancia
    # que falta para o alvo. Da desaceleracao natural na chegada, sem if.
    var erro := _alvo_x - global_position.x
    velocity.x = clampf(erro * suavidade, -velocidade_lateral, velocidade_lateral)
    velocity.z = -velocidade_frente
    velocity.y = 0.0

    move_and_slide()


## Desloca o alvo lateral e mantem dentro da pista.
func _mover_alvo(quanto: float) -> void:
    _alvo_x = clampf(_alvo_x + quanto, -meia_largura_pista, meia_largura_pista)
