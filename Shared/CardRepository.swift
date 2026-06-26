//
//  CardRepository.swift
//  SBPPersonalBanking
//
//  Única fuente de verdad de las tarjetas. Lee y escribe en Core Data, cuya
//  base vive en el App Group, de modo que la app y las extensiones ven los
//  mismos datos.
//

import Foundation
import CoreData

final class CardRepository {

    static let shared = CardRepository()

    private let context: NSManagedObjectContext

    init(stack: CoreDataStack = .shared) {
        self.context = stack.container.viewContext
    }

    // MARK: - Lecturas

    func allCards() -> [BankCard] {
        let request = WalletDataCardEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "cardHolderName", ascending: true)]
        let entities = (try? context.fetch(request)) ?? []
        return entities.map(BankCard.init(entity:))
    }

    /// Tarjetas que aún pueden ofrecerse a Wallet (no provisionadas).
    func provisionableCards() -> [BankCard] {
        allCards().filter { !$0.isProvisioned }
    }

    func card(withID id: String) -> BankCard? {
        entity(withID: id).map(BankCard.init(entity:))
    }

    // MARK: - Escrituras

    /// Inserta o actualiza (upsert) las tarjetas por `cardID`.
    func save(_ cards: [BankCard]) {
        for card in cards {
            let target = entity(withID: card.cardID) ?? WalletDataCardEntity(context: context)
            card.apply(to: target)
        }
        saveContext()
    }

    func markProvisioned(id: String) {
        guard let entity = entity(withID: id) else { return }
        entity.isProvisioned = true
        saveContext()
    }

    /// Borra todas las tarjetas persistidas en Core Data.
    func resetAllData() {
        deleteAll()
    }

    // MARK: - Auxiliares de Core Data

    private func entity(withID id: String) -> WalletDataCardEntity? {
        let request = WalletDataCardEntity.fetchRequest()
        request.predicate = NSPredicate(format: "cardID == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first ?? nil
    }

    private func count() -> Int {
        (try? context.count(for: WalletDataCardEntity.fetchRequest())) ?? 0
    }

    private func deleteAll() {
        let fetch: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "CardEntity")
        let delete = NSBatchDeleteRequest(fetchRequest: fetch)
        _ = try? context.execute(delete)
        context.reset()
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Error al guardar Core Data: \(error)")
        }
    }

    // MARK: - Datos demo

    static var demoCards: [BankCard] {
        [
            makeDemoCard(cardID: "card-visa-001",
                         holder: "Victor Castro",
                         last4: "4821",
                         network: "Visa",
                         type: "credit",
                         description: "SBP Visa Signature"),
            makeDemoCard(cardID: "card-mc-002",
                         holder: "Victor Castro",
                         last4: "9034",
                         network: "MasterCard",
                         type: "debit",
                         description: "SBP Mastercard World"),
            makeDemoCard(cardID: "card-amex-003",
                         holder: "Victor Castro",
                         last4: "1007",
                         network: "Amex",
                         type: "credit",
                         description: "SBP Amex Platinum")
        ]
    }

    /// Construye una tarjeta demo: genera su imagen en Base64 y un `encCard`
    /// de relleno (el `encCard` real lo entregará HST más adelante).
    private static func makeDemoCard(cardID: String,
                                     holder: String,
                                     last4: String,
                                     network: String,
                                     type: String,
                                     description: String) -> BankCard {
        var card = BankCard(cardID: cardID,
                            cardHolderName: holder,
                            cardImageBase64: "",
                            cardType: type,
                            encCard: "",
                            lastFourDigits: last4,
                            localizedDescription: description,
                            paymentNetwork: network,
                            isProvisioned: false)
        card.cardImageBase64 = CardArtRenderer.base64PNG(for: card)
        card.encCard = ProvisioningService.placeholderEncCard(for: card)
        return card
    }
}
