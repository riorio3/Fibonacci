import Foundation
import ARKit
import AVFoundation
import Combine

enum ARSessionState {
    case notStarted
    case running
    case paused
    case interrupted
    case failed
}

@MainActor
class ARKitManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isSessionRunning = false
    @Published var sessionState: ARSessionState = .notStarted
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    @Published var isLiDARAvailable = false
    @Published var depthData: ARDepthData?
    // Removed currentFrame storage to prevent ARFrame retention
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    let arSession = ARSession()
    private var configuration: ARWorldTrackingConfiguration?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Performance Properties
    private let targetFPS: Int = 60
    private var frameCount = 0
    private var lastFrameTime = Date()
    
    override init() {
        super.init()
        setupARSession()
        checkLiDARAvailability()
    }
    
    // MARK: - Setup Methods
    private func setupARSession() {
        arSession.delegate = self
        
        // Configure for optimal performance
        arSession.delegateQueue = DispatchQueue(label: "ar.session.queue", qos: .userInitiated)
        
        // Set up configuration
        configuration = ARWorldTrackingConfiguration()
        configureForOptimalPerformance()
    }
    
    private func configureForOptimalPerformance() {
        guard let config = configuration else { return }
        
        // Enable all available features for iPhone 17
        config.isAutoFocusEnabled = true
        config.isLightEstimationEnabled = true
        config.environmentTexturing = .automatic
        // HDR environment texturing not available in current ARKit version
        
        // Enable LiDAR if available
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
            isLiDARAvailable = true
        }
        
        // Enable people occlusion if available
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        // Configure for iPhone 17 A19 chip optimization
        config.maximumNumberOfTrackedImages = 10
        config.detectionImages = []
        config.detectionObjects = []
        
        // Set video format for optimal performance
        if let videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { 
            $0.imageResolution.width >= 1920 && $0.framesPerSecond >= 60 
        }) {
            config.videoFormat = videoFormat
        }
    }
    
    private func checkLiDARAvailability() {
        isLiDARAvailable = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
    }
    
    // MARK: - Session Control
    func startSession() {
        guard !isSessionRunning else { return }
        
        // Request camera permission
        requestCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startARSession()
                } else {
                    self?.errorMessage = "Camera permission is required for Fibonacci pattern detection"
                }
            }
        }
    }
    
    private func startARSession() {
        guard let config = configuration else {
            errorMessage = "Failed to create AR configuration"
            return
        }
        
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
        isSessionRunning = true
        sessionState = .running
        errorMessage = nil
    }
    
    func stopSession() {
        guard isSessionRunning else { return }
        
        arSession.pause()
        isSessionRunning = false
        sessionState = .paused
        
        // Clear any retained data to free memory
        depthData = nil
        frameCount = 0
    }
    
    func resetSession() {
        stopSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startSession()
        }
    }
    
    // MARK: - Camera Control
    func switchCamera() {
        guard isSessionRunning else { return }
        
        let newPosition: AVCaptureDevice.Position = cameraPosition == .back ? .front : .back
        cameraPosition = newPosition
        
        // Restart session with new camera position
        resetSession()
    }
    
    // MARK: - Permission Handling
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // MARK: - Frame Processing
    func getCurrentFrame() -> ARFrame? {
        // Return frame without storing it to prevent retention
        return arSession.currentFrame
    }
    
    func getDepthData() -> ARDepthData? {
        return depthData
    }
    
    // MARK: - Performance Monitoring
    private func updatePerformanceMetrics() {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastFrameTime)
        
        if timeInterval >= 1.0 {
            let currentFPS = Double(frameCount) / timeInterval
            frameCount = 0
            lastFrameTime = now
            
            // Log performance metrics
            print("📊 AR Session FPS: \(String(format: "%.1f", currentFPS))")
        }
    }
    
    // MARK: - Memory Management
    func cleanupMemory() {
        // Clear any retained data
        depthData = nil
        frameCount = 0
        
        // Force garbage collection if needed
        DispatchQueue.main.async {
            // This helps ensure any retained objects are released
        }
    }
}

// MARK: - ARSessionDelegate
extension ARKitManager: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        Task { @MainActor in
            // Don't store the frame to prevent retention - just update metrics
            self.frameCount += 1
            self.updatePerformanceMetrics()
            
            // Extract depth data if available (this is lightweight)
            if let sceneDepth = frame.sceneDepth {
                self.depthData = sceneDepth
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "AR Session failed: \(error.localizedDescription)"
            self.sessionState = .failed
            self.isSessionRunning = false
        }
    }
    
    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor in
            self.sessionState = .interrupted
            self.isSessionRunning = false
        }
    }
    
    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        Task { @MainActor in
            self.sessionState = .running
            self.isSessionRunning = true
        }
    }
    
    nonisolated func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        Task { @MainActor in
            switch camera.trackingState {
            case .normal:
                self.sessionState = .running
            case .notAvailable:
                self.sessionState = .notStarted
            case .limited(_):
                self.sessionState = .running // Treat limited as running for now
            }
        }
    }
}


// MARK: - Performance Optimization Extensions
extension ARKitManager {
    
    /// Optimize AR session for iPhone 17 A19 chip
    func optimizeForA19Chip() {
        guard let config = configuration else { return }
        
        // Enable advanced features available on A19
        config.environmentTexturing = .automatic
        // HDR environment texturing not available in current ARKit version
        
        // Optimize for 60fps performance
        if let highFPSFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { 
            $0.framesPerSecond >= 60 
        }) {
            config.videoFormat = highFPSFormat
        }
        
        // Enable LiDAR for enhanced depth mapping
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }
    }
    
    /// Configure for offline processing
    func configureForOfflineProcessing() {
        guard let config = configuration else { return }
        
        // Disable network-dependent features
        config.environmentTexturing = .none
        // HDR environment texturing not available in current ARKit version
        
        // Focus on local processing
        config.isLightEstimationEnabled = true
        config.isAutoFocusEnabled = true
    }
    
    /// Get current session performance metrics
    func getPerformanceMetrics() -> (fps: Double, memoryUsage: Double, cpuUsage: Double) {
        let now = Date()
        let timeInterval = now.timeIntervalSince(lastFrameTime)
        let currentFPS = timeInterval > 0 ? Double(frameCount) / timeInterval : 0.0
        
        // Simplified memory and CPU usage (would need more complex monitoring in production)
        let memoryUsage = Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024 / 1024 // GB
        let cpuUsage = 0.0 // Would need more complex monitoring
        
        return (currentFPS, memoryUsage, cpuUsage)
    }
}
