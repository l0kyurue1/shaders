#pragma clang diagnostic ignored "-Wmissing-prototypes"
#pragma clang diagnostic ignored "-Wmissing-braces"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

template<typename T, size_t Num>
struct spvUnsafeArray
{
    T elements[Num ? Num : 1];
    
    thread T& operator [] (size_t pos) thread
    {
        return elements[pos];
    }
    constexpr const thread T& operator [] (size_t pos) const thread
    {
        return elements[pos];
    }
    
    device T& operator [] (size_t pos) device
    {
        return elements[pos];
    }
    constexpr const device T& operator [] (size_t pos) const device
    {
        return elements[pos];
    }
    
    constexpr const constant T& operator [] (size_t pos) const constant
    {
        return elements[pos];
    }
    
    threadgroup T& operator [] (size_t pos) threadgroup
    {
        return elements[pos];
    }
    constexpr const threadgroup T& operator [] (size_t pos) const threadgroup
    {
        return elements[pos];
    }
};

struct Params
{
    float2 u_resolution;
    float u_pixelRatio;
    float u_originX;
    float u_originY;
    float u_worldWidth;
    float u_worldHeight;
    float u_fit;
    float u_scale;
    float u_rotation;
    float u_offsetX;
    float u_offsetY;
    float4 u_colorFront;
    float4 u_colorBack;
    float4 u_colorHighlight;
    float u_imageAspectRatio;
    float u_type;
    float u_pxSize;
    uint u_originalColors;
    uint u_inverted;
    float u_colorSteps;
};

constant spvUnsafeArray<int, 4> _305 = spvUnsafeArray<int, 4>({ 0, 2, 3, 1 });
constant spvUnsafeArray<int, 16> _328 = spvUnsafeArray<int, 16>({ 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 });
constant spvUnsafeArray<int, 64> _393 = spvUnsafeArray<int, 64>({ 0, 32, 8, 40, 2, 34, 10, 42, 48, 16, 56, 24, 50, 18, 58, 26, 12, 44, 4, 36, 14, 46, 6, 38, 60, 28, 52, 20, 62, 30, 54, 22, 3, 35, 11, 43, 1, 33, 9, 41, 51, 19, 59, 27, 49, 17, 57, 25, 15, 47, 7, 39, 13, 45, 5, 37, 63, 31, 55, 23, 61, 29, 53, 21 });

struct main0_out
{
    float4 fragColor [[color(0)]];
};

static inline __attribute__((always_inline))
float2 getImageUV(thread const float2& uv, constant Params& params)
{
    float2 boxOrigin = float2(0.5 - params.u_originX, params.u_originY - 0.5);
    float r = (params.u_rotation * 3.1415927) / 180.0;
    float2x2 graphicRotation = float2x2(float2(cos(r), sin(r)), float2(-sin(r), cos(r)));
    float2 graphicOffset = float2(-params.u_offsetX, params.u_offsetY);
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
    float2 imageUV = uv;
    imageUV *= imageBoxScale;
    imageUV += (boxOrigin * (imageBoxScale - float2(1.0)));
    imageUV += graphicOffset;
    imageUV /= float2(params.u_scale);
    imageUV.x *= params.u_imageAspectRatio;
    imageUV = graphicRotation * imageUV;
    imageUV.x /= params.u_imageAspectRatio;
    imageUV += float2(0.5);
    imageUV.y = 1.0 - imageUV.y;
    return imageUV;
}

static inline __attribute__((always_inline))
float getUvFrame(thread const float2& uv, thread const float2& pad)
{
    float aa = 0.0001;
    float left = smoothstep(-pad.x, (-pad.x) + aa, uv.x);
    float right = smoothstep(1.0 + pad.x, (1.0 + pad.x) - aa, uv.x);
    float bottom = smoothstep(-pad.y, (-pad.y) + aa, uv.y);
    float top = smoothstep(1.0 + pad.y, (1.0 + pad.y) - aa, uv.y);
    return ((left * right) * bottom) * top;
}

