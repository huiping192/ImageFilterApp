//
//  ContentView.swift
//  ImageFilter
//
//  Created by 郭 輝平 on 2024/07/05.
//

import SwiftUI

struct ContentView: View {
    @State private var image: NSImage?
    @State private var brightness: Double = 0
    @State private var isGrayscale: Bool = false
    
    var body: some View {
        NavigationView {
            // 左侧控制面板
            List {
                Button("读取图片") {
                    openImage()
                }
                
                Button("保存图片") {
                    saveImage()
                }
                
                Section(header: Text("调整")) {
                    Slider(value: $brightness, in: -1...1, step: 0.1) {
                        Text("亮度")
                    }
                    
                    Toggle("灰度", isOn: $isGrayscale)
                }
            }
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
            .navigationTitle("控制面板")
            
            // 右侧图片显示
            VStack {
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .brightness(brightness)
                        .grayscale(isGrayscale ? 1 : 0)
                } else {
                    Text("没有选择图片")
                }
            }
            .frame(minWidth: 300, idealWidth: 500)
            .navigationTitle("图片预览")
        }
    }
    
    func openImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["png", "jpg", "jpeg", "tiff"]
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                image = NSImage(contentsOf: url)
            }
        }
    }
    
    func saveImage() {
        guard let image = image else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.title = "Save Image"
        panel.message = "Choose a folder and a name to store the image."
        panel.nameFieldLabel = "Image file name:"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                if let tiffData = image.tiffRepresentation,
                   let bitmapImage = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                    try? pngData.write(to: url)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
