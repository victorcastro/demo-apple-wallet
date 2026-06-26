import Foundation

public enum CoreRequestError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(Error)
    case transport(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida."
        case .invalidResponse: return "Respuesta inválida del servidor."
        case .httpStatus(let code): return "El servidor respondió con código \(code)."
        case .decoding: return "No se pudo interpretar la respuesta del servidor."
        case .transport(let error): return error.localizedDescription
        }
    }
}
