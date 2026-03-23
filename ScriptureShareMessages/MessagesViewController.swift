import UIKit
import Messages
import SwiftUI

class MessagesViewController: MSMessagesAppViewController {

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
        let searchView = SearchView(onSelectVerse: { [weak self] verse in
            self?.insert(verse: verse)
        })
        let host = UIHostingController(rootView: searchView)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private func insert(verse: Verse) {
        guard let conversation = activeConversation else { return }
        let layout = MSMessageTemplateLayout()
        layout.caption = verse.formattedForSharing
        let message = MSMessage()
        message.layout = layout
        conversation.insert(message) { _ in }
    }
}
