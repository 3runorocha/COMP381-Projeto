extends Node3D
## Coqueiros da orla, em trecho que se repete.
##
## Nao e so enfeite. Sem nada passando de lado, o jogador nao tem referencial
## para perceber velocidade, e a escalada do jogo, que e o coracao da
## dificuldade, fica invisivel.
##
## A versao anterior reciclava coqueiro por coqueiro, movendo cada um para a
## frente quando ficava para tras. Isso piscava: a sombra de um coqueiro de 9
## de altura continua caindo no quadro bem depois de ele proprio sair, e
## reposicionar ali fazia a sombra sumir de repente. Afastar o gatilho so
## diminuiu o problema, nao acabou com ele.
##
## Agora o cenario inteiro e um TRECHO que se repete. Nada se move em relacao
## a nada: so este no desliza, em saltos de exatamente um periodo. Como os
## trechos sao copias identicas, o salto cai sobre geometria igual a que saiu
## do lugar, e nao existe instante em que algo apareca ou desapareca.
##
## Isso exige que os trechos sejam IGUAIS entre si. O sorteio de rotacao e
## escala acontece uma vez, na montagem do primeiro, e e repetido nos demais;
## sorteando por copia, o salto trocaria um coqueiro por outro diferente e o
## problema voltaria com outra cara.

@export var cena_coqueiro: PackedScene
## Comprimento do trecho que se repete.
@export var periodo: float = 130.0
## Quanto o tapete se estende PARA TRAS do ponto de salto.
##
## Precisa ser maior que o periodo mais a folga desejada. O salto move o
## cenario um periodo inteiro de uma vez, entao a cobertura de tras oscila
## nessa mesma amplitude: com 130 de periodo e 130 de cauda, haveria um
## instante, logo apos cada salto, com cobertura zero atras do jogador.
@export var cauda: float = 195.0
## Quanto o tapete se estende para a FRENTE.
@export var alcance: float = 300.0
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
@export var passo_entre_fileiras: float = 4.4

var _player: Node3D = null
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    _rng.seed = 20261005
    _player = Comum.jogador(get_tree()) as Node3D
    if cena_coqueiro == null:
        push_warning("roadside: cena_coqueiro nao definida.")
        return
    _plantar()


func _process(_delta: float) -> void:
    if _player == null:
        return
    # Interpolada, pelo mesmo motivo da camera e do cordao: a posicao crua anda
    # em degraus de 60 Hz, e isso apareceria como tranco no cenario inteiro.
    var z := Comum.posicao_suave(_player).z
    # Salta de periodo em periodo. Deslizar continuamente faria o cenario
    # andar junto com o jogador, que e o oposto do que se quer.
    position.z = floorf(z / periodo) * periodo


## Monta o tapete de coqueiros, com o sorteio repetindo a cada periodo.
##
## Nao ha copias de um trecho: ha uma fileira longa em que a vaga `i` e a vaga
## `i + por_periodo` recebem o MESMO sorteio. E isso que torna o tapete
## periodico, e e a periodicidade que faz o salto ser invisivel: depois de
## andar um periodo, cada vaga esta ocupada por um coqueiro igual ao que
## ocupava aquele ponto antes.
func _plantar() -> void:
    var por_periodo := int(round(periodo / espacamento))
    var vagas := int(ceil((cauda + alcance) / espacamento))

    var fileiras: Array[float] = [-afastamento, afastamento]
    for k in fileiras_grama:
        fileiras.append(afastamento + float(k + 1) * passo_entre_fileiras)

    for f in fileiras.size():
        # Sorteio de um periodo, reaproveitado ao longo de toda a fileira.
        var desvios: Array[float] = []
        var giros: Array[float] = []
        var tamanhos: Array[float] = []
        for i in por_periodo:
            desvios.append(_rng.randf_range(-0.7, 0.7))
            giros.append(_rng.randf_range(0.0, TAU))
            tamanhos.append(_rng.randf_range(0.82, 1.18))

        # Cada fileira sai defasada da anterior, senao os coqueiros ficam em
        # pares alinhados e a orla vira um corredor de portico.
        var recuo := espacamento * (float(f) / float(fileiras.size()))

        for i in vagas:
            var k: int = i % por_periodo
            var arvore: Node3D = cena_coqueiro.instantiate()
            add_child(arvore)
            arvore.position = Vector3(
                fileiras[f] + desvios[k],
                0.0,
                cauda - float(i) * espacamento - recuo)
            arvore.rotation.y = giros[k]
            arvore.scale = Vector3.ONE * tamanhos[k]
