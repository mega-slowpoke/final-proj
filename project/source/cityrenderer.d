/// Custom city renderer implementation
module cityrenderer;

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

/// Surface class for creating a plane as ground
class SurfaceGround : ISurface {
    GLuint mVBO;
    GLuint mIBO;
    size_t mIndices;

    /// Create a ground plane
    this(float width, float depth) {
        import std.stdio : writeln;
        writeln("DEBUG: Inside SurfaceGround constructor");
        MakeGround(width, depth);
        writeln("DEBUG: SurfaceGround constructor completed");
    }

    /// Render the ground
    override void Render() {
        import std.stdio : writeln;
        writeln("DEBUG: SurfaceGround render called");
        glBindVertexArray(mVAO);
        glDrawElements(GL_TRIANGLES, cast(GLuint)mIndices, GL_UNSIGNED_INT, null);
        writeln("DEBUG: SurfaceGround render completed");
    }

    /// Create ground geometry (a simple plane)
    void MakeGround(float width, float depth) {
        import std.stdio : writeln;
        writeln("DEBUG: MakeGround - starting geometry creation");
        
        // Vertex data for a plane
        // Format: x, y, z, nx, ny, nz
        GLfloat[] vertices = [
            -width/2, 0, -depth/2, 0, 1, 0,
            width/2, 0, -depth/2, 0, 1, 0,
            width/2, 0, depth/2, 0, 1, 0,
            -width/2, 0, depth/2, 0, 1, 0
        ];
        writeln("DEBUG: MakeGround - vertices created");

        // Indices for the plane
        GLuint[] indices = [
            0, 1, 2, 2, 3, 0
        ];
        writeln("DEBUG: MakeGround - indices created");

        mIndices = indices.length;

        // Create VAO
        writeln("DEBUG: MakeGround - creating VAO");
        glGenVertexArrays(1, &mVAO);
        glBindVertexArray(mVAO);
        writeln("DEBUG: MakeGround - VAO created and bound");

        // Create IBO
        writeln("DEBUG: MakeGround - creating IBO");
        glGenBuffers(1, &mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.length * GLuint.sizeof, indices.ptr, GL_STATIC_DRAW);
        writeln("DEBUG: MakeGround - IBO created and data loaded");

        // Create VBO
        writeln("DEBUG: MakeGround - creating VBO");
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * GLfloat.sizeof, vertices.ptr, GL_STATIC_DRAW);
        writeln("DEBUG: MakeGround - VBO created and data loaded");

        // Set vertex attributes
        writeln("DEBUG: MakeGround - setting vertex attributes");
        SetVertexAttributes!VertexFormat3F3F();
        writeln("DEBUG: MakeGround - vertex attributes set");

        // Unbind
        glBindVertexArray(0);
        DisableVertexAttributes!VertexFormat3F3F();
        writeln("DEBUG: MakeGround - completed");
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

/// Ground material with green color
class GroundMaterial : IMaterial {
    vec3 mColor;

    /// Constructor
    this(string pipelineName) {
        super(pipelineName);
        // Fixed green color
        mColor = vec3(0.2f, 0.7f, 0.2f);
    }

