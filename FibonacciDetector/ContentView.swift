import SwiftUI
import ARKit

struct ContentView: View {
    @StateObject private var arKitManager = ARKitManager()
    @StateObject private var fibonacciDetector = FibonacciDetector()
    @State private var showingEducationalPopup = false
    @State private var selectedPattern: DetectedPattern?
    
    var body: some View {
        ZStack {
            // Main camera view with AR overlays
            CameraView(arKitManager: arKitManager, fibonacciDetector: fibonacciDetector)
                .ignoresSafeArea()
            
            // Pattern detection border - bright green border when patterns are detected
            PatternDetectionBorderView(detectedPatterns: fibonacciDetector.detectedPatterns)
            
            // Control panel overlay
            VStack {
                Spacer()
                ControlPanelView(
                    arKitManager: arKitManager,
                    fibonacciDetector: fibonacciDetector,
                    onPatternDetected: { pattern in
                        selectedPattern = pattern
                        showingEducationalPopup = true
                    }
                )
                .padding()
            }
            
            // Educational popup
            if showingEducationalPopup, let pattern = selectedPattern {
                EducationalPopupView(
                    pattern: pattern,
                    isPresented: $showingEducationalPopup
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            arKitManager.startSession()
        }
        .onDisappear {
            arKitManager.stopSession()
        }
    }
}

#Preview {
    ContentView()
}

