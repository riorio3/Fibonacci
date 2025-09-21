import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var arKitManager: ARKitManager
    @ObservedObject var fibonacciDetector: FibonacciDetector
    let onPatternDetected: (DetectedPattern) -> Void
    
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Top row - Essential controls only
            HStack(spacing: 12) {
                // Settings button
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Voice narration toggle
                Button(action: {
                    fibonacciDetector.toggleVoiceNarration()
                    print("🔊 Voice narration toggled: \(fibonacciDetector.voiceNarrationEnabled ? "ON" : "OFF")")
                }) {
                    Image(systemName: fibonacciDetector.voiceNarrationEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(fibonacciDetector.voiceNarrationEnabled ? Color.green.opacity(0.8) : Color.gray.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            
            // Detection status - compact
            HStack {
                Circle()
                    .fill(fibonacciDetector.isProcessing ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(fibonacciDetector.isProcessing ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: fibonacciDetector.isProcessing)
                
                Text(fibonacciDetector.isProcessing ? "Detecting..." : "Ready")
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(fibonacciDetector.detectedPatterns.count) patterns")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            // Pattern type display - only show when patterns are detected
            if !fibonacciDetector.detectedPatterns.isEmpty {
                PatternTypeDisplay(patterns: fibonacciDetector.detectedPatterns)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.7))
        )
        .sheet(isPresented: $showingSettings) {
            SettingsView(fibonacciDetector: fibonacciDetector)
        }
    }
}

// MARK: - Pattern Type Display
struct PatternTypeDisplay: View {
    let patterns: [DetectedPattern]
    
    // Get unique pattern types to avoid duplicates
    private var uniquePatternTypes: [PatternType] {
        let uniqueTypes = Set(patterns.map { $0.type })
        return Array(uniqueTypes).sorted { $0.displayName < $1.displayName }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(uniquePatternTypes.prefix(3), id: \.self) { patternType in
                PatternTypeBadge(patternType: patternType)
            }
            
            if uniquePatternTypes.count > 3 {
                Text("+\(uniquePatternTypes.count - 3)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.6))
                    )
            }
        }
    }
}

struct PatternTypeBadge: View {
    let patternType: PatternType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: getPatternIcon(for: patternType))
                .font(.caption2)
                .foregroundColor(patternType.primaryColor)
            
            Text(patternType.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(patternType.primaryColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(patternType.primaryColor.opacity(0.6), lineWidth: 1)
                )
        )
    }
    
    private func getPatternIcon(for type: PatternType) -> String {
        switch type {
        case .fibonacciSpiral, .nautilusSpiral, .shellSpiral, .sunflowerSpiral, .pineconeSpiral:
            return "spiral"
        case .goldenRatio:
            return "rectangle.3.group"
        case .fibonacciSequence:
            return "number"
        case .phiGrid:
            return "grid"
        case .leafArrangement:
            return "leaf"
        }
    }
}


// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var fibonacciDetector: FibonacciDetector
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Actions") {
                    Button("Clear All Detections") {
                        fibonacciDetector.clearDetections()
                        print("🧹 Cleared all detections")
                    }
                    .foregroundColor(.red)
                    
                    Button("Test Voice Narration") {
                        fibonacciDetector.testVoiceNarration()
                        print("🎤 Testing voice narration")
                    }
                    .foregroundColor(.green)
                    
                    Button("Test Pattern Tracking") {
                        fibonacciDetector.enableTestMode()
                        print("🎯 Testing pattern tracking")
                    }
                    .foregroundColor(.orange)
                    
                    Button("Test Nautilus Pattern") {
                        fibonacciDetector.enableNautilusTestMode()
                        print("🐚 Testing nautilus pattern")
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset to Defaults") {
                        fibonacciDetector.settings = DetectionSettings()
                        print("🔄 Reset to defaults")
                    }
                    .foregroundColor(.gray)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


