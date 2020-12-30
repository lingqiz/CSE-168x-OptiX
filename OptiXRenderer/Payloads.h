#pragma once

#include <optixu/optixu_math_namespace.h>
#include "Geometries.h"

/**
 * Structures describing different payloads should be defined here.
 */

struct Payload
{
    optix::float3 radiance;
    optix::float3 weight;
    
    // variable for recursive trace
    int depth;    
    bool recurs;
    optix::float3 origin;
    optix::float3 direction;
};

struct ShadowPayload
{
    int isVisible;
};