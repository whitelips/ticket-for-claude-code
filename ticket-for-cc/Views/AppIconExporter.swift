//
//  AppIconExporter.swift
//  ticket-for-cc
//
//  Utility to export app icon to required sizes
//

import SwiftUI
import AppKit

struct AppIconExporter: View {
    @State private var exportStatus = ""
    
    let iconSizes: [(name: String, size: Int)] = [
        ("16", 16),
        ("16@2x", 32),
        ("32", 32),
        ("32@2x", 64),
        ("128", 128),
        ("128@2x", 256),
        ("256", 256),
        ("256@2x", 512),
        ("512", 512),
        ("512@2x", 1024)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Exporter")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            AppIconView(size: 256)
                .frame(width: 256, height: 256)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            
            Button("Export All Icon Sizes") {
                exportAllSizes()
            }
            .buttonStyle(.borderedProminent)
            
            if !exportStatus.isEmpty {
                Text(exportStatus)
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(40)
        .frame(width: 500, height: 500)
    }
    
    private func exportAllSizes() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = []
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = "AppIcon.appiconset"
        savePanel.prompt = "Export Icons"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                    
                    // Export each size
                    for (name, size) in iconSizes {
                        exportIcon(size: size, name: name, to: url)
                    }
                    
                    // Create Contents.json
                    createContentsJSON(at: url)
                    
                    exportStatus = "✅ Successfully exported all icon sizes!"
                } catch {
                    exportStatus = "❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func exportIcon(size: Int, name: String, to directory: URL) {
        let icon = AppIconView(size: CGFloat(size))
            .frame(width: CGFloat(size), height: CGFloat(size))
            .background(Color.clear)
        
        let renderer = ImageRenderer(content: icon)
        renderer.scale = 1.0
        
        if let nsImage = renderer.nsImage {
            if let tiffData = nsImage.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                
                let fileURL = directory.appendingPathComponent("icon_\(name).png")
                try? pngData.write(to: fileURL)
            }
        }
    }
    
    private func createContentsJSON(at directory: URL) {
        let contents = """
        {
          "images" : [
            {
              "filename" : "icon_16.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "16x16"
            },
            {
              "filename" : "icon_16@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "16x16"
            },
            {
              "filename" : "icon_32.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "32x32"
            },
            {
              "filename" : "icon_32@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "32x32"
            },
            {
              "filename" : "icon_128.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "128x128"
            },
            {
              "filename" : "icon_128@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "128x128"
            },
            {
              "filename" : "icon_256.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "256x256"
            },
            {
              "filename" : "icon_256@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "256x256"
            },
            {
              "filename" : "icon_512.png",
              "idiom" : "mac",
              "scale" : "1x",
              "size" : "512x512"
            },
            {
              "filename" : "icon_512@2x.png",
              "idiom" : "mac",
              "scale" : "2x",
              "size" : "512x512"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        
        let fileURL = directory.appendingPathComponent("Contents.json")
        try? contents.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

// Preview
struct AppIconExporter_Previews: PreviewProvider {
    static var previews: some View {
        AppIconExporter()
    }
}