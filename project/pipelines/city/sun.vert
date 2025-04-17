#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec2 aTexCoord;

out vec2 texCoord;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

void main() {
    texCoord = aTexCoord;
    gl_Position = uProjection * uView * uModel * vec4(aPosition, 1.0);
}