//
//  Shaders.metal
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/07.
//

#include <metal_stdlib>
using namespace metal;

// get image pixel color
kernel void getPixelColor(texture2d<float, access::read> inTexture [[texture(0)]],
                          device float4 *outColor [[buffer(0)]],
                          constant uint2 *position [[buffer(1)]])
{
    *outColor = inTexture.read(*position);
}


// make color image to gray image
kernel void makeGray(texture2d<float, access::read> inTexture [[texture(0)]],
                                texture2d<float, access::write> outTexture [[texture(1)]],
                                uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
        return;
    }
    
    float4 color = inTexture.read(gid);
    float luminance = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    outTexture.write(float4(luminance, luminance, luminance, color.a), gid);
}
