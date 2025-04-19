/// Custom city renderer implementation
module cityrenderer;

import std.stdio;
import std.random : uniform;
import std.conv : to;
import core;
import mesh, linear, scene, materials, geometry;
import pipeline;
import bindbc.opengl;

import building, ground, moon;



class CityGenerator {
    SceneTree mSceneTree;
    Pipeline mBuildingPipeline;
    Pipeline mGroundPipeline;
    
    // City parameters
    int mGridSize = 8;       // Grid size (8x8 buildings) - reduced for stability
    float mBlockSize = 2.0f; // Size of a city block
    float mStreetWidth = 1.0f; // Width of streets
    float mGroundSize;       // Total ground size
    
    // For light
    vec3 mLightDirection;

    // Day/Night toggle
    bool mIsNightMode = true;

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
            
            mBuildingPipeline = new Pipeline("building", 
                                            "./pipelines/city/building.vert", 
                                            "./pipelines/city/building.frag");
            writeln("DEBUG CITYGEN: Building pipeline created");
            
            mGroundPipeline = new Pipeline("ground", 
                                        "./pipelines/city/ground.vert", 
                                        "./pipelines/city/ground.frag");
            writeln("DEBUG CITYGEN: Ground pipeline created");

            Pipeline moonPipeline = new Pipeline("moon", 
                                    "./pipelines/city/moon.vert", 
                                    "./pipelines/city/moon.frag");
            writeln("DEBUG CITYGEN: Moon pipeline created");

            Pipeline moonglowPipeline = new Pipeline("moonglow", 
                           "./pipelines/city/moonglow.vert", 
                           "./pipelines/city/moonglow.frag");
            
        } catch (Exception e) {
            writeln("ERROR creating pipelines: ", e.msg);
        }
    }
    
