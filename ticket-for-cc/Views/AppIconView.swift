//
//  AppIconView.swift
//  ticket-for-cc
//
//  App icon design - airplane ticket style for Claude Code
//

import SwiftUI

struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9), // Deep blue
                    Color(red: 0.4, green: 0.6, blue: 1.0)  // Lighter blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Ticket shape with perforated edges
            TicketShape()
                .fill(Color.white)
                .frame(width: size * 0.85, height: size * 0.5)
                .shadow(color: .black.opacity(0.3), radius: size * 0.02, x: 0, y: size * 0.02)
            
            // Ticket content
            VStack(spacing: 0) {
                // Top section with Claude logo/text
                HStack {
                    // Left side - Claude "C"
                    Text("C")
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.9))
                    
                    Spacer()
                    
                    // Flight info style
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("CLAUDE")
                            .font(.system(size: size * 0.08, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                        Text("CODE")
                            .font(.system(size: size * 0.08, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, size * 0.08)
                .frame(height: size * 0.25)
                
                // Divider with perforations
                HStack(spacing: size * 0.02) {
                    ForEach(0..<8) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: size * 0.015, height: size * 0.015)
                    }
                }
                .frame(height: size * 0.03)
                
                // Bottom section with usage meter
                HStack(spacing: size * 0.04) {
                    // Token meter bars
                    HStack(spacing: size * 0.015) {
                        ForEach(0..<5) { index in
                            RoundedRectangle(cornerRadius: size * 0.01)
                                .fill(index < 3 ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: size * 0.06, height: size * 0.08)
                        }
                    }
                    
                    Spacer()
                    
                    // Ticket number style
                    Text("USAGE")
                        .font(.system(size: size * 0.06, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, size * 0.08)
                .frame(height: size * 0.15)
            }
            .frame(width: size * 0.85, height: size * 0.5)
        }
        .frame(width: size, height: size)
    }
}

// Custom shape for ticket with perforated edges
struct TicketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let perforationSize: CGFloat = rect.height * 0.06
        let numberOfPerforations = Int(rect.height / (perforationSize * 2))
        
        // Start from top left
        path.move(to: CGPoint(x: perforationSize, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.width - perforationSize, y: 0))
        
        // Top right corner perforation
        path.addArc(
            center: CGPoint(x: rect.width - perforationSize, y: 0),
            radius: perforationSize,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        
        // Right edge with perforations
        var currentY = perforationSize
        for i in 0..<numberOfPerforations {
            if i > 0 {
                // Straight segment
                path.addLine(to: CGPoint(x: rect.width, y: currentY))
            }
            
            // Perforation cutout
            if currentY + perforationSize * 2 < rect.height {
                path.addArc(
                    center: CGPoint(x: rect.width, y: currentY + perforationSize),
                    radius: perforationSize * 0.5,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(90),
                    clockwise: true
                )
                currentY += perforationSize * 2
            }
        }
        
        // Bottom right to bottom left
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - perforationSize))
        path.addArc(
            center: CGPoint(x: rect.width - perforationSize, y: rect.height),
            radius: perforationSize,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: perforationSize, y: rect.height))
        path.addArc(
            center: CGPoint(x: perforationSize, y: rect.height),
            radius: perforationSize,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        
        // Left edge with perforations
        currentY = rect.height - perforationSize
        for i in 0..<numberOfPerforations {
            if i > 0 {
                // Straight segment
                path.addLine(to: CGPoint(x: 0, y: currentY))
            }
            
            // Perforation cutout
            if currentY - perforationSize > perforationSize {
                path.addArc(
                    center: CGPoint(x: 0, y: currentY - perforationSize),
                    radius: perforationSize * 0.5,
                    startAngle: .degrees(90),
                    endAngle: .degrees(270),
                    clockwise: true
                )
                currentY -= perforationSize * 2
            }
        }
        
        // Close to top left
        path.addLine(to: CGPoint(x: 0, y: perforationSize))
        path.addArc(
            center: CGPoint(x: perforationSize, y: 0),
            radius: perforationSize,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        
        path.closeSubpath()
        
        return path
    }
}

// Preview for different sizes
struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AppIconView(size: 1024)
                .previewDisplayName("1024x1024")
            
            HStack(spacing: 20) {
                AppIconView(size: 512)
                    .previewDisplayName("512x512")
                
                AppIconView(size: 256)
                    .previewDisplayName("256x256")
                
                AppIconView(size: 128)
                    .previewDisplayName("128x128")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}