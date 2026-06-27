//
//  MainTabBarController.swift
//  DemoAppleWallet
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabs()
    }

    private func configureTabs() {
        let cardsNavigationController = UINavigationController(rootViewController: CardsViewController())
        cardsNavigationController.tabBarItem = UITabBarItem(
            title: "Cards",
            image: UIImage(systemName: "creditcard"),
            selectedImage: UIImage(systemName: "creditcard.fill")
        )

        let menuNavigationController = UINavigationController(rootViewController: MenuViewController())
        menuNavigationController.tabBarItem = UITabBarItem(
            title: "Menu",
            image: UIImage(systemName: "line.3.horizontal"),
            selectedImage: UIImage(systemName: "line.3.horizontal.circle.fill")
        )

        viewControllers = [cardsNavigationController, menuNavigationController]
    }
}
