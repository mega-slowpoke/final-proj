#version 410 core

in vs{
    vec3 normal;
    vec3 worldPos;
    vec2 texCoord;
} fs_in;

out vec4 fragColor;

uniform vec3 uBaseColor;       // Ground/grass color
uniform vec3 uRoadColor;       // Road color
uniform vec3 uSidewalkColor;   // Sidewalk color
uniform vec3 uZebraColor;      // Zebra crossing color
uniform float uBlockSize;      // Size of city blocks
uniform float uStreetWidth;    // Width of streets
uniform float uSidewalkWidth;  // Width of sidewalks
uniform float uZebraWidth;     // Width of zebra crossings
uniform float uZebraStripeWidth; // Width of individual zebra stripes

// Lighting uniforms
uniform vec3 uLightDirection;     // Direction of the sun
uniform vec3 uLightColor;         // Color of the sunlight 
uniform float uLightIntensity;    // Intensity of the sunlight

// Noise function for subtle ground variation
float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
    // Get world position coordinates
    vec2 pos = fs_in.texCoord;
    
    // Determine grid position
    float totalCellSize = uBlockSize + uStreetWidth;
    vec2 cellPos = mod(pos, totalCellSize);
    
    // Determine if we're on a road, sidewalk or block
    bool isVerticalRoad = cellPos.x >= uBlockSize && cellPos.x <= uBlockSize + uStreetWidth;
    bool isHorizontalRoad = cellPos.y >= uBlockSize && cellPos.y <= uBlockSize + uStreetWidth;
    
    // Calculate distances from road edges for sidewalks
    float distFromVerticalRoadEdge = min(
        abs(cellPos.x - uBlockSize),
        abs(cellPos.x - (uBlockSize + uStreetWidth))
    );
    
    float distFromHorizontalRoadEdge = min(
        abs(cellPos.y - uBlockSize),
        abs(cellPos.y - (uBlockSize + uStreetWidth))
    );
    
    // Check if we're on a sidewalk adjacent to a road
    bool isVerticalSidewalk = !isVerticalRoad && !isHorizontalRoad && 
                             distFromVerticalRoadEdge < uSidewalkWidth;
    
    bool isHorizontalSidewalk = !isVerticalRoad && !isHorizontalRoad && 
                               distFromHorizontalRoadEdge < uSidewalkWidth;
    
    // Check for crosswalk (zebra) near intersections
    bool isIntersectionZone = isVerticalRoad && isHorizontalRoad;
    
    // Create zebra pattern
    float zebraPattern = 0.0;
    if (isVerticalRoad && abs(cellPos.y - (uBlockSize - uZebraWidth)) < uZebraWidth && !isIntersectionZone) {
        // Horizontal zebra crossing on vertical road
        zebraPattern = step(0.5, mod(cellPos.x / uZebraStripeWidth, 1.0));
    } else if (isHorizontalRoad && abs(cellPos.x - (uBlockSize - uZebraWidth)) < uZebraWidth && !isIntersectionZone) {
        // Vertical zebra crossing on horizontal road
        zebraPattern = step(0.5, mod(cellPos.y / uZebraStripeWidth, 1.0));
    }
    
    // Determine base material color
    vec3 materialColor;
    if (zebraPattern > 0.5) {
        // Zebra stripe
        materialColor = uZebraColor;
    } else if (isIntersectionZone) {
        // Road intersection
        materialColor = uRoadColor;
    } else if (isVerticalRoad || isHorizontalRoad) {
        // Regular road
        materialColor = uRoadColor;
        
        // Add faint road lines
        if (isVerticalRoad && abs(cellPos.x - (uBlockSize + uStreetWidth/2.0)) < 0.03) {
            materialColor = vec3(0.9, 0.9, 0.2); // Yellow road line
        } else if (isHorizontalRoad && abs(cellPos.y - (uBlockSize + uStreetWidth/2.0)) < 0.03) {
            materialColor = vec3(0.9, 0.9, 0.2); // Yellow road line
        }
    } else if (isVerticalSidewalk || isHorizontalSidewalk) {
        // Sidewalk
        materialColor = uSidewalkColor;
    } else {
        // Grass or regular ground
        materialColor = uBaseColor;
    }
    
    // Calculate lighting
    vec3 normal = normalize(fs_in.normal);
    vec3 lightDir = normalize(-uLightDirection); // Light direction points from surface to light
    
    // Ambient component
    float ambient = 0.3;
    
    // Diffuse component
    float diffuseFactor = max(dot(normal, lightDir), 0.0);
    vec3 diffuse = diffuseFactor * uLightColor * uLightIntensity;
    
    // Combine lighting components
    vec3 lighting = ambient + diffuse;
    
    // Apply time-of-day effects
    float daytime = max(0.0, uLightDirection.y); // 0 = night, 1 = noon
    
    // Subtle shadows where buildings would cast them
    float shadowFactor = 1.0;
    
    // Add noise/variation to ground
    float noiseValue = noise(fs_in.texCoord * 10.0);
    materialColor *= 0.95 + 0.05 * noiseValue;
    
    // Apply lighting to material color
    vec3 result = materialColor * lighting * shadowFactor;
    
    // Dawn/dusk orange tint
    if (uLightDirection.y > -0.2 && uLightDirection.y < 0.2) {
        float dawnDuskFactor = 1.0 - abs(uLightDirection.y * 5.0);
        result += vec3(0.3, 0.1, 0.0) * dawnDuskFactor * 0.3;
    }
    // Night - blue tint and darken ground
    else if (uLightDirection.y < 0.0) {
        float nightFactor = smoothstep(0.0, -0.5, uLightDirection.y);
        // Darken everything except road lines at night
        if (!(isVerticalRoad && abs(cellPos.x - (uBlockSize + uStreetWidth/2.0)) < 0.03) && 
            !(isHorizontalRoad && abs(cellPos.y - (uBlockSize + uStreetWidth/2.0)) < 0.03)) {
            result = mix(result, result * 0.3 + vec3(0.02, 0.03, 0.06), nightFactor);
        }
    }
    
    // Road wetness/reflectivity effect
    if (isVerticalRoad || isHorizontalRoad || isIntersectionZone) {
        float wetness = 0.2; // Static wetness factor
        // Add slight reflection of sky color to roads
        vec3 skyColor = vec3(0.5, 0.6, 1.0);
        if (uLightDirection.y < 0.0) {
            // Night sky is darker
            skyColor = vec3(0.02, 0.03, 0.1);
        }
        // Add reflection based on viewing angle (simplified)
        result = mix(result, skyColor, wetness * 0.2);
    }
    
    fragColor = vec4(result, 1.0);
}