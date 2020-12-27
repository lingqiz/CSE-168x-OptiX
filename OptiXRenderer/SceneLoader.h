#pragma once

#include <optixu/optixu_math_namespace.h>
#include <optixu/optixu_matrix_namespace.h>

#include <string>
#include <memory>
#include <fstream>
#include <sstream>
#include <vector>
#include <stack>
#include <iostream>
#include <math.h>

#include "Scene.h"
#include "Geometries.h"
#include "Light.h"


class SceneLoader
{
private:
    // variables for material property
    optix::float3 ambient = optix::make_float3(0.2f, 0.2f, 0.2f);
    optix::float3 diffuse = optix::make_float3(0.f, 0.f, 0.f);
    optix::float3 specular = optix::make_float3(0.f, 0.f, 0.f);
    optix::float3 emission = optix::make_float3(0.f, 0.f, 0.f);
    float shininess = 0.0;

    // matrix stack for keeping track of geometry
    std::stack<optix::Matrix4x4> transStack;

    /**
     * Right multiply M to the top matrix of transform stack.
     */
    void rightMultiply(const optix::Matrix4x4& M);

    /**
     * Transform a point with the top matrix of transform stack.
     */
    optix::float3 transformPoint(optix::float3 v);

    /**
     * Transform an normal with the top matrix of transform stack.
     */
    optix::float3 transformNormal(optix::float3 n);

    /**
     * Read values from a stringstream.
     */
    template <class T>
    bool readValues(std::stringstream& s, const int numvals, T* values);

public:
    std::shared_ptr<Scene> load(std::string sceneFilename);
};