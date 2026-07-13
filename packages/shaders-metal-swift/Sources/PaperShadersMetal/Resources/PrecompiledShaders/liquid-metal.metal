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
    float u_imageAspectRatio;
    float2 u_resolution;
    float u_time;
    float4 u_colorBack;
    float4 u_colorTint;
    float u_softness;
    float u_repetition;
    float u_shiftRed;
    float u_shiftBlue;
    float u_distortion;
    float u_contour;
    float u_angle;
    float u_shape;
    uint u_isImage;
};

struct main0_out
{
    float4 fragColor [[color(0)]];
};

struct main0_in
{
    float2 v_objectUV [[user(locn0)]];
    float2 v_responsiveUV [[user(locn2)]];
    float2 v_responsiveBoxGivenSize [[user(locn3)]];
    float2 v_imageUV [[user(locn6)]];
};

static inline __attribute__((always_inline))
float blurEdge3x3(texture2d<float> tex, sampler texSmplr, thread const float2& uv, thread const float2& dudx, thread const float2& dudy, thread const float& radius, thread const float& centerSample)
{
    float2 texel = float2(1.0) / float2(int2(tex.get_width(), tex.get_height()));
    float2 r = texel * radius;
    float w1 = 1.0;
    float w2 = 2.0;
    float w4 = 4.0;
    float norm = 16.0;
    float sum = w4 * centerSample;
    sum += (w2 * tex.sample(texSmplr, (uv + float2(0.0, -r.y)), gradient2d(dudx, dudy)).x);
    sum += (w2 * tex.sample(texSmplr, (uv + float2(0.0, r.y)), gradient2d(dudx, dudy)).x);
    sum += (w2 * tex.sample(texSmplr, (uv + float2(-r.x, 0.0)), gradient2d(dudx, dudy)).x);
    sum += (w2 * tex.sample(texSmplr, (uv + float2(r.x, 0.0)), gradient2d(dudx, dudy)).x);
    sum += (w1 * tex.sample(texSmplr, (uv + float2(-r.x, -r.y)), gradient2d(dudx, dudy)).x);
    sum += (w1 * tex.sample(texSmplr, (uv + float2(r.x, -r.y)), gradient2d(dudx, dudy)).x);
    sum += (w1 * tex.sample(texSmplr, (uv + float2(-r.x, r.y)), gradient2d(dudx, dudy)).x);
    sum += (w1 * tex.sample(texSmplr, (uv + float2(r.x, r.y)), gradient2d(dudx, dudy)).x);
    return sum / norm;
}

static inline __attribute__((always_inline))
float2 rotate(thread const float2& uv, thread const float& th)
{
    return float2x2(float2(cos(th), sin(th)), float2(-sin(th), cos(th))) * uv;
}

static inline __attribute__((always_inline))
float getImgFrame(thread const float2& uv, thread const float& th)
{
    float frame = 1.0;
    frame *= smoothstep(0.0, th, uv.y);
    frame *= (1.0 - smoothstep(1.0 - th, 1.0, uv.y));
    frame *= smoothstep(0.0, th, uv.x);
    frame *= (1.0 - smoothstep(1.0 - th, 1.0, uv.x));
    return frame;
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
    float4 _126 = x12;
    float2 _128 = _126.xy - i1;
    x12.x = _128.x;
    x12.y = _128.y;
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
    float2 _243 = (a0.yz * x12.xz) + (h.yz * x12.yw);
    g.y = _243.x;
    g.z = _243.y;
    return 130.0 * dot(m, g);
}

