//
//  AppDelegate.swift
//  Wallpaper
//
//  Created by sl on 2018/6/4.
//  Copyright © 2018 shuliang. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popover = NSPopover()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusBar()
        popover.contentViewController = MainViewController.generateController()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - UI
    
    private func setupStatusBar() {
        
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("camera"))
            button.action = #selector(handleStatusBarEvent(_:))
        }
    }
    
    // MARK: - Event
    
    @objc func handleStatusBarEvent(_ sender: Any?) {
        // show popover
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    private func showPopover(_ sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    private func hidePopover(_ sender: Any?) {
        popover.performClose(sender)
    }
}

