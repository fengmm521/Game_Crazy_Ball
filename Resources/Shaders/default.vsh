attribute vec2 position;

uniform sampler2D texture;
uniform mat3 projectionMatrix;
uniform mat3 transformMatrix;
uniform mat3 objectMatrix;
uniform mat3 textureMatrix;

varying vec2 texCoordinate;

void main()
{
	vec3 pos = vec3(position, 1);
	texCoordinate = (textureMatrix * pos).xy;
    gl_Position = vec4(projectionMatrix * transformMatrix * objectMatrix * pos, 1);
}
