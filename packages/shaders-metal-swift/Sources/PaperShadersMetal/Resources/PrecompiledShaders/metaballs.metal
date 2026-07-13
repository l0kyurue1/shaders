#pragma clang diagnostic ignored "-Wmissing-prototypes"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

// Implementation of signed integer mod accurate to SPIR-V specification
template<typename Tx, typename Ty>
inline Tx spvSMod(Tx x, Ty y)
{
    Tx remainder = x - y * (x / y);
    return select(Tx(remainder + y), remainder, remainder == 0 || (x >= 0) == (y >= 0));
}

struct Params
{
    float u_time;
    float4 u_colorBack;
    float4 u_colors[8];
    float u_colorsCount;
    float u_size;
    float u_sizeRange;
    float u_count;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_objectUV [[user(locn0)]];
};

static inline __attribute__((always_inline))
float randomR(thread const float2& p, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float2 uv = (floor(p) / float2(100.0)) + float2(0.5);
    return u_noiseTexture.sample(u_noiseTextureSmplr, fract(uv)).x;
}

static inline __attribute__((always_inline))
float _noise(thread const float& x, texture2d<float> u_noiseTexture, sampler u_noiseTextureSmplr)
{
    float i = floor(x);
    float f = fract(x);
    float u = (f * f) * (3.0 - (2.0 * f));
    float2 p0 = float2(i, 0.0);
    float2 p1 = float2(i + 1.0, 0.0);
    float2 param = p0;
    float2 param_1 = p1;
    return mix(randomR(param, u_noiseTexture, u_noiseTextureSmplr), randomR(param_1, u_noiseTexture, u_noiseTextureSmplr), u);
}

static inline __attribute__((always_inline))
float getBallShape(thread const float2& uv, thread const float2& c, thread const float& p)
{
    float s = 0.5 * length(uv - c);
    s = 1.0 - fast::clamp(s, 0.0, 1.0);
    s = powr(s, p);
    return s;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_noiseTexture [[texture(0)]], sampler u_noiseTextureSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 shape_uv = in.v_objectUV;
    shape_uv += float2(0.5);
    float t = 0.2 * (params.u_time + 2503.4);
    float3 totalColor = float3(0.0);
    float totalShape = 0.0;
    float totalOpacity = 0.0;
    for (int i = 0; i < 20; i++)
    {
        if (i >= int(ceil(params.u_count)))
        {
            break;
        }
        float idxFract = float(i) / 20.0;
        float angle = 6.2831855 * idxFract;
        float speed = 1.0 - (0.2 * idxFract);
        float param = ((angle * 10.0) + float(i)) + (t * speed);
        float noiseX = _noise(param, u_noiseTexture, u_noiseTextureSmplr);
        float param_1 = ((angle * 20.0) + float(i)) - (t * speed);
        float noiseY = _noise(param_1, u_noiseTexture, u_noiseTextureSmplr);
        float2 pos = float2(0.5001) + ((float2(noiseX, noiseY) - float2(0.5)) * 0.9);
        int safeIndex = spvSMod(i, int(params.u_colorsCount + 0.5));
        float4 ballColor = params.u_colors[safeIndex];
        float _212 = ballColor.w;
        float4 _213 = ballColor;
        float3 _215 = _213.xyz * _212;
        ballColor.x = _215.x;
        ballColor.y = _215.y;
        ballColor.z = _215.z;
        float sizeFrac = 1.0;
        if (float(i) > floor(params.u_count - 1.0))
        {
            sizeFrac *= fract(params.u_count);
        }
        float2 param_2 = shape_uv;
        float2 param_3 = pos;
        float param_4 = 45.0 - ((30.0 * params.u_size) * sizeFrac);
        float shape = getBallShape(param_2, param_3, param_4);
        shape *= powr(params.u_size, 0.2);
        shape = smoothstep(0.0, 1.0, shape);
        totalColor += (ballColor.xyz * shape);
        totalShape += shape;
        totalOpacity += (ballColor.w * shape);
    }
    totalColor /= float3(fast::max(totalShape, 0.0001));
    totalOpacity /= fast::max(totalShape, 0.0001);
    float edge_width = fwidth(totalShape);
    float finalShape = smoothstep(0.4, 0.4 + edge_width, totalShape);
    float3 color = totalColor * finalShape;
    float opacity = totalOpacity * finalShape;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

