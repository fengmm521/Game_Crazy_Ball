attribute vec2 position;

uniform mat3 projectionMatrix;
uniform mat3 transformMatrix;
uniform mat3 objectMatrix;
uniform mat4 colorMatrix;

varying vec4 vColor;

void main()
{
	vec4 colorA = colorMatrix[0];
	vec4 colorB = colorMatrix[1];
	vec4 colorC = colorMatrix[2];
	vec4 colorD = colorMatrix[3];

	vec4 hozA = mix(colorA, colorB, position.x);
	vec4 hozB = mix(colorC, colorD, position.x);
	vColor = mix(hozA, hozB, position.y);

	vec3 pos = vec3(position, 1);
    gl_Position = vec4(projectionMatrix * transformMatrix * objectMatrix * pos, 1);
}
