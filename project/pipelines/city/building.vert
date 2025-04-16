#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;

out vs{
    vec3 normal;
    vec3 fragPos;
    vec3 vertexColor;
} vs_out;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

void main() {
    vs_out.normal = aNormal;
    vs_out.fragPos = vec3(uModel * vec4(aPosition, 1.0));
    
    // Pass through the vertex position for window pattern generation
    vs_out.vertexColor = aPosition;
    
    gl_Position = uProjection * uView * uModel * vec4(aPosition, 1.0);
}