# Build Instructions - Fibonacci Detector

This document provides detailed instructions for building and deploying the Fibonacci Detector iOS app.

## 📋 Prerequisites

### System Requirements
- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **iOS SDK**: 18.0 or later
- **Swift**: 5.9 or later

### Hardware Requirements
- **Development Device**: iPhone 12 Pro or later (LiDAR support)
- **Recommended**: iPhone 17 with A19 chip for optimal performance
- **Storage**: 2GB free space for Xcode and dependencies

### Apple Developer Account
- **Free Account**: For development and testing
- **Paid Account**: Required for App Store distribution
- **Certificates**: Valid development/distribution certificates

## 🛠️ Development Setup

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/fibonacci-detector.git
cd fibonacci-detector
```

### 2. Open Project in Xcode
```bash
open FibonacciDetector.xcodeproj
```

### 3. Configure Project Settings

#### General Tab
- **Display Name**: Fibonacci Detector
- **Bundle Identifier**: `com.yourcompany.fibonaccidetector`
- **Version**: 1.0
- **Build**: 1
- **Deployment Target**: iOS 18.0

#### Signing & Capabilities
- **Team**: Select your development team
- **Signing Certificate**: Automatic or manual
- **Capabilities**:
  - ✅ Camera
  - ✅ Photo Library
  - ✅ ARKit

#### Build Settings
- **Swift Language Version**: Swift 5
- **iOS Deployment Target**: 18.0
- **Architectures**: arm64
- **Optimization Level**: Release (-Os)

### 4. Install Dependencies
The project uses only Apple frameworks, no external dependencies required:
- ARKit
- Core ML
- Vision
- SwiftUI
- AVFoundation
- Photos

## 🏗️ Building the App

### Debug Build
```bash
# Build for simulator
xcodebuild -scheme FibonacciDetector -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build for device
xcodebuild -scheme FibonacciDetector -destination 'generic/platform=iOS' build
```

### Release Build
```bash
# Archive for distribution
xcodebuild -scheme FibonacciDetector -destination 'generic/platform=iOS' archive -archivePath FibonacciDetector.xcarchive
```

### Build Configuration

#### Debug Configuration
- **Optimization**: None (-Onone)
- **Debug Information**: Full
- **Symbols**: All
- **Sanitizers**: Address, Thread, Undefined Behavior

#### Release Configuration
- **Optimization**: Optimize for Speed (-O)
- **Debug Information**: None
- **Symbols**: Hidden
- **Sanitizers**: None

## 📱 Device Testing

### Simulator Testing
1. **Select Simulator**: iPhone 17 (iOS 18.0+)
2. **Run App**: Cmd+R
3. **Test Features**:
   - Camera permissions
   - AR session initialization
   - Pattern detection (simulated)
   - UI interactions

### Physical Device Testing

#### Required Permissions
```xml
<!-- Info.plist permissions -->
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to detect Fibonacci patterns in natural objects.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app saves captured images with detected Fibonacci patterns to your photo library.</string>
```

#### Device Setup
1. **Connect Device**: USB or wireless
2. **Trust Computer**: When prompted
3. **Enable Developer Mode**: Settings > Privacy & Security > Developer Mode
4. **Install Profile**: Xcode will handle automatically

#### Testing Checklist
- [ ] Camera access granted
- [ ] AR session starts successfully
- [ ] Pattern detection works with real objects
- [ ] AR overlays display correctly
- [ ] Photo capture functions
- [ ] Educational popups appear
- [ ] Settings can be modified
- [ ] Performance meets 60 FPS target

## 🧪 Testing Strategy

### Unit Tests
```bash
# Run unit tests
xcodebuild test -scheme FibonacciDetector -destination 'platform=iOS Simulator,name=iPhone 17'
```

#### Test Coverage Areas
- **MathUtils**: Mathematical calculations
- **Pattern Detection**: Algorithm accuracy
- **AR Integration**: Session management
- **UI Components**: SwiftUI views
- **Data Models**: Pattern structures

### Integration Tests
- **End-to-End**: Complete user workflows
- **Performance**: Frame rate and memory usage
- **Device Compatibility**: Multiple iPhone models
- **iOS Versions**: Backward compatibility

### Manual Testing Scenarios

#### Pattern Detection
1. **Fibonacci Spirals**:
   - Nautilus shells
   - Sunflower centers
   - Galaxy images
   - Hurricane patterns

2. **Golden Ratio**:
   - Credit cards
   - Architectural photos
   - Art reproductions
   - Human body proportions

3. **Edge Cases**:
   - Poor lighting conditions
   - Blurry images
   - Partial patterns
   - Multiple overlapping patterns

#### Performance Testing
- **Frame Rate**: Monitor 60 FPS target
- **Memory Usage**: Check for leaks
- **Battery Life**: Extended usage testing
- **Heat Management**: Thermal throttling

## 📦 Distribution

### App Store Distribution

#### 1. Archive Preparation
```bash
# Create archive
xcodebuild -scheme FibonacciDetector -destination 'generic/platform=iOS' archive -archivePath FibonacciDetector.xcarchive

