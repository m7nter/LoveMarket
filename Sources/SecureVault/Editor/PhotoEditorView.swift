// PhotoEditorView.swift
import SwiftUI

struct PhotoEditorView: View {
    let image: UIImage
    let onSave: (UIImage) -> Void
    let onDiscard: () -> Void

    @State private var shapes: [DrawnShape] = []
    @State private var selectedTool: DrawingTool = .arrow
    @State private var selectedColor: Color = .red
    @State private var labelText: String = ""
    @State private var showLabelInput = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geo.size.width, height: geo.size.height)

                        DrawingCanvas(shapes: $shapes,
                                      selectedTool: selectedTool,
                                      selectedColor: selectedColor)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Удалить") { onDiscard() }
                        .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") { saveComposed() }
                        .foregroundColor(.orange)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    toolButton("arrow.up.right", tool: .arrow)
                    toolButton("oval", tool: .oval)
                    Spacer()
                    colorButton(.red)
                    colorButton(.yellow)
                    Spacer()
                    Button {
                        showLabelInput = true
                    } label: {
                        Image(systemName: "textformat")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showLabelInput) {
                LabelInputSheet(text: $labelText)
            }
        }
    }

    @ViewBuilder
    private func toolButton(_ icon: String, tool: DrawingTool) -> some View {
        Button {
            selectedTool = tool
        } label: {
            Image(systemName: icon)
                .foregroundColor(selectedTool == tool ? .orange : .white)
                .font(.title2)
        }
    }

    @ViewBuilder
    private func colorButton(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 28, height: 28)
            .overlay(selectedColor == color
                     ? Circle().stroke(Color.white, lineWidth: 2) : nil)
            .onTapGesture { selectedColor = color }
    }

    private func saveComposed() {
    // Узнаём размер изображения на экране через GeometryReader — используем image.size напрямую
    let imageSize = image.size

    // Определяем реальный фрейм изображения внутри GeometryReader (scaledToFit)
    let screenSize = UIScreen.main.bounds.size
    let scaleX = screenSize.width / imageSize.width
    let scaleY = screenSize.height / imageSize.height
    let scale = min(scaleX, scaleY)
    let displayedSize = CGSize(width: imageSize.width * scale,
                               height: imageSize.height * scale)
    let offsetX = (screenSize.width - displayedSize.width) / 2
    let offsetY = (screenSize.height - displayedSize.height) / 2

    // Коэффициент масштаба из экранных координат → координаты изображения
    let toImageScale = CGSize(width: imageSize.width / displayedSize.width,
                              height: imageSize.height / displayedSize.height)

    let renderer = UIGraphicsImageRenderer(size: imageSize)
    let result = renderer.image { ctx in
        image.draw(at: .zero)

        // Рисуем все фигуры
        for shape in shapes {
            // Переводим координаты из экранных в координаты изображения
            let start = CGPoint(
                x: (shape.start.x - offsetX) * toImageScale.width,
                y: (shape.start.y - offsetY) * toImageScale.height
            )
            let end = CGPoint(
                x: (shape.end.x - offsetX) * toImageScale.width,
                y: (shape.end.y - offsetY) * toImageScale.height
            )
            let uiColor = UIColor(shape.color)
            let lineWidth: CGFloat = 2.5 * toImageScale.width

            switch shape.tool {
            case .arrow:
                drawArrowCG(ctx: ctx.cgContext, from: start, to: end,
                            color: uiColor, lineWidth: lineWidth)
            case .oval:
                let rect = CGRect(
                    x: min(start.x, end.x), y: min(start.y, end.y),
                    width: abs(end.x - start.x), height: abs(end.y - start.y)
                )
                ctx.cgContext.setStrokeColor(uiColor.cgColor)
                ctx.cgContext.setLineWidth(lineWidth)
                ctx.cgContext.strokeEllipse(in: rect)
            case .text:
                break
            }
        }

        // Текстовая метка
        if !labelText.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: imageSize.width * 0.03, weight: .semibold),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.5
            ]
            let margin: CGFloat = 16
            let size = (labelText as NSString).size(withAttributes: attrs)
            let pt = CGPoint(x: imageSize.width - size.width - margin,
                             y: imageSize.height - size.height - margin)
            (labelText as NSString).draw(at: pt, withAttributes: attrs)
        }
    }
    onSave(result)
}

private func drawArrowCG(ctx: CGContext, from start: CGPoint, to end: CGPoint,
                          color: UIColor, lineWidth: CGFloat) {
    ctx.setStrokeColor(color.cgColor)
    ctx.setLineWidth(lineWidth)
    ctx.move(to: start)
    ctx.addLine(to: end)
    ctx.strokePath()

    let angle = atan2(end.y - start.y, end.x - start.x)
    let headLen: CGFloat = 14 * lineWidth / 2.5
    let headAngle: CGFloat = .pi / 6
    ctx.move(to: end)
    ctx.addLine(to: CGPoint(x: end.x - headLen * cos(angle - headAngle),
                            y: end.y - headLen * sin(angle - headAngle)))
    ctx.move(to: end)
    ctx.addLine(to: CGPoint(x: end.x - headLen * cos(angle + headAngle),
                            y: end.y - headLen * sin(angle + headAngle)))
    ctx.strokePath()
}


struct LabelInputSheet: View {
    @Binding var text: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Введите метку...", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                Spacer()
            }
            .navigationTitle("Текстовая метка")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
