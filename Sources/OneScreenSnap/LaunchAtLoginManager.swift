import Foundation

public final class LaunchAtLoginManager {
    private static let plistName = "com.onescreensnap.app.plist"

    private static var plistPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/LaunchAgents/\(plistName)"
    }

    /// Path to the executable inside the .app bundle, or the bare binary as fallback
    private static var executablePath: String {
        // If running from a .app bundle, use the bundle's executable path
        if let bundlePath = Bundle.main.executablePath,
           bundlePath.contains(".app/Contents/MacOS/") {
            return bundlePath
        }
        // Fallback: check if installed as .app in /Applications
        let appPath = "/Applications/OneScreenSnap.app/Contents/MacOS/OneScreenSnap"
        if FileManager.default.fileExists(atPath: appPath) {
            return appPath
        }
        return Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]
    }

    public static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    /// Always available — uses the current executable path
    public static var isInstalled: Bool { true }

    public static func setEnabled(_ enabled: Bool) {
        if enabled {
            enable()
        } else {
            disable()
        }
    }

    private static func enable() {
        let dir = (plistPath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)

        let path = executablePath
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.onescreensnap.app</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(path)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """
        try? plist.write(toFile: plistPath, atomically: true, encoding: .utf8)
        NSLog("[OneScreenSnap] Launch at login enabled with path: \(path)")
    }

    private static func disable() {
        try? FileManager.default.removeItem(atPath: plistPath)
        NSLog("[OneScreenSnap] Launch at login disabled")
    }
}
