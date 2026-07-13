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
    float u_scale;
    float4 u_colors[7];
    float u_colorsCount;
    float4 u_colorBack;
    float u_density;
    float u_angle1;
    float u_angle2;
    float u_length;
    uint u_edges;
    float u_blur;
    float u_fadeIn;
    float u_fadeOut;
    float u_gradient;
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
float2 getPanel(thread const float& angle, thread const float2& uv, thread const float& invLength, thread const float& aa, constant Params& params)
{
    float sinA = sin(angle);
    float cosA = cos(angle);
    float denom = sinA - (uv.y * cosA);
    if (abs(denom) < 0.01)
    {
        return float2(0.0);
    }
    float z = uv.y / denom;
    if ((z <= 0.0) || (z > 0.5))
    {
        return float2(0.0);
    }
    float zRatio = z / 0.5;
    float panelMap = 1.0 - zRatio;
    float x = (uv.x * ((cosA * z) + 1.0)) * invLength;
    float zOffset = zRatio - 0.5;
    float left = (-0.5) + (zOffset * params.u_angle1);
    float right = 0.5 - (zOffset * params.u_angle2);
    float blurX = aa + ((2.0 * panelMap) * params.u_blur);
    float leftEdge1 = left - blurX;
    float leftEdge2 = left + (0.25 * blurX);
    float rightEdge1 = right - (0.25 * blurX);
    float rightEdge2 = right + blurX;
    float panel = smoothstep(leftEdge1, leftEdge2, x) * (1.0 - smoothstep(rightEdge1, rightEdge2, x));
    panel *= mix(0.0, panel, smoothstep(0.0, 0.01 / fast::max(params.u_scale, 0.000001), panelMap));
    float midScreen = abs(sinA);
    if ((params.u_edges != 0u) == true)
    {
        panelMap = mix(0.99, panelMap, panel * fast::clamp(panelMap / (0.15 * (1.0 - powr(midScreen, 0.1))), 0.0, 1.0));
    }
    else
    {
        if (midScreen < 0.07)
        {
            panel *= (midScreen * 15.0);
        }
    }
    return float2(panel, panelMap);
}

