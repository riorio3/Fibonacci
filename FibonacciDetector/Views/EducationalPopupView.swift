import SwiftUI

struct EducationalPopupView: View {
    let pattern: DetectedPattern
    @Binding var isPresented: Bool
    
    @State private var currentPage = 0
    @State private var showingShareSheet = false
    @State private var capturedImage: UIImage?
    
    private let pages: [EducationalPage]
    
    init(pattern: DetectedPattern, isPresented: Binding<Bool>) {
        self.pattern = pattern
        self._isPresented = isPresented
        self.pages = EducationalPopupView.createPages(for: pattern)
    }
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopup()
                }
            
            // Popup content
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 400)
                
                // Page indicator
                pageIndicator
                
                // Action buttons
                actionButtons
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 20)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isPresented)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = capturedImage {
                ShareSheet(activityItems: [image])
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.type.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: dismissPopup) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Page View
    private func pageView(_ page: EducationalPage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Page title
                Text(page.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                // Page content
                switch page.type {
                case .description:
                    descriptionView(page)
                case .mathematics:
                    mathematicsView(page)
                case .examples:
                    examplesView(page)
                case .funFacts:
                    funFactsView(page)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Description View
    private func descriptionView(_ page: EducationalPage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(page.content)
                .font(.body)
                .lineSpacing(4)
            
            // Mathematical properties
            mathematicalPropertiesView(pattern.mathematicalProperties)
        }
    }
    
    // MARK: - Mathematics View
    private func mathematicsView(_ page: EducationalPage) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(page.content)
                .font(.body)
                .lineSpacing(4)
            
            // Mathematical formulas
            mathematicalFormulasView
            
            // Interactive elements
            interactiveElementsView
        }
    }
    
    // MARK: - Examples View
    private func examplesView(_ page: EducationalPage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Real-world examples:")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(pattern.educationalContent.examples, id: \.self) { example in
                    ExampleCard(example: example, patternType: pattern.type)
                }
            }
        }
    }
    
    // MARK: - Fun Facts View
    private func funFactsView(_ page: EducationalPage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Did you know?")
                .font(.headline)
            
            ForEach(Array(pattern.educationalContent.funFacts.enumerated()), id: \.offset) { index, fact in
                FunFactCard(fact: fact, index: index + 1)
            }
        }
    }
    
    // MARK: - Mathematical Properties View
    private func mathematicalPropertiesView(_ properties: DetectedPattern.MathematicalProperties) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mathematical Properties")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let phiValue = properties.phiValue {
                PropertyRow(title: "Golden Ratio (φ)", value: String(format: "%.6f", phiValue))
            }
            
            if let fibonacciNumbers = properties.fibonacciNumbers {
                PropertyRow(title: "Fibonacci Sequence", value: fibonacciNumbers.map(String.init).joined(separator: ", "))
            }
            
            if let spiralAngle = properties.spiralAngle {
                PropertyRow(title: "Spiral Angle", value: "\(String(format: "%.1f", spiralAngle))°")
            }
            
            if let ratio = properties.ratio {
                PropertyRow(title: "Ratio", value: String(format: "%.6f", ratio))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Mathematical Formulas View
    private var mathematicalFormulasView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Formulas")
                .font(.headline)
            
            ForEach(getFormulasForPattern(pattern.type), id: \.title) { formula in
                FormulaCard(formula: formula)
            }
        }
    }
    
    // MARK: - Interactive Elements View
    private var interactiveElementsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interactive")
                .font(.headline)
            
            if pattern.type == .fibonacciSequence {
                FibonacciSequenceGenerator()
            } else if pattern.type == .goldenRatio {
                GoldenRatioCalculator()
            } else if pattern.type == .fibonacciSpiral {
                SpiralVisualization()
            }
        }
    }
    
    // MARK: - Page Indicator
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Previous button
            Button(action: previousPage) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.subheadline)
                .foregroundColor(currentPage > 0 ? .primary : .secondary)
            }
            .disabled(currentPage == 0)
            
            Spacer()
            
            // Share button
            Button(action: captureAndShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            Spacer()
            
            // Next button
            Button(action: nextPage) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundColor(currentPage < pages.count - 1 ? .primary : .secondary)
            }
            .disabled(currentPage == pages.count - 1)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Helper Methods
    private func dismissPopup() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
    
    private func previousPage() {
        if currentPage > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage -= 1
            }
        }
    }
    
    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
        }
    }
    
    private func captureAndShare() {
        // Capture current view as image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
        capturedImage = renderer.image { context in
            // Render the popup content
            // This is a simplified implementation
        }
        
        showingShareSheet = true
    }
    
    private func getFormulasForPattern(_ type: PatternType) -> [MathematicalFormula] {
        switch type {
        case .fibonacciSequence:
            return [
                MathematicalFormula(title: "Fibonacci Formula", formula: "F(n) = F(n-1) + F(n-2)", description: "Each number is the sum of the two preceding ones"),
                MathematicalFormula(title: "Binet's Formula", formula: "F(n) = (φⁿ - ψⁿ) / √5", description: "Direct calculation using golden ratio")
            ]
        case .goldenRatio:
            return [
                MathematicalFormula(title: "Golden Ratio", formula: "φ = (1 + √5) / 2", description: "The positive solution to φ² = φ + 1"),
                MathematicalFormula(title: "Golden Ratio Properties", formula: "φ = 1 + 1/φ", description: "Self-similar property")
            ]
        case .fibonacciSpiral:
            return [
                MathematicalFormula(title: "Spiral Growth", formula: "r = a × φ^(bθ)", description: "Logarithmic spiral with golden ratio growth"),
                MathematicalFormula(title: "Golden Angle", formula: "θ = 360° / φ² ≈ 137.5°", description: "Optimal angle for spiral packing")
            ]
        default:
            return []
        }
    }
    
    // MARK: - Static Methods
    static func createPages(for pattern: DetectedPattern) -> [EducationalPage] {
        var pages: [EducationalPage] = []
        
        // Description page
        pages.append(EducationalPage(
            type: .description,
            title: "What is this?",
            content: pattern.educationalContent.description
        ))
        
        // Mathematics page
        pages.append(EducationalPage(
            type: .mathematics,
            title: "The Math Behind It",
            content: pattern.educationalContent.mathematicalExplanation
        ))
        
        // Examples page
        pages.append(EducationalPage(
            type: .examples,
            title: "See It in Nature",
            content: "This pattern appears in many natural objects:"
        ))
        
        // Fun facts page
        pages.append(EducationalPage(
            type: .funFacts,
            title: "Fun Facts",
            content: "Interesting tidbits about this mathematical pattern:"
        ))
        
        return pages
    }
}

