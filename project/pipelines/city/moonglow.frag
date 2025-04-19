#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;

out vs{
    vec3 normal;
    vec3 fragPos;
} vs_out;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

void main() {
    // Scale the sphere slightly larger for the glow effect
    vec3 scaledPos = aPosition * 1.2;
    
    vs_out.normal = aNormal;
    vs_out.fragPos = vec3(uModel * vec4(scaledPos, 1.0));
    
    gl_Position = uProjection * uView * uModel * vec4(scaledPos, 1.0);
}