import SwiftUI
import ARKit
import SceneKit

struct PatternOverlayView: View {
    let patterns: [DetectedPattern]
    let overlayType: OverlayType
    let isVisible: Bool
    let onPatternTap: ((DetectedPattern) -> Void)?
    
    init(patterns: [DetectedPattern], overlayType: OverlayType, isVisible: Bool, onPatternTap: ((DetectedPattern) -> Void)? = nil) {
        self.patterns = patterns
        self.overlayType = overlayType
        self.isVisible = isVisible
        self.onPatternTap = onPatternTap
    }
    
    var body: some View {
        ZStack {
            ForEach(patterns) { pattern in
                PatternOverlay(
                    pattern: pattern,
                    overlayType: overlayType,
                    isVisible: isVisible,
                    onPatternTap: onPatternTap
                )
            }
        }
    }
}

struct PatternOverlay: View {
    let pattern: DetectedPattern
    let overlayType: OverlayType
    let isVisible: Bool
    let onPatternTap: ((DetectedPattern) -> Void)?
    
    @State private var pulseAnimation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simple green outline around the pattern
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.green, lineWidth: 3)
                    .scaleEffect(1.0 + pulseAnimation * 0.02)
                    .opacity(0.8 + pulseAnimation * 0.2)
                
                // Simple pattern label
                VStack {
                    HStack {
                        Spacer()
                        Text(pattern.type.displayName)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.green.opacity(0.8))
                            )
                    }
                    Spacer()
                }
                .padding(8)
            }
            .frame(
                width: pattern.boundingBox.width * geometry.size.width,
                height: pattern.boundingBox.height * geometry.size.height
            )
            .position(
                x: pattern.centerPoint.x * geometry.size.width,
                y: pattern.centerPoint.y * geometry.size.height
            )
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseAnimation = 1.0
                }
            }
            .onTapGesture {
                onPatternTap?(pattern)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        PatternOverlayView(
            patterns: [
                DetectedPattern(
                    type: .fibonacciSpiral,
                    confidence: 0.85,
                    boundingBox: CGRect(x: 100, y: 100, width: 200, height: 200),
                    centerPoint: CGPoint(x: 200, y: 200),
                    detectedAt: Date(),
                    mathematicalProperties: DetectedPattern.MathematicalProperties(
                        phiValue: 1.618,
                        fibonacciNumbers: [1, 1, 2, 3, 5, 8],
                        spiralAngle: 137.5,
                        ratio: 1.618,
                        sequence: nil
                    ),
                    educationalContent: DetectedPattern.EducationalContent(
                        title: "Fibonacci Spiral",
                        description: "A spiral that grows according to the Fibonacci sequence",
                        mathematicalExplanation: "The Fibonacci spiral is created by drawing quarter circles",
                        examples: ["Nautilus shells", "Galaxy arms"],
                        funFacts: ["Also called the golden spiral"]
                    )
                )
            ],
            overlayType: .spiral,
            isVisible: true
        )
    }
}