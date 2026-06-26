//
//  CardRepository.swift
//  SBPPersonalBanking
//
//  Fachada de tarjetas para la UI. Delega el almacenamiento al `WalletEngine`
//  activo (mock en simulador, SDK real de HST en device), de modo que la UI no
//  conoce qué backend hay debajo.
//

import Foundation

final class CardRepository {

    static let shared = CardRepository()

    private let engine: WalletEngine

    init(engine: WalletEngine = WalletEngineProvider.current) {
        self.engine = engine
    }

    // MARK: - Lecturas

    func allCards() -> [BankCard] {
        engine.cards()
    }

    /// Tarjetas que aún pueden ofrecerse a Wallet (no provisionadas).
    func provisionableCards() -> [BankCard] {
        engine.cards().filter { !$0.isProvisioned }
    }

    func card(withID id: String) -> BankCard? {
        engine.card(withID: id)
    }

    // MARK: - Escrituras

    @discardableResult
    func save(_ cards: [BankCard]) -> Bool {
        engine.saveCards(cards)
    }

    func resetAllData() {
        engine.resetCards()
    }
}
