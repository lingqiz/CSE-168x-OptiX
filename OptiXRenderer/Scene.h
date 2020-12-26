#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

#include "Geometries.h"
#include "Light.h"

struct Scene
{
    // Info about the output image
    std::string outputFilename;
    unsigned int width, height;

    std::string integratorName;

    std::vector<optix::float3> vertices;

    std::vector<Triangle> triangles;
    std::vector<Sphere> spheres;

    std::vector<DirectionalLight> dlights;
    std::vector<PointLight> plights;

    // camera parameter
    optix::float3 from;
    optix::float3 at;
    optix::float3 up;
    optix::float3 dir;
    optix::float3 u;
    optix::float3 v;

    float fovxRad;
    float fovyRad;

    Scene()
    {
        outputFilename = "raytrace.png";
        integratorName = "raytracer";
    }
};