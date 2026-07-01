//
//  SBPSecureStore.swift
//  SBPPersonalBanking (App target)
//
//  Acceso centralizado al Keychain para datos SENSIBLES (tokens como `cookieJoy`).
//
//  Espejo no destructivo: un ítem de Keychain vive en UN access group, así que se
//  escriben DOS ítems:
//   - el del grupo por defecto de la app (comportamiento actual, intacto), y
//   - una copia en el access group compartido (lo lee la extensión).
//  La app SIEMPRE lee de su grupo por defecto; el compartido es espejo de salida.
//
//  Requiere que el access group compartido esté permitido (App Groups / Keychain
//  Sharing) en la app y en la extensión. El espejo es best-effort: si falla
//  (p.ej. sin entitlement en simulador), no rompe la escritura principal.
//

import Foundation
import Security
import SBPShared

enum SBPSecureStore {

    /// Cuentas conocidas en el Keychain.
    enum Key: String {
        case cookieJoy
    }

    /// Identificador del servicio (agrupa los ítems de la app en el Keychain).
    private static let service = "dev.victorcastro.SBPPersonalBanking"

    /// Access group compartido para que la extensión lea el token. Se usa el
    /// App Group (válido como keychain access group con la capability activa).
    private static let sharedAccessGroup = AppGroup.identifier

    // MARK: - Escritura (espejo no destructivo)

    /// Guarda (o actualiza) el valor. Si es `nil`, borra la entrada.
    @discardableResult
    static func set(_ value: String?, forKey key: Key) -> Bool {
        guard let value, let data = value.data(using: .utf8) else {
            return remove(key)
        }
        let ok = write(data, for: key, accessGroup: nil)              // grupo por defecto
        _ = write(data, for: key, accessGroup: sharedAccessGroup)     // espejo (best-effort)
        return ok
    }

    // MARK: - Lectura (la app lee de su grupo por defecto)

    static func string(forKey key: Key) -> String? {
        read(key, accessGroup: nil)
    }

    // MARK: - Borrado (en ambos)

    @discardableResult
    static func remove(_ key: Key) -> Bool {
        let ok = delete(key, accessGroup: nil)
        _ = delete(key, accessGroup: sharedAccessGroup)
        return ok
    }

    // MARK: - Operaciones por access group

    private static func write(_ data: Data, for key: Key, accessGroup: String?) -> Bool {
        let query = baseQuery(for: key, accessGroup: accessGroup)
        let status = SecItemUpdate(query as CFDictionary,
                                   [kSecValueData as String: data] as CFDictionary)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            var insert = query
            insert[kSecValueData as String] = data
            return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
        default:
            return false
        }
    }

    private static func read(_ key: Key, accessGroup: String?) -> String? {
        var query = baseQuery(for: key, accessGroup: accessGroup)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    private static func delete(_ key: Key, accessGroup: String?) -> Bool {
        let status = SecItemDelete(baseQuery(for: key, accessGroup: accessGroup) as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Helpers

    private static func baseQuery(for key: Key, accessGroup: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
