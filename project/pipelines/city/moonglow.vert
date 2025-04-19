#version 410 core

in vs{
    vec3 normal;
    vec3 fragPos;
} fs_in;

out vec4 fragColor;

uniform vec3 uGlowColor;
uniform float uGlowIntensity;

void main() {
    // Get normalized vectors
    vec3 norm = normalize(fs_in.normal);
    vec3 viewDir = normalize(-fs_in.fragPos);
    
    // Create glow effect that fades toward the edges
    float edge = max(0.0, dot(norm, viewDir));
    float glow = pow(1.0 - edge, 3.0) * uGlowIntensity;
    
    // Final color with transparency for the glow
    fragColor = vec4(uGlowColor, glow);
}