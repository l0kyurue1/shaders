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
    float u_time;
    float4 u_colorBack;
    float4 u_colors[5];
    float u_colorsCount;
    float u_roundness;
    float u_thickness;
    float u_marginLeft;
    float u_marginRight;
    float u_marginTop;
    float u_marginBottom;
    float u_aspectRatio;
    float u_softness;
    float u_intensity;
    float u_bloom;
    float u_spotSize;
    float u_spots;
    float u_pulse;
    float u_smoke;
    float u_smokeSize;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_responsiveUV [[user(locn2)]];
    float2 v_responsiveBoxGivenSize [[user(locn3)]];
    float2 v_patternUV [[user(locn4)]];
};

static inline __attribute__((always_inline))
float beat(thread const float& time)
{
    float first = powr(abs(sin(time * 6.2831855)), 10.0);
    float second = powr(abs(sin((time - 0.15) * 6.2831855)), 10.0);
    return fast::clamp(first + (0.6 * second), 0.0, 1.0);
}

static inline __attribute__((always_inline))
float sst(thread const float& edge0, thread const float& edge1, thread const float& x)
{
    return smoothstep(edge0, edge1, x);
}

static inline __attribute__((always_inline))
float roundedBox(thread const float2& uv, thread const float2& halfSize, thread const float& _distance, thread const float& cornerDistance, thread const float& thickness, thread const float& softness)
{
    float borderDistance = abs(_distance);
    float aa = 2.0 * fwidth(_distance);
    float param = fast::min(mix(thickness, -thickness, softness), thickness + aa);
    float param_1 = fast::max(mix(thickness, -thickness, softness), thickness + aa);
    float param_2 = borderDistance;
    float border = 1.0 - sst(param, param_1, param_2);
    float cornerFadeCircles = 0.0;
    float param_3 = 0.0;
    float param_4 = 1.0;
    float param_5 = length((uv + halfSize) / float2(thickness));
    cornerFadeCircles = mix(1.0, cornerFadeCircles, sst(param_3, param_4, param_5));
    float param_6 = 0.0;
    float param_7 = 1.0;
    float param_8 = length((uv - float2(-halfSize.x, halfSize.y)) / float2(thickness));
    cornerFadeCircles = mix(1.0, cornerFadeCircles, sst(param_6, param_7, param_8));
    float param_9 = 0.0;
    float param_10 = 1.0;
    float param_11 = length((uv - float2(halfSize.x, -halfSize.y)) / float2(thickness));
    cornerFadeCircles = mix(1.0, cornerFadeCircles, sst(param_9, param_10, param_11));
    float param_12 = 0.0;
    float param_13 = 1.0;
    float param_14 = length((uv - halfSize) / float2(thickness));
    cornerFadeCircles = mix(1.0, cornerFadeCircles, sst(param_12, param_13, param_14));
    aa = fwidth(cornerDistance);
    float param_15 = 0.0;
    float param_16 = mix(aa, thickness, softness);
    float param_17 = cornerDistance;
    float cornerFade = sst(param_15, param_16, param_17);
    cornerFade *= cornerFadeCircles;
    border += cornerFade;
    return border;
}

static inline __attribute__((always_inline))
float randomG(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).y;
}

