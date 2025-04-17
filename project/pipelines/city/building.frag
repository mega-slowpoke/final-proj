// building.frag - Modified to include lighting
#version 410 core

in vs{
    vec3 normal;
    vec3 fragPos;
    vec3 vertexColor;
} fs_in;

out vec4 fragColor;

uniform vec3 uBaseColor;
uniform float uWindowDensity = 0.5;
uniform float uWindowBrightness = 0.8;
uniform float uTime = 0.0;

// Lighting uniforms
uniform vec3 uLightDirection;     // Direction of the sun
uniform vec3 uLightColor;         // Color of the sunlight 
uniform float uLightIntensity;    // Intensity of the sunlight

// Better noise function for more natural randomness
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
    
    // Frame color (structure between windows)
    vec3 frameColor = uBaseColor * 0.7; // Darker than base building
    
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
    
    // Window states - more varied
    // 1. Completely dark (blue-tinted)
    // 2. Dimly lit (evening work)
    // 3. Brightly lit (office lights)
    // 4. Blinking occasionally
    
    // Randomize window states
    float state = fract(seed * 12.3456 + position.y * 0.1);
    
    // Height factor - higher floors have more lit windows at night
    float heightFactor = smoothstep(0.0, 15.0, position.y);
    
    // Time-based blinking for some windows
    float blinkSpeed = 3.0 + seed * 5.0; // Varied blink speed
    float blinkOffset = seed * 20.0;     // Varied blink timing
    float blink = smoothstep(0.3, 0.7, sin(uTime * blinkSpeed + blinkOffset) * 0.5 + 0.5);
    
    // Day/night lighting factor - if sun is below horizon, more windows are lit
    // Use the sun's Y component to determine day/night
    float dayNightFactor = 1.0 - smoothstep(-0.2, 0.5, uLightDirection.y);
    
    // Determine window color based on state
    vec3 windowColor;
    
    if (state < (0.6 * uWindowDensity * (0.7 + 0.3 * heightFactor) * (1.0 + dayNightFactor))) {
        // Lit window - with varied colors
        float warmth = fract(seed * 7.89); // How warm/cool the light is
        
        if (warmth < 0.7) {
            // Warm light (yellowish)
            windowColor = vec3(1.0, 0.9, 0.7) * uWindowBrightness;
        } else if (warmth < 0.9) {
            // White light
            windowColor = vec3(1.0, 1.0, 1.0) * uWindowBrightness;
        } else {
            // Cool light (bluish)
            windowColor = vec3(0.8, 0.9, 1.0) * uWindowBrightness;
        }
        
        // Apply blinking to some windows
        if (fract(seed * 3.456) > 0.85) {
            windowColor *= 0.5 + 0.5 * blink;
        }
    } else {
        // Dark window - blue tinted reflection
        // Reflect more sky light during day
        float skyReflection = max(0.0, uLightDirection.y * 0.5 + 0.5);
        windowColor = vec3(0.1, 0.15, 0.25) * (0.5 + skyReflection * 0.5);
    }
    
    return windowColor;
}

void main() {
    // Normal lighting calculations
    vec3 normal = normalize(fs_in.normal);
    vec3 lightDir = normalize(-uLightDirection); // Light direction points from surface to light
    
    // Get window pattern
    vec3 windowColor = windowPattern(fs_in.vertexColor);
    
    // Calculate base lighting
    float ambient = 0.3; // Ambient light level
    
    // Diffuse lighting - use the dot product between normal and light direction
    float diffuseFactor = max(dot(normal, lightDir), 0.0);
    
    // Use light color and intensity for diffuse component
    vec3 diffuse = diffuseFactor * uLightColor * uLightIntensity;
    
    // Combine ambient and diffuse for base lighting
    vec3 lighting = ambient + diffuse;
    
    // Use window color for windows, and base building color with lighting for the rest
    vec3 result;
    
    // If it's a window (color is not very dark)
    if (length(windowColor) > 0.1) {
        // Apply less direct lighting to windows (they emit light themselves)
        result = windowColor * (ambient + diffuseFactor * 0.5);
    } else {
        // Apply full lighting to building surfaces
        result = uBaseColor * lighting;
        
        // Add slight blue tint to shadowed areas (sky reflection)
        if (diffuseFactor < 0.1) {
            result += vec3(0.0, 0.05, 0.1) * (1.0 - diffuseFactor) * 0.5;
        }
    }
    
    // Apply time-of-day tinting
    // Dawn/dusk - orange tint
    if (uLightDirection.y > -0.2 && uLightDirection.y < 0.2) {
        float dawnDuskFactor = 1.0 - abs(uLightDirection.y * 5.0);
        result += vec3(0.3, 0.1, 0.0) * dawnDuskFactor * 0.3;
    }
    // Night - blue tint
    else if (uLightDirection.y < 0.0) {
        float nightFactor = smoothstep(0.0, -0.5, uLightDirection.y);
        result = mix(result, result * vec3(0.7, 0.8, 1.0), nightFactor * 0.5);
    }
    
    // Final color
    fragColor = vec4(result, 1.0);
}