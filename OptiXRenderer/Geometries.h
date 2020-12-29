#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different geometries should be defined here.
 */

struct Triangle
{    
    // vertices are stored in triangleSoup variable
    
    // (inverse) geometry transformation and surface normal
    optix::float3 surfNormal;    

    // material property
    optix::float3 ambient;
    optix::float3 diffuse;
    optix::float3 specular;
    optix::float3 emission;
    float shininess;

    unsigned int lightSource;    
};

struct Sphere
{
    optix::float3 center;
    float radius;

    optix::Matrix<4, 4> invTransform;

    // material property
    optix::float3 ambient;
    optix::float3 diffuse;
    optix::float3 specular;
    optix::float3 emission;
    float shininess;

    unsigned int lightSource;
};

struct Attributes
{
    // surface normal
    optix::float3 surfNormal;

    // material property
    optix::float3 ambient;
    optix::float3 diffuse;
    optix::float3 specular;
    optix::float3 emission;
    float shininess;

    unsigned int lightSource;
};