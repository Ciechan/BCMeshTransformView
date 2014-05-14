
precision lowp float;

varying vec2 texCoordVarying;
varying vec4 shadingVarying;

uniform sampler2D texSampler;

void main()
{
    //Branch-less transparent texture border
    
    vec2 centered = abs(texCoordVarying - vec2(0.5));
    
    // if tex coords are out of bounds, they're over 0.5 at this point
    
    vec2 clamped = clamp(sign(centered - vec2(0.5)), 0.0, 1.0);
    
    // If a tex coord is out of bounds, then it's equal to 1.0 at this point, otherwise it's 0.0.
    // If either coordinate is 1.0, then their sum will be larger than zero
    
    float inBounds = 1.0 - clamp(clamped.x + clamped.y, 0.0, 1.0);
    
    gl_FragColor = shadingVarying * texture2D(texSampler, texCoordVarying) * inBounds;
}

