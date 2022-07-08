killall picom &
sleep 1 && picom -b --backend glx --glx-fshader-win "$(cat<<EOF
#version 120
#ifdef GL_ES
#define LOWP lowp
    precision mediump float;
#else
    #define LOWP
#endif

uniform float CRT_CURVE_AMNTx; // curve amount on x
uniform float CRT_CURVE_AMNTy; // curve amount on y
#define CRT_CASE_BORDR 0.25
#define SCAN_LINE_MULT 1000.0

varying LOWP vec4 v_color;

uniform sampler2D u_texture;
uniform vec2 direction;
uniform float time;
const float blurSize = 1.0/1024.0;
float phosphor = 1.0 - clamp(0.2, 0.0, 1.0);


vec4[9] gaussKernel3x3;

const float PHI = 1.61803398874989484820459; // Î¦ = Golden Ratio 

float gold_noise(vec2 xy,float seed)
{
    return fract(tan(distance(xy*PHI, xy)*seed)*xy.x);
}

void main() {
	
  gaussKernel3x3[0] = vec4(-1.0, -1.0, 0.0,  1.0 / 16.0);
  gaussKernel3x3[1] = vec4(-1.0,  0.0, 0.0,  2.0 / 16.0);
  gaussKernel3x3[2] = vec4(-1.0, +1.0, 0.0,  1.0 / 16.0);
  gaussKernel3x3[3] = vec4( 0.0, -1.0, 0.0,  2.0 / 16.0);
  gaussKernel3x3[4] = vec4( 0.0,  0.0, 0.0,  4.0 / 16.0);
  gaussKernel3x3[5] = vec4( 0.0, +1.0, 0.0,  2.0 / 16.0);
  gaussKernel3x3[6] = vec4(+1.0, -1.0, 0.0,  1.0 / 16.0);
  gaussKernel3x3[7] = vec4(+1.0,  0.0, 0.0,  2.0 / 16.0);
  gaussKernel3x3[8] = vec4(+1.0, +1.0, 0.0,  1.0 / 16.0);
	vec2 tc = gl_TexCoord[0].xy;

	vec4 sum = vec4(0);
	
	// Distance from the center
	float dx = abs(0.5-tc.x);
	float dy = abs(0.5-tc.y);

	// Square it to smooth the edges
	dx *= dx;
	dy *= dy;

	tc.x -= 0.5;
	tc.x *= 1.0 + (dy * 0.2);
	tc.x += 0.5;

	tc.y -= 0.5;
	tc.y *= 1.0 + (dx * 0.2);
	tc.y += 0.5;
	vec4 cta = texture2D(u_texture, vec2(tc.x,tc.y));
	float hRes =1800.0;
	float vRes =80.0;
	//rgb
	float r=cta.r;
	float g=cta.g;
	float b=cta.b;
	int posr = int(tc.x * hRes + 2.0);
    	int posg = int(tc.x * hRes + 1.0);
    	int posb = int(tc.x * hRes);

   	float intr = mod(float(posr), 4.0);
   	float intg = mod(float(posg), 4.0);
   	float intb = mod(float(posb), 4.0);
        
        r *= clamp(intg * intb, phosphor, 1.0);
        g *= clamp(intr * intb, phosphor, 1.0);
        b *= clamp(intr * intg, phosphor, 1.0);
        
        //breaks between phosphor rgb elements in a hexagonal pattern:
        
        int yposPhosbreak1 = int(tc.y * vRes);
        int yposPhosbreak2 = int(tc.y * vRes + .5);
        int xposPhosbreak = int(tc.x * hRes/2.0 - 0.333333333);
        
        float intPhosbreak1 = mod(float(yposPhosbreak1), 6.0) + mod(float(xposPhosbreak), 2.0);
        float intPhosbreak2 = mod(float(yposPhosbreak2), 6.0) + (1.0-mod(float(xposPhosbreak), 2.0));
	vec3 rgb = vec3(r * (0.9 + 0.1 * phosphor), g, b);
	rgb *= clamp(intPhosbreak1 * intPhosbreak2 + 0.5 + 0.5 * phosphor, 0.0, 1.0);
	
	rgb += (sin(tc.y * SCAN_LINE_MULT) * 0.3)-0.2;
	// Cutoff
	if(tc.y > 1.0 || tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0)
		rgb = vec3(0.0);
	sum.rgb=rgb;
    float blur = 6.0;
	float hstep = direction.x;
	float vstep = direction.y;
	const vec2 texelSize = vec2(1.0) / vec2(1920,1080);
	  for (int i = 0; i < 9; ++i)
		{
			sum+= gaussKernel3x3[i].w * texture2D(u_texture, tc.xy + texelSize * gaussKernel3x3[i].xy);
		}
	sum.rgb = clamp(vec3(r * (0.9 + 0.1 * phosphor), g, b)*sum.rgb,0.0,1.0);
	sum *= clamp(intPhosbreak1 * intPhosbreak2 + 0.5 + 0.5 * phosphor, 0.0, 1.0);
	rgb+=clamp((sum.rgb*1.5)-0.9,0.0,0.5);
	// Apply
	gl_FragColor = vec4(clamp(rgb,0.,1.),cta.a);

}




EOF
)"
