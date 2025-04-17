#version 410 core

in vec2 texCoord;

out vec4 fragColor;

uniform vec3 uSunColor;

void main() {
    // Calculate distance from center
    float dist = distance(texCoord, vec2(0.5, 0.5));
    
    // Create a circular gradient
    float circle = 1.0 - smoothstep(0.4, 0.5, dist);
    
    // Add a brighter center
    float center = 1.0 - smoothstep(0.0, 0.3, dist);
    
    // Final color with transparency for glow effect
    vec3 color = uSunColor * (circle + center);
    float alpha = circle;
    
    fragColor = vec4(color, alpha);
}