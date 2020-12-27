#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>

#include "Payloads.h"

using namespace optix;

rtBuffer<float3, 2> resultBuffer; // used to store the render result

rtDeclareVariable(rtObject, root, , ); // Optix graph
rtDeclareVariable(uint2, launchIndex, rtLaunchIndex, ); // a 2d index (x, y)
rtDeclareVariable(int1, frameID, , );

// Camera info 
rtDeclareVariable(float, width, , );
rtDeclareVariable(float, height, , );
rtDeclareVariable(float3, dir, , );
rtDeclareVariable(float3, u, , );
rtDeclareVariable(float3, v, , );
rtDeclareVariable(float3, camFrom, , );
rtDeclareVariable(float, fovxRad, , );
rtDeclareVariable(float, fovyRad, , );

RT_PROGRAM void generateRays()
{    
    const float T_MIN = 0.0001f;
    const int primRayIndex = 0;

    // Calculate the ray direction
    // x: width variable, y: height variable
    // (0, 0) is at upper left corner
    float idw = ((float) launchIndex.x) + 0.5f;
    float idh = ((float) launchIndex.y) + 0.5f;

    float alpha = tan(fovxRad / 2.0f) * (idw - width / 2.0f) / (width / 2.0f);
    float beta  = tan(fovyRad / 2.0f) * (height / 2.0f - idh) / (height / 2.0f);
    float3 rayDir = normalize(alpha * u + beta * v - dir);

    // Set up variable for recursive ray tracing
    float3 result = make_float3(0.0f, 0.0f, 0.0f);

    Payload payload;
    payload.depth = 0; payload.recurs = true;
    payload.origin = camFrom; payload.direction = rayDir;
    payload.specular = make_float3(1.0f, 1.0f, 1.0f);
    
    do
    {
        Ray ray = make_Ray(payload.origin, payload.direction, primRayIndex, T_MIN, RT_DEFAULT_MAX);
        rtTrace(root, ray, payload);
        
        result += payload.radiance;
    } 
    while(payload.recurs);
            
    // Write the result
    resultBuffer[launchIndex] = result;
}