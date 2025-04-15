/// OBJ File Creation
module objgeometry;

import bindbc.opengl;
import std.stdio;
import geometry;
import error;

/// Geometry stores all of the vertices and/or indices for a 3D object.
/// Geometry also has the responsibility of setting up the 'attributes'
class SurfaceOBJ : ISurface{
    GLuint mVBO;
    GLuint mIBO;
    GLfloat[] mVertexData;
	GLfloat[] mNormalData;
	GLfloat[] mTextureData;
    GLuint[] mIndexData;
    size_t mTriangles;

    /// Geometry data
    this(string filename){
        MakeOBJ(filename);
    }

    /// Render our geometry
    override void Render(){
        // Bind to our geometry that we want to draw
        glBindVertexArray(mVAO);
        // Call our draw call
        glDrawElements(GL_TRIANGLES,cast(GLuint)mIndexData.length,GL_UNSIGNED_INT,null);
    }

    void MakeOBJ(string filepath){

		// TODO 
		// You can erase all of this code, or otherwise add the parsing of your OBJ
		// file here.

		
        // Vertex Arrays Object (VAO) Setup
        glGenVertexArrays(1, &mVAO);
        // We bind (i.e. select) to the Vertex Array Object (VAO) 
        // that we want to work withn.
        glBindVertexArray(mVAO);

        // Index Buffer Object (IBO)
        glGenBuffers(1, &mIBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, mIBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, mIndexData.length* GLuint.sizeof, mIndexData.ptr, GL_STATIC_DRAW);

        // Vertex Buffer Object (VBO) creation
        GLfloat[] allData;
        for(size_t i=0; i < mVertexData.length; i+=3){
            allData ~= mVertexData[i];
            allData ~= mVertexData[i+1];
            allData ~= mVertexData[i+2];
            allData ~= mNormalData[i];
            allData ~= mNormalData[i+1];
            allData ~= mNormalData[i+2];
        }

        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, allData.length* VertexFormat3F3F.sizeof, allData.ptr, GL_STATIC_DRAW);

        // Function call to setup attributes
        SetVertexAttributes!VertexFormat3F3F();

        // Unbind our currently bound Vertex Array Object
        glBindVertexArray(0);
        // Turn off attributes
        DisableVertexAttributes!VertexFormat3F3F();
    }
}

