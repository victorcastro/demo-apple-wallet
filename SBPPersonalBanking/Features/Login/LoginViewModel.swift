//
//  LoginViewModel.swift
//  DemoAppleWallet
//

import Foundation
import Combine
import SBPCorePersonalBanking
import SBPShared

final class LoginViewModel {

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var loginSucceeded = false
    @Published private(set) var hasLocalUser = false
    @Published private(set) var isFaceIDAvailableForLogin = false

    private let session: SessionStore
    private let authService: AuthenticationServicing

    var hasActiveSession: Bool {
        session.hasActiveSession
    }

    init(
        session: SessionStore = SessionStore(),
        authService: AuthenticationServicing = AuthenticationService()
    ) {
        self.session = session
        self.authService = authService
        hasLocalUser = session.hasActiveSession
        isFaceIDAvailableForLogin = session.isFaceIDEnabled
    }

    func login(dni: String, password: String) {
        guard !password.isEmpty else {
            errorMessage = "Ingresa tu contraseña."
            return
        }

        let resolvedDNI: String
        if hasLocalUser {
            guard let storedDNI = session.dni else {
                syncLocalUserState()
                errorMessage = "No se encontró el usuario local."
                return
            }
            resolvedDNI = storedDNI
        } else {
            let trimmedDNI = dni.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedDNI.isEmpty else {
                errorMessage = "Ingresa tu DNI."
                return
            }
            resolvedDNI = trimmedDNI
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let cookieJoy = try await authService.login(dni: resolvedDNI, password: password)
                session.save(cookieJoy: cookieJoy)
                await MainActor.run {
                    self.isLoading = false
                    self.hasLocalUser = true
                    self.isFaceIDAvailableForLogin = self.session.isFaceIDEnabled
                    self.loginSucceeded = true
                }
            } catch let error as CoreRequestError {
                await MainActor.run {
                    self.isLoading = false
                    switch error {
                    case .httpStatus:
                        self.errorMessage = "DNI o contraseña incorrectos."
                    default:
                        self.errorMessage = error.localizedDescription
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func removeLocalUser() {
        session.clear()
        syncLocalUserState()
        errorMessage = nil
    }

    func syncLocalUserState() {
        hasLocalUser = session.hasActiveSession
        isFaceIDAvailableForLogin = session.isFaceIDEnabled
    }

    func loginWithFaceID() {
        guard isFaceIDAvailableForLogin else {
            errorMessage = "Face ID no está disponible para este usuario."
            return
        }
        errorMessage = nil
        loginSucceeded = true
    }
}
