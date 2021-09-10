//
//  AppDelegate.swift
//  AudioSwitcher
//
//  Created by Pavel Morozov on 06.09.2021.
//

import Cocoa
import CoreAudio

enum DefaultsKeys: String {
    case inputDeviceID = "InputDeviceID"
    case inputDeviceCount = "InputDeviceCount"
    case outputDeviceID = "OutputDeviceID"
    case outputDeviceCount = "OutputDeviceCount"
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    private let menu = NSMenu()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AudioService.shared.start()
        NotificationCenter.default.addObserver(self, selector: #selector(audioInputDeviceDidChange), name: Notification.Name("AudioInputDeviceDidChange"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(audioOutputDeviceDidChange), name: Notification.Name("AudioOutputDeviceDidChange"), object: nil)
        if let button = statusItem.button {
          button.image = NSImage(named:NSImage.Name("Icon"))
        }
        menu.delegate = self
        statusItem.menu = menu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        AudioService.shared.stop()
    }

    @objc func selectInputDevice(_ sender: NSMenuItem) {
        AudioService.shared.selectedInputDeviceID = AudioDeviceID(sender.tag)
        UserDefaults.standard.set(sender.tag, forKey: DefaultsKeys.inputDeviceID.rawValue)
    }
    
    @objc func selectOutputDevice(_ sender: NSMenuItem) {
        AudioService.shared.selectedOutputDeviceID = AudioDeviceID(sender.tag)
        UserDefaults.standard.set(sender.tag, forKey: DefaultsKeys.outputDeviceID.rawValue)
    }
    
    @objc
    func audioInputDeviceDidChange() {
        let savedId = UserDefaults.standard.integer(forKey: DefaultsKeys.inputDeviceID.rawValue)
        if let selectedId = AudioService.shared.getDevices().filter({!$0.hasOutput && $0.selected}).first?.id,
           Int32(selectedId) != savedId {
            AudioService.shared.selectedInputDeviceID = AudioDeviceID(savedId)
            
            let count = UserDefaults.standard.integer(forKey: DefaultsKeys.inputDeviceCount.rawValue)
            UserDefaults.standard.set(count + 1, forKey: DefaultsKeys.inputDeviceCount.rawValue)
        }
    }
    
    @objc
    func audioOutputDeviceDidChange() {
        let savedId = UserDefaults.standard.integer(forKey: DefaultsKeys.outputDeviceID.rawValue)
        if let selectedId = AudioService.shared.getDevices().filter({$0.hasOutput && $0.selected}).first?.id,
           Int32(selectedId) != savedId {
            AudioService.shared.selectedOutputDeviceID = AudioDeviceID(savedId)
            
            let count = UserDefaults.standard.integer(forKey: DefaultsKeys.outputDeviceCount.rawValue)
            UserDefaults.standard.set(count + 1, forKey: DefaultsKeys.outputDeviceCount.rawValue)
        }
    }
    
    func constructMenu() {
        menu.removeAllItems()
        menu.addItem(NSMenuItem(title: "Output Devices:", action: nil, keyEquivalent: ""))
        for device in AudioService.shared.getDevices().filter({$0.hasOutput}) {
            let item = NSMenuItem(title: device.name, action: #selector(selectOutputDevice(_:)), keyEquivalent: "")
            item.state = device.selected ? .on : .off
            item.tag = Int(device.id)
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Input Devices:", action: nil, keyEquivalent: ""))
        for device in AudioService.shared.getDevices().filter({$0.hasOutput == false}) {
            let item = NSMenuItem(title: device.name, action: #selector(selectInputDevice(_:)), keyEquivalent: "")
            item.state = device.selected ? .on : .off
            item.tag = Int(device.id)
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About", action: #selector(about), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.update()
    }
    
    @objc
    private func about() {
        guard let window = AboutWindowController.defaultController.window else {
            return
        }

        window.orderFrontRegardless()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        constructMenu()
    }
}

