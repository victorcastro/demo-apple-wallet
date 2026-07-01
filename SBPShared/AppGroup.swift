//
//  AppGroup.swift
//  DemoAppleWallet
//
//  Constante compartida por la app y las extensiones. Es la "llave" del App
//  Group: el almacén común donde vive la base de datos Core Data, para que
//  todas las piezas (app + extensiones) puedan leer/escribir las mismas
//  tarjetas.
//

import Foundation

public enum AppGroup {
    /// Debe coincidir con el App Group declarado en los entitlements de cada
    /// target y registrado en el portal de Apple Developer.
    public static let identifier = "group.dev.victorcastro.DemoWallet"
}
