#include <optix.h>
#include <optix_device.h>
#include "Geometries.h"

using namespace optix;

rtBuffer<Sphere> spheres; // a buffer of all spheres
rtDeclareVariable(Ray, ray, rtCurrentRay, );

// Attributes to be passed to material programs 
rtDeclareVariable(Attributes, attrib, attribute attrib, );

RT_PROGRAM void intersect(int primIndex)
{
    // Find the intersection of the current ray and sphere
    float t;
    float3 surfNormal;

    Sphere sphere = spheres[primIndex];
    float3 center = sphere.center;
    float radius = sphere.radius;

    // Geometry associated with the sphere
    Matrix<4, 4> transform = sphere.invTransform;
    
    float4 oriTrans = transform * make_float4(ray.origin, 1);
    float4 diTrans = transform * make_float4(ray.direction, 0);
    
    float3 origin = make_float3(oriTrans) / oriTrans.w;
    float3 direction = make_float3(diTrans);

    float a = dot(direction, direction);
    float b = 2 * dot(direction, origin - center);
    float c = dot(origin - center, origin - center) - (radius * radius);
    float deter = b*b - 4*a*c;

    if(deter <= 0)
    {
        t = -1;
    }        
    else
    {
        float x1 = (-b + sqrt(deter)) / (2*a);
        float x2 = (-b - sqrt(deter)) / (2*a);

        if (x2 > 0)
        {
            // outside intersection
            t = x2;
            surfNormal = normalize(make_float3(transform.transpose() * 
            make_float4(origin + t * direction - center, 0)));
        }            
        else        
        {   
            // inside intersection
            t = x1;
            surfNormal = -normalize(make_float3(transform.transpose() * 
            make_float4(origin + t * direction - center, 0)));            
        }            
    }
        
    // Report intersection (material programs will handle the rest)
    if (rtPotentialIntersection(t))
    {
        // compute surface normal
        attrib.surfNormal = surfNormal;

        // assign material property
        attrib.ambient = sphere.ambient;
        attrib.diffuse = sphere.diffuse;
        attrib.specular = sphere.specular;
        attrib.emission = sphere.emission;
        attrib.shininess = sphere.shininess;

        rtReportIntersection(0);
    }
}

RT_PROGRAM void bound(int primIndex, float result[6])
{
    Sphere sphere = spheres[primIndex];

    // Sphere bouding box program not implemented for now
    // No acceleration structure is used
    float MIN = -10000.0f;
    float MAX = +10000.0f;

    result[0] = MIN; result[1] = MIN; result[2] = MIN;
    result[3] = MAX; result[4] = MAX; result[5] = MAX;
}