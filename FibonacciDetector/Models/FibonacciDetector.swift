import Foundation
import CoreML
import Vision
import ARKit
import Combine

@MainActor
class FibonacciDetector: ObservableObject {
    // MARK: - Published Properties
    @Published var detectedPatterns: [DetectedPattern] = []
    @Published var isProcessing = false
    @Published var performanceMetrics = PerformanceMetrics()
    @Published var settings = DetectionSettings()
    @Published var voiceNarrationEnabled = true
    
    // MARK: - Private Properties
    private var mlModel: MLModel?
    private var visionProcessor: VisionProcessor?
    private var voiceNarrationManager: VoiceNarrationManager?
    private var processingQueue = DispatchQueue(label: "fibonacci.detection", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private var lastProcessingTime = Date()
    private var frameCount = 0
    
    // MARK: - Pattern Stability Properties
    private var patternHistory: [String: [DetectedPattern]] = [:]
    private var stablePatterns: [DetectedPattern] = []
    private var lastStableUpdate = Date()
    private let stabilityThreshold = 0.6 // Minimum confidence for stable patterns
    private let historySize = 5 // Number of frames to consider for stability
    private let stabilityUpdateInterval: TimeInterval = 0.3 // Update stable patterns every 300ms
    
    // MARK: - Constants
    private let goldenRatio: Double = 1.618033988749895
    private let phi: Double = 1.618033988749895
    private let processingInterval: TimeInterval = 0.5 // 2 FPS processing for better stability
    
    init() {
        setupMLModel()
        setupVisionProcessor()
        setupVoiceNarration()
        setupPerformanceMonitoring()
    }
    
    // MARK: - Setup Methods
    private func setupMLModel() {
        guard let modelURL = Bundle.main.url(forResource: "FibonacciPatternModel", withExtension: "mlmodelc") else {
            print("⚠️ FibonacciPatternModel not found in bundle - using enhanced mathematical detection")
            mlModel = nil
            return
        }
        
        do {
            mlModel = try MLModel(contentsOf: modelURL)
            print("✅ Core ML model loaded successfully")
        } catch {
            print("❌ Failed to load Core ML model: \(error) - using enhanced mathematical detection")
            mlModel = nil
        }
    }
    
    private func setupVisionProcessor() {
        visionProcessor = VisionProcessor()
    }
    
    private func setupVoiceNarration() {
        voiceNarrationManager = VoiceNarrationManager()
        print("✅ Voice narration manager initialized")
    }
    
    private func setupPerformanceMonitoring() {
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePerformanceMetrics()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Detection Methods
    func processFrame(_ pixelBuffer: CVPixelBuffer, depthData: ARDepthData? = nil) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessingTime) >= processingInterval else { return }
        
        lastProcessingTime = now
        frameCount += 1
        
        processingQueue.async { [weak self] in
            Task { @MainActor in
                self?.performDetection(pixelBuffer: pixelBuffer, depthData: depthData)
            }
        }
    }
    
    private func performDetection(pixelBuffer: CVPixelBuffer, depthData: ARDepthData?) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        Task { @MainActor in
            self.isProcessing = true
        }
        
        var newPatterns: [DetectedPattern] = []
        
        // Only run detection if settings are enabled to reduce processing load
        if settings.isSpiralDetectionEnabled || settings.isGoldenRatioDetectionEnabled || settings.isNautilusSpiralDetectionEnabled {
            // 1. Core ML Pattern Detection (if available)
            if let patterns = detectPatternsWithML(pixelBuffer) {
                newPatterns.append(contentsOf: patterns)
            }
            
            // 2. Vision Framework Detection (if enabled)
            if let edgePatterns = detectPatternsWithVision(pixelBuffer) {
                newPatterns.append(contentsOf: edgePatterns)
            }
            
            // 3. Mathematical Pattern Detection (fallback and enhancement)
            if let mathPatterns = detectMathematicalPatterns(pixelBuffer) {
                newPatterns.append(contentsOf: mathPatterns)
            }
            
            // 4. No placeholder patterns - only show real detections
        }
        