    /// Override update to set ground color
    override void Update() {
        // Set our active Shader graphics pipeline 
        PipelineUse(mPipelineName);
        
        // Set any uniforms for our mesh if they exist in the shader
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

/// City generator class
class CityGenerator {
    SceneTree mSceneTree;
    Pipeline mBuildingPipeline;
    Pipeline mGroundPipeline;
    
    // City parameters
    int mGridSize = 8;       // Grid size (8x8 buildings) - reduced for stability
    float mBlockSize = 2.0f; // Size of a city block
    float mStreetWidth = 1.0f; // Width of streets
    float mGroundSize;       // Total ground size
    
    /// Constructor
    this(SceneTree sceneTree) {
        import std.stdio : writeln;
        try {
            writeln("DEBUG CITYGEN: Starting CityGenerator constructor");
            mSceneTree = sceneTree;
            writeln("DEBUG CITYGEN: Scene tree assigned");
            
            mGroundSize = (mGridSize * mBlockSize) + ((mGridSize - 1) * mStreetWidth);
            writeln("DEBUG CITYGEN: Ground size calculated: ", mGroundSize);
            
            // Create custom pipelines for buildings and ground
            writeln("DEBUG CITYGEN: About to create shader pipelines");
            createShaderPipelines();
            writeln("DEBUG CITYGEN: Shader pipelines created");
            
            writeln("DEBUG CITYGEN: CityGenerator constructor completed");
        } 
        catch (Exception e) {
            writeln("ERROR in CityGenerator constructor: ", e.msg);
            throw e;
        }
    }
    
    /// Create shader pipelines for the city
    void createShaderPipelines() {
        import std.stdio : writeln;
        import std.file : exists, readText;
        
        try {
            writeln("DEBUG CITYGEN: createShaderPipelines - Starting shader pipeline creation");
            
            // Check if files exist and print their content
            writeln("DEBUG CITYGEN: Building shader files exist: ", 
                    exists("./pipelines/city/building.vert"), " ", 
                    exists("./pipelines/city/building.frag"));
            
            writeln("DEBUG CITYGEN: Ground shader files exist: ", 
                    exists("./pipelines/city/ground.vert"), " ", 
                    exists("./pipelines/city/ground.frag"));
            
            // Try reading the ground shader files
            if (exists("./pipelines/city/ground.vert")) {
                string vertexShaderContent = readText("./pipelines/city/ground.vert");
                writeln("DEBUG CITYGEN: Ground vertex shader length: ", vertexShaderContent.length);
            }
            
            if (exists("./pipelines/city/ground.frag")) {
                string fragmentShaderContent = readText("./pipelines/city/ground.frag");
                writeln("DEBUG CITYGEN: Ground fragment shader length: ", fragmentShaderContent.length);
            }
            
            // Create pipeline for buildings
            writeln("DEBUG CITYGEN: Creating building pipeline");
            mBuildingPipeline = new Pipeline("building", 
                                            "./pipelines/city/building.vert", 
                                            "./pipelines/city/building.frag");
            writeln("DEBUG CITYGEN: Building pipeline created");
            
            // Create pipeline for ground - with try/catch specifically for this
            writeln("DEBUG CITYGEN: Creating ground pipeline");
            try {
                mGroundPipeline = new Pipeline("ground", 
                                            "./pipelines/city/ground.vert", 
                                            "./pipelines/city/ground.frag");
                writeln("DEBUG CITYGEN: Ground pipeline created");
            } catch (Exception e) {
                writeln("ERROR specifically in ground pipeline creation: ", e.msg);
                // Continue with program rather than crashing
            }
            
            writeln("DEBUG CITYGEN: createShaderPipelines - Pipelines created successfully");
        } catch (Exception e) {
            writeln("ERROR creating pipelines: ", e.msg);
            // Don't rethrow - try to continue running the program
        }
    }
    
    void generateCity() {
        try {
            import std.stdio : writeln;
            
            // Create ground
            createGround();
            
            // Create buildings - with various shapes
            for (int x = 0; x < mGridSize; x++) {
                for (int z = 0; z < mGridSize; z++) {
                    // Every third building will be cylindrical
                    if ((x + z) % 3 == 0) {
                        createCylindricalBuilding(x, z);
                    } else {
                        createBuilding(x, z);
                    }
                }
            }
        } catch (Exception e) {
            import std.stdio : writeln;
            writeln("Error generating city: ", e.msg);
        }
    }
    

    void createGround() {
        try {
            // Create ground mesh
            ISurface groundSurface = new SurfaceGround(mGroundSize, mGroundSize);
            
            // Create ground material with proper pipeline
            IMaterial groundMaterial = new GroundMaterial("building");
            
            // Add all uniforms needed by the shader
            groundMaterial.AddUniform(new Uniform("uModel", "mat4", null));
            groundMaterial.AddUniform(new Uniform("uView", "mat4", null));
            groundMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
            groundMaterial.AddUniform(new Uniform("uBaseColor", "vec3", vec3(0.2f, 0.7f, 0.2f).DataPtr()));
            
            // Create mesh node and add to scene
            MeshNode groundNode = new MeshNode("ground", groundSurface, groundMaterial);
            groundNode.mModelMatrix = MatrixMakeTranslation(vec3(0.0f, 0.0f, 0.0f));
            
            mSceneTree.GetRootNode().AddChildSceneNode(groundNode);
        } catch (Exception e) {
            import std.stdio : writeln;
            writeln("Error creating ground: ", e.msg);
        }
    }
        
    /// Create a building at grid position (x, z)
    void createBuilding(int x, int z) {
        // Using fixed values instead of random to ensure stability during debugging
        float buildingHeight = 4.0f + (x % 3) + (z % 4); // Deterministic height pattern
        float buildingWidth = mBlockSize * 0.8f;
        float buildingDepth = mBlockSize * 0.8f;
        
        // Calculate building position
        float posX = (x * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
        float posZ = (z * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
        
        // Create building color (variation of gray)
        float colorValue = 0.4f + (((x + z) % 5) / 10.0f); // Deterministic color
        vec3 buildingColor = vec3(colorValue, colorValue, colorValue);
        
        // Create building mesh
        ISurface buildingSurface = new SurfaceBuilding(buildingWidth, buildingHeight, buildingDepth);
        IMaterial buildingMaterial = new BuildingMaterial("building", buildingColor);
        
        // Add uniforms to the building material
        buildingMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uView", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uBaseColor", "vec3", buildingColor.DataPtr()));
        
        // Create building node and add to scene
        string buildingName = "building_" ~ x.to!string ~ "_" ~ z.to!string;
        MeshNode buildingNode = new MeshNode(buildingName, buildingSurface, buildingMaterial);
        buildingNode.mModelMatrix = MatrixMakeTranslation(vec3(posX, 0.0f, posZ));
        
        mSceneTree.GetRootNode().AddChildSceneNode(buildingNode);
    }

    void createCylindricalBuilding(int x, int z) {
        // Deterministic values for cylindrical buildings
        float buildingHeight = 5.0f + (x % 4) + (z % 5); // Make cylindrical buildings taller
        float radius = mBlockSize * 0.4f;
        
        // Calculate building position
        float posX = (x * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
        float posZ = (z * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
        
        // Create building color - different tint for cylindrical buildings
        float colorValue = 0.4f + (((x + z) % 5) / 10.0f);
        vec3 buildingColor = vec3(colorValue, colorValue * 0.95f, colorValue * 0.9f);
        
        // Create cylindrical building mesh
        ISurface buildingSurface = new SurfaceCylindricalBuilding(radius, buildingHeight, 16);
        IMaterial buildingMaterial = new BuildingMaterial("building", buildingColor);
        
        // Add uniforms to the building material
        buildingMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uView", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uBaseColor", "vec3", buildingColor.DataPtr()));
        
        // Create building node and add to scene
        string buildingName = "building_cyl_" ~ x.to!string ~ "_" ~ z.to!string;
        MeshNode buildingNode = new MeshNode(buildingName, buildingSurface, buildingMaterial);
        buildingNode.mModelMatrix = MatrixMakeTranslation(vec3(posX, 0.0f, posZ));
        
        mSceneTree.GetRootNode().AddChildSceneNode(buildingNode);
    }
}