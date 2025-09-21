import Foundation
import CoreGraphics
import SwiftUI

// MARK: - Pattern Types
enum PatternType: String, CaseIterable {
    case fibonacciSpiral = "fibonacci_spiral"
    case goldenRatio = "golden_ratio"
    case fibonacciSequence = "fibonacci_sequence"
    case phiGrid = "phi_grid"
    case sunflowerSpiral = "sunflower_spiral"
    case pineconeSpiral = "pinecone_spiral"
    case shellSpiral = "shell_spiral"
    case nautilusSpiral = "nautilus_spiral"
    case leafArrangement = "leaf_arrangement"
    
    var displayName: String {
        switch self {
        case .fibonacciSpiral: return "Fibonacci Spiral"
        case .goldenRatio: return "Golden Ratio"
        case .fibonacciSequence: return "Fibonacci Sequence"
        case .phiGrid: return "Phi Grid"
        case .sunflowerSpiral: return "Sunflower Spiral"
        case .pineconeSpiral: return "Pinecone Spiral"
        case .shellSpiral: return "Shell Spiral"
        case .nautilusSpiral: return "Nautilus Spiral"
        case .leafArrangement: return "Leaf Arrangement"
        }
    }
    
    var confidence: Float {
        switch self {
        case .fibonacciSpiral: return 0.85
        case .goldenRatio: return 0.80
        case .fibonacciSequence: return 0.75
        case .phiGrid: return 0.70
        case .sunflowerSpiral: return 0.90
        case .pineconeSpiral: return 0.88
        case .shellSpiral: return 0.82
        case .nautilusSpiral: return 0.95
        case .leafArrangement: return 0.78
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .fibonacciSpiral: return .blue
        case .goldenRatio: return .yellow
        case .fibonacciSequence: return .purple
        case .phiGrid: return .orange
        case .sunflowerSpiral: return .yellow
        case .pineconeSpiral: return .brown
        case .shellSpiral: return .cyan
        case .nautilusSpiral: return .indigo
        case .leafArrangement: return .green
        }
    }
    
    var glowColor: Color {
        switch self {
        case .fibonacciSpiral: return .blue.opacity(0.6)
        case .goldenRatio: return .yellow.opacity(0.6)
        case .fibonacciSequence: return .purple.opacity(0.6)
        case .phiGrid: return .orange.opacity(0.6)
        case .sunflowerSpiral: return .yellow.opacity(0.6)
        case .pineconeSpiral: return .brown.opacity(0.6)
        case .shellSpiral: return .cyan.opacity(0.6)
        case .nautilusSpiral: return .indigo.opacity(0.6)
        case .leafArrangement: return .green.opacity(0.6)
        }
    }
}

// MARK: - Detected Pattern
struct DetectedPattern: Identifiable {
    let id = UUID()
    let type: PatternType
    let confidence: Float
    let boundingBox: CGRect
    let centerPoint: CGPoint
    let detectedAt: Date
    let mathematicalProperties: MathematicalProperties
    let educationalContent: EducationalContent
    
    struct MathematicalProperties {
        let phiValue: Double?
        let fibonacciNumbers: [Int]?
        let spiralAngle: Double?
        let ratio: Double?
        let sequence: [Double]?
    }
    
    struct EducationalContent {
        let title: String
        let description: String
        let mathematicalExplanation: String
        let examples: [String]
        let funFacts: [String]
    }
}

// MARK: - Pattern Detection Result
struct PatternDetectionResult {
    let patterns: [DetectedPattern]
    let processingTime: TimeInterval
    let frameNumber: Int
    let timestamp: Date
}

// MARK: - AR Overlay Types
enum OverlayType: String, CaseIterable {
    case spiral = "spiral"
    case phiGrid = "phi_grid"
    case fibonacciNumbers = "fibonacci_numbers"
    case goldenRectangle = "golden_rectangle"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .spiral: return "Spiral Overlay"
        case .phiGrid: return "Phi Grid"
        case .fibonacciNumbers: return "Fibonacci Numbers"
        case .goldenRectangle: return "Golden Rectangle"
        case .none: return "No Overlay"
        }
    }
}

// MARK: - Detection Settings
struct DetectionSettings {
    var isSpiralDetectionEnabled: Bool = true
    var isGoldenRatioDetectionEnabled: Bool = true
    var isNautilusSpiralDetectionEnabled: Bool = true // Enable nautilus detection
    var isFibonacciSequenceDetectionEnabled: Bool = false // Disabled for stability
    var isPhiGridDetectionEnabled: Bool = false // Disabled for stability
    var confidenceThreshold: Float = 0.5 // Lower threshold for better detection at all distances
    var maxDetectionsPerFrame: Int = 5 // Allow more detections
    var processingInterval: TimeInterval = 0.1 // 10 FPS processing for better responsiveness
    var overlayType: OverlayType = .spiral
    var showEducationalPopups: Bool = true
    var enableLiDAR: Bool = false // Disabled for stability
    var enableDepthMapping: Bool = false // Disabled for stability
}

// MARK: - Performance Metrics
struct PerformanceMetrics {
    var averageProcessingTime: TimeInterval = 0
    var currentFPS: Double = 0
    var memoryUsage: Double = 0
    var cpuUsage: Double = 0
    var detectionCount: Int = 0
    var lastUpdateTime: Date = Date()
}

