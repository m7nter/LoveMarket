import SwiftUI

struct CalculatorView: View {
    @StateObject private var vm = CalculatorViewModel()
    var onUnlock: () -> Void

    private let buttons: [[String]] = [
        ["AC", "+/−", "%", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["0", ".", "="]
    ]

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 10
            let cols: CGFloat = 4
            let rows: CGFloat = 5
            let totalHSpacing = spacing * (cols + 1)
            let totalVSpacing = spacing * (rows + 1)
            let displayHeight = geo.size.height * 0.25
            let availableH = geo.size.height - displayHeight - totalVSpacing
            let btnSize = min(
                (geo.size.width - totalHSpacing) / cols,
                availableH / rows
            )

            ZStack {
                Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    Text(vm.display)
                        .font(.system(size: btnSize * 0.9, weight: .light))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, spacing * 2)
                        .padding(.bottom, spacing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)

                    ForEach(buttons, id: \.self) { row in
                        HStack(spacing: spacing) {
                            ForEach(row, id: \.self) { btn in
                                CalculatorButton(
                                    title: btn,
                                    vm: vm,
                                    size: btnSize,
                                    spacing: spacing
                                )
                            }
                        }
                        .padding(.bottom, spacing)
                    }
                    .padding(.horizontal, spacing)
                }
                .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : spacing)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: vm.shouldUnlock) { val in
            if val { onUnlock() }
        }
    }
}

struct CalculatorButton: View {
    let title: String
    @ObservedObject var vm: CalculatorViewModel
    let size: CGFloat
    let spacing: CGFloat

    private var isWide: Bool { title == "0" }

    private var bgColor: Color {
        switch title {
        case "AC", "+/−", "%":
            return Color(red: 0.65, green: 0.65, blue: 0.65)
        case "÷", "×", "−", "+", "=":
            return Color(red: 1.0, green: 0.62, blue: 0.04)
        default:
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        }
    }

    var body: some View {
        Button {
            vm.tap(title)
        } label: {
            Text(title)
                .font(.system(size: size * 0.38, weight: .regular))
                .foregroundColor(.white)
                .frame(
                    width: isWide ? size * 2 + spacing : size,
                    height: size
                )
                .background(bgColor)
                .clipShape(Capsule())
        }
    }
}
