extends Area3D
## Um portao. Aplica uma operacao sobre a contagem quando o lider atravessa.
##
## A mask so enxerga a layer 1, onde esta o lider sozinho. Os corpos do cordao
## nao tem colisao, entao nao ha risco de o grupo disparar o portao varias
## vezes nem de acionar os dois lados do par.

## Emitido antes de aplicar a operacao, para o par desativar o irmao a tempo.
signal atravessado(qual: Area3D)

@export var operacao: Estado.Op = Estado.Op.SOMAR:
    set(valor):
        operacao = valor
        _atualizar_visual()
@export var valor: int = 10:
    set(v):
        valor = v
        _atualizar_visual()

const COR_POSITIVA := Color(0.18, 0.72, 0.35)
const COR_NEGATIVA := Color(0.85, 0.24, 0.2)

var _consumido: bool = false
var _material: StandardMaterial3D = null
var _fade: Tween = null

@onready var _placa: Label3D = $Placa
@onready var _painel: MeshInstance3D = $Painel


func _ready() -> void:
    _atualizar_visual()
    body_entered.connect(_on_body_entered)


## Troca operacao e valor de uma vez. Usado pelo gerador ao reciclar.
func configurar(nova_operacao: Estado.Op, novo_valor: int) -> void:
    operacao = nova_operacao
    valor = novo_valor
    _atualizar_visual()


## Engorda ou afina a caixa de gatilho, sem mexer no painel visivel.
##
## Sem teto de velocidade, o passo por frame cresce sem limite: a 180 unidades
## por segundo, a 60 Hz, o corpo anda 3 por frame e atravessaria um gatilho
## fino sem disparar. A forma e compartilhada entre os portoes da cena, o que
## e proposital: todos querem a mesma profundidade.
func ajustar_gatilho(profundidade: float) -> void:
    var forma := $Colisao.shape as BoxShape3D
    if forma != null:
        forma.size.z = maxf(profundidade, 3.0)


## Faz o portao aparecer desvanecendo, em vez de surgir de uma vez.
##
## Reciclar um portao o teleporta para a frente da pista, e com a neblina atual
## ele nasce ainda dentro do campo de visao: aparecia como uma piscada no
## fundo. Afastar o nascimento resolveria, mas custaria lookahead, e lookahead
## maior piora a calibragem dos valores do portao, que ja esta abaixo do alvo.
func surgir(duracao: float = 0.65) -> void:
    if _material == null or _placa == null:
        return
    if _fade != null and _fade.is_valid():
        _fade.kill()
    var opaco := _material.albedo_color
    _material.albedo_color.a = 0.0
    _placa.modulate.a = 0.0
    _fade = create_tween()
    _fade.set_parallel(true)
    _fade.tween_property(_material, "albedo_color:a", opaco.a, duracao)
    _fade.tween_property(_placa, "modulate:a", 1.0, duracao)


## Volta a poder ser acionado, depois de reciclado para a frente da pista.
func rearmar() -> void:
    _consumido = false
    set_deferred(&"monitoring", true)


## Impede que este portao seja acionado. Usado pelo par quando o irmao venceu.
func desativar() -> void:
    _consumido = true
    set_deferred(&"monitoring", false)


func _on_body_entered(_corpo: Node3D) -> void:
    if _consumido:
        return
    _consumido = true
    # Avisa antes de aplicar: o par precisa desativar o irmao no mesmo frame,
    # senao um cordao largo poderia disparar os dois lados.
    atravessado.emit(self)
    GameState.aplicar(operacao, valor)


func _atualizar_visual() -> void:
    if not is_inside_tree():
        return
    var cor := COR_POSITIVA if Estado.e_positiva(operacao) else COR_NEGATIVA
    if _placa != null:
        _placa.text = Estado.texto(operacao, valor)
        _placa.modulate = Color.WHITE
    if _painel != null:
        var material := _painel.get_active_material(0)
        if material is StandardMaterial3D:
            # Guardado porque o fade de surgimento precisa mexer no alfa dele,
            # e cada portao tem a sua copia justamente para nao mexer no alfa
            # de todos ao mesmo tempo.
            _material = material.duplicate()
            _material.albedo_color = Color(cor.r, cor.g, cor.b, 0.45)
            _painel.material_override = _material
