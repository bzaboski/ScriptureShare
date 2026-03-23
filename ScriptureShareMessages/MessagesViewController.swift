import UIKit
import Messages
import SwiftUI

class MessagesViewController: MSMessagesAppViewController {

    private var hostVC: UIHostingController<AnyView>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        showMainInterface()
    }

    override func willBecomeActive(with conversation: MSConversation) {
        showMainInterface()
    }

    override func didResignActive(with conversation: MSConversation) {}

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // No special handling — interface works in both modes
    }

    // MARK: - Interface

    private func showMainInterface() {
        requestPresentationStyle(.expanded)

        hostVC?.willMove(toParent: nil)
        hostVC?.view.removeFromSuperview()
        hostVC?.removeFromParent()

        let mainView = MainTabView(onInsertText: { [weak self] text in
            self?.insertPlainText(text)
        })
        let host = UIHostingController(rootView: AnyView(mainView))
        hostVC = host
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    // MARK: - Plain Text Insert

    /// Insert plain text into the active iMessage conversation.
    /// Works in both compact and expanded presentation modes.
    private func insertPlainText(_ text: String) {
        activeConversation?.insertText(text) { error in
            if let error = error {
                print("ScriptureShare: insertText error — \(error)")
            }
        }
    }
}
