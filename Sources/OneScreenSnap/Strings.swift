import Foundation

public enum L10n {
    private static var isJapanese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("ja") ?? false
    }

    // MARK: - Menu
    public static var settings: String { isJapanese ? "設定..." : "Settings..." }
    public static var checkForUpdates: String { isJapanese ? "アップデートを確認..." : "Check for Updates..." }
    public static var quit: String { isJapanese ? "終了" : "Quit" }
    public static var regionPresetsHeader: String { isJapanese ? "リージョンプリセット" : "Region Presets" }

    // MARK: - Settings Window
    public static var settingsTitle: String { isJapanese ? "OneScreenSnap 設定" : "OneScreenSnap Settings" }
    public static var displayArrangement: String { isJapanese ? "ディスプレイの配置" : "Display Arrangement" }
    public static var displayShortcuts: String { isJapanese ? "ディスプレイショートカット" : "Display Shortcuts" }
    public static var displayShortcutsDesc: String {
        isJapanese
            ? "各ディスプレイにショートカットを割り当てると、そのディスプレイ全体をクリップボードにキャプチャします。"
            : "Assign a keyboard shortcut to capture each display to clipboard."
    }
    public static var noDisplays: String { isJapanese ? "ディスプレイが検出されません" : "No displays detected" }
    public static var regionPresetsTitle: String { isJapanese ? "リージョンプリセット" : "Region Presets" }
    public static var addRegion: String { isJapanese ? "+ 範囲を追加" : "+ Add Region" }
    public static var regionPresetsDesc: String {
        isJapanese
            ? "固定範囲を定義してショートカットでキャプチャ→クリップボードにコピーします。「+ 範囲を追加」で範囲をドラッグ選択。"
            : "Define fixed regions to capture to clipboard with a single shortcut. Click '+ Add Region' then drag to select."
    }
    public static var noRegionPresets: String { isJapanese ? "リージョンプリセットなし" : "No region presets defined" }
    public static var general: String { isJapanese ? "一般" : "General" }
    public static var launchAtLogin: String { isJapanese ? "ログイン時に起動" : "Launch at login" }
    public static var launchAtLoginDisabled: String {
        isJapanese
            ? "先に 'sudo make install' を実行してください"
            : "Run 'sudo make install' first to enable this option"
    }
    public static var checkForUpdatesBtn: String { isJapanese ? "アップデートを確認" : "Check for Updates" }

    // MARK: - Shortcut Recorder
    public static var clickToRecord: String { isJapanese ? "クリックして登録" : "Click to record" }
    public static var pressShortcut: String { isJapanese ? "キーを押す..." : "Press shortcut..." }

    // MARK: - Region Selection
    public static var regionSelectionHint: String {
        isJapanese
            ? "ドラッグで範囲を選択してください。Escでキャンセル。"
            : "Drag to select a region. Press Esc to cancel."
    }

    // MARK: - Shortcut Conflict
    public static var shortcutConflictTitle: String { isJapanese ? "ショートカットの重複" : "Shortcut Conflict" }
    public static func shortcutConflictMessage(_ key: String) -> String {
        isJapanese
            ? "「\(key)」は既に別のキャプチャに割り当てられています。上書きしますか？"
            : "'\(key)' is already assigned to another capture. Do you want to replace it?"
    }
    public static var replace: String { isJapanese ? "置き換え" : "Replace" }
    public static var cancel: String { isJapanese ? "キャンセル" : "Cancel" }

    // MARK: - Update Checker
    public static var updateAvailable: String { isJapanese ? "アップデートがあります" : "Update Available" }
    public static func updateAvailableMessage(_ remote: String, _ local: String) -> String {
        isJapanese
            ? "バージョン \(remote) が利用可能です。現在 v\(local) を使用中です。"
            : "Version \(remote) is available. You are running v\(local)."
    }
    public static var openDownloadPage: String { isJapanese ? "ダウンロードページを開く" : "Open Download Page" }
    public static var later: String { isJapanese ? "あとで" : "Later" }
    public static var upToDate: String { isJapanese ? "最新版です" : "You're Up to Date" }
    public static func upToDateMessage(_ version: String) -> String {
        isJapanese
            ? "OneScreenSnap v\(version) は最新バージョンです。"
            : "OneScreenSnap v\(version) is the latest version."
    }
    public static var ok: String { isJapanese ? "OK" : "OK" }

    // MARK: - Capture Errors
    public static var captureFailedTitle: String { isJapanese ? "キャプチャ失敗" : "Capture Failed" }
    public static var captureFailedMessage: String {
        isJapanese
            ? "画面のキャプチャに失敗しました。画面収録の権限を確認してください。"
            : "Failed to capture the screen. Please check Screen Recording permission."
    }

    // MARK: - Feedback Settings
    public static var feedbackLabel: String { isJapanese ? "キャプチャ通知" : "Capture Feedback" }
    public static var feedbackSoundAndFlash: String { isJapanese ? "音 + フラッシュ" : "Sound + Flash" }
    public static var feedbackFlashOnly: String { isJapanese ? "フラッシュのみ" : "Flash only" }
    public static var feedbackNone: String { isJapanese ? "なし" : "None" }

    // MARK: - Resize Settings
    public static var resizeLabel: String { isJapanese ? "画像サイズ" : "Image Size" }
    public static var resizeFull: String { isJapanese ? "フル解像度" : "Full resolution" }
    public static var resizeAI: String { isJapanese ? "AI最適化 (長辺1568px)" : "AI optimized (max 1568px)" }

    // MARK: - Position Labels
    public static var posLeft: String { isJapanese ? "← 左" : "← Left" }
    public static var posRight: String { isJapanese ? "右 →" : "Right →" }
    public static var posCenter: String { isJapanese ? "中央" : "Center" }
}
