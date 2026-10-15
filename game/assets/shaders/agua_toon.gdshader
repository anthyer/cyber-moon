// Água em estilo toon, para o canal e o reservatório do mapa mundi.
//
// Sem textura nenhuma: tudo sai de conta, em coordenada do mundo, para a água de planos
// diferentes (o canal em trechos, o reservatório inteiro) casar na emenda.
//
// - Duas cores chapadas (funda e rasa) em manchas que andam devagar.
// - Riscos brancos de reflexo, finos e de borda dura, desenhados na emenda das células de
//   um ruído celular (Voronoi) que se mexe com o tempo, só em parte da água.
// - Espuma na beira do plano, com a borda ondulando.
// - Luz em degraus (toon), em vez de degradê suave, com um pouco de brilho próprio.
//
// O plano precisa ter tamanho 1 por 1 e ser esticado pela escala do nó: é pela escala que
// o shader sabe o tamanho em metros e desenha a espuma com a mesma largura em todo plano.
shader_type spatial;
// diffuse_toon é a luz em degraus do próprio Godot: borda dura entre claro e escuro.
render_mode cull_disabled, specular_disabled, diffuse_toon;

uniform vec4 cor_funda : source_color = vec4(0.22, 0.5, 0.9, 1.0);
uniform vec4 cor_rasa : source_color = vec4(0.36, 0.68, 1.0, 1.0);
uniform vec4 cor_do_reflexo : source_color = vec4(0.86, 0.95, 1.0, 1.0);
uniform vec4 cor_da_espuma : source_color = vec4(0.93, 0.98, 1.0, 1.0);
// Quanto maior, menores as manchas e as células.
uniform float escala_das_ondas = 0.3;
uniform float velocidade = 0.35;
// Espessura das linhas de reflexo, de 0 a 1 (fração da célula).
uniform float espessura_do_reflexo = 0.022;
uniform float largura_da_espuma = 0.28;
// Um pouco de brilho próprio, para a água não ficar azul-marinho de manhã cedo e de
// tarde, quando o sol está baixo e o chão claro ainda reflete bastante.
uniform float brilho_proprio = 0.22;

varying vec3 posicao_no_mundo;
varying vec2 tamanho_em_metros;

vec2 sorteio(vec2 ponto) {
	ponto = vec2(dot(ponto, vec2(127.1, 311.7)), dot(ponto, vec2(269.5, 183.3)));
	return fract(sin(ponto) * 43758.5453);
}

// Distância até a emenda mais próxima entre duas células (o "F2 menos F1" do Voronoi).
// Perto de zero é a linha da emenda.
float emenda_das_celulas(vec2 ponto, float tempo) {
	vec2 celula = floor(ponto);
	vec2 dentro = fract(ponto);
	float primeira = 8.0;
	float segunda = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 vizinha = vec2(float(x), float(y));
			vec2 centro = sorteio(celula + vizinha);
			centro = 0.5 + 0.5 * sin(tempo + 6.2831 * centro);
			float distancia = length(vizinha + centro - dentro);
			if (distancia < primeira) {
				segunda = primeira;
				primeira = distancia;
			} else if (distancia < segunda) {
				segunda = distancia;
			}
		}
	}
	return segunda - primeira;
}

void vertex() {
	posicao_no_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	tamanho_em_metros = vec2(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[2].xyz));
}

void fragment() {
	vec2 ponto = posicao_no_mundo.xz * escala_das_ondas;
	float tempo = TIME * velocidade;

	// Manchas funda e rasa, em duas cores chapadas.
	float onda = sin(ponto.x * 0.9 + tempo * 1.3) + sin(ponto.y * 1.1 - tempo) + sin((ponto.x + ponto.y) * 0.6 + tempo * 0.7);
	vec3 cor = mix(cor_funda.rgb, cor_rasa.rgb, step(0.7, onda));

	// Reflexo: só a emenda das células, com borda dura.
	// As linhas aparecem só em parte da água (uma máscara que anda devagar), em riscos
	// soltos. Com a rede inteira à mostra, a água parecia um piso de pedra.
	float emenda = emenda_das_celulas(ponto * 0.9 + vec2(tempo * 0.4, tempo * 0.25), tempo * 2.0);
	float reflexo = 1.0 - step(espessura_do_reflexo, emenda);
	float mascara = step(0.4, sin(ponto.x * 0.7 + tempo) + sin(ponto.y * 0.9 - tempo * 0.8) + sin((ponto.x - ponto.y) * 0.5));
	cor = mix(cor, cor_do_reflexo.rgb, reflexo * mascara * 0.85);

	// Espuma na beira do plano, com a largura ondulando.
	vec2 em_metros = UV * tamanho_em_metros;
	vec2 ate_a_beira = min(em_metros, tamanho_em_metros - em_metros);
	float beira = min(ate_a_beira.x, ate_a_beira.y);
	float ondinha = 0.07 * sin(posicao_no_mundo.x * 3.0 + posicao_no_mundo.z * 2.3 + TIME * 2.2);
	float espuma = 1.0 - step(largura_da_espuma + ondinha, beira);
	cor = mix(cor, cor_da_espuma.rgb, espuma);

	ALBEDO = cor;
	EMISSION = cor * brilho_proprio;
	ROUGHNESS = 1.0;
}
