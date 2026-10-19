// O brilho do objeto que vai responder ao botão de interagir (plano 28).
//
// Vai no material_overlay das malhas do alvo: uma camada somada por cima do material
// normal, sem trocá-lo. A borda (onde a superfície fica de lado para a câmera) brilha mais
// que o meio, e o brilho pulsa devagar. Amarelo claro, a cor de "dá para interagir" do
// jogo, como o balão de conversa do NPC.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, specular_disabled;

uniform vec4 cor : source_color = vec4(1.0, 0.86, 0.45, 1.0);
uniform float forca = 0.9;
uniform float velocidade_do_pulso = 4.0;

void fragment() {
	float borda = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float pulso = 0.65 + 0.35 * sin(TIME * velocidade_do_pulso);
	ALBEDO = cor.rgb * forca * (0.3 + borda * 1.5) * pulso;
}
