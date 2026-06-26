//
//  CoreRequestManager.swift
//  SBPCorePersonalBanking (framework estático)
//
//  Ejecutor central de los servicios. Recibe un `SBPNetworking.Request` y
//  centraliza URL, método, headers, validación de status, decodificación y
//  mapeo de errores. Singleton `shared` (configurable para tests).
//

import Foundation

public final class CoreRequestManager {

    public static let shared = CoreRequestManager()

    public static let defaultBaseURL = URL(string: "http://localhost:5001")!

    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL = CoreRequestManager.defaultBaseURL,
                session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - API

    /// Ejecuta un request y entrega el `Response` decodificado por completion.
    /// El completion puede llamarse fuera del hilo principal; usa
    /// `DispatchQueue.main.async` en el caller si vas a tocar UI.
    public func load<R: SBPNetworking.Request>(_ request: R,
                                               completion: @escaping (Result<R.Response, Error>) -> Void) {
        Task {
            do {
                completion(.success(try await load(request)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Variante async/await del mismo método.
    public func load<R: SBPNetworking.Request>(_ request: R) async throws -> R.Response {
        let urlRequest = try makeURLRequest(from: request)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw CoreRequestError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw CoreRequestError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw CoreRequestError.httpStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(R.Response.self, from: data)
        } catch {
            throw CoreRequestError.decoding(error)
        }
    }

    // MARK: - Construcción del URLRequest

    private func makeURLRequest<R: SBPNetworking.Request>(from request: R) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw CoreRequestError.invalidURL
        }
        components.path = request.path
        components.queryItems = request.queryItems
        guard let url = components.url else { throw CoreRequestError.invalidURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        if request.body != nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.headers.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }
        return urlRequest
    }
}