void generateCity() {
    try {
        import std.stdio : writeln;
        
        writeln("DEBUG: generateCity - Starting in ", mIsNightMode ? "night" : "day", " mode");
        
        // Create ground
        writeln("DEBUG: generateCity - Creating ground");
        createGround();
        writeln("DEBUG: generateCity - Ground created");
        
        // Create moon in night mode
        if (mIsNightMode) {
            writeln("DEBUG: generateCity - Creating moon");
            createMoon();
            writeln("DEBUG: generateCity - Moon created");
        } else {
            writeln("DEBUG: generateCity - Skipping moon creation (day mode)");
        }
        
        // Create buildings
        writeln("DEBUG: generateCity - Creating buildings");
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
        writeln("DEBUG: generateCity - Buildings created");
        
    } catch (Exception e) {
        import std.stdio : writeln;
        writeln("ERROR in generateCity: ", e.msg);
    }
}
    

        
void createBuilding(int x, int z) {
    float buildingHeight = 4.0f + (x % 3) + (z % 4); // Deterministic height pattern
    float buildingWidth = mBlockSize * 0.8f;
    float buildingDepth = mBlockSize * 0.8f;
    
    float posX = (x * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
    float posZ = (z * (mBlockSize + mStreetWidth)) - (mGroundSize / 2) + (mBlockSize / 2);
    
    // Create building color (variation of gray)
    float colorValue;
    vec3 buildingColor;
    
    if (mIsNightMode) {
        colorValue = 0.2f + (((x + z) % 5) / 10.0f);
        buildingColor = vec3(colorValue, colorValue, colorValue + 0.02f);
    } else {
        colorValue = 0.4f + (((x + z) % 5) / 10.0f);
        buildingColor = vec3(colorValue, colorValue, colorValue);
    }
    
    // Create building mesh
    ISurface buildingSurface = new SurfaceBuilding(buildingWidth, buildingHeight, buildingDepth);
    IMaterial buildingMaterial = new BuildingMaterial("building", buildingColor);
    
    // Add basic uniforms
    buildingMaterial.AddUniform(new Uniform("uModel", "mat4", null));
    buildingMaterial.AddUniform(new Uniform("uView", "mat4", null));
    buildingMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
    buildingMaterial.AddUniform(new Uniform("uBaseColor", "vec3", buildingColor.DataPtr()));
    
    // Add light uniforms
    vec3 lightDir;
    vec3 lightColor;
    float ambientStrength;
    float diffuseStrength;
    
    if (mIsNightMode) {
        // Night settings - moon light
        lightDir = mLightDirection;
        lightColor = vec3(0.6f, 0.7f, 0.9f);
        ambientStrength = 0.1f;
        diffuseStrength = 0.3f;
    } else {
        // Day settings - sun light
        lightDir = vec3(0.5f, -0.7f, 0.3f);
        lightColor = vec3(1.0f, 0.95f, 0.8f);
        ambientStrength = 0.3f;
        diffuseStrength = 0.7f;
    }

    buildingMaterial.AddUniform(new Uniform("uLightDirection", "vec3", lightDir.DataPtr()));
    buildingMaterial.AddUniform(new Uniform("uLightColor", "vec3", lightColor.DataPtr()));
    buildingMaterial.AddUniform(new Uniform("uAmbientStrength", ambientStrength));
    buildingMaterial.AddUniform(new Uniform("uDiffuseStrength", diffuseStrength));
    
    if (mIsNightMode) {
        buildingMaterial.AddUniform(new Uniform("uWindowDensity", 0.7f));
        buildingMaterial.AddUniform(new Uniform("uWindowBrightness", 0.9f));
    } else {
        buildingMaterial.AddUniform(new Uniform("uWindowDensity", 0.4f));
        buildingMaterial.AddUniform(new Uniform("uWindowBrightness", 0.6f));
    }

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
    float colorValue;
    vec3 buildingColor;
    
    if (mIsNightMode) {
        colorValue = 0.2f + (((x + z) % 5) / 10.0f);
        buildingColor = vec3(colorValue, colorValue * 0.95f, colorValue * 0.9f + 0.03f);
    } else {
        colorValue = 0.4f + (((x + z) % 5) / 10.0f);
        buildingColor = vec3(colorValue, colorValue * 0.95f, colorValue * 0.9f);
    }
    
    // Create cylindrical building mesh
    ISurface buildingSurface = new SurfaceCylindricalBuilding(radius, buildingHeight, 16);
    IMaterial buildingMaterial = new BuildingMaterial("building", buildingColor);
    
    // Add basic uniforms
    buildingMaterial.AddUniform(new Uniform("uModel", "mat4", null));
    buildingMaterial.AddUniform(new Uniform("uView", "mat4", null));
    buildingMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
    buildingMaterial.AddUniform(new Uniform("uBaseColor", "vec3", buildingColor.DataPtr()));
    
    // Add light uniforms
    vec3 lightDir;
    vec3 lightColor;
    float ambientStrength;
    float diffuseStrength;

    if (mIsNightMode) {
        // Night settings - moon light
        lightDir = mLightDirection;
        lightColor = vec3(0.6f, 0.7f, 0.9f);
        ambientStrength = 0.1f;
        diffuseStrength = 0.3f;
    } else {
        // Day settings - sun light
        lightDir = vec3(0.5f, -0.7f, 0.3f);
        lightColor = vec3(1.0f, 0.95f, 0.8f);
        ambientStrength = 0.3f;
        diffuseStrength = 0.7f;
    }
    
    buildingMaterial.AddUniform(new Uniform("uLightDirection", "vec3", lightDir.DataPtr()));
    buildingMaterial.AddUniform(new Uniform("uLightColor", "vec3", lightColor.DataPtr()));
    buildingMaterial.AddUniform(new Uniform("uAmbientStrength", ambientStrength));
    buildingMaterial.AddUniform(new Uniform("uDiffuseStrength", diffuseStrength));
    
    // Add window parameters (more windows visible at night)
    if (mIsNightMode) {
        buildingMaterial.AddUniform(new Uniform("uWindowDensity", 0.7f));
        buildingMaterial.AddUniform(new Uniform("uWindowBrightness", 0.9f));
    } else {
        buildingMaterial.AddUniform(new Uniform("uWindowDensity", 0.4f));
        buildingMaterial.AddUniform(new Uniform("uWindowBrightness", 0.6f));
    }
    
    // Create building node and add to scene
    string buildingName = "building_cyl_" ~ x.to!string ~ "_" ~ z.to!string;
    MeshNode buildingNode = new MeshNode(buildingName, buildingSurface, buildingMaterial);
    buildingNode.mModelMatrix = MatrixMakeTranslation(vec3(posX, 0.0f, posZ));
    
    mSceneTree.GetRootNode().AddChildSceneNode(buildingNode);
}

void createGround() {
    try {
        ISurface groundSurface = new SurfaceGround(mGroundSize, mGroundSize);
        
        GroundMaterial groundMaterial = new GroundMaterial("ground");
        groundMaterial.SetCityParams(mBlockSize, mStreetWidth);
        
        if (mIsNightMode) {
            // Night colors - darker
            groundMaterial.mBaseColor = vec3(0.1f, 0.3f, 0.1f);       
            groundMaterial.mRoadColor = vec3(0.15f, 0.15f, 0.15f);     
            groundMaterial.mSidewalkColor = vec3(0.4f, 0.4f, 0.38f);   
            groundMaterial.mZebraColor = vec3(0.5f, 0.5f, 0.5f);   
        } else {
            // Day colors - brighter
            groundMaterial.mBaseColor = vec3(0.2f, 0.7f, 0.2f);       
            groundMaterial.mRoadColor = vec3(0.3f, 0.3f, 0.3f);       
            groundMaterial.mSidewalkColor = vec3(0.75f, 0.75f, 0.7f); 
            groundMaterial.mZebraColor = vec3(0.9f, 0.9f, 0.9f);       
        }
        
        // Basic uniforms
        groundMaterial.AddUniform(new Uniform("uModel", "mat4", null));
        groundMaterial.AddUniform(new Uniform("uView", "mat4", null));
        groundMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
        groundMaterial.AddUniform(new Uniform("uBaseColor", "vec3", groundMaterial.mBaseColor.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uRoadColor", "vec3", groundMaterial.mRoadColor.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uSidewalkColor", "vec3", groundMaterial.mSidewalkColor.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uZebraColor", "vec3", groundMaterial.mZebraColor.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uBlockSize", mBlockSize));
        groundMaterial.AddUniform(new Uniform("uStreetWidth", mStreetWidth));
        groundMaterial.AddUniform(new Uniform("uSidewalkWidth", 0.15f));
        groundMaterial.AddUniform(new Uniform("uZebraWidth", 0.3f));
        groundMaterial.AddUniform(new Uniform("uZebraStripeWidth", 0.15f));
        
        vec3 lightDir;
        vec3 lightColor;
        float ambientStrength;
        float diffuseStrength;
        
        if (mIsNightMode) {
            lightDir = mLightDirection;
            lightColor = vec3(0.6f, 0.7f, 0.9f);
            ambientStrength = 0.1f;
            diffuseStrength = 0.3f;
        } else {
            lightDir = vec3(0.5f, -0.7f, 0.3f);
            lightColor = vec3(1.0f, 0.95f, 0.8f);
            ambientStrength = 0.3f;
            diffuseStrength = 0.7f;
        }
        
        groundMaterial.AddUniform(new Uniform("uLightDirection", "vec3", lightDir.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uLightColor", "vec3", lightColor.DataPtr()));
        groundMaterial.AddUniform(new Uniform("uAmbientStrength", ambientStrength));
        groundMaterial.AddUniform(new Uniform("uDiffuseStrength", diffuseStrength));
        
        MeshNode groundNode = new MeshNode("ground", groundSurface, groundMaterial);
        groundNode.mModelMatrix = MatrixMakeTranslation(vec3(0.0f, 0.0f, 0.0f));
        
        mSceneTree.GetRootNode().AddChildSceneNode(groundNode);
    } catch (Exception e) {
        import std.stdio : writeln;
        writeln("Error creating ground: ", e.msg);
    }
}


void createMoon() {
    float moonSize = 5.0f; 
    
    float moonHeight = 20.0f; 
    float moonDistance = 20.0f; 
    
    vec3 moonPosition = vec3(0.0f, moonHeight, -moonDistance); // Centered in X, pushed back in Z
    
    vec3 moonDirection = vec3(0.0f, -moonPosition.y, -moonPosition.z);
    moonDirection = moonDirection.Normalize();
    
    mLightDirection = moonDirection;
    
    ISurface moonSurface = new SurfaceBillboard(moonSize);
    
    vec3 moonColor = vec3(0.98f, 0.95f, 0.90f); // Slightly warm white
    MoonMaterial moonMaterial = new MoonMaterial("moon", moonColor, 0.95f);
    
    moonMaterial.AddUniform(new Uniform("uModel", "mat4", null));
    moonMaterial.AddUniform(new Uniform("uView", "mat4", null));
    moonMaterial.AddUniform(new Uniform("uProjection", "mat4", null));
    moonMaterial.AddUniform(new Uniform("uMoonColor", "vec3", moonColor.DataPtr()));
    moonMaterial.AddUniform(new Uniform("uMoonSize", 0.95f));
    
    MeshNode moonNode = new MeshNode("moon", moonSurface, moonMaterial);
    moonNode.mModelMatrix = MatrixMakeTranslation(moonPosition);
    mSceneTree.GetRootNode().AddChildSceneNode(moonNode);
}


    void toggleDayNight() {
        mIsNightMode = !mIsNightMode;

        regenerateCity();
    }

    void regenerateCity() {
        // Clear existing scene nodes except root
        auto rootNode = mSceneTree.GetRootNode();
        rootNode.mChildren = [];
        
        // Regenerate the city with current settings
        generateCity();

    }

}