static inline __attribute__((always_inline))
float getColorChanges(thread const float& c1, thread const float& c2, thread const float& stripe_p, thread const float3& w, thread const float& blur, thread float& bump, thread const float& tint, constant Params& params)
{
    float ch = mix(c2, c1, smoothstep(0.0, 2.0 * blur, stripe_p));
    float border = w.x;
    ch = mix(ch, c2, smoothstep(border, border + (2.0 * blur), stripe_p));
    if ((params.u_isImage != 0u) == true)
    {
        bump = smoothstep(0.2, 0.8, bump);
    }
    border = w.x + ((0.4 * (1.0 - bump)) * w.y);
    ch = mix(ch, c1, smoothstep(border, border + (2.0 * blur), stripe_p));
    border = w.x + ((0.5 * (1.0 - bump)) * w.y);
    ch = mix(ch, c2, smoothstep(border, border + (2.0 * blur), stripe_p));
    border = w.x + w.y;
    ch = mix(ch, c1, smoothstep(border, border + (2.0 * blur), stripe_p));
    float gradient_t = ((stripe_p - w.x) - w.y) / w.z;
    float gradient = mix(c1, c2, smoothstep(0.0, 1.0, gradient_t));
    ch = mix(ch, gradient, smoothstep(border, border + (0.5 * blur), stripe_p));
    ch = mix(ch, 1.0 - fast::min(1.0, (1.0 - ch) / fast::max(tint, 0.0001)), params.u_colorTint.w);
    return ch;
}

