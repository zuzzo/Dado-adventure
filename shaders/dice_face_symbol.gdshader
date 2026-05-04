shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D symbol_texture : source_color;
uniform float roughness_value : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 symbol = texture(symbol_texture, UV);
	ALBEDO = mix(base_color.rgb, symbol.rgb, symbol.a);
	ALPHA = 1.0;
	ROUGHNESS = roughness_value;
}
