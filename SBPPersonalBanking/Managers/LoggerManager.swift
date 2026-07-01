//
//  LoggerManager.swift
//  DemoAppleWallet
//
//  Punto único de logging del sandbox. Cada entrada se reparte a:
//    • os.Logger → consola de Xcode y consola del dispositivo (Console.app).
//    • buffer en memoria → alimenta la consola visual del sandbox.
//
//  Centraliza también las acciones sobre el log (copiar, limpiar). La UI se
//  sincroniza suscribiéndose a `events`; no toca el buffer directamente.
//

import UIKit
import Combine
import OSLog

final class LoggerManager {

    static let shared = LoggerManager()

    /// Severidad de una entrada. La UI decide el color a partir de esto.
    enum Level {
        case info, success, error

        var osLogType: OSLogType {
            switch self {
            case .info:    return .info
            case .success: return .default
            case .error:   return .error
            }
        }
    }

    struct Entry {
        let date: Date
        let message: String
        let level: Level
    }

    /// Eventos para que la consola visual se mantenga en sincronía con el buffer.
    enum Event {
        case appended(Entry)
        case cleared
    }

    let events = PassthroughSubject<Event, Never>()

    /// Historial completo; fuente de verdad para copiar y re-render.
    private(set) var entries: [Entry] = []

    private let osLogger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "dev.victorcastro.SBPPersonalBanking",
        category: "Provisioning"
    )

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }()

    private init() {}

    // MARK: - Logging

    func log(_ message: String, level: Level = .info) {
        let entry = Entry(date: Date(), message: message, level: level)
        entries.append(entry)

        // Xcode + Console.app del dispositivo. `.public` para no redactar el texto.
        osLogger.log(level: level.osLogType, "\(message, privacy: .public)")

        events.send(.appended(entry))
    }

    // MARK: - Acciones

    func clear() {
        entries.removeAll()
        events.send(.cleared)
    }

    func copyToPasteboard() {
        UIPasteboard.general.string = plainText
    }

    /// Volcado en texto plano (con hora), para copiar o compartir.
    var plainText: String {
        entries
            .map { "\(Self.timeFormatter.string(from: $0.date))  \($0.message)" }
            .joined(separator: "\n")
    }
}
