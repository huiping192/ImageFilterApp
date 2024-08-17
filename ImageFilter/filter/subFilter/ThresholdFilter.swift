//
//  ThresholdFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/08/18.
//

import Foundation
import MetalKit


class ThresholdFilter: BaseFilter {
  var threshold: Float
  
  init(device: MTLDevice, threshold: Float) {
    self.threshold = threshold
    super.init(device: device, kernelFunctionName: "threshold")
  }
  
  override func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
    commandEncoder.setBytes(&threshold, length: MemoryLayout<Float>.size, index: 0)
  }
}
