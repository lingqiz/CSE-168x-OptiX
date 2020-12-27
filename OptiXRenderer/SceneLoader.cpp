#include "SceneLoader.h"

void SceneLoader::rightMultiply(const optix::Matrix4x4& M)
{
    optix::Matrix4x4& T = transStack.top();
    T = T * M;
}

optix::float3 SceneLoader::transformPoint(optix::float3 v)
{
    optix::float4 vh = transStack.top() * optix::make_float4(v, 1);
    return optix::make_float3(vh) / vh.w; 
}

optix::float3 SceneLoader::transformNormal(optix::float3 n)
{
    return optix::make_float3(transStack.top() * make_float4(n, 0));
}

template <class T>
bool SceneLoader::readValues(std::stringstream& s, const int numvals, T* values)
{
    for (int i = 0; i < numvals; i++)
    {
        s >> values[i];
        if (s.fail())
        {
            std::cout << "Failed reading value " << i << " will skip" << std::endl;
            return false;
        }
    }
    return true;
}

std::shared_ptr<Scene> SceneLoader::load(std::string sceneFilename)
{
    // Attempt to open the scene file 
    std::ifstream in(sceneFilename);
    if (!in.is_open())
    {
        // Unable to open the file. Check if the filename is correct.
        throw std::runtime_error("Unable to open scene file " + sceneFilename);
    }

    auto scene = std::make_shared<Scene>();
    transStack.push(optix::Matrix4x4::identity());

    std::string str, cmd;
    // Read a line in the scene file in each iteration
    while (std::getline(in, str))
    {
        // Ruled out comment and blank lines
        if ((str.find_first_not_of(" \t\r\n") == std::string::npos) 
            || (str[0] == '#'))
        {
            continue;
        }

        // Read a command
        std::stringstream s(str);
        s >> cmd;

        // Some arrays for storing values
        float fvalues[12];
        int ivalues[3];
        std::string svalues[1];
        
        if (cmd == "size" && readValues(s, 2, fvalues))
        {
            scene->width = (unsigned int)fvalues[0];
            scene->height = (unsigned int)fvalues[1];
        }
        else if (cmd == "output" && readValues(s, 1, svalues))
        {
            scene->outputFilename = svalues[0];
        }
        else if (cmd == "camera" && readValues(s, 10, fvalues))
        {
            scene->from = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
            scene->at = optix::make_float3(fvalues[3], fvalues[4], fvalues[5]);
            scene->up = optix::make_float3(fvalues[6], fvalues[7], fvalues[8]);

            scene->dir = optix::normalize(scene->from - scene->at);
            scene->u   = optix::normalize(optix::cross(scene->up, scene->dir));
            scene->v   = optix::normalize(optix::cross(scene->dir, scene->u));
            
            float fovy = fvalues[9];
            scene->fovyRad = fovy / 180.0f * M_PI;
            scene->fovxRad = 2 * atan(tan(scene->fovyRad / 2.0f) * 
                              (float) scene->width / (float) scene->height);
        }
        else if (cmd == "vertex" && readValues(s, 3, fvalues))
        {
            optix::float3 newVertex = 
            optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
            scene->vertices.push_back(newVertex);
        }
        else if (cmd == "pushTransform")
        {
            transStack.push(transStack.top());
        }
        else if (cmd == "popTransform")
        {
            transStack.pop();
        }
        else if (cmd == "translate" && readValues(s, 3, fvalues))
        {
            optix::float3 translate = 
            optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);

            rightMultiply(optix::Matrix<4, 4>::translate(translate));
        }
        else if (cmd == "rotate" && readValues(s, 4, fvalues))
        {
            optix::float3 axis = 
            optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);

            float angleRad = fvalues[3] / 180.0f * M_PI;
            rightMultiply(optix::Matrix<4, 4>::rotate(angleRad, axis));
        }
        else if (cmd == "scale" && readValues(s, 3, fvalues))
        {
            optix::float3 scale = 
            optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);

            rightMultiply(optix::Matrix<4, 4>::scale(scale));
        }
        else if (cmd == "tri" && readValues(s, 3, ivalues))
        {
            for(int idx = 0; idx < 3; idx++)
            {                
                scene->triangleSoup.push_back(
                    transformPoint(scene->vertices[ivalues[idx]]));
            }

            optix::float3 diffVec1 = 
            transformPoint(scene->vertices[ivalues[0]]) - transformPoint(scene->vertices[ivalues[1]]);
            optix::float3 diffVec2 = 
            transformPoint(scene->vertices[ivalues[0]]) - transformPoint(scene->vertices[ivalues[2]]);            
            optix::float3 surfNormal = optix::normalize(optix::cross(diffVec1, diffVec2));

            struct Triangle newTriangle = {surfNormal, ambient, diffuse, specular, emission, shininess};
            scene->triangles.push_back(newTriangle);
        }
        else if (cmd == "sphere" && readValues(s, 4, fvalues))
        {
            optix::float3 center = 
            optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
            float radius = fvalues[3];

            // save the inverse transformation for intersection test
            struct Sphere newSphere = {center, radius, transStack.top().inverse(),
                                    ambient, diffuse, specular, emission, shininess};
            scene->spheres.push_back(newSphere);
        }
        else if (cmd == "ambient" && readValues(s, 3, fvalues))
        {
            ambient = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);            
        }
        else if (cmd == "diffuse" && readValues(s, 3, fvalues))
        {
            diffuse = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "specular" && readValues(s, 3, fvalues))
        {
            specular = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "emission" && readValues(s, 3, fvalues))
        {
            emission = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "shininess" && readValues(s, 1, fvalues))
        {
            shininess = fvalues[0];
        }
        else if (cmd == "attenuation" && readValues(s, 3, fvalues))
        {
            attenu = optix::make_float3(fvalues[0], fvalues[1], fvalues[2]);
        }
        else if (cmd == "point" && readValues(s, 6, fvalues))
        {
            struct PointLight newLight = {optix::make_float3(fvalues[0], fvalues[1], fvalues[2]),
            optix::make_float3(fvalues[3], fvalues[4], fvalues[5])};

            scene->plights.push_back(newLight);
        }
        else if (cmd == "directional" && readValues(s, 6, fvalues))
        {
            struct DirectionalLight newLight = {optix::make_float3(fvalues[0], fvalues[1], fvalues[2]),
            optix::make_float3(fvalues[3], fvalues[4], fvalues[5])};

            scene->dlights.push_back(newLight);
        }
        else if (cmd == "maxdepth" && readValues(s, 1, ivalues))
        {
            scene->maxDepth = ivalues[0];
        }
    }
    
    in.close();

    scene->attenu = attenu;
    scene->maxDepth = 5;
    return scene;
}