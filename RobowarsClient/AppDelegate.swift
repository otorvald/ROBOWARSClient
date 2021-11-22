//
//  AppDelegate.swift
//  RobowarsClient
//
//  Created by Maksym Bystryk on 04.10.2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var rootViewController: RWTournamentViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let window = self.window ?? UIWindow(frame: UIScreen.main.bounds)
        let controller = rootViewController ?? RWTournamentViewController()
        rootViewController = controller
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        
        return true
    }
}

