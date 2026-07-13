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

// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()
template<typename Tx, typename Ty>
inline Tx mod(Tx x, Ty y)
{
    return x - y * floor(x / y);
}

struct Params
{
    float u_time;
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
    float u_pxSize;
    float4 u_colorBack;
    float4 u_colorFront;
    float u_shape;
    float u_type;
};

constant spvUnsafeArray<int, 4> _322 = spvUnsafeArray<int, 4>({ 0, 2, 3, 1 });
constant spvUnsafeArray<int, 16> _351 = spvUnsafeArray<int, 16>({ 0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5 });
constant spvUnsafeArray<int, 64> _416 = spvUnsafeArray<int, 64>({ 0, 32, 8, 40, 2, 34, 10, 42, 48, 16, 56, 24, 50, 18, 58, 26, 12, 44, 4, 36, 14, 46, 6, 38, 60, 28, 52, 20, 62, 30, 54, 22, 3, 35, 11, 43, 1, 33, 9, 41, 51, 19, 59, 27, 49, 17, 57, 25, 15, 47, 7, 39, 13, 45, 5, 37, 63, 31, 55, 23, 61, 29, 53, 21 });

struct main0_out
{
    float4 fragColor [[color(0)]];
};

static inline __attribute__((always_inline))
float3 permute(thread const float3& x)
{
    return mod(((x * 34.0) + float3(1.0)) * x, float3(289.0));
}

static inline __attribute__((always_inline))
float snoise(thread const float2& v)
{
    float2 i = floor(v + float2(dot(v, float2(0.36602542))));
    float2 x0 = (v - i) + float2(dot(i, float2(0.21132487)));
    float2 i1 = select(float2(0.0, 1.0), float2(1.0, 0.0), bool2(x0.x > x0.y));
    float4 x12 = x0.xyxy + float4(0.21132487, 0.21132487, -0.57735026, -0.57735026);
    float4 _96 = x12;
    float2 _98 = _96.xy - i1;
    x12.x = _98.x;
    x12.y = _98.y;
    i = mod(i, float2(289.0));
    float3 param = float3(i.y) + float3(0.0, i1.y, 1.0);
    float3 param_1 = (permute(param) + float3(i.x)) + float3(0.0, i1.x, 1.0);
    float3 p = permute(param_1);
    float3 m = fast::max(float3(0.5) - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), float3(0.0));
    m *= m;
    m *= m;
    float3 x = (fract(p * float3(0.024390243)) * 2.0) - float3(1.0);
    float3 h = abs(x) - float3(0.5);
    float3 ox = floor(x + float3(0.5));
    float3 a0 = x - ox;
    m *= (float3(1.7928429) - (((a0 * a0) + (h * h)) * 0.85373473));
    float3 g;
    g.x = (a0.x * x0.x) + (h.x * x0.y);
    float2 _213 = (a0.yz * x12.xz) + (h.yz * x12.yw);
    g.y = _213.x;
    g.z = _213.y;
    return 130.0 * dot(m, g);
}

static inline __attribute__((always_inline))
float getSimplexNoise(thread const float2& uv, thread const float& t)
{
    float2 param = uv - float2(0.0, 0.3 * t);
    float _noise = 0.5 * snoise(param);
    float2 param_1 = (uv * 2.0) + float2(0.0, 0.32 * t);
    _noise += (0.5 * snoise(param_1));
    return _noise;
}

static inline __attribute__((always_inline))
float hash11(thread float& p)
{
    p = fract(p * 0.3183099) + 0.1;
    p *= (p + 19.19);
    return fract(p * p);
}