// MARK: - Supporting Views
struct ExampleCard: View {
    let example: String
    let patternType: PatternType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: iconForExample(example))
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(example)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func iconForExample(_ example: String) -> String {
        if example.lowercased().contains("shell") { return "shell" }
        if example.lowercased().contains("flower") { return "leaf" }
        if example.lowercased().contains("pine") { return "tree" }
        if example.lowercased().contains("galaxy") { return "sparkles" }
        return "circle"
    }
}

struct FunFactCard: View {
    let fact: String
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.blue))
            
            Text(fact)
                .font(.body)
                .lineSpacing(2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct PropertyRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct FormulaCard: View {
    let formula: MathematicalFormula
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formula.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(formula.formula)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            
            Text(formula.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Interactive Components
struct FibonacciSequenceGenerator: View {
    @State private var sequence: [Int] = [1, 1]
    @State private var maxTerms = 10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generate Fibonacci Sequence")
                .font(.headline)
            
            HStack {
                Text("Terms:")
                Slider(value: Binding(
                    get: { Double(maxTerms) },
                    set: { maxTerms = Int($0) }
                ), in: 5...20, step: 1)
                Text("\(maxTerms)")
                    .fontWeight(.medium)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 8) {
                ForEach(sequence.prefix(maxTerms), id: \.self) { number in
                    Text("\(number)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.blue))
                }
            }
        }
        .onAppear {
            generateSequence()
        }
        .onChange(of: maxTerms) {
            generateSequence()
        }
    }
    
    private func generateSequence() {
        sequence = [1, 1]
        for i in 2..<maxTerms {
            sequence.append(sequence[i-1] + sequence[i-2])
        }
    }
}

struct GoldenRatioCalculator: View {
    @State private var a: Double = 1.0
    @State private var b: Double = 1.618
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Golden Ratio Calculator")
                .font(.headline)
            
            HStack {
                Text("A:")
                TextField("1.0", value: $a, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                
                Text("B:")
                TextField("1.618", value: $b, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
            }
            
            let ratio = b / a
            let isGolden = abs(ratio - 1.618) < 0.01
            
            HStack {
                Text("Ratio: \(String(format: "%.3f", ratio))")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: isGolden ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isGolden ? .green : .red)
            }
        }
    }
}

struct SpiralVisualization: View {
    @State private var turns: Double = 3.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spiral Visualization")
                .font(.headline)
            
            HStack {
                Text("Turns:")
                Slider(value: $turns, in: 1...5, step: 0.5)
                Text("\(String(format: "%.1f", turns))")
                    .fontWeight(.medium)
            }
            
            // Simple spiral visualization
            SpiralShape(turns: turns, animationPhase: 1.0)
                .stroke(Color.blue, lineWidth: 2)
                .frame(width: 100, height: 100)
        }
    }
}


// MARK: - SpiralShape Definition
struct SpiralShape: Shape {
    let turns: Double
    let animationPhase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        
        let totalPoints = Int(turns * 100)
        let animatedPoints = Int(Double(totalPoints) * animationPhase)
        
        for i in 0...animatedPoints {
            let angle = Double(i) * 2 * .pi / 100
            let radius = maxRadius * (Double(i) / (turns * 100))
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

// MARK: - Supporting Structures
struct EducationalPage {
    let type: PageType
    let title: String
    let content: String
}

enum PageType {
    case description
    case mathematics
    case examples
    case funFacts
}

struct MathematicalFormula {
    let title: String
    let formula: String
    let description: String
}
