#version 410 core

layout(location=0) in vec3 aPosition;
layout(location=1) in vec3 aNormal;

out vs{
    vec2 texCoord;
} vs_out;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

void main() {
    // Calculate texture coordinates from position (from -1 to 1)
    vs_out.texCoord = aPosition.xy;
    
    // Extract the camera position from the view matrix
    // This is a simplified approach - assumes camera is at origin
    vec3 cameraPos = vec3(0, 0, 0);
    
    // Create billboard rotation to face camera
    // We use the model position for the billboard center
    vec3 pos = vec3(uModel[3][0], uModel[3][1], uModel[3][2]);
    
    // Calculate the final position
    // We keep the quad's original xy coordinates but apply the model's translation
    vec4 finalPos = uProjection * uView * vec4(pos + aPosition, 1.0);
    
    gl_Position = finalPos;
}