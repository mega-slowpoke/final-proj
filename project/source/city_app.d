// City Graphics Application module
module city_app;

import std.stdio : writeln;
import std.file : exists, mkdirRecurse, write;
import std.path : buildPath;
import core;
import mesh, linear, scene, materials, geometry;
import cityrenderer, light, sun;
import platform;


import bindbc.sdl;
import bindbc.opengl;
import std.math;

/// The main city graphics application.
struct CityGraphicsApp {
    bool mGameIsRunning = true;
    bool mRenderWireframe = false;
    SDL_GLContext mContext;
    SDL_Window* mWindow;
    
    DirectionalLight mSunLight;

    bool mSunInitialized = false;
GLuint mSunVAO;
GLuint mSunVBO;
Pipeline mSunPipeline;

    // MeshNode mSunNode;
    // Pipeline mSunPipeline;

    // Scene
    SceneTree mSceneTree;
    // Camera
    Camera mCamera;
    // Renderer
    Renderer mRenderer;
    // City Generator
    CityGenerator mCityGenerator;

    /// Setup OpenGL and any libraries
    this(int major_ogl_version, int minor_ogl_version) {
        try {            
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, major_ogl_version);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, minor_ogl_version);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
            
            // We want to request a double buffer for smooth updating.
            SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
            SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

            // Create an application window using OpenGL that supports SDL
            writeln("DEBUG CONSTRUCTOR: Creating SDL window");
            mWindow = SDL_CreateWindow("City Renderer - OpenGL",
                                      SDL_WINDOWPOS_UNDEFINED,
                                      SDL_WINDOWPOS_UNDEFINED,
                                      800,
                                      600,
                                      SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);

            writeln("DEBUG CONSTRUCTOR: Creating OpenGL context");
            mContext = SDL_GL_CreateContext(mWindow);

            auto retVal = LoadOpenGLLib();

            GetOpenGLVersionInfo();

            mRenderer = new Renderer(mWindow, 800, 600);

            mCamera = new Camera();
            mCamera.SetCameraPosition(0.0f, 15.0f, 40.0f);
            mCamera.UpdateViewMatrix();

            mSceneTree = new SceneTree("root");
            
            mCityGenerator = new CityGenerator(mSceneTree);
            
            mSunLight = new DirectionalLight(
                vec3(0.2f, 0.8f, 0.4f), // Direction (strong Y component for high sun)
                vec3(1.0f, 0.95f, 0.8f), // warm light
                1.5f,  // Increased intensity
                true   
            );

