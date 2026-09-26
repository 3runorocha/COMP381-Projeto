extends Node3D
## Gera a pista infinita: os pares nascem a frente e sao reciclados por tras.
##
## Invariante central: a contagem e SEMPRE PAR. A contagem inicial e par, soma
## e subtracao so usam valores pares, multiplicacao preserva paridade, e a
## divisao por d so e permitida quando 2d divide a contagem. Assim a divisao
## nunca deixa resto e o resultado continua par. Isso dispensa qualquer portao
## corretor de paridade.
##
## Os pares a frente sao decididos contra o CONJUNTO de contagens ainda
## possiveis, nao contra um numero unico, porque o jogador ainda vai escolher
## lados antes de chegar neles. Para a divisao fechar exata em qualquer
## caminho, o divisor precisa dividir o MDC do conjunto.

@export var player_path: NodePath = ^"../Player"
@export var cena_par: PackedScene
## Quantos pares ficam vivos na pista ao mesmo tempo.
@export var pares_ativos: int = 3
## Segundos de viagem entre um par e o seguinte. O espacamento em unidades sai
## da velocidade atual: com a velocidade subindo, distancia fixa encolheria o
## tempo de leitura e o jogo viraria teste de reflexo.
@export var tempo_entre_pares: float = 4.0
## Piso da janela de leitura. Abaixo disto o jogo testa reflexo, nao
## matematica, e a mecanica inteira perde o sentido.
@export var tempo_minimo_entre_pares: float = 2.0
## Em quantos portoes a janela vai do inicial ao minimo.
@export var portoes_ate_tempo_minimo: int = 30
@export var espacamento_minimo: float = 25.0
## Distancia total em modo fase. Zero deixa o jogo infinito.
@export var distancia_final: float = 0.0
@export var finish_path: NodePath = ^"../FinishLine"

const MULTIPLICADORES: Array[int] = [2, 3]
const DIVISORES: Array[int] = [2, 3]
## Margem entre os dois lados. Menos que isto nao doi, mais que isto e obvio.
const MARGEM_MIN: float = 1.20
const MARGEM_MAX: float = 1.40
## Abaixo disto o par e forcado positivo, para o jogador ter como voltar.
const CONTAGEM_BAIXA: int = 12
## Acima disto o par e forcado negativo, senao o numero estoura.
const CONTAGEM_ALTA: int = 400

var _player: Node3D = null
var _fila: Array[Node3D] = []
var _possiveis := ContagensPossiveis.new()
var _z_frente: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    _rng.randomize()
    _player = Comum.achar(self, player_path, "level_generator") as Node3D
    if _player == null or cena_par == null:
        push_warning("level_generator: falta o jogador ou a cena do par.")
        return

    _configurar_chegada()
    _possiveis.definir(GameState.contagem)
    _z_frente = _player.global_position.z

    for i in pares_ativos:
        var par: Node3D = cena_par.instantiate()
        add_child(par)
        par.consumido.connect(_on_par_consumido)
        _posicionar_a_frente(par)
        _decidir(par)
        _fila.append(par)


func _process(_delta: float) -> void:
    if _player == null or _fila.is_empty():
        return
    # Rede de seguranca: se por algum motivo um par ficou para tras sem ser
    # consumido, recicla assim mesmo, senao a fila trava e a pista acaba.
    var primeiro: Node3D = _fila[0]
    if primeiro.global_position.z > _player.global_position.z + 10.0:
        _reciclar(primeiro)


func _on_par_consumido(par: Node3D) -> void:
    # Adiado de proposito: mover um Area3D de lugar dentro do proprio
    # body_entered dele e pedir problema.
    _reciclar.call_deferred(par)


func _reciclar(par: Node3D) -> void:
    if not _fila.has(par):
        return
    _fila.erase(par)
    # A contagem real ja e conhecida, entao o conjunto possivel pode ser
    # refeito do zero simulando so os pares que continuam a frente.
    _recalcular_possiveis()
    par.rearmar()
    _posicionar_a_frente(par)
    _decidir(par)
    _fila.append(par)


