# COMP381 · AB1 de Computação Gráfica · UFAL

Jogo em Godot 4 para a AB1 de Computação Gráfica. Tema obrigatório da
disciplina: **Cultura de Alagoas** mais **Ensino Fundamental da Matemática**.
Vale 5,0 pontos. Bruno faz sozinho.

## Prazo e critérios de nota

Entrega **02/10/2026**. A sprint mira **01/10**, um dia antes.

O professor avalia cinco itens, e quatro deles são binários:

1. Modelar objetos
2. Aplicar transformações
3. Interação mouse/teclado
4. Som/música
5. Navegação completa por teclado/mouse

Mais um critério contínuo: *"quanto maior a qualidade e realismo, maior a nota"*.

O professor autorizou **reaproveitar assets** (música, sprites e afins). O
requisito de modelar objetos continua valendo, então a modelagem própria segue
sendo entregável. Atenção a licença: CC0 não exige nada, CC-BY exige crédito.

## O jogo

Runner de pista reta, sem IA e sem pathfinding. O jogador conduz um **cordão de
personagens do folguedo do Guerreiro alagoano** e atravessa portões que aplicam
operações matemáticas sobre a contagem do grupo.

A matemática está na mecânica, não em perguntas sobrepostas. Isso é deliberado e
foi o que Bruno declarou ao professor: o trabalho precisa ter matemática **e**
cultura alagoana integradas, não uma servindo de cenário para a outra.

### Regras dos portões

- Quatro operações básicas. Portão positivo soma ou multiplica, negativo subtrai
  ou divide.
- **Os pares são do mesmo sinal**, dois positivos ou dois negativos, com valores
  que enganam. Misturar sinais mata a escolha: o jogador pega o verde no
  automático e a matemática vira enfeite.
- O que ensina é a **alternância**. Às vezes a multiplicação vence, às vezes a
  soma, conforme o N daquele trecho. Se um lado vencer sempre, o jogador decora e
  para de calcular. O empate entre `×m` e `+s` ocorre em `s = N × (m − 1)`.
- Margem útil entre as opções: **20 a 40 por cento**. O dobro é óbvio demais,
  5 por cento não dói.
- Valores pequenos: `×2`, `×3`, `÷2`, `÷3`. Multiplicador alto estoura o número
  na tela e só a divisão consegue segurar.
- **Divisão é sempre exata.** O gerador escolhe o divisor contra o MDC das
  contagens possíveis, então nunca sobra resto. `Estado.resultado()` continua
  usando piso como rede, mas na prática ela não é exercida, e a divisão não
  mata. Quem mata é subtração.
- **Contagem zero é derrota.**
- Mínimo de **2 segundos de leitura** antes de cada bifurcação, senão o jogo
  testa reflexo em vez de matemática. Hoje o gerador entrega 4 s, derivados da
  velocidade atual.

### Decisão técnica central

A **contagem lógica** é separada da **contagem renderizada**. O número na tela
pode ser 240, mas só cerca de 25 corpos são desenhados, com o raio da formação
escalando por raiz de N. Isso evita `MultiMeshInstance3D`, que não faz animação
esquelética.

O **mestre do guerreiro** fica em primeiro plano, grande, como asset herói
visível o jogo inteiro. É ele que sustenta a nota de qualidade e realismo, e por
isso **nunca é cortado do escopo**. O primeiro corte, se o prazo apertar, é o
detalhe do guerreiro do cordão.

## Modo infinito (implementado no D6, 22/09/2026)

O jogo e um runner **infinito**. Nao ha linha de chegada por padrao: o placar e
a distancia percorrida. A velocidade sobe com a distancia ate um teto.

`scripts/level_generator.gd` gera a pista. Os pares nascem a frente e sao
reciclados por tras; `scripts/ground_follow.gd` desliza o chao junto com o
jogador, o que e invisivel porque a pista nao tem textura.

**Decisoes que custaram medicao, nao refazer sem medir de novo:**

- **Nao ha teto de velocidade.** O jogo e infinito, entao ela escala para
  sempre. `velocidade_maxima = 0` significa sem teto.
- **A rampa conta portoes, nao metros.** Ligada a distancia ela virava
  exponencial no tempo, porque a velocidade crescia com a distancia e a
  distancia crescia com a velocidade. Portao e a unidade de decisao do jogo, e
  da uma rampa linear e previsivel.
- **A escalada de dificuldade NAO esta na velocidade, esta na janela de
  leitura.** Como o espacamento e derivado da velocidade, acelerar sozinho faz
  o portao chegar a cada 4 s para sempre, a 12 ou a 800 de velocidade: muda a
  paisagem, nao o aperto. Quem apertar e `_tempo_leitura()`, que encolhe de 4 s
  para 2 s ao longo dos primeiros 30 portoes e para ali. O piso de 2 s e
  deliberado: abaixo dele o jogo testa reflexo e a matematica deixa de importar.