            writeln("DEBUG CONSTRUCTOR: Constructor completed successfully");
        }
        catch (Exception e) {
            writeln("FATAL ERROR in constructor: ", e.msg);
            throw e;
        }
    }

    /// Destructor
    ~this() {
        SDL_GL_DeleteContext(mContext);
        SDL_DestroyWindow(mWindow);
    }

    /// Handle input
    void Input() {
        // Store an SDL Event
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) {
                writeln("Exit event triggered (probably clicked 'x' at top of the window)");
                mGameIsRunning = false;
            }
            if (event.type == SDL_KEYDOWN) {
                if (event.key.keysym.scancode == SDL_SCANCODE_ESCAPE) {
                    writeln("Pressed escape key and now exiting...");
                    mGameIsRunning = false;
                } else if (event.key.keysym.sym == SDLK_TAB) {
                    mRenderWireframe = !mRenderWireframe;
                } else if (event.key.keysym.sym == SDLK_DOWN) {
                    mCamera.MoveBackward();
                } else if (event.key.keysym.sym == SDLK_UP) {
                    mCamera.MoveForward();
                } else if (event.key.keysym.sym == SDLK_LEFT) {
                    mCamera.MoveLeft();
                } else if (event.key.keysym.sym == SDLK_RIGHT) {
                    mCamera.MoveRight();
                } else if (event.key.keysym.sym == SDLK_a) {
                    mCamera.MoveUp();
                } else if (event.key.keysym.sym == SDLK_z) {
                    mCamera.MoveDown();
                }
                writeln("Camera Position: ", mCamera.mEyePosition);
            }
        }

        // Retrieve the mouse position
        int mouseX, mouseY;
        SDL_GetMouseState(&mouseX, &mouseY);
        mCamera.MouseLook(mouseX, mouseY);
    }

    void SetupScene() {
        try {
            writeln("DEBUG: SetupScene - Starting scene setup");
            
            // Create shader files if they don't exist
            // Ensure pipelines/city directory exists
            writeln("DEBUG: SetupScene - Checking pipelines directory");
            if (!exists("pipelines/city")) {
                writeln("DEBUG: SetupScene - Creating pipelines directory");
                mkdirRecurse("pipelines/city");
            }
            
            // Create basic vertex shader for buildings
            writeln("DEBUG: SetupScene - Checking building vertex shader");
            if (!exists("pipelines/city/building.vert")) {
                writeln("DEBUG: SetupScene - building vertex shader doesn't exist");
            }
            
            // Create basic fragment shader for buildings
            writeln("DEBUG: SetupScene - Checking building fragment shader");
            if (!exists("pipelines/city/building.frag")) {
                writeln("DEBUG: SetupScene - building fragment shader doesn't exist");
            }
            
            writeln("DEBUG: SetupScene - Checking ground vertex shader");
            if (!exists("pipelines/city/ground.vert")) {
                writeln("DEBUG: SetupScene - ground vertex shader doesn't exist");
            }
            
            // Create basic fragment shader for ground
            writeln("DEBUG: SetupScene - Checking ground fragment shader");
            if (!exists("pipelines/city/ground.frag")) {
                writeln("DEBUG: SetupScene - ground fragment shader doesn't exist");
            }
            
            // Make sure the camera view matrix is updated
            writeln("DEBUG: SetupScene - Updating camera view matrix");
            mCamera.UpdateViewMatrix();
            
            // Generate the city
            writeln("DEBUG: SetupScene - Generating city");
            mCityGenerator.generateCity();
            
            // Update matrices for all rendered objects
            writeln("DEBUG: SetupScene - Updating matrices");
            updateMatrices();
            

            // // Setup sun rendering
            // if (!exists("pipelines/city/sun.vert") || !exists("pipelines/city/sun.frag")) {
            //     writeln("Creating sun shader files...");
            //     // Write the shader files (code omitted - create them manually)
            // }
    
            // // Create sun pipeline
            // mSunPipeline = new Pipeline("sun", 
            //                         "./pipelines/city/sun.vert", 
            //                         "./pipelines/city/sun.frag");
        
            // // Create sun surface and material
            // ISurface sunSurface = new SurfaceSun(5.0f);
            // vec3 sunColor = vec3(1.0f, 0.9f, 0.7f);
            // IMaterial sunMaterial = new SunMaterial("sun", sunColor);
            
            // sunMaterial.AddUniform(new Uniform("uModel", "mat4", null));
            // sunMaterial.AddUniform(new Uniform("uView", "mat4", null));
            // sunMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
            // sunMaterial.AddUniform(new Uniform("uSunColor", "vec3", sunColor.DataPtr()));
            
            // mSunNode = new MeshNode("sun", sunSurface, sunMaterial);
            // mSceneTree.GetRootNode().AddChildSceneNode(mSunNode);

            writeln("DEBUG: SetupScene - Scene setup complete");
        } catch (Exception e) {
            writeln("Error in SetupScene: ", e.msg);
        }
    }
    
    /// Helper function to update matrices in all nodes
    void updateMatrices() {
        try {
            foreach (node; mSceneTree.GetRootNode().mChildren) {
                if (MeshNode meshNode = cast(MeshNode)node) {
                    // Update view and projection matrices for all meshes
                    auto material = meshNode.GetMaterial();
                    if ("uView" in material.mUniformMap) {
                        material.mUniformMap["uView"].Set(mCamera.mViewMatrix.DataPtr());
                    }
                    if ("uProjection" in material.mUniformMap) {
                        material.mUniformMap["uProjection"].Set(mCamera.mProjectionMatrix.DataPtr());
                    }
                }
            }
        } catch (Exception e) {
            writeln("Error updating matrices: ", e.msg);
        }
    }

    void Update() {
        try {
            // Update sun position
            mSunLight.Update();
            
            // Update camera view matrix
            mCamera.UpdateViewMatrix();
            
            // Update all meshes' uniforms
            foreach (node; mSceneTree.GetRootNode().mChildren) {
                if (MeshNode meshNode = cast(MeshNode)node) {
                    auto material = meshNode.GetMaterial();
                    if ("uView" in material.mUniformMap) {
                        material.mUniformMap["uView"].Set(mCamera.mViewMatrix.DataPtr());
                    }
                    
                    if ("uLightDirection" in material.mUniformMap) {
                        material.mUniformMap["uLightDirection"].Set(mSunLight.mDirection.DataPtr());
                    }
                    if ("uLightColor" in material.mUniformMap) {
                        material.mUniformMap["uLightColor"].Set(mSunLight.mColor.DataPtr());
                    }
                    if ("uLightIntensity" in material.mUniformMap) {
                        material.mUniformMap["uLightIntensity"].Set(mSunLight.mIntensity);
                    }
                }
            }
        } catch (Exception e) {
            writeln("Error in Update: ", e.msg);
        }
    }

    /// Render our scene by traversing the scene tree from a specific viewpoint
    void Render() {
        if (mRenderWireframe) {
            glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        } else {
            glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        }

        mRenderer.Render(mSceneTree, mCamera);
        RenderSun();
    }


