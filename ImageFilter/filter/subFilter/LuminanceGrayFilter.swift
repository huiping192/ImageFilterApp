//
//  LuminanceGrayFilter.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/10.
//

import Foundation
import MetalKit

class LuminanceGrayFilter: BaseFilter {
  
  init(device: MTLDevice) {
    super.init(device: device, kernelFunctionName: "makeLuminanceGray")
  }
  
  override func setupCommandEncoder(commandEncoder: MTLComputeCommandEncoder) {
  }
}
