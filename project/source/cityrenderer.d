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
        writeln("DEBUG: MakeGround - unbinding VAO");
        glBindVertexArray(0);
        writeln("DEBUG: MakeGround - disabling vertex attributes");
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

    /// Override update to set building color
    override void Update() {
        // Set our active Shader graphics pipeline 
        PipelineUse(mPipelineName);
        
        // Set any uniforms for our mesh if they exist in the shader
        if("uBuildingColor" in mUniformMap) {
            mUniformMap["uBuildingColor"].Set(mColor.DataPtr());
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
        if("uGroundColor" in mUniformMap) {
            mUniformMap["uGroundColor"].Set(mColor.DataPtr());
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
    
    /// Generate the entire city
    void generateCity() {
        try {
            // Debug print
            import std.stdio : writeln;
            writeln("DEBUG: Starting city generation");
            
            // Create ground
            writeln("DEBUG: About to create ground");
            createGround();
            writeln("DEBUG: Ground created successfully");
            
            // Create buildings - reduced number for debugging
            writeln("DEBUG: About to create buildings");
            for (int x = 0; x < mGridSize; x++) {
                for (int z = 0; z < mGridSize; z++) {
                    writeln("DEBUG: Creating building at (", x, ",", z, ")");
                    createBuilding(x, z);
                    writeln("DEBUG: Building at (", x, ",", z, ") created successfully");
                }
            }
            writeln("DEBUG: All buildings created successfully");
        } catch (Exception e) {
            import std.stdio : writeln;
            writeln("Error generating city: ", e.msg);
        }
    }
    
    /// Create ground plane
    void createGround() {
        try {
            import std.stdio : writeln;
            writeln("DEBUG: Creating ground surface");
            // Create ground mesh
            ISurface groundSurface = new SurfaceGround(mGroundSize, mGroundSize);
            writeln("DEBUG: Ground surface created");
            
            writeln("DEBUG: Creating ground material");
            IMaterial groundMaterial = new GroundMaterial("ground");
            writeln("DEBUG: Ground material created");
            
            // Create a fixed green color for the ground
            vec3 groundColor = vec3(0.2f, 0.7f, 0.2f); // Green color
            
            writeln("DEBUG: Adding uniforms to ground material");
            // Add uniforms to the ground material
            groundMaterial.AddUniform(new Uniform("uModel", "mat4", null));
            writeln("DEBUG: Added uModel uniform");
            groundMaterial.AddUniform(new Uniform("uView", "mat4", null));
            writeln("DEBUG: Added uView uniform");
            groundMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
            writeln("DEBUG: Added uProjection uniform");
            groundMaterial.AddUniform(new Uniform("uGroundColor", "vec3", groundColor.DataPtr()));
            writeln("DEBUG: Added uGroundColor uniform");
            
            writeln("DEBUG: Creating ground node");
            // Create mesh node and add to scene
            MeshNode groundNode = new MeshNode("ground", groundSurface, groundMaterial);
            groundNode.mModelMatrix = MatrixMakeTranslation(vec3(0.0f, 0.0f, 0.0f));
            writeln("DEBUG: Ground model matrix set");
            
            writeln("DEBUG: Adding ground node to scene");
            mSceneTree.GetRootNode().AddChildSceneNode(groundNode);
            writeln("DEBUG: Ground node added to scene");
        } catch (Exception e) {
            import std.stdio : writeln;
            writeln("Error creating ground: ", e.msg);
            throw e;
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
        buildingMaterial.AddUniform(new Uniform("uBuildingColor", "vec3", buildingColor.DataPtr()));
        
        // Create building node and add to scene
        string buildingName = "building_" ~ x.to!string ~ "_" ~ z.to!string;
        MeshNode buildingNode = new MeshNode(buildingName, buildingSurface, buildingMaterial);
        buildingNode.mModelMatrix = MatrixMakeTranslation(vec3(posX, 0.0f, posZ));
        
        mSceneTree.GetRootNode().AddChildSceneNode(buildingNode);
    }
}