#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_COLOR_SHADER

uniform vec2 iResolution;      // viewport resolution (in pixels)
uniform float iGlobalTime;     // shader playback time (in seconds)
uniform vec4 iMouse;           // mouse pixel coords. xy: current (if MLB down), zw: click


// not implemented yet

uniform float iChannelTime[2]; // channel playback time (in seconds)
uniform vec4 iDate;            // (year, month, day, time in seconds)


// Channels can be either 2D maps or Cubemaps. Pick the ones you need.

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;

/*
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;

uniform samplerCube iChannel0;
uniform samplerCube iChannel1;
uniform samplerCube iChannel2;
uniform samplerCube iChannel3;
*/

// Resolution of the channels

uniform vec2 iChannelResolution[2];


// -------- Below is the code you can directly paste back and forth from www.shadertoy.com---------

//  Photoshop blends by ben
//  https://www.shadertoy.com/view/XdS3RW

//	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//	
//	25 of the layer blending modes from Photoshop.
//	
//	The ones I couldn't figure out are from Nvidia's advanced blend equations extension spec -
//	http://www.opengl.org/registry/specs/NV/blend_equation_advanced.txt
//	
//	~bj.2013
//	

vec3 darken( vec3 s, vec3 d )
{
	return min(s,d);
}

vec3 multiply( vec3 s, vec3 d )
{
	return s*d;
}

vec3 colorBurn( vec3 s, vec3 d )
{
	return 1.0 - (1.0 - d) / s;
}

vec3 linearBurn( vec3 s, vec3 d )
{
	return s + d - 1.0;
}

vec3 darkerColor( vec3 s, vec3 d )
{
	return (s.x + s.y + s.z < d.x + d.y + d.z) ? s : d;
}

vec3 lighten( vec3 s, vec3 d )
{
	return max(s,d);
}

vec3 screen( vec3 s, vec3 d )
{
	return s + d - s * d;
}

vec3 colorDodge( vec3 s, vec3 d )
{
	return d / (1.0 - s);
}

vec3 linearDodge( vec3 s, vec3 d )
{
	return s + d;
}

vec3 lighterColor( vec3 s, vec3 d )
{
	return (s.x + s.y + s.z > d.x + d.y + d.z) ? s : d;
}

float overlay( float s, float d )
{
	return (d < 0.5) ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
}

vec3 overlay( vec3 s, vec3 d )
{
	vec3 c;
	c.x = overlay(s.x,d.x);
	c.y = overlay(s.y,d.y);
	c.z = overlay(s.z,d.z);
	return c;
}

float softLight( float s, float d )
{
	return (s < 0.5) ? d - (1.0 - 2.0 * s) * d * (1.0 - d) 
		: (d < 0.25) ? d + (2.0 * s - 1.0) * d * ((16.0 * d - 12.0) * d + 3.0) 
					 : d + (2.0 * s - 1.0) * (sqrt(d) - d);
}

vec3 softLight( vec3 s, vec3 d )
{
	vec3 c;
	c.x = softLight(s.x,d.x);
	c.y = softLight(s.y,d.y);
	c.z = softLight(s.z,d.z);
	return c;
}

float hardLight( float s, float d )
{
	return (s < 0.5) ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
}

vec3 hardLight( vec3 s, vec3 d )
{
	vec3 c;
	c.x = hardLight(s.x,d.x);
	c.y = hardLight(s.y,d.y);
	c.z = hardLight(s.z,d.z);
	return c;
}

float vividLight( float s, float d )
{
	return (s < 0.5) ? 1.0 - (1.0 - d) / (2.0 * s) : d / (2.0 * (1.0 - s));
}

vec3 vividLight( vec3 s, vec3 d )
{
	vec3 c;
	c.x = vividLight(s.x,d.x);
	c.y = vividLight(s.y,d.y);
	c.z = vividLight(s.z,d.z);
	return c;
}

vec3 linearLight( vec3 s, vec3 d )
{
	return 2.0 * s + d - 1.0;
}

