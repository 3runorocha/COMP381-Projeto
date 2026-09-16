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
- **Divisão arredonda para baixo.** Consequência aceita: `1 ÷ 2 = 0`, então a
  divisão pode matar direto.
- **Contagem zero é derrota.**
- Cerca de **2 segundos de leitura** antes de cada bifurcação, senão o jogo testa
  reflexo em vez de matemática.

### Decisão técnica central

A **contagem lógica** é separada da **contagem renderizada**. O número na tela
pode ser 240, mas só cerca de 25 corpos são desenhados, com o raio da formação
escalando por raiz de N. Isso evita `MultiMeshInstance3D`, que não faz animação
esquelética.

O **mestre do guerreiro** fica em primeiro plano, grande, como asset herói
visível o jogo inteiro. É ele que sustenta a nota de qualidade e realismo, e por
isso **nunca é cortado do escopo**. O primeiro corte, se o prazo apertar, é o
detalhe do guerreiro do cordão.

## Estrutura

```
scenes/Main.tscn      raiz: ambiente, sol, pista, player, camera
scenes/Player.tscn    CharacterBody3D, líder, collision layer 1
scripts/player_controller.gd
scripts/camera_follow.gd
SPRINT.md             plano dia a dia, com checkboxes
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
