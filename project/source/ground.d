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
        MakeGround(width, depth);
    }

    /// Render the ground
    override void Render() {
        import std.stdio : writeln;
        glBindVertexArray(mVAO);
        glDrawElements(GL_TRIANGLES, cast(GLuint)mIndices, GL_UNSIGNED_INT, null);
    }

    /// Create ground geometry (a simple plane)
    void MakeGround(float width, float depth) {
        import std.stdio : writeln;
        
        // Vertex data for a plane
        // Format: x, y, z, nx, ny, nz
        GLfloat[] vertices = [
            -width/2, 0, -depth/2, 0, 1, 0,
            width/2, 0, -depth/2, 0, 1, 0,
            width/2, 0, depth/2, 0, 1, 0,
            -width/2, 0, depth/2, 0, 1, 0
        ];

        // Indices for the plane
        GLuint[] indices = [
            0, 1, 2, 2, 3, 0
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



class GroundMaterial : IMaterial {
    vec3 mBaseColor;           
    vec3 mRoadColor;       
    vec3 mSidewalkColor;    
    vec3 mZebraColor;       
    float mBlockSize;      
    float mStreetWidth;
    // Moon light properties
    vec3 mLightDirection = vec3(0.5f, -0.7f, 0.3f);
    vec3 mLightColor = vec3(0.6f, 0.7f, 0.9f);  // Cool moonlight color
    float mAmbientStrength = 0.1f;  // Low ambient light for night
    float mDiffuseStrength = 0.3f;  // Lower diffuse light for moonlight
    
    /// Constructor
    this(string pipelineName) {
        super(pipelineName);
        // Darker colors for night
        mBaseColor = vec3(0.1f, 0.3f, 0.1f);         
        mRoadColor = vec3(0.15f, 0.15f, 0.15f);     
        mSidewalkColor = vec3(0.4f, 0.4f, 0.38f);   
        mZebraColor = vec3(0.5f, 0.5f, 0.5f);      
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
            mUniformMap["uBaseColor"].Set(mBaseColor.DataPtr());
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
        
        // Set light uniforms
        if("uLightDirection" in mUniformMap) {
            mUniformMap["uLightDirection"].Set(mLightDirection.DataPtr());
        }
        
        if("uLightColor" in mUniformMap) {
            mUniformMap["uLightColor"].Set(mLightColor.DataPtr());
        }
        
        if("uAmbientStrength" in mUniformMap) {
            mUniformMap["uAmbientStrength"].Set(mAmbientStrength);
        }
        
        if("uDiffuseStrength" in mUniformMap) {
            mUniformMap["uDiffuseStrength"].Set(mDiffuseStrength);
        }
    }
}

