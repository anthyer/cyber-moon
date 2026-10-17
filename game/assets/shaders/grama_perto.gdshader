// A graminha perto do jogador: tufos de folhas finas, opacos, balançando com o vento.
//
// A cor vem dos vértices (base escura, ponta clara) e é puxada para o verde pela umidade
// de cada cópia. Opaco de propósito: folha com transparência custa caro para desenhar
// aos milhares, e a folha fina já tem o contorno certo sem textura.
//
// Dados de cada cópia (INSTANCE_CUSTOM):
//   r: variação de tom (0 a 1)
//   g: umidade (0 seco, 1 perto da água)
//   b: fase do balanço
shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;

uniform vec4 tom_seco : source_color = vec4(0.86, 0.68, 0.36, 1.0);
uniform vec4 tom_seco_escuro : source_color = vec4(0.74, 0.56, 0.30, 1.0);
uniform vec4 tom_umido : source_color = vec4(0.46, 0.66, 0.30, 1.0);
uniform float forca_do_vento = 0.06;
uniform float velocidade_do_vento = 1.9;

varying vec3 cor_da_copia;

void vertex() {
	// COLOR.r é a altura relativa na folha: 0 na base, 1 na ponta.
	float altura = COLOR.r;
	vec3 no_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float rajada = sin(TIME * velocidade_do_vento + no_mundo.x * 0.45 + no_mundo.z * 0.3 + INSTANCE_CUSTOM.b * 6.28);
	VERTEX.x += rajada * forca_do_vento * altura * altura;
	VERTEX.z += rajada * forca_do_vento * 0.4 * altura * altura;
	vec3 seco = mix(tom_seco_escuro.rgb, tom_seco.rgb, INSTANCE_CUSTOM.r);
	vec3 ponta = mix(seco, tom_umido.rgb, INSTANCE_CUSTOM.g * 0.85);
	cor_da_copia = ponta * mix(0.8, 1.05, altura);
}

void fragment() {
	// A folha é iluminada como o chão: a normal aponta sempre para cima. Sem isto, o lado
	// de trás de cada folha (a normal virada) fica quase preto contra a areia clara.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	ALBEDO = cor_da_copia;
	ROUGHNESS = 1.0;
}
