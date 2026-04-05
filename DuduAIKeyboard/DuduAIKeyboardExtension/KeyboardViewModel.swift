import SwiftUI
import Combine

// ─── KeyboardViewModel ────────────────────────────────────────────────────────
@MainActor
class KeyboardViewModel: ObservableObject {

    // Callbacks wired by KeyboardViewController
    var onInsertText: ((String) -> Void)?
    var onDeleteBackward: (() -> Void)?
    var onNextKeyboard: (() -> Void)?
    var hasFullAccess: Bool = false

    // ── State ─────────────────────────────────────────────────────────────────
    @Published var currentContext: String = "" {
        didSet { scheduleContextDebounce() }
    }

    @Published var suggestions: [String] = []
    @Published var isSuggestionsLoading = false

    @Published var isPanelExpanded = false
    @Published var promptText = ""
    @Published var resultText = ""
    @Published var isGenerating = false
    @Published var hintText = "Your AI draft will appear here ✦"
    @Published var selectedTone = "Auto"
    @Published var errorText: String? = nil

    @Published var isShiftOn = false
    @Published var isCapsLock = false
    @Published var isSymbolMode = false
    @Published var isNumber2Mode = false  // second symbol page

    var conversationHistory: [(role: String, content: String)] = []
    var lastPrompt = ""
    private var streamedResult = ""
    private var debounceTask: Task<Void, Never>?
    private var streamTask: Task<Void, Never>?

    let tones = ["Auto", "Casual", "Formal", "Funny", "Heartfelt", "Direct"]
    let presets = [
        ("🎂", "Birthday message for best friend"),
        ("🙏", "Sincere apology message"),
        ("💼", "Professional follow-up email"),
        ("🎉", "Congratulations message"),
        ("💛", "Heartfelt thank you"),
        ("😊", "Friendly casual message"),
    ]

    // ── Suggestion debounce ───────────────────────────────────────────────────
    private func scheduleContextDebounce() {
        debounceTask?.cancel()
        guard !currentContext.isEmpty && !isPanelExpanded else { return }
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s debounce
            guard !Task.isCancelled else { return }
            await fetchSuggestions()
        }
    }

    func fetchSuggestions() async {
        guard hasFullAccess, !currentContext.trimmingCharacters(in: .whitespaces).isEmpty else {
            suggestions = []
            return
        }
        isSuggestionsLoading = true
        await withCheckedContinuation { cont in
            GroqClient.getSuggestions(context: currentContext) { [weak self] result in
                self?.suggestions = result
                self?.isSuggestionsLoading = false
                cont.resume()
            }
        }
    }

    // ── Text insertion ────────────────────────────────────────────────────────
    func insertSuggestion(_ text: String) {
        onInsertText?(text + " ")
        suggestions = []
    }

    func insertKey(_ char: String) {
        var toInsert = char
        if isShiftOn && !isCapsLock {
            isShiftOn = false
        }
        onInsertText?(toInsert)
    }

    func insertResult() {
        let text = streamedResult.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onInsertText?(text)
        closePanel()
    }

    func deleteBackward() {
        onDeleteBackward?()
    }

    func nextKeyboard() {
        onNextKeyboard?()
    }

    // ── Panel ─────────────────────────────────────────────────────────────────
    func openPanel() {
        isPanelExpanded = true
        suggestions = []
        debounceTask?.cancel()
    }

    func closePanel() {
        isPanelExpanded = false
        promptText = ""
        resultText = ""
        streamedResult = ""
        hintText = "Your AI draft will appear here ✦"
        errorText = nil
        streamTask?.cancel()
    }

    // ── Generation ────────────────────────────────────────────────────────────
    func generate() {
        let prompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        guard hasFullAccess else {
            errorText = "Enable Full Access in Settings to use AI features"
            return
        }

        lastPrompt = prompt
        streamedResult = ""
        resultText = ""
        hintText = ""
        errorText = nil
        isGenerating = true
        streamTask?.cancel()

        let tone = selectedTone == "Auto" ? "" : selectedTone
        let history = conversationHistory

        streamTask = Task {
            await withCheckedContinuation { cont in
                GroqClient.stream(
                    prompt: prompt,
                    tone: tone,
                    history: history,
                    onToken: { [weak self] token in
                        self?.streamedResult += token
                        self?.resultText = self?.streamedResult ?? ""
                    },
                    onDone: { [weak self] in
                        self?.isGenerating = false
                        self?.hintText = "✓ Tap Insert to paste into your text field"
                        self?.conversationHistory.append((role: "user", content: prompt))
                        self?.conversationHistory.append((role: "assistant", content: self?.streamedResult ?? ""))
                        cont.resume()
                    },
                    onError: { [weak self] error in
                        self?.isGenerating = false
                        self?.errorText = "⚠ \(error)"
                        cont.resume()
                    }
                )
            }
        }
    }

    func retry() {
        guard !lastPrompt.isEmpty else { return }
        promptText = lastPrompt
        generate()
    }
}
