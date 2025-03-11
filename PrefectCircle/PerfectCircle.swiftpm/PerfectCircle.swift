

import SwiftUI

struct PerfectCircle: View {
    @State private var drawingPath = Path()
    @State private var isDrawing = false
    @State private var score: Double = 0
    @State private var highScore: Double = 0
    @State private var selectedColor: Color = .red
    @State private var lineWidth: CGFloat = 5
    @State private var highScoreAnimation: Bool = false

    init() {
        //MARK: Register the custom font
        let bundle = Bundle.main
        if let fontURL = bundle.url(forResource: "Minecraft", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }

    var body: some View {
        VStack {
            Spacer()
            Text("Draw a Circle")
                .font(.custom("Minecraft", size: 32))
                .padding()
            
            HStack {
                Text("Color:")
                    .font(.custom("Minecraft", size: 24))
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .frame(width: 50, height: 50)
            }
            .padding()
            
            HStack {
                Text("Line Width:")
                    .font(.custom("Minecraft", size: 24))
                Slider(value: $lineWidth, in: 1...10, step: 1)
                    .padding()
            }
            
            CanvasView(drawingPath: $drawingPath, selectedColor: $selectedColor, lineWidth: $lineWidth, score: $score)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.red, .blue, .green, .yellow]),
                                startPoint: .topLeading,
                                endPoint: .trailing
                            ),
                            lineWidth: 10
                        )
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDrawing {
                                drawingPath.move(to: value.location)
                                isDrawing = true
                            } else {
                                drawingPath.addLine(to: value.location)
                                // Real-time score calculation
                                if let newScore = calculateCircleScore(for: drawingPath) {
                                    score = newScore
                                }
                            }
                        }
                        .onEnded { _ in
                            isDrawing = false
                            //MARK: Update high score
                            if score > highScore {
                                withAnimation(.easeInOut(duration: 1)) {
                                    highScore = score
                                    highScoreAnimation.toggle()
                                }
                            }
                            //MARK: CLEAR
                            drawingPath = Path()                         }
                )
                .padding()
            
            Text("Score: \(Int(score))%")
                .font(.custom("Minecraft", size: 28))
                .padding()
                .foregroundColor(score > 90 ? .green : (score >= 70 ? Color.orange : .red))
            
            Text("High Score: \(Int(highScore))%")
                .font(.custom("Minecraft", size: 28))
                .padding(.top, 5)
                .scaleEffect(highScoreAnimation ? 1.5 : 1.0)
            
                .foregroundColor(highScoreAnimation ? .green : .primary)
            
                .onChange(of: highScore) { _ in
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        withAnimation(.easeInOut(duration: 1)) {
                            highScoreAnimation = false
                        }
                    }
                }
            
            Spacer()
        }
        .padding()
    }
    
    func calculateCircleScore(for path: Path) -> Double? {
        guard !path.isEmpty else { return nil }
        
        //MARK: Safe unwrap currentPoint
        guard let startPoint = path.currentPoint else { return nil }
        let endPoint = path.currentPoint ?? startPoint
        
        //MARK: Check if the path starts and ends at approximately the same point
        let isClosed = abs(startPoint.x - endPoint.x) < 10 && abs(startPoint.y - endPoint.y) < 10
        
        if !isClosed {
            return 0 // If the path is not closed, return 0 score
        }
        
        let rect = path.boundingRect
        let expectedCenter = CGPoint(x: rect.midX, y: rect.midY)
        let expectedRadius = min(rect.width, rect.height) / 2
        
        let sampledPoints = extractSampledPoints(from: path, sampleRate: 0.1)
        
        var totalDeviation: Double = 0
        let totalPoints = Double(sampledPoints.count)
        
        for point in sampledPoints {
            let distanceFromCenter = hypot(point.x - expectedCenter.x, point.y - expectedCenter.y)
            let deviation = abs(distanceFromCenter - expectedRadius)
            totalDeviation += deviation
        }
        
        let maxPossibleDeviation = expectedRadius * totalPoints
        let score = max(0, 100 * (1 - (totalDeviation / maxPossibleDeviation)))
        
        return score
    }

    func extractSampledPoints(from path: Path, sampleRate: Double) -> [CGPoint] {
        var points = [CGPoint]()
        var totalPoints = 0
        
        let cgPath = path.cgPath
        cgPath.applyWithBlock { element in
            let pointsPointer = element.pointee.points
            let pointCount: Int
            
            switch element.pointee.type {
            case .moveToPoint, .addLineToPoint:
                pointCount = 1
            case .addQuadCurveToPoint:
                pointCount = 2
            case .addCurveToPoint:
                pointCount = 3
            case .closeSubpath:
                pointCount = 0
            @unknown default:
                pointCount = 0
            }
            
            for i in 0..<pointCount {
                totalPoints += 1
                if Double(totalPoints).truncatingRemainder(dividingBy: 1.0 / sampleRate) == 0 {
                    points.append(pointsPointer[i])
                }
            }
        }
        
        return points
    }
}

