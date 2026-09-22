# Sprint AB1 Computação Gráfica, 17 dias

**Início:** 15/09/2026 (ter) · **Entrega:** 01/10/2026 (qui), um dia antes do prazo oficial.
> **Prazo adiado.** O professor adiou a entrega em cerca de 10 dias. Bruno confirma a data exata na terca, 22/09/2026. Ate la o calendario abaixo segue valendo como ordem das tarefas, nao como datas.

**Stack:** Godot 4, renderer Forward+, GDScript. Modelagem em Blender, export glTF.

## Princípio de ordem

Fase jogável completa primeiro, com placeholder. Modelagem depois.

Se a modelagem atrasar, você ainda entrega um jogo que roda e cumpre quatro dos cinco requisitos. Se a modelagem vier primeiro e estourar, você entrega um boneco e nenhum jogo. Realismo dá nota, mas interação, som e navegação são binários.

**Regra:** nunca terminar o dia com o projeto quebrado.

## Arquitetura alvo

```
Main.tscn (Node3D)
├── WorldEnvironment + DirectionalLight3D
├── Fase1.tscn            (pista, pares de portoes, linha de chegada)
├── Player.tscn           (CharacterBody3D, lider)
│   ├── CollisionShape3D  (layer 1, so o lider dispara portao)
│   ├── MeshInstance3D    (mestre)
│   └── Camera3D          (atras e acima)
├── Crowd.tscn            (Node3D, gerencia o cordao)
└── HUD.tscn              (CanvasLayer)

Autoload: game_state.gd
```

| Script | Responsabilidade |
|---|---|
| `game_state.gd` | contagem, operações, sinais, derrota |
| `player_controller.gd` | avanço constante, entrada lateral, clamp |
| `crowd_manager.gd` | contagem lógica vs renderizada, formação |
| `gate.gd` | um portão, aplica a operação |
| `gate_pair.gd` | par de portões, consome só um |
| `hud.gd` | número na tela, feedback de cor |

## Marcos

| Marco | Dia | Data | Significa |
|---|---|---|---|
| M1 | D6 | 20/09 | **Uma fase completa jogável**, 2 a 3 min, placeholder |
| M2 | D11 | 25/09 | Mestre e guerreiro reais, animados, dentro do jogo |
| M3 | D14 | 28/09 | Som, iluminação e acabamento fechados |
| M4 | D17 | 01/10 | Build testado e enviado |

---

# BLOCO 1 · Fase jogável (D1 a D6)

## D1 · 15/09 ter · Projeto e movimento

- [x] Criar projeto Godot 4, renderer Forward+, resolução e janela definidas
- [x] `Main.tscn`: Node3D raiz, `WorldEnvironment` com céu, `DirectionalLight3D` com sombra
- [x] `Player.tscn`: `CharacterBody3D` + `CollisionShape3D` (cápsula) + `MeshInstance3D` placeholder
- [x] `player_controller.gd`:
  - avanço constante: `velocity.z = -speed`
  - lateral por teclado: `Input.get_axis("ui_left", "ui_right")`
  - lateral por mouse: `InputEventMouseMotion.relative.x` acumulado
  - suavizar com `move_toward(x, alvo_x, lateral_speed * delta)`
  - `clamp(alvo_x, -meia_largura, meia_largura)`
- [x] `Camera3D` atrás e acima, seguindo com `lerp`, não filha rígida, senão treme
- [x] Pista placeholder com `CSGBox3D` longo

**Pronto quando:** percorre a pista inteira, muda de faixa com teclado **e** mouse, câmera não treme.

## D2 · 16/09 qua · GameState e portão

- [x] Autoload `game_state.gd`:
  - `enum Op { ADD, SUB, MUL, DIV }`
  - `var count: int = 1`
  - `signal count_changed(anterior: int, novo: int)`
  - `signal game_over`
- [x] `func apply(op: Op, v: int) -> void` com `match`, e **piso na divisão**: `count = floori(count / float(v))`
- [x] `count = maxi(count, 0)` e emitir `game_over` ao chegar em 0
- [x] `Gate.tscn`: `Area3D` + `CollisionShape3D` + `MeshInstance3D` (plano translúcido) + `Label3D`
- [x] `gate.gd`: `@export var op: GameState.Op` e `@export var value: int`
- [x] `_ready()` escreve o texto na `Label3D` com billboard ligado, e pinta verde ou vermelho pelo sinal
- [x] `body_entered` chama `GameState.apply(op, value)`

**Pronto quando:** atravessar muda o número, inclusive 20 dividido por 3 dando 6.

## D3 · 17/09 qui · Par de portões e HUD

- [x] `GatePair.tscn` com dois `Gate` lado a lado e `gate_pair.gd`
- [x] **Só o líder dispara.** Pôr o `Player` sozinho na collision layer 1 e a mask do portão apenas na 1. Sem isso o cordão atravessa os dois portões e a mecânica quebra.
- [x] Ao consumir um portão, desativar o irmão com `set_deferred` em `monitoring`
- [x] `HUD.tscn`: `CanvasLayer` + `Label` grande, ligado em `count_changed`
- [x] Feedback: `Tween` no número, verde ao subir e vermelho ao descer

**Pronto quando:** o par dispara uma vez só e o HUD reflete na hora.

## D4 · 18/09 sex · Cordão

- [x] `Guerreiro.tscn`: `Node3D` + `MeshInstance3D` placeholder
- [x] `crowd_manager.gd` com `const MAX_VISIBLE := 25` e pool de instâncias, reaproveitando em vez de liberar a cada portão
- [x] `refresh()` ligado em `count_changed`, mostrando `mini(count, MAX_VISIBLE)` corpos
- [x] Formação por ângulo áureo, que distribui sem sobrepor:
  - `ang = i * 2.39996`
  - `raio = spread * sqrt(i)`
  - `spread` proporcional a `sqrt(count)`, para inchar sem renderizar mais
