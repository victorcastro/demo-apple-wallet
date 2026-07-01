//
//  SBPLocalStore.swift
//  SBPPersonalBanking (App target)
//
//  Acceso centralizado a `UserDefaults` para datos NO sensibles (flags, prefs).
//  Los datos sensibles (tokens) van en `SBPSecureStore` (Keychain).
//
//  La app SIEMPRE lee de `.standard` (su comportamiento no cambia). El App Group
//  es solo un ESPEJO DE SALIDA: cada escritura se copia ahí para que la extensión
//  (que lee el grupo por su lado) la vea. No hay migración ni cambio de autoridad
//  de lectura en la app.
//

import Foundation
import SBPShared

enum SBPLocalStore {

    /// Claves conocidas. Centralizadas para evitar strings sueltos.
    enum Key: String {
        case faceIDEnabled
    }

    /// Almacén local del App target (bundle `dev.victorcastro.SBPPersonalBanking`).
    private static let local: UserDefaults = .standard

    /// Almacén compartido (App Group): lo que la extensión puede leer.
    private static let localGroup: UserDefaults? = UserDefaults(suiteName: AppGroup.identifier)

    // MARK: - Escritura (dual-write)

    static func set(_ value: Any?, forKey key: Key) {
        local.set(value, forKey: key.rawValue)
        localGroup?.set(value, forKey: key.rawValue)
    }

    // MARK: - Lectura (siempre desde local)

    static func string(forKey key: Key) -> String? {
        local.string(forKey: key.rawValue)
    }

    static func bool(forKey key: Key) -> Bool {
        local.bool(forKey: key.rawValue)
    }

    static func object(forKey key: Key) -> Any? {
        local.object(forKey: key.rawValue)
    }

    // MARK: - Borrado (en ambos)

    static func remove(_ key: Key) {
        local.removeObject(forKey: key.rawValue)
        localGroup?.removeObject(forKey: key.rawValue)
    }
}
