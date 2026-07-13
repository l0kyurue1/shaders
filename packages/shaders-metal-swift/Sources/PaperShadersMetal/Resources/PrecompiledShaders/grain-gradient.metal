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
    float2 u_resolution;
    float u_pixelRatio;
    float4 u_colorBack;
    float4 u_colors[7];
    float u_colorsCount;
    float u_softness;
    float u_intensity;
    float u_noise;
    float u_shape;
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
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_objectUV [[user(locn0)]];
    float2 v_patternUV [[user(locn4)]];
    float2 v_objectBoxSize [[user(locn1)]];
    float2 v_patternBoxSize [[user(locn5)]];
};

static inline __attribute__((always_inline))
float hash11(thread float& p)
{
    p = fract(p * 0.3183099) + 0.1;
    p *= (p + 19.19);
    return fract(p * p);
}

static inline __attribute__((always_inline))
float randomR(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).x;
}

static inline __attribute__((always_inline))
float valueNoiseR(thread const float2& st, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
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
float2 truchet(thread float2& uv, thread float& idx)
{
    idx = fract((idx - 0.5) * 2.0);
    if (idx > 0.75)
    {
        uv = float2(1.0) - uv;
    }
    else
    {
        if (idx > 0.5)
        {
            uv = float2(1.0 - uv.x, uv.y);
        }
        else
        {
            if (idx > 0.25)
            {
                uv = float2(1.0) - float2(1.0 - uv.x, uv.y);
            }
        }
    }
    return uv;
}

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
    float4 _103 = x12;
    float2 _105 = _103.xy - i1;
    x12.x = _105.x;
    x12.y = _105.y;
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
    float2 _220 = (a0.yz * x12.xz) + (h.yz * x12.yw);
    g.y = _220.x;
    g.z = _220.y;
    return 130.0 * dot(m, g);
}

static inline __attribute__((always_inline))
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

