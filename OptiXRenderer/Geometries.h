#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different geometries should be defined here.
 */

struct Triangle
{    
    // vertices
    optix::float3 A;
    optix::float3 B;
    optix::float3 C;
};

struct Sphere
{
    optix::float3 center;
    float radius;

    optix::Matrix<4, 4> transform;
};

struct Attributes
{
    
    
};