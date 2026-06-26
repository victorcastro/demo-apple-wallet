//
//  CoreDataStack.swift
//  SBPPersonalBanking (Shared)
//
//  Configura Core Data. Punto CLAVE: la base de datos (.sqlite) se crea dentro
//  del contenedor del App Group, para que TANTO la app COMO las extensiones
//  (que son procesos/sandboxes distintos) lean y escriban la MISMA base.
//

import Foundation
import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    /// El modelo se carga una sola vez en el proceso para evitar advertencias de
    /// "entidades duplicadas" (útil sobre todo al crear varios stacks en tests).
    private static let model: NSManagedObjectModel = {
        let bundle = Bundle(for: CoreDataStack.self)
        let url = bundle.url(forResource: "WalletDataModel", withExtension: "momd")
            ?? bundle.url(forResource: "WalletDataModel", withExtension: "mom")
        guard let modelURL = url,
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("No se encontró el modelo Core Data 'WalletDataModel'")
        }
        return model
    }()

    /// - Parameter inMemory: si es `true`, usa un store en memoria (para tests).
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WalletDataModel",
                                          managedObjectModel: Self.model)

        let description: NSPersistentStoreDescription
        if inMemory {
            description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
        } else if let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier) {
            // La base vive en la "caja compartida" del App Group.
            let storeURL = groupURL.appendingPathComponent("WalletDataModel.sqlite")
            description = NSPersistentStoreDescription(url: storeURL)
        } else {
            // Respaldo: ubicación por defecto (no debería pasar en producción).
            description = NSPersistentStoreDescription()
        }

        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Error al cargar Core Data: \(error)")
            }
        }
        // Mantiene el contexto al día con cambios hechos desde otro contexto.
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
