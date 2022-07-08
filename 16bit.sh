killall picom &
sleep 1 && picom -b --backend glx --glx-fshader-win "
#version 120
uniform sampler2D tex;
uniform float opacity;
void main(){
	vec4 c = texture2D(tex, gl_TexCoord[0].xy);
	float r=c.r;float g=c.g;float b=c.b;
	c.r = float(int(2.0*r*8.0))/16;
	c.g = float(int(2.0*g*8.0))/16;
	c.b = float(int(2.0*b*8.0))/16;
	gl_FragColor = vec4(c.r, c.g, c.b, c.a);
}"
