import UIKit
import Capacitor

//class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//    var window: UIWindow?
//
//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        guard let windowScene = scene as? UIWindowScene else { return }
//
//        window = UIWindow(windowScene: windowScene)
//        window?.rootViewController = CAPBridgeViewController()
//        window?.makeKeyAndVisible()
//
//        SceneDelegateProxy.shared.scene(scene, willConnectTo: session, options: connectionOptions)
//    }
//
//    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
//        SceneDelegateProxy.shared.scene(scene, openURLContexts: URLContexts)
//    }
//
//    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
//        SceneDelegateProxy.shared.scene(scene, continue: userActivity)
//    }
//}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        let viewController = SafeAreaViewController()

        window.rootViewController = viewController
        self.window = window

        window.makeKeyAndVisible()

        // Force the root view to respect the safe area
        viewController.additionalSafeAreaInsets = UIEdgeInsets.zero

        SceneDelegateProxy.shared.scene(
            scene,
            willConnectTo: session,
            options: connectionOptions
        )
    }

    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        SceneDelegateProxy.shared.scene(
            scene,
            openURLContexts: URLContexts
        )
    }

    func scene(
        _ scene: UIScene,
        continue userActivity: NSUserActivity
    ) {
        SceneDelegateProxy.shared.scene(
            scene,
            continue: userActivity
        )
    }
}
