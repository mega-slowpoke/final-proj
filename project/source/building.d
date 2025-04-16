module building;


import std.stdio;
import std.random : uniform;
import std.conv : to;
import core;
import mesh, linear, scene, materials, geometry;
import pipeline;
import bindbc.opengl;

/// Surface class for creating a building block
class SurfaceBuilding : ISurface {
    GLuint mVBO;
    GLuint mIBO;
    size_t mIndices;

    /// Create a cube for a building
    this(float width, float height, float depth) {
        MakeBuilding(width, height, depth);
    }

    /// Render the building
    override void Render() {
        glBindVertexArray(mVAO);
        glDrawElements(GL_TRIANGLES, cast(GLuint)mIndices, GL_UNSIGNED_INT, null);
    }

    /// Create building geometry (a cube with position and normal data)
    void MakeBuilding(float width, float height, float depth) {
        // Vertex data for a cube
        // Format: x, y, z, nx, ny, nz
        GLfloat[] vertices = [
            // Front face
            -width/2, 0, depth/2, 0, 0, 1,
            width/2, 0, depth/2, 0, 0, 1,
            width/2, height, depth/2, 0, 0, 1,
            -width/2, height, depth/2, 0, 0, 1,
            
            // Back face
            -width/2, 0, -depth/2, 0, 0, -1,
            -width/2, height, -depth/2, 0, 0, -1,
            width/2, height, -depth/2, 0, 0, -1,
            width/2, 0, -depth/2, 0, 0, -1,
            
            // Top face
            -width/2, height, -depth/2, 0, 1, 0,
            -width/2, height, depth/2, 0, 1, 0,
            width/2, height, depth/2, 0, 1, 0,
            width/2, height, -depth/2, 0, 1, 0,
            
            // Bottom face
            -width/2, 0, -depth/2, 0, -1, 0,
            width/2, 0, -depth/2, 0, -1, 0,
            width/2, 0, depth/2, 0, -1, 0,
            -width/2, 0, depth/2, 0, -1, 0,
            
            // Right face
            width/2, 0, -depth/2, 1, 0, 0,
            width/2, height, -depth/2, 1, 0, 0,
            width/2, height, depth/2, 1, 0, 0,
            width/2, 0, depth/2, 1, 0, 0,
            
            // Left face
            -width/2, 0, -depth/2, -1, 0, 0,
            -width/2, 0, depth/2, -1, 0, 0,
            -width/2, height, depth/2, -1, 0, 0,
            -width/2, height, -depth/2, -1, 0, 0
        ];

        // Indices for the cube
        GLuint[] indices = [
            0, 1, 2, 2, 3, 0,       // Front face
            4, 5, 6, 6, 7, 4,       // Back face
            8, 9, 10, 10, 11, 8,    // Top face
            12, 13, 14, 14, 15, 12, // Bottom face
            16, 17, 18, 18, 19, 16, // Right face
            20, 21, 22, 22, 23, 20  // Left face
        ];

        mIndices = indices.length;

        // Create VAO
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



/// Building material that allows for color variations
class BuildingMaterial : IMaterial {
    // Building colors (variations of gray)
    vec3 mColor;

    /// Constructor with a color parameter
    this(string pipelineName, vec3 color) {
        super(pipelineName);
        mColor = color;
    }

    override void Update() {
        PipelineUse(mPipelineName);
        
        if("uBaseColor" in mUniformMap) {
            mUniformMap["uBaseColor"].Set(mColor.DataPtr());
        }
    }
}


class SurfaceCylindricalBuilding : ISurface {
    GLuint mVBO;
    GLuint mIBO;
    size_t mIndices;

    /// Create a cylindrical building
    this(float radius, float height, int segments = 20) {
        MakeCylinder(radius, height, segments);
    }

    /// Render the cylindrical building
    override void Render() {
        glBindVertexArray(mVAO);
        glDrawElements(GL_TRIANGLES, cast(GLuint)mIndices, GL_UNSIGNED_INT, null);
    }


    /// Create cylinder geometry
    void MakeCylinder(float radius, float height, int segments) {
        import std.math : sin, cos, PI;
        
        GLfloat[] vertices;
        GLuint[] indices;
        
        // Calculate the angle between segments
        float angleStep = 2.0f * PI / segments;
        
        // Bottom center vertex (0)
        vertices ~= [0.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f];
        
        // Bottom circle vertices (1 to segments)
        for (int i = 0; i < segments; i++) {
            float angle = i * angleStep;
            float x = radius * cos(angle);
            float z = radius * sin(angle);
            
            // Position and normal for bottom circle vertex
            vertices ~= [x, 0.0f, z, 0.0f, -1.0f, 0.0f];
        }
        
        // Top center vertex (segments+1)
        vertices ~= [0.0f, height, 0.0f, 0.0f, 1.0f, 0.0f];
        
        // Top circle vertices (segments+2 to 2*segments+1)
        for (int i = 0; i < segments; i++) {
            float angle = i * angleStep;
            float x = radius * cos(angle);
            float z = radius * sin(angle);
            
            // Position and normal for top circle vertex
            vertices ~= [x, height, z, 0.0f, 1.0f, 0.0f];
        }
        
        // Side vertices (2*segments+2 to 3*segments+1)
        for (int i = 0; i < segments; i++) {
            float angle = i * angleStep;
            float x = radius * cos(angle);
            float z = radius * sin(angle);
            float nx = cos(angle);  // Normal points outward
            float nz = sin(angle);
            
            // Position and normal for side vertex at bottom
            vertices ~= [x, 0.0f, z, nx, 0.0f, nz];
        }
        
        // Side vertices (3*segments+2 to 4*segments+1)
        for (int i = 0; i < segments; i++) {
            float angle = i * angleStep;
            float x = radius * cos(angle);
            float z = radius * sin(angle);
            float nx = cos(angle);  // Normal points outward
            float nz = sin(angle);
            
            // Position and normal for side vertex at top
            vertices ~= [x, height, z, nx, 0.0f, nz];
        }
        
        // Create indices for bottom circle
        for (int i = 0; i < segments; i++) {
            indices ~= 0;  // Center
            indices ~= 1 + i;
            indices ~= 1 + ((i + 1) % segments);
        }
        
        // Create indices for top circle
        for (int i = 0; i < segments; i++) {
            indices ~= segments + 1;  // Center
            indices ~= segments + 2 + ((i + 1) % segments);
            indices ~= segments + 2 + i;
        }
        
        // Create indices for sides (quads made of two triangles)
        int sideStartIndex = 2 * segments + 2;
        for (int i = 0; i < segments; i++) {
            int current = sideStartIndex + i;
            int next = sideStartIndex + ((i + 1) % segments);
            int currentTop = current + segments;
            int nextTop = next + segments;
            
            // First triangle
            indices ~= current;
            indices ~= currentTop;
            indices ~= next;
            
            // Second triangle
            indices ~= next;
            indices ~= currentTop;
            indices ~= nextTop;
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


/// A material for buildings with windows
class TexturedBuildingMaterial : IMaterial {
    // Building base color
    vec3 mBaseColor;
    // Window lighting pattern
    float mWindowDensity = 0.5f;
    float mWindowBrightness = 0.8f;
    
    /// Constructor with color parameters
    this(string pipelineName, vec3 baseColor, float windowDensity = 0.5f, float windowBrightness = 0.8f) {
        super(pipelineName);
        mBaseColor = baseColor;
        mWindowDensity = windowDensity;
        mWindowBrightness = windowBrightness;
    }
    
    /// Override update to set building material properties
    override void Update() {
        // Set our active Shader graphics pipeline 
        PipelineUse(mPipelineName);
        
        // Set any uniforms for our mesh if they exist in the shader
        if("uBaseColor" in mUniformMap) {
            mUniformMap["uBaseColor"].Set(mBaseColor.DataPtr());
        }
        
        if("uWindowDensity" in mUniformMap) {
            mUniformMap["uWindowDensity"].Set(mWindowDensity);
        }
        
        if("uWindowBrightness" in mUniformMap) {
            mUniformMap["uWindowBrightness"].Set(mWindowBrightness);
        }
        
        if("uTime" in mUniformMap) {
            // Simple animation for window lights blinking
            import std.datetime : Clock;
            float time = (Clock.currTime().toUnixTime() % 1000) / 10.0f;
            mUniformMap["uTime"].Set(time);
        }
    }
}