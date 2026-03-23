import UIKit
import Messages
import SwiftUI

class MessagesViewController: MSMessagesAppViewController {

    private var hostVC: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        showMainInterface()
    }

    override func willBecomeActive(with conversation: MSConversation) {
        showMainInterface()
    }

    override func didResignActive(with conversation: MSConversation) {}

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        if presentationStyle == .expanded {
            showMainInterface()
        }
    }

    private func showMainInterface() {
        requestPresentationStyle(.expanded)

        // Remove existing host view controller if any
        hostVC?.willMove(toParent: nil)
        hostVC?.view.removeFromSuperview()
        hostVC?.removeFromParent()

        let mainView = MainTabView(onInsertVerse: { [weak self] verse in
            self?.insertText(verse: verse)
        })
        let host = UIHostingController(rootView: AnyView(mainView))
        hostVC = host
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    /// Insert verse as plain text into the conversation.
    func insertText(verse: Verse) {
        activeConversation?.insertText(verse.formattedForSharing) { _ in }
    }
}
