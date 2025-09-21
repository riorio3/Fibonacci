# Core ML Model Training Guide

This guide explains how to train a custom Core ML model for Fibonacci pattern detection using Create ML.

## 📊 Training Data Requirements

### Dataset Size
- **Minimum**: 1,000 images per pattern type
- **Recommended**: 5,000+ images per pattern type
- **Total Dataset**: 10,000+ images across all categories

### Image Specifications
- **Resolution**: 224x224 pixels (minimum)
- **Format**: JPEG or PNG
- **Quality**: High resolution, clear images
- **Lighting**: Varied lighting conditions
- **Angles**: Multiple viewing angles
- **Backgrounds**: Diverse backgrounds

## 🏷️ Pattern Categories

### 1. Fibonacci Spirals
**Target Objects**: Shells, galaxies, flowers, hurricanes
**Characteristics**:
- Logarithmic spiral growth
- Golden ratio proportions
- Clockwise or counterclockwise rotation
- Natural growth patterns

**Training Images**:
- Nautilus shells (various sizes)
- Sunflower centers
- Galaxy spiral arms
- Hurricane satellite images
- Flower petal arrangements
- Pine cone spirals

### 2. Golden Ratio Rectangles
**Target Objects**: Architecture, art, credit cards, human proportions
**Characteristics**:
- 1.618:1 aspect ratio
- Aesthetically pleasing proportions
- Found in design and nature

**Training Images**:
- Parthenon architecture
- Mona Lisa composition
- Credit card proportions
- Human body measurements
- Renaissance paintings
- Modern web design layouts

### 3. Sunflower Spirals
**Target Objects**: Sunflower centers, daisy centers, pineapples
**Characteristics**:
- 137.5° golden angle
- Fibonacci number spirals
- Optimal packing arrangement

**Training Images**:
- Sunflower seed arrangements
- Daisy flower centers
- Pineapple patterns
- Artichoke leaf arrangements
- Various flower centers

### 4. Shell Spirals
**Target Objects**: Marine shells, snail shells, ammonite fossils
**Characteristics**:
- Logarithmic growth
- Chambered structure
- Natural strength optimization

**Training Images**:
- Nautilus shells
- Snail shells
- Ammonite fossils
- Chambered nautilus
- Various marine shells

### 5. Pinecone Spirals
**Target Objects**: Pine cones, fir cones, spruce cones
**Characteristics**:
- Fibonacci number spirals
- Seed dispersal optimization
- Natural growth patterns

**Training Images**:
- Pine cones (various species)
- Fir cones
- Spruce cones
- Cedar cones
- Various coniferous cones

## 🛠️ Create ML Training Process

### 1. Data Preparation

#### Organize Training Data
```
TrainingData/
├── FibonacciSpiral/
│   ├── nautilus_shells/
│   ├── galaxy_spirals/
│   └── flower_spirals/
├── GoldenRatio/
│   ├── architecture/
│   ├── art_compositions/
│   └── human_proportions/
├── SunflowerSpiral/
│   ├── sunflower_centers/
│   ├── daisy_centers/
│   └── pineapple_patterns/
├── ShellSpiral/
│   ├── marine_shells/
│   ├── snail_shells/
│   └── ammonite_fossils/
└── PineconeSpiral/
    ├── pine_cones/
    ├── fir_cones/
    └── spruce_cones/
```

#### Data Augmentation
- **Rotation**: ±15° rotation
- **Scaling**: 0.8x to 1.2x scale
- **Brightness**: ±20% brightness adjustment
- **Contrast**: ±20% contrast adjustment
- **Noise**: Add slight noise for robustness

### 2. Create ML Setup

#### Create New Project
1. **Open Create ML**: Applications > Create ML
2. **New Project**: Image Classification
3. **Project Name**: FibonacciPatternDetector
4. **Input**: Training data folder
5. **Output**: Multi-label classification

#### Configure Training
```swift
// Training configuration
let config = MLImageClassifier.Configuration()
config.featureExtractor = .scenePrint(revision: 1)
config.validation = .automatic
config.maxIterations = 100
config.batchSize = 32
config.learningRate = 0.01
```

### 3. Training Process

#### Training Parameters
- **Algorithm**: Vision Feature Print (ScenePrint)
- **Max Iterations**: 100-200
- **Batch Size**: 32-64
- **Learning Rate**: 0.01-0.001
- **Validation Split**: 20%

#### Training Steps
1. **Load Data**: Import training images
2. **Validate Data**: Check image quality and labels
3. **Start Training**: Begin model training
4. **Monitor Progress**: Watch training metrics
5. **Evaluate Model**: Test on validation set
6. **Export Model**: Save as .mlmodel file

### 4. Model Evaluation

#### Metrics to Track
- **Accuracy**: Overall classification accuracy
- **Precision**: Per-class precision scores
- **Recall**: Per-class recall scores
- **F1 Score**: Harmonic mean of precision and recall
- **Confusion Matrix**: Detailed error analysis

