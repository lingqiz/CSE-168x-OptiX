#include <optix.h>
#include <optix_device.h>
#include <optixu/optixu_math_namespace.h>
#include "random.h"

#include "Payloads.h"
#include "Geometries.h"
#include "Light.h"

using namespace optix;

rtBuffer<AreaLight> lights;
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

const float T_MIN = 0.001f;
const int shadowRayIndex = 1;

enum Sampler {uniform, cosine, brdf};

// Compute modified Phong BRDF
static __device__ __inline__ float3 phongBRDF(const float3& kd, const float3& ks, 
    const float s, const float3& lightDir, const float3& reflectDir)
{
    float cosTerm  = max(dot(reflectDir, lightDir), 0.0f);
    float3 lambert = kd / M_PIf;

    float zeroDelta = 0.00001f;
    if (cosTerm < zeroDelta)
        return lambert;

    float3 specular = ks * (s + 2.0f) / (2.0f * M_PIf) * powf(cosTerm, s);
    return lambert + specular;    
}

// PDF approximation of the Phong BRDF function
static __device__ __inline__ float brdfPDF(const float3& surfNormal, const float3& reflectDir, const float3& lightDir, float t, float s)
{
    float diffuse = (1 - t) * max(dot(surfNormal, lightDir), 0.0f) / M_PIf;
    float l_dot_r = dot(reflectDir, lightDir);
    float specular = (l_dot_r <= 0)? 0.0f : (t * (s + 1) / (2 * M_PIf) * pow(dot(reflectDir, lightDir), s));

    return diffuse + specular;
}

