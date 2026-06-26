//
//  LoginViewModel.swift
//  SBPPersonalBanking
//

import Foundation
import Combine
import SBPCorePersonalBanking

final class LoginViewModel {

    private enum SessionStorage {
        static let cookieJoyKey = "cookieJoy"
        static let faceIDEnabledKey = "faceIDEnabled"
    }

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var loginSucceeded = false
    @Published private(set) var hasLocalUser = false
    @Published private(set) var isFaceIDAvailableForLogin = false

    private let sharedUserDefaults: UserDefaults
    private let standardUserDefaults: UserDefaults

    init(
        sharedUserDefaults: UserDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard,
        standardUserDefaults: UserDefaults = .standard
    ) {
        self.sharedUserDefaults = sharedUserDefaults
        self.standardUserDefaults = standardUserDefaults
        hasLocalUser = hasActiveSession
        isFaceIDAvailableForLogin = isFaceIDEnabled
    }

    var hasActiveSession: Bool {
        cookieJoy?.isEmpty == false
    }

    func login(dni: String, password: String) {
        guard !password.isEmpty else {
            errorMessage = "Ingresa tu contraseña."
            return
        }

        let resolvedDNI: String
        if hasLocalUser {
            guard let cookieJoy, !cookieJoy.isEmpty else {
                syncLocalUserState()
                errorMessage = "No se encontró el usuario local."
                return
            }
            resolvedDNI = extractDNI(from: cookieJoy)
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
                let response = try await CoreRequestManager.shared.load(LoginRequest(dni: resolvedDNI, password: password))
                guard let cookieJoy = response.cookieJoy, !cookieJoy.isEmpty else {
                    throw LoginError.missingCookie
                }

                saveCookieJoy(cookieJoy)
                await MainActor.run {
                    self.isLoading = false
                    self.hasLocalUser = true
                    self.isFaceIDAvailableForLogin = self.isFaceIDEnabled
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
        clearSession()
        syncLocalUserState()
        errorMessage = nil
    }

    func syncLocalUserState() {
        hasLocalUser = hasActiveSession
        isFaceIDAvailableForLogin = isFaceIDEnabled
    }

    func loginWithFaceID() {
        guard isFaceIDAvailableForLogin else {
            errorMessage = "Face ID no está disponible para este usuario."
            return
        }
        errorMessage = nil
        loginSucceeded = true
    }

    private func extractDNI(from cookieJoy: String) -> String {
        if let dni = cookieJoy.split(separator: "-").last, !dni.isEmpty {
            return String(dni)
        }
        return cookieJoy
    }

    private var cookieJoy: String? {
        sharedUserDefaults.string(forKey: SessionStorage.cookieJoyKey)
            ?? standardUserDefaults.string(forKey: SessionStorage.cookieJoyKey)
    }

    private var isFaceIDEnabled: Bool {
        hasActiveSession && sharedUserDefaults.bool(forKey: SessionStorage.faceIDEnabledKey)
    }

    private func saveCookieJoy(_ cookieJoy: String) {
        sharedUserDefaults.set(cookieJoy, forKey: SessionStorage.cookieJoyKey)
        standardUserDefaults.removeObject(forKey: SessionStorage.cookieJoyKey)
    }

    private func clearSession() {
        sharedUserDefaults.removeObject(forKey: SessionStorage.cookieJoyKey)
        sharedUserDefaults.removeObject(forKey: SessionStorage.faceIDEnabledKey)
        standardUserDefaults.removeObject(forKey: SessionStorage.cookieJoyKey)
        standardUserDefaults.removeObject(forKey: SessionStorage.faceIDEnabledKey)
    }
}

private extension LoginViewModel {
    enum LoginError: LocalizedError {
        case missingCookie

        var errorDescription: String? {
            switch self {
            case .missingCookie:
                return "El login fue correcto, pero no llegó cookieJoy."
            }
        }
    }
}