#### Target Performance
- **Overall Accuracy**: >90%
- **Per-Class Accuracy**: >85%
- **False Positive Rate**: <10%
- **False Negative Rate**: <15%

## 🔧 Model Integration

### 1. Replace Model File
```bash
# Copy trained model to project
cp FibonacciPatternDetector.mlmodel FibonacciDetector/Models/
```

### 2. Update Model Loading
```swift
// In FibonacciDetector.swift
private func setupMLModel() {
    guard let modelURL = Bundle.main.url(forResource: "FibonacciPatternDetector", withExtension: "mlmodelc") else {
        print("⚠️ FibonacciPatternDetector not found in bundle")
        return
    }
    
    do {
        mlModel = try MLModel(contentsOf: modelURL)
        print("✅ Core ML model loaded successfully")
    } catch {
        print("❌ Failed to load Core ML model: \(error)")
    }
}
```

### 3. Update Output Processing
```swift
// Process model output
private func processMLOutput(_ output: MLFeatureProvider) -> [DetectedPattern] {
    var patterns: [DetectedPattern] = []
    
    // Extract predictions for each class
    let classLabels = ["fibonacci_spiral", "golden_ratio", "sunflower_spiral", "shell_spiral", "pinecone_spiral"]
    
    for label in classLabels {
        if let confidence = output.featureValue(for: label)?.doubleValue,
           confidence > Double(settings.confidenceThreshold) {
            
            let patternType = PatternType(rawValue: label) ?? .fibonacciSpiral
            let pattern = createDetectedPattern(
                type: patternType,
                confidence: Float(confidence),
                boundingBox: CGRect(x: 0, y: 0, width: 100, height: 100)
            )
            patterns.append(pattern)
        }
    }
    
    return patterns
}
```

## 📈 Training Best Practices

### Data Quality
- **High Resolution**: Use high-quality images
- **Diverse Examples**: Include various examples of each pattern
- **Balanced Dataset**: Equal representation of all classes
- **Clean Labels**: Accurate and consistent labeling

### Training Optimization
- **Progressive Training**: Start with smaller datasets
- **Transfer Learning**: Use pre-trained models as base
- **Regularization**: Prevent overfitting
- **Early Stopping**: Stop when validation accuracy plateaus

### Model Validation
- **Cross-Validation**: Use k-fold cross-validation
- **Holdout Set**: Reserve test set for final evaluation
- **Real-World Testing**: Test on actual device images
- **Edge Case Testing**: Test with difficult examples

## 🚀 Advanced Training Techniques

### 1. Transfer Learning
```swift
// Use pre-trained model as base
let baseModel = try MLModel(contentsOf: preTrainedModelURL)
let config = MLImageClassifier.Configuration()
config.featureExtractor = .scenePrint(revision: 1)
```

### 2. Data Augmentation
```swift
// Augment training data
let augmentationOptions = MLImageClassifier.DataAugmentationOptions()
augmentationOptions.rotation = .random(angleRange: -15...15)
augmentationOptions.scale = .random(scaleRange: 0.8...1.2)
augmentationOptions.brightness = .random(brightnessRange: -0.2...0.2)
```

### 3. Custom Loss Functions
```swift
// Implement custom loss for imbalanced data
let config = MLImageClassifier.Configuration()
config.lossFunction = .crossEntropy
config.classWeights = [1.0, 1.2, 1.1, 1.3, 1.0] // Weight rare classes higher
```

## 📊 Performance Monitoring

### Training Metrics
- **Loss Curve**: Monitor training and validation loss
- **Accuracy Curve**: Track accuracy improvements
- **Learning Rate**: Adjust learning rate schedule
- **Batch Size**: Optimize batch size for performance

### Model Performance
- **Inference Time**: Measure prediction speed
- **Memory Usage**: Monitor model size and memory
- **Accuracy**: Track real-world accuracy
- **Robustness**: Test with various conditions

## 🔄 Model Updates

### Continuous Learning
- **New Data**: Collect new training examples
- **Retraining**: Regular model updates
- **A/B Testing**: Compare model versions
- **User Feedback**: Incorporate user corrections

### Version Control
- **Model Versions**: Track model iterations
- **Performance Tracking**: Monitor accuracy over time
- **Rollback Capability**: Revert to previous versions
- **Documentation**: Document changes and improvements

## 📚 Additional Resources

### Training Data Sources
- **Nature Photography**: High-quality nature images
- **Scientific Databases**: Academic image collections
- **Museum Collections**: Art and artifact images
- **User Contributions**: Crowdsourced training data

### Tools and Libraries
- **Create ML**: Apple's machine learning framework
- **Core ML Tools**: Model conversion and optimization
- **Turicreate**: Alternative training framework
- **TensorFlow**: Advanced training capabilities

### Documentation
- **Apple Developer**: Core ML documentation
- **Create ML Guide**: Official training guide
- **Machine Learning**: General ML best practices
- **Computer Vision**: Image classification techniques

---

**Happy Training!** 🎯🤖📊

For questions about model training, create an issue on GitHub or join our Discord community.

