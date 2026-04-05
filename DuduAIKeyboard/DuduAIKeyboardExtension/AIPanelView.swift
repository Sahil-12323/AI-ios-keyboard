import SwiftUI

// ─── AI Panel View ─────────────────────────────────────────────────────────────
// Shown when user taps ✦ AI button — replaces keyboard with full AI writing UI

struct AIPanelView: View {
    @ObservedObject var viewModel: KeyboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ──────────────────────────────────────────────
            HStack {
                Text("✦ AI Assistant")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: { viewModel.closePanel() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(hex: "#888899"))
                        .padding(8)
                        .background(Color(hex: "#1A1A2E"))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {

                    // ── Preset chips ────────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.presets, id: \.0) { emoji, text in
                                Button(action: { viewModel.promptText = text }) {
                                    HStack(spacing: 4) {
                                        Text(emoji).font(.system(size: 12))
                                        Text(text)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: "#BBBBDD"))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "#1A1A2E"))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(hex: "#333355"), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                    }

                    // ── Prompt input ────────────────────────────────
                    ZStack(alignment: .topLeading) {
                        if viewModel.promptText.isEmpty {
                            Text("e.g. birthday message for my best friend")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#555566"))
                                .padding(.horizontal, 12)
                                .padding(.top, 10)
                        }
                        TextEditor(text: $viewModel.promptText)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .frame(height: 52)
                            .padding(.horizontal, 8)
                            .scrollContentBackground(.hidden)
                    }
                    .background(Color(hex: "#12122A"))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "#333355"), lineWidth: 1)
                    )
                    .padding(.horizontal, 14)

                    // ── Tone chips ──────────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.tones, id: \.self) { tone in
                                Button(action: { viewModel.selectedTone = tone }) {
                                    Text(tone)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(viewModel.selectedTone == tone ? .white : Color(hex: "#888899"))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(viewModel.selectedTone == tone ? Color(hex: "#534AB7") : Color(hex: "#1A1A2E"))
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                    }

                    // ── Generate button ─────────────────────────────
                    Button(action: { viewModel.generate() }) {
                        HStack(spacing: 6) {
                            if viewModel.isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                                Text("Generating…")
                            } else {
                                Text("Generate ✦")
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(viewModel.isGenerating ? Color(hex: "#3A3480") : Color(hex: "#534AB7"))
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isGenerating || viewModel.promptText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, 14)

                    // ── Result area ─────────────────────────────────
                    ResultCard(viewModel: viewModel)
                        .padding(.horizontal, 14)

                    // ── Action buttons ──────────────────────────────
                    if !viewModel.resultText.isEmpty && !viewModel.isGenerating {
                        HStack(spacing: 8) {
                            Button(action: { viewModel.insertResult() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.system(size: 12))
                                    Text("Insert")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(hex: "#0F6E56"))
                                .cornerRadius(10)
                            }

                            Button(action: { viewModel.retry() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12))
                                    Text("Retry")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "#9999CC"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color(hex: "#1A1A2E"))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 14)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: 10)
                }
                .padding(.bottom, 8)
            }
        }
        .background(Color(hex: "#0D0D1A"))
        .frame(maxHeight: 340)
    }
}

// ─── Result Card ──────────────────────────────────────────────────────────────
struct ResultCard: View {
    @ObservedObject var viewModel: KeyboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("AI DRAFT")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(hex: "#7F77DD"))
                    .kerning(1.2)
                Spacer()
                if !viewModel.resultText.isEmpty {
                    let words = viewModel.resultText.split(separator: " ").count
                    Text("\(words) words")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "#444466"))
                }
            }

            if let error = viewModel.errorText {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#CC6666"))
            } else if viewModel.resultText.isEmpty {
                Text(viewModel.hintText)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#444466"))
                    .italic()
            } else {
                HStack(alignment: .top, spacing: 0) {
                    Text(viewModel.resultText)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    // Blinking cursor while generating
                    if viewModel.isGenerating {
                        BlinkingCursor()
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#0A0A18"))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: "#222244"), lineWidth: 1)
        )
        .animation(.default, value: viewModel.resultText)
    }
}

// ─── Blinking Cursor ──────────────────────────────────────────────────────────
struct BlinkingCursor: View {
    @State private var visible = true

    var body: some View {
        Rectangle()
            .fill(Color(hex: "#7F77DD"))
            .frame(width: 2, height: 14)
            .opacity(visible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                    visible = false
                }
            }
            .padding(.leading, 2)
            .padding(.top, 2)
    }
}
