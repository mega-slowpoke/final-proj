/// Renderer module
module renderer;

import bindbc.sdl;
import bindbc.opengl;

import camera,scene;

/// Purpose of this class is to make it easy to render part of, or the entirety of a scene
/// from a specific camera viewpoint.
class Renderer{

    SDL_Window* mWindow;
    int mScreenWidth;
    int mScreenHeight;

    bool mIsNightMode = true;

    /// Constructor
    this(SDL_Window* window, int width, int height){
        mWindow = window;
        mScreenWidth = width;
        mScreenHeight = height;
    }

   
    void StartingFrame(){
        glViewport(0,0,mScreenWidth, mScreenHeight);
        
        if (mIsNightMode) {
            glClearColor(0.05f, 0.07f, 0.15f, 1.0f); 
        } else {
            glClearColor(0.0f, 0.6f, 0.8f, 1.0f);  
        }
        
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glEnable(GL_DEPTH_TEST);
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }


    /// Set or clear any state at end of a frame
    void EndingFrame(){
        // Final step is to present what we have copied into
        // video memory
        SDL_GL_SwapWindow(mWindow);
    }

    /// Encapsulation of the rendering process of a scene tree with a camera
    void Render(SceneTree s, Camera c){
        // Set the state of the beginning of the frame
        StartingFrame();

        // Set the camera prior to our traversal
        s.SetCamera(c);
        // Start traversing the scene tree
        s.StartTraversal();

        // perform any cleanup and ultimately the double or triple buffering to display the final framebuffer.
        EndingFrame();
    }


    // change mode
    void toggleDayNight() {
        mIsNightMode = !mIsNightMode;
    }
}