static inline __attribute__((always_inline))
float getBayerValue(thread const float2& uv, thread const int& size)
{
    int2 pos = int2(fract(uv / float2(float(size))) * float(size));
    int index = (pos.y * size) + pos.x;
    if (size == 2)
    {
        return float(_305[index]) / 4.0;
    }
    else
    {
        if (size == 4)
        {
            return float(_328[index]) / 16.0;
        }
        else
        {
            if (size == 8)
            {
                return float(_393[index]) / 64.0;
            }
        }
    }
    return 0.0;
}

static inline __attribute__((always_inline))
float hash21(thread float2& p)
{
    p = fract(p * float2(0.3183099, 0.3678794)) + float2(0.1);
    p += float2(dot(p, p + float2(19.19)));
    return fract(p.x * p.y);
}

fragment main0_out main0(constant Params& params [[buffer(0)]], texture2d<float> u_image [[texture(0)]], sampler u_imageSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float pxSize = params.u_pxSize * params.u_pixelRatio;
    float2 pxSizeUV = gl_FragCoord.xy - (params.u_resolution * 0.5);
    pxSizeUV /= float2(pxSize);
    float2 canvasPixelizedUV = (floor(pxSizeUV) + float2(0.5)) * pxSize;
    float2 normalizedUV = canvasPixelizedUV / params.u_resolution;
    float2 param = normalizedUV;
    float2 imageUV = getImageUV(param, params);
    float2 ditheringNoiseUV = canvasPixelizedUV;
    float4 image = u_image.sample(u_imageSmplr, imageUV);
    float2 param_1 = imageUV;
    float2 param_2 = float2(pxSize) / params.u_resolution;
    float frame = getUvFrame(param_1, param_2);
    int type = int(floor(params.u_type));
    float dithering = 0.0;
    float lum = dot(float3(0.2126, 0.7152, 0.0722), image.xyz);
    float _480;
    if (params.u_inverted != 0u)
    {
        _480 = 1.0 - lum;
    }
    else
    {
        _480 = lum;
    }
    lum = _480;
    switch (type)
    {
        case 1:
        {
            float2 param_3 = ditheringNoiseUV;
            float _496 = hash21(param_3);
            dithering = step(_496, lum);
            break;
        }
        case 2:
        {
            float2 param_4 = pxSizeUV;
            int param_5 = 2;
            dithering = getBayerValue(param_4, param_5);
            break;
        }
        case 3:
        {
            float2 param_6 = pxSizeUV;
            int param_7 = 4;
            dithering = getBayerValue(param_6, param_7);
            break;
        }
        default:
        {
            float2 param_8 = pxSizeUV;
            int param_9 = 8;
            dithering = getBayerValue(param_8, param_9);
            break;
        }
    }
    float colorSteps = fast::max(floor(params.u_colorSteps), 1.0);
    float3 color = float3(0.0);
    float opacity = 1.0;
    dithering -= 0.5;
    float brightness = fast::clamp(lum + (dithering / colorSteps), 0.0, 1.0);
    brightness = mix(0.0, brightness, frame);
    brightness = mix(0.0, brightness, image.w);
    float quantLum = floor((brightness * colorSteps) + 0.5) / colorSteps;
    quantLum = mix(0.0, quantLum, frame);
    if ((params.u_originalColors != 0u) == true)
    {
        float3 normColor = image.xyz / float3(fast::max(lum, 0.001));
        color = normColor * quantLum;
        float quantAlpha = floor((image.w * colorSteps) + 0.5) / colorSteps;
        opacity = mix(quantLum, 1.0, quantAlpha);
    }
    else
    {
        float3 fgColor = params.u_colorFront.xyz * params.u_colorFront.w;
        float fgOpacity = params.u_colorFront.w;
        float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
        float bgOpacity = params.u_colorBack.w;
        float3 hlColor = params.u_colorHighlight.xyz * params.u_colorHighlight.w;
        float hlOpacity = params.u_colorHighlight.w;
        fgColor = mix(fgColor, hlColor, float3(step(1.02 - (0.02 * params.u_colorSteps), brightness)));
        fgOpacity = mix(fgOpacity, hlOpacity, step(1.02 - (0.02 * params.u_colorSteps), brightness));
        color = fgColor * quantLum;
        opacity = fgOpacity * quantLum;
        color += (bgColor * (1.0 - opacity));
        opacity += (bgOpacity * (1.0 - opacity));
    }
    out.fragColor = float4(color, opacity);
    return out;
}

