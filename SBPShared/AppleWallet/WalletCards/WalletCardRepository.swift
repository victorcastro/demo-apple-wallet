//
//  WalletCardRepository.swift
//  DemoAppleWallet
//
//  Fachada de tarjetas para la UI. Delega el almacenamiento al `WalletEngine`
//  activo (mock en simulador, SDK real de HST en device), de modo que la UI no
//  conoce qué backend hay debajo.
//

import Foundation

public final class WalletCardRepository {

    public static let shared = WalletCardRepository()

    private let engine: WalletEngineProtocol

    init(engine: WalletEngineProtocol = WalletEngineProvider.current) {
        self.engine = engine
    }

    // MARK: - Lecturas

    public func allCards() -> [WalletCard] {
        engine.cards()
    }

    /// Tarjetas que aún pueden ofrecerse a Wallet (no provisionadas).
    public func provisionableCards() -> [WalletCard] {
        engine.cards().filter { !$0.isProvisioned }
    }

    public func card(withID id: String) -> WalletCard? {
        engine.card(withID: id)
    }

    // MARK: - Escrituras

    @discardableResult
    public func save(_ cards: [WalletCard]) -> Bool {
        engine.saveCards(cards)
    }

    public func resetAllData() {
        engine.resetCards()
    }
}
