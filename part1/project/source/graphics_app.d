/// The main graphics application with the main graphics loop.
module graphics_app;
import std.stdio;
import core;
import mesh, linear, scene, materials, geometry, rendertarget, graphics_window;
import platform;

import bindbc.sdl;
import bindbc.opengl;

/// The main graphics application.
struct GraphicsApp{
		bool mGameIsRunning		= true;
		bool mRenderWireframe = false;
		
		// Window for the graphics application
		GraphicsWindow mWindow;
		// Scene
		SceneTree mSceneTree;
		// Camera
		Camera mCamera;
		// Renderer
		Renderer mRenderer;	
		// Note: For future, you can use for post rendering effects on the renderer
    //		PostRenderDraw mPostRenderer;

		/// Setup OpenGL and any libraries
		this(string title, int major_ogl_version, int minor_ogl_version){
				// Create a window
				mWindow = new OpenGLWindow(title, major_ogl_version, minor_ogl_version);
				// Create a renderer
        // NOTE: For now, our renderer will draw into the default renderbuffer (so 'null' for final pamater.
				mRenderer = new Renderer(mWindow,640,480, null);
        // NOTE: In future, you can create a custom render target to draw to as follows.
				//       mRenderer = new Renderer(mWindow,640,480, new RenderTarget(640,480));
				// Handle effects for the renderer
        // mPostRenderer = new PostRenderDraw("screen","./pipelines/screen/"); 

				// Create a camera
				mCamera = new Camera();
				// Create (or load) a Scene Tree
				mSceneTree = new SceneTree("root");
		}

		/// Destructor
		~this(){
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
				Pipeline  normalMap      = new Pipeline("normalmap","./pipelines/normalmap/");
				IMaterial normalMaterial = new NormalMapMaterial("normalmap","./assets/brick.ppm","./assets/normal.ppm");

				// Create an object and add it to our scene tree
				ISurface obj = MakeTexturedNormalMappedQuad();
				MeshNode  m  = new MeshNode("quad",obj,normalMaterial);
				mSceneTree.GetRootNode().AddChildSceneNode(m);
		}

		/// Update gamestate
		void Update(){
				// A rotation value that 'updates' every frame to give some animation in our scene
				static float yRotation = 0.0f;   yRotation += 0.01f;

				// Update our first object
				MeshNode m = cast(MeshNode)mSceneTree.FindNode("quad");
				// Transform our mesh node
				// Note: Before most transformations, we set the 'identity' matrix, and then
				//       perform our transformations.
				m.LoadIdentity().Translate(0.0f,0.0,-1.0f).RotateY(yRotation);
		}

		/// Render our scene by traversing the scene tree from a specific viewpoint
		void Render(){
				if(mRenderWireframe){
						glPolygonMode(GL_FRONT_AND_BACK,GL_LINE); 
				}else{
						glPolygonMode(GL_FRONT_AND_BACK,GL_FILL); 
				}

				// Render the scene tree form a specific camera
				mRenderer.Render(mSceneTree, mCamera);
				// Post renderer
				//mPostRenderer.PostRender(mRenderer);
		}

		/// Process 1 frame
		void AdvanceFrame(){
				Input();
				Update();
				Render();

				SDL_Delay(16);	// NOTE: This is a simple way to cap framerate at 60 FPS,
												// 		   you might be inclined to improve things a bit.
		}

		/// Main application loop
		void Loop(){
				// Setup the graphics scene
				SetupScene();

				// Lock mouse to center of screen
				// This will help us get a continuous rotation.
				// NOTE: On occasion folks on virtual machine or WSL may not have this work,
				//       so you'll have to compute the 'diff' and reposition the mouse yourself.
				SDL_WarpMouseInWindow(mWindow.mWindow,640/2,320/2);

				// Run the graphics application loop
				while(mGameIsRunning){
						AdvanceFrame();
				}
		}
}

