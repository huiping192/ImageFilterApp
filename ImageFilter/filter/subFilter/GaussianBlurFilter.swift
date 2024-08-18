//
//  GaussianBlurFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/08/18.
//

import Foundation
import MetalKit


class GaussianBlurFilter: BaseFilter {
  var radius: Float
  
  init(device: MTLDevice, radius: Float) {
    self.radius = radius
    super.init(device: device, kernelFunctionName: "gaussianBlur")
  }
  
  override func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
    commandEncoder.setBytes(&radius, length: MemoryLayout<Float>.size, index: 0)
  }
}
