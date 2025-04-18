// City Graphics Application module
module city_app;

import std.stdio : writeln;
import std.file : exists, mkdirRecurse, write;
import std.path : buildPath;
import core;
import mesh, linear, scene, materials, geometry;
import cityrenderer;
import platform;

import bindbc.sdl;
import bindbc.opengl;

/// The main city graphics application.
struct CityGraphicsApp {
    bool mGameIsRunning = true;
    bool mRenderWireframe = false;
    SDL_GLContext mContext;
    SDL_Window* mWindow;

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
            writeln("DEBUG CONSTRUCTOR: Starting constructor");
            
            writeln("DEBUG CONSTRUCTOR: Setting up SDL OpenGL");
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, major_ogl_version);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, minor_ogl_version);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
            
            // We want to request a double buffer for smooth updating.
            SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
            SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
            writeln("DEBUG CONSTRUCTOR: SDL attributes set");

            // Create an application window using OpenGL that supports SDL
            writeln("DEBUG CONSTRUCTOR: Creating SDL window");
            mWindow = SDL_CreateWindow("City Renderer - OpenGL",
                                      SDL_WINDOWPOS_UNDEFINED,
                                      SDL_WINDOWPOS_UNDEFINED,
                                      800,
                                      600,
                                      SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
            writeln("DEBUG CONSTRUCTOR: SDL window created");

            writeln("DEBUG CONSTRUCTOR: Creating OpenGL context");
            mContext = SDL_GL_CreateContext(mWindow);
            writeln("DEBUG CONSTRUCTOR: OpenGL context created");

            // Load OpenGL Function calls
            writeln("DEBUG CONSTRUCTOR: Loading OpenGL library");
            auto retVal = LoadOpenGLLib();
            writeln("DEBUG CONSTRUCTOR: OpenGL library loaded");

            writeln("DEBUG CONSTRUCTOR: Getting OpenGL version");
            GetOpenGLVersionInfo();
            writeln("DEBUG CONSTRUCTOR: OpenGL version checked");

            writeln("DEBUG CONSTRUCTOR: Creating renderer");
            mRenderer = new Renderer(mWindow, 800, 600);
            writeln("DEBUG CONSTRUCTOR: Renderer created");

            writeln("DEBUG CONSTRUCTOR: Creating camera");
            mCamera = new Camera();
            writeln("DEBUG CONSTRUCTOR: Camera created");
            
            writeln("DEBUG CONSTRUCTOR: Positioning camera");
            mCamera.SetCameraPosition(0.0f, 15.0f, 40.0f);
            writeln("DEBUG CONSTRUCTOR: Camera positioned");
            
            writeln("DEBUG CONSTRUCTOR: Updating camera view matrix");
            mCamera.UpdateViewMatrix();
            writeln("DEBUG CONSTRUCTOR: Camera view matrix updated");

            writeln("DEBUG CONSTRUCTOR: Creating scene tree");
            mSceneTree = new SceneTree("root");
            writeln("DEBUG CONSTRUCTOR: Scene tree created");
            
            writeln("DEBUG CONSTRUCTOR: Creating city generator");
            mCityGenerator = new CityGenerator(mSceneTree);
            writeln("DEBUG CONSTRUCTOR: City generator created");
            
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

    /// Update gamestate
    void Update() {
        try {
            // Update camera view matrix
            mCamera.UpdateViewMatrix();
            
            // Update all meshes' uniforms
            foreach (node; mSceneTree.GetRootNode().mChildren) {
                if (MeshNode meshNode = cast(MeshNode)node) {
                    // Update the view matrix with current camera
                    auto material = meshNode.GetMaterial();
                    if ("uView" in material.mUniformMap) {
                        material.mUniformMap["uView"].Set(mCamera.mViewMatrix.DataPtr());
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