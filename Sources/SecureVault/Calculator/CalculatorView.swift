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
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer()

                Text(vm.display)
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 24)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)

                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { btn in
                            CalculatorButton(title: btn, vm: vm)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .onChange(of: vm.shouldUnlock) { val in
            if val { onUnlock() }
        }
    }
}

struct CalculatorButton: View {
    let title: String
    @ObservedObject var vm: CalculatorViewModel

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
                .font(.system(size: 32, weight: .regular))
                .foregroundColor(.white)
                .frame(width: isWide ? 171 : 80, height: 80)
                .background(bgColor)
                .clipShape(Capsule())
        }
    }
}
