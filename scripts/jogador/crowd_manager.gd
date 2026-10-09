extends Node3D
## Cordao de guerreiros que segue o lider.
##
## A contagem logica do GameState pode ser 240, mas so MAX_VISIVEL corpos sao
## desenhados. O crescimento alem disso aparece como aumento do raio da
## formacao, nao como mais bonecos. Sem essa separacao, a alternativa seria
## MultiMeshInstance3D, que e barato de desenhar mas nao faz animacao
## esqueletica, e no D11 os guerreiros precisam andar.

const MAX_VISIVEL: int = 400
## Angulo aureo. Distribui pontos num disco sem alinhamentos nem sobreposicao,
## que e o que faz o grupo parecer multidao e nao grade.
const ANGULO_AUREO: float = 2.39996323

@export var lider_path: NodePath = ^"../Player"
@export var cena_guerreiro: PackedScene
## Distancia entre vizinhos na espiral, no tamanho cheio.
##
## Era 0.76, a diagonal da caixa do guerreiro. Baixou para a largura dele,
## 0.67, para o grupo ficar mais cheio: na espiral o vizinho raramente esta na
## diagonal exata, entao usar a diagonal era folga demais.
@export var espalhamento_base: float = 0.67
## Tamanho do guerreiro com o cordao pequeno. 1.0 e o tamanho do lider.
@export var escala_maxima: float = 1.0
## Piso do tamanho. Corpo menor que isso le como "mais longe", nao como "mais
## gente", e o asset cultural some.
@export var escala_minima: float = 0.26
## Distancia entre o lider e o guerreiro MAIS PROXIMO dele.
##
## Medir pelo corpo da frente, e nao pelo centro do grupo, e o que mantem o
## espaco constante: o centro precisa recuar quando o cordao engorda, senao a
## metade da frente atropelaria o lider.
@export var folga_atras: float = 0.35
## Altura da vaga. Com o modelo, a origem fica nos pes, entao a vaga e um
## ponto no CHAO, nao o centro do corpo.
@export var altura: float = 0.0
## Quao rapido os corpos perseguem sua vaga na formacao.
@export var velocidade_seguir: float = 9.0
## Ate onde o cordao pode chegar de lado. A ponte tem 12 de largura, entao
## 5.7 deixa o corpo inteiro sobre ela.
@export var meia_largura_util: float = 5.7

var _lider: Node3D = null
var _corpos: Array[Node3D] = []
var _visiveis: int = 0
var _espalhamento: float = 0.76
var _escala_corpo: float = 1.0
var _recuo: float = 1.0


func _ready() -> void:
    # Os corpos sao movidos por script em _process, como a camera.
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    _lider = Comum.achar(self, lider_path, "crowd_manager") as Node3D
    if _lider == null:
        return
    if cena_guerreiro == null:
        push_warning("crowd_manager: cena_guerreiro nao definida.")
        return

    # Pool fixo: os 25 corpos nascem uma vez e depois so acendem e apagam.
    # Instanciar e liberar a cada portao engasga, e portao e coisa frequente.
    for i in MAX_VISIVEL:
        var corpo: Node3D = cena_guerreiro.instantiate()
        add_child(corpo)
        corpo.visible = false
        # Fase propria por corpo: em fase, os 25 andam em passo identico e o
        # cordao vira desfile militar em vez de folguedo.
        var caminhada := corpo.find_child("Caminhada", true, false)
        if caminhada != null:
            # Espalhados por igual pelo ciclo. Aqui, ao contrario da formacao,
            # nao ha vantagem em razao aurea: o numero de corpos e fixo, entao
            # dividir o ciclo em partes iguais ja e o espacamento maximo
            # possivel. Passo fixo de 0.37 fazia os corpos 0 e 11 cairem quase
            # no mesmo ponto e andarem juntos.
            caminhada.definir_fase(2.0 * float(i) / float(MAX_VISIVEL))
        _corpos.append(corpo)

    GameState.contagem_mudou.connect(_on_contagem_mudou)
    _aplicar(GameState.contagem, true)


func _on_contagem_mudou(_anterior: int, novo: int) -> void:
    _aplicar(novo, false)


func _aplicar(contagem: int, instantaneo: bool) -> void:
    _visiveis = clampi(contagem, 0, MAX_VISIVEL)

    # A escala nao vem de uma curva arbitraria: ela e DERIVADA de caber na
    # ponte. Com poucos corpos eles ficam no tamanho cheio e o grupo cresce;
    # a partir do ponto em que a formacao encostaria na borda, os corpos
    # encolhem exatamente o quanto for preciso, e o cordao passa a ocupar a
    # largura inteira em vez de encolher junto.
    #
    # Antes era uma interpolacao por contagem, e ela errava o alvo: com 150
    # guerreiros o grupo media 5.64 de largura, e com 400 media 3.99, porque
    # a escala caia mais rapido do que a contagem subia.
    var passos := sqrt(float(maxi(_visiveis - 1, 1)))
    var cabe := meia_largura_util / (espalhamento_base * passos)
    _escala_corpo = clampf(minf(escala_maxima, cabe), escala_minima, escala_maxima)

    # O espacamento acompanha o tamanho do corpo. Fixo, ou sobraria buraco com
    # os corpos pequenos, ou eles se interpenetrariam no tamanho cheio.
    _espalhamento = espalhamento_base * _escala_corpo
    _recalcular_recuo()

    var centro := _centro_da_formacao()
    for i in MAX_VISIVEL:
        var corpo := _corpos[i]
        if i < _visiveis and not corpo.visible:
            corpo.visible = true
            corpo.global_position = _vaga(i, centro)
            corpo.scale = Vector3.ONE * (_escala_corpo if instantaneo else _escala_corpo * 0.1)
        elif instantaneo:
            # So na montagem inicial o corte e seco. Em jogo, quem some e
            # quem entra passa pela perseguicao de escala do _process.
            corpo.visible = i < _visiveis
            corpo.scale = Vector3.ONE * _escala_corpo


