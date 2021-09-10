//
//  AboutWindowController.swift
//  AudioSwitcher
//
//  Created by Pavel Morozov on 06.09.2021.
//

import Cocoa

class AboutWindowController: NSWindowController {

    static let defaultController: AboutWindowController = {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("AboutWindow"), bundle:nil)
        guard let windowController = storyboard.instantiateInitialController() as? AboutWindowController else {
            fatalError("Storyboard inconsistency")
        }
        return windowController
    }()

    override func windowDidLoad() {
        super.windowDidLoad()
    }
}
