import MossgroveKit
import SwiftUI
import UIKit
import UserNotifications

@main
struct MossgroveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                // nthcase-sample://item/{id}, on a cold start as well as a warm one
                .onOpenURL { model.open(url: $0) }
        }
    }
}

/// Shows the app's own notifications while it is in front, so "Your order is packed" is seen at once.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

/// Signed out, only the sign-in screen exists (SPEC.md §4). Signed in, the four tabs. The checkout dialog sits above
/// both.
struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            if model.signedIn {
                MainTabs()
            } else {
                SignInView()
            }
            if let dialog = model.dialog {
                DialogView(request: dialog)
            }
        }
        .tint(Color(Palette.primary))
        .onAppear { model.applyTheme() }
    }
}
