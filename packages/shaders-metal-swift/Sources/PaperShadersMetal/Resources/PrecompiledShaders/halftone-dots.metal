#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Implementation of the GLSL mod() function, which is slightly different than Metal fmod()
template<typename Tx, typename Ty>
inline Tx mod(Tx x, Ty y)
{
    return x - y * floor(x / y);
}

struct Params
{
    float u_rotation;
    float u_time;
    float4 u_colorFront;
    float4 u_colorBack;
    float u_radius;
    float u_contrast;
    float u_imageAspectRatio;
    float u_size;
    float u_grainMixer;
    float u_grainOverlay;
    float u_grainSize;
    float u_grid;
    uint u_originalColors;
    uint u_inverted;
    float u_type;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_imageUV [[user(locn6)]];
};

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
float sigmoid(thread const float& x, thread const float& k)
{
    return 1.0 / (1.0 + exp((-k) * (x - 0.5)));
}

static inline __attribute__((always_inline))
float getLumAtPx(thread const float2& uv, thread const float& contrast, constant Params& params, texture2d<float> u_image, sampler u_imageSmplr)
{
    float4 tex = u_image.sample(u_imageSmplr, uv);
    float param = tex.x;
    float param_1 = contrast;
    float param_2 = tex.y;
    float param_3 = contrast;
    float param_4 = tex.z;
    float param_5 = contrast;
    float3 color = float3(sigmoid(param, param_1), sigmoid(param_2, param_3), sigmoid(param_4, param_5));
    float lum = dot(float3(0.2126, 0.7152, 0.0722), color);
    lum = mix(1.0, lum, tex.w);
    float _487;
    if (params.u_inverted != 0u)
    {
        _487 = 1.0 - lum;
    }
    else
    {
        _487 = lum;
    }
    lum = _487;
    return lum;
}

static inline __attribute__((always_inline))
float getCircle(thread const float2& uv, thread float& r, thread const float& baseR)
{
    r = mix(0.25 * baseR, 0.0, r);
    float d = length(uv - float2(0.5));
    float aa = fwidth(d);
    return 1.0 - smoothstep(r - aa, r + aa, d);
}

static inline __attribute__((always_inline))
float sst(thread const float& edge0, thread const float& edge1, thread const float& x)
{
    return smoothstep(edge0, edge1, x);
}

static inline __attribute__((always_inline))
float getGooeyBall(thread const float2& uv, thread const float& r, thread const float& baseR, constant Params& params)
{
    float d = length(uv - float2(0.5));
    float sizeRadius = 0.3;
    if (params.u_grid == 1.0)
    {
        sizeRadius = 0.42;
    }
    sizeRadius = mix(sizeRadius * baseR, 0.0, r);
    float param = 0.0;
    float param_1 = sizeRadius;
    float param_2 = d;
    d = 1.0 - sst(param, param_1, param_2);
    d = powr(d, 2.0 + baseR);
    return d;
}

static inline __attribute__((always_inline))
float getCell(thread const float2& uv)
{
    float insideX = step(0.0, uv.x) * (1.0 - step(1.0, uv.x));
    float insideY = step(0.0, uv.y) * (1.0 - step(1.0, uv.y));
    return insideX * insideY;
}

static inline __attribute__((always_inline))
float getCircleWithHole(thread const float2& uv, thread float& r, thread const float& baseR)
{
    float2 param = uv;
    float cell = getCell(param);
    r = mix(0.75 * baseR, 0.0, r);
    float rMod = mod(r, 0.5);
    float d = length(uv - float2(0.5));
    float aa = fwidth(d);
    float circle = 1.0 - smoothstep(rMod - aa, rMod + aa, d);
    if (r < 0.5)
    {
        return circle;
    }
    else
    {
        return cell - circle;
    }
}

