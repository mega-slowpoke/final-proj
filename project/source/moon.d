module moon;

import std.stdio;
import std.random : uniform;
import std.conv : to;
import core;
import mesh, linear, scene, materials, geometry;
import pipeline;
import bindbc.opengl;

class SurfaceSphere : ISurface {
    GLuint mVBO;
    GLuint mIBO;
    size_t mIndices;

    /// Create a sphere
    this(float radius, int segments = 24) {
        MakeSphere(radius, segments);
    }

    /// Render the sphere
    override void Render() {
        glBindVertexArray(mVAO);
        glDrawElements(GL_TRIANGLES, cast(GLuint)mIndices, GL_UNSIGNED_INT, null);
    }

    /// Create sphere geometry
    void MakeSphere(float radius, int segments) {
        import std.math : sin, cos, PI;
        
        GLfloat[] vertices;
        GLuint[] indices;
        
        // Create sphere vertices
        for (int latitude = 0; latitude <= segments; latitude++) {
            float theta = latitude * PI / segments;
            float sinTheta = sin(theta);
            float cosTheta = cos(theta);
            
            for (int longitude = 0; longitude <= segments; longitude++) {
                float phi = longitude * 2.0f * PI / segments;
                float sinPhi = sin(phi);
                float cosPhi = cos(phi);
                
                // Calculate normalized direction vector (perfect sphere)
                float x = sinTheta * cosPhi;
                float y = cosTheta;
                float z = sinTheta * sinPhi;
                
                // Scale by radius to get position
                float px = radius * x;
                float py = radius * y;
                float pz = radius * z;
                
                // Add position and normal (normal is the normalized position for a sphere)
                vertices ~= [px, py, pz, x, y, z];
            }
        }
        
        // Create sphere indices
        for (int latitude = 0; latitude < segments; latitude++) {
            for (int longitude = 0; longitude < segments; longitude++) {
                int current = latitude * (segments + 1) + longitude;
                int next = current + 1;
                int nextLatitude = current + (segments + 1);
                int nextLatitudeAndLongitude = nextLatitude + 1;
                
                // Create two triangles for each quad
                indices ~= [current, nextLatitude, next]; 
                indices ~= [next, nextLatitude, nextLatitudeAndLongitude];
            }
        }
        
        mIndices = indices.length;
        
        // Create OpenGL buffers
        glGenVertexArrays(1, &mVAO);
        glBindVertexArray(mVAO);
        
        // Create IBO
        glGenBuffers(1, &mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLuint.sizeof, indices.ptr, GL_STATIC_DRAW);
        
        // Create VBO
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * GLfloat.sizeof, vertices.ptr, GL_STATIC_DRAW);
        
        // Set vertex attributes
        SetVertexAttributes!VertexFormat3F3F();
        
        // Unbind
        glBindVertexArray(0);
        DisableVertexAttributes!VertexFormat3F3F();
    }
}


class MoonMaterial : IMaterial {
    vec3 mMoonColor;
    float mMoonSize = 0.95; 
    
    /// Constructor
    this(string pipelineName, vec3 moonColor, float moonSize = 0.95) {
        super(pipelineName);
        mMoonColor = moonColor;
        mMoonSize = moonSize;
    }
    
    override void Update() {
        PipelineUse(mPipelineName);
        
        if("uMoonColor" in mUniformMap) {
            mUniformMap["uMoonColor"].Set(mMoonColor.DataPtr());
        }
        
        if("uMoonSize" in mUniformMap) {
            mUniformMap["uMoonSize"].Set(mMoonSize);
        }
    }
}



/// A material for creating a glow around the moon
class MoonGlowMaterial : IMaterial {
    vec3 mGlowColor;
    float mGlowIntensity;
    
    /// Constructor
    this(string pipelineName, vec3 glowColor, float intensity = 0.5f) {
        super(pipelineName);
        mGlowColor = glowColor;
        mGlowIntensity = intensity;
    }
    
    override void Update() {
        PipelineUse(mPipelineName);
        
        if("uGlowColor" in mUniformMap) {
            mUniformMap["uGlowColor"].Set(mGlowColor.DataPtr());
        }
        
        if("uGlowIntensity" in mUniformMap) {
            mUniformMap["uGlowIntensity"].Set(mGlowIntensity);
        }
    }
}


/// Surface class for creating a moon billboard
class SurfaceBillboard : ISurface {
    GLuint mVBO;
    GLuint mIBO;
    size_t mIndices;

    /// Create a billboard quad
    this(float size) {
        MakeBillboard(size);
    }

    /// Render the billboard
    override void Render() {
        glBindVertexArray(mVAO);
        glDrawElements(GL_TRIANGLES, cast(GLuint)mIndices, GL_UNSIGNED_INT, null);
    }

    /// Create billboard geometry (a simple quad)
    void MakeBillboard(float size) {
        // Half size for convenience
        float hs = size * 0.5f;
        
        // Create a simple quad facing forward (will be rotated in shader)
        // Format: x, y, z, nx, ny, nz  (normal is arbitrary for billboard)
        GLfloat[] vertices = [
            -hs, -hs, 0.0f, 0.0f, 0.0f, 1.0f,
            hs, -hs, 0.0f, 0.0f, 0.0f, 1.0f,
            hs, hs, 0.0f, 0.0f, 0.0f, 1.0f,
            -hs, hs, 0.0f, 0.0f, 0.0f, 1.0f
        ];

        // Indices for the quad (two triangles)
        GLuint[] indices = [
            0, 1, 2,
            2, 3, 0
        ];

        mIndices = indices.length;

        // Create OpenGL buffers
        glGenVertexArrays(1, &mVAO);
        glBindVertexArray(mVAO);
        
        // Create IBO
        glGenBuffers(1, &mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLuint.sizeof, indices.ptr, GL_STATIC_DRAW);
        
        // Create VBO
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * GLfloat.sizeof, vertices.ptr, GL_STATIC_DRAW);
        
        // Set vertex attributes
        SetVertexAttributes!VertexFormat3F3F();
        
        // Unbind
        glBindVertexArray(0);
        DisableVertexAttributes!VertexFormat3F3F();
    }
}