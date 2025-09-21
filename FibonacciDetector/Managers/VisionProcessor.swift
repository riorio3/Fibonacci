import Foundation
import Vision
import CoreImage
import CoreML
import Accelerate

class VisionProcessor {
    // MARK: - Private Properties
    private let processingQueue = DispatchQueue(label: "vision.processing", qos: .userInitiated)
    private var requestSequence = 0
    
    // MARK: - Vision Requests
    private lazy var edgeDetectionRequest: VNDetectContoursRequest = {
        let request = VNDetectContoursRequest()
        request.detectsDarkOnLight = true
        request.contrastAdjustment = 1.0
        request.maximumImageDimension = 512
        return request
    }()
    
    private lazy var rectangleDetectionRequest: VNDetectRectanglesRequest = {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 10 // Reduced for stability
        request.minimumAspectRatio = 0.2 // More restrictive for golden ratio
        request.maximumAspectRatio = 5.0 // More restrictive for golden ratio
        request.minimumSize = 0.08 // Slightly larger minimum for stability
        request.minimumConfidence = 0.3 // Higher confidence for stability
        return request
    }()
    
    private lazy var textDetectionRequest: VNDetectTextRectanglesRequest = {
        let request = VNDetectTextRectanglesRequest()
        request.reportCharacterBoxes = true
        return request
    }()
    
    // MARK: - Fibonacci Pattern Detection
    func detectPatterns(in pixelBuffer: CVPixelBuffer) -> [DetectedPattern]? {
        var detectedPatterns: [DetectedPattern] = []
        
        // Simplified detection to reduce processing load
        // 1. Rectangle Detection for Golden Ratio (most reliable)
        if let rectanglePatterns = detectRectangles(pixelBuffer) {
            detectedPatterns.append(contentsOf: rectanglePatterns)
        }
        
        // 2. Basic Spiral Detection (simplified)
        if let spiralPatterns = detectSpirals(pixelBuffer) {
            detectedPatterns.append(contentsOf: spiralPatterns)
        }
        
        // 3. Nautilus Spiral Detection (enhanced for nautilus shells)
        if let nautilusPatterns = detectNautilusSpirals(pixelBuffer) {
            detectedPatterns.append(contentsOf: nautilusPatterns)
        }
        
        return detectedPatterns.isEmpty ? nil : detectedPatterns
    }
    
