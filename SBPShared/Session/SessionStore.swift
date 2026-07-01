//
//  SessionStore.swift
//  DemoAppleWallet (Shared)
//
//  Estado de sesión que LEE la extensión desde los contenedores compartidos:
//   - `cookieJoy` (token) → Keychain del access group compartido (`SharedKeychain`).
//   - `faceIDEnabled` (flag) → UserDefaults del App Group.
//  La app espeja ambos ahí (ver `SBPSecureStore`/`SBPLocalStore` + `SessionMirror`).
//
//  Detalle INTERNO de SBPShared: solo lo usa `AuthenticationService`.
//

import Foundation

final class SessionStore {

    private enum Keys {
        static let cookieJoy = "cookieJoy"
        static let faceIDEnabled = "faceIDEnabled"
    }

    /// UserDefaults del App Group (para el flag de biometría).
    private let group: UserDefaults

    init(group: UserDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard) {
        self.group = group
    }

    // MARK: - Consultas

    /// Token de sesión, leído del Keychain compartido (lo espeja la app).
    var cookieJoy: String? {
        SharedKeychain.string(account: Keys.cookieJoy)
    }

    /// Hay un usuario con sesión guardada (la extensión solo pide contraseña).
    var hasActiveSession: Bool {
        cookieJoy?.isEmpty == false
    }

    /// El usuario activó Face ID/Touch ID para esta sesión.
    var isFaceIDEnabled: Bool {
        hasActiveSession && group.bool(forKey: Keys.faceIDEnabled)
    }

    /// DNI embebido en la `cookieJoy` (formato `...-DNI`). Permite re-loguear
    /// sin volver a pedir el DNI cuando ya hay sesión.
    var dni: String? {
        guard let cookieJoy, !cookieJoy.isEmpty else { return nil }
        if let dni = cookieJoy.split(separator: "-").last, !dni.isEmpty {
            return String(dni)
        }
        return cookieJoy
    }

    // MARK: - Mutaciones

    func save(cookieJoy: String) {
        SharedKeychain.set(cookieJoy, account: Keys.cookieJoy)
    }

    func setFaceIDEnabled(_ enabled: Bool) {
        guard hasActiveSession else {
            group.removeObject(forKey: Keys.faceIDEnabled)
            return
        }
        group.set(enabled, forKey: Keys.faceIDEnabled)
    }

    func clear() {
        SharedKeychain.delete(account: Keys.cookieJoy)
        group.removeObject(forKey: Keys.faceIDEnabled)
    }
}
