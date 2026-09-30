extends Node
## Autoload Audio: trilha, passos e efeitos dos portoes.
##
## Fica em PROCESS_MODE_ALWAYS porque a musica precisa continuar enquanto a
## arvore esta pausada, que e o estado do menu e das telas de fim.
##
## Os efeitos usam um pool de tocadores em rodizio. Com um tocador so, dois
## sons proximos cortariam um ao outro, e som proximo e o caso normal aqui:
## passo a cada meio segundo mais o portao chegando por cima.

const PASTA := "res://assets/audio/"
const VOZES := 8
## Nomes aceitos para a trilha. Bruno traz o arquivo de banco open source.
const MUSICA := ["musica_loop.ogg", "musica_loop.wav", "musica.ogg", "musica.wav"]

var _musica: AudioStreamPlayer = null
var _vozes: Array[AudioStreamPlayer] = []
var _proxima: int = 0
var _cache: Dictionary = {}

var _player: Node = null
var _ate_o_passo: float = 0.0
var _pe_direito: bool = false


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    _musica = AudioStreamPlayer.new()
    _musica.bus = &"Musica"
    add_child(_musica)
    _tocar_musica()

    for i in VOZES:
        var voz := AudioStreamPlayer.new()
        voz.bus = &"Efeitos"
        add_child(voz)
        _vozes.append(voz)

    GameState.contagem_mudou.connect(_on_contagem_mudou)


func _process(delta: float) -> void:
    _passos(delta)


## Toca um efeito pelo nome do arquivo, sem extensao.
func tocar(nome: String) -> void:
    var fluxo := _carregar(nome + ".wav")
    if fluxo == null:
        return
    var voz := _vozes[_proxima]
    _proxima = (_proxima + 1) % VOZES
    voz.stream = fluxo
    voz.play()


func _on_contagem_mudou(anterior: int, novo: int) -> void:
    # reiniciar() tambem mexe na contagem. Sem esta guarda, recomecar a partida
    # dispararia um som de portao que ninguem atravessou.
    if GameState.portoes_atravessados <= 0:
        return
    tocar("portao_positivo" if novo > anterior else "portao_negativo")


## Passos na cadencia da corrida, com teto.
##
## A cadencia acompanha a velocidade, mas TRAVA: a velocidade nao tem teto, e
## sem limite o passo viraria metralhadora aos 200 por hora. Alterna dois
## arquivos porque passo identico repetido o ouvido acusa na hora.
func _passos(delta: float) -> void:
    if get_tree().paused:
        return
    if _player == null or not is_instance_valid(_player):
        # Por grupo, nao por caminho. Caminho absoluto como /root/Main/Player
        # quebra assim que a cena nao e a raiz, e falha em silencio: o passo
        # simplesmente nunca toca e ninguem descobre por que.
        _player = get_tree().get_first_node_in_group(&"jogador")
        if _player == null:
            return

    var por_segundo := clampf(Comum.velocidade(_player) / 5.0, 2.0, 7.0)
    _ate_o_passo -= delta
    if _ate_o_passo > 0.0:
        return
    _ate_o_passo = 1.0 / por_segundo
    tocar("passo_b" if _pe_direito else "passo_a")
    _pe_direito = not _pe_direito


func _carregar(arquivo: String) -> AudioStream:
    if _cache.has(arquivo):
        return _cache[arquivo]
    var caminho := PASTA + arquivo
    if not ResourceLoader.exists(caminho):
        _cache[arquivo] = null
        return null
    var fluxo: AudioStream = load(caminho)
    _cache[arquivo] = fluxo
    return fluxo


## Procura a trilha entre os nomes aceitos. Sem ela o jogo roda em silencio de
## fundo, so com os efeitos, em vez de quebrar.
func _tocar_musica() -> void:
    for nome in MUSICA:
        var fluxo := _carregar(nome)
        if fluxo != null:
            _musica.stream = _em_loop(fluxo)
            _musica.play()
            return
    push_warning("audio: sem trilha. Ponha um destes em %s: %s" % [PASTA, ", ".join(MUSICA)])


## O importador do Godot traz audio sem loop. Ligar aqui evita depender de um
## ajuste no .import, que se perde se alguem reimportar o arquivo.
func _em_loop(fluxo: AudioStream) -> AudioStream:
    if fluxo is AudioStreamWAV:
        fluxo.loop_mode = AudioStreamWAV.LOOP_FORWARD
        fluxo.loop_begin = 0
    elif fluxo is AudioStreamOggVorbis:
        fluxo.loop = true
    return fluxo
