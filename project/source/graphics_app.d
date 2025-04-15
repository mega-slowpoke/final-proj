/// The main graphics application with the main graphics loop.
module graphics_app;
import std.stdio;
import core;
import mesh, linear, scene, materials, geometry;
import platform;

import bindbc.sdl;
import bindbc.opengl;

/// The main graphics application.
struct GraphicsApp{
		bool mGameIsRunning=true;
		bool mRenderWireframe = false;
		SDL_GLContext mContext;
		SDL_Window* mWindow;

		// Scene
		SceneTree mSceneTree;
		// Camera
		Camera mCamera;
		// Renderer
		Renderer mRenderer;

		/// Setup OpenGL and any libraries
		this(int major_ogl_version, int minor_ogl_version){

				// Setup SDL OpenGL Version
				SDL_GL_SetAttribute( SDL_GL_CONTEXT_MAJOR_VERSION, major_ogl_version );
				SDL_GL_SetAttribute( SDL_GL_CONTEXT_MINOR_VERSION, minor_ogl_version );
				SDL_GL_SetAttribute( SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE );
				// We want to request a double buffer for smooth updating.
				SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
				SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

				// Create an application window using OpenGL that supports SDL
				mWindow = SDL_CreateWindow( "dlang - OpenGL 4+ Graphics Framework",
								SDL_WINDOWPOS_UNDEFINED,
								SDL_WINDOWPOS_UNDEFINED,
								640,
								480,
								SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN );

				// Create the OpenGL context and associate it with our window
				mContext = SDL_GL_CreateContext(mWindow);

				// Load OpenGL Function calls
				auto retVal = LoadOpenGLLib();

				// Check OpenGL version
				GetOpenGLVersionInfo();

				// Create a renderer
				mRenderer = new Renderer(mWindow,640,480);

				// Create a camera
				mCamera = new Camera();

				// Create (or load) a Scene Tree
				mSceneTree = new SceneTree("root");
		}

		/// Destructor
		~this(){
				// Destroy our context
				SDL_GL_DeleteContext(mContext);
				// Destroy our window
				SDL_DestroyWindow(mWindow);
		}

		/// Handle input
		void Input(){
				// Store an SDL Event
				SDL_Event event;
				while(SDL_PollEvent(&event)){
						if(event.type == SDL_QUIT){
								writeln("Exit event triggered (probably clicked 'x' at top of the window)");
								mGameIsRunning= false;
						}
						if(event.type == SDL_KEYDOWN){
								if(event.key.keysym.scancode == SDL_SCANCODE_ESCAPE){
										writeln("Pressed escape key and now exiting...");
										mGameIsRunning= false;
								}else if(event.key.keysym.sym == SDLK_TAB){
										mRenderWireframe = !mRenderWireframe;
								}
								else if(event.key.keysym.sym == SDLK_DOWN){
										mCamera.MoveBackward();
								}
								else if(event.key.keysym.sym == SDLK_UP){
										mCamera.MoveForward();
								}
								else if(event.key.keysym.sym == SDLK_LEFT){
										mCamera.MoveLeft();
								}
								else if(event.key.keysym.sym == SDLK_RIGHT){
										mCamera.MoveRight();
								}
								else if(event.key.keysym.sym == SDLK_a){
										mCamera.MoveUp();
								}
								else if(event.key.keysym.sym == SDLK_z){
										mCamera.MoveDown();
								}
								writeln("Camera Position: ",mCamera.mEyePosition);
						}
				}


                // Retrieve the mouse position
                int mouseX,mouseY;
                SDL_GetMouseState(&mouseX,&mouseY);
                mCamera.MouseLook(mouseX,mouseY);
		}

		/// A helper function to setup a scene.
		/// NOTE: In the future this can use a configuration file to otherwise make our graphics applications
		///       data-driven.
		void SetupScene(){

				// Create a pipeline and associate it with a material
				// that can be attached to meshes.
				Pipeline basicPipeline = new Pipeline("basic","./pipelines/basic/basic.vert","./pipelines/basic/basic.frag");
				IMaterial basicMaterial    = new BasicMaterial("basic");

				// Create an object and add it to our scene tree
				ISurface obj = new SurfaceOBJ("./assets/bunny_centered.obj"); 
				MeshNode  m        = new MeshNode("bunny",obj,basicMaterial);
				mSceneTree.GetRootNode().AddChildSceneNode(m);

				// Add three uniforms to the basic material.
				// The 4th parameter is set to the pointer where the value will be updated each frame.
				// Becauses the model matrix will be different among models, then we will just leave
				// this null for now.
				basicMaterial.AddUniform(new Uniform("uModel", "mat4", null));
				basicMaterial.AddUniform(new Uniform("uView", "mat4", mCamera.mViewMatrix.DataPtr()));
				basicMaterial.AddUniform(new Uniform("uProjection", "mat4", mCamera.mProjectionMatrix.DataPtr()));

		}

		/// Update gamestate
		void Update(){
				// A rotation value that 'updates' every frame to give some animation in our scene
				static float yRotation = 0.0f;   yRotation += 0.01f;

				// Update our first object
				MeshNode m = cast(MeshNode)mSceneTree.FindNode("bunny");
				m.mModelMatrix = MatrixMakeTranslation(vec3(0.0f,0.0f,-1.0f));
				m.mModelMatrix = m.mModelMatrix * MatrixMakeYRotation(yRotation);
		}

		/// Render our scene by traversing the scene tree from a specific viewpoint
		void Render(){
				if(mRenderWireframe){
						glPolygonMode(GL_FRONT_AND_BACK,GL_LINE); 
				}else{
						glPolygonMode(GL_FRONT_AND_BACK,GL_FILL); 
				}

				mRenderer.Render(mSceneTree,mCamera);
		}

		/// Process 1 frame
		void AdvanceFrame(){
				Input();
				Update();
				Render();
				
				SDL_Delay(16);	// NOTE: This is a simple way to cap framerate at 60 FPS,
								// 		  you might be inclined to improve things a bit.
		}

		/// Main application loop
		void Loop(){
				// Setup the graphics scene
				SetupScene();

				// Lock mouse to center of screen
				// This will help us get a continuous rotation.
				// NOTE: On occasion folks on virtual machine or WSL may not have this work,
				//       so you'll have to compute the 'diff' and reposition the mouse yourself.
				SDL_WarpMouseInWindow(mWindow,640/2,320/2);

				// Run the graphics application loop
				while(mGameIsRunning){
						AdvanceFrame();
				}
		}
}