- **O ritmo de portoes e 1/janela**, independente da velocidade. Depois do
  portao 30 e um portao a cada 2 s, para sempre.
- **O gatilho do portao escala com a velocidade** (`velocidade / 60 * 6`), pelo
  mesmo motivo de nao haver teto: o passo por frame cresce sem limite e um
  gatilho fixo seria atravessado. Verificado a 872 unidades por segundo.
- **Os pares a frente sao decididos contra o CONJUNTO de contagens possiveis**,
  nao contra um numero, porque o jogador ainda vai escolher lados antes de
  chegar neles. Para a divisao fechar exata em qualquer caminho, o divisor
  precisa dividir o MDC do conjunto. Isso vive em `ContagensPossiveis`.
- **Todo par tem um lado PROPORCIONAL e um lado FIXO.** Proporcional multiplica
  ou divide, fixo soma ou subtrai um tanto. A mecanica inteira cabe numa frase
  com esses nomes: qual dos dois vence depende de quantos guerreiros o jogador
  tem, e e por isso que ele precisa contar em vez de decorar um lado.
- **A margem real fica abaixo do alvo.** Medido em 600 portoes, a mediana da
  margem NA CHEGADA e 1.18, nao 1.20 a 1.40, e 275 de 592 caem fora da faixa.
  A causa e a distancia entre decisao e chegada: o portao e calibrado contra a
  media do conjunto possivel, e ate o jogador chegar a contagem real ja se
  afastou dela. Quanto maior o lookahead, pior a deriva.
- **Exatidao da divisao e exigencia; paridade da contagem nao.** Exigir que o
  resultado da divisao tambem fosse par derrubou a divisao para 16 aparicoes em
  600 portoes e degenerou o par negativo em duas subtracoes. A paridade virou
  preferencia dentro de `_divisor_exato()`, nao regra.
- **O gatilho do portao tem 3 de profundidade**, nao a espessura do painel. Com
  velocidade maxima 30 e fisica a 60 Hz o passo por frame chega a 0.5, e um
  gatilho fino seria atravessado sem disparar.
- **O gerador MODELA a contagem futura.** Se algo mudar a contagem por fora
  dele (um reiniciar sem recarregar a cena, por exemplo), os pares ja decididos
  ficam invalidos e um portao de divisao pode passar a deixar resto. Hoje nao
  ocorre, porque reiniciar sempre recarrega a cena inteira e o gerador nasce
  junto. Quem mudar isso precisa refazer a fila do gerador na mesma hora.

**Divida conhecida:** a mistura de operacoes esta desequilibrada. Em soak de 600
portoes: somar 20%, multiplicar 20%, subtrair 47%, dividir 13%. A causa e que
contagem impar se propaga (soma par mantem impar, `x3` mantem impar) e em
contagem alta o par e forcado negativo, sem `x2` para voltar a par, entao trava
em subtracao. As quatro operacoes aparecem, que era o requisito, mas da para
melhorar.

**Modo fase ainda existe:** `distancia_final` maior que zero no `Gerador`
reposiciona a linha de chegada e devolve a tela de vitoria. Zero deixa infinito.

### Ainda nao implementado

**Portao de pedagio:** a cada X portoes, uma barreira com preco em bonecos.

- **Nao pode ser so um par de precos diferentes.** Com 50 bonecos, escolher
  entre pagar 30 ou 10 nao e escolha: pega-se o barato sempre.
- **Vira escolha quando o preco encosta na contagem.** A pergunta passa a ser
  "eu tenho o suficiente?", comparacao de grandeza, conteudo diferente do que os
  portoes de operacao ensinam.
- **Seria o ralo do modo infinito.** Hoje o teto vem de `CONTAGEM_ALTA`, que
  forca pares negativos acima de 400. Funciona, mas e um freio artificial.
- **Pendente:** o que acontece quando nenhum lado e pagavel. Bruno acha que nao
  deveria acontecer.

**Escala do cordao (ideia de Bruno, 24/09, a fazer DEPOIS da modelagem):** o
mestre fica com tamanho fixo e os guerreiros do cordao encolhem conforme a
contagem sobe.

- **Encolher e o meio, nao o fim.** Corpo menor le como "mais longe", nao como
  "mais": e assim que a percepcao funciona. Encolhido demais, o grupo parece se
  afastar e o asset cultural some justamente quando deveria impressionar.
- O ganho real e **caber mais corpo na mesma largura de ponte**. Entao a escala
  deve vir acompanhada de `MAX_VISIVEL` subindo, de 25 para uns 45. O efeito
  combinado e multidao mais densa, nao mais distante.
