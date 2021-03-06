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
    float cosTerm  = max(dot(reflectDir, lightDir), 0.0f);
    float3 lambert = kd / M_PIf;

    float zeroDelta = 0.000001f;
    if (cosTerm < zeroDelta)
        return lambert;

    float3 specular = ks * (s + 2.0f) / (2.0f * M_PIf) * pow(cosTerm, s);
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
    float3 reflectDir = normalize(ray.direction - 2 * dot(ray.direction, attrib.surfNormal) * attrib.surfNormal);

    if (!attrib.lightSource)
    {
        // Physically based rendering for area lights
        unsigned int seed = tea<16>(launchIndex.x, launchIndex.y);
        for(int i = 0; i < lights.size(); i++)
        {
            AreaLight light = lights[i];
            
            float3 radianceSum = make_float3(0.f, 0.f, 0.f);
            float3 lightNormal = normalize(cross(light.ab, light.ac));
            float  lightArea   = length(cross(light.ab, light.ac));
                            
            // Monte Carlo simulation
            for(int n = 0; n < nSample; n++)
            {   
                float u = rnd(seed);
                float v = rnd(seed);
                float3 lightLoc;

                if (stratify)
                {
                    int gridSize = (int) sqrt((float) nSample);
                    int x = n / gridSize;
                    int y = n % gridSize;
                    
                    lightLoc = light.a 
                        + ((float) x + u) / (float) gridSize * light.ab
                        + ((float) y + v) / (float) gridSize * light.ac;
                }
                else
                {
                    lightLoc = light.a + u * light.ab + v * light.ac;
                }
                                
                float3 lightDir = normalize(lightLoc - hitPoint);
                float lightDist = length(lightLoc - hitPoint);

                // Light source visibility
                Ray shadowRay = 
                    make_Ray(hitPoint, lightDir, shadowRayIndex, T_MIN, lightDist - T_MIN);
                ShadowPayload shadowPayload;
                shadowPayload.isVisible = true;
                
                rtTrace(root, shadowRay, shadowPayload);
                if(shadowPayload.isVisible)
                {
                    radianceSum +=
                    phongBRDF(attrib.diffuse, attrib.specular, attrib.shininess, lightDir, reflectDir) * 
                    max(dot(attrib.surfNormal, lightDir), 0.0f) * 
                    max(dot(lightNormal, lightDir), 0.0f) / (lightDist * lightDist);
                }
            }

            radiance += light.col * lightArea / ((float) nSample) * radianceSum;
        }
    }       
    // turn off recursive trace
    payload.recurs = false;
    payload.radiance = radiance;        
}