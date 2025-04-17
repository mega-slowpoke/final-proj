// City Graphics Application module
module city_app;

import std.stdio : writeln;
import std.file : exists, mkdirRecurse, write;
import std.path : buildPath;
import core;
import mesh, linear, scene, materials, geometry;
import cityrenderer, light;
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
                vec3(0.5f, 1.0f, 0.8f), // Direction (morning sun)
                vec3(1.0f, 0.95f, 0.8f), // warm light
                1.0f,  
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
        // Don't render sun if it's below the horizon
        if (mSunLight.mDirection.y < 0.0f) {
            return;
        }
        
        // Calculate sun position in screen space
        vec3 sunPos = mCamera.mEyePosition - mSunLight.mDirection * 100.0f;
        
        vec4 projectedSun = mCamera.mProjectionMatrix * mCamera.mViewMatrix * vec4(sunPos, 1.0);
        
        // Skip if behind the camera
        if (projectedSun.z < 0.0f) {
            return;
        }
        
        float x = projectedSun.x / projectedSun.w;
        float y = projectedSun.y / projectedSun.w;
        
        // Skip if outside visible area
        if (abs(x) > 1.0f || abs(y) > 1.0f) {
            return;
        }
        
        int screenX = cast(int)((x + 1.0f) * 0.5f * 800.0f);
        int screenY = cast(int)((1.0f - (y + 1.0f) * 0.5f) * 600.0f);

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