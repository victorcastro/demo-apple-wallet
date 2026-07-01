//
//  SessionMirror.swift
//  SBPPersonalBanking (App target)
//
//  Siembra única (no destructiva) de la sesión existente hacia los contenedores
//  compartidos, para cubrir a los usuarios YA logueados que no volverán a pasar
//  por el login (y por tanto nunca dispararían el dual-write de `set`).
//
//  Copia, no mueve: los datos originales (Keychain del grupo por defecto y
//  `.standard`) quedan intactos.
//

import Foundation

enum SessionMirror {

    /// Copia la sesión actual al Keychain compartido y al App Group. Idempotente:
    /// se puede llamar en cada arranque sin efectos secundarios.
    static func seedSharedGroupIfNeeded() {
        // Token: lee el ítem actual (grupo por defecto) y re-escribe → dual-write
        // siembra el Keychain compartido sin tocar el original.
        if let token = SBPSecureStore.string(forKey: .cookieJoy) {
            SBPSecureStore.set(token, forKey: .cookieJoy)
        }
        // Flag Face ID: lee local (.standard) y re-escribe → siembra App Group.
        if SBPLocalStore.object(forKey: .faceIDEnabled) != nil {
            SBPLocalStore.set(SBPLocalStore.bool(forKey: .faceIDEnabled), forKey: .faceIDEnabled)
        }

        // TODO: [Implementación real] Tener en cuenta antes de llevar esto a producción:
        //  1. Identificadores: `SBPSecureStore`/`SBPLocalStore` deben leer con el
        //     MISMO service/account/clave (y kSecAttrAccessible) que ya usa tu app
        //     hoy; si tu token vive bajo otro service/account, ajusta la lectura
        //     aquí para encontrar el ítem existente.
        //  2. Accesibilidad: al espejar el token, usa kSecAttrAccessibleAfterFirstUnlock
        //     para que la extensión pueda leerlo aunque la app no esté activa.
        //  3. Disparo: basta llamarlo una vez por arranque; si prefieres, guárdalo
        //     tras un flag de versión para no repetirlo en cada launch.
    }
}
