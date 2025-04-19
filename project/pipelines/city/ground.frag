#version 410 core

in vs{
    vec3 normal;
    vec3 worldPos;
    vec2 texCoord;
} fs_in;

out vec4 fragColor;

// Ground colors
uniform vec3 uBaseColor;       // Ground/grass color
uniform vec3 uRoadColor;       // Road color
uniform vec3 uSidewalkColor;   // Sidewalk color
uniform vec3 uZebraColor;      // Zebra crossing color

// City layout parameters
uniform float uBlockSize;      // Size of city blocks
uniform float uStreetWidth;    // Width of streets
uniform float uSidewalkWidth;  // Width of sidewalks
uniform float uZebraWidth;     // Width of zebra crossings
uniform float uZebraStripeWidth; // Width of individual zebra stripes

// Moon light properties
uniform vec3 uLightDirection = vec3(0.5, -0.7, 0.3);
uniform vec3 uLightColor = vec3(0.6, 0.7, 0.9);
uniform float uAmbientStrength = 0.1;
uniform float uDiffuseStrength = 0.3;

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
        zebraPattern = step(0.5, mod(cellPos.x / uZebraStripeWidth, 1.0));
    } else if (isHorizontalRoad && abs(cellPos.x - (uBlockSize - uZebraWidth)) < uZebraWidth && !isIntersectionZone) {
        zebraPattern = step(0.5, mod(cellPos.y / uZebraStripeWidth, 1.0));
    }
    
    // Determine base color before lighting - darker for night
    vec3 baseColor;
    if (zebraPattern > 0.5) {
        baseColor = uZebraColor * 0.7; // Dimmer at night
    } else if (isIntersectionZone) {
        baseColor = uRoadColor * 0.7; // Dimmer at night
    } else if (isVerticalRoad || isHorizontalRoad) {
        baseColor = uRoadColor * 0.7; // Dimmer at night
        
        // Add faint road lines - brighter for night visibility
        if (isVerticalRoad && abs(cellPos.x - (uBlockSize + uStreetWidth/2.0)) < 0.03) {
            baseColor = vec3(0.8, 0.8, 0.2) * 0.5; // Dim yellow road line
        } else if (isHorizontalRoad && abs(cellPos.y - (uBlockSize + uStreetWidth/2.0)) < 0.03) {
            baseColor = vec3(0.8, 0.8, 0.2) * 0.5; // Dim yellow road line
        }
    } else if (isVerticalSidewalk || isHorizontalSidewalk) {
        baseColor = uSidewalkColor * 0.6; // Dimmer at night
    } else {
        baseColor = uBaseColor * 0.3; // Very dim for grass/ground at night
    }
    
    // Apply lighting calculations
    vec3 norm = normalize(fs_in.normal);
    vec3 lightDir = normalize(-uLightDirection);
    
    // Calculate ambient component
    vec3 ambient = uAmbientStrength * uLightColor;
    
    // Calculate diffuse component
    float diff = max(dot(norm, lightDir), 0.0);
    vec3 diffuse = uDiffuseStrength * diff * uLightColor;
    
    // Combine lighting with base color
    vec3 result = baseColor * (ambient + diffuse);
    
    // Add some subtle noise to break up uniformity
    float noise = fract(sin(dot(fs_in.texCoord, vec2(12.9898, 78.233))) * 43758.5453);
    result *= 0.95 + 0.05 * noise;
    
    // Add some subtle blue tint for night
    result = mix(result, vec3(0.1, 0.2, 0.4), 0.1);
    
    fragColor = vec4(result, 1.0);
}