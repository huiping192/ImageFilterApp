//
//  Help.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/07.
//

import Foundation
import MetalKit

func convertTextureToUIImage(_ texture: MTLTexture) -> NSImage? {
  // let ciImage = CIImage(mtlTexture: texture, options: nil) 的会上下反转，需要进行矩阵变换
  let ciImage = CIImage(mtlTexture: texture, options: nil)?.transformed(by: CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: CGFloat(texture.height)))
  let context = CIContext(options: nil)
  guard let cgImage = context.createCGImage(ciImage!, from: ciImage!.extent) else {
    return nil
  }
  return NSImage(cgImage: cgImage, size: NSSize(width: texture.width, height: texture.height))
}
