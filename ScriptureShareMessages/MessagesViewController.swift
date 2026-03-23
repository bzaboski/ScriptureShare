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
        // Always request expanded for best UX, but keep interface intact.
        if presentationStyle == .compact {
            // Allow compact; interface still usable
        }
    }

    // MARK: - Interface

    private func showMainInterface() {
        // Request expanded mode for full browse/search UI
        requestPresentationStyle(.expanded)

        // Remove existing host if present
        hostVC?.willMove(toParent: nil)
        hostVC?.view.removeFromSuperview()
        hostVC?.removeFromParent()

        let mainView = MainTabView(onInsertVerse: { [weak self] verse in
            self?.insertVerse(verse)
        })
        let host = UIHostingController(rootView: AnyView(mainView))
        hostVC = host
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    // MARK: - Verse Insertion

    /// Insert a verse as plain text into the active iMessage conversation.
    /// Works in both compact and expanded presentation modes.
    func insertVerse(_ verse: Verse) {
        let text = ShareService.shareText(for: verse)
        activeConversation?.insertText(text) { [weak self] error in
            if let error = error {
                print("ScriptureShare: insertText error — \(error)")
            }
            // Stay in expanded mode; user can see the verse they shared
        }
    }
}
