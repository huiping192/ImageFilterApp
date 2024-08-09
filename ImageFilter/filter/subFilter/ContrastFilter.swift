//
//  ContrastFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/15.
//

import Foundation
import MetalKit


class ContrastFilter: BaseFilter {
  var contrast: Float
  
  init(device: MTLDevice, contrast: Float) {
    self.contrast = contrast
    super.init(device: device, kernelFunctionName: "adjustContrast")
  }
  
  override func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
    commandEncoder.setBytes(&contrast, length: MemoryLayout<Float>.size, index: 0)
  }
}
