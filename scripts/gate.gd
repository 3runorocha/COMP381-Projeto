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
            var copia: StandardMaterial3D = material.duplicate()
            copia.albedo_color = Color(cor.r, cor.g, cor.b, 0.45)
            _painel.material_override = copia