struct CanvasView: View {
    @Binding var drawingPath: Path
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    @Binding var score: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                    .position(center)
                
                drawingPath.stroke(selectedColor, lineWidth: lineWidth)
            }
            .background(Color(UIColor.systemBackground))
            .contentShape(Rectangle())
        }
    }
}






//import SwiftUI
//
//struct ContentView: View {
//    @State private var drawingPath = Path()
//    @State private var isDrawing = false
//    @State private var score: Double? = nil
//    @State private var highScore: Double = 0
//    @State private var selectedColor: Color = .red
//    @State private var lineWidth: CGFloat = 5
//
//    var body: some View {
//        VStack {
//            Spacer()
//            Text("Draw a Circle").font(.largeTitle)
//
//            HStack {
//                Text("Color:")
//                ColorPicker("", selection: $selectedColor)
//                    .labelsHidden()
//                    .frame(width: 50, height: 50)
//            }
//            .padding()
//
//            HStack {
//                Text("Line Width:")
//                Slider(value: $lineWidth, in: 1...10, step: 1)
//                    .padding()
//            }
//
//            CanvasView(drawingPath: $drawingPath, selectedColor: $selectedColor, lineWidth: $lineWidth, score: $score)
//                .aspectRatio(1, contentMode: .fit)
//                .border(Color.green, width: 5)
//                .gesture(
//                    DragGesture(minimumDistance: 0)
//                        .onChanged { value in
//                            if !isDrawing {
//                                drawingPath.move(to: value.location)
//                                isDrawing = true
//                            } else {
//                                drawingPath.addLine(to: value.location)
//                                if let newScore = calculateCircleScore(for: drawingPath) {
//                                    score = newScore
//                                    if newScore > highScore {
//                                        highScore = newScore
//                                    }
//                                }
//                            }
//                        }
//                        .onEnded { _ in
//                            isDrawing = false
//                            drawingPath = Path() // Clear the canvas after the drawing is complete
//                        }
//                )
//                .padding()
//
//            if let score = score {
//                Text("Score: \(Int(score))")
//                    .font(.title)
//                    .padding()
//                    .foregroundColor(score > 90 ? .green : (score >= 70 ? Color.orange : .red)) // Conditional text color
//                Text("High Score: \(Int(highScore))")
//                    .font(.title2)
//                    .padding(.top, 5)
//            }
//
//            Spacer()
//        }
//        .padding()
//    }
//
//    func calculateCircleScore(for path: Path) -> Double? {
//        guard !path.isEmpty else { return nil }
//
//        let rect = path.boundingRect
//        let expectedCenter = CGPoint(x: rect.midX, y: rect.midY)
//        let expectedRadius = min(rect.width, rect.height) / 2
//
//        let sampledPoints = extractPoints(from: path)
//
//        var totalDeviation: Double = 0
//        for point in sampledPoints {
//            let distanceFromCenter = hypot(point.x - expectedCenter.x, point.y - expectedCenter.y)
//            let deviation = abs(distanceFromCenter - expectedRadius)
//            totalDeviation += deviation
//        }
//
//        let maxPossibleDeviation = expectedRadius * Double(sampledPoints.count)
//        let score = max(0, 100 * (1 - (totalDeviation / maxPossibleDeviation)))
//
//        return score
//    }
//
//    func extractPoints(from path: Path) -> [CGPoint] {
//        var points = [CGPoint]()
//
//        let cgPath = path.cgPath
//        cgPath.applyWithBlock { element in
//            let pointsPointer = element.pointee.points
//            let pointCount: Int
//
//            switch element.pointee.type {
//            case .moveToPoint, .addLineToPoint:
//                pointCount = 1
//            case .addQuadCurveToPoint:
//                pointCount = 2
//            case .addCurveToPoint:
//                pointCount = 3
//            case .closeSubpath:
//                pointCount = 0
//            @unknown default:
//                pointCount = 0
//            }
//
//            for i in 0..<pointCount {
//                points.append(pointsPointer[i])
//            }
//        }
//
//        return points
//    }
//}
//
//struct CanvasView: View {
//    @Binding var drawingPath: Path
//    @Binding var selectedColor: Color
//    @Binding var lineWidth: CGFloat
//    @Binding var score: Double?
//
//    var body: some View {
//        GeometryReader { geometry in
//            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
//
//            ZStack {
//                Circle()
//                    .fill(Color.blue)
//                    .frame(width: 10, height: 10)
//                    .position(center)
//
//                drawingPath.stroke(selectedColor, lineWidth: lineWidth)
//            }
//            .background(Color(UIColor.systemBackground))
//            .contentShape(Rectangle())
//        }
//    }
//}
//
//
//

