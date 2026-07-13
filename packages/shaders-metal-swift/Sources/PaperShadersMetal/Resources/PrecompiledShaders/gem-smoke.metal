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
    float u_imageAspectRatio;
    float2 u_resolution;
    float u_time;
    float4 u_colors[6];
    float u_colorsCount;
    float4 u_colorBack;
    float4 u_colorInner;
    float u_innerDistortion;
    float u_outerDistortion;
    float u_outerGlow;
    float u_innerGlow;
    float u_offset;
    float u_angle;
    float u_size;
    float u_shape;
    uint u_isImage;
};

constant spvUnsafeArray<float, 9> _88 = spvUnsafeArray<float, 9>({ 1.0, 8.0, 28.0, 56.0, 70.0, 56.0, 28.0, 8.0, 1.0 });
constant spvUnsafeArray<float, 3> _235 = spvUnsafeArray<float, 3>({ 1.0, 2.0, 1.0 });

struct main0_out
{
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_imageUV [[user(locn6)]];
    float2 v_objectUV [[user(locn0)]];
    float2 v_responsiveUV [[user(locn2)]];
    float2 v_responsiveBoxGivenSize [[user(locn3)]];
};

static inline __attribute__((always_inline))
float2 gaussBlur9x9RG(texture2d<float> tex, sampler texSmplr, thread const float2& uv, thread const float2& dudx, thread const float2& dudy, thread const float& radius)
{
    float2 texel = float2(1.0) / float2(int2(tex.get_width(), tex.get_height()));
    float2 r = texel * fast::max(radius, 0.0);
    float2 sum = float2(0.0);
    for (int j = -4; j <= 4; j++)
    {
        float wy = _88[j + 4];
        for (int i = -4; i <= 4; i++)
        {
            float w = _88[i + 4] * wy;
            float2 off = float2(float(i) * r.x, float(j) * r.y);
            sum += (tex.sample(texSmplr, (uv + off)).xy * w);
        }
    }
    return sum / float2(65536.0);
}

static inline __attribute__((always_inline))
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

