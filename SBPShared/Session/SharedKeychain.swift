//
//  SharedKeychain.swift
//  DemoAppleWallet (Shared)
//
//  Acceso al Keychain del access group COMPARTIDO (App Group), para que las
//  extensiones lean/escriban el token que la app espeja ahí.
//
//  Los identificadores DEBEN coincidir exactamente con `SBPSecureStore` del App
//  target, o la extensión no encontrará el ítem.
//

import Foundation
import Security

enum SharedKeychain {

    // TODO: [Implementación real] Centralizar estas constantes en un único lugar
    // compartido por la app (SBPSecureStore) y SBPShared para evitar drift: si
    // cambian aquí o allá sin sincronizar, la extensión deja de ver el token.
    private static let service = "dev.victorcastro.SBPPersonalBanking"
    private static let accessGroup = AppGroup.identifier

    static func string(account: String) -> String? {
        var query = baseQuery(account: account)
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
    static func set(_ value: String?, account: String) -> Bool {
        guard let value else { return delete(account: account) }

        let data = Data(value.utf8)
        let query = baseQuery(account: account)
        let status = SecItemUpdate(query as CFDictionary,
                                   [kSecValueData as String: data] as CFDictionary)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
        default:
            return false
        }
    }

    @discardableResult
    static func delete(account: String) -> Bool {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup
        ]
    }
}
