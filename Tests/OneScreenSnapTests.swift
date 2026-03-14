import XCTest
@testable import OneScreenSnapLib

final class OneScreenSnapTests: XCTestCase {

    func testDisplayManagerDetectsDisplays() {
        let manager = DisplayManager()
        XCTAssertFalse(manager.displays.isEmpty, "Should detect at least one display")
    }

    func testDisplayManagerMainDisplay() {
        let manager = DisplayManager()
        let mainDisplay = manager.displays.first(where: { $0.isMain })
        XCTAssertNotNil(mainDisplay, "Should have a main display")
    }

    func testDisplayInfoResolution() {
        let info = DisplayInfo(
            id: 1,
            name: "Test",
            bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isMain: true
        )
        XCTAssertEqual(info.resolution, "1920×1080")
    }

    func testDisplayInfoStableKey() {
        let info = DisplayInfo(
            id: 1,
            name: "Built-in Retina Display",
            bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isMain: true
        )
        XCTAssertEqual(info.stableKey, "Built-in Retina Display_1920x1080")
    }

    func testSettingsManagerPersistenceWithDisplayInfo() {
        let manager = SettingsManager()
        let display = DisplayInfo(
            id: 99999,
            name: "TestMonitor",
            bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isMain: true
        )
        let shortcut = Shortcut(keyCode: 0x7A, modifiers: 0) // F1

        manager.setShortcut(shortcut, for: display)
        let retrieved = manager.shortcut(forStableKey: display.stableKey)
        XCTAssertEqual(retrieved, shortcut)

        manager.removeShortcut(for: display)
        XCTAssertNil(manager.shortcut(forStableKey: display.stableKey))
    }

    func testSettingsManagerStableKeyResolvesAfterIDChange() {
        let manager = SettingsManager()
        let display = DisplayInfo(
            id: 99999,
            name: "TestMonitor",
            bounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            isMain: true
        )
        let shortcut = Shortcut(keyCode: 0x7A, modifiers: 0)

        manager.setShortcut(shortcut, for: display)

        // Shortcut should be found by stable key even if displayID changes
        let found = manager.shortcut(forStableKey: "TestMonitor_1920x1080")
        XCTAssertEqual(found, shortcut)

        // Cleanup
        manager.removeShortcut(for: display)
    }

    func testShortcutDisplayString() {
        let shortcut = Shortcut(
            keyCode: 0x7A,
            modifiers: UInt32(CGEventFlags.maskControl.rawValue | CGEventFlags.maskShift.rawValue)
        )
        let display = shortcut.displayString
        XCTAssertTrue(display.contains("⌃"))
        XCTAssertTrue(display.contains("⇧"))
        XCTAssertTrue(display.contains("F1"))
    }

    func testShortcutDisplayStringCommandOnly() {
        let shortcut = Shortcut(
            keyCode: 0x12,
            modifiers: UInt32(CGEventFlags.maskCommand.rawValue)
        )
        XCTAssertEqual(shortcut.displayString, "⌘1")
    }