static inline __attribute__((always_inline))
float sst(thread const float& a, thread const float& b, thread const float& x)
{
    return smoothstep(a, b, x);
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_image [[texture(0)]], sampler u_imageSmplr [[sampler(0)]])
{
    main0_out out = {};
    float time = params.u_time;
    float roundness = 0.0;
    float imgAlpha = 0.0;
    if ((params.u_isImage != 0u) == true)
    {
        float2 imageUV = in.v_imageUV;
        imageUV -= float2(0.5);
        imageUV *= 0.95;
        imageUV += float2(0.5);
        float2 dudx = dfdx(in.v_imageUV);
        float2 dudy = dfdy(in.v_imageUV);
        float2 param = imageUV;
        float2 param_1 = dudx;
        float2 param_2 = dudy;
        float param_3 = 10.0;
        float2 blurred = gaussBlur9x9RG(u_image, u_imageSmplr, param, param_1, param_2, param_3);
        roundness = 1.0 - blurred.x;
        float2 texelA = float2(1.0) / float2(int2(u_image.get_width(), u_image.get_height()));
        for (int j = -1; j <= 1; j++)
        {
            for (int i = -1; i <= 1; i++)
            {
                imgAlpha += ((_235[i + 1] * _235[j + 1]) * u_image.sample(u_imageSmplr, (imageUV + float2(float(i) * texelA.x, float(j) * texelA.y))).y);
            }
        }
        imgAlpha /= 16.0;
    }
    else
    {
        float2 uv = in.v_objectUV + float2(0.5);
        uv.y = 1.0 - uv.y;
        float edge = 0.0;
        if (params.u_shape < 1.0)
        {
            float2 borderUV = in.v_responsiveUV + float2(0.5);
            float2 mask = fast::min(borderUV, float2(1.0) - borderUV);
            float2 pixel_thickness = fast::min(float2(250.0) / in.v_responsiveBoxGivenSize, float2(0.5));
            float maskX = smoothstep(0.0, pixel_thickness.x, mask.x);
            float maskY = smoothstep(0.0, pixel_thickness.y, mask.y);
            maskX = powr(maskX, 0.25);
            maskY = powr(maskY, 0.25);
            edge = fast::clamp(1.0 - (maskX * maskY), 0.0, 1.0);
        }
        else
        {
            if (params.u_shape < 2.0)
            {
                float2 shapeUV = uv - float2(0.5);
                shapeUV *= 0.67;
                edge = powr(fast::clamp(3.0 * length(shapeUV), 0.0, 1.0), 18.0);
            }
            else
            {
                if (params.u_shape < 3.0)
                {
                    float2 shapeUV_1 = uv - float2(0.5);
                    shapeUV_1 *= 1.68;
                    float r = length(shapeUV_1) * 2.0;
                    float a = precise::atan2(shapeUV_1.y, shapeUV_1.x) + 0.2;
                    r *= (1.0 + (0.05 * sin((3.0 * a) + (2.0 * time))));
                    float f = abs(cos(a * 3.0));
                    edge = smoothstep(f, f + 0.7, r);
                    edge *= edge;
                }
                else
                {
                    if (params.u_shape < 4.0)
                    {
                        float2 shapeUV_2 = uv - float2(0.5);
                        float2 param_4 = shapeUV_2;
                        float param_5 = 0.7853982;
                        shapeUV_2 = rotate(param_4, param_5);
                        shapeUV_2 *= 1.42;
                        shapeUV_2 += float2(0.5);
                        float2 mask_1 = fast::min(shapeUV_2, float2(1.0) - shapeUV_2);
                        float2 pixel_thickness_1 = float2(0.15);
                        float maskX_1 = smoothstep(0.0, pixel_thickness_1.x, mask_1.x);
                        float maskY_1 = smoothstep(0.0, pixel_thickness_1.y, mask_1.y);
                        maskX_1 = powr(maskX_1, 0.25);
                        maskY_1 = powr(maskY_1, 0.25);
                        edge = fast::clamp(1.0 - (maskX_1 * maskY_1), 0.0, 1.0);
                    }
                    else
                    {
                        if (params.u_shape < 5.0)
                        {
                            float2 shapeUV_3 = uv - float2(0.5);
                            shapeUV_3 *= 1.3;
                            edge = 0.0;
                            for (int i_1 = 0; i_1 < 5; i_1++)
                            {
                                float fi = float(i_1);
                                float speed = 1.5 + (0.6666667 * sin(fi * 12.345));
                                float angle = (-fi) * 1.5;
                                float2 dir1 = float2(cos(angle), sin(angle));
                                float2 dir2 = float2(cos(angle + 1.57), sin(angle + 1.0));
                                float2 traj = ((dir1 * sin((time * speed) + (fi * 1.23))) + (dir2 * cos((time * (speed * 0.7)) + (fi * 2.17)))) * 0.4;
                                float d = length(shapeUV_3 + traj);
                                edge += powr(1.0 - fast::clamp(d, 0.0, 1.0), 4.0);
                            }
                            edge = 1.0 - smoothstep(0.65, 0.9, edge);
                            edge = powr(edge, 4.0);
                        }
                    }
                }
            }
        }
        imgAlpha = 1.0 - smoothstep(0.9 - (2.0 * fwidth(edge)), 0.9, edge);
        roundness = 1.0 - edge;
    }
    float2 smokeUV = in.v_objectUV;
    float2 param_6 = smokeUV;
    float param_7 = (params.u_angle * 3.1415927) / 180.0;
    smokeUV = rotate(param_6, param_7);
    smokeUV *= mix(4.0, 1.0, params.u_size);
    float2 innerUV = smokeUV;
    float2 outerUV = smokeUV;
    float param_8 = 0.0;
    float param_9 = 1.0;
    float param_10 = length(innerUV * 0.4);
    innerUV.y += (params.u_innerDistortion * (1.0 - sst(param_8, param_9, param_10)));
    innerUV.y -= (0.4 * params.u_innerDistortion);
    innerUV.y += ((0.7 * params.u_offset) * roundness);
    float param_11 = 0.0;
    float param_12 = 1.0;
    float param_13 = length(outerUV * 0.4);
    outerUV.y += (params.u_outerDistortion * (1.0 - sst(param_11, param_12, param_13)));
    outerUV.y -= (0.4 * params.u_outerDistortion);
    float innerSwirl = params.u_innerDistortion * roundness;
    float outerSwirl = params.u_outerDistortion;
    for (int i_2 = 1; i_2 < 5; i_2++)
    {
        float fi_1 = float(i_2);
        float stretchIn = fast::max(length(dfdx(innerUV)), length(dfdy(innerUV)));
        float dampenIn = 1.0 / (1.0 + (stretchIn * 8.0));
        float sIn = innerSwirl * dampenIn;
        innerUV.x += ((sIn / fi_1) * cos(time + ((fi_1 * 2.9) * innerUV.y)));
        innerUV.y += ((sIn / fi_1) * cos(time + ((fi_1 * 1.5) * innerUV.x)));
        float stretchOut = fast::max(length(dfdx(outerUV)), length(dfdy(outerUV)));
        float dampenOut = 1.0 / (1.0 + (stretchOut * 8.0));
        float sOut = outerSwirl * dampenOut;
        outerUV.x += ((sOut / fi_1) * cos(time + ((fi_1 * 2.9) * outerUV.y)));
        outerUV.y += ((sOut / fi_1) * cos(time + ((fi_1 * 1.5) * outerUV.x)));
    }
    float innerShape = exp((-1.5) * dot(innerUV, innerUV));
    float outerShape = exp((-1.5) * dot(outerUV, outerUV));
    float outerMask = powr(params.u_outerGlow, 2.0) * (1.0 - imgAlpha);
    float innerMask = (0.01 + (0.99 * params.u_innerGlow)) * imgAlpha;
    innerShape *= innerMask;
    outerShape *= outerMask;
    float mixer = (innerShape + outerShape) * params.u_colorsCount;
    float4 gradient = params.u_colors[0];
    float _812 = gradient.w;
    float4 _814 = gradient;
    float3 _816 = _814.xyz * _812;
    gradient.x = _816.x;
    gradient.y = _816.y;
    gradient.z = _816.z;
    float smokeMask = 0.0;
    for (int i_3 = 1; i_3 < 7; i_3++)
    {
        if (i_3 > int(params.u_colorsCount))
        {
            break;
        }
        float param_14 = 0.0;
        float param_15 = 1.0;
        float param_16 = fast::clamp(mixer - float(i_3 - 1), 0.0, 1.0);
        float m = sst(param_14, param_15, param_16);
        if (i_3 == 1)
        {
            smokeMask = m;
        }
        float4 c = params.u_colors[i_3 - 1];
        float _863 = c.w;
        float4 _864 = c;
        float3 _866 = _864.xyz * _863;
        c.x = _866.x;
        c.y = _866.y;
        c.z = _866.z;
        gradient = mix(gradient, c, float4(m));
    }
    float3 color = gradient.xyz * smokeMask;
    float opacity = gradient.w * smokeMask;
    float innerOpacity = params.u_colorInner.w * imgAlpha;
    float3 innerColor = params.u_colorInner.xyz * innerOpacity;
    color += (innerColor * (1.0 - opacity));
    opacity += (innerOpacity * (1.0 - opacity));
    float3 backColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (backColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    out.fragColor = float4(color, opacity);
    return out;
}

