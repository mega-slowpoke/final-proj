#version 410 core

in vs{
    vec3 normal;
    vec3 fragPos;
    vec3 vertexColor;
} fs_in;

out vec4 fragColor;

// Building properties
uniform vec3 uBaseColor;
uniform float uWindowDensity = 0.5;
uniform float uWindowBrightness = 0.8;
uniform float uTime = 0.0;

// Moon light properties
uniform vec3 uLightDirection = vec3(0.5, -0.7, 0.3); // Direction the moonlight is coming from
uniform vec3 uLightColor = vec3(0.6, 0.7, 0.9);     // Cool moonlight color
uniform float uAmbientStrength = 0.1;               // Low ambient light for night
uniform float uDiffuseStrength = 0.3;               // Lower diffuse light for moonlight

// Existing noise function
float hash(vec2 p) {
    p = 50.0*fract(p*0.3183099 + vec2(0.71,0.113));
    return -1.0+2.0*fract(p.x*p.y*(p.x+p.y));
}

// Function to determine if a window is lit based on position
vec3 windowPattern(vec3 position) {
    // Only consider vertical surfaces for windows
    if (abs(fs_in.normal.y) > 0.1) {
        return vec3(0.0);
    }
    
    // Make window grid smaller for more windows
    float gridSizeX = 0.15;
    float gridSizeY = 0.15;
    
    // Wall-based coordinates
    vec2 wallCoord;
    if (abs(fs_in.normal.x) > 0.5) {
        // For X-aligned walls
        wallCoord = vec2(position.z, position.y);
    } else {
        // For Z-aligned walls
        wallCoord = vec2(position.x, position.y);
    }
    
    // Calculate grid position (which window we're in)
    vec2 gridPos = floor(wallCoord / vec2(gridSizeX, gridSizeY));
    
    // Calculate position within a window cell (0-1 range)
    vec2 cellPos = fract(wallCoord / vec2(gridSizeX, gridSizeY));
    
    // Window border thickness (percentage of cell)
    float borderThickness = 0.1;
    
    // Frame color (structure between windows) - darker at night
    vec3 frameColor = uBaseColor * 0.4; // Darker than base building for night
    
    // Check if we're in the window or the frame
    bool isFrame = cellPos.x < borderThickness || 
                  cellPos.x > (1.0 - borderThickness) || 
                  cellPos.y < borderThickness || 
                  cellPos.y > (1.0 - borderThickness);
                  
    if (isFrame) {
        return frameColor;
    }
    
    // Calculate varied window properties based on position
    float seed = hash(gridPos); // Unique value per window
    
    // Window states - at night, we want more windows to be lit
    // 1. Completely dark (blue-tinted)
    // 2. Dimly lit (evening work)
    // 3. Brightly lit (office lights)
    // 4. Blinking occasionally
    
    // Randomize window states - increase density for night scene
    float state = fract(seed * 12.3456 + position.y * 0.1);
    
    // Height factor - higher floors tend to have more lit windows at night
    float heightFactor = smoothstep(0.0, 15.0, position.y);
    
    // Time-based blinking for some windows
    float blinkSpeed = 3.0 + seed * 5.0; // Varied blink speed
    float blinkOffset = seed * 20.0;     // Varied blink timing
    float blink = smoothstep(0.3, 0.7, sin(uTime * blinkSpeed + blinkOffset) * 0.5 + 0.5);
    
    // Determine window color based on state
    vec3 windowColor;
    
    // More lit windows at night (0.75 instead of 0.6)
    if (state < 0.75 * uWindowDensity * (0.7 + 0.3 * heightFactor)) {
        // Lit window - with varied colors
        float warmth = fract(seed * 7.89); // How warm/cool the light is
        
        if (warmth < 0.6) {
            // Warm light (yellowish) - more common at night
            windowColor = vec3(1.0, 0.9, 0.7) * uWindowBrightness * 1.2; // Brighter for contrast
        } else if (warmth < 0.85) {
            // White light
            windowColor = vec3(1.0, 1.0, 1.0) * uWindowBrightness * 1.2; // Brighter for contrast
        } else {
            // Cool light (bluish)
            windowColor = vec3(0.8, 0.9, 1.0) * uWindowBrightness * 1.2; // Brighter for contrast
        }
        
        // Apply blinking to some windows
        if (fract(seed * 3.456) > 0.85) {
            windowColor *= 0.5 + 0.5 * blink;
        }
    } else {
        // Dark window - blue tinted reflection of night sky
        windowColor = vec3(0.05, 0.08, 0.15) * 0.4; // Very dark blue for night
    }
    
    return windowColor;
}

void main() {
    // Get window pattern
    vec3 windowColor = windowPattern(fs_in.vertexColor);
    
    // Normalize the light direction and surface normal
    vec3 norm = normalize(fs_in.normal);
    vec3 lightDir = normalize(-uLightDirection);
    
    // Calculate ambient component
    vec3 ambient = uAmbientStrength * uLightColor;
    
    // Calculate diffuse component (Lambertian reflection)
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = uDiffuseStrength * diff * uLightColor;
    
    // Apply lighting to the base building color
    vec3 litColor = uBaseColor * (ambient + diffuse);
    
    // Use window color for windows, and lit building color for the rest
    vec3 result = windowColor;
    
    // If it's not a window (color is very dark), use building lighting
    if (length(windowColor) < 0.1) {
        result = litColor;
    }
    
    // Final color
    fragColor = vec4(result, 1.0);
}