- [x] Cada corpo segue o líder com `lerp` e atraso proporcional ao índice

**Pronto quando:** contagem 240 desenha 25 corpos, o grupo incha visivelmente, sem engasgo.

## D5 · 19/09 sáb · Ciclo completo

- [x] `FinishLine` com `Area3D` no fim da pista
- [x] Tela de vitória com a contagem final
- [x] Tela de derrota ligada em `game_over`
- [x] Reiniciar com tecla, via `reload_current_scene`
- [x] Menu inicial mínimo
- [x] No menu, o jogador escolhe a fonte de controle, teclado **ou** mouse, chamando `definir_modo()` no `Player`

**Pronto quando:** começa, joga, ganha ou perde e reinicia sem fechar o jogo.

## D6 · 20/09 dom · A FASE · MARCO M1

- [x] `Fase1.tscn` com 8 a 12 pares de portões posicionados à mão
- [x] Calibrar cada par pela fórmula de empate, soma igual a N vezes (multiplicador menos 1), com margem de 20 a 40 por cento
- [x] Garantir 2 segundos de leitura antes de cada bifurcação, ou seja, distância igual a velocidade vezes 2
- [x] Alternar qual lado vence, para o jogador não decorar
- [x] Divisor central entre os dois portões do par. Sem ele, com o jogador em `x=0` a cápsula toca os dois e qual lado vence fica arbitrário

**Feito diferente do planejado:** com a decisão do jogo infinito, o D6 virou um
**gerador procedural** em vez de uma fase montada à mão. Os pares nascem à frente e
são reciclados por trás, o espaçamento sai da velocidade atual, e a divisão escolhe
o divisor contra o MDC das contagens ainda possíveis, para nunca deixar resto.
Verificado em soak de 600 portões e em 60 s de movimento real.

---

# BLOCO 2 · Modelagem (D7 a D11)

## D7 · 21/09 seg · Pesquisa cultural e blockout
- [ ] Referência do Guerreiro alagoano: personagens, indumentária, chapéu, paleta
- [ ] Anotar 3 fontes confiáveis. O professor é local e percebe erro de folguedo
- [ ] Decidir quais personagens entram
- [ ] Blender: blockout do mestre, só proporção e silhueta

## D8 · 22/09 ter · Mestre, indumentária
- [ ] Chapéu ornamentado, roupa, fitas, os elementos que dão identidade
- [ ] Manter a contagem de polígonos sob controle

## D9 · 23/09 qua · Mestre, material
- [ ] UV unwrap, textura e material
- [ ] Este é o asset em close o jogo inteiro. É aqui que a nota de realismo é ganha

## D10 · 24/09 qui · Guerreiro do cordão
- [ ] Versão low poly, mesma paleta, será repetida 25 vezes
- [ ] Testar legibilidade da silhueta na distância real de câmera

## D11 · 25/09 sex · Integração · MARCO M2
- [ ] Export glTF, import no Godot, conferir escala e eixos
- [ ] Animação de caminhada via `AnimationPlayer`, podendo vir pronta, já que o reaproveitamento está liberado
- [ ] Substituir os placeholders do `Player` e do `Guerreiro`
- [ ] Dessincronizar a animação por instância com offset aleatório no `seek`, senão os 25 andam como robô

---

# BLOCO 3 · Produção (D12 a D15)

## D12 · 26/09 sáb · Cenário
- [ ] Chão, laterais, céu e props de ambientação
- [ ] Modelar os portões de verdade, no lugar dos planos

## D13 · 27/09 dom · Áudio
- [ ] `AudioStreamPlayer` para a música de fundo
- [ ] Efeitos de portão positivo, portão negativo, derrota e vitória
- [ ] Conferir licença e escrever `CREDITS.md`. CC0 não exige nada, CC-BY exige crédito

## D14 · 28/09 seg · Acabamento · MARCO M3
- [ ] Iluminação, sombras, ajuste de céu e fog no `WorldEnvironment`
- [ ] Materiais e enquadramento final do mestre

## D15 · 29/09 ter · Playtest
- [ ] Alguém de fora joga sem instrução
- [ ] Anotar onde trava e onde a escolha do portão ficou óbvia demais
- [ ] Recalibrar valores

---

# BLOCO 4 · Entrega (D16 a D17)

## D16 · 30/09 qua · Buffer
Reservado para o que atrasou. Se nada atrasou, polimento. **Não planejar nada novo aqui.**

## D17 · 01/10 qui · Entrega
- [ ] Build de release
- [ ] Testar o executável em máquina limpa
- [ ] Texto de entrega e envio

---

## Daily, 10 minutos

1. O que fechou ontem?
2. O que está travando?
3. O que fecha hoje?

**Derrapagem:** atraso come o D16, nunca empurra a tarefa do dia seguinte. Quando o buffer acabar, corta escopo. O primeiro corte é o detalhe do guerreiro do cordão. **O mestre nunca é cortado**, porque é ele que aparece em close.

## Riscos

| Risco | Sinal de alerta | Resposta |
|---|---|---|
| Modelagem estoura | D9 sem o mestre texturizado | Cortar o guerreiro para versão muito simples |
| Nunca abriu Blender | D7 travado | Modelar por CSG dentro do Godot, é legítimo em CG |
| Erro de folguedo | Só aparece na apresentação | Resolvido no D7, com fonte anotada |
| PAA e TCC roubam dias | Dois dias seguidos sem fechar | Usar o buffer cedo e cortar escopo, não virar noite |
