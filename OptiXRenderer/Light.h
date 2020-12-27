#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

/**
 * Structures describing different light sources should be defined here.
 */

struct PointLight
{
    optix::float3 loc;
    optix::float3 col;
};

struct DirectionalLight
{
    optix::float3 loc;
    optix::float3 col;
};