fragment main0_out main0(main0_in in [[stage_in]], constant Params& params [[buffer(0)]], texture2d<float> u_image [[texture(0)]], sampler u_imageSmplr [[sampler(0)]], float4 gl_FragCoord [[position]])
{
    main0_out out = {};
    float t = 0.3 * (params.u_time + 2.8);
    float2 uv = in.v_imageUV;
    float2 dudx = dfdx(in.v_imageUV);
    float2 dudy = dfdy(in.v_imageUV);
    float4 img = u_image.sample(u_imageSmplr, uv, gradient2d(dudx, dudy));
    if ((params.u_isImage != 0u) == false)
    {
        uv = in.v_objectUV + float2(0.5);
        uv.y = 1.0 - uv.y;
    }
    float cycleWidth = params.u_repetition;
    float edge = 0.0;
    float contOffset = 1.0;
    float2 rotatedUV = uv - float2(0.5);
    float angle = (((-params.u_angle) + 70.0) * 3.1415927) / 180.0;
    float cosA = cos(angle);
    float sinA = sin(angle);
    rotatedUV = float2((rotatedUV.x * cosA) - (rotatedUV.y * sinA), (rotatedUV.x * sinA) + (rotatedUV.y * cosA)) + float2(0.5);
    if ((params.u_isImage != 0u) == true)
    {
        float edgeRaw = img.x;
        float2 param = uv;
        float2 param_1 = dudx;
        float2 param_2 = dudy;
        float param_3 = 6.0;
        float param_4 = edgeRaw;
        edge = blurEdge3x3(u_image, u_imageSmplr, param, param_1, param_2, param_3, param_4);
        edge = powr(edge, 1.6);
        edge *= mix(0.0, 1.0, smoothstep(0.0, 0.4, params.u_contour));
    }
    else
    {
        if (params.u_shape < 1.0)
        {
            float2 borderUV = in.v_responsiveUV + float2(0.5);
            float ratio = in.v_responsiveBoxGivenSize.x / in.v_responsiveBoxGivenSize.y;
            float2 mask = fast::min(borderUV, float2(1.0) - borderUV);
            float2 pixel_thickness = fast::min(float2(250.0) / in.v_responsiveBoxGivenSize, float2(0.5));
            float maskX = smoothstep(0.0, pixel_thickness.x, mask.x);
            float maskY = smoothstep(0.0, pixel_thickness.y, mask.y);
            maskX = powr(maskX, 0.25);
            maskY = powr(maskY, 0.25);
            edge = fast::clamp(1.0 - (maskX * maskY), 0.0, 1.0);
            uv = in.v_responsiveUV;
            if (ratio > 1.0)
            {
                uv.y /= ratio;
            }
            else
            {
                uv.x *= ratio;
            }
            uv += float2(0.5);
            uv.y = 1.0 - uv.y;
            cycleWidth *= 2.0;
            contOffset = 1.5;
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
                    r *= (1.0 + (0.05 * sin((3.0 * a) + (2.0 * t))));
                    float f = abs(cos(a * 3.0));
                    edge = smoothstep(f, f + 0.7, r);
                    edge *= edge;
                    uv *= 0.8;
                    cycleWidth *= 1.6;
                }
                else
                {
                    if (params.u_shape < 4.0)
                    {
                        float2 shapeUV_2 = uv - float2(0.5);
                        float2 param_5 = shapeUV_2;
                        float param_6 = 0.7853982;
                        shapeUV_2 = rotate(param_5, param_6);
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
                            for (int i = 0; i < 5; i++)
                            {
                                float fi = float(i);
                                float speed = 1.5 + (0.6666667 * sin(fi * 12.345));
                                float angle_1 = (-fi) * 1.5;
                                float2 dir1 = float2(cos(angle_1), sin(angle_1));
                                float2 dir2 = float2(cos(angle_1 + 1.57), sin(angle_1 + 1.0));
                                float2 traj = ((dir1 * sin((t * speed) + (fi * 1.23))) + (dir2 * cos((t * (speed * 0.7)) + (fi * 2.17)))) * 0.4;
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
        edge = mix(smoothstep(0.9 - (2.0 * fwidth(edge)), 0.9, edge), edge, smoothstep(0.0, 0.4, params.u_contour));
    }
    float opacity = 0.0;
    if ((params.u_isImage != 0u) == true)
    {
        opacity = img.y;
        float2 param_7 = in.v_imageUV;
        float param_8 = 0.0;
        float frame = getImgFrame(param_7, param_8);
        opacity *= frame;
    }
    else
    {
        opacity = 1.0 - smoothstep(0.9 - (2.0 * fwidth(edge)), 0.9, edge);
        if (params.u_shape < 2.0)
        {
            edge = 1.2 * edge;
        }
        else
        {
            if (params.u_shape < 5.0)
            {
                edge = 1.8 * powr(edge, 1.5);
            }
        }
    }
    float diagBLtoTR = rotatedUV.x - rotatedUV.y;
    float diagTLtoBR = rotatedUV.x + rotatedUV.y;
    float3 color = float3(0.0);
    float3 color1 = float3(0.98, 0.98, 1.0);
    float3 color2 = float3(0.1, 0.1, 0.1 + (0.1 * smoothstep(0.7, 1.3, diagTLtoBR)));
    float2 grad_uv = uv - float2(0.5);
    float dist = length(grad_uv + float2(0.0, 0.2 * diagBLtoTR));
    float2 param_9 = grad_uv;
    float param_10 = (0.25 - (0.2 * diagBLtoTR)) * 3.1415927;
    grad_uv = rotate(param_9, param_10);
    float direction = grad_uv.x;
    float bump = powr(1.8 * dist, 1.2);
    bump = 1.0 - bump;
    bump *= powr(uv.y, 0.3);
    float thin_strip_1_ratio = (0.12 / cycleWidth) * (1.0 - (0.4 * bump));
    float thin_strip_2_ratio = (0.07 / cycleWidth) * (1.0 + (0.4 * bump));
    float wide_strip_ratio = (1.0 - thin_strip_1_ratio) - thin_strip_2_ratio;
    float thin_strip_1_width = cycleWidth * thin_strip_1_ratio;
    float thin_strip_2_width = cycleWidth * thin_strip_2_ratio;
    float2 param_11 = uv - float2(t);
    float _noise = snoise(param_11);
    edge += (((1.0 - edge) * params.u_distortion) * _noise);
    direction += diagBLtoTR;
    float contour = 0.0;
    direction -= (((2.0 * _noise) * diagBLtoTR) * (smoothstep(0.0, 1.0, edge) * (1.0 - smoothstep(0.0, 1.0, edge))));
    direction *= mix(1.0, 1.0 - edge, smoothstep(0.5, 1.0, params.u_contour));
    direction -= ((1.7 * edge) * smoothstep(0.5, 1.0, params.u_contour));
    direction += ((0.2 * powr(params.u_contour, 4.0)) * (1.0 - smoothstep(0.0, 1.0, edge)));
    bump *= fast::clamp(powr(uv.y, 0.1), 0.3, 1.0);
    direction *= (0.1 + ((1.1 - edge) * bump));
    direction *= (0.4 + (0.6 * (1.0 - smoothstep(0.5, 1.0, edge))));
    direction += (0.18 * (smoothstep(0.1, 0.2, uv.y) * (1.0 - smoothstep(0.2, 0.4, uv.y))));
    direction += (0.03 * (smoothstep(0.1, 0.2, 1.0 - uv.y) * (1.0 - smoothstep(0.2, 0.4, 1.0 - uv.y))));
    direction *= (0.5 + (0.5 * powr(uv.y, 2.0)));
    direction *= cycleWidth;
    direction -= t;
    float colorDispersion = 1.0 - bump;
    colorDispersion = fast::clamp(colorDispersion, 0.0, 1.0);
    float dispersionRed = colorDispersion;
    dispersionRed += ((0.03 * bump) * _noise);
    dispersionRed += ((5.0 * (smoothstep(-0.1, 0.2, uv.y) * (1.0 - smoothstep(0.1, 0.5, uv.y)))) * (smoothstep(0.4, 0.6, bump) * (1.0 - smoothstep(0.4, 1.0, bump))));
    dispersionRed -= diagBLtoTR;
    float dispersionBlue = colorDispersion;
    dispersionBlue *= 1.3;
    dispersionBlue += ((smoothstep(0.0, 0.4, uv.y) * (1.0 - smoothstep(0.1, 0.8, uv.y))) * (smoothstep(0.4, 0.6, bump) * (1.0 - smoothstep(0.4, 0.8, bump))));
    dispersionBlue -= (0.2 * edge);
    dispersionRed *= (params.u_shiftRed / 20.0);
    dispersionBlue *= (params.u_shiftBlue / 20.0);
    float blur = 0.0;
    float rExtraBlur = 0.0;
    float gExtraBlur = 0.0;
    if ((params.u_isImage != 0u) == true)
    {
        float softness = 0.05 * params.u_softness;
        blur = softness + ((0.5 * smoothstep(1.0, 10.0, params.u_repetition)) * smoothstep(0.0, 1.0, edge));
        float smallCanvasT = 1.0 - smoothstep(100.0, 500.0, fast::min(params.u_resolution.x, params.u_resolution.y));
        blur += (smallCanvasT * smoothstep(0.0, 1.0, edge));
        rExtraBlur = softness * (0.05 + ((0.1 * (params.u_shiftRed / 20.0)) * bump));
        gExtraBlur = (softness * 0.05) / fast::max(0.001, abs(1.0 - diagBLtoTR));
    }
    else
    {
        blur = (params.u_softness / 15.0) + (0.3 * contour);
    }
    float3 w = float3(thin_strip_1_width, thin_strip_2_width, wide_strip_ratio);
    w.y -= (0.02 * smoothstep(0.0, 1.0, edge + bump));
    float stripe_r = fract(direction + dispersionRed);
    float param_12 = color1.x;
    float param_13 = color2.x;
    float param_14 = stripe_r;
    float3 param_15 = w;
    float param_16 = (blur + fwidth(stripe_r)) + rExtraBlur;
    float param_17 = bump;
    float param_18 = params.u_colorTint.x;
    float _1441 = getColorChanges(param_12, param_13, param_14, param_15, param_16, param_17, param_18, params);
    float r_1 = _1441;
    float stripe_g = fract(direction);
    float param_19 = color1.y;
    float param_20 = color2.y;
    float param_21 = stripe_g;
    float3 param_22 = w;
    float param_23 = (blur + fwidth(stripe_g)) + gExtraBlur;
    float param_24 = bump;
    float param_25 = params.u_colorTint.y;
    float _1468 = getColorChanges(param_19, param_20, param_21, param_22, param_23, param_24, param_25, params);
    float g = _1468;
    float stripe_b = fract(direction - dispersionBlue);
    float param_26 = color1.z;
    float param_27 = color2.z;
    float param_28 = stripe_b;
    float3 param_29 = w;
    float param_30 = blur + fwidth(stripe_b);
    float param_31 = bump;
    float param_32 = params.u_colorTint.z;
    float _1495 = getColorChanges(param_26, param_27, param_28, param_29, param_30, param_31, param_32, params);
    float b = _1495;
    color = float3(r_1, g, b);
    color *= opacity;
    float3 bgColor = params.u_colorBack.xyz * params.u_colorBack.w;
    color += (bgColor * (1.0 - opacity));
    opacity += (params.u_colorBack.w * (1.0 - opacity));
    color += float3(0.00390625 * (fract(sin(dot(gl_FragCoord.xy * 0.014, float2(12.9898, 78.233))) * 43758.547) - 0.5));
    out.fragColor = float4(color, opacity);
    return out;
}