// Compute radiance from direct area lighting
static __device__ __inline__ float3 directLight(unsigned int seed, 
    const float3& hitPoint, const float3& reflectDir)
{
    float3 radianceDirect = make_float3(0.0f, 0.0f, 0.0f);
    for(int i = 0; i < lights.size(); i++)
    {
        AreaLight light = lights[i];
        
        float3 radianceSum = make_float3(0.f, 0.f, 0.f);
        float3 lightNormal = normalize(cross(light.ab, light.ac));
        float  lightArea   = length(cross(light.ab, light.ac));
                        
        // Monte Carlo integration of direct lighting
        int nSample = 9;        
        for(int n = 0; n < nSample; n++)
        {   
            // Stratified sampling for area light source
            float u = rnd(seed);
            float v = rnd(seed);
            float3 lightLoc;
            
            int gridSize = (int) sqrt((float) nSample);
            int x = n / gridSize;
            int y = n % gridSize;
            
            lightLoc = light.a 
                + ((float) x + u) / (float) gridSize * light.ab
                + ((float) y + v) / (float) gridSize * light.ac;
                                        
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

        radianceDirect += light.col * lightArea / ((float) nSample) * radianceSum;
    }

    return radianceDirect;
}

// Uniformlly sample the upper hemisphere
static __device__ __inline__ float3 uniformSampler(unsigned int seed, const float3& surfNormal)
{
    float3 lightDir = make_float3(0.0f, 0.0f, 0.0f);
    do
    {
        lightDir.x = rnd(seed) * 2.0f - 1.0f;
        lightDir.y = rnd(seed) * 2.0f - 1.0f;
        lightDir.z = rnd(seed) * 2.0f - 1.0f;
    }
    while (length(lightDir) > 1.0f);
    lightDir = normalize(lightDir);

    if(dot(surfNormal, lightDir) < 0)
        return -lightDir;

    return lightDir;
}

// Sample with cosine PDF
static __device__ __inline__ float3 cosSampler(unsigned int seed, const float3& surfNormal)
{
    float theta = acosf(sqrtf(rnd(seed)));
    float phi = 2 * M_PIf * rnd(seed);

    float3 s = make_float3(cosf(phi) * sinf(theta), 
        sinf(phi) * sinf(theta), cosf(theta));

    float3 a = make_float3(1.0f, 0.f, 0.f);
    if(1 - dot(a, surfNormal) < 0.1f)
        a = make_float3(0.f, 1.0f, 0.f);

    float3 u = normalize(cross(a, surfNormal));
    float3 v = cross(surfNormal, u);

    return s.x * u + s.y * v + s.z * surfNormal;
}

// Sample from PDF adapted from Phong BRDF
static __device__ __inline__ float3 brdfSampler(unsigned int seed, const float3& surfNormal, const float3& reflectDir, float t, float s)
{    
    if(rnd(seed) <= t)
    {
        // sample the specular component
        float theta = acosf(powf(rnd(seed), 1.0f / (s + 1.0f)));
        float phi = 2 * M_PIf * rnd(seed);

        float3 s = make_float3(cosf(phi) * sinf(theta), 
            sinf(phi) * sinf(theta), cosf(theta));

        float3 a = make_float3(1.0f, 0.f, 0.f);
        if(1 - dot(a, reflectDir) < 0.1f)
            a = make_float3(0.f, 1.0f, 0.f);

        float3 u = normalize(cross(a, reflectDir));
        float3 v = cross(reflectDir, u);
        
        return s.x * u + s.y * v + s.z * reflectDir;
    }

    // sample the diffuse component
    return cosSampler(seed, surfNormal);
}

// Main path tracing routine
RT_PROGRAM void closestHit()
{    
    unsigned int seed = tea<16>(payload.seed, payload.depth);

    // Next event estimation of the rendering equation
    // Terminate if we hit the light source
    // Return emission for the first bounce
    if (attrib.lightSource)
    {
        payload.recurs = false;
        if(payload.depth == 0)        
            payload.radiance = attrib.emission;
    }             
    else
    {
        float3 hitPoint = ray.origin + t * ray.direction;
        float3 reflectDir = 
            normalize(ray.direction - 2 * dot(ray.direction, attrib.surfNormal) * attrib.surfNormal);

        // Otherwise, accumulate the emission and direct lighting term first
        payload.radiance += 
            payload.weight * (attrib.emission + directLight(seed, hitPoint, reflectDir));
                
        // Terminte using a Russian Roulette procedure
        float q = 1 - fminf(fmaxf(payload.weight), 1.0f);
        if (rnd(seed) < q)
        {
            payload.recurs = false;
        }
        else
        {
            // Reweight path contribution            
            payload.weight /= (1 - q);

            // Sample next indirect path
            // and update the contribution of the new path
            float3 lightDir;

            Sampler sampler = brdf;
            switch (sampler)
            {
                case uniform:
                    lightDir = uniformSampler(seed, attrib.surfNormal);
                    payload.weight *= (2 * M_PIf) * dot(attrib.surfNormal, lightDir) * 
                    phongBRDF(attrib.diffuse, attrib.specular, attrib.shininess, lightDir, reflectDir);
                break;

                case cosine:
                    lightDir = cosSampler(seed, attrib.surfNormal);
                    payload.weight *= M_PIf * 
                    phongBRDF(attrib.diffuse, attrib.specular, attrib.shininess, lightDir, reflectDir);
                break;

                case brdf:
                    lightDir = brdfSampler(seed, attrib.surfNormal, reflectDir, attrib.brdf_t, attrib.shininess);
                    if(dot(lightDir, attrib.surfNormal) <= 0)
                    {                        
                        payload.weight *= make_float3(0.0f, 0.0f, 0.0f);
                    }
                    else
                    {
                        payload.weight *= dot(attrib.surfNormal, lightDir) * 
                        phongBRDF(attrib.diffuse, attrib.specular, attrib.shininess, lightDir, reflectDir) /
                        brdfPDF(attrib.surfNormal, reflectDir, lightDir, attrib.brdf_t, attrib.shininess);
                    }                    
                break;
            }

            // Return and trace the new path
            payload.origin = hitPoint;
            payload.direction = lightDir;
            payload.depth += 1;
        }
    }   
}