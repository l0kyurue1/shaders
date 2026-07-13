#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct Params
{
    float2 u_resolution;
    float u_pixelRatio;
    float4 u_colorFront;
    float4 u_colorBack;
    float u_imageAspectRatio;
    float u_contrast;
    float u_roughness;
    float u_fiber;
    float u_fiberSize;
    float u_crumples;
    float u_crumpleSize;
    float u_folds;
    float u_foldCount;
    float u_drops;
    float u_seed;
    float u_fade;
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
float randomG(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(50.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).y;
}

static inline __attribute__((always_inline))
float roughness(thread float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    p *= 0.1;
    float o = 0.0;
    float i = 0.0;
    for (;;)
    {
        float _271 = i;
        float _272 = _271 + 1.0;
        i = _272;
        if (_272 < 4.0)
        {
            float4 w = float4(floor(p), ceil(p));
            float2 f = fract(p);
            float2 param = w.xy;
            float2 param_1 = w.xw;
            float2 param_2 = w.zy;
            float2 param_3 = w.zw;
            o += mix(mix(randomG(param, u_noiseTexture, u_noiseTextureSmplr), randomG(param_1, u_noiseTexture, u_noiseTextureSmplr), f.y), mix(randomG(param_2, u_noiseTexture, u_noiseTextureSmplr), randomG(param_3, u_noiseTexture, u_noiseTextureSmplr), f.y), f.x);
            o += (0.2 / exp(2.0 * abs(sin((0.2 * p.x) + (0.5 * p.y)))));
            p *= 2.1;
            continue;
        }
        else
        {
            break;
        }
    }
    return o / 3.0;
}

static inline __attribute__((always_inline))
float2 randomGB(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(50.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).yz;
}

static inline __attribute__((always_inline))
float crumpledNoise(thread const float2& t, thread const float& pw, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 p = floor(t);
    float wsum = 0.0;
    float cl = 0.0;
    for (int y = -1; y < 2; y++)
    {
        for (int x = -1; x < 2; x++)
        {
            float2 b = float2(float(x), float(y));
            float2 q = b + p;
            float2 q2 = q - (floor(q / float2(8.0)) * 8.0);
            float2 param = q2;
            float2 c = q + randomGB(param, u_noiseTexture, u_noiseTextureSmplr);
            float2 r = c - t;
            float w = powr(smoothstep(0.0, 1.0, 1.0 - abs(r.x)), pw) * powr(smoothstep(0.0, 1.0, 1.0 - abs(r.y)), pw);
            cl += ((0.5 + (0.5 * sin((q2.x + (q2.y * 5.0)) * 8.0))) * w);
            wsum += w;
        }
    }
    float _596;
    if (wsum != 0.0)
    {
        _596 = cl / wsum;
    }
    else
    {
        _596 = 0.0;
    }
    return powr(_596, 0.5) * 2.0;
}

static inline __attribute__((always_inline))
float crumplesShape(thread const float2& uv, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 param = uv * 0.25;
    float param_1 = 16.0;
    float2 param_2 = uv * 0.5;
    float param_3 = 2.0;
    return crumpledNoise(param, param_1, u_noiseTexture, u_noiseTextureSmplr) * crumpledNoise(param_2, param_3, u_noiseTexture, u_noiseTextureSmplr);
}

static inline __attribute__((always_inline))
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

static inline __attribute__((always_inline))
float fiberRandom(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = floor(p) / float2(100.0);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).z;
}

