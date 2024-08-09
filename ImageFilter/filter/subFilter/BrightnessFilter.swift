//
//  BrightnessFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/10.
//

import Foundation
import MetalKit

class BrightnessFilter: BaseFilter {
  var brightness: Float
  
  init(device: MTLDevice, brightness: Float) {
    self.brightness = brightness
    super.init(device: device, kernelFunctionName: "adjustBrightness")
  }
  
  override func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
    commandEncoder.setBytes(&brightness, length: MemoryLayout<Float>.size, index: 0)
  }
}
