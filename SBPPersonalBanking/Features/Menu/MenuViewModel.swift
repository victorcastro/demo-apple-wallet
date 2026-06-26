//
//  MenuViewModel.swift
//  SBPPersonalBanking
//

import Foundation

final class MenuViewModel {

    private enum SessionStorage {
        static let cookieJoyKey = "cookieJoy"
        static let faceIDEnabledKey = "faceIDEnabled"
    }

    private let sharedUserDefaults: UserDefaults
    private let standardUserDefaults: UserDefaults

    init(
        sharedUserDefaults: UserDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard,
        standardUserDefaults: UserDefaults = .standard
    ) {
        self.sharedUserDefaults = sharedUserDefaults
        self.standardUserDefaults = standardUserDefaults
    }

    var hasLocalUser: Bool {
        cookieJoy?.isEmpty == false
    }

    var isFaceIDEnabled: Bool {
        hasLocalUser && sharedUserDefaults.bool(forKey: SessionStorage.faceIDEnabledKey)
    }

    func setFaceIDEnabled(_ enabled: Bool) {
        guard hasLocalUser else {
            sharedUserDefaults.removeObject(forKey: SessionStorage.faceIDEnabledKey)
            standardUserDefaults.removeObject(forKey: SessionStorage.faceIDEnabledKey)
            return
        }
        sharedUserDefaults.set(enabled, forKey: SessionStorage.faceIDEnabledKey)
        standardUserDefaults.removeObject(forKey: SessionStorage.faceIDEnabledKey)
    }

    private var cookieJoy: String? {
        sharedUserDefaults.string(forKey: SessionStorage.cookieJoyKey)
            ?? standardUserDefaults.string(forKey: SessionStorage.cookieJoyKey)
    }
}
