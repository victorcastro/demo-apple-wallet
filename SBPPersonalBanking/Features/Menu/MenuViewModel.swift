//
//  MenuViewModel.swift
//  DemoAppleWallet
//

import Foundation
import SBPShared

final class MenuViewModel {

    private let session: SessionStore

    init(session: SessionStore = SessionStore()) {
        self.session = session
    }

    var hasLocalUser: Bool {
        session.hasActiveSession
    }

    var isFaceIDEnabled: Bool {
        session.isFaceIDEnabled
    }

    func setFaceIDEnabled(_ enabled: Bool) {
        session.setFaceIDEnabled(enabled)
    }
}
