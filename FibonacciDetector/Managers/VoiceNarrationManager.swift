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
    
    // MARK: - Voice Settings
    private let voice: AVSpeechSynthesisVoice
    private let minimumIntervalBetweenSpeeches: TimeInterval = 3.0 // Prevent spam
    
    override init() {
        // Try to find an Australian female voice, fallback to any Australian voice
        if let australianFemaleVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { 
            $0.language.hasPrefix("en-AU") && $0.gender == .female 
        }) {
            self.voice = australianFemaleVoice
        } else if let australianVoice = AVSpeechSynthesisVoice(language: "en-AU") {
            self.voice = australianVoice
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
        
        // Prevent speaking the same pattern repeatedly
        let patternDescription = generatePatternDescription(pattern)
        guard patternDescription != lastSpokenPattern else { 
            print("🔇 Pattern already spoken recently: \(patternDescription)")
            return 
        }
        
        print("🎤 Speaking pattern: \(patternDescription)")
        
        // Stop any current speech
        stopSpeaking()
        
        // Create speech utterance
        let utterance = AVSpeechUtterance(string: patternDescription)
        configureUtterance(utterance)
        
        // Speak the pattern
        synthesizer.speak(utterance)
        lastSpokenPattern = patternDescription
        
        // Set a timer to allow speaking again after minimum interval
        speechTimer?.invalidate()
        speechTimer = Timer.scheduledTimer(withTimeInterval: minimumIntervalBetweenSpeeches, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.lastSpokenPattern = ""
            }
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
        utterance.rate = speechRate
        utterance.volume = speechVolume
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
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
        return "Tap for more details."
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
