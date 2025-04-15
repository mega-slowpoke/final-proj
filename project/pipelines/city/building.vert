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

void main()
{
    vs_out.normal = mat3(transpose(inverse(uModel))) * aNormal;
    vs_out.fragPos = vec3(uModel * vec4(aPosition, 1.0));
    
    vec4 finalPosition = uProjection * uView * uModel * vec4(aPosition, 1.0);
    gl_Position = finalPosition;
}