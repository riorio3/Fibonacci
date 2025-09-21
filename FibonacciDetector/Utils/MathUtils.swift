import Foundation
import CoreGraphics
import Accelerate

struct MathUtils {
    
    // MARK: - Constants
    static let goldenRatio: Double = 1.618033988749895
    static let goldenAngle: Double = 137.50776405003785 // 360 / φ²
    static let phi: Double = 1.618033988749895
    static let sqrt5: Double = 2.23606797749979
    
    // MARK: - Fibonacci Sequence
    static func fibonacciSequence(upTo n: Int) -> [Int] {
        guard n > 0 else { return [] }
        guard n > 1 else { return [1] }
        
        var sequence = [1, 1]
        for i in 2..<n {
            sequence.append(sequence[i-1] + sequence[i-2])
        }
        return sequence
    }
    
    static func fibonacciNumber(at index: Int) -> Int {
        guard index >= 0 else { return 0 }
        guard index > 1 else { return 1 }
        
        var a = 1, b = 1
        for _ in 2..<index {
            let temp = a + b
            a = b
            b = temp
        }
        return b
    }
    
    static func binetsFormula(n: Int) -> Double {
        let phi = goldenRatio
        let psi = 1 - phi
        return (pow(phi, Double(n)) - pow(psi, Double(n))) / sqrt5
    }
    
    // MARK: - Golden Ratio Calculations
    static func isGoldenRatio(_ ratio: Double, tolerance: Double = 0.05) -> Bool {
        let difference = min(
            abs(ratio - goldenRatio),
            abs(ratio - (1.0 / goldenRatio))
        )
        return difference < tolerance
    }
    
    static func goldenRatioConfidence(_ ratio: Double) -> Double {
        let difference = min(
            abs(ratio - goldenRatio),
            abs(ratio - (1.0 / goldenRatio))
        )
        return max(0, 1.0 - (difference / 0.1))
    }
    
    static func createGoldenRectangle(width: Double) -> (width: Double, height: Double) {
        return (width: width, height: width / goldenRatio)
    }
    
    static func createGoldenRectangle(height: Double) -> (width: Double, height: Double) {
        return (width: height * goldenRatio, height: height)
    }
    
    // MARK: - Spiral Calculations
    static func logarithmicSpiral(
        center: CGPoint,
        radius: Double,
        turns: Double,
        points: Int = 100
    ) -> [CGPoint] {
        var spiralPoints: [CGPoint] = []
        
        for i in 0..<points {
            let angle = Double(i) * 2 * .pi * turns / Double(points)
            let currentRadius = radius * pow(goldenRatio, angle / (2 * .pi))
            
            let x = center.x + currentRadius * cos(angle)
            let y = center.y + currentRadius * sin(angle)
            
            spiralPoints.append(CGPoint(x: x, y: y))
        }
        
        return spiralPoints
    }
    
    static func fibonacciSpiral(
        center: CGPoint,
        maxRadius: Double,
        turns: Double = 3.0
    ) -> [CGPoint] {
        var spiralPoints: [CGPoint] = []
        let segments = Int(turns * 100)
        
        for i in 0...segments {
            let angle = Double(i) * 2 * .pi / 100
            let currentRadius = maxRadius * (Double(i) / Double(segments))
            
            let x = center.x + currentRadius * cos(angle)
            let y = center.y + currentRadius * sin(angle)
            
            spiralPoints.append(CGPoint(x: x, y: y))
        }
        
        return spiralPoints
    }
    
