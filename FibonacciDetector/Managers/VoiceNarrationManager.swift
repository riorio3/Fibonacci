import Foundation
import AVFoundation
import Combine

@MainActor
class VoiceNarrationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isSpeaking = false
    @Published var isEnabled = true
    @Published var speechRate: Float = 0.5
    @Published var speechVolume: Float = 0.8
    
    // MARK: - Private Properties
    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenPattern: String = ""
    private var speechTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Spatial awareness and smart repetition prevention
    private var spokenPatterns: [String: Date] = [:] // Track what was spoken and when
    private var lastSpokenLocation: CGPoint? = nil
    private let spatialThreshold: CGFloat = 100.0 // Minimum distance between spoken patterns
    private let timeThreshold: TimeInterval = 10.0 // Minimum time between same pattern types
    
    // MARK: - Voice Settings
    private let voice: AVSpeechSynthesisVoice
    private let minimumIntervalBetweenSpeeches: TimeInterval = 5.0 // Prevent spam - increased for better UX
    
    override init() {
        // Try to find the most natural-sounding voice available
        if let enhancedVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { 
            $0.name.contains("Enhanced") || $0.name.contains("Premium") || $0.name.contains("Neural")
        }) {
            self.voice = enhancedVoice
        } else if let australianFemaleVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { 
            $0.language.hasPrefix("en-AU") && $0.gender == .female 
        }) {
            self.voice = australianFemaleVoice
        } else if let australianVoice = AVSpeechSynthesisVoice(language: "en-AU") {
            self.voice = australianVoice
        } else if let usFemaleVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { 
            $0.language.hasPrefix("en-US") && $0.gender == .female 
        }) {
            self.voice = usFemaleVoice
        } else {
            // Fallback to any available voice
            self.voice = AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice.speechVoices().first!
        }
        
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    func narratePattern(_ pattern: DetectedPattern) {
        guard isEnabled else { 
            print("🔇 Voice narration is disabled")
            return 
        }
        
        // Smart repetition prevention with spatial awareness
        guard shouldSpeakPattern(pattern) else { 
            print("🔇 Pattern filtered by smart repetition prevention")
            return 
        }
        
        let patternDescription = generatePatternDescription(pattern)
        print("🎤 Speaking pattern: \(patternDescription)")
        
        // Stop any current speech
        stopSpeaking()
        
        // Create speech utterance
        let utterance = AVSpeechUtterance(string: patternDescription)
        configureUtterance(utterance)
        
        // Speak the pattern
        synthesizer.speak(utterance)
        
        // Update tracking
        updatePatternTracking(pattern)
    }
    
    // MARK: - Smart Pattern Filtering
    private func shouldSpeakPattern(_ pattern: DetectedPattern) -> Bool {
        let patternKey = "\(pattern.type.rawValue)_\(Int(pattern.centerPoint.x))_\(Int(pattern.centerPoint.y))"
        let now = Date()
        
        // Check if we've spoken this exact pattern recently
        if let lastSpoken = spokenPatterns[patternKey],
           now.timeIntervalSince(lastSpoken) < timeThreshold {
            return false
        }
        
        // Check spatial proximity to last spoken pattern
        if let lastLocation = lastSpokenLocation {
            let distance = sqrt(pow(pattern.centerPoint.x - lastLocation.x, 2) + 
                              pow(pattern.centerPoint.y - lastLocation.y, 2))
            if distance < spatialThreshold {
                return false
            }
        }
        
        // Check if we've spoken this pattern type recently anywhere
        let patternTypeKey = pattern.type.rawValue
        if let lastSpoken = spokenPatterns[patternTypeKey],
           now.timeIntervalSince(lastSpoken) < timeThreshold {
            return false
        }
        
        return true
    }
    
    private func updatePatternTracking(_ pattern: DetectedPattern) {
        let patternKey = "\(pattern.type.rawValue)_\(Int(pattern.centerPoint.x))_\(Int(pattern.centerPoint.y))"
        let patternTypeKey = pattern.type.rawValue
        let now = Date()
        
        // Update tracking
        spokenPatterns[patternKey] = now
        spokenPatterns[patternTypeKey] = now
        lastSpokenLocation = pattern.centerPoint
        
        // Clean up old entries to prevent memory buildup
        cleanupOldEntries()
    }
    
    private func cleanupOldEntries() {
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-timeThreshold * 2)
        
        spokenPatterns = spokenPatterns.filter { _, date in
            date > cutoffTime
        }
    }
    
    func narrateDetailedExplanation(_ pattern: DetectedPattern) {
        guard isEnabled else { return }
        
        let detailedExplanation = generateDetailedExplanation(pattern)
        guard detailedExplanation != lastSpokenPattern else { return }
        
        print("🎤 Speaking detailed explanation: \(detailedExplanation)")
        
        stopSpeaking()
        
        let utterance = AVSpeechUtterance(string: detailedExplanation)
        configureUtterance(utterance)
        utterance.rate = speechRate * 0.8 // Slightly slower for detailed explanations
        
        synthesizer.speak(utterance)
        lastSpokenPattern = detailedExplanation
        
        speechTimer?.invalidate()
        speechTimer = Timer.scheduledTimer(withTimeInterval: minimumIntervalBetweenSpeeches, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.lastSpokenPattern = ""
            }
        }
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func clearLastSpoken() {
        lastSpokenPattern = ""
    }
    
    func testSimpleSpeech() {
        guard isEnabled else { 
            print("🔇 Voice narration is disabled")
            return 
        }
        
        print("🎤 Testing simple speech...")
        
        // Stop any current speech
        stopSpeaking()
        
        // Create simple test utterance
        let utterance = AVSpeechUtterance(string: "Hello, voice narration is working")
        configureUtterance(utterance)
        
        // Speak the test message
        synthesizer.speak(utterance)
    }
    
    // MARK: - Private Methods
    private func setupAudioSession() {
        do {
            // Set up audio session for speech synthesis
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session setup successful")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            // Try minimal fallback setup
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                print("✅ Fallback audio session setup successful")
            } catch {
                print("❌ Fallback audio session setup failed: \(error)")
            }
        }
    }
    
    private func configureUtterance(_ utterance: AVSpeechUtterance) {
        utterance.voice = voice
        utterance.rate = speechRate * 0.7 // Slower, more natural pace
        utterance.volume = speechVolume
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch for more engaging tone
        utterance.preUtteranceDelay = 0.2 // Slight pause before speaking
        utterance.postUtteranceDelay = 0.3 // Pause after speaking
    }
    
    private func generatePatternDescription(_ pattern: DetectedPattern) -> String {
        let confidence = Int(pattern.confidence * 100)
        let patternType = pattern.type
        
        switch patternType {
        case .fibonacciSpiral:
            return generateSpiralDescription(pattern, confidence: confidence)
        case .goldenRatio:
            return generateGoldenRatioDescription(pattern, confidence: confidence)
        case .fibonacciSequence:
            return generateSequenceDescription(pattern, confidence: confidence)
        case .phiGrid:
            return generatePhiGridDescription(pattern, confidence: confidence)
        case .sunflowerSpiral:
            return generateSunflowerDescription(pattern, confidence: confidence)
        case .pineconeSpiral:
            return generatePineconeDescription(pattern, confidence: confidence)
        case .shellSpiral:
            return generateShellDescription(pattern, confidence: confidence)
        case .nautilusSpiral:
            return generateNautilusDescription(pattern, confidence: confidence)
        case .leafArrangement:
            return generateLeafDescription(pattern, confidence: confidence)
        }
    }
    
    private func generateSpiralDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Fibonacci spiral detected. \(confidence)% confidence."
    }
    
    private func generateGoldenRatioDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Golden ratio detected. \(confidence)% confidence."
    }
    
    private func generateSequenceDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Fibonacci sequence detected. \(confidence)% confidence."
    }
    
    private func generatePhiGridDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Phi grid detected. \(confidence)% confidence."
    }
    
    private func generateSunflowerDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Sunflower spiral detected. \(confidence)% confidence."
    }
    
    private func generatePineconeDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Pinecone spiral detected. \(confidence)% confidence."
    }
    
    private func generateShellDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Shell spiral detected. \(confidence)% confidence."
    }
    
    private func generateNautilusDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Nautilus spiral detected. \(confidence)% confidence."
    }
    
    private func generateLeafDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Leaf arrangement detected. \(confidence)% confidence."
    }
    
    private func generateDetailedExplanation(_ pattern: DetectedPattern) -> String {
        return generateDetailedPatternDescription(pattern)
    }
    
    private func generateDetailedPatternDescription(_ pattern: DetectedPattern) -> String {
        let confidence = Int(pattern.confidence * 100)
        let patternType = pattern.type
        
        switch patternType {
        case .fibonacciSpiral:
            return "This is a beautiful Fibonacci spiral, found in nature's most elegant designs. The spiral grows at the golden ratio of 1.618, creating perfect mathematical harmony. You can see this same pattern in nautilus shells and galaxy arms."
        case .goldenRatio:
            return "You've found the golden ratio! This divine proportion of 1.618 appears throughout nature and art. It's considered the most aesthetically pleasing ratio, found in everything from flower petals to architectural masterpieces."
        case .fibonacciSequence:
            return "A Fibonacci sequence pattern! Each number is the sum of the two before it: 1, 1, 2, 3, 5, 8, 13. This sequence appears in flower petal counts, pinecone spirals, and even the branching of trees."
        case .phiGrid:
            return "This is a phi grid pattern, based on the golden ratio. It creates perfect proportions that our eyes find naturally beautiful, used by artists and architects for centuries."
        case .sunflowerSpiral:
            return "A sunflower spiral! The seeds are arranged in perfect Fibonacci spirals, maximizing space efficiency. This mathematical pattern ensures every seed gets optimal sunlight and space."
        case .pineconeSpiral:
            return "Pinecone spiral detected! The scales follow Fibonacci spirals, creating the most efficient packing arrangement. Nature's engineering at its finest."
        case .shellSpiral:
            return "A shell spiral pattern! This logarithmic spiral grows at the golden ratio, creating the perfect balance of strength and beauty found in nautilus shells."
        case .nautilusSpiral:
            return "The classic nautilus spiral! This perfect logarithmic spiral grows at exactly the golden ratio, creating one of nature's most beautiful mathematical patterns."
        case .leafArrangement:
            return "Leaf arrangement following Fibonacci patterns! Plants use this mathematical sequence to ensure optimal sunlight exposure for each leaf, maximizing photosynthesis efficiency."
        }
    }
    
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceNarrationManager: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}
