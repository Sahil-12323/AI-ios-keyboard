import UIKit
import SwiftUI

// ─── KeyboardViewController ───────────────────────────────────────────────────
// Entry point for the iOS Keyboard Extension.
// Hosts a SwiftUI KeyboardView via UIHostingController.

class KeyboardViewController: UIInputViewController {

    private var hostingController: UIHostingController<KeyboardRootView>?
    private var keyboardViewModel = KeyboardViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Signal to the main app that extension is active + full access status
        let defaults = UserDefaults(suiteName: "group.com.dudu.ai.keyboard")
        defaults?.set(true, forKey: "keyboard_installed")
        defaults?.set(hasFullAccess, forKey: "full_access_granted")

        // Wire up text insertion callback
        keyboardViewModel.onInsertText = { [weak self] text in
            self?.textDocumentProxy.insertText(text)
        }
        keyboardViewModel.onDeleteBackward = { [weak self] in
            self?.textDocumentProxy.deleteBackward()
        }
        keyboardViewModel.onNextKeyboard = { [weak self] in
            self?.advanceToNextInputMode()
        }
        keyboardViewModel.hasFullAccess = hasFullAccess

        let rootView = KeyboardRootView(viewModel: keyboardViewModel)
        let hc = UIHostingController(rootView: rootView)
        hostingController = hc

        addChild(hc)
        view.addSubview(hc.view)
        hc.didMove(toParent: self)

        hc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hc.view.topAnchor.constraint(equalTo: view.topAnchor),
            hc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        view.backgroundColor = UIColor(Color(hex: "#0D0D1A"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh context when keyboard appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshContext()
        }
    }

    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        refreshContext()
    }

    private func refreshContext() {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        keyboardViewModel.currentContext = String(before.suffix(80))
    }
}
