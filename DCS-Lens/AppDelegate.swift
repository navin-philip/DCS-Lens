import UIKit
import SwiftUI // Needed for @main if this were the entry point, but we use @UIApplicationDelegateAdaptor

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow? // Required even if using SwiftUI App lifecycle for some delegate methods
    var backgroundSessionCompletionHandler: (() -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("[AppDelegate] Application did finish launching.")
        return true
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        // Store the completion handler to call when all background tasks are finished.
        backgroundSessionCompletionHandler = completionHandler
        print("[AppDelegate] Handling events for background session: \(identifier)")
    }
    
    // Add other AppDelegate methods if needed (e.g., for push notifications)
} 