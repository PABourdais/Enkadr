import SwiftUI

@main
struct EnkadrApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 480, height: 640)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }

    init() {
        Defaults.register()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register as a regular GUI app so it captures keyboard focus
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Ensure the Edit menu exists so text fields can receive keyboard input
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let editMenuItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        editMenuItem.submenu = editMenu

        if let mainMenu = NSApp.mainMenu {
            mainMenu.addItem(editMenuItem)
        } else {
            let mainMenu = NSMenu()
            mainMenu.addItem(editMenuItem)
            NSApp.mainMenu = mainMenu
        }
    }
}
