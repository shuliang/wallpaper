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
    var monitor: Any?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusBar()
        popover.contentViewController = MainViewController.generateController()
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        hidePopover(nil)
    }

    // MARK: - UI
    
    private func setupStatusBar() {
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("camera_icon"))
            button.action = #selector(handleStatusBarEvent(_:))
        }
    }
    
    // MARK: - Event
    
    @objc func handleStatusBarEvent(_ sender: Any?) {
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    private func showPopover(_ sender: Any?) {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] event in
            self?.hidePopover(nil)
        })
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    private func hidePopover(_ sender: Any?) {
        popover.performClose(sender)
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}

