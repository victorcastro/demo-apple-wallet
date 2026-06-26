//
//  CardRepositoryTests.swift
//  SBPPersonalBankingTests
//
//  Tests de la capa de datos sobre Core Data (store en memoria) y de las reglas
//  que determinan la disponibilidad de tarjetas para Wallet.
//

import XCTest
import CoreData

final class CardRepositoryTests: XCTestCase {

    private var stack: CoreDataStack!
    private var repository: CardRepository!

    override func setUp() {
        super.setUp()
        // Store en memoria: aislado por test, no toca el App Group real.
        stack = CoreDataStack(inMemory: true)
        repository = CardRepository(stack: stack)
    }

    override func tearDown() {
        repository = nil
        stack = nil
        super.tearDown()
    }

    func testStoreStartsEmpty() {
        XCTAssertTrue(repository.allCards().isEmpty)
    }

    func testSeedPopulatesCards() {
        repository.seedIfNeeded()
        XCTAssertEqual(repository.allCards().count, CardRepository.demoCards.count)
    }

    func testSeedIsIdempotent() {
        repository.seedIfNeeded()
        repository.seedIfNeeded()
        XCTAssertEqual(repository.allCards().count, CardRepository.demoCards.count)
    }

    func testSaveIsUpsertByCardID() {
        repository.save(CardRepository.demoCards)
        // Guardar de nuevo NO debe duplicar (mismo cardID).
        repository.save(CardRepository.demoCards)
        XCTAssertEqual(repository.allCards().count, CardRepository.demoCards.count)
    }

    func testProvisionableExcludesAddedCards() {
        repository.save(CardRepository.demoCards)
        let target = CardRepository.demoCards[0]

        repository.markProvisioned(id: target.cardID)

        let provisionable = repository.provisionableCards()
        XCTAssertEqual(provisionable.count, CardRepository.demoCards.count - 1)
        XCTAssertFalse(provisionable.contains { $0.cardID == target.cardID })
    }

    func testMarkProvisionedPersists() {
        repository.save(CardRepository.demoCards)
        let target = CardRepository.demoCards[1]

        repository.markProvisioned(id: target.cardID)

        XCTAssertEqual(repository.card(withID: target.cardID)?.isProvisioned, true)
    }

    func testFieldsRoundTripThroughCoreData() {
        let original = CardRepository.demoCards[0]
        repository.save([original])

        let stored = repository.card(withID: original.cardID)
        XCTAssertEqual(stored, original)
    }

    func testDemoCardsHaveImageAndEncCard() {
        // El seed genera imagen Base64 y un encCard con formato válido.
        for card in CardRepository.demoCards {
            XCTAssertFalse(card.cardImageBase64.isEmpty)
            XCTAssertNotNil(ProvisioningService.unpack(card.encCard),
                            "El encCard demo debe poder desempacarse en los 3 datos de Apple")
        }
    }
}