# Export for App Store
xcodebuild -exportArchive -archivePath FibonacciDetector.xcarchive -exportPath AppStore -exportOptionsPlist ExportOptions.plist
```

#### 2. App Store Connect
1. **Create App**: New app in App Store Connect
2. **Upload Build**: Use Xcode or Application Loader
3. **App Information**:
   - Name: Fibonacci Detector
   - Subtitle: Discover Math in Nature
   - Description: Educational content
   - Keywords: fibonacci, golden ratio, math, nature, AR
   - Category: Education

#### 3. Metadata Requirements
- **App Icon**: 1024x1024 PNG
- **Screenshots**: iPhone and iPad sizes
- **App Preview**: Video demonstration
- **Privacy Policy**: Required for camera usage

### TestFlight Distribution

#### Beta Testing Setup
1. **Upload Build**: Archive and upload to TestFlight
2. **Internal Testing**: Team members
3. **External Testing**: Up to 10,000 testers
4. **Feedback Collection**: TestFlight feedback system

#### Beta Testing Checklist
- [ ] Core functionality works
- [ ] Performance is acceptable
- [ ] No critical bugs
- [ ] User experience is smooth
- [ ] Educational content is accurate

## 🔧 Troubleshooting

### Common Build Issues

#### Code Signing Errors
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset certificates
# Xcode > Preferences > Accounts > Download Manual Profiles
```

#### Simulator Issues
```bash
# Reset simulator
xcrun simctl erase all

# Reinstall simulators
# Xcode > Preferences > Components
```

#### ARKit Issues
- **Device Support**: Ensure LiDAR-capable device
- **iOS Version**: Minimum iOS 18.0 required
- **Permissions**: Camera access must be granted
- **Lighting**: Adequate lighting for AR tracking

### Performance Issues

#### Frame Rate Problems
- **Reduce Processing**: Lower detection frequency
- **Optimize Algorithms**: Profile and optimize code
- **Memory Management**: Check for retain cycles
- **Background Processing**: Move heavy work off main thread

#### Memory Leaks
- **Instruments**: Use Leaks instrument
- **Weak References**: Use weak references where appropriate
- **ARC**: Ensure proper memory management
- **Image Processing**: Release large images promptly

### Device-Specific Issues

#### iPhone 17 Optimization
- **A19 Chip**: Leverage advanced ML capabilities
- **LiDAR**: Enable enhanced depth mapping
- **High FPS**: Utilize 60+ FPS camera feed
- **Memory**: Optimize for increased RAM

#### Older Device Support
- **Fallback Features**: Disable advanced features
- **Performance Modes**: Lower quality settings
- **Memory Limits**: Reduce processing load
- **Battery Optimization**: Power-saving modes

## 📊 Performance Monitoring

### Metrics to Track
- **Frame Rate**: Target 60 FPS
- **Memory Usage**: <200MB peak
- **CPU Usage**: <50% average
- **Battery Life**: 2+ hours continuous use
- **Detection Accuracy**: >85% correct

### Monitoring Tools
- **Xcode Instruments**: Performance profiling
- **MetricKit**: iOS performance metrics
- **Custom Analytics**: App-specific metrics
- **Crash Reports**: Automatic crash reporting

## 🚀 Deployment Checklist

### Pre-Release
- [ ] All tests pass
- [ ] Performance targets met
- [ ] No critical bugs
- [ ] Documentation updated
- [ ] Screenshots prepared
- [ ] App Store metadata complete

### Release
- [ ] Archive created successfully
- [ ] Uploaded to App Store Connect
- [ ] TestFlight build available
- [ ] Beta testing completed
- [ ] App Store review submitted
- [ ] Release notes prepared

### Post-Release
- [ ] Monitor crash reports
- [ ] Track performance metrics
- [ ] Collect user feedback
- [ ] Plan future updates
- [ ] Update documentation

## 📞 Support

### Development Support
- **GitHub Issues**: Bug reports and feature requests
- **Discord**: Developer community chat
- **Email**: dev@fibonaccidetector.app

### User Support
- **App Store Reviews**: User feedback
- **Support Email**: support@fibonaccidetector.app
- **Documentation**: User guides and tutorials

---

**Happy Building!** 🚀📱✨

For additional help, refer to the main [README.md](README.md) or create an issue on GitHub.

