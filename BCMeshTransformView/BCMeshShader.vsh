
attribute vec4 position;
attribute vec3 normal;
attribute vec2 texCoord;

varying lowp vec2 texCoordVarying;
varying lowp vec4 shadingVarying;

uniform mat4 viewProjectionMatrix;
uniform mat3 normalMatrix;

uniform vec3 lightDirection;
uniform float diffuseFactor;

void main()
{
    vec3 worldNormal = normalize(normalMatrix * normal);
    
    float diffuseIntensity = abs(dot(worldNormal, lightDirection));
    float diffuse = mix(1.0, diffuseIntensity, diffuseFactor);
    
    shadingVarying = vec4(diffuse, diffuse, diffuse, 1.0);
    texCoordVarying = texCoord;

    gl_Position = viewProjectionMatrix * position;
}

