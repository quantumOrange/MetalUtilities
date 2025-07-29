//
//  Passthrough.metal
//  StopMotionPro
//
//  Created by David Crooks on 15/10/2024.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
} ImageVertex;

typedef struct {
    float value;
} Uniforms;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} VertexInOut;
                   
vertex VertexInOut passthroughVertex(ImageVertex in [[stage_in]]) {
    VertexInOut out;
    
    // Pass through the image vertex's position
    out.position = float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
   
    return out;
}

fragment float4 passthroughFragment(VertexInOut in [[stage_in]],
                                    constant Uniforms &uniforms [[ buffer(0) ]],
                                     texture2d<float, access::sample> texture [[texture(0)]]
                                     ) {
    
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear,
                                   address::clamp_to_zero
                                   );
    
    float4   c =  texture.sample(colorSampler,in.texCoord);
   
    return c;
}
