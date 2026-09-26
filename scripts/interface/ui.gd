extends CanvasLayer
## Menu inicial, vitoria e derrota.
##
## Roda com process_mode ALWAYS: os paineis precisam responder enquanto a
## arvore esta pausada, que e como a partida fica parada por tras deles.

@export var player_path: NodePath = ^"../Player"

@onready var _menu: Control = $Menu
@onready var _vitoria: Control = $Vitoria
@onready var _derrota: Control = $Derrota
@onready var _resultado: Label = $Vitoria/Caixa/Resultado
@onready var _placar_derrota: Label = $Derrota/Caixa/Mensagem

var _player: Node = null
## Todos os paineis, para mostrar um significar esconder os outros sem que
## ninguem precise lembrar de apagar cada um na mao.
var _paineis: Array[Control] = []


func _ready() -> void:
    # A cena pode estar recomecando depois de um reload, e o autoload
    # sobrevive ao reload, entao a contagem precisa voltar ao inicio aqui.
    GameState.reiniciar()
    _player = Comum.achar(self, player_path, "ui")

    _paineis = [_menu, _vitoria, _derrota]

    GameState.fim_de_jogo.connect(_on_derrota)
    GameState.vitoria.connect(_on_vitoria)

    $Menu/Caixa/BotaoTeclado.pressed.connect(_comecar.bind(0))
    $Menu/Caixa/BotaoMouse.pressed.connect(_comecar.bind(1))
    for painel in [_vitoria, _derrota]:
        painel.get_node("Caixa/BotaoReiniciar").pressed.connect(_reiniciar)

    _mostrar(_menu)
    $Menu/Caixa/BotaoTeclado.grab_focus()


func _unhandled_input(evento: InputEvent) -> void:
    if not evento.is_action_pressed(&"ui_accept"):
        return
    if _fim_aberto():
        _reiniciar()


## Um painel de fim de partida esta na tela.
func _fim_aberto() -> bool:
    return _vitoria.visible or _derrota.visible


## Mostra um painel e pausa a partida. `nulo` volta ao jogo.
func _mostrar(painel: Control) -> void:
    for outro in _paineis:
        outro.visible = outro == painel

    var pausado := painel != null
    get_tree().paused = pausado

    if pausado:
        # Se a partida estava no modo mouse, o cursor esta capturado e nao da
        # para clicar em botao nenhum.
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _comecar(modo: int) -> void:
    _mostrar(null)
    if _player != null:
        _player.definir_modo(modo)


func _on_vitoria() -> void:
    _resultado.text = "Voce chegou com %d guerreiros, %d metros" % [GameState.contagem, _metros()]
    _mostrar(_vitoria)
    $Vitoria/Caixa/BotaoReiniciar.grab_focus()


func _on_derrota() -> void:
    _placar_derrota.text = "Voce percorreu %d metros" % _metros()
    _mostrar(_derrota)
    $Derrota/Caixa/BotaoReiniciar.grab_focus()


func _reiniciar() -> void:
    # Despausar antes de recarregar: recarregar com a arvore pausada deixa a
    # cena nova parada e sem painel nenhum para despausar.
    get_tree().paused = false
    GameState.reiniciar()
    get_tree().reload_current_scene()


## Distancia percorrida, que no modo infinito e o placar.
func _metros() -> int:
    if _player == null:
        return 0
    return int(absf(_player.global_position.z))
