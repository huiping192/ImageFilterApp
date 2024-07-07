//
//  Help.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/07.
//

import Foundation
import MetalKit

func convertTextureToUIImage(_ texture: MTLTexture) -> NSImage? {
  let width = texture.width
  let height = texture.height
  
  // 创建一个位图上下文
  let bytesPerPixel = 4
  let bytesPerRow = width * bytesPerPixel
  let rawPointer = UnsafeMutableRawPointer.allocate(byteCount: height * bytesPerRow, alignment: 8)
  defer {
    rawPointer.deallocate()
  }
  
  // 从纹理中复制数据
  let region = MTLRegionMake2D(0, 0, width, height)
  texture.getBytes(rawPointer, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
  
  // 创建CGImage
  guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
        let context = CGContext(data: rawPointer,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    return nil
  }
  
  guard let cgImage = context.makeImage() else {
    return nil
  }
  
  // 创建UIImage
  return NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
}
