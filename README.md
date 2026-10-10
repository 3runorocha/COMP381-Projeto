# Guerreiros

Jogo em Godot 4 para a **AB1 de Computação Gráfica (COMP381), UFAL**.

Tema da disciplina: **Cultura de Alagoas** e **Ensino Fundamental da Matemática**.

Autor: Bruno Rocha. Equipe individual.

---

## O que é

Um *runner* infinito ambientado na **orla de Maceió**. O jogador conduz um
cordão de personagens do folguedo do **Guerreiro alagoano** e atravessa portões
que aplicam operações matemáticas sobre o tamanho do grupo.

A ideia central é que **a matemática está na mecânica, não em perguntas
sobrepostas ao jogo**. Não há tela de quiz: o jogador escolhe entre dois
portões, e a conta é a própria decisão.

### A mecânica em uma frase

> Todo par de portões tem um lado **proporcional** (`×2`, `÷3`) e um lado
> **fixo** (`+40`, `-18`), e qual dos dois vence **depende de quantos
> guerreiros você tem naquele momento**.

É daí que vem o aprendizado: com 10 guerreiros, `+40` ganha de `×2`. Com 60,
`×2` ganha de `+40`. O jogador não consegue decorar um lado, precisa comparar.

---

## Como rodar

Requer **Godot 4** (desenvolvido na 4.7.2).

```bash
godot --path .
```

Depois `F5` para jogar. No menu inicial escolhe-se **teclado** (setas ou A/D)
ou **mouse**; só uma fonte de controle fica ativa por partida.

Para validar sem abrir janela:

```bash
godot --headless --path . --import
godot --headless --path . --quit-after 200
```

No Windows, use a variante `_console` do executável: a padrão é GUI e não
escreve no console, então erro passa batido.

---

## Os cinco requisitos da disciplina

| requisito | onde está |
|---|---|
| **Modelar objetos** | Mestre do Guerreiro, guerreiro do cordão e coqueiro, todos modelados do zero em Blender |
| **Aplicar transformações** | Translação, rotação e escala em tempo real: pernas e braços giram pelo quadril e ombro, fitas ondulam pelo topo, cordão escala conforme a contagem |
| **Interação mouse/teclado** | Controle lateral por setas, A/D ou mouse, escolhido no menu |
| **Som/música** | Efeitos de passo e de portão, sintetizados; trilha em `assets/audio/` |
| **Navegação completa** | A corrida inteira é navegada por teclado ou mouse, do menu à tela de fim |

---

## Pesquisa cultural

O folguedo não é pano de fundo: a pesquisa está em
[`docs/guerreiro-referencia.md`](docs/guerreiro-referencia.md), com fontes.

O achado que definiu o personagem: os chapéus do Guerreiro têm formato de
igrejas e catedrais, e **os do mestre e do contramestre representam as
catedrais**. Por isso o personagem principal usa um capacete de catedral com
três torres e cruz, que é o que o torna reconhecível de longe.

Outras decisões vindas da pesquisa:

- **Fitas caindo atrás da cabeça**, elemento central da indumentária. Como a
  câmera fica atrás do jogador, são elas mais o capacete que formam quase toda
  a silhueta vista durante a partida.
- **Paleta restrita ao azul, branco e vermelho** da bandeira de Alagoas.
- **O índio Peri e a Nação dos Índios não são representados.** São personagens
  reais do folguedo, mas representá-los num jogo infantil pediria um cuidado
  que o prazo não comportava, e errar ali custa mais caro que errar um chapéu.
- **A orla de Maceió como cenário** fecha com o folguedo: o Guerreiro é
  manifestação **de rua**, então um cordão descendo a avenida não é mistura.

---

## Estrutura do projeto

```
scenes/Main.tscn          cena raiz

scripts/nucleo/           o que todo o resto usa
  game_state.gd           contagem e as quatro operações
  comum.gd                funções compartilhadas
  audio.gd                trilha, passos e efeitos

scripts/jogador/ e scenes/jogador/
  player_controller.gd    avanço, controle lateral, rampa de velocidade
  crowd_manager.gd        cordão de guerreiros
  camera_follow.gd        câmera
  caminhada.gd            pernas e braços
  fitas_balanco.gd        ondulação das fitas

scripts/pista/ e scenes/pista/
  level_generator.gd      gera e recicla os pares de portões
  contagens_possiveis.gd  o conjunto de contagens que o jogador pode ter
  gate.gd  gate_pair.gd   um portão e o par exclusivo
  ground_follow.gd        chão infinito
  roadside.gd             coqueiros da orla

scripts/interface/ e scenes/interface/
  hud.gd  ui.gd           contagem, distância, menu e telas de fim

shaders/asfalto.gdshader  faixas da pista
tools/                    scripts de Blender que geram os modelos
docs/                     pesquisa cultural
assets/                   modelos exportados e áudio
```