static inline __attribute__((always_inline))
float4 blendColor(thread const float4& colorA, thread const float& panelMask, thread const float& panelMap, constant Params& params)
{
    float fade = 1.0 - smoothstep(0.97 - (0.97 * params.u_fadeIn), 1.0, panelMap);
    fade *= smoothstep((-0.2) * (1.0 - params.u_fadeOut), params.u_fadeOut, panelMap);
    float3 blendedRGB = mix(float3(0.0), colorA.xyz, float3(fade));
    float blendedAlpha = mix(0.0, colorA.w, fade);
    return float4(blendedRGB, blendedAlpha) * panelMask;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float2 uv = in.v_objectUV;
    uv *= 1.25;
    float t = 0.02 * params.u_time;
    t = fract(t);
    bool reverseTime = t < 0.5;
    float3 color = float3(0.0);
    float opacity = 0.0;
    float aa = 0.005 / params.u_scale;
    int colorsCount = int(params.u_colorsCount);
    spvUnsafeArray<float4, 7> premultipliedColors;
    for (int i = 0; i < 7; i++)
    {
        if (i >= colorsCount)
        {
            break;
        }
        float4 c = params.u_colors[i];
        float _301 = c.w;
        float4 _302 = c;
        float3 _304 = _302.xyz * _301;
        c.x = _304.x;
        c.y = _304.y;
        c.z = _304.z;
        premultipliedColors[i] = c;
    }
    float invLength = 1.5 / fast::max(params.u_length, 0.001);
    float totalColorWeight = 0.0;
    int panelsNumber = 12;
    float densityNormalizer = 1.0;
    if (colorsCount == 4)
    {
        panelsNumber = 16;
        densityNormalizer = 1.34;
    }
    else
    {
        if (colorsCount == 5)
        {
            panelsNumber = 20;
            densityNormalizer = 1.67;
        }
        else
        {
            if (colorsCount == 7)
            {
                panelsNumber = 14;
                densityNormalizer = 1.17;
            }
        }
    }
    float fPanelsNumber = float(panelsNumber);
    float totalPanelsShape = 0.0;
    float panelGrad = 1.0 - fast::clamp(params.u_gradient, 0.0, 1.0);
    for (int set = 0; set < 2; set++)
    {
        bool _376 = (set == 0) && (!reverseTime);
        bool _384;
        if (!_376)
        {
            _384 = (set == 1) && reverseTime;
        }
        else
        {
            _384 = _376;
        }
        bool isForward = _384;
        if (!isForward)
        {
            continue;
        }
        for (int i_1 = 0; i_1 <= 20; i_1++)
        {
            if (i_1 >= panelsNumber)
            {
                break;
            }
            int idx = (panelsNumber - 1) - i_1;
            float offset = float(idx) / fPanelsNumber;
            if (set == 1)
            {
                offset += 0.5;
            }
            float densityFract = densityNormalizer * fract(t + offset);
            float angleNorm = densityFract / params.u_density;
            if ((densityFract >= 0.5) || (angleNorm >= 0.3))
            {
                continue;
            }
            float smoothDensity = fast::clamp((0.5 - densityFract) / 0.1, 0.0, 1.0) * fast::clamp(densityFract / 0.01, 0.0, 1.0);
            float smoothAngle = fast::clamp((0.3 - angleNorm) / 0.05, 0.0, 1.0);
            if ((smoothDensity * smoothAngle) < 0.001)
            {
                continue;
            }
            if (angleNorm > 0.5)
            {
                angleNorm = 0.5;
            }
            float param = (angleNorm * 6.2831855) + 3.1415927;
            float2 param_1 = uv;
            float param_2 = invLength;
            float param_3 = aa;
            float2 panel = getPanel(param, param_1, param_2, param_3, params);
            if (panel.x <= 0.001)
            {
                continue;
            }
            float panelMask = (panel.x * smoothDensity) * smoothAngle;
            float panelMap = panel.y;
            int colorIdx = spvSMod(idx, colorsCount);
            int nextColorIdx = spvSMod(idx + 1, colorsCount);
            float4 colorA = premultipliedColors[colorIdx];
            float4 colorB = premultipliedColors[nextColorIdx];
            colorA = mix(colorA, colorB, float4(fast::max(0.0, smoothstep(0.0, 0.45, panelMap) - panelGrad)));
            float4 param_4 = colorA;
            float param_5 = panelMask;
            float param_6 = panelMap;
            float4 blended = blendColor(param_4, param_5, param_6, params);
            color = blended.xyz + (color * (1.0 - blended.w));
            opacity = blended.w + (opacity * (1.0 - blended.w));
        }
        for (int i_2 = 0; i_2 <= 20; i_2++)
        {
            if (i_2 >= panelsNumber)
            {
                break;
            }
            int idx_1 = (panelsNumber - 1) - i_2;
            float offset_1 = float(idx_1) / fPanelsNumber;
            if (set == 0)
            {
                offset_1 += 0.5;
            }
            float densityFract_1 = densityNormalizer * fract((-t) + offset_1);
            float angleNorm_1 = (-densityFract_1) / params.u_density;
            if ((densityFract_1 >= 0.5) || (angleNorm_1 < (-0.3)))
            {
                continue;
            }
            float smoothDensity_1 = fast::clamp((0.5 - densityFract_1) / 0.1, 0.0, 1.0) * fast::clamp(densityFract_1 / 0.01, 0.0, 1.0);
            float smoothAngle_1 = fast::clamp((angleNorm_1 + 0.3) / 0.05, 0.0, 1.0);
            if ((smoothDensity_1 * smoothAngle_1) < 0.001)
            {
                continue;
            }
            float param_7 = (angleNorm_1 * 6.2831855) + 3.1415927;
            float2 param_8 = uv;
            float param_9 = invLength;
            float param_10 = aa;
            float2 panel_1 = getPanel(param_7, param_8, param_9, param_10, params);
            float panelMask_1 = (panel_1.x * smoothDensity_1) * smoothAngle_1;
            if (panelMask_1 <= 0.001)
            {
                continue;
            }
            float panelMap_1 = panel_1.y;
            int colorIdx_1 = spvSMod(colorsCount - spvSMod(idx_1, colorsCount), colorsCount);
            if (colorIdx_1 < 0)
            {
                colorIdx_1 += colorsCount;
            }
            int nextColorIdx_1 = spvSMod(colorIdx_1 + 1, colorsCount);
            float4 colorA_1 = premultipliedColors[colorIdx_1];
            float4 colorB_1 = premultipliedColors[nextColorIdx_1];
            colorA_1 = mix(colorA_1, colorB_1, float4(fast::max(0.0, smoothstep(0.0, 0.45, panelMap_1) - panelGrad)));
            float4 param_11 = colorA_1;
            float param_12 = panelMask_1;
            float param_13 = panelMap_1;
            float4 blended_1 = blendColor(param_11, param_12, param_13, params);
            color = blended_1.xyz + (color * (1.0 - blended_1.w));
            opacity = blended_1.w + (opacity * (1.0 - blended_1.w));
        }
    }
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

