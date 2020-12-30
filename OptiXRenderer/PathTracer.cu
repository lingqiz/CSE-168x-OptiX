#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>
#include "random.h"

#include "Payloads.h"
#include "Geometries.h"
#include "Light.h"

using namespace optix;

rtDeclareVariable(int, maxDepth, , );

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
    float cosTerm  = max(dot(reflectDir, lightDir), 0.0f);
    float3 lambert = kd / M_PIf;

    float zeroDelta = 0.00001f;
    if (cosTerm < zeroDelta)
        return lambert;

    float3 specular = ks * (s + 2.0f) / (2.0f * M_PIf) * pow(cosTerm, s);
    return lambert + specular;    
}

RT_PROGRAM void closestHit()
{
    const float T_MIN = 0.001f;    
    const int shadowRayIndex = 1;    
    unsigned int seed = tea<16>(payload.seed, payload.depth);

    // Naïve Monte Carlo estimation of the rendering equation
    // Terminate if we hit the light source
    if (attrib.lightSource)
    {
        payload.recurs = false;
        payload.radiance = attrib.emission;
    }    
    // Otherwise, keep sampling new path through the scene
    // Terminte using a Russian Roulette procedure
    else
    {           
        float q = 1 - fminf(fmaxf(payload.weight), 1.0f);
        if (rnd(seed) < q)
        {
            payload.recurs = false;
            payload.radiance = attrib.emission;
        }
        else
        {
            payload.weight /= (1 - q);
            float3 hitPoint = ray.origin + t * ray.direction;
            float3 reflectDir = normalize(ray.direction - 2 * dot(ray.direction, attrib.surfNormal) * attrib.surfNormal);
            
            // sample the upper half hemisphere for light ray        
            float3 lightDir = make_float3(0.0f, 0.0f, 0.0f);
            do
            {
                lightDir.x = rnd(seed) * 2.0f - 1.0f;
                lightDir.y = rnd(seed) * 2.0f - 1.0f;
                lightDir.z = rnd(seed) * 2.0f - 1.0f;
            }
            while (length(lightDir) > 1.0f);
            lightDir = normalize(lightDir);

            if(dot(attrib.surfNormal, lightDir) < 0)
                lightDir = -lightDir;

            payload.weight *= (2 * M_PIf) * dot(attrib.surfNormal, lightDir) * 
                phongBRDF(attrib.diffuse, attrib.specular, attrib.shininess, lightDir, reflectDir);

            payload.origin = hitPoint;
            payload.direction = lightDir;
            payload.depth += 1;
        }        
    }        
        
}