void RenderSun() {
    writeln("DEBUG: RenderSun called");
    
    // Don't render sun if it's below the horizon
    if (mSunLight.mDirection.y < 0.0f) {
        writeln("DEBUG: Sun below horizon, not rendering");
        return;
    }
    
    // Static VAO and VBO for the sun
    static GLuint sunVAO = 0;
    static GLuint sunVBO = 0;
    
    // Create sun mesh if not already done
    if (sunVAO == 0) {
        // Create a simple quad for the sun
        GLfloat[] vertices = [
            -1.0f, -1.0f, 0.0f,  // Vertex 1 (positions)
             1.0f, -1.0f, 0.0f,  // Vertex 2
             1.0f,  1.0f, 0.0f,  // Vertex 3
            -1.0f,  1.0f, 0.0f   // Vertex 4
        ];
        
        // Create VAO
        glGenVertexArrays(1, &sunVAO);
        glBindVertexArray(sunVAO);
        
        // Create VBO
        glGenBuffers(1, &sunVBO);
        glBindBuffer(GL_ARRAY_BUFFER, sunVBO);
        glBufferData(GL_ARRAY_BUFFER, vertices.length * GLfloat.sizeof, vertices.ptr, GL_STATIC_DRAW);
        
        // Position attribute
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * GLfloat.sizeof, null);
        
        glBindVertexArray(0);
    }
    
    // Calculate position of sun in world space
    vec3 sunWorldPos = mCamera.mEyePosition - mSunLight.mDirection * 50.0f;
    
    // Create a simple shader for the sun if it doesn't exist
    if (!("sun_simple" in Pipeline.sPipeline)) {
        // Create temporary shader files if they don't exist
        if (!exists("pipelines/city/sun_simple.vert")) {
            write("pipelines/city/sun_simple.vert", 
                "#version 410 core\n" ~
                "layout(location=0) in vec3 aPosition;\n" ~
                "uniform mat4 uMVP;\n" ~
                "void main() {\n" ~
                "    gl_Position = uMVP * vec4(aPosition, 1.0);\n" ~
                "}\n");
        }
        
        if (!exists("pipelines/city/sun_simple.frag")) {
            write("pipelines/city/sun_simple.frag", 
                "#version 410 core\n" ~
                "out vec4 fragColor;\n" ~
                "uniform vec3 uSunColor;\n" ~
                "void main() {\n" ~
                "    fragColor = vec4(uSunColor, 1.0);\n" ~
                "}\n");
        }
        
        new Pipeline("sun_simple", 
                    "pipelines/city/sun_simple.vert", 
                    "pipelines/city/sun_simple.frag");
    }
    
    // Use the simple sun shader
    PipelineUse("sun_simple");
    
    // Set shader uniforms
    GLint mvpLoc = glGetUniformLocation(Pipeline.sPipeline["sun_simple"], "uMVP");
    GLint colorLoc = glGetUniformLocation(Pipeline.sPipeline["sun_simple"], "uSunColor");
    
    // Calculate model-view-projection matrix
    mat4 model = MatrixMakeTranslation(sunWorldPos) * MatrixMakeScale(vec3(2.0f, 2.0f, 2.0f));
    mat4 mvp = mCamera.mProjectionMatrix * mCamera.mViewMatrix * model;
    
    // Set uniforms
    glUniformMatrix4fv(mvpLoc, 1, GL_TRUE, mvp.DataPtr());
    glUniform3f(colorLoc, 1.0f, 0.9f, 0.5f); // Yellow-orange sun
    
    // Draw sun
    glBindVertexArray(sunVAO);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glBindVertexArray(0);
    
    writeln("DEBUG: Drew sun at position: ", sunWorldPos);
}

    /// Process 1 frame
    void AdvanceFrame() {
        Input();
        Update();
        Render();
        
        SDL_Delay(16); // Cap framerate at approximately 60 FPS
    }

    /// Main application loop
    void Loop() {
        try {
            writeln("DEBUG: About to set up scene");
            // Setup the graphics scene
            SetupScene();
            writeln("DEBUG: Scene setup complete, starting main loop");

            // Run the graphics application loop
            while (mGameIsRunning) {
                writeln("DEBUG: Processing frame");
                AdvanceFrame();
                writeln("DEBUG: Frame processed");
            }
        } catch (Exception e) {
            writeln("ERROR in main loop: ", e.msg);
        }
    }
}