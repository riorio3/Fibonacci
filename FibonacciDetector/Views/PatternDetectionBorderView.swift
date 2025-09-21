import SwiftUI

struct PatternDetectionBorderView: View {
    let detectedPatterns: [DetectedPattern]
    @State private var borderAnimation: Double = 0
    @State private var colorAnimation: Double = 0
    
    var body: some View {
        ZStack {
            if !detectedPatterns.isEmpty {
                // Multicolor border based on detected patterns
                Rectangle()
                    .stroke(
                        createMulticolorGradient(),
                        lineWidth: 6
                    )
                    .overlay(
                        // Animated glow effect with pattern-specific colors
                        Rectangle()
                            .stroke(
                                createGlowGradient(),
                                lineWidth: 12
                            )
                            .blur(radius: 6)
                            .scaleEffect(1.0 + borderAnimation * 0.15)
                            .opacity(0.7 - borderAnimation * 0.4)
                    )
                    .ignoresSafeArea()
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: borderAnimation
                    )
                    .animation(
                        .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                        value: colorAnimation
                    )
                    .onAppear {
                        borderAnimation = 1.0
                        colorAnimation = 1.0
                    }
                    .onDisappear {
                        borderAnimation = 0.0
                        colorAnimation = 0.0
                    }
                
                // Pattern-specific corner indicators - show different patterns in each corner
                VStack {
                    HStack {
                        if detectedPatterns.count > 0 {
                            PatternCornerIndicator(pattern: detectedPatterns[0])
                        }
                        Spacer()
                        if detectedPatterns.count > 1 {
                            PatternCornerIndicator(pattern: detectedPatterns[1])
                        }
                    }
                    Spacer()
                    HStack {
                        if detectedPatterns.count > 2 {
                            PatternCornerIndicator(pattern: detectedPatterns[2])
                        }
                        Spacer()
                        if detectedPatterns.count > 3 {
                            PatternCornerIndicator(pattern: detectedPatterns[3])
                        }
                    }
                }
                .padding(20)
                
                // Pattern count indicator
                VStack {
                    HStack {
                        Spacer()
                        PatternCountIndicator(count: detectedPatterns.count)
                    }
                    Spacer()
                }
                .padding(20)
            }
        }
    }
    
    private func createMulticolorGradient() -> LinearGradient {
        let colors = detectedPatterns.map { pattern in
            pattern.type.primaryColor
        }
        
        if colors.isEmpty {
            return LinearGradient(
                colors: [.green, .mint, .green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Create a rainbow gradient if multiple patterns
        if colors.count > 1 {
            return LinearGradient(
                colors: colors + [colors.first ?? .green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Single pattern - use its color with variations
            let primaryColor = colors.first ?? .green
            return LinearGradient(
                colors: [primaryColor, primaryColor.opacity(0.7), primaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func createGlowGradient() -> LinearGradient {
        let glowColors = detectedPatterns.map { pattern in
            pattern.type.glowColor
        }
        
        if glowColors.isEmpty {
            return LinearGradient(
                colors: [.green.opacity(0.6), .mint.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        return LinearGradient(
            colors: glowColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct PatternCornerIndicator: View {
    let pattern: DetectedPattern?
    @State private var pulseAnimation: Double = 0
    
    var body: some View {
        ZStack {
            // Outer glow with pattern color
            Circle()
                .fill((pattern?.type.primaryColor ?? .green).opacity(0.3))
                .frame(width: 20, height: 20)
                .scaleEffect(1.0 + pulseAnimation * 0.5)
                .blur(radius: 2)
            
            // Inner circle with pattern color
            Circle()
                .fill(pattern?.type.primaryColor ?? .green)
                .frame(width: 12, height: 12)
                .scaleEffect(1.0 + pulseAnimation * 0.2)
        }
        .animation(
            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
            value: pulseAnimation
        )
        .onAppear {
            pulseAnimation = 1.0
        }
    }
}

struct PatternCountIndicator: View {
    let count: Int
    @State private var scaleAnimation: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 40, height: 40)
                .scaleEffect(1.0 + scaleAnimation * 0.1)
            
            // Count text
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .animation(
            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
            value: scaleAnimation
        )
        .onAppear {
            scaleAnimation = 1.0
        }
    }
}

struct CornerIndicator: View {
    @State private var pulseAnimation: Double = 0
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.green.opacity(0.3))
                .frame(width: 20, height: 20)
                .scaleEffect(1.0 + pulseAnimation * 0.5)
                .blur(radius: 2)
            
            // Inner circle
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .scaleEffect(1.0 + pulseAnimation * 0.2)
        }
        .animation(
            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
            value: pulseAnimation
        )
        .onAppear {
            pulseAnimation = 1.0
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        PatternDetectionBorderView(detectedPatterns: [
            DetectedPattern(
                type: .nautilusSpiral,
                confidence: 0.95,
                boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6),
                centerPoint: CGPoint(x: 0.5, y: 0.5),
                detectedAt: Date(),
                mathematicalProperties: DetectedPattern.MathematicalProperties(
                    phiValue: 1.618,
                    fibonacciNumbers: nil,
                    spiralAngle: 137.5,
                    ratio: 1.618,
                    sequence: nil
                ),
                educationalContent: DetectedPattern.EducationalContent(
                    title: "Nautilus Spiral",
                    description: "A perfect logarithmic spiral",
                    mathematicalExplanation: "Follows the golden ratio",
                    examples: ["Nautilus shells"],
                    funFacts: ["500 million years old"]
                )
            )
        ])
    }
}
