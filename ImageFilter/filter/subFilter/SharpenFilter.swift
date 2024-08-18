//
//  SharpenFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/08/18.
//

import Foundation
import MetalKit


class SharpenFilter: BaseFilter {
  var strength: Float
  
  init(device: MTLDevice, strength: Float) {
    self.strength = strength
    super.init(device: device, kernelFunctionName: "sharpen")
  }
  
  override func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
    commandEncoder.setBytes(&strength, length: MemoryLayout<Float>.size, index: 0)
  }
}
