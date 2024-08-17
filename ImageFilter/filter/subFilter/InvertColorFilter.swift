//
//  InvertColorFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/08/18.
//

import Foundation
import MetalKit

class InvertColorFilter: BaseFilter {
  
  init(device: MTLDevice) {
    super.init(device: device, kernelFunctionName: "invertColors")
  }
  
  override func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
  }
}
