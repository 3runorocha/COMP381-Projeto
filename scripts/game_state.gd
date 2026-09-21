class_name Estado
extends Node
## Estado da partida. Registrado como autoload com o nome GameState.
##
## A contagem aqui e a **contagem logica** do cordao: e ela que os portoes
## operam e que aparece no HUD. Quantos corpos sao desenhados na tela e
## problema do crowd_manager, e o numero nao precisa bater.

enum Op {
    SOMAR,
    SUBTRAIR,
    MULTIPLICAR,
    DIVIDIR,
}

## Contagem com que a fase comeca.
const CONTAGEM_INICIAL: int = 10

## Emitido sempre que a contagem muda de valor.
signal contagem_mudou(anterior: int, novo: int)
## Emitido quando a contagem chega a zero.
signal fim_de_jogo
## Emitido quando o jogador cruza a linha de chegada.
signal vitoria

var contagem: int = CONTAGEM_INICIAL

var _acabou: bool = false


## Volta ao estado de inicio de fase.
func reiniciar() -> void:
    var anterior := contagem
    contagem = CONTAGEM_INICIAL
    _acabou = false
    if anterior != contagem:
        contagem_mudou.emit(anterior, contagem)


## Encerra a partida com vitoria. Chamado pela linha de chegada.
##
## Usa a mesma trava do fim por zero: depois que a partida acaba, de um jeito
## ou de outro, portao nenhum mexe mais na contagem.
func concluir() -> void:
    if _acabou:
        return
    _acabou = true
    vitoria.emit()


## Aplica um portao sobre a contagem atual.
func aplicar(op: Op, valor: int) -> void:
    if _acabou:
        return

    var anterior := contagem
    contagem = resultado(op, valor, contagem)

    if contagem != anterior:
        contagem_mudou.emit(anterior, contagem)

    if contagem == 0:
        _acabou = true
        fim_de_jogo.emit()


## Funcao pura: quanto sobra ao aplicar a operacao sobre `n`.
##
## Serve tanto para aplicar de fato quanto para o level design conferir, no
## papel ou em teste, qual lado do par vence em cada trecho da pista.
static func resultado(op: Op, valor: int, n: int) -> int:
    var saida := n
    match op:
        Op.SOMAR:
            saida = n + valor
        Op.SUBTRAIR:
            saida = n - valor
        Op.MULTIPLICAR:
            saida = n * valor
        Op.DIVIDIR:
            # Piso, nao arredondamento: e o que a crianca espera ver, os que
            # sobram simplesmente ficam de fora. Como efeito colateral aceito,
            # 1 dividido por 2 da 0, entao a divisao pode matar direto.
            if valor == 0:
                push_error("Portao de divisao com valor zero.")
                return n
            saida = floori(float(n) / float(valor))
    return maxi(saida, 0)


## True quando a operacao tende a aumentar o cordao.
static func e_positiva(op: Op) -> bool:
    return op == Op.SOMAR or op == Op.MULTIPLICAR


## Texto curto para a placa do portao.
static func texto(op: Op, valor: int) -> String:
    match op:
        Op.SOMAR:
            return "+%d" % valor
        Op.SUBTRAIR:
            return "-%d" % valor
        Op.MULTIPLICAR:
            return "x%d" % valor
        Op.DIVIDIR:
            return "/%d" % valor
    return "?"
