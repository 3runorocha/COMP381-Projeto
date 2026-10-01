extends Node3D
## Cordao de guerreiros que segue o lider.
##
## A contagem logica do GameState pode ser 240, mas so MAX_VISIVEL corpos sao
## desenhados. O crescimento alem disso aparece como aumento do raio da
## formacao, nao como mais bonecos. Sem essa separacao, a alternativa seria
## MultiMeshInstance3D, que e barato de desenhar mas nao faz animacao
## esqueletica, e no D11 os guerreiros precisam andar.

const MAX_VISIVEL: int = 45
## Angulo aureo. Distribui pontos num disco sem alinhamentos nem sobreposicao,
## que e o que faz o grupo parecer multidao e nao grade.
const ANGULO_AUREO: float = 2.39996323

@export var lider_path: NodePath = ^"../Player"
@export var cena_guerreiro: PackedScene
## Distancia entre vizinhos na espiral, no tamanho cheio. Precisa cobrir a
## maior medida do corpo: o guerreiro e uma CAIXA de 0.67 por 0.35, entao na
## diagonal ele ocupa 0.76, e nao os 0.67 da largura.
@export var espalhamento_base: float = 0.76
## Tamanho do guerreiro com o cordao pequeno. 1.0 e o tamanho do lider.
@export var escala_maxima: float = 1.0
## Tamanho com o cordao cheio. Nao desce mais que isso: corpo pequeno demais
## le como "mais longe", nao como "mais gente", e o asset cultural some.
@export var escala_minima: float = 0.55
## Em quantos corpos a escala chega ao minimo.
@export var corpos_para_escala_minima: int = 40
## Distancia entre o lider e o guerreiro MAIS PROXIMO dele.
##
## Medir pelo corpo da frente, e nao pelo centro do grupo, e o que mantem o
## espaco constante: o centro precisa recuar quando o cordao engorda, senao a
## metade da frente atropelaria o lider.
@export var folga_atras: float = 1.1
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

    # Os guerreiros encolhem conforme o cordao cresce. Encolher aqui e MEIO,
    # nao fim: o ganho e caber mais corpo na mesma largura de ponte. Por isso
    # ha piso na escala, senao o grupo pareceria se afastar em vez de crescer.
    var cheio := float(maxi(corpos_para_escala_minima - 1, 1))
    var quanto := clampf(float(_visiveis - 1) / cheio, 0.0, 1.0)
    _escala_corpo = lerpf(escala_maxima, escala_minima, quanto)

    # O espacamento acompanha o tamanho do corpo. Fixo, ou sobraria buraco com
    # os corpos pequenos, ou eles se interpenetrariam no tamanho cheio.
    _espalhamento = espalhamento_base * _escala_corpo

    var centro := _centro_da_formacao()
    for i in MAX_VISIVEL:
        var corpo := _corpos[i]
        var deve_aparecer := i < _visiveis
        if deve_aparecer and not corpo.visible:
            corpo.visible = true
            corpo.global_position = _vaga(i, centro)
            corpo.scale = Vector3.ONE * _escala_corpo
            if not instantaneo:
                _surgir(corpo)
        elif not deve_aparecer and corpo.visible:
            corpo.visible = false
        elif deve_aparecer:
            # Os que ja estavam na tela tambem mudam de tamanho: a escala
            # depende de QUANTOS sao, entao ela muda para todos a cada portao.
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

    for i in _visiveis:
        var corpo := _corpos[i]
        # Quem esta mais atras na formacao persegue mais devagar, o que da
        # elasticidade ao grupo em vez de um bloco rigido preso ao lider.
        var atraso := 1.0 - 0.45 * (float(i) / float(MAX_VISIVEL))
        var peso := Comum.peso(ritmo * atraso, delta)
        corpo.global_position = corpo.global_position.lerp(_vaga(i, centro), peso)


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
    var recuo := folga_atras + _raio_maximo()
    return Vector3(
        # O clamp por corpo e rede de seguranca, para o caso de a formacao
        # ficar mais larga que a propria pista.
        clampf(centro.x + cos(angulo) * raio, -meia_largura_util, meia_largura_util),
        altura,
        centro.z + sin(angulo) * raio + recuo
    )


## Ate onde a formacao chega, a partir do centro dela.
##
## Conta os corpos que existem AGORA, nao o teto. Usando o teto, um cordao de
## quatro guerreiros reservava espaco para quarenta e cinco e ficava cinco
## unidades atras do lider, com um buraco no meio.
func _raio_maximo() -> float:
    return _espalhamento * sqrt(float(maxi(_visiveis - 1, 0)))


## Tranco de escala quando um guerreiro entra, para a mudanca ser visivel.
func _surgir(corpo: Node3D) -> void:
    var alvo := Vector3.ONE * _escala_corpo
    corpo.scale = alvo * 0.2
    var t := create_tween()
    t.tween_property(corpo, "scale", alvo, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
