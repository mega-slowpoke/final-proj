#version 410 core

in vs{
    vec3 normal;
    vec3 fragPos;
} fs_in;

out vec4 fragColor;

uniform vec3 uBuildingColor;

void main()
{
    // Ambient light
    float ambientStrength = 0.3;
    vec3 ambient = ambientStrength * vec3(1.0, 1.0, 1.0);
    
    // Diffuse light
    vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
    vec3 norm = normalize(fs_in.normal);
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = diff * vec3(1.0, 1.0, 1.0);
    
    // Combine lighting with building color
    vec3 result = (ambient + diffuse) * uBuildingColor;
    
    // Final color
    fragColor = vec4(result, 1.0);
}