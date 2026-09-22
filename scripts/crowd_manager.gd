extends Node3D
## Cordao de guerreiros que segue o lider.
##
## A contagem logica do GameState pode ser 240, mas so MAX_VISIVEL corpos sao
## desenhados. O crescimento alem disso aparece como aumento do raio da
## formacao, nao como mais bonecos. Sem essa separacao, a alternativa seria
## MultiMeshInstance3D, que e barato de desenhar mas nao faz animacao
## esqueletica, e no D11 os guerreiros precisam andar.

const MAX_VISIVEL: int = 25
## Angulo aureo. Distribui pontos num disco sem alinhamentos nem sobreposicao,
## que e o que faz o grupo parecer multidao e nao grade.
const ANGULO_AUREO: float = 2.39996323

@export var lider_path: NodePath = ^"../Player"
@export var cena_guerreiro: PackedScene
## Distancia entre vizinhos na espiral. Precisa ser maior que o diametro do
## corpo (2 x 0.24 = 0.48), senao os guerreiros se interpenetram.
@export var espalhamento_base: float = 0.55
## Quanto o cordao fica atras do lider.
@export var recuo: float = 3.0
## Altura do centro do corpo dos guerreiros.
@export var altura: float = 0.7
## Quao rapido os corpos perseguem sua vaga na formacao.
@export var velocidade_seguir: float = 9.0

var _lider: Node3D = null
var _corpos: Array[Node3D] = []
var _visiveis: int = 0
var _espalhamento: float = 0.55


func _ready() -> void:
    # Os corpos sao movidos por script em _process, como a camera.
    physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
    _lider = get_node_or_null(lider_path) as Node3D
    if _lider == null:
        push_warning("crowd_manager: lider nao encontrado em '%s'." % lider_path)
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
        _corpos.append(corpo)

    GameState.contagem_mudou.connect(_on_contagem_mudou)
    _aplicar(GameState.contagem, true)


## Quantos corpos estao acesos agora. Usado pelos testes.
func visiveis() -> int:
    return _visiveis


func _on_contagem_mudou(_anterior: int, novo: int) -> void:
    _aplicar(novo, false)


func _aplicar(contagem: int, instantaneo: bool) -> void:
    _visiveis = clampi(contagem, 0, MAX_VISIVEL)

    # A contagem entra no raio pela raiz: dobrar o cordao nao dobra a largura,
    # so a area. E o mesmo que o olho espera de gente se juntando.
    var escala := sqrt(float(maxi(contagem, 1))) / sqrt(float(MAX_VISIVEL))
    # O piso e 1.0 de proposito: espalhamento_base ja vale o diametro do
    # corpo, entao encolher abaixo disso volta a sobrepor os guerreiros.
    _espalhamento = espalhamento_base * clampf(escala, 1.0, 1.25)

    for i in MAX_VISIVEL:
        var corpo := _corpos[i]
        var deve_aparecer := i < _visiveis
        if deve_aparecer and not corpo.visible:
            corpo.visible = true
            corpo.global_position = _vaga(i)
            if not instantaneo:
                _surgir(corpo)
        elif not deve_aparecer and corpo.visible:
            corpo.visible = false


func _process(delta: float) -> void:
    if _lider == null:
        return
    for i in _visiveis:
        var corpo := _corpos[i]
        # Quem esta mais atras na formacao persegue mais devagar, o que da
        # elasticidade ao grupo em vez de um bloco rigido preso ao lider.
        var folga := 1.0 - 0.45 * (float(i) / float(MAX_VISIVEL))
        # A perseguicao escala com a velocidade do lider: sem isso, o cordao
        # ficaria cada vez mais para tras conforme a corrida acelera.
        var ritmo := velocidade_seguir
        if "velocidade_frente" in _lider:
            ritmo *= maxf(1.0, _lider.velocidade_frente / 12.0)
        var peso := 1.0 - exp(-ritmo * folga * delta)
        corpo.global_position = corpo.global_position.lerp(_vaga(i), peso)


## Posicao da vaga `i` na formacao, em coordenadas globais.
func _vaga(indice: int) -> Vector3:
    var angulo := float(indice) * ANGULO_AUREO
    var raio := _espalhamento * sqrt(float(indice))
    # Interpolada, pelo mesmo motivo da camera: ler a posicao crua faria o
    # cordao inteiro tremer junto com o enquadramento.
    var centro := _lider.get_global_transform_interpolated().origin
    return Vector3(
        centro.x + cos(angulo) * raio,
        altura,
        centro.z + sin(angulo) * raio + recuo
    )


## Tranco de escala quando um guerreiro entra, para a mudanca ser visivel.
func _surgir(corpo: Node3D) -> void:
    corpo.scale = Vector3.ONE * 0.2
    var t := create_tween()
    t.tween_property(corpo, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
