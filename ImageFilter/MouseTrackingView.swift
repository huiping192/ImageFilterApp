//
//  MouseTrackingView.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/10.
//

import Foundation
import SwiftUI

class MouseTrackingView: NSView {
  var mouseMovedCallback: ((NSPoint) -> Void)?
  
  override func mouseMoved(with event: NSEvent) {
    super.mouseMoved(with: event)
    let location = convert(event.locationInWindow, from: nil)
    mouseMovedCallback?(location)
  }
  
  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    
    for area in trackingAreas {
      removeTrackingArea(area)
    }
    
    let trackingArea = NSTrackingArea(rect: bounds, options: [.mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil)
    addTrackingArea(trackingArea)
  }
}

struct MouseTrackingNSView: NSViewRepresentable {
  @Binding var position: NSPoint
  
  func makeNSView(context: Context) -> MouseTrackingView {
    let view = MouseTrackingView()
    view.mouseMovedCallback = { point in
      DispatchQueue.main.async {
        self.position = point
      }
    }
    return view
  }
  
  func updateNSView(_ nsView: MouseTrackingView, context: Context) {}
}
