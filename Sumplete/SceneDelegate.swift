//
//  SceneDelegate.swift
//  Sumplete
//
//  Created by Jiro on 4/3/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let gameVC = GameViewController()
        gameVC.tabBarItem = UITabBarItem(
            title: "Play",
            image: UIImage(systemName: "number.square"),
            selectedImage: UIImage(systemName: "number.square.fill")
        )
        
        let statsVC = StatsViewController()
        statsVC.tabBarItem = UITabBarItem(
            title: "Stats",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )
        
        let howToPlayVC = HowToPlayViewController()
        howToPlayVC.tabBarItem = UITabBarItem(
            title: "How to Play",
            image: UIImage(systemName: "questionmark.circle"),
            selectedImage: UIImage(systemName: "questionmark.circle.fill")
        )
        
        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [gameVC, statsVC, howToPlayVC, settingsVC]
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Save game when user switches away from the app
        saveCurrentGame()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Also save when entering background as a safety net
        saveCurrentGame()
    }
    
    private func saveCurrentGame() {
        guard let tabBar = window?.rootViewController as? UITabBarController,
              let gameVC = tabBar.viewControllers?.first as? GameViewController else { return }
        gameVC.saveGame()
    }
}