    // MARK: - Edge and Contour Detection
    private func detectEdgesAndContours(_ pixelBuffer: CVPixelBuffer) -> [DetectedPattern]? {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try requestHandler.perform([edgeDetectionRequest])
            
            guard let observations = edgeDetectionRequest.results else { return nil }
            
            var patterns: [DetectedPattern] = []
            
            for observation in observations {
                if let contourPattern = analyzeContourForFibonacciPattern(observation) {
                    patterns.append(contourPattern)
                }
            }
            
            return patterns.isEmpty ? nil : patterns
        } catch {
            print("❌ Edge detection failed: \(error)")
            return nil
        }
    }
    
    private func analyzeContourForFibonacciPattern(_ observation: VNContoursObservation) -> DetectedPattern? {
        // Analyze contour for spiral patterns
        let contourPoints = observation.topLevelContours.flatMap { $0.normalizedPoints }
            .map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
        
        if contourPoints.count < 10 { return nil }
        
        // Check for spiral characteristics
        let spiralScore = calculateSpiralScore(contourPoints)
        
        if spiralScore > 0.7 {
            let boundingBox = CGRect(x: 0, y: 0, width: 1, height: 1) // Placeholder bounding box
            let confidence = Float(spiralScore)
            
            return createDetectedPattern(
                type: .fibonacciSpiral,
                confidence: confidence,
                boundingBox: boundingBox,
                additionalData: ["spiral_score": spiralScore, "contour_points": contourPoints.count]
            )
        }
        
        return nil
    }
    
    // MARK: - Rectangle Detection for Golden Ratio
    private func detectRectangles(_ pixelBuffer: CVPixelBuffer) -> [DetectedPattern]? {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        do {
            try requestHandler.perform([rectangleDetectionRequest])
            
            guard let observations = rectangleDetectionRequest.results else { return nil }
            
            var patterns: [DetectedPattern] = []
            
            for observation in observations {
                if let goldenRatioPattern = analyzeRectangleForGoldenRatio(observation) {
                    patterns.append(goldenRatioPattern)
                }
            }
            
            return patterns.isEmpty ? nil : patterns
        } catch {
            print("❌ Rectangle detection failed: \(error)")
            return nil
        }
    }
    
    private func analyzeRectangleForGoldenRatio(_ observation: VNRectangleObservation) -> DetectedPattern? {
        let boundingBox = observation.boundingBox
        let width = boundingBox.width
        let height = boundingBox.height
        
        // Calculate aspect ratio
        let aspectRatio = width / height
        let goldenRatio: Double = 1.618033988749895
        
        // Check if aspect ratio is close to golden ratio or its inverse
        let ratioDifference = min(
            abs(aspectRatio - goldenRatio),
            abs(aspectRatio - (1.0 / goldenRatio))
        )
        
        // More restrictive threshold for stability (8% instead of 12%)
        if ratioDifference < 0.08 {
            let confidence = Float(1.0 - (ratioDifference / 0.08))
            
            // Additional validation: check if the rectangle is reasonably sized
            let area = width * height
            // More restrictive size range for stability (2% to 40% of image)
            if area > 0.02 && area < 0.4 {
                // Only return if confidence is high enough for stability
                if confidence >= 0.6 {
                    return createDetectedPattern(
                        type: .goldenRatio,
                        confidence: confidence,
                        boundingBox: boundingBox,
                        additionalData: ["aspect_ratio": aspectRatio, "golden_ratio_difference": ratioDifference]
                    )
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Nautilus Spiral Detection
    private func detectNautilusSpirals(_ pixelBuffer: CVPixelBuffer) -> [DetectedPattern]? {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        let contourRequest = VNDetectContoursRequest()
        contourRequest.detectsDarkOnLight = true
        contourRequest.contrastAdjustment = 1.2 // Higher contrast for shell edges
        contourRequest.maximumImageDimension = 256
        
        do {
            try requestHandler.perform([contourRequest])
            
            guard let observations = contourRequest.results else { return nil }
            
            var patterns: [DetectedPattern] = []
            
            for observation in observations {
                let contours = observation.topLevelContours
                for contour in contours {
                    let points = contour.normalizedPoints.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
                    
                    if points.count > 20 { // Higher point requirement for stability
                        // Use enhanced nautilus detection
                        let center = MathUtils.calculateCenterPoint(points)
                        let nautilusResult = MathUtils.detectNautilusSpiral(in: points, center: center)
                        
                        if nautilusResult.isNautilus && nautilusResult.confidence > 0.7 { // Higher confidence threshold for stability
                            let boundingBox = MathUtils.calculateBoundingBox(points)
                            let area = boundingBox.width * boundingBox.height
                            
                            // More restrictive size range for stability (2% to 60% of image)
                            if area > 0.02 && area < 0.6 {
                                let confidence = Float(nautilusResult.confidence)
                                
                                // Only add if confidence is high enough for stability
                                if confidence >= 0.7 {
                                    patterns.append(createDetectedPattern(
                                        type: .nautilusSpiral,
                                        confidence: confidence,
                                        boundingBox: boundingBox,
                                        additionalData: [
                                            "chamber_count": nautilusResult.chamberCount,
                                            "growth_rate": nautilusResult.growthRate,
                                            "nautilus_score": nautilusResult.confidence
                                        ]
                                    ))
                                }
                            }
                        }
                    }
                }
            }
            
            return patterns.isEmpty ? nil : patterns
        } catch {
            print("❌ Nautilus spiral detection failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Spiral Detection
    private func detectSpirals(_ pixelBuffer: CVPixelBuffer) -> [DetectedPattern]? {
        // Simplified spiral detection to reduce processing load
        // Use contour detection instead of complex edge analysis
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        let contourRequest = VNDetectContoursRequest()
        contourRequest.detectsDarkOnLight = true
        contourRequest.contrastAdjustment = 1.0
        contourRequest.maximumImageDimension = 256 // Reduce resolution for performance
        
        do {
            try requestHandler.perform([contourRequest])
            
            guard let observations = contourRequest.results else { return nil }
            
            var patterns: [DetectedPattern] = []
            
            for observation in observations {
                let contours = observation.topLevelContours
                for contour in contours {
                    let points = contour.normalizedPoints.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
                    
                    if points.count > 10 { // Higher point requirement for stability
                        let spiralScore = MathUtils.calculateSpiralScore(points)
                        if spiralScore > 0.6 { // Higher threshold for stability
                            // Additional validation: check if the spiral is reasonably sized
                            let boundingBox = calculateBoundingBox(for: points)
                            let area = boundingBox.width * boundingBox.height
                            
                            // More restrictive size range for stability (2% to 60% of image)
                            if area > 0.02 && area < 0.6 {
                                let confidence = Float(spiralScore)
                                
                                // Only add if confidence is high enough for stability
                                if confidence >= 0.6 {
                                    patterns.append(createDetectedPattern(
                                        type: .fibonacciSpiral,
                                        confidence: confidence,
                                        boundingBox: boundingBox
                                    ))
                                }
                            }
                        }
                    }
                }
            }
            
            return patterns.isEmpty ? nil : patterns
        } catch {
            print("❌ Spiral detection failed: \(error)")
            return nil
        }
    }
    
    private func analyzeSpiralPatterns(in image: CIImage) -> [DetectedPattern]? {
        // This is a simplified spiral detection algorithm
        // In a production app, you would implement more sophisticated algorithms
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(image, from: image.extent) else { return nil }
        
        // Analyze image for spiral characteristics
        let spiralRegions = detectSpiralRegions(in: cgImage)
        
        var patterns: [DetectedPattern] = []
        
        for region in spiralRegions {
            let confidence = Float(region.confidence)
            let boundingBox = region.boundingBox
            
            let patternType: PatternType = region.type == "sunflower" ? .sunflowerSpiral : .fibonacciSpiral
            
            patterns.append(createDetectedPattern(
                type: patternType,
                confidence: confidence,
                boundingBox: boundingBox,
                additionalData: ["spiral_type": region.type, "spiral_angle": region.angle]
            ))
        }
        
        return patterns.isEmpty ? nil : patterns
    }
    
    private func detectSpiralRegions(in cgImage: CGImage) -> [SpiralRegion] {
        var regions: [SpiralRegion] = []
        
        // Convert CGImage to CIImage for processing
        let ciImage = CIImage(cgImage: cgImage)
        
        // Apply edge detection
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return regions }
        edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let edgeImage = edgeFilter.outputImage else { return regions }
        
        // Convert to CGImage for analysis
        let context = CIContext()
        guard let edgeCGImage = context.createCGImage(edgeImage, from: edgeImage.extent) else { return regions }
        
        // Analyze edge image for spiral patterns
        let width = cgImage.width
        let height = cgImage.height
        
        // Sample points along potential spiral paths
        let centerX = width / 2
        let centerY = height / 2
        let maxRadius = min(width, height) / 2
        
        // Check for logarithmic spiral patterns
        for turn in stride(from: 1.0, through: 3.0, by: 0.5) {
            let spiralPoints = generateSpiralPoints(
                center: CGPoint(x: centerX, y: centerY),
                maxRadius: Double(maxRadius),
                turns: turn
            )
            
            let spiralScore = analyzeSpiralPath(spiralPoints, in: edgeCGImage)
            
            if spiralScore > 0.6 {
                let boundingBox = calculateBoundingBox(for: spiralPoints)
                let region = SpiralRegion(
                    boundingBox: boundingBox,
                    confidence: spiralScore,
                    type: "fibonacci",
                    angle: 137.5
                )
                regions.append(region)
            }
        }
        
        return regions
    }
    
    private func generateSpiralPoints(center: CGPoint, maxRadius: Double, turns: Double) -> [CGPoint] {
        var points: [CGPoint] = []
        let segments = Int(turns * 50)
        
        for i in 0...segments {
            let angle = Double(i) * 2 * .pi * turns / Double(segments)
            let radius = maxRadius * (Double(i) / Double(segments))
            
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private func analyzeSpiralPath(_ points: [CGPoint], in image: CGImage) -> Double {
        // Analyze how well the spiral path matches edge features in the image
        var edgeMatches = 0
        let totalPoints = points.count
        
        for point in points {
            if isEdgePoint(point, in: image) {
                edgeMatches += 1
            }
        }
        
        return Double(edgeMatches) / Double(totalPoints)
    }
    
    private func isEdgePoint(_ point: CGPoint, in image: CGImage) -> Bool {
        let x = Int(point.x)
        let y = Int(point.y)
        
        guard x >= 0 && x < image.width && y >= 0 && y < image.height else { return false }
        
        // Sample pixel data to check for edge characteristics
        // This is a simplified check - in production, use proper edge detection
        let pixelData = image.dataProvider?.data
        let data = CFDataGetBytePtr(pixelData)
        
        if let data = data {
            let bytesPerPixel = image.bitsPerPixel / 8
            let pixelIndex = (y * image.bytesPerRow) + (x * bytesPerPixel)
            
            if pixelIndex < CFDataGetLength(pixelData) {
                let intensity = data[pixelIndex]
                return intensity > 128 // Threshold for edge detection
            }
        }
        
        return false
    }
    
    private func calculateBoundingBox(for points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    // MARK: - Mathematical Pattern Analysis
    private func analyzeMathematicalPatterns(_ pixelBuffer: CVPixelBuffer) -> [DetectedPattern]? {
        // Analyze image for mathematical patterns like Fibonacci sequences in arrangements
        
        var patterns: [DetectedPattern] = []
        
        // Analyze for Fibonacci sequence patterns in object arrangements
        if let fibonacciPattern = detectFibonacciSequencePattern(pixelBuffer) {
            patterns.append(fibonacciPattern)
        }
        
        // Analyze for phi grid patterns
        if let phiGridPattern = detectPhiGridPattern(pixelBuffer) {
            patterns.append(phiGridPattern)
        }
        
        // Analyze for specific natural Fibonacci patterns
        if let sunflowerPattern = detectSunflowerPattern(pixelBuffer) {
            patterns.append(sunflowerPattern)
        }
        
        if let pineconePattern = detectPineconePattern(pixelBuffer) {
            patterns.append(pineconePattern)
        }
        
        return patterns.isEmpty ? nil : patterns
    }
    
    private func detectSunflowerPattern(_ pixelBuffer: CVPixelBuffer) -> DetectedPattern? {
        // Detect sunflower-like spiral patterns
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        // Use circle detection to find circular objects
        let circleRequest = VNDetectRectanglesRequest()
        circleRequest.maximumObservations = 10
        circleRequest.minimumAspectRatio = 0.8
        circleRequest.maximumAspectRatio = 1.2
        circleRequest.minimumSize = 0.1
        circleRequest.minimumConfidence = 0.4
        
        do {
            try requestHandler.perform([circleRequest])
            
            guard let observations = circleRequest.results else { return nil }
            
            for observation in observations {
                let boundingBox = observation.boundingBox
                
                // Analyze the circular region for sunflower-like patterns
                if let sunflowerScore = analyzeSunflowerPattern(in: boundingBox, pixelBuffer: pixelBuffer) {
                    if sunflowerScore > 0.7 {
                        let confidence = Float(sunflowerScore)
                        
                        return createDetectedPattern(
                            type: .sunflowerSpiral,
                            confidence: confidence,
                            boundingBox: boundingBox,
                            additionalData: ["sunflower_score": sunflowerScore]
                        )
                    }
                }
            }
        } catch {
            print("❌ Sunflower detection failed: \(error)")
        }
        
        return nil
    }
    
    private func detectPineconePattern(_ pixelBuffer: CVPixelBuffer) -> DetectedPattern? {
        // Detect pinecone-like spiral patterns
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        // Use rectangle detection to find elongated objects
        let rectangleRequest = VNDetectRectanglesRequest()
        rectangleRequest.maximumObservations = 15
        rectangleRequest.minimumAspectRatio = 0.3
        rectangleRequest.maximumAspectRatio = 3.0
        rectangleRequest.minimumSize = 0.05
        rectangleRequest.minimumConfidence = 0.3
        
        do {
            try requestHandler.perform([rectangleRequest])
            
            guard let observations = rectangleRequest.results else { return nil }
            
            // Group rectangles that might form a pinecone pattern
            let rectangles = observations.map { $0.boundingBox }
            let groupedRectangles = groupRectanglesForPinecone(rectangles)
            
            for group in groupedRectangles {
                if group.count >= 5 {
                    let pineconeScore = analyzePineconePattern(group)
                    
                    if pineconeScore > 0.6 {
                        let boundingBox = calculateGroupBoundingBox(group)
                        let confidence = Float(pineconeScore)
                        
                        return createDetectedPattern(
                            type: .pineconeSpiral,
                            confidence: confidence,
                            boundingBox: boundingBox,
                            additionalData: ["pinecone_score": pineconeScore, "scale_count": group.count]
                        )
                    }
                }
            }
        } catch {
            print("❌ Pinecone detection failed: \(error)")
        }
        
        return nil
    }
    
    private func analyzeSunflowerPattern(in boundingBox: CGRect, pixelBuffer: CVPixelBuffer) -> Double? {
        // Analyze the region for sunflower-like spiral patterns
        // This would involve analyzing the internal structure of the circular region
        
        // For now, return a placeholder score based on bounding box characteristics
        let aspectRatio = boundingBox.width / boundingBox.height
        let isCircular = abs(aspectRatio - 1.0) < 0.2
        
        if isCircular && boundingBox.width > 0.1 {
            return 0.8 // High confidence for circular objects
        }
        
        return nil
    }
    
    private func groupRectanglesForPinecone(_ rectangles: [CGRect]) -> [[CGRect]] {
        // Group rectangles that might form a pinecone pattern
        var groups: [[CGRect]] = []
        var used = Set<Int>()
        
        for (index, rect) in rectangles.enumerated() {
            if used.contains(index) { continue }
            
            var group = [rect]
            used.insert(index)
            
            // Find rectangles that are aligned and overlapping
            for (otherIndex, otherRect) in rectangles.enumerated() {
                if used.contains(otherIndex) { continue }
                
                if areRectanglesAligned(rect, otherRect) && rectanglesOverlap(rect, otherRect) {
                    group.append(otherRect)
                    used.insert(otherIndex)
                }
            }
            
            if group.count >= 3 {
                groups.append(group)
            }
        }
        
        return groups
    }
    
    private func areRectanglesAligned(_ rect1: CGRect, _ rect2: CGRect) -> Bool {
        // Check if rectangles are roughly aligned (for pinecone scales)
        let center1 = CGPoint(x: rect1.midX, y: rect1.midY)
        let center2 = CGPoint(x: rect2.midX, y: rect2.midY)
        
        let horizontalDistance = abs(center1.x - center2.x)
        let verticalDistance = abs(center1.y - center2.y)
        
        // Check if they're roughly in a line
        return horizontalDistance < 0.1 || verticalDistance < 0.1
    }
    
    private func rectanglesOverlap(_ rect1: CGRect, _ rect2: CGRect) -> Bool {
        return rect1.intersects(rect2)
    }
    
    private func analyzePineconePattern(_ rectangles: [CGRect]) -> Double {
        // Analyze if the arrangement of rectangles forms a pinecone-like pattern
        
        guard rectangles.count >= 3 else { return 0.0 }
        
        // Sort rectangles by position
        let sortedRectangles = rectangles.sorted { $0.midY < $1.midY }
        
        // Check for spiral-like arrangement
        var spiralScore = 0.0
        
        for i in 1..<sortedRectangles.count {
            let prevRect = sortedRectangles[i-1]
            let currentRect = sortedRectangles[i]
            
            // Check if rectangles are arranged in a spiral pattern
            let angleChange = calculateAngleChange(prevRect, currentRect)
            if abs(angleChange - 137.5) < 20 { // Golden angle ± 20 degrees
                spiralScore += 1.0
            }
        }
        
        return spiralScore / Double(sortedRectangles.count - 1)
    }
    
    private func calculateAngleChange(_ rect1: CGRect, _ rect2: CGRect) -> Double {
        let center1 = CGPoint(x: rect1.midX, y: rect1.midY)
        let center2 = CGPoint(x: rect2.midX, y: rect2.midY)
        
        let angle1 = atan2(Double(center1.y), Double(center1.x))
        let angle2 = atan2(Double(center2.y), Double(center2.x))
        
        return abs(angle2 - angle1) * 180 / .pi
    }
    
    private func detectFibonacciSequencePattern(_ pixelBuffer: CVPixelBuffer) -> DetectedPattern? {
        // Analyze image for Fibonacci sequence patterns in object arrangements
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        // Use object detection to find circular/oval objects that might be arranged in Fibonacci patterns
        let objectRequest = VNDetectRectanglesRequest()
        objectRequest.maximumObservations = 20
        objectRequest.minimumAspectRatio = 0.1
        objectRequest.maximumAspectRatio = 10.0
        objectRequest.minimumSize = 0.05
        objectRequest.minimumConfidence = 0.3
        
        do {
            try requestHandler.perform([objectRequest])
            
            guard let observations = objectRequest.results else { return nil }
            
            // Group objects by proximity and analyze their arrangements
            let objects = observations.map { $0.boundingBox }
            let groupedObjects = groupObjectsByProximity(objects)
            
            for group in groupedObjects {
                if group.count >= 3 {
                    // Analyze if the arrangement follows Fibonacci patterns
                    let fibonacciScore = analyzeFibonacciArrangement(group)
                    
                    if fibonacciScore > 0.7 {
                        let boundingBox = calculateGroupBoundingBox(group)
                        let confidence = Float(fibonacciScore)
                        
                        return createDetectedPattern(
                            type: .fibonacciSequence,
                            confidence: confidence,
                            boundingBox: boundingBox,
                            additionalData: ["arrangement_score": fibonacciScore, "object_count": group.count]
                        )
                    }
                }
            }
        } catch {
            print("❌ Object detection failed: \(error)")
        }
        
        return nil
    }
    
    private func groupObjectsByProximity(_ objects: [CGRect]) -> [[CGRect]] {
        var groups: [[CGRect]] = []
        var used = Set<Int>()
        
        for (index, object) in objects.enumerated() {
            if used.contains(index) { continue }
            
            var group = [object]
            used.insert(index)
            
            // Find nearby objects
            for (otherIndex, otherObject) in objects.enumerated() {
                if used.contains(otherIndex) { continue }
                
                let distance = calculateDistance(object, otherObject)
                if distance < 0.2 { // Within 20% of image size
                    group.append(otherObject)
                    used.insert(otherIndex)
                }
            }
            
            if group.count >= 2 {
                groups.append(group)
            }
        }
        
        return groups
    }
    
    private func calculateDistance(_ rect1: CGRect, _ rect2: CGRect) -> Double {
        let center1 = CGPoint(x: rect1.midX, y: rect1.midY)
        let center2 = CGPoint(x: rect2.midX, y: rect2.midY)
        
        let dx = Double(center1.x - center2.x)
        let dy = Double(center1.y - center2.y)
        
        return sqrt(dx * dx + dy * dy)
    }
    
    private func analyzeFibonacciArrangement(_ objects: [CGRect]) -> Double {
        // Analyze if the arrangement of objects follows Fibonacci patterns
        // This could include spiral arrangements, golden ratio spacing, etc.
        
        guard objects.count >= 3 else { return 0.0 }
        
        // Calculate center of the arrangement
        let centerX = objects.map { $0.midX }.reduce(0, +) / CGFloat(objects.count)
        let centerY = objects.map { $0.midY }.reduce(0, +) / CGFloat(objects.count)
        let center = CGPoint(x: centerX, y: centerY)
        
        // Calculate angles from center
        let angles = objects.map { object in
            atan2(Double(object.midY - center.y), Double(object.midX - center.x))
        }.sorted()
        
        // Check for golden angle spacing (137.5 degrees)
        let goldenAngleRadians = 137.5 * .pi / 180
        var matches = 0
        
        for i in 1..<angles.count {
            let angleDiff = angles[i] - angles[i-1]
            let normalizedDiff = angleDiff.truncatingRemainder(dividingBy: 2 * .pi)
            
            if abs(normalizedDiff - goldenAngleRadians) < 0.1 {
                matches += 1
            }
        }
        
        return Double(matches) / Double(angles.count - 1)
    }
    
    private func calculateGroupBoundingBox(_ objects: [CGRect]) -> CGRect {
        guard !objects.isEmpty else { return .zero }
        
        let minX = objects.map { $0.minX }.min() ?? 0
        let maxX = objects.map { $0.maxX }.max() ?? 0
        let minY = objects.map { $0.minY }.min() ?? 0
        let maxY = objects.map { $0.maxY }.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private func detectPhiGridPattern(_ pixelBuffer: CVPixelBuffer) -> DetectedPattern? {
        // Analyze image for phi grid patterns
        // This would look for grid-like arrangements based on golden ratio
        
        // Placeholder implementation
        return nil
    }
    
    // MARK: - Helper Methods
    private func calculateSpiralScore(_ points: [CGPoint]) -> Double {
        // Calculate how spiral-like a contour is
        // This is a simplified algorithm - in production, use more sophisticated methods
        
        guard points.count > 10 else { return 0.0 }
        
        var totalAngleChange = 0.0
        var radiusChange = 0.0
        
        for i in 2..<points.count {
            let p1 = points[i-2]
            let p2 = points[i-1]
            let p3 = points[i]
            
            // Calculate angle change
            let angle1 = atan2(p2.y - p1.y, p2.x - p1.x)
            let angle2 = atan2(p3.y - p2.y, p3.x - p2.x)
            let angleChange = abs(angle2 - angle1)
            totalAngleChange += angleChange
            
            // Calculate radius change
            let r1 = sqrt(p1.x * p1.x + p1.y * p1.y)
            let r2 = sqrt(p2.x * p2.x + p2.y * p2.y)
            let r3 = sqrt(p3.x * p3.x + p3.y * p3.y)
            radiusChange += abs(r3 - r2) - abs(r2 - r1)
        }
        
        // Normalize scores
        let avgAngleChange = totalAngleChange / Double(points.count - 2)
        let avgRadiusChange = radiusChange / Double(points.count - 2)
        
        // Combine scores (simplified)
        let spiralScore = min(1.0, (avgAngleChange + avgRadiusChange) / 2.0)
        
        return spiralScore
    }
    
    private func createDetectedPattern(
        type: PatternType,
        confidence: Float,
        boundingBox: CGRect,
        additionalData: [String: Any] = [:]
    ) -> DetectedPattern {
        let centerPoint = CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )
        
        let mathematicalProperties = DetectedPattern.MathematicalProperties(
            phiValue: type == .goldenRatio ? 1.618033988749895 : nil,
            fibonacciNumbers: type == .fibonacciSequence ? [1, 1, 2, 3, 5, 8, 13, 21] : nil,
            spiralAngle: type == .fibonacciSpiral ? 137.5 : nil,
            ratio: type == .goldenRatio ? 1.618033988749895 : nil,
            sequence: nil
        )
        
        let educationalContent = DetectedPattern.EducationalContent(
            title: type.displayName,
            description: getPatternDescription(type),
            mathematicalExplanation: getMathematicalExplanation(type),
            examples: getPatternExamples(type),
            funFacts: getPatternFunFacts(type)
        )
        
        return DetectedPattern(
            type: type,
            confidence: confidence,
            boundingBox: boundingBox,
            centerPoint: centerPoint,
            detectedAt: Date(),
            mathematicalProperties: mathematicalProperties,
            educationalContent: educationalContent
        )
    }
    
    // MARK: - Educational Content Helpers
    private func getPatternDescription(_ type: PatternType) -> String {
        switch type {
        case .fibonacciSpiral:
            return "A spiral that grows according to the Fibonacci sequence, found in shells, galaxies, and flowers."
        case .goldenRatio:
            return "The mathematical ratio of approximately 1.618, considered aesthetically pleasing and found throughout nature."
        case .fibonacciSequence:
            return "A sequence where each number is the sum of the two preceding ones: 1, 1, 2, 3, 5, 8, 13..."
        case .phiGrid:
            return "A grid system based on the golden ratio, used in art and architecture for harmonious proportions."
        case .sunflowerSpiral:
            return "The spiral arrangement of seeds in a sunflower follows Fibonacci numbers for optimal packing."
        case .pineconeSpiral:
            return "Pinecone scales are arranged in spirals that follow Fibonacci numbers for efficient growth."
        case .shellSpiral:
            return "Shells grow in logarithmic spirals that approximate the golden ratio for structural strength."
        case .nautilusSpiral:
            return "The nautilus shell is a perfect example of a logarithmic spiral, with chambers that grow according to the golden ratio, creating one of nature's most beautiful mathematical patterns."
        case .leafArrangement:
            return "Leaves are arranged in patterns that follow Fibonacci numbers to maximize sunlight exposure."
        }
    }
    
    private func getMathematicalExplanation(_ type: PatternType) -> String {
        switch type {
        case .fibonacciSpiral:
            return "The Fibonacci spiral is created by drawing quarter circles in squares with Fibonacci number dimensions. The ratio of consecutive Fibonacci numbers approaches the golden ratio (φ ≈ 1.618)."
        case .goldenRatio:
            return "The golden ratio φ = (1 + √5)/2 ≈ 1.618. It's the positive solution to φ² = φ + 1, and appears in the ratio of consecutive Fibonacci numbers."
        case .fibonacciSequence:
            return "F(n) = F(n-1) + F(n-2) with F(0) = 0, F(1) = 1. The ratio F(n+1)/F(n) approaches φ as n increases."
        case .phiGrid:
            return "A grid where each rectangle has sides in the ratio 1:φ. This creates harmonious proportions used in design."
        case .sunflowerSpiral:
            return "Seeds are placed at angles of 137.5° (360°/φ²) apart, creating optimal packing with Fibonacci numbers of spirals."
        case .pineconeSpiral:
            return "Scales are arranged in spirals with Fibonacci numbers of clockwise and counterclockwise spirals."
        case .shellSpiral:
            return "Shells grow by adding material at a constant angle, creating a logarithmic spiral with golden ratio proportions."
        case .nautilusSpiral:
            return "The nautilus shell grows by adding new chambers at a constant angle, creating a logarithmic spiral where each chamber is approximately 1.618 times larger than the previous one, following the golden ratio."
        case .leafArrangement:
            return "Leaves are positioned at angles of 360°/φ ≈ 222.5° apart to minimize overlap and maximize light exposure."
        }
    }
    
    private func getPatternExamples(_ type: PatternType) -> [String] {
        switch type {
        case .fibonacciSpiral:
            return ["Nautilus shells", "Galaxy arms", "Hurricane patterns", "Flower petals"]
        case .goldenRatio:
            return ["Human body proportions", "Parthenon architecture", "Mona Lisa composition", "DNA helix"]
        case .fibonacciSequence:
            return ["Rabbit breeding", "Pinecone spirals", "Flower petal counts", "Tree branching"]
        case .phiGrid:
            return ["Renaissance paintings", "Modern web design", "Photography composition", "Architectural layouts"]
        case .sunflowerSpiral:
            return ["Sunflower seeds", "Daisy centers", "Pineapple patterns", "Artichoke leaves"]
        case .pineconeSpiral:
            return ["Pine cones", "Fir cones", "Spruce cones", "Cedar cones"]
        case .shellSpiral:
            return ["Nautilus shells", "Snail shells", "Ammonite fossils", "Chambered nautilus"]
        case .nautilusSpiral:
            return ["Chambered nautilus", "Nautilus pompilius", "Fossil nautiloids", "Cross-section of nautilus shells"]
        case .leafArrangement:
            return ["Tree leaves", "Plant stems", "Flower arrangements", "Branch patterns"]
        }
    }
    
    private func getPatternFunFacts(_ type: PatternType) -> [String] {
        switch type {
        case .fibonacciSpiral:
            return ["The Fibonacci spiral is also called the golden spiral", "It appears in the arrangement of leaves on plants", "Galaxies often have spiral arms following this pattern"]
        case .goldenRatio:
            return ["Also known as the divine proportion", "Used in the design of credit cards", "Appears in the proportions of the human face"]
        case .fibonacciSequence:
            return ["Named after Leonardo of Pisa (Fibonacci)", "Appears in the breeding patterns of rabbits", "Used in computer algorithms and data structures"]
        case .phiGrid:
            return ["Used by ancient Greek architects", "Found in the design of the Great Pyramid", "Used in modern graphic design principles"]
        case .sunflowerSpiral:
            return ["The angle 137.5° is called the golden angle", "This arrangement maximizes seed packing", "Found in over 90% of sunflower varieties"]
        case .pineconeSpiral:
            return ["Usually has 8 and 13 spirals", "The pattern helps with seed dispersal", "Found in most coniferous trees"]
        case .shellSpiral:
            return ["Provides maximum strength with minimum material", "The spiral grows at a constant rate", "Found in marine animals for millions of years"]
        case .nautilusSpiral:
            return ["The nautilus is called a 'living fossil' - it has remained unchanged for 500 million years", "Each chamber is sealed off as the nautilus grows, creating a perfect logarithmic spiral", "The golden ratio in nautilus shells inspired the design of the Parthenon in ancient Greece"]
        case .leafArrangement:
            return ["Called phyllotaxis in botany", "Helps plants maximize sunlight exposure", "Prevents leaves from shading each other"]
        }
    }
}

// MARK: - Supporting Structures
struct SpiralRegion {
    let boundingBox: CGRect
    let confidence: Double
    let type: String
    let angle: Double
}
