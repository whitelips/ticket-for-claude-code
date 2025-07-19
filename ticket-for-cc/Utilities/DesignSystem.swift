//
//  DesignSystem.swift
//  ticket-for-cc
//
//  Centralized design system for consistent UI across the app
//

import SwiftUI

// MARK: - Design System

struct DesignSystem {
    
    // MARK: - Colors
    
    struct Colors {
        // Primary colors
        static let primary = Color.blue
        static let secondary = Color.purple
        static let accent = Color.blue
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Background colors
        static let cardBackground = Color(NSColor.controlBackgroundColor)
        static let headerBackground = Color(NSColor.controlBackgroundColor)
        static let windowBackground = Color(NSColor.windowBackgroundColor)
        
        // Text colors
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let tertiaryText = Color.secondary.opacity(0.6)
        
        // Interactive colors
        static let activeSession = Color.green
        static let inactiveSession = Color.gray
        static let burnRatePositive = Color.blue
        static let burnRateNegative = Color.red
        
        // Chart colors
        static let chartBlue = Color.blue
        static let chartGreen = Color.green
        static let chartOrange = Color.orange
        static let chartPurple = Color.purple
        static let chartRed = Color.red
        
        // Gradient colors
        static let blueGradient = LinearGradient(
            colors: [Color.blue, Color.blue.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        static let greenGradient = LinearGradient(
            colors: [Color.green, Color.green.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        static let orangeGradient = LinearGradient(
            colors: [Color.orange, Color.orange.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        static let purpleGradient = LinearGradient(
            colors: [Color.purple, Color.purple.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Font sizes
        static let displayFont = Font.largeTitle // 34pt
        static let headlineFont = Font.title // 28pt
        static let title2Font = Font.title2 // 22pt
        static let title3Font = Font.title3 // 20pt
        static let bodyFont = Font.body // 17pt
        static let calloutFont = Font.callout // 16pt
        static let subheadlineFont = Font.subheadline // 15pt
        static let footnoteFont = Font.footnote // 13pt
        static let captionFont = Font.caption // 12pt
        static let caption2Font = Font.caption2 // 11pt
        
        // Font weights
        static let boldWeight = Font.Weight.bold
        static let semiboldWeight = Font.Weight.semibold
        static let mediumWeight = Font.Weight.medium
        static let regularWeight = Font.Weight.regular
        static let lightWeight = Font.Weight.light
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        // Micro spacing
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        
        // Small spacing
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        
        // Medium spacing
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        
        // Large spacing
        static let xxxl: CGFloat = 32
        static let xxxxl: CGFloat = 40
        
        // Card spacing
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 16
        static let cardShadowRadius: CGFloat = 8
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let cardShadow = Shadow(
            color: .black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 2
        )
        
        static let elevatedShadow = Shadow(
            color: .black.opacity(0.15),
            radius: 12,
            x: 0,
            y: 4
        )
        
        static let pressedShadow = Shadow(
            color: .black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 1
        )
    }
}

// MARK: - Shadow Helper

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Spacing.cardCornerRadius)
                    .fill(DesignSystem.Colors.cardBackground)
                    .shadow(
                        color: DesignSystem.Shadows.cardShadow.color,
                        radius: DesignSystem.Shadows.cardShadow.radius,
                        x: DesignSystem.Shadows.cardShadow.x,
                        y: DesignSystem.Shadows.cardShadow.y
                    )
            )
    }
    
    func elevatedCardStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Spacing.cardCornerRadius)
                    .fill(DesignSystem.Colors.cardBackground)
                    .shadow(
                        color: DesignSystem.Shadows.elevatedShadow.color,
                        radius: DesignSystem.Shadows.elevatedShadow.radius,
                        x: DesignSystem.Shadows.elevatedShadow.x,
                        y: DesignSystem.Shadows.elevatedShadow.y
                    )
            )
    }
    
    func headerStyle() -> some View {
        self
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.headerBackground)
    }
    
    func gridSpan(_ span: Int) -> some View {
        self
            .gridCellColumns(span)
    }
}

// MARK: - Enhanced Progress Views

struct EnhancedProgressView: View {
    let progress: Double
    let foregroundColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let height: CGFloat
    
    init(
        progress: Double,
        foregroundColor: Color = DesignSystem.Colors.primary,
        backgroundColor: Color = DesignSystem.Colors.primary.opacity(0.2),
        cornerRadius: CGFloat = DesignSystem.Spacing.sm,
        height: CGFloat = 8
    ) {
        self.progress = progress
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.height = height
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .frame(height: height)
                
                // Progress
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(LinearGradient(
                        colors: [foregroundColor, foregroundColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(
                        width: geometry.size.width * min(max(progress, 0), 1),
                        height: height
                    )
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

struct RingProgressView: View {
    let progress: Double
    let foregroundColor: Color
    let backgroundColor: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    init(
        progress: Double,
        foregroundColor: Color = DesignSystem.Colors.primary,
        backgroundColor: Color = DesignSystem.Colors.primary.opacity(0.2),
        lineWidth: CGFloat = 6,
        size: CGFloat = 40
    ) {
        self.progress = progress
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.lineWidth = lineWidth
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    LinearGradient(
                        colors: [foregroundColor, foregroundColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}