Cerca de 1.900 linhas de GDScript, organizadas **por categoria** e não por tipo
de arquivo: cada pasta responde "de que isso trata?".

---

## Decisões técnicas que valem explicação

**Os modelos são gerados por script de Blender**, em `tools/`, e não arquivos
binários opacos. As medidas são constantes editáveis e o modelo se regenera.

**A contagem lógica é separada da renderizada.** O número na tela pode ser
20.000, mas no máximo 400 corpos são desenhados. A escala de cada um é
*derivada de caber na ponte*: com poucos eles ficam do tamanho do líder, e
depois que a formação encosta na borda eles encolhem o necessário, de modo que
o cordão passa a ocupar a largura inteira e ficar mais denso.

**A formação usa ângulo áureo.** Distribui os corpos num disco sem alinhamento
nem sobreposição, o que faz o grupo parecer multidão e não grade.

**A divisão nunca deixa resto.** O portão é decidido alguns pares antes de o
jogador chegar nele, e até lá ele ainda vai escolher lados. Então naquele ponto
não existe "a contagem", existe um **conjunto** de contagens possíveis, e o
divisor é escolhido para dividir o máximo divisor comum do conjunto.

**A dificuldade não está na velocidade, está na janela de leitura.** Como o
espaçamento entre portões é derivado da velocidade, acelerar sozinho não aperta
nada. O que aperta é o tempo para decidir, que encolhe de 4 s a 0.9 s ao longo
de 140 portões.

**Câmera e cordão seguem o eixo de avanço de forma exata, suavizando só o
lateral.** Suavização de primeira ordem fica velocidade dividida pela constante
atrás do alvo: a 132 de velocidade isso media 1.83 unidades de atraso por
corpo, e o cordão parecia descolado do líder.

**O cenário é um tapete periódico.** Nada se move em relação a nada: o nó
inteiro salta um período exato sobre geometria idêntica.

---

## Créditos e licenças

| item | origem | licença |
|---|---|---|
| Modelos 3D (mestre, guerreiro, coqueiro) | feitos para este trabalho, gerados pelos scripts em `tools/` | do autor |
| Efeitos sonoros (passos, portões) | sintetizados por `tools/gerar_sons.py` | do autor |
| Trilha sonora | **a preencher** | **a preencher** |

O professor autorizou reaproveitar assets. CC0 não exige nada; CC-BY exige
crédito. Qualquer asset de terceiro que entre no projeto precisa de uma linha
nesta tabela.

---

## Pendências conhecidas

Registradas com honestidade, porque o trabalho continua numa segunda parte.

- **Trilha sonora.** O sistema de áudio já procura o arquivo em
  `assets/audio/` com os nomes `musica_loop.ogg`, `musica_loop.wav`,
  `musica.ogg` ou `musica.wav`, e toca em loop sozinho. Sem ele o jogo roda com
  os efeitos e um aviso no log.
- **Frequência das operações desequilibrada.** Em teste de 600 portões:
  somar 20%, multiplicar 20%, subtrair 47%, dividir 13%. As quatro aparecem,
  mas a mistura podia ser melhor.
- **Margem entre os dois lados do portão abaixo do alvo.** O desenho pedia 20 a
  40 por cento de diferença; a mediana medida na chegada é 18 por cento. A
  causa é a distância entre o momento em que o portão é decidido e o momento em
  que o jogador chega nele.
- **Iluminação e acabamento visual** ficaram deliberadamente para a segunda
  parte: nenhum dos cinco itens avaliados pede iluminação.
- **Portão de pedágio**, uma barreira que custa guerreiros para atravessar,
  projetada mas não implementada.

---

## Como os modelos são regenerados

```bash
blender --background --python tools/blockout_mestre.py
blender --background --python tools/blockout_guerreiro.py
blender --background --python tools/blockout_coqueiro.py
blender --background --python tools/render_preview.py
python tools/gerar_sons.py
```

Os três primeiros escrevem `.glb` em `assets/`. O `render_preview` gera as
imagens de frente e costas do mestre. O `gerar_sons` escreve os `.wav`.
