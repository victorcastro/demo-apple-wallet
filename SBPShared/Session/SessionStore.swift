//
//  SessionStore.swift
//  DemoAppleWallet (Shared)
//
//  Estado de sesión compartido entre la app y las extensiones. Guarda la
//  `cookieJoy` (token de sesión que devuelve el login) y la preferencia de
//  biometría en el App Group, para que todas las piezas (app + extensiones)
//  vean la misma sesión.
//
//  No hace red: solo lee/escribe el estado. El login en sí vive en
//  `AuthService` (SBPCorePersonalBanking).
//

import Foundation

public final class SessionStore {

    private enum Keys {
        static let cookieJoy = "cookieJoy"
        static let faceIDEnabled = "faceIDEnabled"
    }

    private let shared: UserDefaults
    private let standard: UserDefaults

    public init(
        shared: UserDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard,
        standard: UserDefaults = .standard
    ) {
        self.shared = shared
        self.standard = standard
    }

    // MARK: - Consultas

    /// Token de sesión. Se busca primero en el App Group y, por compatibilidad,
    /// en `standard`.
    public var cookieJoy: String? {
        shared.string(forKey: Keys.cookieJoy)
            ?? standard.string(forKey: Keys.cookieJoy)
    }

    /// Hay un usuario con sesión guardada (la extensión solo pide contraseña).
    public var hasActiveSession: Bool {
        cookieJoy?.isEmpty == false
    }

    /// El usuario activó Face ID/Touch ID para esta sesión.
    public var isFaceIDEnabled: Bool {
        hasActiveSession && shared.bool(forKey: Keys.faceIDEnabled)
    }

    /// DNI embebido en la `cookieJoy` (formato `...-DNI`). Permite re-loguear
    /// sin volver a pedir el DNI cuando ya hay sesión.
    public var dni: String? {
        guard let cookieJoy, !cookieJoy.isEmpty else { return nil }
        if let dni = cookieJoy.split(separator: "-").last, !dni.isEmpty {
            return String(dni)
        }
        return cookieJoy
    }

    // MARK: - Mutaciones

    public func save(cookieJoy: String) {
        shared.set(cookieJoy, forKey: Keys.cookieJoy)
        standard.removeObject(forKey: Keys.cookieJoy)
    }

    public func setFaceIDEnabled(_ enabled: Bool) {
        guard hasActiveSession else {
            shared.removeObject(forKey: Keys.faceIDEnabled)
            standard.removeObject(forKey: Keys.faceIDEnabled)
            return
        }
        shared.set(enabled, forKey: Keys.faceIDEnabled)
        standard.removeObject(forKey: Keys.faceIDEnabled)
    }

    public func clear() {
        for defaults in [shared, standard] {
            defaults.removeObject(forKey: Keys.cookieJoy)
            defaults.removeObject(forKey: Keys.faceIDEnabled)
        }
    }
}
