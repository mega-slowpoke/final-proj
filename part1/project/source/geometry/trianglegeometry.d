/// Triangle Creation
module trianglegeometry;

import bindbc.opengl;
import std.stdio;
import geometry;
import error;

/// Geometry stores all of the vertices and/or indices for a 3D object.
/// Geometry also has the responsibility of setting up the 'attributes'
class SurfaceTriangle: ISurface{
    GLuint mVBO;
    size_t mTriangles;

    /// Geometry data
    this(GLfloat[] vbo){
        MakeTriangleFactory(vbo);
    }

    /// Render our geometry
    override void Render(){
        // Bind to our geometry that we want to draw
        glBindVertexArray(mVAO);
        // Call our draw call
        glDrawArrays(GL_TRIANGLES,0,cast(int) mTriangles);
    }

    /// Setup MeshNode as a Triangle
    void MakeTriangleFactory(GLfloat[] vbo){
        // Compute the number of traingles.
        // Note: 6 floats per vertex, is why we are dividing by 6
        mTriangles = vbo.length / 6;

        // Vertex Arrays Object (VAO) Setup
        glGenVertexArrays(1, &mVAO);
        // We bind (i.e. select) to the Vertex Array Object (VAO) that we want to work withn.
        glBindVertexArray(mVAO);

        // Vertex Buffer Object (VBO) creation
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, vbo.length* GLfloat.sizeof, vbo.ptr, GL_STATIC_DRAW);

        // Function call to setup attributes
        SetVertexAttributes!VertexFormat3F3F();

        // Unbind our currently bound Vertex Array Object
        glBindVertexArray(0);

        // Turn off attributes
        DisableVertexAttributes!VertexFormat3F3F();
    }
}

/// Stores triangles that also have texture coordinates
class SurfaceTexturedTriangle: ISurface{
    GLuint mVBO;
    size_t mTriangles;

    /// Geometry data
    this(GLfloat[] vbo){
        MakeTriangleFactory(vbo);
    }

    /// Render our geometry
    override void Render(){
        // Bind to our geometry that we want to draw
        glBindVertexArray(mVAO);
        // Call our draw call
        glDrawArrays(GL_TRIANGLES,0,cast(int) mTriangles);
    }

    /// Setup MeshNode as a Triangle
    void MakeTriangleFactory(GLfloat[] vbo){

        // Compute the number of traingles.
        // Note: 5 floats per vertex, is why we are dividing by 5
        mTriangles = vbo.length / 5;

        // Vertex Arrays Object (VAO) Setup
        glGenVertexArrays(1, &mVAO);
        // We bind (i.e. select) to the Vertex Array Object (VAO) that we want to work withn.
        glBindVertexArray(mVAO);

        // Vertex Buffer Object (VBO) creation
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, vbo.length* GLfloat.sizeof, vbo.ptr, GL_STATIC_DRAW);

        // Function call to setup attributes
        SetVertexAttributes!VertexFormat3F2F();

        // Unbind our currently bound Vertex Array Object
        glBindVertexArray(0);

        // Turn off attributes
        DisableVertexAttributes!VertexFormat3F2F();
    }
}

/// Stores triangles that also have texture coordinates, normals, bitangents, and tangents
class SurfaceNormalMappedTriangle: ISurface{
    GLuint mVBO;
    size_t mTriangles;

    /// Geometry data
    this(GLfloat[] vbo){
        MakeTriangleFactory(vbo);
    }

    /// Render our geometry
    override void Render(){
        // Bind to our geometry that we want to draw
        glBindVertexArray(mVAO);
        // Call our draw call
        glDrawArrays(GL_TRIANGLES,0,cast(int) mTriangles);
    }

    /// Setup MeshNode as a Triangle
    void MakeTriangleFactory(GLfloat[] vbo){

        // Compute the number of traingles.
        // Note: 14 floats per vertex, is why we are dividing by 14
        mTriangles = vbo.length / 14;

        // Vertex Arrays Object (VAO) Setup
        glGenVertexArrays(1, &mVAO);
        // We bind (i.e. select) to the Vertex Array Object (VAO) that we want to work withn.
        glBindVertexArray(mVAO);

        // Vertex Buffer Object (VBO) creation
        glGenBuffers(1, &mVBO);
        glBindBuffer(GL_ARRAY_BUFFER, mVBO);
        glBufferData(GL_ARRAY_BUFFER, vbo.length* GLfloat.sizeof, vbo.ptr, GL_STATIC_DRAW);

        // Function call to setup attributes
        SetVertexAttributes!VertexFormat3F2F3F3F3F();

        // Unbind our currently bound Vertex Array Object
        glBindVertexArray(0);

        // Turn off attributes
        DisableVertexAttributes!VertexFormat3F2F();
    }
}


/// Helper function to return a textured quad
SurfaceTexturedTriangle MakeTexturedQuad(){
	return new SurfaceTexturedTriangle([
																				-1.0,1.0,0.0,  0.0,1.0,
																				-1.0,-1.0,0.0, 0.0,0.0,
																				1.0,-1.0,0.0,  1.0,0.0,
																				1.0,1.0,0.0, 1.0,1.0,
																				-1.0,1.0,0.0, 0.0,1.0,
																				1.0,-1.0,0.0, 1.0,0.0,
																		 ]
																		);
}

/// Helper function to return a textured quad with normals, binormals, and bitangents
SurfaceNormalMappedTriangle MakeTexturedNormalMappedQuad(){
  //TODO: For students to compute binormal and bitangents (either here, or by writing a helper function -- your choice!)
	return new SurfaceNormalMappedTriangle([
																				-1.0,1.0,0.0,  0.0,1.0,     0,0,-1.0, 0,0,0, 0,0,0,
																				-1.0,-1.0,0.0, 0.0,0.0,     0,0,-1.0, 0,0,0, 0,0,0,
																				1.0,-1.0,0.0,  1.0,0.0,     0,0,-1.0, 0,0,0, 0,0,0,
																				1.0,1.0,0.0,   1.0,1.0,     0,0,-1.0, 0,0,0, 0,0,0,
																				-1.0,1.0,0.0,  0.0,1.0,     0,0,-1.0, 0,0,0, 0,0,0,
																				1.0,-1.0,0.0,  1.0,0.0,     0,0,-1.0, 0,0,0, 0,0,0
																		 ]
																		);
}
