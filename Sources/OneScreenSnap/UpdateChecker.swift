import Foundation
import AppKit

public final class UpdateChecker {

    public struct ReleaseInfo {
        public let tagName: String
        public let htmlURL: String
    }

    public static func checkForUpdate() async -> ReleaseInfo? {
        let urlString = "https://api.github.com/repos/\(AppVersion.repoOwner)/\(AppVersion.repoName)/releases/latest"
        guard let url = URL(string: urlString) else { return nil }

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 10

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String else { return nil }

            return ReleaseInfo(tagName: tagName, htmlURL: htmlURL)
        } catch {
            NSLog("[OneScreenSnap] Update check failed: \(error)")
            return nil
        }
    }

    public static func isNewer(_ remoteTag: String) -> Bool {
        let remote = remoteTag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let local = AppVersion.current
        return remote.compare(local, options: .numeric) == .orderedDescending
    }

    public static func checkAndNotify() {
        Task {
            guard let release = await checkForUpdate() else {
                await MainActor.run { showUpToDateAlert() }
                return
            }
            if isNewer(release.tagName) {
                await MainActor.run { showUpdateAvailableAlert(release) }
            } else {
                await MainActor.run { showUpToDateAlert() }
            }
        }
    }

    private static func showUpdateAvailableAlert(_ release: ReleaseInfo) {
        let alert = NSAlert()
        alert.messageText = L10n.updateAvailable
        alert.informativeText = L10n.updateAvailableMessage(release.tagName, AppVersion.current)
        alert.addButton(withTitle: L10n.openDownloadPage)
        alert.addButton(withTitle: L10n.later)
        alert.alertStyle = .informational

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: release.htmlURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private static func showUpToDateAlert() {
        let alert = NSAlert()
        alert.messageText = L10n.upToDate
        alert.informativeText = L10n.upToDateMessage(AppVersion.current)
        alert.addButton(withTitle: L10n.ok)
        alert.alertStyle = .informational
        alert.runModal()
    }
}