func _process(delta: float) -> void:
    if _lider == null:
        return

    # Centro e ritmo sao iguais para os 25 corpos neste quadro, entao ficam
    # fora do laco. Dentro dele, eram 25 calculos identicos por quadro.
    var centro := _centro_da_formacao()
    # A perseguicao escala com a velocidade do lider: sem isso, o cordao
    # ficaria cada vez mais para tras conforme a corrida acelera.
    var ritmo := velocidade_seguir * maxf(1.0, Comum.velocidade(_lider) / 12.0)

    var passo := Comum.peso(6.0, delta)
    for i in MAX_VISIVEL:
        var corpo := _corpos[i]
        if not corpo.visible:
            continue

        # Quem passou do limite encolhe ate sumir, em vez de apagar de uma vez.
        # Apagar era o que sobrava de piscada: medido, dezenas de guerreiros
        # trocavam para invisivel no mesmo quadro, a 7 unidades da camera.
        var alvo := _escala_corpo if i < _visiveis else 0.0
        corpo.scale = corpo.scale.lerp(Vector3.ONE * alvo, passo)
        if alvo == 0.0 and corpo.scale.x < 0.02:
            corpo.visible = false
            continue

        var vaga := _vaga(i, centro)
        # Quem esta mais atras na formacao persegue mais devagar, o que da
        # elasticidade ao grupo em vez de um bloco rigido preso ao lider.
        var atraso := 1.0 - 0.45 * (float(i) / float(MAX_VISIVEL))
        var peso := Comum.peso(ritmo * atraso, delta)
        # Z EXATO, so o lateral suavizado. Mesmo erro que a camera tinha:
        # suavizacao de primeira ordem fica velocidade dividida pela constante
        # atras do alvo, e a 132 de velocidade isso media 1.83 unidades. Como
        # o avanco e constante, nao ha o que suavizar nele. O lateral sim, e e
        # dali que vem a elasticidade quando o jogador desvia.
        corpo.global_position = Vector3(
            lerpf(corpo.global_position.x, vaga.x, peso),
            vaga.y,
            vaga.z)



## Onde o grupo inteiro esta centrado, ja trazido para dentro da ponte.
##
## Quando o lider vai para a beirada, o cordao desliza para dentro em vez de
## deixar a metade de tras cair da pista.
func _centro_da_formacao() -> Vector3:
    var centro := Comum.posicao_suave(_lider)
    var margem := maxf(meia_largura_util - _raio_maximo(), 0.0)
    centro.x = clampf(centro.x, -margem, margem)
    return centro


## Posicao da vaga `indice` dentro da formacao, em coordenadas globais.
##
## Recebe o centro pronto em vez de calcula-lo: ele e o mesmo para os 25
## corpos, e esta funcao e chamada uma vez por corpo por quadro.
func _vaga(indice: int, centro: Vector3) -> Vector3:
    var angulo := float(indice) * ANGULO_AUREO
    var raio := _espalhamento * sqrt(float(indice))
    return Vector3(
        # O clamp por corpo e rede de seguranca, para o caso de a formacao
        # ficar mais larga que a propria pista.
        clampf(centro.x + cos(angulo) * raio, -meia_largura_util, meia_largura_util),
        altura,
        centro.z + sin(angulo) * raio + _recuo
    )


## Ate onde a formacao chega de lado, a partir do centro dela.
func _raio_maximo() -> float:
    return _espalhamento * sqrt(float(maxi(_visiveis - 1, 0)))


## Recalcula o quanto o grupo recua, para o corpo da frente ficar exatamente
## `folga_atras` atras do lider.
##
## MEDE qual corpo esta mais adiantado, em vez de supor que algum caia bem na
## frente da formacao. Com o angulo aureo isso nao acontece: nenhum indice
## tende a cair em seno igual a menos um, entao assumir isso deixava o cordao
## sobrando varias unidades para tras do que foi pedido.
func _recalcular_recuo() -> void:
    var mais_adiantado := 0.0
    for i in _visiveis:
        var angulo := float(i) * ANGULO_AUREO
        var raio := _espalhamento * sqrt(float(i))
        mais_adiantado = minf(mais_adiantado, sin(angulo) * raio)
    _recuo = folga_atras - mais_adiantado


## O tranco de entrada saiu: quem faz o corpo crescer agora e a mesma
## perseguicao de escala que roda todo quadro, e dois donos para a mesma
## propriedade brigariam.