static inline __attribute__((always_inline))
float getBayerValue(thread const float2& uv, thread const int& size)
{
    int2 pos = int2(fract(uv / float2(float(size))) * float(size));
    int index = (pos.y * size) + pos.x;
    if (size == 2)
    {
        return float(_322[index]) / 4.0;
    }
    else
    {
        if (size == 4)
        {
            return float(_351[index]) / 16.0;
        }
        else
        {
            if (size == 8)
            {
                return float(_416[index]) / 64.0;
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

fragment main0_out main0(constant Params& params [[buffer(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float t = 0.5 * params.u_time;
    float pxSize = params.u_pxSize * params.u_pixelRatio;
    float2 pxSizeUV = gl_FragCoord.xy - (params.u_resolution * 0.5);
    pxSizeUV /= float2(pxSize);
    float2 canvasPixelizedUV = (floor(pxSizeUV) + float2(0.5)) * pxSize;
    float2 normalizedUV = canvasPixelizedUV / params.u_resolution;
    float2 ditheringNoiseUV = canvasPixelizedUV;
    float2 shapeUV = normalizedUV;
    float2 boxOrigin = float2(0.5 - params.u_originX, params.u_originY - 0.5);
    float2 givenBoxSize = float2(params.u_worldWidth, params.u_worldHeight);
    givenBoxSize = fast::max(givenBoxSize, float2(1.0)) * params.u_pixelRatio;
    float r = (params.u_rotation * 3.1415927) / 180.0;
    float2x2 graphicRotation = float2x2(float2(cos(r), sin(r)), float2(-sin(r), cos(r)));
    float2 graphicOffset = float2(-params.u_offsetX, params.u_offsetY);
    float patternBoxRatio = givenBoxSize.x / givenBoxSize.y;
    float _531;
    if (params.u_worldWidth == 0.0)
    {
        _531 = params.u_resolution.x;
    }
    else
    {
        _531 = givenBoxSize.x;
    }
    float _543;
    if (params.u_worldHeight == 0.0)
    {
        _543 = params.u_resolution.y;
    }
    else
    {
        _543 = givenBoxSize.y;
    }
    float2 boxSize = float2(_531, _543);
    if (params.u_shape > 3.5)
    {
        float2 objectBoxSize = float2(0.0);
        objectBoxSize.x = fast::min(boxSize.x, boxSize.y);
        if (params.u_fit == 1.0)
        {
            objectBoxSize.x = fast::min(params.u_resolution.x, params.u_resolution.y);
        }
        else
        {
            if (params.u_fit == 2.0)
            {
                objectBoxSize.x = fast::max(params.u_resolution.x, params.u_resolution.y);
            }
        }
        objectBoxSize.y = objectBoxSize.x;
        float2 objectWorldScale = params.u_resolution / objectBoxSize;
        shapeUV *= objectWorldScale;
        shapeUV += (boxOrigin * (objectWorldScale - float2(1.0)));
        shapeUV += float2(-params.u_offsetX, params.u_offsetY);
        shapeUV /= float2(params.u_scale);
        shapeUV = graphicRotation * shapeUV;
    }
    else
    {
        float2 patternBoxSize = float2(0.0);
        patternBoxSize.x = patternBoxRatio * fast::min(boxSize.x / patternBoxRatio, boxSize.y);
        float patternWorldNoFitBoxWidth = patternBoxSize.x;
        if (params.u_fit == 1.0)
        {
            patternBoxSize.x = patternBoxRatio * fast::min(params.u_resolution.x / patternBoxRatio, params.u_resolution.y);
        }
        else
        {
            if (params.u_fit == 2.0)
            {
                patternBoxSize.x = patternBoxRatio * fast::max(params.u_resolution.x / patternBoxRatio, params.u_resolution.y);
            }
        }
        patternBoxSize.y = patternBoxSize.x / patternBoxRatio;
        float2 patternWorldScale = params.u_resolution / patternBoxSize;
        shapeUV += (float2(-params.u_offsetX, params.u_offsetY) / patternWorldScale);
        shapeUV += boxOrigin;
        shapeUV -= (boxOrigin / patternWorldScale);
        shapeUV *= params.u_resolution;
        shapeUV /= float2(params.u_pixelRatio);
        if (params.u_fit > 0.0)
        {
            shapeUV *= (patternWorldNoFitBoxWidth / patternBoxSize.x);
        }
        shapeUV /= float2(params.u_scale);
        shapeUV = graphicRotation * shapeUV;
        shapeUV += (boxOrigin / patternWorldScale);
        shapeUV -= boxOrigin;
        shapeUV += float2(0.5);
    }
    float shape = 0.0;
    if (params.u_shape < 1.5)
    {
        shapeUV *= 0.001;
        float2 param = shapeUV;
        float param_1 = t;
        shape = 0.5 + (0.5 * getSimplexNoise(param, param_1));
        shape = smoothstep(0.3, 0.9, shape);
    }
    else
    {
        if (params.u_shape < 2.5)
        {
            shapeUV *= 0.003;
            for (float i = 1.0; i < 6.0; i += 1.0)
            {
                shapeUV.x += ((0.6 / i) * cos(((i * 2.5) * shapeUV.y) + t));
                shapeUV.y += ((0.6 / i) * cos(((i * 1.5) * shapeUV.x) + t));
            }
            shape = 0.15 / fast::max(0.001, abs(sin((t - shapeUV.y) - shapeUV.x)));
            shape = smoothstep(0.02, 1.0, shape);
        }
        else
        {
            if (params.u_shape < 3.5)
            {
                shapeUV *= 0.05;
                float stripeIdx = floor((2.0 * shapeUV.x) / 6.2831855);
                float param_2 = stripeIdx * 10.0;
                float _845 = hash11(param_2);
                float rand = _845;
                rand = sign(rand - 0.5) * powr(0.1 + abs(rand), 0.4);
                shape = sin(shapeUV.x) * cos(shapeUV.y - ((5.0 * rand) * t));
                shape = powr(abs(shape), 6.0);
            }
            else
            {
                if (params.u_shape < 4.5)
                {
                    shapeUV *= 4.0;
                    float wave = (cos((0.5 * shapeUV.x) - (2.0 * t)) * sin((1.5 * shapeUV.x) + t)) * (0.75 + (0.25 * cos(3.0 * t)));
                    shape = 1.0 - smoothstep(-1.0, 1.0, shapeUV.y + wave);
                }
                else
                {
                    if (params.u_shape < 5.5)
                    {
                        float dist = length(shapeUV);
                        float waves = (sin((powr(dist, 1.7) * 7.0) - (3.0 * t)) * 0.5) + 0.5;
                        shape = waves;
                    }
                    else
                    {
                        if (params.u_shape < 6.5)
                        {
                            float l = length(shapeUV);
                            float angle = (6.0 * precise::atan2(shapeUV.y, shapeUV.x)) + (4.0 * t);
                            float twist = 1.2;
                            float offset = (1.0 / powr(fast::max(l, 0.000001), twist)) + (angle / 6.2831855);
                            float mid = smoothstep(0.0, 1.0, powr(l, twist));
                            shape = mix(0.0, fract(offset), mid);
                        }
                        else
                        {
                            shapeUV *= 2.0;
                            float d = 1.0 - powr(length(shapeUV), 2.0);
                            float3 pos = float3(shapeUV, sqrt(fast::max(0.0, d)));
                            float3 lightPos = fast::normalize(float3(cos(1.5 * t), 0.8, sin(1.25 * t)));
                            shape = 0.5 + (0.5 * dot(lightPos, pos));
                            shape *= step(0.0, d);
                        }
                    }
                }
            }
        }
    }
    int type = int(floor(params.u_type));
    float dithering = 0.0;
    switch (type)
    {
        case 1:
        {
            float2 param_3 = ditheringNoiseUV;
            float _1025 = hash21(param_3);
            dithering = step(_1025, shape);
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
    dithering -= 0.5;
    float res = step(0.5, shape + dithering);
    float3 fgColor = params.u_colorFront.xyz * params.u_colorFront.w;
    float fgOpacity = params.u_colorFront.w;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    float bgOpacity = params.u_colorBack.w;
    float3 color = fgColor * res;
    float opacity = fgOpacity * res;
    color += (bgColor * (1.0 - opacity));
    opacity += (bgOpacity * (1.0 - opacity));
    out.fragColor = float4(color, opacity);
    return out;
}

