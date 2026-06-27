//
//  AuthenticationService.swift
//  DemoAppleWallet (Shared)
//
//  Método general de login, reutilizable por la app y por las extensiones.
//  Ejecuta el flujo de autenticación y devuelve la `cookieJoy` (token de sesión).
//
//  Vive junto a `SessionStore` (estado de sesión) y reutiliza la capa de red de
//  `SBPCorePersonalBanking` (`CoreRequestManager.shared` + `LoginRequest`).
//  La persistencia de la sesión NO vive aquí: la guarda `SessionStore`.
//

import Foundation
import SBPCorePersonalBanking

public protocol AuthenticationServicing {
    func login(dni: String, password: String) async throws -> String
}

public final class AuthenticationService: AuthenticationServicing {

    private let requestManager: CoreRequestManager

    public init(requestManager: CoreRequestManager = .shared) {
        self.requestManager = requestManager
    }

    // TODO: Implementar el login completo
    public func login(dni: String, password: String) async throws -> String {
        let response: LoginResponseDTO = try await requestManager.load(LoginRequest(dni: dni, password: password))
        guard let cookieJoy = response.cookieJoy, !cookieJoy.isEmpty else {
            throw AuthenticationError.missingCookie
        }
        return cookieJoy
    }
}

public enum AuthenticationError: LocalizedError {
    case missingCookie

    public var errorDescription: String? {
        switch self {
        case .missingCookie:
            return "El login fue correcto, pero no llegó cookieJoy."
        }
    }
}
