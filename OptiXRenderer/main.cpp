#include "main.h"

int main(int argc, char** argv)
{
    try
    {
        // Check for scene file 
        if (argc == 1) throw
            std::runtime_error("Missing path to a scene file as the first argument.");

        // Load the scene file
        SceneLoader loader;
        std::shared_ptr<Scene> scene = loader.load(argv[1]);

        // Create the optix app by passing in the path to the scene file
        Renderer renderer(scene);
         
        renderer.run(false);
        resultToPNG(renderer.getOutputFilename(),
            renderer.getWidth(),
            renderer.getHeight(),
            renderer.getResult());

    }
    catch (const std::exception & ex)
    {
        // Print out the exception for debugging
        std::cerr << ex.what() << std::endl;
    }
    return 0;
}