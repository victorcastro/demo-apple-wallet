//
//  CardRepository.swift
//  SBPPersonalBanking
//
//  Única fuente de verdad de las tarjetas para la UI. Es una fachada delgada
//  sobre el SDK del emisor (HP2AppleSDK): el SDK es el dueño del almacén
//  (Core Data `CardExtensionData` en el App Group), y aquí solo traducimos
//  entre su `CardDataModel` y el `BankCard` que consume la app.
//

import Foundation
import HP2AppleSDK

final class CardRepository {

    static let shared = CardRepository()

    private let hp2: HP2

    init(sdk: HP2 = WalletSDK.shared) {
        self.hp2 = sdk
    }

    // MARK: - Lecturas

    func allCards() -> [BankCard] {
        hp2.getCardsFromCoreData()
            .map { BankCard(model: $0, isProvisioned: isProvisioned(cardID: $0.cardID ?? "")) }
            .sorted { $0.cardHolderName < $1.cardHolderName }
    }

    /// Tarjetas que aún pueden ofrecerse a Wallet (no provisionadas).
    func provisionableCards() -> [BankCard] {
        allCards().filter { !$0.isProvisioned }
    }

    func card(withID id: String) -> BankCard? {
        guard let model = hp2.getCardDataModel(cardID: id) else { return nil }
        return BankCard(model: model, isProvisioned: isProvisioned(cardID: id))
    }

    // MARK: - Escrituras

    /// Inserta o actualiza las tarjetas en el almacén del SDK.
    @discardableResult
    func save(_ cards: [BankCard]) -> Bool {
        let result = hp2.updateDataBase(cardDataList: cards.map(\.asCardDataModel))
        return result == DataBaseErrors.SUCCESS.rawValue
    }

    /// Best-effort: el SDK no expone un borrado explícito, así que reescribimos
    /// el almacén con una lista vacía.
    func resetAllData() {
        _ = hp2.updateDataBase(cardDataList: [])
    }

    // MARK: - Estado de provisioning

    /// Una tarjeta está "provisionada" cuando ya NO está disponible para
    /// agregarse (PassKit/SDK son la fuente de verdad, no un flag local).
    private func isProvisioned(cardID: String) -> Bool {
        guard !cardID.isEmpty else { return false }
        return !hp2.isAvailableForCard(panRefId: cardID)
    }
}
