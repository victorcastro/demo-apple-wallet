//
//  WalletDataCardEntity.swift
//  SBPPersonalBanking (Shared)
//
//  Subclase de NSManagedObject para la tarjeta de pago provisionable en Apple
//  Wallet, con la estructura exacta que pide el proveedor HST (8 campos String)
//  más el campo local `isProvisioned`.
//
//  Nombres a propósito:
//   - Nombre de ENTIDAD en el modelo: "CardEntity" (corto; dentro de
//     WalletDataModel ya se entiende que es de Wallet).
//   - Nombre de CLASE Swift: WalletDataCardEntity (único globalmente, evita
//     colisiones de tipo con otras "Card" a futuro).
//
//  ⚠️ Como el nombre de entidad y el de la clase difieren, los fetch requests y
//  predicados usan SIEMPRE el entity name "CardEntity", no el de la clase.
//
//  Codegen MANUAL + `@objc(WalletDataCardEntity)`: como el modelo se comparte
//  entre la app y varias extensiones (módulos distintos), el nombre fijo en el
//  runtime de Obj-C garantiza que Core Data encuentre la clase en todos ellos.
//

import Foundation
import CoreData

@objc(WalletDataCardEntity)
public final class WalletDataCardEntity: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WalletDataCardEntity> {
        NSFetchRequest<WalletDataCardEntity>(entityName: "CardEntity")
    }

    // Campos definidos por HST (todos String)
    @NSManaged public var cardHolderName: String?
    @NSManaged public var cardID: String?
    @NSManaged public var cardImageBase64: String?
    @NSManaged public var cardType: String?
    @NSManaged public var encCard: String?
    @NSManaged public var lastFourDigits: String?
    @NSManaged public var localizedDescription: String?
    @NSManaged public var paymentNetwork: String?

    // Campo local (no forma parte del payload de HST)
    @NSManaged public var isProvisioned: Bool
}
