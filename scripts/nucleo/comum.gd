class_name Comum
extends Object
## Funcoes compartilhadas por mais de um script.
##
## Cada coisa aqui estava escrita em dois a sete lugares diferentes. Nao e
## utilitario por utilitario: sao as quatro operacoes que varios nos precisam
## fazer igual, e que se fossem divergindo dariam bug silencioso. A posicao
## interpolada e o exemplo claro: se um no lesse a posicao crua e outro a
## interpolada, um tremeria em relacao ao outro.


## Busca um no e avisa no log se nao achar, em vez de estourar depois.
static func achar(dono: Node, caminho: NodePath, quem: String) -> Node:
    var alvo := dono.get_node_or_null(caminho)
    if alvo == null:
        push_warning("%s: nao encontrei o no em '%s'." % [quem, caminho])
    return alvo


## Peso de interpolacao independente da taxa de quadros.
##
## Com um lerp cru por delta, o movimento fica mais duro em maquina rapida e
## mais mole em maquina lenta, e um playtest mediria a maquina, nao o jogo.
static func peso(constante: float, delta: float) -> float:
    return 1.0 - exp(-constante * delta)


## Posicao do no interpolada entre os passos de fisica.
##
## Quem se move em _physics_process anda a 60 Hz travado. Lendo a posicao crua
## de dentro de _process, o alvo fica parado em varios quadros e depois pula, e
## o resultado e a tela tremendo. Medido: 235 de 400 quadros sem avanco algum.
static func posicao_suave(alvo: Node3D) -> Vector3:
    return alvo.get_global_transform_interpolated().origin


## Velocidade de avanco do lider, com valor de seguranca.
##
## A guarda existe porque camera, cordao e gerador funcionam mesmo apontados
## para um no que nao seja o jogador, o que e util em cena de teste.
static func velocidade(alvo: Node, padrao: float = 12.0) -> float:
    if alvo != null and "velocidade_frente" in alvo:
        return alvo.velocidade_frente
    return padrao


## Quantos passos por segundo na velocidade dada.
##
## Tem teto de proposito: a velocidade do jogo nao tem limite, e sem travar a
## cadencia o passo viraria metralhadora e a perna, um ventilador.
##
## Mora aqui porque DUAS coisas dependem dela e precisam concordar: o som do
## passo e o giro da perna. Em copias separadas, o pe bateria fora do som.
static func cadencia_passo(velocidade: float) -> float:
    # Piso em 3, nao em 2: parado, dois passos por segundo lia como arrastar o
    # pe, nao como correr.
    return clampf(velocidade / 5.0, 3.0, 7.0)


## O jogador, achado pelo grupo "jogador".
##
## Por grupo, nunca por caminho. Caminho relativo ja quebrou tres vezes neste
## projeto, e sempre em silencio: o no e encontrado, mas e o errado, cai no
## valor padrao e o bug aparece longe da causa.
static func jogador(arvore: SceneTree) -> Node:
    return arvore.get_first_node_in_group(&"jogador")
