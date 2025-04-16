/// Custom city renderer implementation
module cityrenderer;

import std.stdio;
import std.random : uniform;
import std.conv : to;
import core;
import mesh, linear, scene, materials, geometry;
import pipeline;
import bindbc.opengl;

import building, ground;


class CityGenerator {
    SceneTree mSceneTree;
    Pipeline mBuildingPipeline;
    Pipeline mGroundPipeline;
    
    // City parameters
    int mGridSize = 8;       // Grid size (8x8 buildings) - reduced for stability
    float mBlockSize = 2.0f; // Size of a city block
    float mStreetWidth = 1.0f; // Width of streets
    float mGroundSize;       // Total ground size
    
    /// Constructor
    this(SceneTree sceneTree) {
        import std.stdio : writeln;
        try {
            writeln("DEBUG CITYGEN: Starting CityGenerator constructor");
            mSceneTree = sceneTree;
            writeln("DEBUG CITYGEN: Scene tree assigned");
            
            mGroundSize = (mGridSize * mBlockSize) + ((mGridSize - 1) * mStreetWidth);
            writeln("DEBUG CITYGEN: Ground size calculated: ", mGroundSize);
            
            // Create custom pipelines for buildings and ground
            writeln("DEBUG CITYGEN: About to create shader pipelines");
            createShaderPipelines();
            writeln("DEBUG CITYGEN: Shader pipelines created");
            
            writeln("DEBUG CITYGEN: CityGenerator constructor completed");
        } 
        catch (Exception e) {
            writeln("ERROR in CityGenerator constructor: ", e.msg);
            throw e;
        }
    }
    
    /// Create shader pipelines for the city
    void createShaderPipelines() {
        import std.stdio : writeln;
        import std.file : exists, readText;
        
        try {
            writeln("DEBUG CITYGEN: createShaderPipelines - Starting shader pipeline creation");
            
            // Check if files exist and print their content
            writeln("DEBUG CITYGEN: Building shader files exist: ", 
                    exists("./pipelines/city/building.vert"), " ", 
                    exists("./pipelines/city/building.frag"));
            
            writeln("DEBUG CITYGEN: Ground shader files exist: ", 
                    exists("./pipelines/city/ground.vert"), " ", 
                    exists("./pipelines/city/ground.frag"));
            
            // Try reading the ground shader files
            if (exists("./pipelines/city/ground.vert")) {
                string vertexShaderContent = readText("./pipelines/city/ground.vert");
                writeln("DEBUG CITYGEN: Ground vertex shader length: ", vertexShaderContent.length);
            }
            
            if (exists("./pipelines/city/ground.frag")) {
                string fragmentShaderContent = readText("./pipelines/city/ground.frag");
                writeln("DEBUG CITYGEN: Ground fragment shader length: ", fragmentShaderContent.length);
            }
            
            // Create pipeline for buildings
            writeln("DEBUG CITYGEN: Creating building pipeline");
            mBuildingPipeline = new Pipeline("building", 
                                            "./pipelines/city/building.vert", 
                                            "./pipelines/city/building.frag");
            writeln("DEBUG CITYGEN: Building pipeline created");
            
            // Create pipeline for ground - with try/catch specifically for this
            writeln("DEBUG CITYGEN: Creating ground pipeline");
            try {
                mGroundPipeline = new Pipeline("ground", 
                                            "./pipelines/city/ground.vert", 
                                            "./pipelines/city/ground.frag");
                writeln("DEBUG CITYGEN: Ground pipeline created");
            } catch (Exception e) {
                writeln("ERROR specifically in ground pipeline creation: ", e.msg);
                // Continue with program rather than crashing
            }
            
            writeln("DEBUG CITYGEN: createShaderPipelines - Pipelines created successfully");
        } catch (Exception e) {
            writeln("ERROR creating pipelines: ", e.msg);
            // Don't rethrow - try to continue running the program
        }
    }
    
