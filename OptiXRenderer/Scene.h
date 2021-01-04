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
    unsigned int maxDepth;

    std::string integratorName;

    std::vector<optix::float3> vertices;
    std::vector<optix::float3> triangleSoup;

    std::vector<Triangle> triangles;
    std::vector<Sphere> spheres;

    std::vector<DirectionalLight> dlights;
    std::vector<PointLight> plights;
    std::vector<AreaLight> alights;
    optix::float3 attenu;

    // Camera parameter
    optix::float3 from;
    optix::float3 at;
    optix::float3 up;
    optix::float3 dir;
    optix::float3 u;
    optix::float3 v;

    float fovxRad;
    float fovyRad;

    // Monte Carlo parameter
    unsigned int spp;
    unsigned int lightSamples;
    bool lightStratify;

    Scene()
    {
        outputFilename = "raytrace.png";
        integratorName = "raytracer";

        maxDepth = 10;
        spp = 64;
        lightSamples = 1;
        lightStratify = false;
    }
};