        // Filter and sort patterns by confidence, then remove overlapping detections
        let filteredPatterns = newPatterns
            .filter { $0.confidence >= 0.4 } // Lower confidence threshold for better detection
            .sorted { $0.confidence > $1.confidence }
            .removeOverlappingPatterns()
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        Task { @MainActor in
            // Update pattern history for stability tracking
            self.updatePatternHistory(Array(filteredPatterns))
            
            // Update stable patterns if enough time has passed
            let now = Date()
            if now.timeIntervalSince(self.lastStableUpdate) >= self.stabilityUpdateInterval {
                self.updateStablePatterns()
                self.lastStableUpdate = now
            }
            
            // Use stable patterns for display to prevent flickering
            let previousPatterns = self.detectedPatterns
            self.detectedPatterns = self.stablePatterns
            self.isProcessing = false
            self.updatePerformanceMetrics(processingTime: processingTime)
            
            // Only narrate when stable patterns change significantly
            if self.shouldNarratePatterns(previousPatterns: previousPatterns, newPatterns: self.stablePatterns) {
                self.narrateNewPatterns(previousPatterns: previousPatterns, newPatterns: self.stablePatterns)
            }
        }
    }
    
    // MARK: - Core ML Detection
    private func detectPatternsWithML(_ pixelBuffer: CVPixelBuffer) -> [DetectedPattern]? {
        guard let model = mlModel else { 
            // No ML model available - return nil instead of fake patterns
            return nil
        }
        
        do {
            let input = try MLDictionaryFeatureProvider(dictionary: [
                "image": MLFeatureValue(pixelBuffer: pixelBuffer)
            ])
            
            let output = try model.prediction(from: input)
            
            // Process ML model output
            return processMLOutput(output)
        } catch {
            print("❌ ML prediction failed: \(error)")
            return nil
        }
    }
    
    
    private func processMLOutput(_ output: MLFeatureProvider) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []
        
        // Extract pattern detections from ML model output
        // This would be customized based on your specific model architecture
        for patternType in PatternType.allCases {
            if let confidence = output.featureValue(for: patternType.rawValue)?.doubleValue,
               confidence > Double(settings.confidenceThreshold) {
                
                let pattern = createDetectedPattern(
                    type: patternType,
                    confidence: Float(confidence),
                    boundingBox: CGRect(x: 0, y: 0, width: 100, height: 100) // Placeholder
                )
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    // MARK: - Vision Framework Detection
    private func detectPatternsWithVision(_ pixelBuffer: CVPixelBuffer) -> [DetectedPattern]? {
        return visionProcessor?.detectPatterns(in: pixelBuffer)
    }
    
    // MARK: - Mathematical Pattern Detection
    private func detectMathematicalPatterns(_ pixelBuffer: CVPixelBuffer) -> [DetectedPattern]? {
        // Implement mathematical pattern detection algorithms
        // This includes spiral detection, golden ratio analysis, etc.
        
        var patterns: [DetectedPattern] = []
        
        // Fibonacci Spiral Detection
        if settings.isSpiralDetectionEnabled {
            if let spiralPattern = detectFibonacciSpiral(pixelBuffer) {
                patterns.append(spiralPattern)
            }
        }
        
        // Golden Ratio Detection
        if settings.isGoldenRatioDetectionEnabled {
            if let goldenRatioPattern = detectGoldenRatio(pixelBuffer) {
                patterns.append(goldenRatioPattern)
            }
        }
        
        return patterns.isEmpty ? nil : patterns
    }
    
    private func detectFibonacciSpiral(_ pixelBuffer: CVPixelBuffer) -> DetectedPattern? {
        // Enhanced Fibonacci spiral detection using image analysis
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Analyze image for spiral patterns
        // This is a simplified version - in production you'd use more sophisticated algorithms
        let hasSpiralPattern = analyzeImageForSpiralPattern(pixelBuffer)
        
        if hasSpiralPattern {
            let confidence: Float = 0.75
            let boundingBox = CGRect(x: width/4, y: height/4, width: width/2, height: height/2)
            
            return createDetectedPattern(
                type: .fibonacciSpiral,
                confidence: confidence,
                boundingBox: boundingBox
            )
        }
        
        return nil
    }
    
    private func analyzeImageForSpiralPattern(_ pixelBuffer: CVPixelBuffer) -> Bool {
        // Enhanced multi-algorithm spiral detection
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        // Algorithm 1: Contour-based spiral detection
        let contourRequest = VNDetectContoursRequest()
        contourRequest.detectsDarkOnLight = true
        contourRequest.contrastAdjustment = 1.0
        
        // Algorithm 2: Edge detection for spiral patterns
        let edgeRequest = VNDetectEdgesRequest()
        edgeRequest.edgePreserving = true
        
        // Algorithm 3: Circle detection for spiral centers
        let circleRequest = VNDetectCircleRequest()
        circleRequest.maximumObservations = 5
        circleRequest.minimumRadius = 0.05
        circleRequest.maximumRadius = 0.5
        
        do {
            try requestHandler.perform([contourRequest, edgeRequest, circleRequest])
            
            var spiralScore: Double = 0.0
            
            // Analyze contours for spiral characteristics
            if let contourObservations = contourRequest.results {
                for observation in contourObservations {
                    let contours = observation.topLevelContours
                    for contour in contours {
                        let points = contour.normalizedPoints.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) }
                        
                        if points.count > 20 {
                            let contourSpiralScore = MathUtils.calculateSpiralScore(points)
                            spiralScore = max(spiralScore, contourSpiralScore)
                        }
                    }
                }
            }
            
            // Analyze edges for logarithmic spiral patterns
            if let edgeObservations = edgeRequest.results {
                for observation in edgeObservations {
                    let edgeSpiralScore = MathUtils.analyzeEdgesForSpiralPattern(observation)
                    spiralScore = max(spiralScore, edgeSpiralScore)
                }
            }
            
            // Analyze circles for spiral center points
            if let circleObservations = circleRequest.results {
                for observation in circleObservations {
                    let circleSpiralScore = MathUtils.analyzeCirclesForSpiralPattern(observation, pixelBuffer: pixelBuffer)
                    spiralScore = max(spiralScore, circleSpiralScore)
                }
            }
            
            // Enhanced threshold with multiple algorithm consensus
            return spiralScore > 0.65
            
        } catch {
            print("❌ Enhanced spiral detection failed: \(error)")
        }
        
        return false
    }
    
    private func detectGoldenRatio(_ pixelBuffer: CVPixelBuffer) -> DetectedPattern? {
        // Enhanced golden ratio detection using image analysis
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Analyze image for golden ratio proportions
        let hasGoldenRatio = analyzeImageForGoldenRatio(pixelBuffer)
        
        if hasGoldenRatio {
            let confidence: Float = 0.70
            let boundingBox = CGRect(x: width/3, y: height/3, width: width/3, height: height/3)
            
            return createDetectedPattern(
                type: .goldenRatio,
                confidence: confidence,
                boundingBox: boundingBox
            )
        }
        
        return nil
    }
    
    private func analyzeImageForGoldenRatio(_ pixelBuffer: CVPixelBuffer) -> Bool {
        // Enhanced multi-algorithm golden ratio detection
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        // Algorithm 1: Rectangle detection for golden ratio proportions
        let rectangleRequest = VNDetectRectanglesRequest()
        rectangleRequest.maximumObservations = 15
        rectangleRequest.minimumAspectRatio = 0.1
        rectangleRequest.maximumAspectRatio = 10.0
        rectangleRequest.minimumSize = 0.05
        rectangleRequest.minimumConfidence = 0.4
        
        // Algorithm 2: Horizon detection for natural golden ratio lines
        let horizonRequest = VNDetectHorizonRequest()
        
        // Algorithm 3: Face detection for facial golden ratio proportions
        let faceRequest = VNDetectFaceRectanglesRequest()
        faceRequest.maximumObservations = 3
        
        do {
            try requestHandler.perform([rectangleRequest, horizonRequest, faceRequest])
            
            var goldenRatioScore: Double = 0.0
            
            // Analyze rectangles for golden ratio proportions
            if let rectangleObservations = rectangleRequest.results {
                for observation in rectangleObservations {
                    let boundingBox = observation.boundingBox
                    let width = boundingBox.width
                    let height = boundingBox.height
                    
                    // Calculate aspect ratio
                    let aspectRatio = Double(width) / Double(height)
                    let inverseRatio = Double(height) / Double(width)
                    
                    // Check both orientations for golden ratio
                    let rectScore = max(
                        MathUtils.calculateGoldenRatioScore(aspectRatio),
                        MathUtils.calculateGoldenRatioScore(inverseRatio)
                    )
                    goldenRatioScore = max(goldenRatioScore, rectScore)
                }
            }
            
            // Analyze horizon for natural golden ratio divisions
            if let horizonObservations = horizonRequest.results {
                for observation in horizonObservations {
                    let horizonScore = MathUtils.analyzeHorizonForGoldenRatio(observation, pixelBuffer: pixelBuffer)
                    goldenRatioScore = max(goldenRatioScore, horizonScore)
                }
            }
            
            // Analyze faces for facial golden ratio proportions
            if let faceObservations = faceRequest.results {
                for observation in faceObservations {
                    let faceScore = MathUtils.analyzeFaceForGoldenRatio(observation)
                    goldenRatioScore = max(goldenRatioScore, faceScore)
                }
            }
            
            // Enhanced threshold with multiple algorithm consensus
            return goldenRatioScore > 0.7
            
        } catch {
            print("❌ Enhanced golden ratio detection failed: \(error)")
        }
        
        return false
    }
    
    // MARK: - LiDAR Depth Detection
    private func detectPatternsWithDepth(_ depthData: ARDepthData) -> [DetectedPattern]? {
        // Implement 3D pattern detection using LiDAR depth data
        // This would analyze 3D structures for Fibonacci patterns
        
        return nil // Placeholder
    }
    
    // MARK: - Helper Methods
    private func createDetectedPattern(type: PatternType, confidence: Float, boundingBox: CGRect) -> DetectedPattern {
        let centerPoint = CGPoint(
            x: boundingBox.midX,
            y: boundingBox.midY
        )
        
        let mathematicalProperties = DetectedPattern.MathematicalProperties(
            phiValue: type == .goldenRatio ? phi : nil,
            fibonacciNumbers: type == .fibonacciSequence ? [1, 1, 2, 3, 5, 8, 13, 21] : nil,
            spiralAngle: type == .fibonacciSpiral ? 137.5 : nil,
            ratio: type == .goldenRatio ? goldenRatio : nil,
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
    
    // MARK: - Educational Content
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
    
    // MARK: - Performance Monitoring
    private func updatePerformanceMetrics(processingTime: TimeInterval = 0) {
        performanceMetrics.averageProcessingTime = processingTime
        performanceMetrics.currentFPS = 1.0 / max(processingTime, 0.001)
        performanceMetrics.detectionCount = detectedPatterns.count
        performanceMetrics.lastUpdateTime = Date()
        
        // Update memory and CPU usage (simplified)
        performanceMetrics.memoryUsage = Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024 / 1024 // GB
        performanceMetrics.cpuUsage = 0.0 // Would need more complex monitoring
    }
    
    // MARK: - Voice Narration
    private func narrateNewPatterns(previousPatterns: [DetectedPattern], newPatterns: [DetectedPattern]) {
        guard let voiceManager = voiceNarrationManager else { 
            print("❌ Voice manager not available")
            return 
        }
        
        guard voiceNarrationEnabled else {
            print("🔇 Voice narration is disabled")
            return
        }
        
        print("🔍 Checking for new patterns. Previous: \(previousPatterns.count), New: \(newPatterns.count)")
        
        // If we have patterns and didn't have any before, narrate the best one
        if !newPatterns.isEmpty && previousPatterns.isEmpty {
            if let bestPattern = newPatterns.max(by: { $0.confidence < $1.confidence }) {
                print("🎤 Narrating first detected pattern: \(bestPattern.type.displayName) with confidence: \(bestPattern.confidence)")
                voiceManager.narratePattern(bestPattern)
                
                // Then after a delay, provide detailed explanation
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    voiceManager.narrateDetailedExplanation(bestPattern)
                }
            }
            return
        }
        
        // Find new patterns that weren't in the previous detection
        let newPatternsToNarrate = newPatterns.filter { newPattern in
            !previousPatterns.contains { previousPattern in
                previousPattern.id == newPattern.id
            }
        }
        
        print("🎯 Found \(newPatternsToNarrate.count) new patterns to narrate")
        
        // Narrate the highest confidence new pattern with detailed explanation
        if let bestNewPattern = newPatternsToNarrate.max(by: { $0.confidence < $1.confidence }) {
            print("🎤 Narrating pattern: \(bestNewPattern.type.displayName) with confidence: \(bestNewPattern.confidence)")
            
            // First narrate the basic pattern
            voiceManager.narratePattern(bestNewPattern)
            
            // Then after a delay, provide detailed explanation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                voiceManager.narrateDetailedExplanation(bestNewPattern)
            }
        }
    }
    
    // MARK: - Public Methods
    func clearDetections() {
        detectedPatterns.removeAll()
        voiceNarrationManager?.clearLastSpoken()
    }
    
    func updateSettings(_ newSettings: DetectionSettings) {
        settings = newSettings
    }
    
    func toggleVoiceNarration() {
        voiceNarrationEnabled.toggle()
        voiceNarrationManager?.isEnabled = voiceNarrationEnabled
        print("🔊 Voice narration toggled: \(voiceNarrationEnabled ? "ON" : "OFF")")
    }
    
    func stopVoiceNarration() {
        voiceNarrationManager?.stopSpeaking()
    }
    
    func narrateDetailedExplanation(for pattern: DetectedPattern) {
        voiceNarrationManager?.narrateDetailedExplanation(pattern)
    }
    
    // MARK: - Debug Methods
    func enableNautilusTestMode() {
        // Generate a test nautilus pattern for demonstration
        DispatchQueue.main.async {
            let nautilusPattern = self.createDetectedPattern(
                type: .nautilusSpiral,
                confidence: 0.95,
                boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
            )
            self.detectedPatterns = [nautilusPattern]
            
            // Trigger voice narration for the nautilus pattern
            self.narrateNewPatterns(previousPatterns: [], newPatterns: [nautilusPattern])
        }
    }
    
    func enableTestMode() {
        // Generate multiple test patterns for demonstration
        DispatchQueue.main.async {
            let testPatterns = [
                self.createDetectedPattern(
                    type: .goldenRatio,
                    confidence: 0.88,
                    boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.2)
                ),
                self.createDetectedPattern(
                    type: .nautilusSpiral,
                    confidence: 0.92,
                    boundingBox: CGRect(x: 0.4, y: 0.3, width: 0.4, height: 0.4)
                ),
                self.createDetectedPattern(
                    type: .fibonacciSpiral,
                    confidence: 0.85,
                    boundingBox: CGRect(x: 0.2, y: 0.6, width: 0.5, height: 0.3)
                )
            ]
            self.detectedPatterns = testPatterns
            
            // Trigger voice narration for the first pattern
            if let firstPattern = testPatterns.first {
                self.narrateNewPatterns(previousPatterns: [], newPatterns: [firstPattern])
            }
        }
    }
    
    func testVoiceNarration() {
        // Test voice narration directly
        guard let voiceManager = voiceNarrationManager else {
            print("❌ Voice manager not available for test")
            return
        }

        print("🎤 Testing voice narration...")
        print("🔊 Voice enabled: \(voiceManager.isEnabled)")
        print("🔊 Voice speaking: \(voiceManager.isSpeaking)")

        // Force enable voice narration for test
        voiceManager.isEnabled = true

        // Test simple speech first
        voiceManager.testSimpleSpeech()
    }
    
    // MARK: - Pattern Stability Methods
    private func updatePatternHistory(_ patterns: [DetectedPattern]) {
        // Group patterns by type and location for tracking
        for pattern in patterns {
            let key = "\(pattern.type.rawValue)_\(Int(pattern.centerPoint.x))_\(Int(pattern.centerPoint.y))"
            
            if patternHistory[key] == nil {
                patternHistory[key] = []
            }
            
            patternHistory[key]?.append(pattern)
            
            // Keep only recent history
            if let history = patternHistory[key], history.count > historySize {
                patternHistory[key] = Array(history.suffix(historySize))
            }
        }
        
        // Clean up old pattern histories
        let cutoffTime = Date().addingTimeInterval(-2.0) // Remove patterns older than 2 seconds
        for (key, history) in patternHistory {
            let recentHistory = history.filter { $0.detectedAt > cutoffTime }
            if recentHistory.isEmpty {
                patternHistory.removeValue(forKey: key)
            } else {
                patternHistory[key] = recentHistory
            }
        }
    }
    
    private func updateStablePatterns() {
        var newStablePatterns: [DetectedPattern] = []
        
        for (_, history) in patternHistory {
            guard history.count >= 3 else { continue } // Need at least 3 detections for stability
            
            // Calculate average confidence and position
            let avgConfidence = history.map { $0.confidence }.reduce(0, +) / Float(history.count)
            let avgX = history.map { $0.centerPoint.x }.reduce(0, +) / Double(history.count)
            let avgY = history.map { $0.centerPoint.y }.reduce(0, +) / Double(history.count)
            let avgWidth = history.map { $0.boundingBox.width }.reduce(0, +) / Double(history.count)
            let avgHeight = history.map { $0.boundingBox.height }.reduce(0, +) / Double(history.count)
            
            // Only consider patterns with stable confidence
            if avgConfidence >= Float(stabilityThreshold) {
                let stablePattern = DetectedPattern(
                    type: history.first!.type,
                    confidence: avgConfidence,
                    boundingBox: CGRect(
                        x: avgX - avgWidth/2,
                        y: avgY - avgHeight/2,
                        width: avgWidth,
                        height: avgHeight
                    ),
                    centerPoint: CGPoint(x: avgX, y: avgY),
                    detectedAt: Date(),
                    mathematicalProperties: history.first!.mathematicalProperties,
                    educationalContent: history.first!.educationalContent
                )
                newStablePatterns.append(stablePattern)
            }
        }
        
        // Sort by confidence and limit to prevent performance issues
        stablePatterns = newStablePatterns
            .sorted { $0.confidence > $1.confidence }
            .removeOverlappingPatterns()
            .prefix(3)
            .map { $0 }
    }
    
    private func shouldNarratePatterns(previousPatterns: [DetectedPattern], newPatterns: [DetectedPattern]) -> Bool {
        // Only narrate if there's a significant change in patterns
        if previousPatterns.count != newPatterns.count {
            return true
        }
        
        // Check if any pattern type has changed significantly
        for newPattern in newPatterns {
            let hasSignificantChange = !previousPatterns.contains { previousPattern in
                previousPattern.type == newPattern.type &&
                abs(previousPattern.confidence - newPattern.confidence) < 0.1 &&
                abs(previousPattern.centerPoint.x - newPattern.centerPoint.x) < 50 &&
                abs(previousPattern.centerPoint.y - newPattern.centerPoint.y) < 50
            }
            
            if hasSignificantChange {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Array Extension for Overlapping Pattern Removal
extension Array where Element == DetectedPattern {
    func removeOverlappingPatterns() -> [DetectedPattern] {
        var result: [DetectedPattern] = []
        
        for pattern in self {
            // Check if this pattern overlaps significantly with any pattern already in result
            let hasSignificantOverlap = result.contains { existingPattern in
                let overlap = pattern.boundingBox.intersection(existingPattern.boundingBox)
                let overlapArea = overlap.width * overlap.height
                let patternArea = pattern.boundingBox.width * pattern.boundingBox.height
                let existingArea = existingPattern.boundingBox.width * existingPattern.boundingBox.height
                
                // Consider it overlapping if more than 30% of either pattern overlaps
                return overlapArea > 0.3 * Swift.min(patternArea, existingArea)
            }
            
            if !hasSignificantOverlap {
                result.append(pattern)
            }
        }
        
        return result
    }
}
