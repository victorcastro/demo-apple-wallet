//
//  MenuViewModel.swift
//  DemoAppleWallet
//

import Foundation
import SBPShared

final class MenuViewModel {

    var hasLocalUser: Bool {
        cookieJoy?.isEmpty == false
    }

    /// Vacía el store local de tarjetas (CoreData del SDK en device, mock en
    /// simulador). Se repuebla al volver a sincronizar desde Mockoon.
    func resetCards() {
        WalletCardRepository.shared.resetAllData()
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
