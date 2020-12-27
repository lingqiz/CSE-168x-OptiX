#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>
#include "random.h"

#include "Payloads.h"
#include "Geometries.h"
#include "Light.h"

using namespace optix;

// Declare light buffers and variable
rtBuffer<PointLight> plights;
rtBuffer<DirectionalLight> dlights;
rtDeclareVariable(float3, attenu, , );
rtDeclareVariable(int, maxDepth, , );

// Declare variables
rtDeclareVariable(Payload, payload, rtPayload, );
rtDeclareVariable(rtObject, root, , );

// Declare attibutes 
rtDeclareVariable(Attributes, attrib, attribute attrib, );

// ray and intersection related
rtDeclareVariable(Ray, ray, rtCurrentRay, );
rtDeclareVariable(float, t, rtIntersectionDistance, );

static __device__ __inline__ float3 
computeShading(const float3& lightDir, const float3& lightColor, const float3& normalVector,
const float3& halfVector, const float3& diffuse, const float3& specular, const float shininess)
{
    float n_dot_l = max(dot(normalVector, lightDir), 0.0f);
    float3 lambert = diffuse * lightColor * n_dot_l;

    float n_dot_h = max(dot(normalVector, halfVector), 0.0f);
    float3 phong   = specular * lightColor * pow(n_dot_h, shininess);

    return lambert + phong;
}

RT_PROGRAM void closestHit()
{
    const float T_MIN = 0.001f;    
    const int shadowRayIndex = 1;

    float3 radiance = attrib.ambient + attrib.emission;
    float3 hitPoint = ray.origin + t * ray.direction;

    // compute shading for point light
    for(int i = 0; i < plights.size(); i++)
    {   
        PointLight light = plights[i];
        float3 lightDir  = normalize(light.loc - hitPoint);
        float lightDist = length(light.loc - hitPoint);

        // Cast shadow ray and test for light source visibility
        Ray shadowRay = make_Ray(hitPoint, lightDir, shadowRayIndex, T_MIN, lightDist);
        ShadowPayload shadowPayload;
        shadowPayload.isVisible = true;

        rtTrace(root, shadowRay, shadowPayload);

        if(shadowPayload.isVisible)
        {
            float3 halfVector = normalize(lightDir - ray.direction);
            float attenuConst = attenu.x + attenu.y * lightDist + attenu.z * (lightDist * lightDist);
            
            radiance += computeShading(lightDir, light.col / attenuConst, attrib.surfNormal, 
                halfVector, attrib.diffuse, attrib.specular, attrib.shininess);
        }
    }

    // compute shading for direct light
    for(int i = 0; i < dlights.size(); i++)
    {
        DirectionalLight light = dlights[i];
        float3 lightDir = normalize(light.loc);

        // Cast shadow ray and test for light source visibility
        Ray shadowRay = make_Ray(hitPoint, lightDir, shadowRayIndex, T_MIN, RT_DEFAULT_MAX);
        ShadowPayload shadowPayload;
        shadowPayload.isVisible = true;

        rtTrace(root, shadowRay, shadowPayload);

        if(shadowPayload.isVisible)
        {
            float3 halfVector = normalize(lightDir - ray.direction);
            radiance += computeShading(lightDir, light.col, attrib.surfNormal, 
                halfVector, attrib.diffuse, attrib.specular, attrib.shininess);
        }
    }
    
    // Set radiance of current ray    
    payload.radiance = payload.specular * radiance;
   
    // recursive trace
    float zeroDelta = 0.001f;
    if(length(attrib.specular) < zeroDelta || payload.depth > maxDepth)
    {
        payload.recurs = false;
    }
    else
    {   
        // payload.recurs = true;
        // light ray for reflection
        payload.origin = hitPoint;
        payload.direction = ray.direction - 2 * dot(ray.direction, attrib.surfNormal) * attrib.surfNormal;
        payload.specular *= attrib.specular;
        payload.depth += 1;
    }
        
}