extends CharacterBody3D
## Lider do cordao.
##
## Avanca sozinho no eixo -Z. O jogador so controla o deslocamento lateral,
## e escolhe UMA fonte de controle: teclado ou mouse, nunca as duas ao mesmo
## tempo. Com as duas ativas, um esbarrao no mouse disputa o alvo lateral
## com o teclado e o controle fica imprevisivel.
##
## O corpo fica sozinho na collision layer 1: e ele, e so ele, que dispara
## os portoes. Se o cordao inteiro tivesse corpo, o grupo atravessaria os
## dois portoes do par ao mesmo tempo.

enum Modo {
    TECLADO, ## Setas ou A/D. Cursor livre.
    MOUSE,   ## Movimento horizontal do mouse. Cursor capturado, Esc solta.
}

## Fonte de controle ativa. O menu do D5 define isto via definir_modo().
@export var modo: Modo = Modo.TECLADO
## Velocidade de avanco atual, em unidades por segundo. Sobe com a distancia
## e e lida pelo gerador para espacar os portoes.
@export var velocidade_frente: float = 12.0
## Teto da velocidade. Zero significa SEM TETO: o jogo e infinito, entao a
## velocidade escala para sempre.
@export var velocidade_maxima: float = 0.0
## Quanto a velocidade sobe a cada portao atravessado.
@export var ganho_por_portao: float = 1.1
## Velocidade maxima do deslocamento lateral.
@export var velocidade_lateral: float = 10.0
## Metade da largura util da pista. O alvo lateral nunca passa disso.
@export var meia_largura_pista: float = 4.0
## Quanto o movimento do mouse desloca o alvo lateral.
@export var sensibilidade_mouse: float = 0.012
## Quao rapido a posicao real persegue o alvo. Maior = mais seco.
@export var suavidade: float = 12.0

## Posicao lateral desejada. A posicao real persegue este valor.
var _alvo_x: float = 0.0
## Velocidade com que a partida comecou, base da rampa.
var _velocidade_inicial: float = 12.0


func _ready() -> void:
    _velocidade_inicial = velocidade_frente
    _alvo_x = global_position.x
    _aplicar_modo()


## Troca a fonte de controle em tempo de execucao.
func definir_modo(novo: Modo) -> void:
    modo = novo
    _aplicar_modo()


func _unhandled_input(evento: InputEvent) -> void:
    # Esc devolve o cursor, senao nao se sai do jogo no modo mouse.
    if evento.is_action_pressed(&"ui_cancel"):
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        return

    if modo != Modo.MOUSE:
        return

    # Clicar recaptura o cursor depois de um Esc.
    if evento is InputEventMouseButton and evento.pressed:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        return

    if evento is InputEventMouseMotion:
        _mover_alvo(evento.relative.x * sensibilidade_mouse)


func _physics_process(delta: float) -> void:
    _acelerar()

    if modo == Modo.TECLADO:
        var eixo := Input.get_axis(&"mover_esquerda", &"mover_direita")
        if not is_zero_approx(eixo):
            _mover_alvo(eixo * velocidade_lateral * delta)

    # Controle proporcional: a velocidade lateral e proporcional a distancia
    # que falta para o alvo. Da desaceleracao natural na chegada, sem if.
    var erro := _alvo_x - global_position.x
    velocity.x = clampf(erro * suavidade, -velocidade_lateral, velocidade_lateral)
    velocity.z = -velocidade_frente
    velocity.y = 0.0

    move_and_slide()


## Velocidade cresce a cada portao, sem teto.
##
## Quem le isto e o gerador, para esticar o espaco entre portoes na mesma
## proporcao. Sem isso o tempo de leitura encolheria junto com a aceleracao.
func _acelerar() -> void:
    # Por portao, nao por distancia. Ligada a distancia, a rampa virava
    # exponencial no tempo: a velocidade crescia com a distancia e a distancia
    # crescia com a velocidade, entao ela se acelerava sozinha.
    var subida := ganho_por_portao * float(GameState.portoes_atravessados)
    velocidade_frente = _velocidade_inicial + subida
    if velocidade_maxima > 0.0:
        velocidade_frente = minf(velocidade_frente, velocidade_maxima)


## Desloca o alvo lateral e mantem dentro da pista.
func _mover_alvo(quanto: float) -> void:
    _alvo_x = clampf(_alvo_x + quanto, -meia_largura_pista, meia_largura_pista)


## No modo mouse o cursor precisa ser capturado: com o cursor livre, ao
## encostar na borda da tela o evento de movimento relativo para de chegar
## e o controle morre sem aviso.
func _aplicar_modo() -> void:
    if DisplayServer.get_name() == "headless":
        return
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if modo == Modo.MOUSE else Input.MOUSE_MODE_VISIBLE
