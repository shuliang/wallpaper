//
//  MainViewController.swift
//  Wallpaper
//
//  Created by sl on 2018/6/4.
//  Copyright © 2018 shuliang. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet weak var setWallpaperButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var creatorButton: NSButton!
    @IBOutlet weak var downloadButton: NSButton!
    @IBOutlet weak var settingButton: NSButton!
    
    private var currentWallpaper: Wallpaper?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNextPhoto(completion: nil)
    }
    
    // MARK: - Data Source
    
    private func loadNextPhoto(completion: ((NSImage?) -> Void)?) {
        disableUI()
        WallpaperManager.shared.fetchNextPhoto(.small) { (img, model, err) in
            DispatchQueue.main.async { [weak self] in
                self?.enableUI()
                guard self != nil, let image = img, let wallpaper = model else {
                    completion?(nil)
                    return
                }
                guard self != nil else { return }
                self!.imageView.image = image
                self!.creatorButton.attributedTitle = self!.genCreatorTitle(wallpaper)
                self!.currentWallpaper = wallpaper
                completion?(image)
            }
        }
    }
    
    // MARK: -  Event
    @IBAction func handleSetWallpaperButton(_ sender: Any) {
        disableUI()
        WallpaperManager.shared.savePhoto(.full, toCache: true) { [weak self] (photoUrl, err) in
            DispatchQueue.main.async {
                self?.enableUI()
                guard let url = photoUrl, let main = NSScreen.main else {
                    return
                }
                do {
                    let defaultOptions: [NSWorkspace.DesktopImageOptionKey: Any] = [
                        .allowClipping: true,
                        .fillColor: NSColor.black,
                        .imageScaling: NSImageScaling.scaleAxesIndependently
                    ]
                    let opts = NSWorkspace.shared.desktopImageOptions(for: main) ?? defaultOptions
                    try NSWorkspace.shared.setDesktopImageURL(url, for: main, options: opts)
                } catch let error {
                    print("Set wallpaper error:", error)
                }
            }
        }
    }
    
    @IBAction func handleNextButton(_ sender: Any) {
        loadNextPhoto(completion: nil)
    }
    
    @IBAction func handleCreatorButton(_ sender: Any) {
        guard let url = currentWallpaper?.user?.links?.html else { return }
        NSWorkspace.shared.open(url)
    }
    
    @IBAction func handleDownloadButton(_ sender: Any) {
        disableUI()
        WallpaperManager.shared.savePhoto(.full, toCache: false) { [weak self] (photoUrl, err) in
            DispatchQueue.main.async {
                self?.enableUI()
                guard self != nil, let url = photoUrl else {
                    return
                }
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    @IBAction func handleSettingButton(_ sender: NSButton) {
        let menu = NSMenu()
        let aboutItem = NSMenuItem(title: "About", action: #selector(toggleAbout), keyEquivalent: "a")
        menu.addItem(aboutItem)
        let quitItem = NSMenuItem(title: "Quit", action: #selector(toggleQuit), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        let p = NSPoint(x: sender.frame.width / 2, y: sender.frame.height / 2)
        menu.popUp(positioning: nil, at: p, in: sender)
    }
    
    @objc private func toggleAbout() {        
        let sb = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let id = NSStoryboard.SceneIdentifier(rawValue: "AboutViewController")
        guard let vc = sb.instantiateController(withIdentifier: id) as? NSViewController else {
            fatalError("Instantiate About Controller failed.")
        }
        presentViewControllerAsModalWindow(vc)
    }
    
    @objc private func toggleQuit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Helper
    
    private func disableUI() {
        indicator.startAnimation(nil)
        indicator.isHidden = false
        let btns = [setWallpaperButton, nextButton, creatorButton, downloadButton]
        for btn in btns {
            btn?.isEnabled = false
        }
    }
    
    private func enableUI() {
        indicator.stopAnimation(nil)
        indicator.isHidden = true
        let btns = [setWallpaperButton, nextButton, creatorButton, downloadButton]
        for btn in btns {
            btn?.isEnabled = true
        }
    }
    
    private func genCreatorTitle(_ wallpaper: Wallpaper) -> NSAttributedString {
        let str = NSMutableAttributedString(string: "By ")
        let creator = wallpaper.user?.name ?? wallpaper.user?.username ?? "Anonymous"
        let attr = [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 13, weight: .semibold)]
        str.append(NSAttributedString(string: creator, attributes: attr))
        return str
    }
}

extension MainViewController {
    static func generateController() -> MainViewController {
        let sb = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let id = NSStoryboard.SceneIdentifier(rawValue: "MainViewController")
        guard let vc = sb.instantiateController(withIdentifier: id) as? MainViewController else {
            fatalError("Instantiate pop Controller failed.")
        }
        return vc
    }
}