float pinLight( float s, float d )
{
	return (2.0 * s - 1.0 > d) ? 2.0 * s - 1.0 : (s < 0.5 * d) ? 2.0 * s : d;
}

vec3 pinLight( vec3 s, vec3 d )
{
	vec3 c;
	c.x = pinLight(s.x,d.x);
	c.y = pinLight(s.y,d.y);
	c.z = pinLight(s.z,d.z);
	return c;
}

vec3 hardMix( vec3 s, vec3 d )
{
	return floor(s + d);
}

vec3 difference( vec3 s, vec3 d )
{
	return abs(d - s);
}

vec3 exclusion( vec3 s, vec3 d )
{
	return s + d - 2.0 * s * d;
}

vec3 subtract( vec3 s, vec3 d )
{
	return s - d;
}

vec3 divide( vec3 s, vec3 d )
{
	return s / d;
}

//	rgb<-->hsv functions by Sam Hocevar
//	http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 rgb2hsv(vec3 c)
{
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 hue( vec3 s, vec3 d )
{
	d = rgb2hsv(d);
	d.x = rgb2hsv(s).x;
	return hsv2rgb(d);
}

vec3 color( vec3 s, vec3 d )
{
	s = rgb2hsv(s);
	s.z = rgb2hsv(d).z;
	return hsv2rgb(s);
}

vec3 saturation( vec3 s, vec3 d )
{
	d = rgb2hsv(d);
	d.y = rgb2hsv(s).y;
	return hsv2rgb(d);
}

vec3 luminosity( vec3 s, vec3 d )
{
	float dLum = dot(d, vec3(0.3, 0.59, 0.11));
	float sLum = dot(s, vec3(0.3, 0.59, 0.11));
	float lum = sLum - dLum;
	vec3 c = d + lum;
	float minC = min(min(c.x, c.y), c.z);
	float maxC = max(max(c.x, c.y), c.z);
	if(minC < 0.0) return sLum + ((c - sLum) * sLum) / (sLum - minC);
	else if(maxC > 1.0) return sLum + ((c - sLum) * (1.0 - sLum)) / (maxC - sLum);
	else return c;
}

void main(void)
{
	vec2 uv = gl_FragCoord.xy / iResolution.xy * vec2(1.0,-1.0) + vec2(0.0, 1.0);
	int id = int(floor(uv.x * 5.0)) + int(floor(uv.y * 5.0))*5;
	
	// source texture (upper layer)
	vec3 s = texture2D(iChannel0, gl_FragCoord.xy / iChannelResolution[0].xy).xyz;
	
	// destination texture (lower layer)
	vec3 d = texture2D(iChannel1, gl_FragCoord.xy / iChannelResolution[1].xy).xyz;
	
	vec3 c = vec3(0.0);
		 if(id==0)	c = darken(s,d);
	else if(id==1)	c = multiply(s,d);
	else if(id==2)	c = colorBurn(s,d);
	else if(id==3)	c = linearBurn(s,d);
	else if(id==4)	c = darkerColor(s,d);
	
	else if(id==5)	c = lighten(s,d);
	else if(id==6)	c = screen(s,d);
	else if(id==7)	c = colorDodge(s,d);
	else if(id==8)	c = linearDodge(s,d);
	else if(id==9)	c = lighterColor(s,d);
	
	else if(id==10)	c = overlay(s,d);
	else if(id==11)	c = softLight(s,d);
	else if(id==12)	c = hardLight(s,d);
	else if(id==13)	c = vividLight(s,d);
	else if(id==14)	c = linearLight(s,d);
	else if(id==15)	c = pinLight(s,d);
	else if(id==16)	c = hardMix(s,d);
	
	else if(id==17)	c = difference(s,d);
	else if(id==18)	c = exclusion(s,d);
	else if(id==19)	c = subtract(s,d);
	else if(id==20)	c = divide(s,d);
	
	else if(id==21)	c = hue(s,d);
	else if(id==22)	c = color(s,d);
	else if(id==23)	c = saturation(s,d);
	else if(id==24)	c = luminosity(s,d);
	
	gl_FragColor = vec4(c,1.0);
}