func _posicionar_a_frente(par: Node3D) -> void:
    _z_frente -= _espacamento()
    par.global_position = Vector3(0.0, 0.0, _z_frente)
    # Gatilho proporcional ao passo por frame, ja que a velocidade nao tem teto.
    par.ajustar_gatilho(_velocidade() / 60.0 * 6.0)


func _espacamento() -> float:
    return maxf(espacamento_minimo, _velocidade() * _tempo_leitura())


func _velocidade() -> float:
    return Comum.velocidade(_player)


## Janela de leitura, que encolhe conforme os portoes passam.
##
## Aqui e que mora a escalada de dificuldade. Velocidade sozinha nao aperta
## nada: com o espacamento derivado dela, o portao chegaria a cada 4 segundos
## para sempre, a 12 ou a 200 de velocidade. O que aperta e o tempo para
## decidir, e ele tem piso, senao vira jogo de reflexo.
func _tempo_leitura() -> float:
    var progresso := clampf(
        float(GameState.portoes_atravessados) / float(maxi(portoes_ate_tempo_minimo, 1)),
        0.0, 1.0)
    return lerpf(tempo_entre_pares, tempo_minimo_entre_pares, progresso)


func _decidir(par: Node3D) -> void:
    var margem := _rng.randf_range(MARGEM_MIN, MARGEM_MAX)
    # Quem vence alterna de proposito. Se o mesmo lado ganhasse sempre, o
    # jogador decora em tres portoes e para de calcular.
    var fixo_vence := _rng.randf() < 0.5
    var lados := _sortear_lados(margem, fixo_vence)

    # De que lado da pista cada um fica tambem e sorteado, senao o jogador
    # aprende a posicao em vez de aprender a conta.
    if _rng.randf() < 0.5:
        par.configurar(lados[0], lados[1], lados[2], lados[3])
    else:
        par.configurar(lados[2], lados[3], lados[0], lados[1])

    _possiveis.avancar(par.operacoes())


## Escolhe o tipo de par e devolve [op proporcional, valor, op fixa, valor].
##
## Todo par tem um lado PROPORCIONAL, que multiplica ou divide, e um lado FIXO,
## que soma ou subtrai um tanto. A mecanica inteira do jogo cabe numa frase com
## esses dois nomes: qual dos dois lados vence depende de quantos guerreiros o
## jogador tem naquele momento, e e por isso que ele precisa fazer a conta em
## vez de decorar um lado.
func _sortear_lados(margem: float, fixo_vence: bool) -> Array:
    var base := _possiveis.media()

    if _sortear_positivo(base):
        return _par_positivo(base, margem, fixo_vence)

    var divisor := _divisor_exato(_possiveis.mdc())
    if divisor > 0:
        return _par_com_divisao(base, divisor, margem, fixo_vence)

    # Sem divisor exato o par negativo viraria duas subtracoes, que e o formato
    # mais sem graca possivel. Com a contagem ainda administravel, vale mais
    # trocar por um par positivo.
    if base <= float(CONTAGEM_ALTA):
        return _par_positivo(base, margem, fixo_vence)
    return _par_de_subtracoes(base, margem)


## Multiplicar contra somar. Os dois lados empatam quando s = N x (m - 1).
func _par_positivo(base: float, margem: float, fixo_vence: bool) -> Array:
    var m: int = MULTIPLICADORES[_rng.randi() % MULTIPLICADORES.size()]
    var empate := base * float(m - 1)
    return [
        Estado.Op.MULTIPLICAR, m,
        Estado.Op.SOMAR, _calibrar(empate, margem, fixo_vence, true),
    ]


