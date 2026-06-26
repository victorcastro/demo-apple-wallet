//
//  LoginRequest.swift
//  SBPCorePersonalBanking (framework estático)
//
//  Servicio `POST /login` y su DTO de respuesta.
//  Se ejecuta con `CoreRequestManager.shared.load(...)`.
//

import Foundation

public struct LoginResponseDTO: Codable {
    public let cookieJoy: String?
    public let error: String?

    public init(cookieJoy: String?, error: String?) {
        self.cookieJoy = cookieJoy
        self.error = error
    }
}

public struct LoginRequest: SBPNetworking.Request {
    public typealias Response = LoginResponseDTO
    public let path: String
    public let method: HTTPMethod
    public let body: Data?

    public init(dni: String, password: String) {
        path = "/login"
        method = .post
        body = try? JSONEncoder().encode(LoginPayload(dni: dni, password: password))
    }
}

private struct LoginPayload: Encodable {
    let dni: String
    let password: String
}