    func testImageComposerSingleImage() {
        let image = NSImage(size: NSSize(width: 100, height: 100))
        let result = ImageComposer.composeVertically([image])
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.size.width, 100)
    }

    func testImageComposerEmpty() {
        let result = ImageComposer.composeVertically([])
        XCTAssertNil(result)
    }

    func testImageComposerMultiple() {
        let img1 = NSImage(size: NSSize(width: 100, height: 50))
        let img2 = NSImage(size: NSSize(width: 100, height: 50))
        let result = ImageComposer.composeVertically([img1, img2])
        XCTAssertNotNil(result)
        // 50 + 50 + 4 (spacing)
        XCTAssertEqual(result?.size.height, 104)
        XCTAssertEqual(result?.size.width, 100)
    }

    func testClipboardManagerCopy() {
        let image = NSImage(size: NSSize(width: 10, height: 10))
        image.lockFocus()
        NSColor.red.set()
        NSBezierPath.fill(NSRect(x: 0, y: 0, width: 10, height: 10))
        image.unlockFocus()

        ClipboardManager.copyToClipboard(image)

        let pasteboard = NSPasteboard.general
        let types = pasteboard.types ?? []
        XCTAssertTrue(types.contains(.tiff) || types.contains(.png))
    }

    // MARK: - Region Preset Tests

    func testRegionPresetCodable() {
        let preset = RegionPreset(
            displayStableKey: "TestMonitor_1920x1080",
            rect: CGRect(x: 100, y: 200, width: 800, height: 600),
            name: "Test Region"
        )
        XCTAssertEqual(preset.rect.cgRect.width, 800)
        XCTAssertEqual(preset.rect.cgRect.height, 600)
        XCTAssertEqual(preset.name, "Test Region")

        // Test encode/decode
        let data = try! JSONEncoder().encode(preset)
        let decoded = try! JSONDecoder().decode(RegionPreset.self, from: data)
        XCTAssertEqual(decoded.displayStableKey, preset.displayStableKey)
        XCTAssertEqual(decoded.rect, preset.rect)
        XCTAssertEqual(decoded.name, preset.name)
    }

    func testRegionPresetSummary() {
        let preset = RegionPreset(
            displayStableKey: "Test_1920x1080",
            rect: CGRect(x: 10, y: 20, width: 400, height: 300),
            name: "My Region"
        )
        XCTAssertEqual(preset.summary, "400×300 at (10,20)")
    }

    func testSettingsManagerRegionPresets() {
        let manager = SettingsManager()
        let preset = RegionPreset(
            displayStableKey: "TestMonitor_1920x1080",
            rect: CGRect(x: 0, y: 0, width: 500, height: 400),
            name: "Test"
        )
        manager.addRegionPreset(preset)
        XCTAssertFalse(manager.regionPresets.isEmpty)

        let shortcut = Shortcut(keyCode: 0x78, modifiers: 0) // F2
        manager.setShortcutForRegion(shortcut, id: preset.id)
        let updated = manager.regionPresets.first(where: { $0.id == preset.id })
        XCTAssertEqual(updated?.shortcut, shortcut)

        manager.removeRegionPreset(id: preset.id)
        XCTAssertTrue(manager.regionPresets.filter({ $0.id == preset.id }).isEmpty)
    }

    func testPositionLabel() {
        // Single display: no label
        XCTAssertEqual(SettingsWindowController.positionLabel(index: 0, total: 1), "")
        // Two displays: left and right
        XCTAssertFalse(SettingsWindowController.positionLabel(index: 0, total: 2).isEmpty)
        XCTAssertFalse(SettingsWindowController.positionLabel(index: 1, total: 2).isEmpty)
        // Three displays: left, center, right - all different
        let left = SettingsWindowController.positionLabel(index: 0, total: 3)
        let center = SettingsWindowController.positionLabel(index: 1, total: 3)
        let right = SettingsWindowController.positionLabel(index: 2, total: 3)
        XCTAssertFalse(left.isEmpty)
        XCTAssertFalse(center.isEmpty)
        XCTAssertFalse(right.isEmpty)
        XCTAssertNotEqual(left, center)
        XCTAssertNotEqual(center, right)
    }

    func testUpdateCheckerVersionComparison() {
        XCTAssertTrue(UpdateChecker.isNewer("2.0.0"))
        XCTAssertTrue(UpdateChecker.isNewer("v1.1.0"))
        XCTAssertFalse(UpdateChecker.isNewer("v1.0.0"))
        XCTAssertFalse(UpdateChecker.isNewer("0.9.0"))
    }

    func testCodableRect() {
        let original = CGRect(x: 10, y: 20, width: 300, height: 400)
        let codable = CodableRect(original)
        XCTAssertEqual(codable.cgRect.origin.x, 10)
        XCTAssertEqual(codable.cgRect.origin.y, 20)
        XCTAssertEqual(codable.cgRect.width, 300)
        XCTAssertEqual(codable.cgRect.height, 400)
    }

    // MARK: - Coordinate System Tests

    func testCodableRectPreservesCoordinates() {
        // Verify that CodableRect faithfully preserves negative origins
        // (common in multi-monitor setups where secondary display is left of primary)
        let rect = CGRect(x: -1920, y: 0, width: 1920, height: 1080)
        let codable = CodableRect(rect)
        let restored = codable.cgRect
        XCTAssertEqual(restored.origin.x, -1920)
        XCTAssertEqual(restored.origin.y, 0)
        XCTAssertEqual(restored.width, 1920)
        XCTAssertEqual(restored.height, 1080)
    }

    func testCodableRectRoundTrip() {
        // Encode and decode to verify JSON round-trip
        let original = CGRect(x: 100.5, y: 200.5, width: 800.0, height: 600.0)
        let codable = CodableRect(original)
        let data = try! JSONEncoder().encode(codable)
        let decoded = try! JSONDecoder().decode(CodableRect.self, from: data)
        XCTAssertEqual(decoded.cgRect.origin.x, original.origin.x, accuracy: 0.001)
        XCTAssertEqual(decoded.cgRect.origin.y, original.origin.y, accuracy: 0.001)
        XCTAssertEqual(decoded.cgRect.width, original.width, accuracy: 0.001)
        XCTAssertEqual(decoded.cgRect.height, original.height, accuracy: 0.001)
    }

    func testRegionPresetCoordinatesPreserved() {
        // Region preset rect from a secondary display with negative coordinates
        let preset = RegionPreset(
            displayStableKey: "External_2560x1440",
            rect: CGRect(x: -2560, y: -200, width: 1280, height: 720),
            name: "Left Monitor Region"
        )
        let data = try! JSONEncoder().encode(preset)
        let decoded = try! JSONDecoder().decode(RegionPreset.self, from: data)
        XCTAssertEqual(decoded.rect.cgRect.origin.x, -2560)
        XCTAssertEqual(decoded.rect.cgRect.origin.y, -200)
        XCTAssertEqual(decoded.rect.cgRect.width, 1280)
        XCTAssertEqual(decoded.rect.cgRect.height, 720)
    }

    // MARK: - Resize Tests

    func testResizeForAISmallImage() {
        // Images smaller than 1568px should not be resized
        let image = NSImage(size: NSSize(width: 800, height: 600))
        let result = CaptureManager.resizeForAI(image)
        XCTAssertEqual(result.size.width, 800)
        XCTAssertEqual(result.size.height, 600)
    }

    func testResizeForAILargeImage() {
        // Images larger than 1568px should be scaled down
        let image = NSImage(size: NSSize(width: 3840, height: 2160))
        let result = CaptureManager.resizeForAI(image)
        let maxDim = max(result.size.width, result.size.height)
        XCTAssertLessThanOrEqual(maxDim, 1568)
        // Aspect ratio should be preserved
        let originalRatio = 3840.0 / 2160.0
        let resultRatio = result.size.width / result.size.height
        XCTAssertEqual(originalRatio, resultRatio, accuracy: 0.01)
    }

    // MARK: - Settings Tests

    func testFeedbackModeRawValues() {
        XCTAssertEqual(FeedbackMode.soundAndFlash.rawValue, 0)
        XCTAssertEqual(FeedbackMode.flashOnly.rawValue, 1)
        XCTAssertEqual(FeedbackMode.none.rawValue, 2)
    }

    func testCaptureResizeModeRawValues() {
        XCTAssertEqual(CaptureResizeMode.full.rawValue, 0)
        XCTAssertEqual(CaptureResizeMode.aiOptimized.rawValue, 1)
    }

    func testDisplayManagerThreadSafety() {
        let manager = DisplayManager()
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10

        for _ in 0..<10 {
            DispatchQueue.global().async {
                _ = manager.displays
                manager.refreshDisplays()
                _ = manager.displays
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5.0)
    }
}
