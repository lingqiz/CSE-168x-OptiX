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

    // Physically based rendering for area lights
   
    // turn off recursive trace
    payload.recurs = false;
        
}