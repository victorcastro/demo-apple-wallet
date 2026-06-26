//
//  ProvisioningService.swift
//  SBPPersonalBanking
//
//  Convierte el `encCard` guardado (el paquete cifrado que entrega HST) en los
//  TRES datos que Apple exige para agregar una tarjeta:
//     - encryptedPassData
//     - activationData
//     - ephemeralPublicKey
//
//  Formato (provisional, para el mock): `encCard` es un JSON en Base64 cuyos
//  valores también van en Base64. Cuando se integre HST real, solo hay que
//  ajustar `unpack(_:)` y `placeholderEncCard(for:)` a su formato.
//

import Foundation

struct EncryptedPassPayload {
    let encryptedPassData: Data
    let activationData: Data
    let ephemeralPublicKey: Data
}

enum ProvisioningError: Error {
    case cardNotFound
    case invalidEncCard
}

final class ProvisioningService {

    static let shared = ProvisioningService()

    private enum Keys {
        static let encryptedPassData = "encryptedPassData"
        static let activationData = "activationData"
        static let ephemeralPublicKey = "ephemeralPublicKey"
    }

    /// Devuelve el payload listo para construir el `PKAddPaymentPassRequest`,
    /// desempacando el `encCard` almacenado de la tarjeta.
    func payload(forCardID id: String) -> Result<EncryptedPassPayload, Error> {
        guard let card = CardRepository.shared.card(withID: id) else {
            return .failure(ProvisioningError.cardNotFound)
        }
        guard let payload = Self.unpack(card.encCard) else {
            return .failure(ProvisioningError.invalidEncCard)
        }
        return .success(payload)
    }

    // MARK: - Empaquetado / desempaquetado del encCard

    /// Desempaca el `encCard` (JSON en Base64) en los 3 datos de Apple.
    static func unpack(_ encCard: String) -> EncryptedPassPayload? {
        guard let jsonData = Data(base64Encoded: encCard),
              let object = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String],
              let epd = object[Keys.encryptedPassData].flatMap({ Data(base64Encoded: $0) }),
              let act = object[Keys.activationData].flatMap({ Data(base64Encoded: $0) }),
              let epk = object[Keys.ephemeralPublicKey].flatMap({ Data(base64Encoded: $0) }) else {
            return nil
        }
        return EncryptedPassPayload(encryptedPassData: epd,
                                    activationData: act,
                                    ephemeralPublicKey: epk)
    }

    /// Genera un `encCard` de relleno para los datos demo. En producción este
    /// valor lo entrega HST por backend; aquí solo creamos algo con el formato
    /// correcto para que el flujo sea ejercitable.
    static func placeholderEncCard(for card: BankCard) -> String {
        let dictionary = [
            Keys.encryptedPassData: Data("ENC-\(card.cardID)".utf8).base64EncodedString(),
            Keys.activationData: Data("ACT-\(card.cardID)".utf8).base64EncodedString(),
            Keys.ephemeralPublicKey: Data("EPK-\(card.cardID)".utf8).base64EncodedString()
        ]
        let json = (try? JSONSerialization.data(withJSONObject: dictionary)) ?? Data()
        return json.base64EncodedString()
    }
}
