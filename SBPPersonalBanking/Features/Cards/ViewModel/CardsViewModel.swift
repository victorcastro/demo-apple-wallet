//
//  CardsViewModel.swift
//  SBPPersonalBanking
//
//  ViewModel (MVVM). Es quien llama a los servicios vía CoreRequestManager
//  (del framework SBPCorePersonalBanking), mapea las respuestas al modelo y
//  expone el estado a la vista mediante Combine (@Published).
//

import Foundation
import Combine
import SBPCorePersonalBanking

final class CardsViewModel {

    // Estado observable por la vista (Combine).
    @Published private(set) var cards: [BankCard] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: CardRepository

    init(repository: CardRepository = .shared) {
        self.repository = repository
        cards = repository.allCards()
    }

    /// Refresca desde el almacén del SDK (p. ej. al volver a la pantalla).
    func reload() {
        cards = repository.allCards()
    }

    /// Sincroniza con el backend: GET /cards-wallet vía CoreRequestManager, mapea
    /// y siembra el almacén del SDK (`HP2.updateDataBase`). El estado de
    /// provisioning lo deriva el repositorio del propio SDK/PassKit.
    func sync() {
        isLoading = true
        errorMessage = nil

        CoreRequestManager.shared.load(WalletCardsRequest()) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let dtos):
                    self.repository.save(dtos.map { $0.toBankCard() })
                    self.cards = self.repository.allCards()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func reset() {
        repository.resetAllData()
        cards = repository.allCards()
    }
}
