extends CanvasLayer
## Mostra a contagem logica do cordao.

const COR_SUBIU := Color(0.35, 0.95, 0.5)
const COR_DESCEU := Color(1.0, 0.45, 0.4)
const COR_NEUTRA := Color.WHITE

@export var player_path: NodePath = ^"../Player"

@onready var _rotulo: Label = $Contagem
@onready var _distancia: Label = $Distancia

var _player: Node3D = null

var _tween: Tween = null


func _ready() -> void:
    _player = get_node_or_null(player_path) as Node3D
    GameState.contagem_mudou.connect(_on_contagem_mudou)
    _rotulo.text = str(GameState.contagem)
    _rotulo.pivot_offset = _rotulo.size * 0.5


func _on_contagem_mudou(anterior: int, novo: int) -> void:
    _rotulo.text = str(novo)
    _rotulo.pivot_offset = _rotulo.size * 0.5

    if _tween != null and _tween.is_valid():
        _tween.kill()

    # Um tranco de escala mais a cor dizem, sem texto, se o portao ajudou ou
    # atrapalhou. Isso importa porque o jogador esta olhando a pista, nao o HUD.
    var cor := COR_SUBIU if novo > anterior else COR_DESCEU
    _rotulo.modulate = cor
    _rotulo.scale = Vector2.ONE * 1.5

    _tween = create_tween().set_parallel(true)
    _tween.tween_property(_rotulo, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _tween.tween_property(_rotulo, "modulate", COR_NEUTRA, 0.4)


func _process(_delta: float) -> void:
    if _player == null:
        return
    # Sem linha de chegada, a distancia percorrida e o placar da partida.
    _distancia.text = "%d m" % int(absf(_player.global_position.z))
