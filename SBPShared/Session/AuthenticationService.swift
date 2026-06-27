//
//  AuthenticationService.swift
//  DemoAppleWallet (Shared)
//
//  Autenticador completo, reutilizable por la app y por las extensiones.
//  Encapsula TODA la lógica de auth/sesión: estado de sesión, resolución del DNI,
//  login con contraseña, desbloqueo por biometría y persistencia de la `cookieJoy`.
//  Los consumidores (p.ej. la pantalla de autorización de Wallet) solo invocan
//  estos métodos; no tocan `SessionStore` ni `LocalAuthentication` directamente.
//
//  Reutiliza la capa de red de `SBPCorePersonalBanking`
//  (`CoreRequestManager.shared` + `LoginRequest`).
//

import Foundation
import LocalAuthentication
import SBPCorePersonalBanking

public protocol AuthenticationServicing {
    /// Hay una sesión previa (cookieJoy) creada desde la app.
    var hasActiveSession: Bool { get }
    /// El usuario activó biometría para esta sesión.
    var isBiometricLoginAvailable: Bool { get }
    /// Login con contraseña: resuelve el DNI de la sesión y persiste la nueva cookieJoy.
    func loginWithPassword(_ password: String) async throws
    /// Desbloqueo por biometría (la sesión ya existe; no vuelve a llamar al backend).
    func loginWithBiometrics() async throws
}

public final class AuthenticationService: AuthenticationServicing {

    private let requestManager: CoreRequestManager
    private let session = SessionStore()

    public init(requestManager: CoreRequestManager = .shared) {
        self.requestManager = requestManager
    }

    public var hasActiveSession: Bool {
        session.hasActiveSession
    }

    public var isBiometricLoginAvailable: Bool {
        session.isFaceIDEnabled
    }

    // TODO: Implementar el login completo
    public func loginWithPassword(_ password: String) async throws {
        guard !password.isEmpty else {
            throw AuthenticationError.emptyPassword
        }
        // La extensión no pide DNI: usa el de la sesión previa (cookieJoy).
        guard session.hasActiveSession, let dni = session.dni else {
            throw AuthenticationError.noActiveSession
        }

        // DEMO: un único servicio. PRODUCCIÓN: aquí se encadenan los 4 servicios de
        // HST; el último devuelve la cookieJoy. Único punto de extensión.
        do {
            let response = try await requestManager.load(LoginRequest(dni: dni, password: password))
            guard let cookieJoy = response.cookieJoy, !cookieJoy.isEmpty else {
                throw AuthenticationError.missingCookie
            }
            session.save(cookieJoy: cookieJoy)
        } catch let error as CoreRequestError {
            if case .httpStatus = error {
                throw AuthenticationError.invalidCredentials
            }
            throw error
        }
    }

    public func loginWithBiometrics() async throws {
        guard session.isFaceIDEnabled else {
            throw AuthenticationError.biometricsNotEnabled
        }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        let reason = "Autentícate para agregar tu tarjeta SBP a Apple Wallet."

        let success = await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                   localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }

        guard success else {
            throw AuthenticationError.biometricsFailed
        }
        // La sesión ya existe (cookieJoy guardada): la biometría solo la desbloquea.
    }
}

public enum AuthenticationError: LocalizedError {
    case emptyPassword
    case noActiveSession
    case invalidCredentials
    case missingCookie
    case biometricsNotEnabled
    case biometricsFailed

    public var errorDescription: String? {
        switch self {
        case .emptyPassword:
            return "Ingresa tu contraseña."
        case .noActiveSession:
            return "Abre la app SBP e inicia sesión antes de agregar tu tarjeta."
        case .invalidCredentials:
            return "Contraseña incorrecta."
        case .missingCookie:
            return "El login fue correcto, pero no llegó cookieJoy."
        case .biometricsNotEnabled:
            return "Activa Face ID en la app para usarlo aquí."
        case .biometricsFailed:
            return "No se pudo validar con biometría. Usa tu contraseña."
        }
    }
}
