module light;

import linear;
import std.math : sin, cos;
import std.datetime : Clock;

/// For the sun
class DirectionalLight {
    vec3 mDirection;   // Direction the light is shining from
    vec3 mColor;       
    float mIntensity; 
    bool mAnimate;     // Whether the light should move over time (day/night cycle)
    
    this(vec3 direction, vec3 color, float intensity = 1.0f, bool animate = false) {
        mDirection = direction.Normalize();
        mColor = color;
        mIntensity = intensity;
        mAnimate = animate;
    }
    
    void Update() {
        if (mAnimate) {
            // For debugging, set a fixed daytime position
            mDirection = vec3(0.2f, 0.8f, 0.4f).Normalize();
            
            /* Original animation code, comment out for now
            import std.datetime : Clock;
            float time = (Clock.currTime().toUnixTime() % 86400) / 86400.0f; // 0-1 over 24h
            float angle = time * (2 * 3.14159f); // 0-2π
            
            // Rotate around x-axis for day/night cycle
            float y = sin(angle);
            float z = cos(angle);
            mDirection = vec3(0.5f, y, z).Normalize();
            */
        }
    }
}