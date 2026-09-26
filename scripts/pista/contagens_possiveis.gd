class_name ContagensPossiveis
extends RefCounted
## Quantos guerreiros o jogador PODE ter ao chegar num portao ainda distante.
##
## O gerador decide os portoes com varios pares de antecedencia, e ate o
## jogador chegar la ele ainda vai escolher lados. Entao naquele ponto da pista
## nao existe "a contagem": existe um CONJUNTO de contagens possiveis, uma para
## cada caminho que ele pode ter feito.
##
## Isso nao e preciosismo, resolve um problema concreto. Para a divisao nunca
## deixar resto, o divisor precisa dividir TODAS as contagens possiveis, nao so
## uma. Dividir o maximo divisor comum do conjunto e exatamente isso.
##
## O conjunto nao explode porque os dois lados de um par sao calibrados para
## ficar a 20 ou 40 por cento um do outro: a mesma regra que torna a escolha
## interessante mantem os caminhos perto uns dos outros.

var _valores: Array[int] = []


func _init(inicial: int = 1) -> void:
    definir(inicial)


## Recomeca o conjunto a partir de uma contagem conhecida.
func definir(inicial: int) -> void:
    _valores = [maxi(inicial, 1)]


## Avanca o conjunto por um par: cada contagem possivel vira duas.
##
## Caminho que mata o jogador sai do conjunto: se ele morre ali, nao ha portao
## seguinte para planejar.
func avancar(operacoes: Array) -> void:
    var saida: Array[int] = []
    for n in _valores:
        for lado in operacoes:
            var r: int = Estado.resultado(lado[0], lado[1], n)
            if r > 0 and not saida.has(r):
                saida.append(r)
    _valores = saida if not saida.is_empty() else [Estado.CONTAGEM_INICIAL] as Array[int]


## Media do conjunto. E contra ela que os valores do portao sao calibrados.
func media() -> float:
    if _valores.is_empty():
        return float(Estado.CONTAGEM_INICIAL)
    var soma := 0
    for n in _valores:
        soma += n
    return float(soma) / float(_valores.size())


## Menor contagem possivel. Usada para garantir que o lado bom deixe sobreviver.
func minimo() -> int:
    if _valores.is_empty():
        return Estado.CONTAGEM_INICIAL
    var menor: int = _valores[0]
    for n in _valores:
        menor = mini(menor, n)
    return menor


## Maximo divisor comum de todas as contagens possiveis.
##
## Um divisor que divide este numero divide qualquer caminho, e so por isso a
## divisao pode ser prometida exata tres portoes antes de o jogador chegar.
func mdc() -> int:
    if _valores.is_empty():
        return 0
    var g: int = _valores[0]
    for n in _valores:
        g = _mdc_de(g, n)
    return g


static func _mdc_de(a: int, b: int) -> int:
    a = absi(a)
    b = absi(b)
    while b != 0:
        var resto := a % b
        a = b
        b = resto
    return a
