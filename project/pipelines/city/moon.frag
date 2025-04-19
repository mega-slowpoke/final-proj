#version 410 core

in vs{
    vec2 texCoord;
} fs_in;

out vec4 fragColor;

uniform vec3 uMoonColor;
uniform float uMoonSize; // Controls the apparent size of the moon

void main() {
    // Calculate distance from center (0,0)
    float dist = length(fs_in.texCoord);
    
    // Create circular gradient that fades at edges
    // We use a smooth step function to create a soft edge
    float circle = 1.0 - smoothstep(uMoonSize * 0.8, uMoonSize, dist);
    
    // Create a subtle highlight at the center (simulate light diffusion)
    float highlight = 1.0 - smoothstep(0.0, uMoonSize * 0.5, dist);
    highlight = highlight * 0.2; // Subtle effect
    
    // Combine base glow with highlight
    float intensity = circle + highlight;
    
    // Create final color with transparency at edges
    vec3 finalColor = uMoonColor * intensity;
    float alpha = circle * 0.95; // Allow some transparency even at center
    
    // Create a slight red/purple tint around the edges (atmospheric scattering)
    finalColor = mix(finalColor, vec3(0.9, 0.8, 0.9), 1.0 - circle);
    
    fragColor = vec4(finalColor, alpha);
}