## Dividir contra subtrair. Os dois lados empatam quando s = N x (d - 1) / d.
##
## Aqui a divisao e o lado seguro: sendo exata, o resultado nunca chega a zero.
## Quem pode matar o jogador e a subtracao.
func _par_com_divisao(base: float, divisor: int, margem: float, fixo_vence: bool) -> Array:
    var empate := base * float(divisor - 1) / float(divisor)
    return [
        Estado.Op.DIVIDIR, divisor,
        Estado.Op.SUBTRAIR, _calibrar(empate, margem, fixo_vence, false),
    ]


## Ultimo recurso: dois lados de subtracao.
##
## So acontece quando nenhum divisor fecha exato E a contagem esta alta demais
## para um par positivo, ou seja, quando o cordao precisa mesmo ser drenado.
func _par_de_subtracoes(base: float, margem: float) -> Array:
    var leve := base * 0.3
    # O lado mais leve precisa deixar sobrevivencia, senao a morte vira
    # inevitavel em vez de escolha.
    var sobra := maxi(_possiveis.minimo() - 2, 2)
    return [
        Estado.Op.SUBTRAIR, _valor_par(leve * margem, 2),
        Estado.Op.SUBTRAIR, mini(_valor_par(leve, 2), sobra),
    ]


## Valor do lado fixo, calculado a partir do ponto de empate.
##
## Uma funcao so atende soma e subtracao porque a unica diferenca entre elas e
## o sentido: somando, numero maior e melhor; subtraindo, menor e melhor. Duas
## funcoes quase identicas seriam mais codigo para dizer a mesma coisa.
func _calibrar(empate: float, margem: float, deve_vencer: bool, maior_e_melhor: bool) -> int:
    var fator := margem if deve_vencer == maior_e_melhor else 1.0 / margem
    return _valor_par(empate * fator, 2)


func _sortear_positivo(base: float) -> bool:
    if base < float(CONTAGEM_BAIXA):
        return true
    if base > float(CONTAGEM_ALTA):
        return false
    return _rng.randf() < 0.58


## Divisor que fecha exato em QUALQUER caminho ainda possivel.
##
## Exigir que o resultado tambem continuasse par (2d dividindo o MDC) parecia
## mais seguro, mas na pratica matava a divisao: com varios pares decididos a
## frente, o conjunto possivel cresce e o MDC colapsa para 2. Medido em soak de
## 600 portoes, a divisao caia para 16 aparicoes e o par negativo degenerava em
## duas subtracoes. Exatidao e o que foi pedido; paridade era so o meio.
func _divisor_exato(mdc: int) -> int:
    if mdc <= 0:
        return -1
    var candidatos := DIVISORES.duplicate()
    candidatos.shuffle()
    # Primeira passada prefere divisor que deixa o resultado par. Nao e
    # exigencia, e estrategia: resultado par mantem o MDC par e a divisao
    # continua disponivel nos portoes seguintes. Exigir isso matava a divisao;
    # preferir isso a mantem viva.
    for d in candidatos:
        if mdc % (2 * d) == 0:
            return d
    for d in candidatos:
        if mdc % d == 0:
            return d
    return -1


## Arredonda para um par, nunca abaixo do minimo. Valor par e o que mantem a
## contagem par e, por consequencia, a divisao sem resto.
func _valor_par(x: float, minimo: int) -> int:
    var v := int(round(x / 2.0)) * 2
    return maxi(v, minimo)



## Refaz o conjunto de contagens possiveis a partir da contagem real de agora,
## simulando os pares que ainda estao a frente.
func _recalcular_possiveis() -> void:
    _possiveis.definir(GameState.contagem)
    for par in _fila:
        _possiveis.avancar(par.operacoes())



## Com distancia_final maior que zero o jogo volta a ter fim, para comparar com
## o modo infinito sem precisar desfazer nada.
func _configurar_chegada() -> void:
    var chegada := Comum.achar(self, finish_path, "level_generator") as Area3D
    if chegada == null:
        return
    if distancia_final > 0.0:
        chegada.global_position.z = -distancia_final
        chegada.visible = true
        chegada.monitoring = true
    else:
        chegada.visible = false
        chegada.monitoring = false