    static func calculateSpiralScore(_ points: [CGPoint]) -> Double {
        guard points.count > 10 else { return 0.0 }
        
        var totalAngleChange = 0.0
        var radiusChange = 0.0
        var centerX = 0.0, centerY = 0.0
        
        // Calculate center point
        for point in points {
            centerX += Double(point.x)
            centerY += Double(point.y)
        }
        centerX /= Double(points.count)
        centerY /= Double(points.count)
        
        let center = CGPoint(x: centerX, y: centerY)
        
        for i in 2..<points.count {
            let p1 = points[i-2]
            let p2 = points[i-1]
            let p3 = points[i]
            
            // Calculate angle change
            let angle1 = atan2(Double(p2.y - p1.y), Double(p2.x - p1.x))
            let angle2 = atan2(Double(p3.y - p2.y), Double(p3.x - p2.x))
            let angleChange = abs(angle2 - angle1)
            totalAngleChange += angleChange
            
            // Calculate radius change
            let r1 = sqrt(pow(Double(p1.x - center.x), 2) + pow(Double(p1.y - center.y), 2))
            let r2 = sqrt(pow(Double(p2.x - center.x), 2) + pow(Double(p2.y - center.y), 2))
            let r3 = sqrt(pow(Double(p3.x - center.x), 2) + pow(Double(p3.y - center.y), 2))
            radiusChange += abs(r3 - r2) - abs(r2 - r1)
        }
        
        // Normalize scores
        let avgAngleChange = totalAngleChange / Double(points.count - 2)
        let avgRadiusChange = radiusChange / Double(points.count - 2)
        
        // Combine scores
        let spiralScore = min(1.0, (avgAngleChange + avgRadiusChange) / 2.0)
        
        return spiralScore
    }
    
    // MARK: - Pattern Detection Algorithms
    static func detectFibonacciSpiral(
        in points: [CGPoint],
        tolerance: Double = 0.1
    ) -> (isSpiral: Bool, confidence: Double, center: CGPoint, radius: Double) {
        
        guard points.count > 20 else {
            return (false, 0.0, .zero, 0.0)
        }
        
        // Calculate center point
        let center = calculateCenterPoint(points)
        
        // Calculate distances from center
        let distances = points.map { point in
            sqrt(pow(Double(point.x - center.x), 2) + pow(Double(point.y - center.y), 2))
        }
        
        // Check for spiral growth pattern
        let spiralScore = calculateSpiralScore(points)
        let isSpiral = spiralScore > 0.6
        
        // Calculate average radius
        let avgRadius = distances.reduce(0, +) / Double(distances.count)
        
        return (isSpiral, spiralScore, center, avgRadius)
    }
    
    static func detectGoldenRatio(
        in rect: CGRect
    ) -> (isGoldenRatio: Bool, confidence: Double, ratio: Double) {
        
        let width = Double(rect.width)
        let height = Double(rect.height)
        
        guard width > 0 && height > 0 else {
            return (false, 0.0, 0.0)
        }
        
        let ratio = max(width, height) / min(width, height)
        let isGoldenRatio = isGoldenRatio(ratio)
        let confidence = goldenRatioConfidence(ratio)
        
        return (isGoldenRatio, confidence, ratio)
    }
    
    static func detectFibonacciSequence(
        in numbers: [Int]
    ) -> (isFibonacci: Bool, confidence: Double, sequence: [Int]) {
        
        guard numbers.count >= 3 else {
            return (false, 0.0, [])
        }
        
        var matches = 0
        var detectedSequence: [Int] = []
        
        for i in 2..<numbers.count {
            if numbers[i] == numbers[i-1] + numbers[i-2] {
                matches += 1
                if detectedSequence.isEmpty {
                    detectedSequence = Array(numbers[i-2...i])
                } else {
                    detectedSequence.append(numbers[i])
                }
            }
        }
        
        let confidence = Double(matches) / Double(numbers.count - 2)
        let isFibonacci = confidence > 0.7
        
        return (isFibonacci, confidence, detectedSequence)
    }
    
    // MARK: - Geometric Calculations
    static func calculateCenterPoint(_ points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        
        return CGPoint(
            x: sumX / CGFloat(points.count),
            y: sumY / CGFloat(points.count)
        )
    }
    