static inline __attribute__((always_inline))
float valueNoise(thread const float2& st, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 i = floor(st);
    float2 f = fract(st);
    float2 param = i;
    float a = randomG(param, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_1 = i + float2(1.0, 0.0);
    float b = randomG(param_1, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_2 = i + float2(0.0, 1.0);
    float c = randomG(param_2, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_3 = i + float2(1.0);
    float d = randomG(param_3, u_noiseTexture, u_noiseTextureSmplr);
    float2 u = (f * f) * (float2(3.0) - (f * 2.0));
    float x1 = mix(a, b, u.x);
    float x2 = mix(c, d, u.x);
    return mix(x1, x2, u.y);
}

static inline __attribute__((always_inline))
float2 randomGB(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).yz;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], sampler u_noiseTextureSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float t = 1.2 * (params.u_time + 109.0);
    float2 borderUV = in.v_responsiveUV;
    float param = 0.18 * params.u_time;
    float pulse = params.u_pulse * beat(param);
    float canvasRatio = in.v_responsiveBoxGivenSize.x / in.v_responsiveBoxGivenSize.y;
    float2 halfSize = float2(0.5);
    borderUV.x *= fast::max(canvasRatio, 1.0);
    borderUV.y /= fast::min(canvasRatio, 1.0);
    halfSize.x *= fast::max(canvasRatio, 1.0);
    halfSize.y /= fast::min(canvasRatio, 1.0);
    float mL = params.u_marginLeft;
    float mR = params.u_marginRight;
    float mT = params.u_marginTop;
    float mB = params.u_marginBottom;
    float mX = mL + mR;
    float mY = mT + mB;
    if (params.u_aspectRatio > 0.0)
    {
        float shapeRatio = (canvasRatio * (1.0 - mX)) / fast::max(1.0 - mY, 0.000001);
        float _392;
        if (shapeRatio > 1.0)
        {
            _392 = (1.0 - mX) * (1.0 - (1.0 / fast::max(abs(shapeRatio), 0.000001)));
        }
        else
        {
            _392 = 0.0;
        }
        float freeX = _392;
        float _408;
        if (shapeRatio < 1.0)
        {
            _408 = (1.0 - mY) * (1.0 - shapeRatio);
        }
        else
        {
            _408 = 0.0;
        }
        float freeY = _408;
        mL += (freeX * 0.5);
        mR += (freeX * 0.5);
        mT += (freeY * 0.5);
        mB += (freeY * 0.5);
        mX = mL + mR;
        mY = mT + mB;
    }
    float thickness = (0.5 * params.u_thickness) * fast::min(halfSize.x, halfSize.y);
    halfSize.x *= (1.0 - mX);
    halfSize.y *= (1.0 - mY);
    float2 centerShift = float2(((mL - mR) * fast::max(canvasRatio, 1.0)) * 0.5, ((mB - mT) / fast::min(canvasRatio, 1.0)) * 0.5);
    borderUV -= centerShift;
    halfSize -= float2(mix(thickness, 0.0, params.u_softness));
    float radius = mix(0.0, fast::min(halfSize.x, halfSize.y), params.u_roundness);
    float2 d = (abs(borderUV) - halfSize) + float2(radius);
    float outsideDistance = length(fast::max(d, float2(0.0001))) - radius;
    float insideDistance = fast::min(fast::max(d.x, d.y), 0.0001);
    float cornerDistance = abs(fast::min(fast::max(d.x, d.y) - (0.45 * radius), 0.0));
    float _distance = outsideDistance + insideDistance;
    float borderThickness = mix(thickness, 3.0 * thickness, params.u_softness);
    float2 param_1 = borderUV;
    float2 param_2 = halfSize;
    float param_3 = _distance;
    float param_4 = cornerDistance;
    float param_5 = borderThickness;
    float param_6 = params.u_softness;
    float border = roundedBox(param_1, param_2, param_3, param_4, param_5, param_6);
    border = powr(border, 1.0 + params.u_softness);
    float2 smokeUV = in.v_patternUV * (0.3 * params.u_smokeSize);
    float2 param_7 = (smokeUV * 2.7) + float2(0.5 * t);
    float smoke = fast::clamp(3.0 * valueNoise(param_7, u_noiseTexture, u_noiseTextureSmplr), 0.0, 1.0);
    float2 param_8 = (smokeUV * 3.4) - float2(0.5 * t);
    smoke -= valueNoise(param_8, u_noiseTexture, u_noiseTextureSmplr);
    float smokeThickness = thickness + 0.2;
    smokeThickness = fast::min(0.4, fast::max(smokeThickness, 0.1));
    float2 param_9 = borderUV;
    float2 param_10 = halfSize;
    float param_11 = _distance;
    float param_12 = cornerDistance;
    float param_13 = smokeThickness;
    float param_14 = 1.0;
    smoke *= roundedBox(param_9, param_10, param_11, param_12, param_13, param_14);
    smoke = (30.0 * smoke) * smoke;
    smoke *= mix(0.0, 0.5, powr(params.u_smoke, 2.0));
    smoke *= mix(1.0, pulse, params.u_pulse);
    smoke = fast::clamp(smoke, 0.0, 1.0);
    border += smoke;
    border = fast::clamp(border, 0.0, 1.0);
    float3 blendColor = float3(0.0);
    float blendAlpha = 0.0;
    float3 addColor = float3(0.0);
    float addAlpha = 0.0;
    float bloom = 4.0 * params.u_bloom;
    float intensity = 1.0 + ((1.0 + (4.0 * params.u_softness)) * params.u_intensity);
    float angle = precise::atan2(borderUV.y, borderUV.x) / 6.2831855;
    for (int colorIdx = 0; colorIdx < 5; colorIdx++)
    {
        if (colorIdx >= int(params.u_colorsCount))
        {
            break;
        }
        float colorIdxF = float(colorIdx);
        float3 c = params.u_colors[colorIdx].xyz * params.u_colors[colorIdx].w;
        float a = params.u_colors[colorIdx].w;
        for (int spotIdx = 0; spotIdx < 4; spotIdx++)
        {
            if (spotIdx >= int(params.u_spots))
            {
                break;
            }
            float spotIdxF = float(spotIdx);
            float2 param_15 = float2((spotIdxF * 10.0) + 2.0, 40.0 + colorIdxF);
            float2 randVal = randomGB(param_15, u_noiseTexture, u_noiseTextureSmplr);
            float time = ((0.1 + (0.15 * abs(sin(spotIdxF * (2.0 + colorIdxF)) * cos(spotIdxF * (2.0 + (2.5 * colorIdxF)))))) * t) + (randVal.x * 3.0);
            time *= mix(1.0, -1.0, step(0.5, randVal.y));
            float mask = 0.5 + (0.5 * mix(sin(t + (spotIdxF * (5.0 - (1.5 * colorIdxF)))), cos(t + (spotIdxF * (3.0 + (1.3 * colorIdxF)))), step(mod(colorIdxF, 2.0), 0.5)));
            float p = fast::clamp((2.0 * params.u_pulse) - randVal.x, 0.0, 1.0);
            mask = mix(mask, pulse, p);
            float atg1 = fract(angle + time);
            float spotSize = (0.05 + (0.6 * powr(params.u_spotSize, 2.0))) + (0.05 * randVal.x);
            spotSize = mix(spotSize, 0.1, p);
            float param_16 = 0.5 - spotSize;
            float param_17 = 0.5;
            float param_18 = atg1;
            float param_19 = 0.5;
            float param_20 = 0.5 + spotSize;
            float param_21 = atg1;
            float sector = sst(param_16, param_17, param_18) * (1.0 - sst(param_19, param_20, param_21));
            sector *= mask;
            sector *= border;
            sector *= intensity;
            sector = fast::clamp(sector, 0.0, 1.0);
            float3 srcColor = c * sector;
            float srcAlpha = a * sector;
            blendColor += (srcColor * (1.0 - blendAlpha));
            blendAlpha += ((1.0 - blendAlpha) * srcAlpha);
            addColor += srcColor;
            addAlpha += srcAlpha;
        }
    }
    float3 accumColor = mix(blendColor, addColor, float3(bloom));
    float accumAlpha = mix(blendAlpha, addAlpha, bloom);
    accumAlpha = fast::clamp(accumAlpha, 0.0, 1.0);
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    float3 color = accumColor + (bgColor * (1.0 - accumAlpha));
    float opacity = accumAlpha + ((1.0 - accumAlpha) * params.u_colorBack.w);
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

