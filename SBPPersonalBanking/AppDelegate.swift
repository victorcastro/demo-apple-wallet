//
//  AppDelegate.swift
//  DemoAppleWallet
//
//  Created by Victor Castro on 25/06/26.
//

import UIKit
import SBPShared

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Siembra la sesión existente hacia los contenedores compartidos para
        // cubrir a los usuarios ya logueados (no pasan por login onboarding).
        SessionMirror.seedSharedGroupIfNeeded()
        // Inicializa el WalletEngine (y con él el SDK HP2 + su Core Data) al
        // arrancar, para que esté listo antes de la primera interacción con Wallet
        // y para retener la instancia durante toda la vida del proceso.
        _ = WalletEngineProvider.current
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
