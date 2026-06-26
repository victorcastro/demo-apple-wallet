import Foundation

public enum SBPNetworking {
    public typealias Request = NetworkRequest
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public protocol NetworkRequest {
    associatedtype Response: Decodable
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var headers: [String: String] { get }
    var body: Data? { get }
}

public extension NetworkRequest {
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem]? { nil }
    var headers: [String: String] { [:] }
    var body: Data? { nil }
}
