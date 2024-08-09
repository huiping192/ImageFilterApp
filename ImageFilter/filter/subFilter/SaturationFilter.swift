//
//  SaturationFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/15.
//

import Foundation
import MetalKit

class SaturationFilter: BaseFilter {
  var saturation: Float
  
  init(device: MTLDevice, saturation: Float) {
    self.saturation = saturation
    super.init(device: device, kernelFunctionName: "adjustSaturationRGB")
  }
  
  override func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
    commandEncoder.setBytes(&saturation, length: MemoryLayout<Float>.size, index: 0)
  }
}
