extends Area3D
## Linha de chegada. So o lider dispara, pela mesma mask dos portoes.

func _ready() -> void:
    body_entered.connect(_on_body_entered)


func _on_body_entered(_corpo: Node3D) -> void:
    GameState.concluir()
