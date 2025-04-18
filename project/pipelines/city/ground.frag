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
    
    // Determine final color
    vec3 color;
    if (zebraPattern > 0.5) {
        // Zebra stripe
        color = uZebraColor;
    } else if (isIntersectionZone) {
        // Road intersection
        color = uRoadColor;
    } else if (isVerticalRoad || isHorizontalRoad) {
        // Regular road
        color = uRoadColor;
        
        // Add faint road lines
        if (isVerticalRoad && abs(cellPos.x - (uBlockSize + uStreetWidth/2.0)) < 0.03) {
            color = vec3(0.9, 0.9, 0.2); // Yellow road line
        } else if (isHorizontalRoad && abs(cellPos.y - (uBlockSize + uStreetWidth/2.0)) < 0.03) {
            color = vec3(0.9, 0.9, 0.2); // Yellow road line
        }
    } else if (isVerticalSidewalk || isHorizontalSidewalk) {
        // Sidewalk
        color = uSidewalkColor;
    } else {
        // Grass or regular ground
        color = uBaseColor;
    }
    
    // Add some subtle noise to break up uniformity
    float noise = fract(sin(dot(fs_in.texCoord, vec2(12.9898, 78.233))) * 43758.5453);
    color *= 0.95 + 0.05 * noise;
    
    fragColor = vec4(color, 1.0);
}