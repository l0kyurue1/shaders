#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float2 u_resolution;
    float u_pixelRatio;
    float u_imageAspectRatio;
    float u_originX;
    float u_originY;
    float u_worldWidth;
    float u_worldHeight;
    float u_fit;
    float u_scale;
    float u_rotation;
    float u_offsetX;
    float u_offsetY;
};

struct main0_out
{
    float2 v_objectUV [[user(locn0)]];
    float2 v_objectBoxSize [[user(locn1)]];
    float2 v_responsiveUV [[user(locn2)]];
    float2 v_responsiveBoxGivenSize [[user(locn3)]];
    float2 v_patternUV [[user(locn4)]];
    float2 v_patternBoxSize [[user(locn5)]];
    float2 v_imageUV [[user(locn6)]];
    float4 gl_Position [[position]];
};

struct main0_in
{
    float4 a_position [[attribute(0)]];
};

static inline __attribute__((always_inline))
float3 getBoxSize(thread const float& boxRatio, thread const float2& givenBoxSize, constant Params& params)
{
    float2 box = float2(0.0);
    box.x = boxRatio * fast::min(givenBoxSize.x / boxRatio, givenBoxSize.y);
    float noFitBoxWidth = box.x;
    if (params.u_fit == 1.0)
    {
        box.x = boxRatio * fast::min(params.u_resolution.x / boxRatio, params.u_resolution.y);
    }
    else
    {
        if (params.u_fit == 2.0)
        {
            box.x = boxRatio * fast::max(params.u_resolution.x / boxRatio, params.u_resolution.y);
        }
    }
    box.y = box.x / boxRatio;
    return float3(box, noFitBoxWidth);
}

