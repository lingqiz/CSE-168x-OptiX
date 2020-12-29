#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>
#include "random.h"

#include "Payloads.h"
#include "Geometries.h"
#include "Light.h"

using namespace optix;

// Declare light buffers and variable
rtBuffer<AreaLight> lights;
rtDeclareVariable(int, nSample, , );
rtDeclareVariable(int, stratify, , );

// Declare variables
rtDeclareVariable(uint2, launchIndex, rtLaunchIndex, );
rtDeclareVariable(Payload, payload, rtPayload, );
rtDeclareVariable(rtObject, root, , );

// Declare attibutes 
rtDeclareVariable(Attributes, attrib, attribute attrib, );

// ray and intersection related
rtDeclareVariable(Ray, ray, rtCurrentRay, );
rtDeclareVariable(float, t, rtIntersectionDistance, );

static __device__ __inline__ float3 phongBRDF(const float3& kd, const float3& ks, 
    const float s, const float3& lightDir, const float3& reflectDir)
{
    float3 lambert = kd / M_PIf;
    float3 specular = ks * (s + 2) / (2 * M_PIf) * pow(dot(reflectDir, lightDir), s);
    return lambert + specular;
}

RT_PROGRAM void closestHit()
{
    const float T_MIN = 0.001f;    
    const int shadowRayIndex = 1;

    // We slove the first two terms of the rendering equation:
    // emission and direct lighting

    float3 radiance = attrib.emission;
    float3 hitPoint = ray.origin + t * ray.direction;

    // Physically based rendering for area lights
    unsigned int seed = tea<16>(launchIndex.x, launchIndex.y);
    for(int i = 0; i < lights.size(); i++)
    {
        AreaLight light = lights[i];
        float3 radianceSum = make_float3(0.f, 0.f, 0.f);
        float3 lightNormal = normalize(cross(light.ab, light.ac));
        float  lightArea   = length(cross(light.ab, light.ac));        
        
        for(int n = 0; n < nSample; n++)
        {
            float u = rnd(seed);
            float v = rnd(seed);                        
            rtPrintf("%.2f, %.2f \n", u, v);
        }
        radiance += radianceSum / (float) nSample;
    }
   
    // turn off recursive trace
    payload.recurs = false;
        
}