- **Piso na escala**, algo como 1.0 ate 0.7, nunca menos.
- O mestre com tamanho fixo tambem acerta a hierarquia visual, que e o papel
  dele no folguedo: lidera o cordao.
- **Fazer so depois que o guerreiro estiver modelado.** Com capsula, o ponto em
  que um corpo "some" e chute: depende de silhueta, paleta e chapeu, que ainda
  nao existem.

**HUD com acabamento:** o layout atual e funcional (cantos livres, centro
limpo, separador de milhar) mas cru. Bruno quer um HUD bonito, e decidiu fazer
isso depois de fechar a modelagem do guerreiro, para o visual do HUD conversar
com o do personagem.

**Quantidade de corpos:** fica em 25 ate existir a sprite final do guerreiro.

## Estrutura

Organizada por **categoria**, nao por tipo de arquivo. Cada pasta responde "de
que isso trata?", e o nome dela ja e metade da explicacao.

```
scenes/Main.tscn          raiz: ambiente, sol, chao, jogador, gerador, camera, HUD, UI

scripts/nucleo/           o que todo o resto usa
  game_state.gd           autoload GameState: contagem e as 4 operacoes
  comum.gd                funcoes compartilhadas por mais de um script

scripts/jogador/ e scenes/jogador/
  player_controller.gd    avanco, controle lateral, rampa de velocidade
  crowd_manager.gd        cordao de guerreiros
  camera_follow.gd        camera que persegue o lider
  Player.tscn  Crowd.tscn  Guerreiro.tscn

scripts/pista/ e scenes/pista/
  level_generator.gd      gera e recicla os pares, decide os valores
  contagens_possiveis.gd  o conjunto de contagens que o jogador pode ter
  gate.gd  gate_pair.gd   um portao, e o par exclusivo
  ground_follow.gd        chao infinito
  finish_line.gd          so usada em modo fase
  Gate.tscn  GatePair.tscn  FinishLine.tscn

scripts/interface/ e scenes/interface/
  hud.gd                  contagem e distancia
  ui.gd                   menu, vitoria, derrota
  HUD.tscn  UI.tscn

docs/guerreiro-referencia.md   pesquisa cultural, com fontes
tools/blockout_mestre.py       gera o modelo do mestre
tools/render_preview.py        renderiza previa do blockout
assets/                        .blend, .glb e audio
SPRINT.md                      plano dia a dia, com checkboxes
```

Convenções já estabelecidas no código:

- **Só o líder dispara portões.** O `Player` fica sozinho na collision layer 1.
  Se o cordão inteiro tivesse corpo, o grupo atravessaria os dois portões do par
  ao mesmo tempo e a mecânica quebraria.
- **Controle exclusivo:** teclado **ou** mouse, nunca os dois. Com as duas fontes
  ativas, um esbarrão no mouse disputa o alvo lateral com o teclado. Ver o enum
  `Modo` e `definir_modo()` no `player_controller.gd`.
- No modo mouse o cursor é capturado. Com cursor livre, ao encostar na borda da
  tela o `relative` para de chegar e o controle morre sem aviso.
- A câmera **não é filha** do jogador, persegue com suavização independente de
  framerate (`1 - exp(-k*delta)`). Com `lerp` cru ela fica dura em máquina rápida
  e mole em máquina lenta, e o playtest mediria a máquina, não o jogo.
- Parâmetros de ajuste ficam como `@export`, para calibrar no inspetor com o jogo
  rodando.

## Rodar e validar

**Use sempre a variante `_console` do executável do Godot.** No Windows, o
executável padrão é GUI e não escreve no console: a saída some e erro de parse
passa batido como se estivesse tudo certo.

```bash
# abrir o editor
godot --path .

# validar sem abrir janela: importa e roda N frames, mostrando erros
godot --headless --path . --import
godot --headless --path . --quit-after 200
```

Para testar comportamento sem interface, o padrão que funciona é criar uma cena
`Node` temporária que instancia `Main.tscn` e mede o que interessa, apontar
`run/main_scene` para ela, rodar com `--quit-after`, e depois restaurar. Passar o
caminho da cena como argumento posicional junto com `--path` não funciona.

`Input.action_press()` e `Input.parse_input_event()` funcionam em headless, o que
permite testar input de verdade. O evento sintético de mouse chega com cerca do
dobro do delta, então confie na direção e no sinal, não na magnitude.

## Escrita

**Não usar travessão (—) nem meia-risca (–)** em nada escrito para Bruno: chat,
commits, documentos, comentários de código. Reescrever com vírgula, dois-pontos,
parênteses ou frase separada.

Textos do projeto em português.

## Cuidado cultural

O Guerreiro é folguedo real de Alagoas, com personagens nomeados e indumentária
específica. Conferir caracterização em fonte séria antes de modelar: o professor
é local e percebe erro de folguedo.
