import SwiftUI

// ─── KeyboardRootView ─────────────────────────────────────────────────────────
struct KeyboardRootView: View {
    @ObservedObject var viewModel: KeyboardViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#0D0D1A").ignoresSafeArea()

            if viewModel.isPanelExpanded {
                AIPanelView(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                NormalKeyboardView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.isPanelExpanded)
    }
}

// ─── Normal Keyboard View ─────────────────────────────────────────────────────
struct NormalKeyboardView: View {
    @ObservedObject var viewModel: KeyboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            // AI suggestion bar
            SuggestionBar(viewModel: viewModel)

            // Key rows
            if viewModel.isSymbolMode {
                SymbolKeyRows(viewModel: viewModel)
            } else {
                AlphaKeyRows(viewModel: viewModel)
            }

            // Bottom toolbar
            BottomToolbar(viewModel: viewModel)
        }
        .padding(.bottom, 4)
    }
}

// ─── Suggestion Bar ────────────────────────────────────────────────────────────
struct SuggestionBar: View {
    @ObservedObject var viewModel: KeyboardViewModel

    var body: some View {
        HStack(spacing: 0) {
            // AI expand button
            Button(action: { viewModel.openPanel() }) {
                HStack(spacing: 5) {
                    Text("✦")
                        .font(.system(size: 13, weight: .bold))
                    Text("AI")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(hex: "#7F77DD"))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(hex: "#1A1A2E"))
                .cornerRadius(8)
            }
            .padding(.leading, 8)

            Divider()
                .background(Color(hex: "#222244"))
                .frame(height: 24)
                .padding(.horizontal, 6)

            // Suggestions
            if viewModel.isSuggestionsLoading {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "#1A1A2E"))
                            .frame(width: 70, height: 26)
                            .shimmer()
                    }
                }
            } else if viewModel.suggestions.isEmpty {
                Text(viewModel.currentContext.isEmpty ? "Start typing for AI suggestions…" : "Fetching suggestions…")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#444466"))
                    .padding(.leading, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(viewModel.suggestions, id: \.self) { s in
                            Button(action: { viewModel.insertSuggestion(s) }) {
                                Text(s)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#CCCCEE"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#1A1A2E"))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "#534AB7").opacity(0.4), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }

            Spacer()
        }
        .frame(height: 42)
        .background(Color(hex: "#0A0A18"))
    }
}

// ─── Alpha Key Rows ────────────────────────────────────────────────────────────
struct AlphaKeyRows: View {
    @ObservedObject var viewModel: KeyboardViewModel

    let row1 = ["q","w","e","r","t","y","u","i","o","p"]
    let row2 = ["a","s","d","f","g","h","j","k","l"]
    let row3 = ["z","x","c","v","b","n","m"]

    var body: some View {
        VStack(spacing: 8) {
            // Row 1
            HStack(spacing: 5) {
                ForEach(row1, id: \.self) { key in
                    LetterKey(label: viewModel.isShiftOn || viewModel.isCapsLock ? key.uppercased() : key, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 4)

            // Row 2 (slightly inset)
            HStack(spacing: 5) {
                ForEach(row2, id: \.self) { key in
                    LetterKey(label: viewModel.isShiftOn || viewModel.isCapsLock ? key.uppercased() : key, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 20)

            // Row 3 (with shift and backspace)
            HStack(spacing: 5) {
                // Shift
                ActionKey(icon: viewModel.isCapsLock ? "⇪" : (viewModel.isShiftOn ? "⬆" : "⇧"), color: viewModel.isShiftOn || viewModel.isCapsLock ? Color(hex: "#534AB7") : Color(hex: "#1E1E32"), width: 42) {
                    if viewModel.isShiftOn {
                        viewModel.isCapsLock = true
                        viewModel.isShiftOn = false
                    } else if viewModel.isCapsLock {
                        viewModel.isCapsLock = false
                        viewModel.isShiftOn = false
                    } else {
                        viewModel.isShiftOn = true
                    }
                }

                ForEach(row3, id: \.self) { key in
                    LetterKey(label: viewModel.isShiftOn || viewModel.isCapsLock ? key.uppercased() : key, viewModel: viewModel)
                }

                // Backspace
                ActionKey(icon: "⌫", color: Color(hex: "#1E1E32"), width: 42) {
                    viewModel.deleteBackward()
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.top, 8)
    }
}

// ─── Symbol Key Rows ───────────────────────────────────────────────────────────
struct SymbolKeyRows: View {
    @ObservedObject var viewModel: KeyboardViewModel

    let symRow1 = ["1","2","3","4","5","6","7","8","9","0"]
    let symRow2 = ["-","/",":",";","(",")","$","&","@","\""]
    let symRow3Page1 = [".",",","?","!","'"]
    let symRow3Page2 = ["[","]","{","}","#","%","^","*","+","="]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(symRow1, id: \.self) { key in
                    LetterKey(label: key, viewModel: viewModel)
                }
            }.padding(.horizontal, 4)

            HStack(spacing: 5) {
                ForEach(symRow2, id: \.self) { key in
                    LetterKey(label: key, viewModel: viewModel)
                }
            }.padding(.horizontal, 4)

            HStack(spacing: 5) {
                ActionKey(icon: viewModel.isNumber2Mode ? "123" : "#+=", color: Color(hex: "#1E1E32"), width: 42) {
                    viewModel.isNumber2Mode.toggle()
                }
                ForEach(viewModel.isNumber2Mode ? symRow3Page2 : symRow3Page1, id: \.self) { key in
                    LetterKey(label: key, viewModel: viewModel)
                }
                ActionKey(icon: "⌫", color: Color(hex: "#1E1E32"), width: 42) {
                    viewModel.deleteBackward()
                }
            }.padding(.horizontal, 4)
        }
        .padding(.top, 8)
    }
}

// ─── Bottom Toolbar ───────────────────────────────────────────────────────────
struct BottomToolbar: View {
    @ObservedObject var viewModel: KeyboardViewModel

    var body: some View {
        HStack(spacing: 5) {
            // Symbol/ABC toggle
            ActionKey(
                icon: viewModel.isSymbolMode ? "ABC" : "123",
                color: Color(hex: "#1E1E32"),
                width: 44,
                fontSize: 12
            ) {
                viewModel.isSymbolMode.toggle()
                viewModel.isNumber2Mode = false
            }

            // Next keyboard (globe)
            ActionKey(icon: "🌐", color: Color(hex: "#1E1E32"), width: 44) {
                viewModel.nextKeyboard()
            }

            // Space
            Button(action: { viewModel.insertKey(" ") }) {
                Text("space")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "#888899"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color(hex: "#1E1E32"))
                    .cornerRadius(8)
            }

            // Return
            ActionKey(icon: "↵", color: Color(hex: "#1E1E32"), width: 88, fontSize: 16) {
                viewModel.insertKey("\n")
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }
}

// ─── Key Components ────────────────────────────────────────────────────────────
struct LetterKey: View {
    let label: String
    @ObservedObject var viewModel: KeyboardViewModel

    var body: some View {
        Button(action: { viewModel.insertKey(label) }) {
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(Color(hex: "#1E1E32"))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.3), radius: 0, x: 0, y: 1)
        }
    }
}

struct ActionKey: View {
    let icon: String
    let color: Color
    let width: CGFloat
    var fontSize: CGFloat = 18
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(icon)
                .font(.system(size: fontSize))
                .foregroundColor(.white)
                .frame(width: width, height: 42)
                .background(color)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.3), radius: 0, x: 0, y: 1)
        }
    }
}

// ─── Shimmer modifier ─────────────────────────────────────────────────────────
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, Color.white.opacity(0.08), .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: phase)
                .onAppear { phase = 1 }
            )
            .clipped()
    }
}
extension View {
    func shimmer() -> some View { modifier(ShimmerModifier()) }
}
