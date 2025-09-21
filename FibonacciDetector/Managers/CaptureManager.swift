import Foundation
import UIKit
import Photos
import AVFoundation
import SwiftUI
import SceneKit
import ARKit

@MainActor
class CaptureManager: ObservableObject {
    // MARK: - Published Properties
    @Published var isCapturing = false
    @Published var capturedImages: [CapturedImage] = []
    @Published var showingShareSheet = false
    @Published var shareItems: [Any] = []
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let photoLibrary = PHPhotoLibrary.shared()
    private let imageCache = NSCache<NSString, UIImage>()
    
    // MARK: - Initialization
    init() {
        checkPhotoLibraryPermission()
        setupImageCache()
    }
    
    // MARK: - Permission Management
    private func checkPhotoLibraryPermission() {
        permissionStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    func requestPhotoLibraryPermission() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        await MainActor.run {
            permissionStatus = status
        }
    }
    
    // MARK: - Image Cache Setup
    private func setupImageCache() {
        imageCache.countLimit = 50
        imageCache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }
    
    // MARK: - Capture Methods
    func captureARFrame(
        from arView: ARSCNView,
        with patterns: [DetectedPattern],
        overlayType: OverlayType
    ) async {
        guard !isCapturing else { return }
        
        isCapturing = true
        
        do {
            // Capture the AR frame
            let capturedImage = try await captureARFrameImage(from: arView)
            
            // Add overlays
            let imageWithOverlays = try await addOverlaysToImage(
                capturedImage,
                patterns: patterns,
                overlayType: overlayType
            )
            
            // Create metadata
            let metadata = createImageMetadata(patterns: patterns)
            
            // Save to photo library
            _ = try await saveImageToPhotoLibrary(imageWithOverlays, metadata: metadata)
            
            // Add to captured images
            let capturedImageData = CapturedImage(
                image: imageWithOverlays,
                patterns: patterns,
                capturedAt: Date(),
                metadata: metadata
            )
            
            capturedImages.append(capturedImageData)
            
        } catch {
            print("❌ Failed to capture AR frame: \(error)")
        }
        
        isCapturing = false
    }
    
    private func captureARFrameImage(from arView: ARSCNView) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                // Capture the current AR frame
                guard let frame = arView.session.currentFrame else {
                    continuation.resume(throwing: CaptureError.noARFrame)
                    return
                }
                
                // Convert AR frame to UIImage
                let pixelBuffer = frame.capturedImage
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let context = CIContext()
                
                guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                    continuation.resume(throwing: CaptureError.imageConversionFailed)
                    return
                }
                
                let image = UIImage(cgImage: cgImage)
                continuation.resume(returning: image)
            }
        }
    }
    
    private func addOverlaysToImage(
        _ image: UIImage,
        patterns: [DetectedPattern],
        overlayType: OverlayType
    ) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let size = image.size
                let scale = image.scale
                
                UIGraphicsBeginImageContextWithOptions(size, false, scale)
                defer { UIGraphicsEndImageContext() }
                
                // Draw original image
                image.draw(in: CGRect(origin: .zero, size: size))
                
                // Draw overlays
                for pattern in patterns {
                    self.drawOverlayForPattern(
                        pattern,
                        overlayType: overlayType,
                        in: CGRect(origin: .zero, size: size)
                    )
                }
                
                guard let imageWithOverlays = UIGraphicsGetImageFromCurrentImageContext() else {
                    continuation.resume(throwing: CaptureError.overlayRenderingFailed)
                    return
                }
                
                continuation.resume(returning: imageWithOverlays)
            }
        }
    }
    
    private nonisolated func drawOverlayForPattern(
        _ pattern: DetectedPattern,
        overlayType: OverlayType,
        in rect: CGRect
    ) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        // Convert normalized coordinates to image coordinates
        let imageRect = CGRect(
            x: pattern.boundingBox.origin.x * rect.width,
            y: pattern.boundingBox.origin.y * rect.height,
            width: pattern.boundingBox.width * rect.width,
            height: pattern.boundingBox.height * rect.height
        )
        
        switch overlayType {
        case .spiral:
            drawSpiralOverlay(in: imageRect, context: context)
        case .phiGrid:
            drawPhiGridOverlay(in: imageRect, context: context)
        case .fibonacciNumbers:
            drawFibonacciNumbersOverlay(in: imageRect, context: context)
        case .goldenRectangle:
            drawGoldenRectangleOverlay(in: imageRect, context: context)
        case .none:
            break
        }
        
        // Draw confidence indicator
        drawConfidenceIndicator(
            confidence: pattern.confidence,
            at: CGPoint(
                x: imageRect.midX,
                y: imageRect.minY - 30
            ),
            context: context
        )
        
        // Draw pattern label
        drawPatternLabel(
            pattern: pattern,
            at: CGPoint(
                x: imageRect.midX,
                y: imageRect.maxY + 20
            ),
            context: context
        )
        
        context?.restoreGState()
    }
    
    private nonisolated func drawSpiralOverlay(in rect: CGRect, context: CGContext?) {
        context?.setStrokeColor(UIColor.yellow.cgColor)
        context?.setLineWidth(3.0)
        context?.setLineCap(.round)
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        
        context?.move(to: center)
        
        for i in 0...300 {
            let angle = Double(i) * 2 * .pi / 100
            let radius = maxRadius * (Double(i) / 300.0)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            context?.addLine(to: CGPoint(x: x, y: y))
        }
        
        context?.strokePath()
    }
    
    private nonisolated func drawPhiGridOverlay(in rect: CGRect, context: CGContext?) {
        context?.setStrokeColor(UIColor.blue.cgColor)
        context?.setLineWidth(2.0)
        
        let goldenRatio: CGFloat = 1.618
        
        // Draw golden rectangle
        let width = rect.width
        let height = width / goldenRatio
        let x = rect.origin.x + (rect.width - width) / 2
        let y = rect.origin.y + (rect.height - height) / 2
        
        context?.stroke(CGRect(x: x, y: y, width: width, height: height))
        
        // Draw grid lines
        context?.setLineWidth(1.0)
        context?.setStrokeColor(UIColor.blue.withAlphaComponent(0.5).cgColor)
        
        // Vertical lines
        let verticalPositions: [CGFloat] = [x, x + width / goldenRatio, x + width]
        for vx in verticalPositions {
            context?.move(to: CGPoint(x: vx, y: y))
            context?.addLine(to: CGPoint(x: vx, y: y + height))
        }
        
        // Horizontal lines
        let horizontalPositions: [CGFloat] = [y, y + height / goldenRatio, y + height]
        for hy in horizontalPositions {
            context?.move(to: CGPoint(x: x, y: hy))
            context?.addLine(to: CGPoint(x: x + width, y: hy))
        }
        
        context?.strokePath()
    }
    
    private nonisolated func drawFibonacciNumbersOverlay(in rect: CGRect, context: CGContext?) {
        let fibonacciNumbers = [1, 1, 2, 3, 5, 8, 13]
        let colors: [UIColor] = [.red, .orange, .yellow, .green, .blue, .purple, .systemPink]
        
        let boxSize: CGFloat = 30
        let spacing: CGFloat = 5
        let totalWidth = CGFloat(fibonacciNumbers.count) * boxSize + CGFloat(fibonacciNumbers.count - 1) * spacing
        let startX = rect.midX - totalWidth / 2
        let y = rect.midY - boxSize / 2
        
        for (index, number) in fibonacciNumbers.enumerated() {
            let x = startX + CGFloat(index) * (boxSize + spacing)
            let numberRect = CGRect(x: x, y: y, width: boxSize, height: boxSize)
            
            // Draw background circle
            context?.setFillColor(colors[index % colors.count].cgColor)
            context?.fillEllipse(in: numberRect)
            
            // Draw number
            let numberString = "\(number)"
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 12)
            ]
            
            let textSize = numberString.size(withAttributes: attributes)
            let textRect = CGRect(
                x: numberRect.midX - textSize.width / 2,
                y: numberRect.midY - textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            numberString.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private nonisolated func drawGoldenRectangleOverlay(in rect: CGRect, context: CGContext?) {
        context?.setStrokeColor(UIColor.green.cgColor)
        context?.setLineWidth(3.0)
        
        let goldenRatio: CGFloat = 1.618
        let width = rect.width
        let height = width / goldenRatio
        let x = rect.origin.x + (rect.width - width) / 2
        let y = rect.origin.y + (rect.height - height) / 2
        
        context?.stroke(CGRect(x: x, y: y, width: width, height: height))
        
        // Draw ratio indicators
        context?.setLineWidth(1.0)
        context?.setStrokeColor(UIColor.green.withAlphaComponent(0.5).cgColor)
        
        // Corner indicators
        let indicatorSize: CGFloat = 10
        let corners = [
            CGPoint(x: x, y: y),
            CGPoint(x: x + width, y: y),
            CGPoint(x: x, y: y + height),
            CGPoint(x: x + width, y: y + height)
        ]
        
        for corner in corners {
            context?.stroke(CGRect(
                x: corner.x - indicatorSize / 2,
                y: corner.y - indicatorSize / 2,
                width: indicatorSize,
                height: indicatorSize
            ))
        }
    }
    
    private nonisolated func drawConfidenceIndicator(
        confidence: Float,
        at point: CGPoint,
        context: CGContext?
    ) {
        let confidenceColor: UIColor = {
            if confidence >= 0.8 { return .green }
            if confidence >= 0.6 { return .yellow }
            return .red
        }()
        
        // Draw background circle
        let circleSize: CGFloat = 20
        let circleRect = CGRect(
            x: point.x - circleSize / 2,
            y: point.y - circleSize / 2,
            width: circleSize,
            height: circleSize
        )
        
        context?.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
        context?.fillEllipse(in: circleRect)
        
        // Draw confidence circle
        context?.setFillColor(confidenceColor.cgColor)
        context?.fillEllipse(in: circleRect.insetBy(dx: 2, dy: 2))
        
        // Draw percentage text
        let percentage = "\(Int(confidence * 100))%"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 8)
        ]
        
        let textSize = percentage.size(withAttributes: attributes)
        let textRect = CGRect(
            x: point.x - textSize.width / 2,
            y: point.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        percentage.draw(in: textRect, withAttributes: attributes)
    }
    
    private nonisolated func drawPatternLabel(
        pattern: DetectedPattern,
        at point: CGPoint,
        context: CGContext?
    ) {
        let label = pattern.type.displayName
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 12),
            .backgroundColor: UIColor.black.withAlphaComponent(0.7)
        ]
        
        let textSize = label.size(withAttributes: attributes)
        let textRect = CGRect(
            x: point.x - textSize.width / 2,
            y: point.y - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        label.draw(in: textRect, withAttributes: attributes)
    }
    
    // MARK: - Metadata Creation
    private func createImageMetadata(patterns: [DetectedPattern]) -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        metadata["app_name"] = "Fibonacci Detector"
        metadata["app_version"] = "1.0"
        metadata["capture_date"] = ISO8601DateFormatter().string(from: Date())
        metadata["pattern_count"] = patterns.count
        
        // Pattern details
        var patternDetails: [[String: Any]] = []
        for pattern in patterns {
            var patternInfo: [String: Any] = [:]
            patternInfo["type"] = pattern.type.rawValue
            patternInfo["confidence"] = pattern.confidence
            patternInfo["center_x"] = pattern.centerPoint.x
            patternInfo["center_y"] = pattern.centerPoint.y
            patternInfo["bounding_box"] = [
                "x": pattern.boundingBox.origin.x,
                "y": pattern.boundingBox.origin.y,
                "width": pattern.boundingBox.width,
                "height": pattern.boundingBox.height
            ]
            
            if let phiValue = pattern.mathematicalProperties.phiValue {
                patternInfo["phi_value"] = phiValue
            }
            
            if let fibonacciNumbers = pattern.mathematicalProperties.fibonacciNumbers {
                patternInfo["fibonacci_numbers"] = fibonacciNumbers
            }
            
            patternDetails.append(patternInfo)
        }
        
        metadata["patterns"] = patternDetails
        
        return metadata
    }
    
    // MARK: - Photo Library Management
    private func saveImageToPhotoLibrary(_ image: UIImage, metadata: [String: Any]) async throws -> UIImage {
        guard permissionStatus == .authorized || permissionStatus == .limited else {
            throw CaptureError.photoLibraryPermissionDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            photoLibrary.performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                if let imageData = image.jpegData(compressionQuality: 0.9) {
                    creationRequest.addResource(with: .photo, data: imageData, options: nil)
                }
                
                // Note: PHAssetCreationRequest doesn't support custom metadata directly
                // Metadata would need to be stored separately or in the image EXIF data
                
            }, completionHandler: { success, error in
                if success {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: error ?? CaptureError.photoLibrarySaveFailed)
                }
            })
        }
    }
    
    // MARK: - Sharing Methods
    func shareImage(_ image: CapturedImage) {
        var shareItems: [Any] = [image.image]
        
        // Add metadata as text
        let metadataText = createShareableMetadataText(for: image)
        shareItems.append(metadataText)
        
        // Add hashtags
        let hashtags = createHashtags(for: image.patterns)
        shareItems.append(hashtags)
        
        self.shareItems = shareItems
        showingShareSheet = true
    }
    
    func shareAllImages() {
        var shareItems: [Any] = []
        
        for capturedImage in capturedImages {
            shareItems.append(capturedImage.image)
        }
        
        // Add summary metadata
        let summaryText = createSummaryText()
        shareItems.append(summaryText)
        
        self.shareItems = shareItems
        showingShareSheet = true
    }
    
    private func createShareableMetadataText(for image: CapturedImage) -> String {
        var text = "🔍 Fibonacci Pattern Detected!\n\n"
        
        for pattern in image.patterns {
            text += "• \(pattern.type.displayName) (\(Int(pattern.confidence * 100))% confidence)\n"
        }
        
        text += "\n📱 Captured with Fibonacci Detector app"
        return text
    }
    
    private func createHashtags(for patterns: [DetectedPattern]) -> String {
        var hashtags = "#FibonacciDetector #MathInNature"
        
        for pattern in patterns {
            switch pattern.type {
            case .fibonacciSpiral:
                hashtags += " #FibonacciSpiral #GoldenSpiral"
            case .goldenRatio:
                hashtags += " #GoldenRatio #Phi"
            case .fibonacciSequence:
                hashtags += " #FibonacciSequence #Math"
            case .phiGrid:
                hashtags += " #PhiGrid #Design"
            case .sunflowerSpiral:
                hashtags += " #SunflowerSpiral #Nature"
            case .pineconeSpiral:
                hashtags += " #PineconeSpiral #Botany"
            case .shellSpiral:
                hashtags += " #ShellSpiral #MarineLife"
            case .nautilusSpiral:
                hashtags += " #NautilusSpiral #LivingFossil #GoldenRatio"
            case .leafArrangement:
                hashtags += " #LeafArrangement #Phyllotaxis"
            }
        }
        
        return hashtags
    }
    
    private func createSummaryText() -> String {
        let totalPatterns = capturedImages.reduce(0) { $0 + $1.patterns.count }
        let uniqueTypes = Set(capturedImages.flatMap { $0.patterns.map { $0.type } })
        
        var text = "🔍 Fibonacci Pattern Collection!\n\n"
        text += "📊 Total patterns detected: \(totalPatterns)\n"
        text += "🎯 Pattern types found: \(uniqueTypes.count)\n"
        text += "📱 Captured with Fibonacci Detector app\n\n"
        
        for type in uniqueTypes {
            text += "• \(type.displayName)\n"
        }
        
        return text
    }
    
    // MARK: - Image Management
    func deleteImage(_ image: CapturedImage) {
        capturedImages.removeAll { $0.id == image.id }
    }
    
    func clearAllImages() {
        capturedImages.removeAll()
    }
    
    func getImageCount() -> Int {
        return capturedImages.count
    }
    
    func getPatternCount() -> Int {
        return capturedImages.reduce(0) { $0 + $1.patterns.count }
    }
}

// MARK: - Supporting Structures
struct CapturedImage: Identifiable {
    let id = UUID()
    let image: UIImage
    let patterns: [DetectedPattern]
    let capturedAt: Date
    let metadata: [String: Any]
}

enum CaptureError: Error, LocalizedError {
    case noARFrame
    case imageConversionFailed
    case overlayRenderingFailed
    case photoLibraryPermissionDenied
    case photoLibrarySaveFailed
    
    var errorDescription: String? {
        switch self {
        case .noARFrame:
            return "No AR frame available for capture"
        case .imageConversionFailed:
            return "Failed to convert AR frame to image"
        case .overlayRenderingFailed:
            return "Failed to render overlays on image"
        case .photoLibraryPermissionDenied:
            return "Photo library permission denied"
        case .photoLibrarySaveFailed:
            return "Failed to save image to photo library"
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
