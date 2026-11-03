import Foundation
import UserNotifications

/// Local notifications only: nothing is pushed from a server, and nothing is posted unless the person allowed it.
/// Asking is the app's one system permission prompt (SPEC.md §5, Settings).
@MainActor
final class NotificationService {
    private var center: UNUserNotificationCenter { .current() }

    /// Whether the system lets the app post notifications now.
    func allowed() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    /// Shows the system prompt the first time; after a refusal the system answers without asking.
    func request() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
