#include <optix.h>
#include <optix_device.h>

#include "Payloads.h"

using namespace optix;

rtDeclareVariable(Payload, payload, rtPayload, );
rtDeclareVariable(float3, backgroundColor, , );

RT_PROGRAM void miss()
{
    // Set the result to be the background color if miss
    payload.radiance = backgroundColor;
    payload.done = true;
}

RT_PROGRAM void exception()
{
    // Print any exception for debugging
    const unsigned int code = rtGetExceptionCode();
    rtPrintExceptionDetails();
}

rtDeclareVariable(ShadowPayload, shadowPayload, rtPayload, );
rtDeclareVariable(float1, t, rtIntersectionDistance, );

RT_PROGRAM void anyHit()
{
    shadowPayload.isVisible = false;
    rtTerminateRay();
}