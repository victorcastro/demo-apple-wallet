//
//  MenuViewModel.swift
//  DemoAppleWallet
//

import Foundation

final class MenuViewModel {

    var hasLocalUser: Bool {
        cookieJoy?.isEmpty == false
    }

    var isFaceIDEnabled: Bool {
        hasLocalUser && SBPLocalStore.bool(forKey: .faceIDEnabled)
    }

    func setFaceIDEnabled(_ enabled: Bool) {
        guard hasLocalUser else {
            SBPLocalStore.remove(.faceIDEnabled)
            return
        }
        SBPLocalStore.set(enabled, forKey: .faceIDEnabled)
    }

    private var cookieJoy: String? {
        SBPSecureStore.string(forKey: .cookieJoy)
    }
}