static inline __attribute__((always_inline))
float lst(thread const float& edge0, thread const float& edge1, thread const float& x)
{
    return fast::clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

static inline __attribute__((always_inline))
float getSoftBall(thread const float2& uv, thread const float& r, thread const float& baseR)
{
    float d = length(uv - float2(0.5));
    float sizeRadius = fast::clamp(baseR, 0.0, 1.0);
    sizeRadius = mix(0.5 * sizeRadius, 0.0, r);
    float param = 0.0;
    float param_1 = sizeRadius;
    float param_2 = d;
    d = 1.0 - lst(param, param_1, param_2);
    float param_3 = 0.0;
    float param_4 = 2.0;
    float param_5 = baseR;
    float powRadius = 1.0 - lst(param_3, param_4, param_5);
    d = powr(d, 4.0 + (3.0 * powRadius));
    return d;
}

static inline __attribute__((always_inline))
float getLumBall(thread float2& p, thread const float2& pad, thread const float2& inCellOffset, thread const float& contrast, thread const float& baseR, thread const float& stepSize, thread float4& ballColor, constant Params& params, texture2d<float> u_image, sampler u_imageSmplr)
{
    p += inCellOffset;
    float2 uv_i = floor(p);
    float2 uv_f = fract(p);
    float2 samplingUV = (((uv_i + float2(0.5)) - inCellOffset) * pad) + float2(0.5);
    float2 param = samplingUV;
    float2 param_1 = pad * stepSize;
    float outOfFrame = getUvFrame(param, param_1);
    float2 param_2 = samplingUV;
    float param_3 = contrast;
    float lum = getLumAtPx(param_2, param_3, params, u_image, u_imageSmplr);
    ballColor = u_image.sample(u_imageSmplr, samplingUV);
    float _535 = ballColor.w;
    float4 _536 = ballColor;
    float3 _538 = _536.xyz * _535;
    ballColor.x = _538.x;
    ballColor.y = _538.y;
    ballColor.z = _538.z;
    ballColor *= outOfFrame;
    float ball = 0.0;
    if (params.u_type == 0.0)
    {
        float2 param_4 = uv_f;
        float param_5 = lum;
        float param_6 = baseR;
        float _561 = getCircle(param_4, param_5, param_6);
        ball = _561;
    }
    else
    {
        if (params.u_type == 1.0)
        {
            float2 param_7 = uv_f;
            float param_8 = lum;
            float param_9 = baseR;
            ball = getGooeyBall(param_7, param_8, param_9, params);
        }
        else
        {
            if (params.u_type == 2.0)
            {
                float2 param_10 = uv_f;
                float param_11 = lum;
                float param_12 = baseR;
                float _587 = getCircleWithHole(param_10, param_11, param_12);
                ball = _587;
            }
            else
            {
                if (params.u_type == 3.0)
                {
                    float2 param_13 = uv_f;
                    float param_14 = lum;
                    float param_15 = baseR;
                    ball = getSoftBall(param_13, param_14, param_15);
                }
            }
        }
    }
    return ball * outOfFrame;
}

static inline __attribute__((always_inline))
float hash21(thread float2& p)
{
    p = fract(p * float2(0.3183099, 0.3678794)) + float2(0.1);
    p += float2(dot(p, p + float2(19.19)));
    return fract(p.x * p.y);
}

static inline __attribute__((always_inline))
float valueNoise(thread const float2& st)
{
    float2 i = floor(st);
    float2 f = fract(st);
    float2 param = i;
    float _141 = hash21(param);
    float a = _141;
    float2 param_1 = i + float2(1.0, 0.0);
    float _147 = hash21(param_1);
    float b = _147;
    float2 param_2 = i + float2(0.0, 1.0);
    float _153 = hash21(param_2);
    float c = _153;
    float2 param_3 = i + float2(1.0);
    float _159 = hash21(param_3);
    float d = _159;
    float2 u = (f * f) * (float2(3.0) - (f * 2.0));
    float x1 = mix(a, b, u.x);
    float x2 = mix(c, d, u.x);
    return mix(x1, x2, u.y);
}

static inline __attribute__((always_inline))
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_image [[texture(0)]], sampler u_imageSmplr [[sampler(0)]])
{
    main0_out out = {};
    float stepMultiplier = 1.0;
    if (params.u_type == 0.0)
    {
        stepMultiplier = 2.0;
    }
    else
    {
        bool _615 = params.u_type == 1.0;
        bool _622;
        if (!_615)
        {
            _622 = params.u_type == 3.0;
        }
        else
        {
            _622 = _615;
        }
        if (_622)
        {
            stepMultiplier = 6.0;
        }
    }
    float cellsPerSide = mix(300.0, 7.0, powr(params.u_size, 0.7));
    cellsPerSide /= stepMultiplier;
    float cellSizeY = 1.0 / cellsPerSide;
    float2 pad = float2(1.0 / params.u_imageAspectRatio, 1.0) * cellSizeY;
    bool _651 = params.u_type == 1.0;
    bool _657;
    if (_651)
    {
        _657 = params.u_grid == 1.0;
    }
    else
    {
        _657 = _651;
    }
    if (_657)
    {
        pad *= 0.7;
    }
    float2 uv = in.v_imageUV;
    uv -= float2(0.5);
    uv /= pad;
    float contrast = mix(0.0, 15.0, powr(params.u_contrast, 1.5));
    float baseRadius = params.u_radius;
    if ((params.u_originalColors != 0u) == true)
    {
        contrast = mix(0.1, 4.0, powr(params.u_contrast, 2.0));
        baseRadius = 2.0 * powr(0.5 * params.u_radius, 0.3);
    }
    float totalShape = 0.0;
    float3 totalColor = float3(0.0);
    float totalOpacity = 0.0;
    float stepSize = 1.0 / stepMultiplier;
    float4 param_6;
    for (float x = -0.5; x < 0.5; x += stepSize)
    {
        for (float y = -0.5; y < 0.5; y += stepSize)
        {
            float2 offset = float2(x, y);
            if (params.u_grid == 1.0)
            {
                float rowIndex = floor((y + 0.5) / stepSize);
                float colIndex = floor((x + 0.5) / stepSize);
                if (stepSize == 1.0)
                {
                    rowIndex = floor((uv.y + y) + 1.0);
                    if (params.u_type == 1.0)
                    {
                        colIndex = floor((uv.x + x) + 1.0);
                    }
                }
                if (params.u_type == 1.0)
                {
                    if (mod(rowIndex + colIndex, 2.0) == 1.0)
                    {
                        continue;
                    }
                }
                else
                {
                    if (mod(rowIndex, 2.0) == 1.0)
                    {
                        offset.x += (0.5 * stepSize);
                    }
                }
            }
            float2 param = uv;
            float2 param_1 = pad;
            float2 param_2 = offset;
            float param_3 = contrast;
            float param_4 = baseRadius;
            float param_5 = stepSize;
            float _806 = getLumBall(param, param_1, param_2, param_3, param_4, param_5, param_6, params, u_image, u_imageSmplr);
            float4 ballColor = param_6;
            float shape = _806;
            totalColor += (ballColor.xyz * shape);
            totalShape += shape;
            totalOpacity += shape;
        }
    }
    totalColor /= float3(fast::max(totalShape, 0.0001));
    totalOpacity /= fast::max(totalShape, 0.0001);
    float finalShape = 0.0;
    if (params.u_type == 0.0)
    {
        finalShape = fast::min(1.0, totalShape);
    }
    else
    {
        if (params.u_type == 1.0)
        {
            float aa = fwidth(totalShape);
            float th = 0.5;
            finalShape = smoothstep(th - aa, th + aa, totalShape);
        }
        else
        {
            if (params.u_type == 2.0)
            {
                finalShape = fast::min(1.0, totalShape);
            }
            else
            {
                if (params.u_type == 3.0)
                {
                    finalShape = totalShape;
                }
            }
        }
    }
    float2 grainSize = float2(1.0, 1.0 / params.u_imageAspectRatio) * mix(2000.0, 200.0, params.u_grainSize);
    float2 grainUV = in.v_imageUV - float2(0.5);
    grainUV *= grainSize;
    grainUV += float2(0.5);
    float2 param_7 = grainUV;
    float grain = valueNoise(param_7);
    grain = smoothstep(0.55, 0.7 + (0.2 * params.u_grainMixer), grain);
    grain *= params.u_grainMixer;
    finalShape = mix(finalShape, 0.0, grain);
    float3 color = float3(0.0);
    float opacity = 0.0;
    if ((params.u_originalColors != 0u) == true)
    {
        color = totalColor * finalShape;
        opacity = totalOpacity * finalShape;
        float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
        color += (bgColor * (1.0 - opacity));
        opacity += (params.u_colorBack.w * (1.0 - opacity));
    }
    else
    {
        float3 fgColor = params.u_colorFront.xyz * params.u_colorFront.w;
        float fgOpacity = params.u_colorFront.w;
        float3 bgColor_1 = params.u_colorBack.xyz * params.u_colorBack.w;
        float bgOpacity = params.u_colorBack.w;
        color = fgColor * finalShape;
        opacity = fgOpacity * finalShape;
        color += (bgColor_1 * (1.0 - opacity));
        opacity += (bgOpacity * (1.0 - opacity));
    }
    float2 param_8 = grainUV;
    float param_9 = 1.0;
    float2 param_10 = rotate(param_8, param_9) + float2(3.0);
    float grainOverlay = valueNoise(param_10);
    float2 param_11 = grainUV;
    float param_12 = 2.0;
    float2 param_13 = rotate(param_11, param_12) + float2(-1.0);
    grainOverlay = mix(grainOverlay, valueNoise(param_13), 0.5);
    grainOverlay = powr(grainOverlay, 1.3);
    float grainOverlayV = (grainOverlay * 2.0) - 1.0;
    float3 grainOverlayColor = float3(step(0.0, grainOverlayV));
    float grainOverlayStrength = params.u_grainOverlay * abs(grainOverlayV);
    grainOverlayStrength = powr(grainOverlayStrength, 0.8);
    color = mix(color, grainOverlayColor, float3(0.5 * grainOverlayStrength));
    opacity += (0.5 * grainOverlayStrength);
    opacity = fast::clamp(opacity, 0.0, 1.0);
    out.fragColor = float4(color, opacity);
    return out;
}