    void generateCity() {
        try {
            import std.stdio : writeln;
            
            // Create ground
            createGround();
            
            // Create buildings - with various shapes
            for (int x = 0; x < mGridSize; x++) {
                for (int z = 0; z < mGridSize; z++) {
                    // Every third building will be cylindrical
                    if ((x + z) % 3 == 0) {
                        createCylindricalBuilding(x, z);
                    } else {
                        createBuilding(x, z);
                    }
                }
            }
        } catch (Exception e) {
            import std.stdio : writeln;
            writeln("Error generating city: ", e.msg);
        }
    }
    

void createGround() {
    try {
        // Create ground mesh
        ISurface groundSurface = new SurfaceGround(mGroundSize, mGroundSize);
        
        // Create ground material with proper pipeline
        GroundMaterial groundMaterial = new GroundMaterial("ground");
        groundMaterial.SetCityParams(mBlockSize, mStreetWidth);
        
        // Add all uniforms needed by the shader
        groundMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        groundMaterial.AddUniform(new Uniform("uView", "mat4", null));
        groundMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
        groundMaterial.AddUniform(new Uniform("uBaseColor", "vec3", groundMaterial.mColor.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uRoadColor", "vec3", groundMaterial.mRoadColor.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uSidewalkColor", "vec3", groundMaterial.mSidewalkColor.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uZebraColor", "vec3", groundMaterial.mZebraColor.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uBlockSize", mBlockSize));
        groundMaterial.AddUniform(new Uniform("uStreetWidth", mStreetWidth));
        groundMaterial.AddUniform(new Uniform("uSidewalkWidth", 0.15f));
        groundMaterial.AddUniform(new Uniform("uZebraWidth", 0.3f));
        groundMaterial.AddUniform(new Uniform("uZebraStripeWidth", 0.15f));
        
        // Create mesh node and add to scene
        MeshNode groundNode = new MeshNode("ground", groundSurface, groundMaterial);
        groundNode.mModelMatrix = MatrixMakeTranslation(vec3(0.0f, 0.0f, 0.0f));
        
        mSceneTree.GetRootNode().AddChildSceneNode(groundNode);
    } catch (Exception e) {
        import std.stdio : writeln;
        writeln("Error creating ground: ", e.msg);
    }
}
        
    /// Create a building at grid position (x, z)
    void createBuilding(int x, int z) {
        // Using fixed values instead of random to ensure stability during debugging
        float buildingHeight = 4.0f + (x % 3) + (z % 4); // Deterministic height pattern
        float buildingWidth = mBlockSize * 0.8f;
        float buildingDepth = mBlockSize * 0.8f;
        
        // Calculate building position
        float posX = (x * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
        float posZ = (z * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
        
        // Create building color (variation of gray)
        float colorValue = 0.4f + (((x + z) % 5) / 10.0f); // Deterministic color
        vec3 buildingColor = vec3(colorValue, colorValue, colorValue);
        
        // Create building mesh
        ISurface buildingSurface = new SurfaceBuilding(buildingWidth, buildingHeight, buildingDepth);
        IMaterial buildingMaterial = new BuildingMaterial("building", buildingColor);
        
        // Add uniforms to the building material
        buildingMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uView", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uBaseColor", "vec3", buildingColor.DataPtr()));
        
        // Create building node and add to scene
        string buildingName = "building_" ~ x.to!string ~ "_" ~ z.to!string;
        MeshNode buildingNode = new MeshNode(buildingName, buildingSurface, buildingMaterial);
        buildingNode.mModelMatrix = MatrixMakeTranslation(vec3(posX, 0.0f, posZ));
        
        mSceneTree.GetRootNode().AddChildSceneNode(buildingNode);
    }

    void createCylindricalBuilding(int x, int z) {
        // Deterministic values for cylindrical buildings
        float buildingHeight = 5.0f + (x % 4) + (z % 5); // Make cylindrical buildings taller
        float radius = mBlockSize * 0.4f;
        
        // Calculate building position
        float posX = (x * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
        float posZ = (z * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
        
        // Create building color - different tint for cylindrical buildings
        float colorValue = 0.4f + (((x + z) % 5) / 10.0f);
        vec3 buildingColor = vec3(colorValue, colorValue * 0.95f, colorValue * 0.9f);
        
        // Create cylindrical building mesh
        ISurface buildingSurface = new SurfaceCylindricalBuilding(radius, buildingHeight, 16);
        IMaterial buildingMaterial = new BuildingMaterial("building", buildingColor);
        
        // Add uniforms to the building material
        buildingMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uView", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
        buildingMaterial.AddUniform(new Uniform("uBaseColor", "vec3", buildingColor.DataPtr()));
        
        // Create building node and add to scene
        string buildingName = "building_cyl_" ~ x.to!string ~ "_" ~ z.to!string;
        MeshNode buildingNode = new MeshNode(buildingName, buildingSurface, buildingMaterial);
        buildingNode.mModelMatrix = MatrixMakeTranslation(vec3(posX, 0.0f, posZ));
        
        mSceneTree.GetRootNode().AddChildSceneNode(buildingNode);
    }
}