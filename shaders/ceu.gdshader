shader_type sky;
// Ceu da orla: degrade mais nuvens procedurais.
//
// Procedural e nao imagem, porque assim nao depende de baixar nada nem de
// licenca de terceiros, e o visual se ajusta por numero.

uniform vec3 cor_topo : source_color = vec3(0.13, 0.42, 0.82);
uniform vec3 cor_horizonte : source_color = vec3(0.76, 0.88, 0.96);
uniform vec3 cor_nuvem : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cor_sombra_nuvem : source_color = vec3(0.72, 0.78, 0.86);
// Quanto maior, menos nuvem.
uniform float cobertura = 0.52;
uniform float escala = 1.6;
uniform float velocidade = 0.006;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
    vec2 celula = floor(p);
    vec2 dentro = fract(p);
    // Suavizacao cubica, para a nuvem nao ficar com cara de xadrez.
    vec2 t = dentro * dentro * (3.0 - 2.0 * dentro);
    float a = hash(celula);
    float b = hash(celula + vec2(1.0, 0.0));
    float c = hash(celula + vec2(0.0, 1.0));
    float d = hash(celula + vec2(1.0, 1.0));
    return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
}

float camadas(vec2 p) {
    float soma = 0.0;
    float peso = 0.5;
    for (int i = 0; i < 5; i++) {
        soma += peso * ruido(p);
        p *= 2.03;
        peso *= 0.5;
    }
    return soma;
}

void sky() {
    float altura = clamp(EYEDIR.y, 0.0, 1.0);
    vec3 cor = mix(cor_horizonte, cor_topo, pow(altura, 0.55));

    if (EYEDIR.y > 0.01) {
        // Projeta a direcao do olhar num plano la em cima. A divisao por y faz
        // a nuvem se achatar perto do horizonte, que e o que a perspectiva de
        // verdade faz.
        vec2 uv = EYEDIR.xz / (EYEDIR.y + 0.22) * escala;
        uv += vec2(TIME * velocidade, TIME * velocidade * 0.4);

        float n = camadas(uv);
        float massa = smoothstep(cobertura, cobertura + 0.22, n);
        // Desbota perto do horizonte, senao a nuvem bate na linha do mar.
        massa *= smoothstep(0.01, 0.22, EYEDIR.y);

        // Uma segunda camada mais densa vira a sombra por baixo da nuvem.
        float nucleo = smoothstep(cobertura + 0.12, cobertura + 0.30, n);
        vec3 tom = mix(cor_sombra_nuvem, cor_nuvem, nucleo);
        cor = mix(cor, tom, massa);
    }

    COLOR = cor;
}
