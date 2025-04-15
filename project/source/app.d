/// Main entry point for the city renderer application
import city_app;
import std.stdio : writeln;


void main(string[] args)
{
    try {
        writeln("DEBUG MAIN: Starting application");
        
        // Create our city graphics application with OpenGL 4.1
        writeln("DEBUG MAIN: Creating CityGraphicsApp");
        CityGraphicsApp app = CityGraphicsApp(4, 1);
        writeln("DEBUG MAIN: CityGraphicsApp created");
        
        // Run the main application loop
        writeln("DEBUG MAIN: Entering main loop");
        app.Loop();
        writeln("DEBUG MAIN: Main loop exited");
    }
    catch (Exception e) {
        writeln("FATAL ERROR in main: ", e.msg);
    }
}