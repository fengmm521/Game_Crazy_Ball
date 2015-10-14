varying lowp vec4 vColor;

uniform lowp int inkEffect;
uniform lowp vec4 blendColor;

void main()
{
	lowp vec4 nColor = vColor * blendColor;

	if(inkEffect == 2)			//INVERT
		nColor.rgb = vec3(1,1,1)-nColor.rgb;
	else if(inkEffect == 10)	//MONO
	{
		lowp float mono = 0.3125*nColor.r + 0.5625*nColor.g + 0.125*nColor.b;
		nColor.rgb = vec3(mono,mono,mono);
	}
	
	gl_FragColor = nColor;
}
