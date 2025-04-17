module sun;

import std.stdio;
import std.random : uniform;
import std.conv : to;
import core;
import mesh, linear, scene, materials, geometry;
import pipeline;
import bindbc.opengl;

class SurfaceSun : ISurface {
    GLuint mVBO;
    GLuint mIBO;
    size_t mIndices;

    // Create a quad for the sun
    this(float size) {
        MakeSun(size);
    }

    // Render the sun
    override void Render() {
        glBindVertexArray(mVAO);
        glDrawElements(GL_TRIANGLES, cast(GLuint)mIndices, GL_UNSIGNED_INT, null);
    }

    // Create sun geometry (a simple quad with position and texture coords)
    void MakeSun(float size) {
        // Vertex data for a quad
        // Format: x, y, z, tx, ty
        GLfloat[] vertices = [
            -size/2, -size/2, 0, 0, 0,
            size/2, -size/2, 0, 1, 0,
            size/2, size/2, 0, 1, 1,
            -size/2, size/2, 0, 0, 1
        ];

        // Indices for the quad
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
        SetVertexAttributes!VertexFormat3F2F();

        // Unbind
        glBindVertexArray(0);
        DisableVertexAttributes!VertexFormat3F2F();
    }
}

class SunMaterial : IMaterial {
    vec3 mSunColor;

    // Constructor
    this(string pipelineName, vec3 color) {
        super(pipelineName);
        mSunColor = color;
    }

    // Update the material
    override void Update() {
        // Set our active Shader graphics pipeline 
        PipelineUse(mPipelineName);
        
        // Set uniforms
        if("uSunColor" in mUniformMap) {
            mUniformMap["uSunColor"].Set(mSunColor.DataPtr());
        }
    }
}