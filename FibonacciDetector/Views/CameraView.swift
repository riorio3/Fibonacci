import SwiftUI
import ARKit
import AVFoundation

struct CameraView: View {
    @ObservedObject var arKitManager: ARKitManager
    @ObservedObject var fibonacciDetector: FibonacciDetector
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // AR Camera View with zoom support
            ARCameraView(arKitManager: arKitManager, fibonacciDetector: fibonacciDetector, zoomScale: zoomScale)
                .ignoresSafeArea()
                .scaleEffect(zoomScale)
                .clipped() // Prevent black bars when zooming
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastZoomScale
                            lastZoomScale = value
                            let newScale = zoomScale * delta
                            zoomScale = min(max(newScale, 1.0), 3.0) // Limit zoom between 1x and 3x
                        }
                        .onEnded { _ in
                            lastZoomScale = 1.0
                        }
                )
            
            // 2D Pattern Overlays - positioned directly on detected patterns
            PatternOverlayView(
                patterns: fibonacciDetector.detectedPatterns,
                overlayType: fibonacciDetector.settings.overlayType,
                isVisible: true,
                onPatternTap: { pattern in
                    fibonacciDetector.narrateDetailedExplanation(for: pattern)
                }
            )
            .scaleEffect(zoomScale) // Scale overlays with zoom
            
            // Zoom controls
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        // Zoom in button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                zoomScale = min(zoomScale * 1.2, 3.0)
                            }
                        }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        // Zoom out button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                zoomScale = max(zoomScale / 1.2, 1.0)
                            }
                        }) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        // Reset zoom button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                zoomScale = 1.0
                            }
                        }) {
                            Text("1x")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.trailing, 20)
                }
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

struct ARCameraView: UIViewRepresentable {
    @ObservedObject var arKitManager: ARKitManager
    @ObservedObject var fibonacciDetector: FibonacciDetector
    let zoomScale: CGFloat
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView()
        
        // Configure AR view
        arView.session = arKitManager.arSession
        arView.delegate = context.coordinator
        arView.automaticallyUpdatesLighting = true
        arView.antialiasingMode = .multisampling4X
        
        // Enable debug options for development
        #if DEBUG
        arView.showsStatistics = false
        arView.debugOptions = []
        #endif
        
        // Set up scene
        arView.scene = SCNScene()
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update AR view based on state changes
        if arKitManager.isSessionRunning {
            uiView.session = arKitManager.arSession
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARCameraView
        private var lastFrameTime = Date()
        private let processingInterval: TimeInterval = 1.0 // 1 FPS processing to reduce memory pressure
        
        init(_ parent: ARCameraView) {
            self.parent = parent
        }
        
        // MARK: - ARSCNViewDelegate
        nonisolated func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
            // Process frames at controlled rate for performance
            let now = Date()
            guard now.timeIntervalSince(lastFrameTime) >= processingInterval else { return }
            
            lastFrameTime = now
            
            // Process frame for Fibonacci patterns
            Task { @MainActor in
                guard let frame = parent.arKitManager.getCurrentFrame() else { return }
                parent.fibonacciDetector.processFrame(
                    frame.capturedImage,
                    depthData: parent.arKitManager.depthData
                )
            }
        }
        
    }
}

// MARK: - ARSCNView Extensions
extension ARSCNView {
    func setupForFibonacciDetection() {
        // Configure for optimal Fibonacci pattern detection
        automaticallyUpdatesLighting = true
        antialiasingMode = .multisampling4X
        
        // Enable depth testing for better overlay rendering
        scene.rootNode.castsShadow = true
        
        // Set up lighting
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .ambient
        lightNode.light?.intensity = 1000
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)
    }
}
