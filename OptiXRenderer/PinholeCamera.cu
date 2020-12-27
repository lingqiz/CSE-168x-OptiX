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
    // Calculate the ray direction
    // Note that the indices are flipped due to column major convention
    float T_MIN = 0.001f;
    float idw = ((float) launchIndex.x) + 0.5f;
    float idh = ((float) launchIndex.y) + 0.5f;

    float alpha = tan(fovxRad / 2.0f) * (idw - width / 2.0f) / (width / 2.0f);
    float beta  = tan(fovyRad / 2.0f) * (height / 2.0f - idh) / (height / 2.0f);
    float3 rayDir = normalize(alpha * u + beta * v - dir);

    // Shoot a ray to compute the color of the current pixel
    Ray ray = make_Ray(camFrom, rayDir, 0, T_MIN, RT_DEFAULT_MAX);
    Payload payload;
    rtTrace(root, ray, payload);
        
    // Write the result
    resultBuffer[launchIndex] = payload.radiance;
}