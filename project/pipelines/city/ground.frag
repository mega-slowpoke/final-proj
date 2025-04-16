#version 410 core

in vs{
    vec3 normal;
} fs_in;

out vec4 fragColor;

uniform vec3 uGroundColor;

void main()
{
    fragColor = vec4(uGroundColor, 1.0);
}