static inline __attribute__((always_inline))
float fiberValueNoise(thread const float2& st, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 i = floor(st);
    float2 f = fract(st);
    float2 param = i;
    float a = fiberRandom(param, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_1 = i + float2(1.0, 0.0);
    float b = fiberRandom(param_1, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_2 = i + float2(0.0, 1.0);
    float c = fiberRandom(param_2, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_3 = i + float2(1.0);
    float d = fiberRandom(param_3, u_noiseTexture, u_noiseTextureSmplr);
    float2 u = (f * f) * (float2(3.0) - (f * 2.0));
    float x1 = mix(a, b, u.x);
    float x2 = mix(c, d, u.x);
    return mix(x1, x2, u.y);
}

static inline __attribute__((always_inline))
float fiberNoiseFbm(thread float2& n, thread const float2& seedOffset, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float total = 0.0;
    float amplitude = 1.0;
    for (int i = 0; i < 4; i++)
    {
        float2 param = n;
        float param_1 = 0.7;
        n = rotate(param, param_1);
        float2 param_2 = n + seedOffset;
        total += (fiberValueNoise(param_2, u_noiseTexture, u_noiseTextureSmplr) * amplitude);
        n *= 2.0;
        amplitude *= 0.6;
    }
    return total;
}

static inline __attribute__((always_inline))
float fiberNoise(thread const float2& uv, thread const float2& seedOffset, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float epsilon = 0.001;
    float2 param = uv + float2(epsilon, 0.0);
    float2 param_1 = seedOffset;
    float _449 = fiberNoiseFbm(param, param_1, u_noiseTexture, u_noiseTextureSmplr);
    float n1 = _449;
    float2 param_2 = uv - float2(epsilon, 0.0);
    float2 param_3 = seedOffset;
    float _458 = fiberNoiseFbm(param_2, param_3, u_noiseTexture, u_noiseTextureSmplr);
    float n2 = _458;
    float2 param_4 = uv + float2(0.0, epsilon);
    float2 param_5 = seedOffset;
    float _467 = fiberNoiseFbm(param_4, param_5, u_noiseTexture, u_noiseTextureSmplr);
    float n3 = _467;
    float2 param_6 = uv - float2(0.0, epsilon);
    float2 param_7 = seedOffset;
    float _476 = fiberNoiseFbm(param_6, param_7, u_noiseTexture, u_noiseTextureSmplr);
    float n4 = _476;
    return length(float2(n1 - n2, n3 - n4)) / (2.0 * epsilon);
}

static inline __attribute__((always_inline))
float2 folds(thread const float2& uv, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr, constant Params& params)
{
    float3 pp = float3(0.0);
    float l = 9.0;
    for (float i = 0.0; i < 15.0; i += 1.0)
    {
        if (i >= params.u_foldCount)
        {
            break;
        }
        float2 param = float2(i, i * params.u_seed);
        float2 rand = randomGB(param, u_noiseTexture, u_noiseTextureSmplr);
        float an = rand.x * 6.2831855;
        float2 p = float2(cos(an), sin(an)) * rand.y;
        float dist = distance(uv, p);
        l = fast::min(l, dist);
        if (l == dist)
        {
            float2 _688 = uv - p;
            pp.x = _688.x;
            pp.y = _688.y;
            pp.z = dist;
        }
    }
    return mix(pp.xy, float2(0.0), float2(powr(pp.z, 0.25)));
}

static inline __attribute__((always_inline))
float drops(thread const float2& uv, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr, constant Params& params)
{
    float2 iDropsUV = floor(uv);
    float2 fDropsUV = fract(uv);
    float dropsMinDist = 1.0;
    for (int j = -1; j <= 1; j++)
    {
        for (int i = -1; i <= 1; i++)
        {
            float2 neighbor = float2(float(i), float(j));
            float2 param = iDropsUV + neighbor;
            float2 offset = randomGB(param, u_noiseTexture, u_noiseTextureSmplr);
            offset = float2(0.5) + (sin(float2(10.0 * params.u_seed) + (offset * 6.2831855)) * 0.5);
            float2 pos = (neighbor + offset) - fDropsUV;
            float dist = length(pos);
            dropsMinDist = fast::min(dropsMinDist, dropsMinDist * dist);
        }
    }
    return 1.0 - smoothstep(0.05, 0.09, powr(dropsMinDist, 0.5));
}

static inline __attribute__((always_inline))
float randomR(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).x;
}

static inline __attribute__((always_inline))
float valueNoise(thread const float2& st, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 i = floor(st);
    float2 f = fract(st);
    float2 param = i;
    float a = randomR(param, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_1 = i + float2(1.0, 0.0);
    float b = randomR(param_1, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_2 = i + float2(0.0, 1.0);
    float c = randomR(param_2, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_3 = i + float2(1.0);
    float d = randomR(param_3, u_noiseTexture, u_noiseTextureSmplr);
    float2 u = (f * f) * (float2(3.0) - (f * 2.0));
    float x1 = mix(a, b, u.x);
    float x2 = mix(c, d, u.x);
    return mix(x1, x2, u.y);
}

static inline __attribute__((always_inline))
float fbm(thread float2& n, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float total = 0.0;
    float amplitude = 0.4;
    for (int i = 0; i < 3; i++)
    {
        float2 param = n;
        total += (valueNoise(param, u_noiseTexture, u_noiseTextureSmplr) * amplitude);
        n *= 1.99;
        amplitude *= 0.65;
    }
    return total;
}

static inline __attribute__((always_inline))
float getUvFrame(thread const float2& uv)
{
    float aax = 2.0 * fwidth(uv.x);
    float aay = 2.0 * fwidth(uv.y);
    float left = smoothstep(0.0, aax, uv.x);
    float right = 1.0 - smoothstep(1.0 - aax, 1.0, uv.x);
    float bottom = smoothstep(0.0, aay, uv.y);
    float top = 1.0 - smoothstep(1.0 - aay, 1.0, uv.y);
    return ((left * right) * bottom) * top;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], texture2d<float> u_image [[texture(1)]], sampler u_noiseTextureSmplr [[sampler(0)]], sampler u_imageSmplr [[sampler(1)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 imageUV = in.v_imageUV;
    float2 patternUV = in.v_imageUV - float2(0.5);
    patternUV = (patternUV * float2(params.u_imageAspectRatio, 1.0)) * 5.0;
    float2 roughnessUv = ((gl_FragCoord.xy - (params.u_resolution * 0.5)) * 1.5) / float2(params.u_pixelRatio);
    float2 param = roughnessUv + float2(1.0, 0.0);
    float _814 = roughness(param, u_noiseTexture, u_noiseTextureSmplr);
    float2 param_1 = roughnessUv - float2(1.0, 0.0);
    float _818 = roughness(param_1, u_noiseTexture, u_noiseTextureSmplr);
    float roughness_1 = _814 - _818;
    float2 crumplesUV = fract(((patternUV * 0.02) / float2(params.u_crumpleSize)) - float2(params.u_seed)) * 32.0;
    float2 param_2 = crumplesUV + float2(0.05, 0.0);
    float2 param_3 = crumplesUV;
    float crumples = params.u_crumples * (crumplesShape(param_2, u_noiseTexture, u_noiseTextureSmplr) - crumplesShape(param_3, u_noiseTexture, u_noiseTextureSmplr));
    float2 fiberUV = patternUV * (2.0 / params.u_fiberSize);
    float2 param_4 = fiberUV;
    float2 param_5 = float2(0.0);
    float fiber = fiberNoise(param_4, param_5, u_noiseTexture, u_noiseTextureSmplr);
    fiber = (0.5 * params.u_fiber) * (fiber - 1.0);
    float2 normal = float2(0.0);
    float2 normalImage = float2(0.0);
    float2 foldsUV = patternUV * 0.12;
    float2 param_6 = foldsUV;
    float param_7 = 4.0 * params.u_seed;
    foldsUV = rotate(param_6, param_7);
    float2 param_8 = foldsUV;
    float2 w = folds(param_8, u_noiseTexture, u_noiseTextureSmplr, params);
    float2 param_9 = foldsUV + float2(0.007 * cos(params.u_seed));
    float param_10 = 0.01 * sin(params.u_seed);
    foldsUV = rotate(param_9, param_10);
    float2 param_11 = foldsUV;
    float2 w2 = folds(param_11, u_noiseTexture, u_noiseTextureSmplr, params);
    float2 param_12 = patternUV * 2.0;
    float drops_1 = params.u_drops * drops(param_12, u_noiseTexture, u_noiseTextureSmplr, params);
    float2 param_13 = (patternUV * 0.17) + float2(10.0 * params.u_seed);
    float _928 = fbm(param_13, u_noiseTexture, u_noiseTextureSmplr);
    float fade = params.u_fade * _928;
    fade = fast::clamp(((8.0 * fade) * fade) * fade, 0.0, 1.0);
    w = mix(w, float2(0.0), float2(fade));
    w2 = mix(w2, float2(0.0), float2(fade));
    crumples = mix(crumples, 0.0, fade);
    drops_1 = mix(drops_1, 0.0, fade);
    fiber *= mix(1.0, 0.5, fade);
    roughness_1 *= mix(1.0, 0.5, fade);
    normal += (fast::max(float2(0.0), w + w2) * ((params.u_folds * fast::min(5.0 * params.u_contrast, 1.0)) * 4.0));
    normalImage += (w * (params.u_folds * 2.0));
    normal += float2(crumples);
    normalImage += float2(1.5 * crumples);
    normal += float2(3.0 * drops_1);
    normalImage += float2(0.2 * drops_1);
    normal += float2((params.u_roughness * 1.5) * roughness_1);
    normal += float2(fiber);
    normalImage += float2((params.u_roughness * 0.75) * roughness_1);
    normalImage += float2(0.2 * fiber);
    float3 lightPos = float3(1.0, 2.0, 1.0);
    float res = dot(fast::normalize(float3(normal, 9.5 - (9.0 * powr(params.u_contrast, 0.1)))), fast::normalize(lightPos));
    float3 fgColor = params.u_colorFront.xyz * params.u_colorFront.w;
    float fgOpacity = params.u_colorFront.w;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    float bgOpacity = params.u_colorBack.w;
    imageUV += (normalImage * 0.02);
    float2 param_14 = imageUV;
    float frame = getUvFrame(param_14);
    float4 image = u_image.sample(u_imageSmplr, imageUV);
    float4 _1088 = image;
    float3 _1091 = _1088.xyz + float3((0.6 * powr(params.u_contrast, 0.4)) * (res - 0.7));
    image.x = _1091.x;
    image.y = _1091.y;
    image.z = _1091.z;
    frame *= image.w;
    float3 color = fgColor * res;
    float opacity = fgOpacity * res;
    color += (bgColor * (1.0 - opacity));
    opacity += (bgOpacity * (1.0 - opacity));
    opacity = mix(opacity, 1.0, frame);
    color -= float3(0.007 * drops_1);
    color = mix(color, image.xyz, float3(frame));
    out.fragColor = float4(color, opacity);
    return out;
}