vertex main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]])
{
    main0_out out = {};
    out.gl_Position = in.a_position;
    float2 uv = out.gl_Position.xy * 0.5;
    float2 boxOrigin = float2(0.5 - params.u_originX, params.u_originY - 0.5);
    float2 givenBoxSize = float2(params.u_worldWidth, params.u_worldHeight);
    givenBoxSize = fast::max(givenBoxSize, float2(1.0)) * params.u_pixelRatio;
    float r = (params.u_rotation * 3.1415927) / 180.0;
    float2x2 graphicRotation = float2x2(float2(cos(r), sin(r)), float2(-sin(r), cos(r)));
    float2 graphicOffset = float2(-params.u_offsetX, params.u_offsetY);
    float fixedRatio = 1.0;
    float _165;
    if (params.u_worldWidth == 0.0)
    {
        _165 = params.u_resolution.x;
    }
    else
    {
        _165 = givenBoxSize.x;
    }
    float _177;
    if (params.u_worldHeight == 0.0)
    {
        _177 = params.u_resolution.y;
    }
    else
    {
        _177 = givenBoxSize.y;
    }
    float2 fixedRatioBoxGivenSize = float2(_165, _177);
    float param = fixedRatio;
    float2 param_1 = fixedRatioBoxGivenSize;
    out.v_objectBoxSize = getBoxSize(param, param_1, params).xy;
    float2 objectWorldScale = params.u_resolution / out.v_objectBoxSize;
    out.v_objectUV = uv;
    out.v_objectUV *= objectWorldScale;
    out.v_objectUV += (boxOrigin * (objectWorldScale - float2(1.0)));
    out.v_objectUV += graphicOffset;
    out.v_objectUV /= float2(params.u_scale);
    out.v_objectUV = graphicRotation * out.v_objectUV;
    float _229;
    if (params.u_worldWidth == 0.0)
    {
        _229 = params.u_resolution.x;
    }
    else
    {
        _229 = givenBoxSize.x;
    }
    float _241;
    if (params.u_worldHeight == 0.0)
    {
        _241 = params.u_resolution.y;
    }
    else
    {
        _241 = givenBoxSize.y;
    }
    out.v_responsiveBoxGivenSize = float2(_229, _241);
    float responsiveRatio = out.v_responsiveBoxGivenSize.x / out.v_responsiveBoxGivenSize.y;
    float param_2 = responsiveRatio;
    float2 param_3 = out.v_responsiveBoxGivenSize;
    float2 responsiveBoxSize = getBoxSize(param_2, param_3, params).xy;
    float2 responsiveBoxScale = params.u_resolution / responsiveBoxSize;
    out.v_responsiveUV = uv;
    out.v_responsiveUV *= responsiveBoxScale;
    out.v_responsiveUV += (boxOrigin * (responsiveBoxScale - float2(1.0)));
    out.v_responsiveUV += graphicOffset;
    out.v_responsiveUV /= float2(params.u_scale);
    out.v_responsiveUV.x *= responsiveRatio;
    out.v_responsiveUV = graphicRotation * out.v_responsiveUV;
    out.v_responsiveUV.x /= responsiveRatio;
    float patternBoxRatio = givenBoxSize.x / givenBoxSize.y;
    float _313;
    if (params.u_worldWidth == 0.0)
    {
        _313 = params.u_resolution.x;
    }
    else
    {
        _313 = givenBoxSize.x;
    }
    float _325;
    if (params.u_worldHeight == 0.0)
    {
        _325 = params.u_resolution.y;
    }
    else
    {
        _325 = givenBoxSize.y;
    }
    float2 patternBoxGivenSize = float2(_313, _325);
    patternBoxRatio = patternBoxGivenSize.x / patternBoxGivenSize.y;
    float param_4 = patternBoxRatio;
    float2 param_5 = patternBoxGivenSize;
    float3 boxSizeData = getBoxSize(param_4, param_5, params);
    out.v_patternBoxSize = boxSizeData.xy;
    float patternBoxNoFitBoxWidth = boxSizeData.z;
    float2 patternBoxScale = params.u_resolution / out.v_patternBoxSize;
    out.v_patternUV = uv;
    out.v_patternUV += (graphicOffset / patternBoxScale);
    out.v_patternUV += boxOrigin;
    out.v_patternUV -= (boxOrigin / patternBoxScale);
    out.v_patternUV *= params.u_resolution;
    out.v_patternUV /= float2(params.u_pixelRatio);
    if (params.u_fit > 0.0)
    {
        out.v_patternUV *= (patternBoxNoFitBoxWidth / out.v_patternBoxSize.x);
    }
    out.v_patternUV /= float2(params.u_scale);
    out.v_patternUV = graphicRotation * out.v_patternUV;
    out.v_patternUV += (boxOrigin / patternBoxScale);
    out.v_patternUV -= boxOrigin;
    out.v_patternUV *= 0.01;
    float2 imageBoxSize;
    if (params.u_fit == 1.0)
    {
        imageBoxSize.x = fast::min(params.u_resolution.x / params.u_imageAspectRatio, params.u_resolution.y) * params.u_imageAspectRatio;
    }
    else
    {
        if (params.u_fit == 2.0)
        {
            imageBoxSize.x = fast::max(params.u_resolution.x / params.u_imageAspectRatio, params.u_resolution.y) * params.u_imageAspectRatio;
        }
        else
        {
            imageBoxSize.x = fast::min(10.0, (10.0 / params.u_imageAspectRatio) * params.u_imageAspectRatio);
        }
    }
    imageBoxSize.y = imageBoxSize.x / params.u_imageAspectRatio;
    float2 imageBoxScale = params.u_resolution / imageBoxSize;
    out.v_imageUV = uv;
    out.v_imageUV *= imageBoxScale;
    out.v_imageUV += (boxOrigin * (imageBoxScale - float2(1.0)));
    out.v_imageUV += graphicOffset;
    out.v_imageUV /= float2(params.u_scale);
    out.v_imageUV.x *= params.u_imageAspectRatio;
    out.v_imageUV = graphicRotation * out.v_imageUV;
    out.v_imageUV.x /= params.u_imageAspectRatio;
    out.v_imageUV += float2(0.5);
    out.v_imageUV.y = 1.0 - out.v_imageUV.y;
    return out;
}

