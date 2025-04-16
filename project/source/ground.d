module ground;

import std.stdio;
import std.random : uniform;
import std.conv : to;
import core;
import mesh, linear, scene, materials, geometry;
import pipeline;
import bindbc.opengl;


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



/// Ground material with green color
// Modified GroundMaterial class in cityrenderer.d
class GroundMaterial : IMaterial {
    vec3 mColor;            // Base ground/grass color
    vec3 mRoadColor;        // Road color
    vec3 mSidewalkColor;    // Sidewalk color
    vec3 mZebraColor;       // Zebra crossing color
    float mBlockSize;       // Size of city blocks
    float mStreetWidth;     // Width of streets
    
    /// Constructor
    this(string pipelineName) {
        super(pipelineName);
        // Default colors
        mColor = vec3(0.2f, 0.7f, 0.2f);           // Green for grass
        mRoadColor = vec3(0.3f, 0.3f, 0.3f);        // Dark gray for asphalt
        mSidewalkColor = vec3(0.75f, 0.75f, 0.7f);  // Light gray for sidewalks
        mZebraColor = vec3(0.9f, 0.9f, 0.9f);       // White for zebra crossings
    }
    
    /// Set the city layout parameters (from city generator)
    void SetCityParams(float blockSize, float streetWidth) {
        mBlockSize = blockSize;
        mStreetWidth = streetWidth;
    }
    
    /// Override update to set ground color
    override void Update() {
        // Set our active Shader graphics pipeline 
        PipelineUse(mPipelineName);
        
        // Set basic uniforms for our mesh if they exist in the shader
        if("uBaseColor" in mUniformMap) {
            mUniformMap["uBaseColor"].Set(mColor.DataPtr());
        }
        
        // Set road-specific uniforms
        if("uRoadColor" in mUniformMap) {
            mUniformMap["uRoadColor"].Set(mRoadColor.DataPtr());
        }
        
        if("uSidewalkColor" in mUniformMap) {
            mUniformMap["uSidewalkColor"].Set(mSidewalkColor.DataPtr());
        }
        
        if("uZebraColor" in mUniformMap) {
            mUniformMap["uZebraColor"].Set(mZebraColor.DataPtr());
        }
        
        if("uBlockSize" in mUniformMap) {
            mUniformMap["uBlockSize"].Set(mBlockSize);
        }
        
        if("uStreetWidth" in mUniformMap) {
            mUniformMap["uStreetWidth"].Set(mStreetWidth);
        }
    }
}

// Modified createGround function in CityGenerator class
