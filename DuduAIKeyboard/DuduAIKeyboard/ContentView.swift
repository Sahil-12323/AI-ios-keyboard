import SwiftUI

struct ContentView: View {
    @State private var step1Done = false
    @State private var step2Done = false

    var body: some View {
        ZStack {
            Color(hex: "#0D0D1A").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // ── Header ──────────────────────────────────────
                    VStack(spacing: 12) {
                        Text("✦")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "#7F77DD"))
                            .padding(.top, 60)

                        Text("Dudu AI Keyboard")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("AI-powered suggestions & writing assistant\nright inside your keyboard")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#888899"))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .padding(.bottom, 36)

                    // ── Steps ────────────────────────────────────────
                    VStack(spacing: 16) {
                        SetupCard(
                            number: "1",
                            title: "Enable the Keyboard",
                            subtitle: "Go to Settings → General → Keyboard → Keyboards → Add New Keyboard → Dudu AI",
                            done: step1Done,
                            buttonLabel: "Open Settings",
                            action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )

                        SetupCard(
                            number: "2",
                            title: "Allow Full Access",
                            subtitle: "Tap Dudu AI in keyboard list → enable \"Allow Full Access\" so AI can connect to the internet",
                            done: step2Done,
                            buttonLabel: "Open Settings",
                            action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 20)

                    // ── How to use ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        Text("HOW TO USE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#534AB7"))
                            .kerning(1.5)

                        HowToRow(icon: "✦", text: "Tap any text field to open the keyboard")
                        HowToRow(icon: "💡", text: "AI suggestions appear in the top bar — tap to insert")
                        HowToRow(icon: "⬆️", text: "Tap the expand button for the full AI writing panel")
                        HowToRow(icon: "🎨", text: "Pick a tone: Casual, Formal, Funny, Heartfelt…")
                        HowToRow(icon: "📋", text: "Tap Insert to copy result directly into your text field")
                    }
                    .padding(20)
                    .background(Color(hex: "#12122A"))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    Spacer(minLength: 50)
                }
            }
        }
        .onAppear { checkSetupStatus() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkSetupStatus()
        }
    }

    func checkSetupStatus() {
        // Check if keyboard extension is installed & has full access
        // We detect this via UserDefaults shared with the extension (App Group)
        let defaults = UserDefaults(suiteName: "group.com.dudu.ai.keyboard")
        step1Done = defaults?.bool(forKey: "keyboard_installed") ?? false
        step2Done = defaults?.bool(forKey: "full_access_granted") ?? false
    }
}

struct SetupCard: View {
    let number: String
    let title: String
    let subtitle: String
    let done: Bool
    let buttonLabel: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(done ? Color(hex: "#0F6E56") : Color(hex: "#534AB7"))
                    .frame(width: 32, height: 32)
                Text(done ? "✓" : number)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#888899"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if !done {
                    Button(action: action) {
                        Text(buttonLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "#534AB7"))
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "#12122A"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(done ? Color(hex: "#0F6E56").opacity(0.4) : Color(hex: "#534AB7").opacity(0.2), lineWidth: 1)
        )
    }
}

struct HowToRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon).font(.system(size: 14))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#CCCCDD"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

#Preview {
    ContentView()
}
