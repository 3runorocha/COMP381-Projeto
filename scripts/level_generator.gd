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
var _possiveis: Array[int] = []
var _z_frente: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    _rng.randomize()
    _player = Comum.achar(self, player_path, "level_generator") as Node3D
    if _player == null or cena_par == null:
        push_warning("level_generator: falta o jogador ou a cena do par.")
        return

    _configurar_chegada()
    _possiveis = [GameState.contagem]
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
    var base := _media(_possiveis)
    var mdc := _mdc_lista(_possiveis)
    var menor := _minimo(_possiveis)
    var margem := _rng.randf_range(MARGEM_MIN, MARGEM_MAX)
    # Quem vence alterna de proposito. Se a multiplicacao ganhasse sempre, o
    # jogador decora "pega o x" em tres portoes e para de calcular.
    var vence_o_simples := _rng.randf() < 0.5

    var op_forte: Estado.Op
    var val_forte: int
    var op_simples: Estado.Op
    var val_simples: int

    var positivo := _sortear_positivo(base)
    var divisor := -1
    if not positivo:
        divisor = _divisor_exato(mdc)
        # Sem divisor exato, um par negativo vira duas subtracoes, que e o
        # formato mais sem graca possivel. Melhor trocar por um par positivo,
        # a menos que a contagem esteja alta e precise mesmo ser drenada.
        if divisor <= 0 and base <= float(CONTAGEM_ALTA):
            positivo = true

    if positivo:
        var m: int = MULTIPLICADORES[_rng.randi() % MULTIPLICADORES.size()]
        var empate := base * float(m - 1)
        op_forte = Estado.Op.MULTIPLICAR
        val_forte = m
        op_simples = Estado.Op.SOMAR
        val_simples = _valor_par(empate * margem if vence_o_simples else empate / margem, 2)
    else:
        var d := divisor
        if d > 0:
            # A divisao e o lado seguro: com 2d dividindo a contagem, o
            # resultado nunca desce de 2. Quem pode matar e a subtracao.
            var empate := base * float(d - 1) / float(d)
            op_forte = Estado.Op.DIVIDIR
            val_forte = d
            op_simples = Estado.Op.SUBTRAIR
            val_simples = _valor_par(empate / margem if vence_o_simples else empate * margem, 2)
        else:
            # Nenhum divisor fecha exato. Dois lados de subtracao ainda formam
            # um par de mesmo sinal, so e menos interessante.
            var leve := base * 0.3
            op_forte = Estado.Op.SUBTRAIR
            val_forte = _valor_par(leve * margem, 2)
            op_simples = Estado.Op.SUBTRAIR
            val_simples = _valor_par(leve, 2)
            # Com os dois lados subtraindo, o lado leve precisa deixar
            # sobrevivencia, senao a morte vira inevitavel em vez de escolha.
            val_simples = mini(val_simples, maxi(menor - 2, 2))

    if _rng.randf() < 0.5:
        par.configurar(op_forte, val_forte, op_simples, val_simples)
    else:
        par.configurar(op_simples, val_simples, op_forte, val_forte)

    _possiveis = _aplicar_par(_possiveis, par.operacoes())


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


func _recalcular_possiveis() -> void:
    var conjunto: Array[int] = [GameState.contagem]
    for par in _fila:
        conjunto = _aplicar_par(conjunto, par.operacoes())
    _possiveis = conjunto


func _aplicar_par(conjunto: Array[int], operacoes: Array) -> Array[int]:
    var saida: Array[int] = []
    for n in conjunto:
        for lado in operacoes:
            var r: int = Estado.resultado(lado[0], lado[1], n)
            # Caminho que mata nao precisa ser planejado adiante.
            if r > 0 and not saida.has(r):
                saida.append(r)
    if saida.is_empty():
        saida.append(Estado.CONTAGEM_INICIAL)
    return saida


func _media(lista: Array[int]) -> float:
    if lista.is_empty():
        return float(Estado.CONTAGEM_INICIAL)
    var soma := 0
    for n in lista:
        soma += n
    return float(soma) / float(lista.size())


func _minimo(lista: Array[int]) -> int:
    if lista.is_empty():
        return Estado.CONTAGEM_INICIAL
    var menor: int = lista[0]
    for n in lista:
        menor = mini(menor, n)
    return menor


func _mdc_lista(lista: Array[int]) -> int:
    if lista.is_empty():
        return 0
    var g: int = lista[0]
    for n in lista:
        g = _mdc(g, n)
    return g


func _mdc(a: int, b: int) -> int:
    a = absi(a)
    b = absi(b)
    while b != 0:
        var t := b
        b = a % b
        a = t
    return a


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