static inline __attribute__((always_inline))
float4 fbmR(thread float2& n0, thread float2& n1, thread float2& n2, thread float2& n3, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float amplitude = 0.2;
    float4 total = float4(0.0);
    for (int i = 0; i < 3; i++)
    {
        float2 param = n0;
        float param_1 = 0.3;
        n0 = rotate(param, param_1);
        float2 param_2 = n1;
        float param_3 = 0.3;
        n1 = rotate(param_2, param_3);
        float2 param_4 = n2;
        float param_5 = 0.3;
        n2 = rotate(param_4, param_5);
        float2 param_6 = n3;
        float param_7 = 0.3;
        n3 = rotate(param_6, param_7);
        float2 param_8 = n0;
        total.x += (valueNoiseR(param_8, u_noiseTexture, u_noiseTextureSmplr) * amplitude);
        float2 param_9 = n1;
        total.y += (valueNoiseR(param_9, u_noiseTexture, u_noiseTextureSmplr) * amplitude);
        float2 param_10 = n2;
        total.z += (valueNoiseR(param_10, u_noiseTexture, u_noiseTextureSmplr) * amplitude);
        float2 param_11 = n3;
        total.z += (valueNoiseR(param_11, u_noiseTexture, u_noiseTextureSmplr) * amplitude);
        n0 *= 1.99;
        n1 *= 1.99;
        n2 *= 1.99;
        n3 *= 1.99;
        amplitude *= 0.6;
    }
    return total;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], sampler u_noiseTextureSmplr [[sampler(0)]])
{
    main0_out out = {};
    float t = 0.1 * (params.u_time + 7.0);
    float2 shape_uv = float2(0.0);
    float2 grain_uv = float2(0.0);
    float r = (params.u_rotation * 3.1415927) / 180.0;
    float cr = cos(r);
    float sr = sin(r);
    float2x2 graphicRotation = float2x2(float2(cr, sr), float2(-sr, cr));
    float2 graphicOffset = float2(-params.u_offsetX, params.u_offsetY);
    if (params.u_shape > 3.5)
    {
        shape_uv = in.v_objectUV;
        grain_uv = shape_uv;
        grain_uv = transpose(graphicRotation) * grain_uv;
        grain_uv *= params.u_scale;
        grain_uv -= graphicOffset;
        grain_uv *= in.v_objectBoxSize;
        grain_uv *= 0.7;
    }
    else
    {
        shape_uv = in.v_patternUV * 0.5;
        grain_uv = in.v_patternUV * 100.0;
        grain_uv = transpose(graphicRotation) * grain_uv;
        grain_uv *= params.u_scale;
        if (params.u_fit > 0.0)
        {
            float2 givenBoxSize = float2(params.u_worldWidth, params.u_worldHeight);
            givenBoxSize = fast::max(givenBoxSize, float2(1.0)) * params.u_pixelRatio;
            float patternBoxRatio = givenBoxSize.x / givenBoxSize.y;
            float _589;
            if (params.u_worldWidth == 0.0)
            {
                _589 = params.u_resolution.x;
            }
            else
            {
                _589 = givenBoxSize.x;
            }
            float _601;
            if (params.u_worldHeight == 0.0)
            {
                _601 = params.u_resolution.y;
            }
            else
            {
                _601 = givenBoxSize.y;
            }
            float2 patternBoxGivenSize = float2(_589, _601);
            patternBoxRatio = patternBoxGivenSize.x / patternBoxGivenSize.y;
            float patternBoxNoFitBoxWidth = patternBoxRatio * fast::min(patternBoxGivenSize.x / patternBoxRatio, patternBoxGivenSize.y);
            grain_uv /= float2(patternBoxNoFitBoxWidth / in.v_patternBoxSize.x);
        }
        float2 patternBoxScale = params.u_resolution / in.v_patternBoxSize;
        grain_uv -= (graphicOffset / patternBoxScale);
        grain_uv *= 1.6;
    }
    float shape = 0.0;
    if (params.u_shape < 1.5)
    {
        float wave = (cos((0.5 * shape_uv.x) - (4.0 * t)) * sin((1.5 * shape_uv.x) + (2.0 * t))) * (0.75 + (0.25 * cos(6.0 * t)));
        shape = 1.0 - smoothstep(-1.0, 1.0, shape_uv.y + wave);
    }
    else
    {
        if (params.u_shape < 2.5)
        {
            float stripeIdx = floor((2.0 * shape_uv.x) / 6.2831855);
            float param = stripeIdx * 100.0;
            float _705 = hash11(param);
            float rand = _705;
            rand = sign(rand - 0.5) * powr(4.0 * abs(rand), 0.3);
            shape = sin(shape_uv.x) * cos(shape_uv.y - ((5.0 * rand) * t));
            shape = powr(abs(shape), 4.0);
        }
        else
        {
            if (params.u_shape < 3.5)
            {
                float2 param_1 = (shape_uv * 0.4) - float2(3.75 * t);
                float n2 = valueNoiseR(param_1, u_noiseTexture, u_noiseTextureSmplr);
                shape_uv.x += 10.0;
                shape_uv *= 0.6;
                float2 param_2 = floor(shape_uv);
                float2 param_3 = fract(shape_uv);
                float param_4 = randomR(param_2, u_noiseTexture, u_noiseTextureSmplr);
                float2 _763 = truchet(param_3, param_4);
                float2 tile = _763;
                float distance1 = length(tile);
                float distance2 = length(tile - float2(1.0));
                n2 -= 0.5;
                n2 *= 0.1;
                shape = smoothstep(0.2, 0.55, distance1 + n2) * (1.0 - smoothstep(0.45, 0.8, distance1 - n2));
                shape += (smoothstep(0.2, 0.55, distance2 + n2) * (1.0 - smoothstep(0.45, 0.8, distance2 - n2)));
                shape = powr(shape, 1.5);
            }
            else
            {
                if (params.u_shape < 4.5)
                {
                    shape_uv *= 0.6;
                    float2 outer = float2(0.5);
                    float2 bl = smoothstep(float2(0.0), outer, shape_uv + float2(0.1 + (0.1 * sin(3.0 * t)), 0.2 - (0.1 * sin(5.25 * t))));
                    float2 tr = smoothstep(float2(0.0), outer, float2(1.0) - shape_uv);
                    shape = 1.0 - (((bl.x * bl.y) * tr.x) * tr.y);
                    shape_uv = -shape_uv;
                    bl = smoothstep(float2(0.0), outer, shape_uv + float2(0.1 + (0.1 * sin(3.0 * t)), 0.2 - (0.1 * cos(5.25 * t))));
                    tr = smoothstep(float2(0.0), outer, float2(1.0) - shape_uv);
                    shape -= (((bl.x * bl.y) * tr.x) * tr.y);
                    shape = 1.0 - smoothstep(0.0, 1.0, shape);
                }
                else
                {
                    if (params.u_shape < 5.5)
                    {
                        shape_uv *= 2.0;
                        float dist = length(shape_uv * 0.4);
                        float waves = (sin((powr(dist, 1.2) * 5.0) - (3.0 * t)) * 0.5) + 0.5;
                        shape = waves;
                    }
                    else
                    {
                        if (params.u_shape < 6.5)
                        {
                            t *= 2.0;
                            float2 f1_traj = float2(1.3 * sin(t), 0.2 + (1.3 * cos((0.6 * t) + 4.0))) * 0.25;
                            float2 f2_traj = float2(1.2 * sin(-t), 1.3 * sin(1.6 * t)) * 0.2;
                            float2 f3_traj = float2(1.7 * cos((-0.6) * t), cos((-1.6) * t)) * 0.25;
                            float2 f4_traj = float2(1.4 * cos(0.8 * t), 1.2 * sin(((-0.6) * t) - 3.0)) * 0.3;
                            shape = 0.5 * powr(1.0 - fast::clamp(0.0, 1.0, length(shape_uv + f1_traj)), 5.0);
                            shape += (0.5 * powr(1.0 - fast::clamp(0.0, 1.0, length(shape_uv + f2_traj)), 5.0));
                            shape += (0.5 * powr(1.0 - fast::clamp(0.0, 1.0, length(shape_uv + f3_traj)), 5.0));
                            shape += (0.5 * powr(1.0 - fast::clamp(0.0, 1.0, length(shape_uv + f4_traj)), 5.0));
                            shape = smoothstep(0.0, 0.9, shape);
                            float edge = smoothstep(0.25, 0.3, shape);
                            shape = mix(0.0, shape, edge);
                        }
                        else
                        {
                            shape_uv *= 2.0;
                            float d = 1.0 - powr(length(shape_uv), 2.0);
                            float3 pos = float3(shape_uv, sqrt(fast::max(d, 0.0)));
                            float3 lightPos = fast::normalize(float3(cos(1.5 * t), 0.8, sin(1.25 * t)));
                            shape = 0.5 + (0.5 * dot(lightPos, pos));
                            shape *= step(0.0, d);
                        }
                    }
                }
            }
        }
    }
    float2 param_5 = grain_uv * 0.5;
    float baseNoise = snoise(param_5);
    float2 param_6 = grain_uv * 0.4;
    float param_7 = 2.0;
    float2 param_8 = (grain_uv * 0.002) + float2(10.0);
    float2 param_9 = grain_uv * 0.003;
    float2 param_10 = grain_uv * 0.001;
    float2 param_11 = rotate(param_6, param_7);
    float4 _1078 = fbmR(param_8, param_9, param_10, param_11, u_noiseTexture, u_noiseTextureSmplr);
    float4 fbmVals = _1078;
    float2 param_12 = grain_uv * 0.2;
    float grainDist = ((baseNoise * snoise(param_12)) - fbmVals.x) - fbmVals.y;
    float rawNoise = ((0.75 * baseNoise) - fbmVals.w) - fbmVals.z;
    float _noise = fast::clamp(rawNoise, 0.0, 1.0);
    shape += (((params.u_intensity * 2.0) / params.u_colorsCount) * (grainDist + 0.5));
    shape += (((params.u_noise * 10.0) / params.u_colorsCount) * _noise);
    float aa = fwidth(shape);
    shape = fast::clamp(shape - (0.5 / params.u_colorsCount), 0.0, 1.0);
    float totalShape = smoothstep(0.0, params.u_softness + (2.0 * aa), fast::clamp(shape * params.u_colorsCount, 0.0, 1.0));
    float mixer = shape * (params.u_colorsCount - 1.0);
    int cntStop = int(params.u_colorsCount) - 1;
    float4 gradient = params.u_colors[0];
    float _1168 = gradient.w;
    float4 _1169 = gradient;
    float3 _1171 = _1169.xyz * _1168;
    gradient.x = _1171.x;
    gradient.y = _1171.y;
    gradient.z = _1171.z;
    for (int i = 1; i < 7; i++)
    {
        if (i > cntStop)
        {
            break;
        }
        float localT = fast::clamp(mixer - float(i - 1), 0.0, 1.0);
        localT = smoothstep((0.5 - (0.5 * params.u_softness)) - aa, (0.5 + (0.5 * params.u_softness)) + aa, localT);
        float4 c = params.u_colors[i];
        float _1218 = c.w;
        float4 _1219 = c;
        float3 _1221 = _1219.xyz * _1218;
        c.x = _1221.x;
        c.y = _1221.y;
        c.z = _1221.z;
        gradient = mix(gradient, c, float4(localT));
    }
    float3 color = gradient.xyz * totalShape;
    float opacity = gradient.w * totalShape;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    out.fragColor = float4(color, opacity);
    return out;
}

