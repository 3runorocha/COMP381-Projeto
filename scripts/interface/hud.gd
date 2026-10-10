extends CanvasLayer
## Mostra a contagem logica do cordao e a distancia percorrida.
##
## Contagem centrada no alto, distancia no canto direito, as duas sem placa.
##
## A contagem ficou no centro a pedido de Bruno. Ela mora BEM no alto de
## proposito: os portoes aparecem na metade da tela para baixo, e e por pouco
## que os dois nao disputam espaco. Se algum dia encostarem, o que cede e a
## contagem, porque o portao e o que precisa ser lido para decidir.
##
## Sem placa, o contorno escuro volta a ser obrigatorio: a pista e asfalto
## escuro e o ceu e claro, entao texto branco solto some num dos dois conforme
## o enquadramento.

const COR_SUBIU := Color(0.35, 0.95, 0.5)
const COR_DESCEU := Color(1.0, 0.45, 0.4)
const COR_NEUTRA := Color.WHITE

@export var player_path: NodePath = ^"../Player"

@onready var _rotulo: Label = $Contagem
@onready var _distancia: Label = $Distancia

var _player: Node3D = null

var _tween: Tween = null


func _ready() -> void:
    _player = Comum.achar(self, player_path, "hud") as Node3D
    GameState.contagem_mudou.connect(_on_contagem_mudou)
    _rotulo.text = str(GameState.contagem)
    _ajustar_pivo()


func _on_contagem_mudou(anterior: int, novo: int) -> void:
    _rotulo.text = str(novo)
    _ajustar_pivo()

    if _tween != null and _tween.is_valid():
        _tween.kill()

    # Um tranco de escala mais a cor dizem, sem texto, se o portao ajudou ou
    # atrapalhou. Isso importa porque o jogador esta olhando a pista, nao o HUD.
    var cor := COR_SUBIU if novo > anterior else COR_DESCEU
    _rotulo.modulate = cor
    _rotulo.scale = Vector2.ONE * 1.18

    _tween = create_tween().set_parallel(true)
    _tween.tween_property(_rotulo, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _tween.tween_property(_rotulo, "modulate", COR_NEUTRA, 0.4)


func _process(_delta: float) -> void:
    if _player == null:
        return
    # Sem linha de chegada, a distancia percorrida e o placar da partida.
    _distancia.text = "%s m" % _com_milhar(int(absf(_player.global_position.z)))


## O tranco de escala cresce a partir do canto superior esquerdo.
##
## Com o pivo no centro da caixa, o numero crescia tambem para cima e para a
## esquerda, e saia pela borda da tela: medido, o topo chegava a y = -9.
## O tranco cresce a partir do centro, agora que o numero esta centrado.
func _ajustar_pivo() -> void:
    _rotulo.pivot_offset = _rotulo.size * 0.5


## 23626 vira 23.626. Cinco digitos crus sao dificeis de ler de relance, e de
## relance e o unico jeito que esse numero e lido durante a corrida.
func _com_milhar(valor: int) -> String:
    var texto := str(valor)
    var saida := ""
    var contador := 0
    for i in range(texto.length() - 1, -1, -1):
        saida = texto[i] + saida
        contador += 1
        if contador % 3 == 0 and i > 0:
            saida = "." + saida
    return saida
