#include <optix.h>
#include <optixu/optixu_math_namespace.h>
#include "Geometries.h"

using namespace optix;

rtBuffer<Triangle> triangles;
rtDeclareVariable(Attributes, attrib, attribute attrib, );

RT_PROGRAM void triangleAttribute()
{
    // pass surface normal and material information
    // to ray hit programs

    const int primIndex = rtGetPrimitiveIndex();
    Triangle triangle = triangles[primIndex];

    attrib.surfNormal = triangle.surfNormal;

    attrib.ambient = triangle.ambient;
    attrib.diffuse = triangle.diffuse;
    attrib.specular = triangle.specular;
    attrib.emission = triangle.emission;
    attrib.shininess = triangle.shininess;    
}