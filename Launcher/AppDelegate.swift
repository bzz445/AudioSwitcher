//
//  AppDelegate.swift
//  Launcher
//
//  Created by Pavel Morozov on 13.09.2021.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainAppIdentifier = "com.b333i.AudioSwitcher"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty

        if !isRunning {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.terminate), name: Notification.Name("killLauncher"), object: mainAppIdentifier)

            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("AudioSwitcher")
            let newPath = NSString.path(withComponents: components)
            NSWorkspace.shared.launchApplication(newPath)
        }
        else {
            self.terminate()
        }
    }

    @objc func terminate() {
        NSApp.terminate(nil)
    }
}

