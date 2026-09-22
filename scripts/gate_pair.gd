extends Node3D
## Par de portoes lado a lado. Garante que so um seja consumido.
##
## Os dois lados devem ter o MESMO sinal, dois positivos ou dois negativos.
## Misturar sinais mata a escolha: o jogador pega o verde no automatico e a
## matematica vira enfeite.

## Emitido depois que um dos dois lados foi consumido.
signal consumido(par: Node3D)


func _ready() -> void:
    for portao in _portoes():
        portao.atravessado.connect(_on_atravessado)
    _conferir_sinais()


func _on_atravessado(vencedor: Area3D) -> void:
    for portao in _portoes():
        if portao != vencedor:
            portao.desativar()
    consumido.emit(self)


## Define os dois lados de uma vez. Chamado pelo gerador.
func configurar(op_esq: Estado.Op, val_esq: int, op_dir: Estado.Op, val_dir: int) -> void:
    var lados := _portoes()
    if lados.size() != 2:
        return
    lados[0].configurar(op_esq, val_esq)
    lados[1].configurar(op_dir, val_dir)


## Operacoes atuais, na ordem esquerda e direita, para o gerador simular.
func operacoes() -> Array:
    var saida: Array = []
    for portao in _portoes():
        saida.append([portao.operacao, portao.valor])
    return saida


## Devolve os dois lados ao estado acionavel.
func rearmar() -> void:
    for portao in _portoes():
        portao.rearmar()


func _portoes() -> Array[Area3D]:
    var lista: Array[Area3D] = []
    for filho in get_children():
        if filho is Area3D:
            lista.append(filho)
    return lista


## Avisa no editor e no log se o par ficou com sinais trocados.
func _conferir_sinais() -> void:
    var portoes := _portoes()
    if portoes.size() != 2:
        push_warning("%s: par com %d portoes, esperado 2." % [name, portoes.size()])
        return
    var a: bool = Estado.e_positiva(portoes[0].operacao)
    var b: bool = Estado.e_positiva(portoes[1].operacao)
    if a != b:
        push_warning("%s: par com sinais misturados. A escolha fica obvia." % name)