    static func calculateBoundingBox(_ points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    static func calculateAspectRatio(_ rect: CGRect) -> Double {
        guard rect.width > 0 && rect.height > 0 else { return 0.0 }
        return Double(max(rect.width, rect.height)) / Double(min(rect.width, rect.height))
    }
    
    // MARK: - Statistical Analysis
    static func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        
        return sqrt(variance)
    }
    
    static func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0.0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator != 0 ? numerator / denominator : 0.0
    }
    
    // MARK: - Image Processing Utilities
    static func normalizeCoordinates(_ points: [CGPoint], to size: CGSize) -> [CGPoint] {
        return points.map { point in
            CGPoint(
                x: point.x / size.width,
                y: point.y / size.height
            )
        }
    }
    
    static func denormalizeCoordinates(_ points: [CGPoint], from size: CGSize) -> [CGPoint] {
        return points.map { point in
            CGPoint(
                x: point.x * size.width,
                y: point.y * size.height
            )
        }
    }
    
    // MARK: - Performance Optimizations
    static func downsamplePoints(_ points: [CGPoint], to targetCount: Int) -> [CGPoint] {
        guard points.count > targetCount else { return points }
        
        let step = Double(points.count) / Double(targetCount)
        var downsampled: [CGPoint] = []
        
        for i in 0..<targetCount {
            let index = Int(Double(i) * step)
            downsampled.append(points[index])
        }
        
        return downsampled
    }
    
    static func smoothPoints(_ points: [CGPoint], windowSize: Int = 3) -> [CGPoint] {
        guard points.count > windowSize else { return points }
        
        var smoothed: [CGPoint] = []
        
        for i in 0..<points.count {
            let start = max(0, i - windowSize / 2)
            let end = min(points.count, i + windowSize / 2 + 1)
            let window = Array(points[start..<end])
            
            let avgX = window.map { $0.x }.reduce(0, +) / CGFloat(window.count)
            let avgY = window.map { $0.y }.reduce(0, +) / CGFloat(window.count)
            
            smoothed.append(CGPoint(x: avgX, y: avgY))
        }
        
        return smoothed
    }
    
    // MARK: - Nautilus Spiral Detection
    static func detectNautilusSpiral(
        in points: [CGPoint],
        center: CGPoint
    ) -> (isNautilus: Bool, confidence: Double, chamberCount: Int, growthRate: Double) {
        
        guard points.count > 20 else {
            return (false, 0.0, 0, 0.0)
        }
        
        // Calculate polar coordinates
        let polarPoints = points.map { point in
            let r = sqrt(pow(Double(point.x - center.x), 2) + pow(Double(point.y - center.y), 2))
            let theta = atan2(Double(point.y - center.y), Double(point.x - center.x))
            return (r: r, theta: theta)
        }
        
        // Sort by angle to follow the spiral
        let sortedPolar = polarPoints.sorted { $0.theta < $1.theta }
        
        // Detect chamber-like structures (radius jumps)
        var chambers: [Double] = []
        var currentChamber = sortedPolar[0].r
        var chamberCount = 1
        
        for i in 1..<sortedPolar.count {
            let radiusChange = sortedPolar[i].r - currentChamber
            // If radius increases significantly, it might be a new chamber
            if radiusChange > 0.1 * currentChamber {
                chambers.append(currentChamber)
                currentChamber = sortedPolar[i].r
                chamberCount += 1
            }
        }
        chambers.append(currentChamber)
        
        // Check for logarithmic growth pattern
        let logGrowthScore = calculateLogarithmicGrowthScore(chambers)
        
        // Check for golden ratio proportions between chambers
        let goldenRatioScore = calculateChamberGoldenRatioScore(chambers)
        
        // Combine scores
        let totalScore = (logGrowthScore + goldenRatioScore) / 2.0
        let isNautilus = totalScore > 0.7 && chamberCount >= 3
        
        return (isNautilus, totalScore, chamberCount, logGrowthScore)
    }
    
    private static func calculateLogarithmicGrowthScore(_ chambers: [Double]) -> Double {
        guard chambers.count >= 3 else { return 0.0 }
        
        // Check if chambers follow logarithmic growth
        var growthRates: [Double] = []
        for i in 1..<chambers.count {
            let growthRate = chambers[i] / chambers[i-1]
            growthRates.append(growthRate)
        }
        
        // Check if growth rates are consistent (characteristic of logarithmic spiral)
        let avgGrowthRate = growthRates.reduce(0, +) / Double(growthRates.count)
        let variance = growthRates.map { pow($0 - avgGrowthRate, 2) }.reduce(0, +) / Double(growthRates.count)
        let consistency = 1.0 / (1.0 + variance) // Higher consistency = higher score
        
        // Check if growth rate is close to golden ratio
        let goldenRatioProximity = 1.0 - abs(avgGrowthRate - goldenRatio) / goldenRatio
        
        return (consistency + goldenRatioProximity) / 2.0
    }
    
    private static func calculateChamberGoldenRatioScore(_ chambers: [Double]) -> Double {
        guard chambers.count >= 2 else { return 0.0 }
        
        var goldenRatioMatches = 0
        let totalComparisons = chambers.count - 1
        
        for i in 1..<chambers.count {
            let ratio = chambers[i] / chambers[i-1]
            if isGoldenRatio(ratio, tolerance: 0.15) {
                goldenRatioMatches += 1
            }
        }
        
        return Double(goldenRatioMatches) / Double(totalComparisons)
    }
    
    // MARK: - Advanced Pattern Recognition
    static func detectPhyllotaxisPattern(
        in points: [CGPoint],
        center: CGPoint
    ) -> (isPhyllotaxis: Bool, confidence: Double, angle: Double) {
        
        guard points.count > 5 else {
            return (false, 0.0, 0.0)
        }
        
        // Calculate angles from center
        let angles = points.map { point in
            atan2(Double(point.y - center.y), Double(point.x - center.x))
        }
        
        // Sort angles
        let sortedAngles = angles.sorted()
        
        // Calculate angle differences
        var angleDifferences: [Double] = []
        for i in 1..<sortedAngles.count {
            let diff = sortedAngles[i] - sortedAngles[i-1]
            angleDifferences.append(diff)
        }
        
        // Check if angles follow golden angle pattern
        let goldenAngleRadians = goldenAngle * .pi / 180
        let tolerance = 0.1
        
        var matches = 0
        for diff in angleDifferences {
            if abs(diff - goldenAngleRadians) < tolerance {
                matches += 1
            }
        }
        
        let confidence = Double(matches) / Double(angleDifferences.count)
        let isPhyllotaxis = confidence > 0.6
        
        return (isPhyllotaxis, confidence, goldenAngle)
    }
    
    static func detectLogarithmicSpiral(
        in points: [CGPoint],
        center: CGPoint
    ) -> (isLogarithmic: Bool, confidence: Double, growthRate: Double) {
        
        guard points.count > 10 else {
            return (false, 0.0, 0.0)
        }
        
        // Calculate polar coordinates
        let polarPoints = points.map { point in
            let r = sqrt(pow(Double(point.x - center.x), 2) + pow(Double(point.y - center.y), 2))
            let theta = atan2(Double(point.y - center.y), Double(point.x - center.x))
            return (r: r, theta: theta)
        }
        
        // Check for logarithmic relationship: r = a * e^(b * theta)
        let logR = polarPoints.map { log($0.r) }
        let theta = polarPoints.map { $0.theta }
        
        let correlation = calculateCorrelation(theta, logR)
        let isLogarithmic = abs(correlation) > 0.8
        
        // Estimate growth rate
        let growthRate = correlation * 0.1 // Simplified estimation
        
        return (isLogarithmic, abs(correlation), growthRate)
    }
    
    // MARK: - Utility Functions
    static func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180
    }
    
    static func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }
    
    static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return Swift.max(min, Swift.min(max, value))
    }
    
    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        return a + (b - a) * t
    }
    
    static func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = clamp((x - edge0) / (edge1 - edge0), min: 0, max: 1)
        return t * t * (3 - 2 * t)
    }
    
    // MARK: - Enhanced Pattern Detection Algorithms
    
    /// Analyzes edge detection results for spiral patterns
    static func analyzeEdgesForSpiralPattern(_ edgeObservation: Any) -> Double {
        // Simplified implementation - return placeholder score
        // In a full implementation, this would analyze Vision framework results
        return 0.5 // Placeholder score
    }
    
    /// Analyzes circle detection results for spiral center points
    static func analyzeCirclesForSpiralPattern(_ circleObservation: Any, pixelBuffer: CVPixelBuffer) -> Double {
        // Simplified implementation - return placeholder score
        // In a full implementation, this would analyze Vision framework results
        return 0.5 // Placeholder score
    }
    
    /// Calculates golden ratio score for a given ratio
    static func calculateGoldenRatioScore(_ ratio: Double) -> Double {
        let phi = goldenRatio
        let phiInverse = 1.0 / phi
        
        // Check both orientations
        let score1 = 1.0 - abs(ratio - phi) / phi
        let score2 = 1.0 - abs(ratio - phiInverse) / phiInverse
        
        return max(0.0, max(score1, score2))
    }
    
    /// Analyzes horizon detection for natural golden ratio divisions
    static func analyzeHorizonForGoldenRatio(_ horizonObservation: Any, pixelBuffer: CVPixelBuffer) -> Double {
        // Simplified implementation - return placeholder score
        // In a full implementation, this would analyze Vision framework results
        return 0.5 // Placeholder score
    }
    
    /// Analyzes face detection for facial golden ratio proportions
    static func analyzeFaceForGoldenRatio(_ faceObservation: Any) -> Double {
        // Simplified implementation - return placeholder score
        // In a full implementation, this would analyze Vision framework results
        return 0.5 // Placeholder score
    }
    
    /// Enhanced spiral detection with multiple algorithms
    static func detectAdvancedSpiralPattern(
        in points: [CGPoint],
        center: CGPoint
    ) -> (isSpiral: Bool, confidence: Double, spiralType: String, parameters: [String: Double]) {
        
        guard points.count > 20 else {
            return (false, 0.0, "none", [:])
        }
        
        var scores: [String: Double] = [:]
        var parameters: [String: Double] = [:]
        
        // 1. Basic spiral score
        let basicScore = calculateSpiralScore(points)
        scores["basic"] = basicScore
        
        // 2. Logarithmic spiral detection
        let (isLogarithmic, logConfidence, growthRate) = detectLogarithmicSpiral(in: points, center: center)
        scores["logarithmic"] = logConfidence
        parameters["growthRate"] = growthRate
        
        // 3. Fibonacci spiral detection
        let (isFibonacci, fibConfidence, fibCenter, fibRadius) = detectFibonacciSpiral(in: points, tolerance: 0.15)
        scores["fibonacci"] = fibConfidence
        parameters["fibRadius"] = fibRadius
        
        // 4. Nautilus spiral detection
        let (isNautilus, nautilusConfidence, chamberCount, nautilusGrowthRate) = detectNautilusSpiral(in: points, center: center)
        scores["nautilus"] = nautilusConfidence
        parameters["chamberCount"] = Double(chamberCount)
        parameters["nautilusGrowthRate"] = nautilusGrowthRate
        
        // 5. Phyllotaxis pattern detection
        let (isPhyllotaxis, phylloConfidence, phylloAngle) = detectPhyllotaxisPattern(in: points, center: center)
        scores["phyllotaxis"] = phylloConfidence
        parameters["phylloAngle"] = phylloAngle
        
        // Determine the best match
        let bestMatch = scores.max { $0.value < $1.value }
        let bestScore = bestMatch?.value ?? 0.0
        let bestType = bestMatch?.key ?? "none"
        
        let isSpiral = bestScore > 0.6
        
        return (isSpiral, bestScore, bestType, parameters)
    }
    
    /// Multi-algorithm golden ratio detection
    static func detectAdvancedGoldenRatio(
        in rect: CGRect,
        context: [String: Any] = [:]
    ) -> (isGoldenRatio: Bool, confidence: Double, ratio: Double, context: String) {
        
        let width = Double(rect.width)
        let height = Double(rect.height)
        
        guard width > 0 && height > 0 else {
            return (false, 0.0, 0.0, "invalid_dimensions")
        }
        
        var scores: [String: Double] = [:]
        var ratios: [String: Double] = [:]
        
        // 1. Basic aspect ratio
        let aspectRatio = max(width, height) / min(width, height)
        let inverseRatio = min(width, height) / max(width, height)
        
        scores["aspect"] = max(
            calculateGoldenRatioScore(aspectRatio),
            calculateGoldenRatioScore(inverseRatio)
        )
        ratios["aspect"] = aspectRatio
        
        // 2. Rectangle subdivision analysis
        let subdivisionScore = analyzeRectangleSubdivision(rect)
        scores["subdivision"] = subdivisionScore
        ratios["subdivision"] = aspectRatio
        
        // 3. Context-aware analysis
        if let contextType = context["type"] as? String {
            let contextScore = analyzeContextualGoldenRatio(rect, contextType: contextType)
            scores["context"] = contextScore
            ratios["context"] = aspectRatio
        }
        
        // Determine best match
        let bestMatch = scores.max { $0.value < $1.value }
        let bestScore = bestMatch?.value ?? 0.0
        let bestContext = bestMatch?.key ?? "basic"
        let bestRatio = ratios[bestContext] ?? aspectRatio
        
        let isGoldenRatio = bestScore > 0.7
        
        return (isGoldenRatio, bestScore, bestRatio, bestContext)
    }
    
    /// Analyzes rectangle subdivision for golden ratio patterns
    private static func analyzeRectangleSubdivision(_ rect: CGRect) -> Double {
        let width = Double(rect.width)
        let height = Double(rect.height)
        
        // Check if rectangle can be subdivided into golden ratio rectangles
        let phi = goldenRatio
        
        // Test horizontal subdivision
        let horizontalSubdivision = width / phi
        let horizontalScore = calculateGoldenRatioScore(horizontalSubdivision / height)
        
        // Test vertical subdivision
        let verticalSubdivision = height / phi
        let verticalScore = calculateGoldenRatioScore(verticalSubdivision / width)
        
        return max(horizontalScore, verticalScore)
    }
    
    /// Context-aware golden ratio analysis
    private static func analyzeContextualGoldenRatio(_ rect: CGRect, contextType: String) -> Double {
        let aspectRatio = Double(rect.width) / Double(rect.height)
        
        switch contextType.lowercased() {
        case "face":
            // Facial golden ratio proportions
            return calculateFacialGoldenRatioScore(aspectRatio)
        case "architecture":
            // Architectural golden ratio proportions
            return calculateArchitecturalGoldenRatioScore(aspectRatio)
        case "nature":
            // Natural golden ratio proportions
            return calculateNaturalGoldenRatioScore(aspectRatio)
        default:
            return calculateGoldenRatioScore(aspectRatio)
        }
    }
    
    private static func calculateFacialGoldenRatioScore(_ ratio: Double) -> Double {
        // Facial proportions often follow different golden ratio patterns
        let facialPhi = 1.618
        let facialPhiInverse = 1.0 / facialPhi
        
        let score1 = 1.0 - abs(ratio - facialPhi) / facialPhi
        let score2 = 1.0 - abs(ratio - facialPhiInverse) / facialPhiInverse
        
        return max(0.0, max(score1, score2))
    }
    
    private static func calculateArchitecturalGoldenRatioScore(_ ratio: Double) -> Double {
        // Architectural proportions often use golden ratio
        return calculateGoldenRatioScore(ratio)
    }
    
    private static func calculateNaturalGoldenRatioScore(_ ratio: Double) -> Double {
        // Natural proportions may have more variation
        let tolerance = 0.2
        let phi = goldenRatio
        let phiInverse = 1.0 / phi
        
        let score1 = 1.0 - abs(ratio - phi) / (phi * tolerance)
        let score2 = 1.0 - abs(ratio - phiInverse) / (phiInverse * tolerance)
        
        return max(0.0, max(score1, score2))
    }
    
    // MARK: - Advanced Object Recognition
    static func analyzeAdvancedSpiralPattern(_ points: [CGPoint], pixelBuffer: CVPixelBuffer) -> (confidence: Double, objectType: String, context: String) {
        // Analyze the spiral pattern to determine what object it might be
        let spiralScore = calculateSpiralScore(points)
        
        // Determine object type based on spiral characteristics
        let objectType = determineSpiralObjectType(points, spiralScore: spiralScore)
        let context = generateSpiralContext(objectType, spiralScore: spiralScore)
        
        return (spiralScore, objectType, context)
    }
    
    static func analyzeRectangleForObjectContext(_ rectangleObservation: Any, pixelBuffer: CVPixelBuffer) -> (confidence: Double, objectType: String, context: String) {
        // Analyze rectangle to determine object context
        return (0.5, "geometric_shape", "Rectangular object detected")
    }
    
    private static func determineSpiralObjectType(_ points: [CGPoint], spiralScore: Double) -> String {
        // Analyze spiral characteristics to determine object type
        let center = calculateCenter(points)
        let radius = calculateAverageRadius(points, center: center)
        let tightness = calculateSpiralTightness(points, center: center)
        
        // Object type classification based on spiral properties
        if tightness > 0.8 && radius < 100 {
            return "shell"
        } else if tightness > 0.6 && radius > 100 {
            return "flower_petal"
        } else if tightness > 0.4 {
            return "nautilus"
        } else if radius > 200 {
            return "galaxy_arm"
        } else {
            return "spiral_object"
        }
    }
    
    private static func generateSpiralContext(_ objectType: String, spiralScore: Double) -> String {
        switch objectType {
        case "shell":
            return "This shell follows a logarithmic spiral, growing at the golden ratio for maximum strength and efficiency."
        case "flower_petal":
            return "The petals are arranged in a Fibonacci spiral pattern, ensuring optimal sunlight exposure for each petal."
        case "nautilus":
            return "This nautilus shell exhibits the perfect golden ratio spiral, with each chamber 1.618 times larger than the previous."
        case "galaxy_arm":
            return "The galaxy arm follows a spiral pattern similar to Fibonacci sequences found in nature."
        case "spiral_object":
            return "This object exhibits spiral characteristics that follow mathematical patterns found throughout nature."
        default:
            return "A spiral pattern has been detected with mathematical properties similar to those found in natural objects."
        }
    }
    
    private static func calculateCenter(_ points: [CGPoint]) -> CGPoint {
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
    
    private static func calculateAverageRadius(_ points: [CGPoint], center: CGPoint) -> CGFloat {
        let distances = points.map { sqrt(pow($0.x - center.x, 2) + pow($0.y - center.y, 2)) }
        return distances.reduce(0, +) / CGFloat(distances.count)
    }
    
    private static func calculateSpiralTightness(_ points: [CGPoint], center: CGPoint) -> Double {
        // Calculate how tightly wound the spiral is
        let distances = points.map { sqrt(pow($0.x - center.x, 2) + pow($0.y - center.y, 2)) }
        let minDistance = distances.min() ?? 0
        let maxDistance = distances.max() ?? 1
        return Double(minDistance / maxDistance)
    }
}

