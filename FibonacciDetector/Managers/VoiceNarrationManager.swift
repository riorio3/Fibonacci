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
        return "Spiral detected!"
    }
    
    private func generateGoldenRatioDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "You found the golden ratio!"
    }
    
    private func generateSequenceDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Fibonacci sequence found!"
    }
    
    private func generatePhiGridDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Phi grid detected!"
    }
    
    private func generateSunflowerDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Sunflower spiral found!"
    }
    
    private func generatePineconeDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Pinecone spiral detected!"
    }
    
    private func generateShellDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Shell spiral found!"
    }
    
    private func generateNautilusDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Nautilus spiral detected!"
    }
    
    private func generateLeafDescription(_ pattern: DetectedPattern, confidence: Int) -> String {
        return "Leaf arrangement found!"
    }
    
    private func generateDetailedExplanation(_ pattern: DetectedPattern) -> String {
        return generateDetailedPatternDescription(pattern)
    }
    
    private func generateDetailedPatternDescription(_ pattern: DetectedPattern) -> String {
        let patternType = pattern.type
        
        switch patternType {
        case .fibonacciSpiral:
            return generateQuirkySpiralSaying()
        case .goldenRatio:
            return generateQuirkyGoldenRatioSaying()
        case .fibonacciSequence:
            return generateQuirkySequenceSaying()
        case .phiGrid:
            return generateQuirkyPhiGridSaying()
        case .sunflowerSpiral:
            return generateQuirkySunflowerSaying()
        case .pineconeSpiral:
            return generateQuirkyPineconeSaying()
        case .shellSpiral:
            return generateQuirkyShellSaying()
        case .nautilusSpiral:
            return generateQuirkyNautilusSaying()
        case .leafArrangement:
            return generateQuirkyLeafSaying()
        }
    }
    
    // MARK: - Quirky Pattern Sayings
    private func generateQuirkySpiralSaying() -> String {
        let sayings = [
            "Spiral detected! Nature's way of saying 'let's get twisty!'",
            "Fibonacci spiral found! It's like nature's own corkscrew.",
            "Spiral alert! This is how the universe does a twirl.",
            "Spiral spotted! Even math can be a little dizzy sometimes.",
            "Spiral detected! Nature's original spiral staircase.",
            "Spiral found! It's the universe's way of saying 'let's dance!'"
        ]
        return sayings.randomElement() ?? "Spiral detected!"
    }
    
    private func generateQuirkyGoldenRatioSaying() -> String {
        let sayings = [
            "You found the golden ratio! Nature's favorite number.",
            "Golden ratio detected! It's like finding mathematical gold.",
            "You found the golden ratio! Even math has its golden moments.",
            "Golden ratio spotted! Nature's way of saying 'just right!'",
            "You found the golden ratio! The universe's perfect proportion.",
            "Golden ratio detected! It's the math equivalent of a perfect sunset."
        ]
        return sayings.randomElement() ?? "You found the golden ratio!"
    }
    
    private func generateQuirkySequenceSaying() -> String {
        let sayings = [
            "Fibonacci sequence found! Math that actually makes sense.",
            "Sequence detected! Nature's counting system in action.",
            "Fibonacci sequence spotted! It's like nature's own calculator.",
            "Sequence found! Even numbers can be beautiful.",
            "Fibonacci sequence detected! Nature's way of counting to infinity.",
            "Sequence spotted! It's the universe's favorite number pattern."
        ]
        return sayings.randomElement() ?? "Fibonacci sequence detected!"
    }
    
    private func generateQuirkyPhiGridSaying() -> String {
        let sayings = [
            "Phi grid detected! Nature's own grid system.",
            "Grid pattern found! Even nature needs organization.",
            "Phi grid spotted! It's like nature's own graph paper.",
            "Grid detected! The universe's way of staying organized.",
            "Phi grid found! Nature's perfect planning system.",
            "Grid pattern spotted! Even math likes to stay in line."
        ]
        return sayings.randomElement() ?? "Phi grid detected!"
    }
    
    private func generateQuirkySunflowerSaying() -> String {
        let sayings = [
            "Sunflower spiral found! Nature's own sunflower power.",
            "Sunflower pattern detected! It's like a mathematical flower.",
            "Sunflower spiral spotted! Nature's way of saying 'sunny side up!'",
            "Sunflower pattern found! Even flowers can do math.",
            "Sunflower spiral detected! Nature's original sunflower seeds.",
            "Sunflower pattern spotted! It's the universe's way of blooming."
        ]
        return sayings.randomElement() ?? "Sunflower spiral detected!"
    }
    
    private func generateQuirkyPineconeSaying() -> String {
        let sayings = [
            "Pinecone spiral found! Nature's own pine cone power.",
            "Pinecone pattern detected! It's like a mathematical pine tree.",
            "Pinecone spiral spotted! Nature's way of saying 'pine fresh!'",
            "Pinecone pattern found! Even pine trees can do math.",
            "Pinecone spiral detected! Nature's original pine cone seeds.",
            "Pinecone pattern spotted! It's the universe's way of growing."
        ]
        return sayings.randomElement() ?? "Pinecone spiral detected!"
    }
    
    private func generateQuirkyShellSaying() -> String {
        let sayings = [
            "Shell spiral found! Nature's own shell game.",
            "Shell pattern detected! It's like a mathematical seashell.",
            "Shell spiral spotted! Nature's way of saying 'shell yeah!'",
            "Shell pattern found! Even seashells can do math.",
            "Shell spiral detected! Nature's original shell collection.",
            "Shell pattern spotted! It's the universe's way of shelling out."
        ]
        return sayings.randomElement() ?? "Shell spiral detected!"
    }
    
    private func generateQuirkyNautilusSaying() -> String {
        let sayings = [
            "Nautilus spiral found! Nature's own nautilus power.",
            "Nautilus pattern detected! It's like a mathematical nautilus.",
            "Nautilus spiral spotted! Nature's way of saying 'nautilus up!'",
            "Nautilus pattern found! Even nautiluses can do math.",
            "Nautilus spiral detected! Nature's original nautilus shell.",
            "Nautilus pattern spotted! It's the universe's way of nautilusing."
        ]
        return sayings.randomElement() ?? "Nautilus spiral detected!"
    }
    
    private func generateQuirkyLeafSaying() -> String {
        let sayings = [
            "Leaf arrangement found! Nature's own leaf system.",
            "Leaf pattern detected! It's like a mathematical leaf.",
            "Leaf arrangement spotted! Nature's way of saying 'leaf it to me!'",
            "Leaf pattern found! Even leaves can do math.",
            "Leaf arrangement detected! Nature's original leaf collection.",
            "Leaf pattern spotted! It's the universe's way of leafing out."
        ]
        return sayings.randomElement() ?? "Leaf arrangement detected!"
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
